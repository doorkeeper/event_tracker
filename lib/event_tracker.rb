require "event_tracker/version"
require "active_support/concern"

module EventTracker
  module ActionControllerExtension
    def track_event(event_name, args = {})
      (session[:event_tracker_queue] ||= []) << [event_name, args]
    end

    def register_property(name, value)
      (session[:registered_properties] ||= {})[name] = value
    end

    def append_event_tracking_tags
      body = response.body
      insert_at = body.index('</head')
      if insert_at
        body.insert insert_at, event_tracking_tag
        response.body = body
      end
    end

    def event_tracking_tag
      registered_properties = session.delete(:registered_properties)
      event_tracker_queue = session.delete(:event_tracker_queue)
      identity = respond_to?(:event_tracker_identity) && event_tracker_identity 

      s = %q{<script type="text/javascript">}
      s << <<-EOD
        (function(c,a){window.mixpanel=a;var b,d,h,e;b=c.createElement("script");
        b.type="text/javascript";b.async=!0;b.src=("https:"===c.location.protocol?"https:":"http:")+
        '//cdn.mxpnl.com/libs/mixpanel-2.1.min.js';d=c.getElementsByTagName("script")[0];
        d.parentNode.insertBefore(b,d);a._i=[];a.init=function(b,c,f){function d(a,b){
        var c=b.split(".");2==c.length&&(a=a[c[0]],b=c[1]);a[b]=function(){a.push([b].concat(
        Array.prototype.slice.call(arguments,0)))}}var g=a;"undefined"!==typeof f?g=a[f]=[]:
        f="mixpanel";g.people=g.people||[];h=['disable','track','track_pageview','track_links',
        'track_forms','register','register_once','unregister','identify','name_tag',
        'set_config','people.identify','people.set','people.increment'];for(e=0;e<h.length;e++)d(g,h[e]);
        a._i.push([b,c,f])};a.__SV=1.1;})(document,window.mixpanel||[]);
        mixpanel.init("#{Rails.application.config.event_tracker.mixpanel_key}");
      EOD
      s << %Q{mixpanel.register(#{registered_properties.to_json})\n} unless registered_properties.blank?
      s << event_tracker_queue.map {|event_name, properties| event_call(event_name, properties) }.join("\n") if event_tracker_queue
      s << %Q{mixpanel.identify(#{identity.to_json})} if identity
      s << %Q{</script>}
    end

    def event_call(event_name, properties)
      s = properties.empty? ? "" : ", #{properties.to_json}"
      %Q{mixpanel.track("#{event_name}"#{s});}
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
