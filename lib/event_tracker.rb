require "event_tracker/version"
require "event_tracker/integration"
require "event_tracker/integration/base"
require "event_tracker/integration/mixpanel"
require "event_tracker/integration/kissmetrics"
require "event_tracker/integration/google_analytics"

module EventTracker
  module HelperMethods
    def track_event(event_name, args = {})
      (session[:event_tracker_queue] ||= []) << [event_name, args]
    end

    def register_properties(args)
      (session[:registered_properties] ||= {}).merge!(args)
    end

    def mixpanel_set_config(args)
      (session[:mixpanel_set_config] ||= {}).merge!(args)
    end

    def mixpanel_people_set(args)
      (session[:mixpanel_people_set] ||= {}).merge!(args)
    end

    def mixpanel_people_set_once(args)
      (session[:mixpanel_people_set_once] ||= {}).merge!(args)
    end

    def mixpanel_people_increment(event_name)
      (session[:mixpanel_people_increment] ||= []) << event_name
    end

    def mixpanel_alias(identity)
      session[:mixpanel_alias] = identity
    end
  end

  module ActionControllerExtension
    def append_event_tracking_tags
      event_trackers = EventTracker::Integration.configured
      yield
      return if event_trackers.empty?

      body = response.body
      head_insert_at = body.index('</head')
      return unless head_insert_at

      body.insert head_insert_at, view_context.javascript_tag(event_trackers.map {|t| t.init }.join("\n"))
      body_insert_at = body.index('</body')
      return unless body_insert_at

      a = []
      registered_properties = session.delete(:registered_properties)
      event_tracker_queue = session.delete(:event_tracker_queue)

      event_trackers.each do |tracker|
        if tracker.is_a?(EventTracker::Integration::Mixpanel)
          if mixpanel_alias = session.delete(:mixpanel_alias)
            a << tracker.alias(mixpanel_alias)
          elsif distinct_id = respond_to?(:mixpanel_distinct_id, true) && mixpanel_distinct_id
            a << tracker.identify(distinct_id)
          end

          if name_tag = respond_to?(:mixpanel_name_tag, true) && mixpanel_name_tag
            a << tracker.name_tag(name_tag)
          end

          if (config = session.delete(:mixpanel_set_config)).present?
            a << tracker.set_config(config)
          end

          if (people = session.delete(:mixpanel_people_set)).present?
            a << tracker.people_set(people)
          end

          if (people = session.delete(:mixpanel_people_set_once)).present?
            a << tracker.people_set_once(people)
          end

          if (people = session.delete(:mixpanel_people_increment)).present?
            a << tracker.people_increment(people)
          end
        elsif tracker.is_a?(EventTracker::Integration::Kissmetrics)
          if identity = respond_to?(:kissmetrics_identity, true) && kissmetrics_identity
            a << tracker.identify(identity)
          end
        end

        a << tracker.register(registered_properties) if registered_properties.present? && tracker.respond_to?(:register)

        if event_tracker_queue.present?
          event_tracker_queue.each do |event_name, properties|
            a << tracker.track(event_name, properties)
          end
        end
      end

      body.insert body_insert_at, view_context.javascript_tag(a.join("\n"))
      response.body = body
    end

  end

  class Railtie < Rails::Railtie
    config.event_tracker = ActiveSupport::OrderedOptions.new
    initializer "event_tracker" do |app|
      ActiveSupport.on_load :action_controller do
        include ActionControllerExtension
        include HelperMethods
        helper HelperMethods if respond_to?(:helper)
      end
    end
  end
end
