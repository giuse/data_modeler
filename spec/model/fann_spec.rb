
# Describe your model class
describe DataModeler::Model::FANN do
  # WARNING: your model needs to have 2 inputs and 1 output (will test on XOR)
  let(:netstruct) { [ 2, [2], 1 ] }
  # put the model in the subject, then call `it_behaves_like` as follows:
  subject(:model) { described_class.new netstruct, algo: :rprop, actfn: :sigmoid }
  # You get 5 tries to solve XOR in the number of generations you pass
  it_behaves_like DataModeler::Model, 100
end
