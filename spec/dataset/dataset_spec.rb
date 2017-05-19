
include DataModeler

describe Dataset do
  context 'when initialized with a timeseries hash' do
    # Definition in `spec_helper.rb`
    # { time: [1,2,..,9], s1: [10,11,..,18], .., s4: [40,41,..,48] }
    # data.size = 5 (=nseries+1), data.first.size = 9
    let(:data) { WithDataTable::DATA }

    context 'when building a simple static model' do
      let(:args) do
        { inputs: [:s1], targets: [:s2], first_idx: 2, end_idx: 4,
          ninput_points: 1, tspread: 0, look_ahead: 0 }
      end
      # NOTE: Datasets indices use with left inclusion and right exclusions,
      #       i.e. targets are considered in the range `[first_idx,end_idx)`
      subject(:ds) { described_class.new data, **args }

      describe '#inputs' do
        it { expect(ds.inputs).to eq [12] }
      end

      describe '#targets' do
        it { expect(ds.targets).to eq [22] }
      end

      describe '#next' do
        it 'increases the internal index' do
          expect { ds.next }.to change { ds.target_idx }.by(1)
        end
        it 'raises StopIteration when reaching end_idx' do
          expect { 3.times { ds.next } }.to raise_error(StopIteration)
        end
        it 'returns sequential data' do
          expect(ds.next).to eq [3,[12],[22]]
          expect(ds.next).to eq [4,[13],[23]]
        end
      end

      describe '#to_a' do
        let(:right) { [[3,[12],[22]],[4,[13],[23]]] }
        let(:wrong) { [[3,[12],[22]],[4,[13],[23]],[5,[14],[24]]] }
        subject { ds.to_a }
        it 'stops at end_idx' do
          is_expected.not_to eq wrong
          is_expected.to eq right
        end
      end
    end

    context 'when building a more complex model with longer dependancy and look-ahead' do
      # Starting from index 6 as target
      # 1: trg = i6(t7), in1 = i3(t4), in2 = i5(t6)
      # 2: trg = i7(t8), in1 = i4(t5), in2 = i6(t7)
      # first => idx trg(1) = 6
      # end => idx trg(2) + 1 = 8
      let(:args) do
        { inputs: [:s1,:s2], targets: [:s3,:s4], first_idx: 6, end_idx: 8,
          ninput_points: 2, tspread: 2, look_ahead: 1 }
      end
      let(:right) do
        [ # list of 2 entries, for trg(1) idx=6 and trg(2) idx=7
          [ # first entry for trg(1) idx = 6
            7,
            [ # inputs from s1 idx3, s2 idx3, s1 idx5, s2 idx5,
              13, 23, 15, 25
            ],
            [ # targets from s3 idx6, s4 idx 6
              36, 46
            ]
          ],
          [8,[14, 24, 16, 26],[37, 47]] # second entry for trg(2) idx = 7
        ]
      end
      subject(:ds) { described_class.new data, **args }

      describe '#to_a' do
        it { expect(ds.to_a).to eq right }
      end

    end
  end
end
