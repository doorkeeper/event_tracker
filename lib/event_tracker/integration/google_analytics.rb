class EventTracker::Integration::GoogleAnalytics < EventTracker::Integration::Base
  def init
    # The following is for initializing GA4. Uncomment it if you aren't already including GA4 on the site:

    # <<-EOD
    #   (function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
    #   new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
    #   j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
    #   'https://www.googletagmanager.com/gtag/js?id='+i+dl;f.parentNode.insertBefore(j,f);
    #   })(window,document,'script','dataLayer', '#{@key}');

    #   gtag('js', new Date());
    #   gtag('config', '#{@key}');
    # EOD
  end

  def track(event_name, properties = {})
    properties_js = properties.to_json
    %Q{gtag('event', '#{event_name}', #{properties_js});}
  end
end
