

######################
# MODEL TEST EXAMPLE #
######################

# To verify your model works with the framework, copy the lines below and
# adapt them to your model
YOUR_MODEL = DataModeler::Model::FANN

# Describe the Model class
describe YOUR_MODEL do
  # WARNING: your model NEEDS to have 2 inputs and 1 output for this test
  let(:opts) do
    { ninputs: 2,
      hidden_layers: [2],
      noutputs: 1,
      algo: :rprop,
      actfn: :sigmoid,
      ngens: 300
    }
  end
  # put the model in the subject, then call `it_behaves_like` as follows:
  subject(:model) { described_class.new **opts }
  it_behaves_like DataModeler::Model

##########################
# MODEL TEST EXAMPLE end #
##########################


  # Now you can continue unit-testing your model
  # For example with the shared examples for nonlinear solving capability
  it_behaves_like "nonlinear solver"

  # Or testing specific features: i.e., I added RWG training to FANN
  describe '#train' do
    context 'with `:rwg` as algorithm' do
      let(:rwg_opts) { opts.merge({algo: :rwg, init_weights_range:[-5,5]}) }
      subject(:model) { described_class.new **rwg_opts }
      it_behaves_like DataModeler::Model # re-use the test
    end
  end

end
