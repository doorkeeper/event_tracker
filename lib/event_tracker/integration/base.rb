class EventTracker::Integration::Base
  include ERB::Util

  def initialize(key)
    @key = key
  end

  private

  def embeddable_json(properties)
    json_escape(properties.to_json).html_safe
  end
end
