if defined?(Rails.application.config.assets)
  Rails.application.config.assets.precompile << %w[prx_auth-rails_manifest.js]
end
