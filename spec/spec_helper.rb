$:.unshift File.expand_path('../../lib', __FILE__)

require "bundler"
require "rails"
Rails.env = "test"
Bundler.require(:default, Rails.env)
require 'action_controller/railtie'
require 'action_view/railtie'

app = Class.new(Rails::Application)
app.config.root = File.dirname(__FILE__)
app.config.secret_token = "3b7cd727ee24e8444053437c36cc66c4"
app.config.active_support.deprecation = :log
app.config.action_dispatch.show_exceptions = false

app.config.event_tracker.mixpanel_key = "YOUR_TOKEN"
app.config.event_tracker.kissmetrics_key = "KISSMETRICS_KEY"
app.config.event_tracker.google_analytics_key = "GOOGLE_ANALYTICS_KEY"

app.initialize!

app.routes.draw do
  get ':controller(/:action(/:id))'
end

class ApplicationController < ActionController::Base; end

require 'rspec/rails'

