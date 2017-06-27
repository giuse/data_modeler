# Installation instructions

New to Ruby? Welcome! :)


## Obtaining Ruby

I handle my Rubies with RVM. Just head to [rvm.io](http://rvm.io) and follow the instructions.  
Windows users: you're probably better off with [The Ruby Installer](https://rubyinstaller.org/) for starters.


## Installing the gem

To manually install the gem, use the following command from your command line:

    $ gem install data_modeler

To include it in a Bundler-managed application, add this to your Gemfile:

```ruby
gem 'data_modeler'
```

And then execute:

    $ bundler

Bundler will keep your gemset coherent for the life of your application, if you're not using it already you should totally check it out at [bundler.io](http://bundler.io).


## Testing the installation

To test if everything installed correctly, launch an interactive Ruby console from the terminal with:

    $ irb

then try loading the gem

```ruby
  ruby> require 'data_modeler'
  # => true
```

If the command returns `true`, the gem is installed and available. You should be good to go!

Still, forstarters, I advice you to unpack a copy of the gem to play with. These commands will create an independent copy you can mess up with to no consequences:

    $ gem unpack data_modeler

Now get in, install the dependencies (did you check out [Bundler](http://bundler.io) as advised?), then run the tests and make sure everything works

    $ cd data_modeler
    $ bundle install
    $ rake

If the tests run green, you're sure everything is working correctly. There's a working configuration example + test data in `spec/example/config_01.rb`. Go ahead and try it:

    $ cd spec/example
    $ ruby config_01.rb

This will create a subfolder `01/` containing the results of the computation.

With this you should be ready to head back to the [README](README.md) for further instructions.

Enjoy!
