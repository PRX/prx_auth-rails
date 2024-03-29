# PrxAuth::Rails

Rails integration for next generation PRX Authorization system. This
provides common OpenId authorization patterns used in PRX apps.

## Installation

Add this line to your application's Gemfile:

    gem 'prx_auth-rails'

And then execute:

    $ bundle

## Usage

Installing the gem in a Rails project will automatically add the
appropriate Rack middleware to your Rails application and add two
methods to your controllers. These methods are:

* `prx_auth_token`: returns a token (similar to PrxAuth::Token) which
  automatically namespaces queries. The main methods you will be
interested in are `authorized?`, `globally_authorized?` and `resources`.
More information can be found in PrxAuth.

* `prx_authenticated?`: returns whether or not this request includes a
  valid PrxAuth token.

This will let set up the Rails app to be ready for HTTP requests
associated with an OpenId access token.

### Configuration

Generally, configuration is not required and the gem aims for great
defaults, but you can override some settings if you need to change the
default behavior.

If you're using the Rails server-side session flow, you must supply the
client_id via configuration.

In your rails app, add a file to config/initializers called
`prx_auth.rb`:

```ruby
PrxAuth::Rails.configure do |config|

  # enables automatic installation of token parser middleware
  config.install_middleware = true # default: true

  # set the ID host
  config.id_host = 'id.staging.prx.tech' # default: id.prx.org

  # automatically adds namespace to all scoped queries, e.g. .authorized?(:foo) will be treated
  # as .authorized?(:my_great_ns, :foo). Has no impact on unscoped queries.
  config.namespace = :my_great_ns   # default: derived from Rails::Application name.
                                    #          e.g. class Feeder < Rails::Application => :feeder

  # Set up the PRX OpenID client_id if using the backend rails sessions flow.
  config.client_id = '<some client id>'
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
