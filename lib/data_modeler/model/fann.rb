require 'ruby-fann'

# Model class based on Fast Artificial Neural Networks (FANN)
class DataModeler::Model::FANN

  attr_reader :fann_opts, :ngens, :fann, :algo, :actfn

  # @param ngens [Integer] number of generations alloted for training
  # @param hidden_layers [Array<Integer>] list of number of hidden neurons
  #      per each hidden layer in the network
  # @param ninputs [Integer] number of inputs of the network
  # @param noutputs [Integer] number of outputs of the network
  # @param algo [:incremental, :batch, :rprop, :quickprop] training algorithm
  # @param actfn [:sigmoid, ...] activation function
  def initialize ngens:, hidden_layers:, ninputs:, noutputs:, algo: nil, actfn: nil
    @fann_opts = {
      num_inputs: ninputs,
      hidden_neurons: hidden_layers,
      num_outputs: noutputs
    }
    @ngens = ngens
    @algo = algo
    @actfn = actfn
    reset
  end

  # Resets / initializes the model
  # @return [void]
  def reset
    @fann = RubyFann::Standard.new fann_opts
    fann.set_training_algorithm(algo) if algo
    if actfn
      fann.set_activation_function_hidden(actfn)
      fann.set_activation_function_output(actfn)
    end
    nil
  end

  # Trains the model for ngens on the trainset
  # @param trainset [Hash-like<input: Array, target: Array>] training set
  # @param ngens [Integer] number of training generations
  # @return [void]
  def train trainset, ngens=@ngens, report_interval: 1000, desired_error: 1e-10
    # TODO: optimize maybe?
    inputs, targets = trainset.values
    tset = RubyFann::TrainData.new inputs: inputs, desired_outputs: targets
    # fann.init_weights tset # test this weights initialization

    # params: train_data, max_epochs, report_interval, desired_error
    fann.train_on_data(tset, ngens, report_interval, desired_error)
  end

  # Tests the model on inputs.
  # @param inputs [Array<Array<inputs>>] sequence of inputs for the model
  # @return [Array<Array<outputs>>] outputs corresponding to each input
  def test inputs
    inputs.collect { |i| fann.run i }
  end

  # Save the model
  # @param filename [String/path] where to save the model
  # @return [void]
  def save filename
    # can do filename check here...?
    # TODO: I'd like to have a kind of `to_s`, and do all the saving in the modeler...
    fann.save filename.to_s
  end
end
