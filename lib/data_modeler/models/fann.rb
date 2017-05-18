require 'ruby-fann'

# Model the data using an artificial neural network, based on the
# Fast Artificial Neural Networks (FANN) implementation
class DataModeler::Models::FANN

  attr_reader :fann_opts, :ngens, :fann, :algo, :actfn, :init_weights_range

  # @param ngens [Integer] number of generations (repetitions) alloted for training
  # @param hidden_layers [Array<Integer>] list of number of hidden neurons
  #      per each hidden layer in the network
  # @param ninputs [Integer] number of inputs in the network
  # @param noutputs [Integer] number of outputs in the network
  # @param algo [:rprop, :rwg, ...] training algorithm
  # @param actfn [:sigmoid, ...] activation function
  # @param init_weights_range [Array<min_w, max_w>] minimum and maximum value for weight initialization range
  def initialize ngens:, hidden_layers:, ninputs:, noutputs:, algo: nil, actfn: nil, init_weights_range: nil
    @fann_opts = {
      num_inputs: ninputs,
      hidden_neurons: hidden_layers,
      num_outputs: noutputs
    }
    @ngens = ngens
    @algo = algo
    @actfn = actfn
    @init_weights_range = init_weights_range
    reset
  end

  # Resets / initializes the model
  # @return [void]
  def reset
    @fann = RubyFann::Standard.new fann_opts
    if algo && algo != :rwg
      fann.set_training_algorithm(algo)
    end
    if actfn
      fann.set_activation_function_hidden(actfn)
      fann.set_activation_function_output(actfn)
    end
    if init_weights_range
      fann.randomize_weights(*init_weights_range.map(&method(:Float)))
    end
  end

  # Trains the model for ngens on the trainset
  # @param trainset [Hash<input: Array, target: Array>] training set
  # @param ngens [Integer] number of training generations
  # @return [void]
  def train trainset, ngens=@ngens, report_interval: 1000, desired_error: 1e-10
    # special case: not implemented in FANN
    if algo == :rwg
      return train_rwg(trainset, ngens,
        report_interval: report_interval, desired_error: desired_error)
    end
    # TODO: optimize maybe?
    inputs, targets = trainset.values
    tset = RubyFann::TrainData.new inputs: inputs, desired_outputs: targets
    # fann.init_weights tset # test this weights initialization

    # params: train_data, max_epochs, report_interval, desired_error
    fann.train_on_data(tset, ngens, report_interval, desired_error)
  end

  # Trains the model for ngens on the trainset using Random Weight Guessing
  # @param trainset [Hash-like<input: Array, target: Array>] training set
  # @param ngens [Integer] number of training generations
  # @return [void]
  def train_rwg trainset, ngens=@ngens, report_interval: 1000, desired_error: 1e-10
    # TODO: use report_interval and desired_error
    # initialize weight with random values in an interval [min_weight, max_weight]
    # NOTE: if the RWG training is unsuccessful, this range is the first place to
    # check to improve performance
    fann.randomize_weights(*init_weights_range.map(&method(:Float)))
    # test it on inputs
    inputs, targets = trainset.values
    outputs = test(inputs)
    # calculate RMSE
    rmse_fn = -> (outs) do
      sq_err = outs.zip(targets).flat_map do |os,ts|
        os.zip(ts).collect { |o,t| (t-o)**2 }
      end
      Math.sqrt(sq_err.reduce(:+) / sq_err.size)
    end
    rmse = rmse_fn.call(outputs)
    # initialize best
    best = [fann,rmse]
    # rinse and repeat
    ngens.times do
      outputs = test(inputs)
      rmse = rmse_fn.call(outputs)
      (best = [fann,rmse]; puts rmse) if rmse < best.last
    end
    # expose the best to the interface
    fann = best.first
  end

  # Tests the model on inputs.
  # @param inputs [Array<Array<inputs>>] sequence of inputs for the model
  # @return [Array<Array<outputs>>] outputs corresponding to each input
  def test inputs
    inputs.collect { |i| fann.run i }
  end

  # Saves the model
  # @param filename [String/path] where to save the model
  # @return [void]
  def save filename
    # can do filename check here...?
    # TODO: I'd like to have a kind of `to_s`, and do all the saving in the modeler...
    fann.save filename.to_s
  end
end
