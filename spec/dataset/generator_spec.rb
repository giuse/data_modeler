
include DataModeler

describe Dataset::Generator do
  context 'when initialized with a timeseries hash' do
    # Definition in `spec_helper.rb`
    # { time: [1,2,..,9], s1: [10,11,..,18], .., s4: [40,41,..,48] }
    # data.size = 5 (=nseries+1), data.first.size = 9
    let(:data) { WithDataTable::DATA }

    context 'when building a simple static model' do
      let(:ds_args) do
        { inputs: [:s1], targets: [:s2],
          ninput_points: 1, tspread: 0, look_ahead: 0 }
      end
      # |win|train|ts|    # spacing for run 1
      #        |train|ts| # spacing for run 2
      # |win|ts|train|ts| # equivalent spacing run 2
      # We expect train2 to go from win+ts to win+ts+train
      # We expect test2 to go from win+ts+train to win+ts+train+test
      # NOTE: Datasets indices use with left inclusion and right exclusions,
      #       i.e. targets are considered in the range `[first_idx,end_idx)`
      subject(:gen) do
        described_class.new data, ds_args: ds_args, train_size: 2, test_size: 3
      end
      # Each train set consumes 2 indices, each test set 3
      # Hence, the `Dataset`s for the second run are expected to be:
      let(:nrun) { 2 }
      let(:ds_train) do
        Dataset.new data, **ds_args.merge(first_idx: 3, end_idx: 5)
      end
      let(:ds_test) do
        Dataset.new data, **ds_args.merge(first_idx: 5, end_idx: 8)
      end

      describe '#train' do
        it { expect(gen.train(nrun)).to eq ds_train }
      end

      describe '#test' do
        it { expect(gen.test(nrun)).to eq ds_test }
      end

      describe 'to_ds_a' do
        it { expect(gen.to_ds_a[nrun-1]).to eq [ds_train, ds_test] }
      end

      describe '#to_a' do
        # win: 0, train_size 2, test_size 3
        # idx:   012345678
        # data:  |--------|
        # run1:  |t|ts|   |
        # run2:  |  |t|ts||
        # run3: not enough data
        let(:right) do
          [ # list of pairs of datasets (train, test), one per run
            [ # first run: two datasets (train, test), each `#to_a`
              [ # train set for first run: list of 2 entries, for trg = 0, 1
                [ # first entry for trg=0: list of 3 entries: time, inputs, targets
                  1, # time for trg=0
                  [ # input from s1 idx0
                    10
                  ],
                  [ # target from s2 idx0
                    20
                  ]
                ],
                [2,[11],[21]] # second entry for trg=1
              ],
              [ # test set for first run: list of 3 entries, for trg = 2, 3, 4
                [3,[12],[22]],
                [4,[13],[23]],
                [5,[14],[24]]
              ]
            ],
            [ # second run, train idx in [3,4], test idx in[5,6,7]
              [ [4,[13],[23]],
                [5,[14],[24]] ],
              [ [6,[15],[25]],
                [7,[16],[26]],
                [8,[17],[27]] ]
            ]
          ]
        end
        it { expect(gen.to_a).to eq right }
      end

    end

    context 'when building a more complex model with longer dependancy and look-ahead' do
      # Starting from index 6 as target
      # 1: trg = i6(t7), in1 = i3(t4), in2 = i5(t6)
      # 2: trg = i7(t8), in1 = i4(t5), in2 = i6(t7)
      # first => idx trg(1) = 6
      # end => idx trg(2) + 1 = 8
      let(:ds_args) do
        { inputs: [:s1,:s2], targets: [:s3,:s4],
          ninput_points: 2, tspread: 2, look_ahead: 1 }
      end
      let(:sizes) { {train_size: 2, test_size: 3} }
      # win: tspread*(ninput_points-1) + l_a = 3, train_size 2, test_size 3
      # idx:   012345678
      # data:  |--------|
      # run1:  |ww|t|ts||
      # There's only data for one run, but it's ok here, we're testing the window
      let(:right) do
        [ # data for only one run: this runs list has only one element
          [ # first run: two datasets (train, test), each `#to_a`
            [ # train set for first run: list of 2 entries, for trg = 3, 4
              [ # first entry for trg=3: list of 3 entries: time, inputs, targets
                4, # time for trg=3
                [ # inputs from s1 idx0, s2 idx0, s1 idx2, s2 idx2
                  10, 20, 12, 22
                ],
                [ # targets from s3 idx3, s4 idx 3
                  33, 43
                ]
              ],
              [5,[11,21,13,23],[34,44]] # second entry for trg=4
            ],
            [ # test set for first run: list of 3 entries, for trg = 5, 6, 7
              [6,[12,22,14,24],[35,45]],
              [7,[13,23,15,25],[36,46]],
              [8,[14,24,16,26],[37,47]]
            ]
          ]
        ]
      end
      subject(:gen) do
        described_class.new data, ds_args: ds_args, **sizes
      end


      it { expect(gen.to_a).to eq right }
    end
  end
end
