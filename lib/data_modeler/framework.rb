# TODO: use fastestcsv if available
require 'csv'

# Base class, core of the DataModeler framework.
# - Initializes the system based on the config
# - Runs over the data training and testing models
# - Results and models are saved to the file system
class DataModeler::Framework

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
    @save_models = config[:data].delete :save_models

    @data = load_data config[:data].delete :input_file
    @out_dir = prepare_output config[:data]

    @tset_gen = DataModeler::Dataset::Generator.new data, **opts_for(:dataset_gen)
    @model = DataModeler::Model.selector **opts_for(:learner)
  end

  # Main control: up to `nruns` (or until end of data) loop train-test-save
  # @param report_interval [Integer] interval at which to print to stdout
  #     (in number of generations) -- will be passed to the `Model`
  # @return [void]
  # @note saves model, preds and obs to the file sistem at the end of each run
  def run report_interval: 1000
    printing = report_interval && report_interval > 0
    over_nruns = nruns == Float::INFINITY ? "" : "/#{nruns}"
    puts "\nStarting @ #{Time.now}\n#{self}" if printing
    1.upto(nruns) do |nrun|
      begin
        train_set = tset_gen.train(nrun)
      rescue DataModeler::Dataset::Generator::NoDataLeft
        break # there's not enough data left for a train+test set pair
      end
      puts "\nRun #{nrun}#{over_nruns} -- starting @ #{Time.now}" if printing
      model.reset
      puts "-Training" if printing
      model.train train_set, report_interval: report_interval
      puts "-Testing" if printing
      times, test_input, observations = tset_gen.test(nrun).values
      predictions = model.test test_input
      puts "-Saving" if printing
      save_run nrun, model, [times, predictions, observations]
      puts "Run #{nrun}#{over_nruns} -- ending @ #{Time.now}" if printing
    end
    puts "\nDone! @ #{Time.now}" if printing
  end

  # Attribute reader for instance variable `@save_models`, ending in '?' since
  # it's a boolean value.
  # @return [true|false] value of instance variable @save_models
  #    (false if nil/uninitialized)
  def save_models?
    @save_models || false
  end

  # @return [String]
  def to_s
    config.to_s
  end

  private

  # Loads the data in a Hash ready for `DatasetGen` (and `Dataset`)
  # @param file [String/fname] path to the file containing the data (from `config`)
  # @return [Hash] the data ready for access
  def load_data filename
    filename = Pathname.new filename
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
  def prepare_output results_dir:, exp_id:
    Pathname.new(results_dir).join(exp_id).tap { |path| FileUtils.mkdir_p path }
  end

  # Compatibility helper, preparing configuration hashes for different classes
  # @param whom [Symbol] which class are you preparing the config for
  # @return [Hash] configuration for the class as required
  def opts_for whom
    case whom
    when :dataset_gen
      { ds_args: opts_for(:dataset),
        train_size: config[:tset][:train_size],
        test_size: config[:tset][:test_size]
      }
    when :dataset
      { inputs: inputs,
        targets:  targets,
        ninput_points: config[:tset][:ninput_points],
        tspread: config[:tset][:tspread],
        look_ahead: config[:tset][:look_ahead]
      }
    when :learner
      config[:learner].merge({
        ninputs: (config[:tset][:ninput_points] * inputs.size),
        noutputs: targets.size
      })
    else abort "Unrecognized `whom`: '#{whom}'"
    end
  end

  # Save a run's results on the file system
  # @param nrun [Integer] the curent run number (used as id for naming)
  # @param model [Model] the model trained in the current run
  # @param predobs [Array<Array<pred, obs>>] list of prediction-observation pairs
  # @return [void]
  # @note side effect: saves model and predobs to file system
  def save_run nrun, model, tpredobs
    run_id = format '%02d', nrun
    model.save out_dir.join("model_#{run_id}.sav") if save_models?
    CSV.open(out_dir.join("tpredobs_#{run_id}.csv"), 'wb') do |csv|
      csv << (%w(time) + targets.collect { |t| ["p_#{t}", "o_#{t}"] }.transpose.flatten)
      tpredobs.transpose.each { |tpo| csv << tpo.flatten }
    end
  end
end
