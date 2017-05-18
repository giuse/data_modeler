
# Build train and test datasets for each run of the training.
#
# Train and test sets are seen as moving windows on the data.
# Alignment is designed to provide continuous testing results over (most of) the data.
# The following diagram exemplifies this: the training sets `t1`, `t2` and `t3` are
# aligned such that their results can be plotted countinuously against the obserevations.
# (b) is the amount of data covering for the input+look_ahead window uset for the first
# target.
#   data:  ---------------------->  (time, datapoints)
#   run1:  (b)|train1|t1|       ->  train starts after (b), test after training
#   run2:        |train2|t2|    ->  train starts after (b) + 1 tset
#   run3:           |train3|t3| ->  train starts after (b) + 2 tset
# Note how the test sets line up. This allows the testing results plots
# to be continuous, while no model is tested on data on which _itself_ has been trained.
# All data is used multiple times, alternately both as train and test sets.
class DataModeler::DatasetGen

  attr_reader :data, :ds_args, :first_idx, :train_size, :test_size, :nrows

  # @param data [Hash] the data, in an object that can be
  #     accessed by keys and return a time series per each key.
  #     It is required to include (and be sorted by) a series named `:time`,
  #     and for all series to have equal length.
  # @param ds_args [Hash] parameters hash for `Dataset`s initialization.
  #     Keys: `%i[inputs, targets, first_idx, end_idx, ninput_points]`.
  #     See `Dataset#initialize` for details.
  # @param train_size [Integer] how many points to expose as targets in each training set
  # @param test_size [Integer] how many points to expose as targets in each test set
  def initialize data, ds_args:, train_size:, test_size:, min_nruns: 1
    @data = data
    @ds_args = ds_args
    @first_idx = first_idx
    @train_size = train_size
    @test_size = test_size
    reset_iteration

    @nrows = data[:time].size
    validate_enough_data_for min_nruns
  end

  ### DATA ACCESS

  # Builds training sets for model training
  # @param nrun [Integer] will build different trainset for each run
  # @return [Dataset]
  # @raise [NoDataLeft] when there's not enough data left for a full train+test
  # @note train or test have no meaning alone, and train always comes first.
  #     Hence, `#train` checks if enough `data` is available for both `train`+`test`.
  def train nrun
    first = min_eligible_trg + (nrun-1) * test_size
    last = first + train_size
    raise NoDataLeft unless last + test_size < nrows  # make sure there's enough data
    DataModeler::Dataset.new data, ds_args.merge(first_idx: first, end_idx: last)
  end

  # Builds test sets for model testing
  # @param nrun [Integer] will build different testset for each run
  # @return [Dataset]
  # @note train or test have no meaning alone, and train always comes first.
  #     Hence, `#train` checks if enough `data` is available for both `train`+`test`.
  def test nrun
    first = min_eligible_trg + (nrun-1) * test_size + train_size
    last = first + test_size
    DataModeler::Dataset.new data, ds_args.merge(first_idx: first, end_idx: last)
  end

  ### ITERATION

  # TODO: @local_nrun is an ugly name, refactor it!

  # Returns the next pair `[trainset, testset]`
  # @return [Array<Dataset, Dataset>]
  def peek
    [self.train(@local_nrun), self.test(@local_nrun)]
  end

  # Returns the next pair `[trainset, testset]` and increments the counter
  # @return [Array<Dataset, Dataset>]
  def next
    peek.tap { @local_nrun += 1 }
  end

  # `#each` and `#to_a` based on `#next`
  include DataModeler::Dataset::IteratingBasedOnNext

  # I want `#to_a` to return an array of arrays rather than an array of dataset

  # Returns an array of datasets
  # @return [Array<Array[Dataset]>]
  alias_method :to_ds_a, :to_a
  # Returns an array of arrays (list of inputs-targets pairs)
  # @return [Array<Array<Array<...>>]
  def to_a
    to_ds_a.collect do |train_test_for_run|
      train_test_for_run.collect &:to_a
    end
  end

  private

  # Resets the index at the start position -- used for iterations
  # @return [void]
  def reset_iteration
    @local_nrun = 1
  end

  # `#time` and `#idx` for time/index conversion
  include DataModeler::Dataset::ConvertingTimeAndIndices

  # Find the index of the first element in the data eligible as target for training
  # @return [Integer] the index of the first eligible target
  def min_eligible_trg
    @min_eligible_trg ||= idx( time(0) +
      # minimum time span required as input for the first target
      ds_args[:look_ahead] + (ds_args[:ninput_points]-1) * ds_args[:tspread]
    )
  end

  # Check if there is enough data to build `min_nruns` train + test sets
  # @raise [NotEnoughDataError] if `not enough minerals` (cit.)
  # @return [void]
  # @note remember the schema: need to check for `|win|train1|t1|t2|...|tn|`
  def validate_enough_data_for min_nruns
    min_data_size = min_eligible_trg + train_size + min_nruns * test_size
    raise NotEnoughDataError if nrows < min_data_size
  end
end
