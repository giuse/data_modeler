require "bundler/setup"
require "data_modeler"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
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
