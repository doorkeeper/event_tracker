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

    def track_event(s)
      event_tracker_queue << s
    end

    def append_event_tracking_tags
      body = response.body
      insert_at = body.index('</head')
      body.insert insert_at, event_tracking_tag
      response.body = body
    end

    def event_tracker_queue
      session[:event_tracker_queue] ||= []
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
      s << event_tracker_queue.map {|s| %Q{mixpanel.track("#{s}");} }.join("\n")
      s << %Q{</script>}
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
