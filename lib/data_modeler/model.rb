
# All models for the framework should belong to this module.
# Also includes a model selector for initialization from config.
module DataModeler::Model
  # Returns a new Model correctly initialized based on the `type` of choice
  # @param type [Symbol] which type of Model is chosen
  # @param opts [splatted Hash params] the rest of the parameters will be passed
  #     to the model for initialization
  # @return [Model] a correctly initialized Model of type `type`
  def self.from_conf type:, **opts
    case type
    when :fann
      FANN.new opts
    else abort "Unrecognized model: #{type}"
    end
  end
end
