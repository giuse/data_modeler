
# All models for the framework should belong to this module.
# Also includes a model selector for initialization from config.
module DataModeler::Models
  # Returns a new `Model` based on the `type` of choice initialized
  #     with `opts` parameters
  # @param type [Symbol] selects the type of `Model`
  # @param opts [**Hash] the rest of the parameters will be passed
  #     to the model for its initialization
  # @return [Model] an initialized `Model` of type `type`
  def self.selector type:, **opts
    case type
    when :fann
      FANN.new opts
    else abort "Unrecognized model: #{type}"
    end
  end
end
