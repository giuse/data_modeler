
# Build complex inputs and targets from the data to train the model.
#
# @note checks to validate if enough data is present (given `ntimes`, `tspread`
#     and `look_ahead`) should be done on the caller (typically `DatasetGen`)
class DataModeler::Dataset

  attr_reader :data, :input_series, :target_series, :first_idx, :end_idx,
              :ntimes, :tspread, :look_ahead, :target_idx, :input_idxs,
              :nrows

  # @param data [Hash-like] the data, in an object that can be
  #     accessed by keys and return a time series per each key.
  #     It is required to include and be sorted by a series named `time`,
  #     and for all series to have equal length.
  # @param inputs [Array] data key accessors for input series
  # @param targets [Array] data key accessors for target series
  # @param first_idx [Integer] index where the dataset starts on data
  # @param end_idx [Integer] index where the dataset ends on data
  # @param ntimes [Integer] number of lines/times/datapoints to be
  #     used to construct the input
  # @param tspread [Numeric] distance (in `time`!) between the `ntimes`
  #     lines/times/datapoints used to construct the input
  # @param look_ahead [Numeric] distance (in `time`!) between the
  #     most recent line/time/datapoint used for the input and
  #     the target -- i.e., how far ahead the model is trained to predict
  # @note we expect Datasets indices to be used with left inclusion but
  #     right exclusion, i.e. targets are considered in the range `[from,to)`
  def initialize data, inputs:, targets:, first_idx:, end_idx:,
      ntimes:, tspread:, look_ahead:
    @data = data
    @input_series = inputs
    @target_series = targets
    @first_idx = first_idx
    @end_idx = end_idx
    @ntimes = ntimes
    @nrows = data[:time].size
    @tspread = tspread
    @look_ahead = look_ahead
    @target_idx = first_idx
    @input_idxs = init_inputs
  end

  # TODO: make sure constructor requirements are unnecessary for static models
  # TODO: check if enough data / minimum_target
  # TODO: the check in `#init_target` should go in the `ds_gen`

  # Builds inputs for the model
  # @return [Array]
  def inputs
    input_idxs.flat_map do |idx|
      input_series.collect do |s|
        data[s][idx]
      end
    end
  end

  # Builds targets for the model
  # @return [Array]
  def targets
    target_series.collect do |s|
      data[s][target_idx]
    end
  end

  # Returns the next pair [inputs, targets]
  # @return [Array]
  def peek
    raise StopIteration if target_idx >= end_idx
    [inputs, targets]
  end

  # Returns the next pair [inputs, targets] and increments the target
  # @return [Array]
  def next
    peek.tap do
      @target_idx += 1
      @input_idxs = init_inputs
    end
  end

  include DataModeler::IteratingBasedOnNext # `#each` and `#to_a` based on `#next`

  # Overloaded comparison for easier testing
  def == other
    self.class == other.class &&
      data.object_id == other.data.object_id &&
      (instance_variables - [:@data]).all? do |var|
        self.instance_variable_get(var) == other.instance_variable_get(var)
      end
  end

  private

  include DataModeler::ConvertingTimeAndIndices # `#time` and `#idx`

  def init_inputs
    if target_idx < end_idx
      # build list of incremental time buffers
      bufs = ntimes.times.collect { |n| look_ahead + n * tspread }
      # reverse it and subtract from the target's time
      times = bufs.reverse.collect { |s| time(target_idx) - s }
      # now you have the list of times at which each pointer should point
      times.collect &method(:idx)
    end
  end

end
