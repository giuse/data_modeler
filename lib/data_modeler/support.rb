
# Main gem module
module DataModeler

  ### HELPER FUNCTIONS

  # Returns a standardized String ID from a (sequentially named) file
  # @return [String]
  # @note convenient method to have available in the config
  def self.id_from filename
    format "%02d", Integer(filename[/_(\d+).rb$/,1])
  end

  # Returns an instance of the Framework class
  # @param config [Hash] Framework class configuration
  # @return [Framework] initialized instance of Framework class
  def self.new config
    DataModeler::Framework.new config
  end

  ### EXCEPTIONS

  class DataModeler::Dataset
    # Exception: the requested `time` is not present in the data
    class TimeNotFoundError < StandardError; end
  end

  class DataModeler::DatasetGen
    # Exception: not enough `data` was provided for even a single train+test setup
    class NotEnoughDataError < StandardError; end

    # Exception: not enough `data` left to build another train+test
    # @note subclassed from `StopIteration` -> it will break loops
    class NoDataLeft < StopIteration; end
  end
end
