require "data_modeler/version"
require "data_modeler/exceptions"

# Dataset
require "data_modeler/dataset/dataset_helper"
require "data_modeler/dataset/dataset"
require "data_modeler/dataset/dataset_gen"

# Models (should be added to this module)
module DataModeler::Model; end
require "data_modeler/model/fann"
