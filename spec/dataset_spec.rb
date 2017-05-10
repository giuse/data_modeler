
describe DataModeler::Dataset do
  context 'when initialized with a timeseries hash' do
    let(:data) do
      { time: [1,2,3,4,5], s1: [11,22,33,44,55], s2: [111,222,333,444,555] }
    end
    let(:args) do
      { inputs: [:s1], targets: [:s2], first_idx: 2, last_idx: 4,
        ntimes: 2, tspread: 1, look_ahead: 0 }
    end
    subject(:ds) { DataModeler::Dataset.new data, **args }

    describe '#inputs' do
      it { expect(ds.inputs).to eq [22,33] }
    end

    describe '#targets' do
      it { expect(ds.targets).to eq [333] }
    end

    describe '#next' do
      it 'increases the internal index' do
        expect { ds.next }.to change { ds.target_idx }.by(1)
      end
      it 'raises StopIteration when reaching last_idx' do
        expect { 3.times { ds.next } }.to raise_error(StopIteration)
      end
      it 'returns sequential data' do
        expect(ds.next).to eq [[22,33],[333]]
        expect(ds.next).to eq [[33,44],[444]]
      end
    end

    describe '#to_a' do
      let(:right) { [[[22,33],[333]],[[33,44],[444]]] }
      let(:wrong) { [[[22,33],[333]],[[33,44],[444]],[[44,55],[555]]] }
      subject { ds.to_a }
      it 'stops at last_idx' do
        is_expected.not_to eq wrong
        is_expected.to eq right
      end
    end

  end
end
