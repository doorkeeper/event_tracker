require "event_tracker/version"
require "event_tracker/mixpanel"
require "event_tracker/kissmetrics"

module EventTracker
  module HelperMethods
    def track_event(event_name, args = {})
      (session[:event_tracker_queue] ||= []) << [event_name, args]
    end

    def register_properties(args)
      (session[:registered_properties] ||= {}).merge!(args)
    end
  end

  module ActionControllerExtension
    def append_event_tracking_tags
      mixpanel_key = Rails.application.config.event_tracker.mixpanel_key
      kissmetrics_key = Rails.application.config.event_tracker.kissmetrics_key
      return unless mixpanel_key || kissmetrics_key

      body = response.body
      insert_at = body.index('</head')
      if insert_at
        trackers = []

        a = []
        if mixpanel_key
          trackers << EventTracker::Mixpanel
          distinct_id = respond_to?(:mixpanel_distinct_id) && mixpanel_distinct_id
          name_tag = respond_to?(:mixpanel_name_tag) && mixpanel_name_tag
          a << EventTracker::Mixpanel.init(mixpanel_key)
          a << EventTracker::Mixpanel.identify(distinct_id) if distinct_id
          a << EventTracker::Mixpanel.name_tag(name_tag) if name_tag
        end

        if kissmetrics_key
          trackers << EventTracker::Kissmetrics
          identity = respond_to?(:kissmetrics_identity) && kissmetrics_identity
          a << EventTracker::Kissmetrics.init(kissmetrics_key)
          a << EventTracker::Kissmetrics.identify(identity) if identity
        end

        registered_properties = session.delete(:registered_properties)
        event_tracker_queue = session.delete(:event_tracker_queue)

        trackers.each do |tracker|
          a << tracker.register(registered_properties) if registered_properties.present?

          if event_tracker_queue.present?
            event_tracker_queue.each do |event_name, properties|
              a << tracker.track(event_name, properties)
            end
          end
        end
        body.insert insert_at, view_context.javascript_tag(a.join("\n"))
        response.body = body
      end
    end

  end

  class Railtie < Rails::Railtie
    config.event_tracker = ActiveSupport::OrderedOptions.new
    initializer "event_tracker" do |app|
      ActiveSupport.on_load :action_controller do
        include ActionControllerExtension
        include HelperMethods
        helper HelperMethods
      end
    end
  end
end
