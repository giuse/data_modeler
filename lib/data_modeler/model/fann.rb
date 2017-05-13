require 'ruby-fann'

# Model class based on Fast Artificial Neural Networks (FANN)
class DataModeler::Model::FANN

  attr_reader :opts, :fann, :algo, :actfn

  # @param netstruct [Array<ninputs, Array<hidden_layers>, noutputs>] network
  #     structure
  # @param algo [:incremental, :batch, :rprop, :quickprop] training algorithm
  # @param actfn [:sigmoid, ...] activation function
  def initialize netstruct, algo: nil, actfn: nil
    ninputs, hidden_layers, noutputs = netstruct
    @opts = {
      num_inputs: ninputs,
      hidden_neurons: hidden_layers,
      num_outputs: noutputs
    }
    @algo = algo
    @actfn = actfn
    reset
  end

  # Resets / initializes the model
  # @return [void]
  def reset
    @fann = RubyFann::Standard.new opts
    fann.set_training_algorithm(algo) if algo
    if actfn
      fann.set_activation_function_hidden(actfn)
      fann.set_activation_function_output(actfn)
    end
    nil
  end

  # Trains the model for ngens on the trainset
  # @param ngens [Integer] number of training generations
  # @param trainset [Hash-like<input: Array, target: Array>] training set
  # @return [void]
  def train ngens, trainset
    tset = RubyFann::TrainData.new(
      inputs: trainset[:input], desired_outputs: trainset[:target])
    # fann.init_weights tset # test this weights initialization

    # params: train_data, max_epochs, reports_interval, desired_error
    fann.train_on_data(tset, ngens, 1000, 1e-10)
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
    fann.save filename
  end
end
