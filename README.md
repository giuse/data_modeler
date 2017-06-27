
# [Data Modeler](https://github.com/giuse/data_modeler)


[![Gem Version](https://badge.fury.io/rb/data_modeler.svg)](https://badge.fury.io/rb/data_modeler)
[![Build Status](https://travis-ci.org/giuse/data_modeler.svg?branch=master)](https://travis-ci.org/giuse/data_modeler)
[![Code Climate](https://codeclimate.com/github/giuse/data_modeler/badges/gpa.svg)](https://codeclimate.com/github/giuse/data_modeler)


#### Using machine learning, create generative models based on your data alone. Applications span from prediction to imputation and compression.


## Installation

Add `gem 'data_modeler'` to your Gemfile then `$ bundle`, or install manually with `$ gem install data_modeler`.

If you're new to Ruby or Bundler, check these detailed [installation instructions](installation.md) first.


## Full documentation

I wish for my code to stay well documented. If you find the documentation lacking or outdated, please do let me know. You can find it [here](http://www.rubydoc.info/gems/data_modeler/).


## Getting started


### Obtaining a working configuration on example data

Make a copy of [`/spec/example`](spec/example) for you to play with.
The `config*.rb` files are configuration examples. The configuration is written in a simple  Ruby `Hash`, and the files themselves can be directly executed with (i.e. run `ruby config_01.rb`) thanks to the few lines at the bottom.

The `.csv` files are examples of the format the data must be pre-processed into beforehand: a CSV table with a numeric time as first column, followed by one column for each of the time series available. The data should be complete (i.e. no missing values) and already normalized (depending on the model of choice). The file [`prepare_demo_csv`](spec/example/prepare_demo_csv.rb) can help you getting started on the task, as it was used to generate the demo CSV.

Start by just running one of the configurations, then play around with the config and customize them to your taste. And off you go!


### Understanding the results

Running a config file will create a folder holding the results; the path can be customized in the config file.  
Note that `DataModeler#id_from` returns a numeric ID from the end of a string (e.g. file name), saving you from forgetting to update the output folder after creating a new config by copy.

Inside the results folder you will find a result file (CSV) for each run. They follow the naming convention `tpredobs_<nrun>.csv` as to remind their internal structure:

- First column is `time` and contains the timestamp of each target in the original data
- Then come all the columns relative to predictions
    - The naming pattern `p_<series name>` corresponds to the predicted values for series named "series name" in the original data.
- Then come all the columns relative to observations
    - The naming pattern `o_<series name>` corresponds to the observed values for series named "series name" in the original data.

Loading this raw result data allows for easy calculation of residuals and statistics, and to plot your predictions against the ground truth.


### Customizing your experiment

Outdated documentation is often worse than lack of documentation. To understand all configuration options, consider the following:

- All configuration keys but the last refer to the data: where to find the original data, where to save the results, and how to build the train/test sets. I guarantee there will be no default value for these configurations, making it necessary for all the options to be explicitly declared in all `config` files. So everything you find there is everything there is.

- The (usually) last configuration key is named `:learner` and is model dependent, totally flexible.
Its (usually) first key is `:type`: you will find a model of the same(ish) name in the folder [`lib/data_modeler/model`](lib/data_modeler/model). The initializer of this class receives the `:learner` sub-configuration hash minus the key `:type` (already consumed to select the model).

This means that to know all available options you should rely on a previous config file, plus to the documentation (or implementation) of the `initialize` function of the model of choice (should be small).


### Leveraging time series data

There are three settings under `:tset` in the config which may be cryptic: `ninput_points`, `tspread` and `look_ahead`. Names can change in the future as I found it hard to name these three, please open an issue if I forget to modify this (or if you have suggestions).

If you don't work with time series, just set them to [1,0,0], use a line counter for `time`, and ignore the following. These three only make sense if the data is composed of aligned time series, with a numeric column `time` -- its unit will also be the unit for `tspread` and `look_ahead`. 

- ninput_points: how many points in time to construct the model's input. For example, if the number is 3, then data coming from 3 data lines is considered.
- tspread: time spread between the data lines considered in the point above. For example, if the number is 2, then the data lines considered will have (at least) 2 time (units) between each other.
- look_ahead: span between the most recent input considered and the target to be learned. For example, if the number is 5, then the target will be constructed from a data line which is (at least) 5 time (units) later than the most recent input.

Example configurations:

- ninput_points = 1, tspread = 0, look_ahead = 0 -> build input from one line, no spreading, predict results in same line. This is the basic configuration allowing same-timestep prediction, e.g. for static modeling or simple data imputation.
- ninput_points = 4, tspread = 7, look_ahead = 7 -> hypothesize the unit of the column `time` to be days: build input from 4 lines spanning 21 days at one-week intervals (+ current), then use it to learn to predict one week ahead. This allows to train a proper time-ahead predictor, which will estimate the target at a constant one-week ahead interval.
- ninput_points = 30, tspread = 1, look_ahead = 1 -> hypothesize the unit of the column `time` to be seconds: train a real-time predictor estimating a behavior one-second ahead based on 1s-spaced data over the past 29 seconds + current.

Important: from each line, only the data coming from the listed input time series is considered for input, while the target time series list is used to construct the output.

Example inputs and targets, considering t0 the "current" time for a given iteration:

- ninput_points = 1, tspread = 0, look_ahead = 0, input_series = [s1, s4], targets = [s3]: inputs -> [s1t0, s2t0], targets = [s3t0]
- ninput_points = 4, tspread = 7, look_ahead = 7, input_series = [s1, s4], targets = [s3, s5]: inputs -> [s1t-21, s2t-21, s1t-14, s2t-14, s1t-7, s2t-7, s1t0, s2t0], targets = [s3t0, s5t0]


## Contributing


### Suggestions / requests

Feel free to open new issues. I mean it. We can work together from there.


### Adding new models

This system has by design a plug-in architecture. To add your own models, you just need to create a new wrapper in `lib/data_modeler/model`:

- Duplicate the `fann.rb` model: it provides both instructions and template for the interface you need to present to the system
- Duplicate the `spec/model/fann_spec.rb` spec: it will provide instructions on how to verify your model works with the system using some ready `shared_examples`.

Ideally, a `DataModeler::Model` should be a wrapper around an external independent functionality: keep it as compact as possible. To implement the interface you can use BDD on the `spec`, which verifies both the availability of the interface and basic modeling capabilities. 

Remember to update [`lib/data_modeler.rb`](lib/data_modeler.rb) to load your file, and add an option to select it in [`lib/data_modeler/model/selector.rb`](lib/data_modeler/model/selector.rb)

THEN: please do propose a pull requests! Share your work with the community!  
Even if you think it's not polished enough: I'll help out before accepting.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


## Notes

This build specifically leverages time series. Further work on data preparation will be released as a separate project.
