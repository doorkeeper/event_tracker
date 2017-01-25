[![Build Status](https://travis-ci.org/doorkeeper/event_tracker.svg?branch=master)](https://travis-ci.org/doorkeeper/event_tracker)

# Event Tracker

Easy tracking using mixpanel, kissmetrics, or Google Analytics (universal analytics).

For details, see our guide to [tracking events](http://www.doorkeeperhq.com/developer/event-tracker-mixpanel-kissmetrics).

## Installation

Add this line to your application's Gemfile:

    gem 'event_tracker'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install event_tracker

## Usage

```ruby
# config/application.rb
config.event_tracker.mixpanel_key = "YOUR_KEY"
config.event_tracker.kissmetrics_key = "YOUR_KEY"
config.event_tracker.google_analytics_key = "YOUR_KEY"

class ApplicationController < ActionController::Base
  around_filter :append_event_tracking_tags

  # optionally identify users
  def mixpanel_distinct_id
    current_visitor_id
  end

  def mixpanel_name_tag
    current_user && current_user.email
  end

  def kissmetrics_identity
    current_user && current_user.email
  end
end

# in controller or views
track_event("Event Name", optional_property: "value")
register_properties(name: "value")
mixpanel_people_set( "property" => "value", "property" => "value")
```

## Todos

* AJAX handling
* External redirects

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
