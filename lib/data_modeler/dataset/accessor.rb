
# Build complex inputs and targets from the data to train the model.
class DataModeler::Dataset::Accessor

  attr_reader :data, :input_series, :target_series, :first_idx, :end_idx,
              :ninput_points, :tspread, :look_ahead, :first_idx, :target_idx,
              :input_idxs, :nrows

  # @param data [Hash] the data, in an object that can be
  #     accessed by keys and return a time series per each key.
  #     It is required to include and be sorted by a series named `time`,
  #     and for all series to have equal length.
  # @param inputs [Array] data key accessors for input series
  # @param targets [Array] data key accessors for target series
  # @param first_idx [Integer] index where the dataset starts on data
  # @param end_idx [Integer] index where the dataset ends on data
  # @param ninput_points [Integer] number of lines/datapoints to be
  #     used to construct the input
  # @param tspread [Numeric] distance (in `time`!) between the `ninput_points`
  #     lines/datapoints used to construct the input
  # @param look_ahead [Numeric] distance (in `time`!) between the
  #     most recent line/time/datapoint used for the input and
  #     the target -- i.e., how far ahead the model is trained to predict
  # @note we expect Datasets indices to be used with left inclusion but
  #     right exclusion, i.e. targets are considered in the range `[from,to)`
  def initialize data, inputs:, targets:, first_idx:, end_idx:, ninput_points:, tspread:, look_ahead:
    @data = data
    @input_series = inputs
    @target_series = targets
    @first_idx = first_idx
    @end_idx = end_idx
    @ninput_points = ninput_points
    @nrows = data[:time].size
    @tspread = tspread
    @look_ahead = look_ahead
    @first_idx = first_idx
    reset_iteration
  end

  # TODO: make sure constructor requirements are unnecessary for static models

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

  # Returns the time of the current target
  # @return [type of `data[:time]`]
  def trg_time
    data[:time][target_idx]
  end

  ### ITERATION

  # Returns the next pair [inputs, targets]
  # @return [Array]
  # @raise [StopIteration] when the target index is past the dataset limits
  def peek
    raise StopIteration if target_idx >= end_idx
    [trg_time, inputs, targets]
  end

  # Returns the next pair [inputs, targets] and increments the target
  # @return [Array]
  def next
    peek.tap do
      @target_idx += 1
      @input_idxs = init_inputs
    end
  end

  # `#each` and `#to_a` based on `#next`
  include DataModeler::Dataset::IteratingBasedOnNext

  ### COMPATIBILITY

  # Compatibility with Hash, which returns a list of series' data arrays
  # @return [Array<Array>>] list of values per each serie
  def values
    to_a.transpose
  end

  # Equality operator -- most useful in testing
  # @param other [Dataset] what needs comparing to
  # @return [true|false]
  def == other
    self.class == other.class && # terminate check here if wrong class
      data.object_id == other.data.object_id && # both `data` point to same object
      (instance_variables - [:@data]).all? do |var|
        self.instance_variable_get(var) == other.instance_variable_get(var)
      end
  end

  private

  # Resets the indices at the start position -- used for iterations
  # @return [void]
  def reset_iteration
    @target_idx = first_idx
    @input_idxs = init_inputs
  end

  # `#time` and `#idx` for time/index conversion
  include DataModeler::Dataset::ConvertingTimeAndIndices

  # Initializes input indices vector
  # @return [Array<input_idx>]
  def init_inputs
    if target_idx < end_idx
      # build list of incremental time buffers
      bufs = ninput_points.times.collect { |n| look_ahead + n * tspread }
      # reverse it and subtract from the target's time
      times = bufs.reverse.collect { |s| time(target_idx) - s }
      # now you have the list of times at which each pointer should point
      times.collect &method(:idx)
    end
  end

end
