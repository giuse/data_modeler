# Example config

require 'data_modeler'

CONFIG = {
  data: {
    dir: 'spec/example',
    file: 'demo_ts.csv'
  },
  results: {
    save_models: true,
    dir: 'spec/example/tmp',
    id: DataModeler.id_from_filename(__FILE__)
  },
  tset: {
    input_series: %w[s1 s2],
    target_series: %w[s3],
    train_size: 10,
    test_size: 10,
    ntimes: 2,
    tspread: 1,
    look_ahead: 1
  },
  learner: {
    type: :fann,
    ngens: 80_000,
    hidden_layers: []
  }
}

# Run only if called directly (allows importing)
if __FILE__ == $0
  CONFIG[:learner][:ngens] = 5 if ARGV[0] == 'debug'  # quicker debug
  DataModeler.new(CONFIG).run
end
