

### VERY IMPORTANT: `model` needs to be initialized with 2 inputs and 1 output

# To validate your model works within the framework,
# initialize one in the subject (named :model) like this:
# `subject(:model) { described_class.new your_options }`
# then test for:
# `it_behaves_like Dataset::Model ngens`


# Shared examples for models
# See `spec/model/fann_spec.rb` for my original example
shared_examples DataModeler::Model do |ngens|
  # context 'with correct initialization' do
    let(:data) do
      # XOR problem dataset
      [ [[0,0],[1]],
        [[0,1],[0]],
        [[1,0],[0]],
        [[1,1],[1]] ]
    end
    # one for both train&test (no need for precision here)
    let(:tset) { [:input, :target].zip(data.transpose).to_h }

    it 'presents the correct interface' do
      is_expected.to respond_to(:reset).with(0).arguments
      is_expected.to respond_to(:train).
        with(1..2).arguments.  # trainset, ngens
        and_keywords(:report_interval, :desired_error)
      is_expected.to respond_to(:test).with(1).argument       # inputs
      is_expected.to respond_to(:save).with(1).argument       # filename
    end

    # just make sure it's working, no need for precision here
    it 'consistently models XOR', retry: 5 do
      model.train tset, report_interval: 0
      predictions = model.test tset[:input]
      observations = tset[:target]
      residuals = predictions.zip(observations).map { |(pr),(ob)| (pr-ob).abs }
      avg_res = residuals.reduce(:+) / predictions.size
      expect(avg_res).to be < 0.3
    end
  # end
end
