class DataModeler::Dataset
  # Exception: the requested `time` is not present in the data
  class TimeNotFoundError < StandardError; end
end

class DataModeler::DatasetGen
  # Exception: the `data` is not sufficient for the training setup
  class NotEnoughDataError < StandardError; end
  # Exception: not enough `data` left to build another train+test
  # @note being subclassed from `StopIteration`, it will break loops
  class NoDataLeft < StopIteration; end
end
