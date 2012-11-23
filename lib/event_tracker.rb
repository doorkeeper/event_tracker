require "event_tracker/version"
require "event_tracker/mixpanel"

module EventTracker
  module ActionControllerExtension
    def track_event(event_name, args = {})
      (session[:event_tracker_queue] ||= []) << [event_name, args]
    end

    def register_properties(args)
      (session[:registered_properties] ||= {}).merge!(args)
    end

    def append_event_tracking_tags
      mixpanel_key = Rails.application.config.event_tracker.mixpanel_key
      return unless mixpanel_key

      body = response.body
      insert_at = body.index('</head')
      if insert_at
        registered_properties = session.delete(:registered_properties)
        event_tracker_queue = session.delete(:event_tracker_queue)
        distinct_id = respond_to?(:mixpanel_distinct_id) && mixpanel_distinct_id
        name_tag = respond_to?(:mixpanel_name_tag) && mixpanel_name_tag

        a = [ %q{<script type="text/javascript">} ]
        a << EventTracker::Mixpanel.init(mixpanel_key)
        a << EventTracker::Mixpanel.identify(distinct_id) if distinct_id
        a << EventTracker::Mixpanel.name_tag(name_tag) if name_tag
        a << EventTracker::Mixpanel.register(registered_properties) if registered_properties.present?
        a << EventTracker::Mixpanel.track(event_tracker_queue) if event_tracker_queue.present?
        a << %q{</script>}
        body.insert insert_at, a.join("\n")
        response.body = body
      end
    end

  end

  class Railtie < Rails::Railtie
    config.event_tracker = ActiveSupport::OrderedOptions.new
    initializer "event_tracker" do |app|
      ActiveSupport.on_load :action_controller do
        include ActionControllerExtension
      end
    end
  end
end
