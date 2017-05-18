
# Main gem module
module DataModeler

  ### VERSION

  # Version number
  VERSION = "0.3.3"

  ### HELPER FUNCTIONS

  # Returns a standardized String ID from a (sequentially named) file
  # @return [String]
  # @note convenient method to have available in the config
  def self.id_from_filename filename=__FILE__
    format "%02d", Integer(filename[/_(\d+).rb$/,1])
  end

  # Returns an instance of the Base class
  # @param config [Hash] Base class configuration
  # @return [Base] initialized instance of Base class
  def self.new config
    DataModeler::Base.new config
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
