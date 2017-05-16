
describe DataModeler::Base do
  before(:all) do
    # this config can be used as an example to create your own experiments
    load Pathname.new(__FILE__).dirname.join 'example', 'config_01.rb'
    @tmp_dir = Pathname.new CONFIG[:results][:dir]
    FileUtils.mkdir_p @tmp_dir
  end
  after(:all) { FileUtils.rm_rf @tmp_dir }

  let(:res_dir) { @tmp_dir.join CONFIG[:results][:id] }
  subject(:modeler) { described_class.new CONFIG }

  it '#run', retry: 5 do
    modeler.run report_interval: 0
    output_files = Pathname.glob res_dir.join('*')
    expect(output_files.size).to eq 6 # 3 models, 3 predobs
    result_files = output_files.select { |f| f.to_s =~ /predobs_\d+.csv/ }
    results = result_files.flat_map do |f|
      headers, *data = CSV.read(f, converters: :float)
      data
    end
    residuals = results.collect { |(pr, ob)| (pr-ob).abs }
    avg_res = residuals.reduce(:+) / residuals.size
    expect(avg_res).to be < 0.3
  end
end
