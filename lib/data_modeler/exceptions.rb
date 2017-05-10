class DataModeler::Dataset
  # Exception: the requested `time` is not present in the data
  class TimeNotFound < StandardError; end
  # Exception: the `data` is not sufficient for the training setup
  class InsufficientData < StandardError; end
end
