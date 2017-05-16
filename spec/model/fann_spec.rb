
# Describe your model class
describe DataModeler::Model::FANN do
  # WARNING: your model needs to have 2 inputs and 1 output (will test on XOR)
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
  # You get 5 tries to solve XOR in the number of generations you pass
  it_behaves_like DataModeler::Model
end
