# PrxAuth::Rails

Rails integration for next generation PRX Authorization system.

## Installation

Add this line to your application's Gemfile:

    gem 'prx_auth-rails'

And then execute:

    $ bundle

## Usage

Installing the gem in a Rails project will automatically add the appropriate Rack middleware to your Rails application and add two methods to your controllers. These methods are:

* `prx_auth_token`: returns a token (similar to PrxAuth::Token) which automatically namespaces queries. The main methods you will be interested in are `authorized?`, `globally_authorized?` and `resources`. More information can be found in PrxAuth.

* `prx_authenticated?`: returns whether or not this request includes a valid PrxAuth token.

### Configuration

In your rails app, add a file to config/initializers called `prx_auth.rb`:

```ruby
PrxAuth::Rails.configure do |config|

  # enables automatic installation of token parser middleware
  config.install_middleware = false # default: true

  # automatically adds namespace to all scoped queries, e.g. .authorized?(:foo) will be treated
  # as .authorized?(:my_great_ns, :foo). Has no impact on unscoped queries.
  config.namespace = :my_great_ns   # default: derived from Rails::Application name.
                                    #          e.g. class Feeder < Rails::Application => :feeder
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
