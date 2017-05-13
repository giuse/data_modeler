
# Build train and test datasets for each run of the training.
#
# This diagram should help understanding how it works
# (win is the input+look_ahead window for first training target)
#   ----------------------------------------> data (time)
#   |win|train1|t1|       -> train starts after window, test after training
#          |train2|t2|    -> train starts after window + 1 tset
#             |train3|t3| -> train starts after window + 2 tset
# Note how the test sets line up. This allows the testing results plots
# to be continuous, no model is tested on data on which *itself* has been
# trained, and all data is used multiple times
class DataModeler::DatasetGen

  attr_reader :data, :ds_args, :first_idx, :train_size, :test_size, :nrows

  # @param data [Hash-like] the data, in an object that can be
  #     accessed by keys and return a time series per each key.
  #     It is required to include and be sorted by a series named `time`,
  #     and for all series to have equal length.
  # @param ds_args [Hash] parameters for the Datasets: inputs, targets,
  #     first_idx, end_idx, ntimes. Check class Dataset for details.
  # @train_size: how many points to predict for each training set
  # @test_size: how many points to predict for each test set
  def initialize data, ds_args:, train_size:, test_size:, min_nruns: 1
    @data = data
    @ds_args = ds_args
    @first_idx = first_idx
    @train_size = train_size
    @test_size = test_size
    @local_nrun = 1 # used to iterate over nruns with #next

    @nrows = data[:time].size
    validate_enough_data_for min_nruns
  end

  # Builds training set for the training
  # @param nrun [Integer] will build different train+test for each run
  # @return [Dataset]
  # @raise [NoDataLeft] when there's not enough data left for a full train+test
  def train nrun
    first = min_eligible_trg + (nrun-1) * test_size
    last = first + train_size
    # make sure there's enough data for both train and test
    raise NoDataLeft unless last + test_size < nrows
    DataModeler::Dataset.new data, ds_args.merge(first_idx: first, end_idx: last)
  end

  # Builds test set for the training
  # @param nrun [Integer] will build different train+test for each run
  # @return [Dataset]
  # @note we already checked pre-training there's enough data for the test too
  def test nrun
    first = min_eligible_trg + (nrun-1) * test_size + train_size
    last = first + test_size
    DataModeler::Dataset.new data, ds_args.merge(first_idx: first, end_idx: last)
  end

  # Returns the next pair [trainset, testset]
  # @return [Array<Dataset, Dataset>]
  def peek
    [self.train(@local_nrun), self.test(@local_nrun)]
  end

  # TODO: @local_nrun is an ugly hack, refactor it!

  # Returns the next pair [trainset, testset] and increments the counter
  # @return [Array<Dataset, Dataset>]
  def next
    peek.tap { @local_nrun += 1 }
  end

  include DataModeler::IteratingBasedOnNext # `#each` and `#to_a` based on `#next`

  # I want `#to_a` to return an array of arrays rather than an array of dataset

  # @return [Array<Array[Dataset]>]
  alias_method :to_ds_a, :to_a
  # @return [Array<Array<Array<...>>]
  def to_a
    to_ds_a.collect do |run|
      run.collect &:to_a
    end
  end

  private

  include DataModeler::ConvertingTimeAndIndices # `#time` and `#idx`

  # Find the index of the first element in the data eligible as target for training
  # @return [Integer] the index of the first eligible target
  def min_eligible_trg
    @min_eligible_trg ||= idx(time(0) +
      # minimum time span required as input for the first target
      ds_args[:look_ahead] + (ds_args[:ntimes]-1) * ds_args[:tspread]
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
