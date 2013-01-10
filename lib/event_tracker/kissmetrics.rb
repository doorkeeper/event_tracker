class EventTracker::Kissmetrics
  def initialize(key)
    @key = key
  end

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
    %Q{_kmq.push(['set', #{registered_properties.to_json}]);}
  end

  def track(event_name, properties)
    p = properties.empty? ? "" : ", #{properties.to_json}"
    %Q{_kmq.push(['record', '#{event_name}'#{p}]);}
  end

  def identify(identity)
    %Q{_kmq.push(['identify', '#{identity}']);}
  end
end
