require "event_tracker/version"
require "active_support/concern"

module EventTracker
  module ActionControllerExtension
    extend ActiveSupport::Concern
    module ClassMethods
      def tracks_event
        after_filter :append_event_tracking_tags
      end
    end

    def track_event(event_name, args = {})
      event_tracker_queue << [event_name, args]
    end

    def register_property(name, value)
      registered_properties[name] = value
    end

    def append_event_tracking_tags
      body = response.body
      insert_at = body.index('</head')
      if insert_at
        body.insert insert_at, event_tracking_tag
        response.body = body
      end
    end

    def event_tracker_queue
      session[:event_tracker_queue] ||= []
    end

    def registered_properties
      session[:registered_properties] ||= {}
    end

    def event_tracking_tag
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
        mixpanel.init("YOUR_TOKEN");
      EOD
      s << %Q{mixpanel.register(#{registered_properties.to_json})\n} unless registered_properties.empty?
      s << event_tracker_queue.map {|event_name, properties| event_call(event_name, properties) }.join("\n")
      s << %Q{</script>}
    end

    def event_call(event_name, properties)
      s = properties.empty? ? "" : ", #{properties.to_json}"
      %Q{mixpanel.track("#{event_name}"#{s});}
    end
  end

  class Railtie < Rails::Railtie
    initializer "event_tracker" do |app|
      ActiveSupport.on_load :action_controller do
        include ActionControllerExtension
      end
    end
  end
end
