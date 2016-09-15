# -*- encoding: utf-8 -*-
require File.expand_path('../lib/event_tracker/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Paul McMahon"]
  gem.email         = ["paul@mobalean.com"]
  gem.description   = %q{Easy integration with Mixpanel, Kissmetrics, and Google Analytics for Rails}
  gem.summary       = %q{Track using javascript from your controllers, even when redirecting}
  gem.homepage      = "http://www.doorkeeperhq.com/developer/event-tracker-mixpanel-kissmetrics"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "event_tracker"
  gem.require_paths = ["lib"]
  gem.version       = EventTracker::VERSION

  gem.add_dependency 'rails', '>= 3.0'
  gem.add_development_dependency 'capybara', '>= 2.1'
  gem.add_development_dependency 'rspec-rails'
end
