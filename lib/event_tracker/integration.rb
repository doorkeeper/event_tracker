module EventTracker::Integration
  def self.configured
    @configured ||= begin
      trackers = []
      integrations = [Mixpanel, Kissmetrics, GoogleAnalytics ]
      integrations.each do |integration|
        key_string = "#{integration.to_s.demodulize.underscore}_key"
        key = Rails.application.config.event_tracker[key_string]
        if key
          trackers << integration.new(key)
        end
      end
      trackers
    end
  end
end
