class EventTracker::Integration::Kissmetrics < EventTracker::Integration::Base
  def init
    <<-EOD
      var _kmq = _kmq || [];
      var _kmk = _kmk || '#{@key}';
      function _kms(u){
        setTimeout(function(){
          var d = document, f = d.getElementsByTagName('script')[0],
          s = d.createElement('script');
          s.type = 'text/javascript'; s.async = true; s.src = u;
          f.parentNode.insertBefore(s, f);
        }, 1);
      }
      _kms('//i.kissmetrics.com/i.js');
      _kms('//doug1izaerwt3.cloudfront.net/' + _kmk + '.1.js');
    EOD
  end

  def register(registered_properties)
    %Q{_kmq.push(['set', #{embeddable_json(registered_properties)}]);}
  end

  def track(event_name, properties)
    p = properties.empty? ? "" : ", #{embeddable_json(properties)}"
    %Q{_kmq.push(['record', '#{event_name}'#{p}]);}
  end

  def identify(identity)
    %Q{_kmq.push(['identify', '#{identity}']);}
  end
end
