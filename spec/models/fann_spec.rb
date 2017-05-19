

######################
# MODEL TEST EXAMPLE #
######################

# To verify your model works with the framework, copy the lines below and
# adapt them to your model
YOUR_MODEL = DataModeler::Models::FANN

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
  # You get 5 tries to solve XOR in the number of generations you pass
  it_behaves_like DataModeler::Models

##########################
# MODEL TEST EXAMPLE end #
##########################


# now you can continue unit-testing your model

  context 'faced with a nonlinear problem' do
    # XOR problem dataset
    let(:data) do
      [ [1,[0,0],[1]],
        [2,[0,1],[0]],
        [3,[1,0],[0]],
        [4,[1,1],[1]] ]
    end
    # one for both train&test (no need for precision here)
    let(:tset) { [:time, :input, :target].zip(data.transpose).to_h }

    # just make sure it's working, no need for precision here
    it 'consistently models XOR', retry: 5 do
      model.train tset, report_interval: 0
      predictions = model.test tset[:input]
      observations = tset[:target]
      residuals = predictions.zip(observations).map { |(pr),(ob)| (pr-ob).abs }
      avg_res = residuals.reduce(:+) / predictions.size
      expect(avg_res).to be < 0.3
    end
  end

  describe '#train' do
    context 'with `:rwg` as algorithm' do
      let(:rwg_opts) { opts.merge({algo: :rwg, init_weights_range:[-5,5]}) }
      subject(:model) { described_class.new **rwg_opts }
      it_behaves_like DataModeler::Models # re-use the test
    end
  end
end
