
# Create complex inputs and targets for the model from the given data
class DataModeler::Dataset

  attr_reader :data, :input_series, :target_series, :first_idx, :last_idx,
              :ntimes, :tspread, :look_ahead, :target_idx, :input_idxs

  # @param data [Hash] requirements:
  #     1. hash of `name->column`, 2. `time` column 3. sorted by `time`
  # @param inputs [Array] data key accessors for input series
  # @param targets [Array] data key accessors for target series
  # @param first_idx [Integer] index where the dataset starts on data
  # @param last_idx [Integer] index where the dataset ends on data
  # @param ntimes [Integer] number of lines/times/datapoints to be
  #     used to construct the input
  # @param tspread [Numeric] distance (in `time`!) between the `ntimes`
  #     lines/times/datapoints used to construct the input
  # @param look_ahead [Numeric] distance (in `time`!) between the
  #     most recent line/time/datapoint used for the input and
  #     the target -- i.e., how far ahead the model is trained to predict
  def initialize data, inputs:, targets:, first_idx:, last_idx:,
      ntimes:, tspread:, look_ahead:
    @data = data
    @input_series = inputs
    @target_series = targets
    @first_idx = first_idx
    @last_idx = last_idx
    @ntimes = ntimes
    @tspread = tspread
    @look_ahead = look_ahead
    @target_idx = init_target
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
    raise StopIteration if target_idx >= last_idx
    [inputs, targets]
  end

  # Returns the next pair [inputs, targets] and increments the target
  # @return [Array]
  def next
    raise StopIteration if target_idx >= last_idx
    peek.tap do
      @target_idx += 1
      @input_idxs = init_inputs
    end
  end

  # Yields on each [inputs, targets] pair.
  # @return [nil, Iterator] Returns an `Iterator` unless block given
  def each
    return enum_for(:each) unless block_given?
    loop { yield self.next }
    nil
  end

  # @return [Array]
  def to_a
    each.to_a
  end

  private

  def init_target
    # minimum time span required as input for first target
    min_time_span = look_ahead + ntimes * tspread
    # index of first element eligible as target on this data
    first_eligible_idx = idx time(0) + min_time_span
    # return the first eligible for the current data slice
    [first_eligible_idx, first_idx].max
  end

  def time idx
    data[:time][idx]
  end

  def idx time
    # TODO: optimize with `from:`
    # TODO: test corner case when index not found
    # find index of first above time
    idx = data[:time].index { |t| t > time }
    # if index not found: all data is below time, "first above" is outofbound
    idx ||= data.size
    # if first above time is 0: there is no element with that time
    raise TimeNotFound, "Time not found: #{time}" if idx.zero?
    # return index of predecessor (last below time)
    idx-1
  end

  def init_inputs
    # build list of incremental time buffers
    bufs = ntimes.times.collect { |n| look_ahead + n * tspread }
    # reverse it and subtract from the target's time
    times = bufs.reverse.collect { |s| time(target_idx) - s }
    # now you have the list of times at which each pointer should point
    times.collect &method(:idx)
  end

end
