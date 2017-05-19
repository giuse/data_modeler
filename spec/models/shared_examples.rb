

### VERY IMPORTANT: your `Model` needs to be initialized with 2 inputs and 1 output

# See an example usage (to copy!) in `spec/fann_spec.rb`

# Shared examples for models
shared_examples DataModeler::Models do |ngens|
  context 'with correct initialization' do
    # linearly correlated real data
    let(:data) do
      [ [1,[1.0,0.905],[0.951]],
        [2,[0.974,0.943],[0.952]],
        [3,[0.937,0.971],[0.968]],
        [4,[0.927,0.958],[0.985]],
        [5,[0.944,0.915],[1.0]],
        [6,[0.932,0.919],[0.996]],
        [7,[0.927,0.938],[0.937]],
        [8,[0.944,0.957],[0.967]],
        [9,[0.965,0.98],[0.966]]
      ]
    end
    # one for both train&test (not testing model generalization here)
    let(:tset) { [:time, :input, :target].zip(data.transpose).to_h }

    it 'presents the correct interface' do
      is_expected.to respond_to(:reset).with(0).arguments
      is_expected.to respond_to(:train)
        .with(1..2).arguments                              # trainset, ngens
        .and_keywords(:report_interval, :desired_error)    # plus keys
      is_expected.to respond_to(:test).with(1).argument    # inputs
      is_expected.to respond_to(:save).with(1).argument    # filename
    end

    # just make sure it's working, no need for precision here
    it 'consistently models the data', retry: 5 do
      model.train tset, report_interval: 0
      predictions = model.test tset[:input]
      observations = tset[:target]
      residuals = predictions.zip(observations).map { |(pr),(ob)| (pr-ob).abs }
      avg_res = residuals.reduce(:+) / predictions.size
      expect(avg_res).to be < 0.3
    end
  end
end
