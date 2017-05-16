
# Helper functions go here
module DataModeler
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
end
