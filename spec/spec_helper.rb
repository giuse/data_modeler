require "bundler/setup"
require "rspec/retry"
require "data_modeler"

# Shared examples
Dir["./spec/shared_examples_for_*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Enforce new expectation syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Show rspec-retry status in spec process
  config.verbose_retry = true
end

# Keep at hand basic (small) data shared between tests
module DatasetSpecHelper
  DATA = begin
    table = [
      # Keep time and indices different to spot for bugs
      # TODO: unregular time
      [:time, :s1, :s2, :s3, :s4 ], # data indices (rows):
      [    1,  10,  20,  30,  40 ], # 0
      [    2,  11,  21,  31,  41 ], # 1
      [    3,  12,  22,  32,  42 ], # 2
      [    4,  13,  23,  33,  43 ], # 3
      [    5,  14,  24,  34,  44 ], # 4
      [    6,  15,  25,  35,  45 ], # 5
      [    7,  16,  26,  36,  46 ], # 6
      [    8,  17,  27,  37,  47 ], # 7
      [    9,  18,  28,  38,  48 ]  # 8
    ]
    headers, *values = table
    headers.zip(values.transpose).to_h
  end
end

# Helper functions

# Silence chatty functions in test (or at least try to...)
def silenced stream=STDOUT
  abort "Pass what you would like to run as a block" unless block_given?
  old = stream.dup
  stream.reopen File::NULL
  yield
ensure
  stream.sync = true
  stream.reopen(old)
end
