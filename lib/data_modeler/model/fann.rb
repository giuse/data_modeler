require 'ruby-fann'

# Model class based on Fast Artificial Neural Networks (FANN)
class DataModeler::Model::FANN

  attr_reader :opts, :fann, :algo, :actfn

  def initialize netstruct, algo: nil, actfn: nil
    ninputs, hidden_layers, noutputs = netstruct
    @opts = {
      num_inputs: ninputs,
      hidden_neurons: hidden_layers,
      num_outputs: noutputs
    }
    @algo = algo
    @actfn = actfn
  end

  def reset
    @fann = RubyFann::Standard.new opts

    if algo
      fann.set_training_algorithm(algo)
    end

    if actfn
      fann.set_activation_function_hidden(actfn)
      fann.set_activation_function_output(actfn)
    end

    return self # allows chaining for `model.reset.train`
  end

  def train ngens, trainset
    tset = RubyFann::TrainData.new(
      inputs: trainset[:input], desired_outputs: trainset[:target])
    # fann.init_weights tset # test this weights initialization

    # params: train_data, max_epochs, reports_interval, desired_error
    fann.train_on_data(tset, ngens, 1000, 1e-10)
  end

  def test inputs
    inputs.collect { |i| fann.run i }
  end

  def save filename
    # can do filename check here...?
    # I'd rather have kind of a `to_s`, and do the saving in the modeler
    fann.save filename
  end
end
