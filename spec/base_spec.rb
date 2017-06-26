
describe DataModeler::Base do
  before(:all) do
    # this config can be used as an example to create your own experiments
    load Pathname.new(__FILE__).dirname.join 'example', 'config_01.rb'
    @tmp_dir = Pathname.new CONFIG[:data][:results_dir]
    FileUtils.mkdir_p @tmp_dir || abort("Cannot create `#{CONFIG[:data][:results_dir]}`")
  end
  after(:all) { FileUtils.rm_rf @tmp_dir if @tmp_dir }

  let(:res_dir) { @tmp_dir.join CONFIG[:data][:exp_id] }
  subject(:modeler) { described_class.new CONFIG }

  it '#run', retry: 100 do
    # use this to verify per-run printout
    # modeler.run report_interval: (CONFIG[:learner][:ngens]/2)
    modeler.run report_interval: false
    output_files = Pathname.glob res_dir.join('*')
    expect(output_files.size).to eq 6 # 3 models, 3 tpredobs
    result_files = output_files.select { |f| f.to_s =~ /tpredobs_\d+.csv/ }
    results = result_files.flat_map do |f|
      headers, *data = CSV.read(f, converters: :float)
      data
    end
    residuals = results.collect { |(t, pr, ob)| (pr-ob).abs }
    avg_res = residuals.reduce(:+) / residuals.size
    expect(avg_res).to be < 0.3
  end
end
