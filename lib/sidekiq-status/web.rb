require "sidekiq/web"
require 'sidekiq-status/web/web_extension'

Sidekiq::Web.register Sidekiq::Status::WebExtension

if Sidekiq::Web.tabs.is_a?(Array)
  # For sidekiq < 2.5
  Sidekiq::Web.tabs << "status"
else
  Sidekiq::Web.tabs["Status"] = "status"
end