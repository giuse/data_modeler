# TODO: use fastestcsv if available
require 'csv'

# Base class, core of the DataModeler framework.
# - Initializes the system based on the config
# - Runs over the data training and testing models
# - Results and models are saved to the file system
class DataModeler::Base

  attr_reader :config, :inputs, :targets, :train_size, :test_size,
              :nruns, :data, :out_dir, :tset_gen, :model

  # @param config [Hash] configuration hash for the whole experiment setup
  def initialize config
    @config = config
    @inputs = config[:tset][:input_series].map! &:to_sym
    @targets =  config[:tset][:target_series].map! &:to_sym
    @train_size = config[:tset][:train_size]
    @test_size = config[:tset][:test_size]
    @nruns = config[:tset][:nruns] ||= Float::INFINITY # terminates with data
    @save_models = config[:results].delete :save_models

    @data = load_data config[:data]
    @out_dir = prepare_output config[:results]

    @tset_gen = DataModeler::DatasetGen.new data, **opts_for(:datasetgen)
    @model = DataModeler::Model.from_conf **opts_for(:learner)
  end

  # Main control: up to `nruns` (or until end of data) loop train-test-save
  # @param report_interval [Integer] interval at which to print to stdout
  #     (in number of generations) -- will be passed to the `Model`
  # @return [void]
  # @note saves model, preds and obs to the file sistem at the end of each run
  def run report_interval: 1000
    1.upto(nruns) do |nrun; predictions, observations| # block-local variables
      begin
        train_set = tset_gen.train(nrun)
      rescue DataModeler::DatasetGen::NoDataLeft
        # will check if there's enough data for both train&test
        break
      end
      model.reset
      model.train train_set, report_interval: report_interval
      test_input, observations = tset_gen.test(nrun).values
      predictions = model.test test_input
      save_run nrun, model, [predictions, observations]
    end
  end

  # Attribute reader for instance variable `@save_models`, ending in '?' since
  #    it's a boolean value.
  # @return [true|false] value of instance variable @save_models
  #    (false if nil/uninitialized)
  def save_models?
    @save_models || false
  end

  private

  # Loads the data in a Hash ready for `DatasetGen` (and `Dataset`)
  # @param dir [String/path] directory where to find the data (from `config`)
  # @param file [String/fname] name of the file containing the data (from `config`)
  # @return [Hash] the data ready for access
  def load_data dir:, file:
    filename = Pathname.new(dir).join(file)
    abort "Only CSV data for now, sorry" unless filename.extname == '.csv'
    # avoid loading data we won't use
    series = [:time] + inputs + targets
    csv_opts = { headers: true, header_converters: :symbol, converters: :float }
    Hash.new { |h,k| h[k] = [] }.tap do |data|
      CSV.foreach(filename, **csv_opts) do |row|
        series.each { |s| data[s] << row[s] }
      end
    end
  end

  # Prepares a directory to hold the output of each run
  # @param dir [String/path] directory where to save the results (from `config`)
  # @param id [String/fname] id of current config/experiment (from `config`)
  # @return [void]
  # @note side effect: creates directories on file system to hold output
  def prepare_output dir:, id:
    Pathname.new(dir).join(id).tap { |path| FileUtils.mkdir_p path }
  end

  # Compatibility helper, preparing configuration hashes for different classes
  # @param who [Symbol] which class are you preparing the config for
  # @return [Hash] configuration for the class as required
  def opts_for who
    case who
    when :datasetgen
      { ds_args: opts_for(:dataset),
        train_size: config[:tset][:train_size],
        test_size: config[:tset][:test_size]
      }
    when :dataset
      { inputs: inputs,
        targets:  targets,
        ntimes: config[:tset][:ntimes],
        tspread: config[:tset][:tspread],
        look_ahead: config[:tset][:look_ahead]
      }
    when :learner
      config[:learner].merge({
        ninputs: (config[:tset][:ntimes] * inputs.size),
        noutputs: targets.size
      })
    else abort "Unrecognized `who`: '#{who}'"
    end
  end

  # Save a run's results on the file system
  # @param nrun [Integer] the curent run number (used as id for naming)
  # @param model [Model] the model trained in the current run
  # @param predobs [Array<Array<pred, obs>>] list of prediction-observation pairs
  # @return [void]
  # @note side effect: saves model and predobs to file system
  def save_run nrun, model, predobs
    run_id = format '%02d', nrun
    model.save out_dir.join("model_#{run_id}.sav") if save_models?
    CSV.open(out_dir.join("predobs_#{run_id}.csv"), 'wb') do |csv|
      csv << targets.collect { |t| ["p_#{t}", "o_#{t}"] }.transpose.flatten
      predobs.transpose.each { |po| csv << po.flatten }
    end
  end
end
