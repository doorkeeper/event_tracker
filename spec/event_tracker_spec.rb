require "spec_helper"

shared_examples_for "mixpanel init" do
  it { should include('mixpanel.init("YOUR_TOKEN")') }
end

shared_examples_for "without distinct id" do
  it { should_not include('distinct_id') }
end

shared_examples_for "with distinct id" do
  it { should include('mixpanel.identify("distinct_id")') }
end

shared_examples_for "with event" do
  it { should include('mixpanel.track("Register for site")') }
end

feature 'basic integration' do
  subject { page.find("script").native.content }

  class BasicController < ApplicationController
    tracks_event
    def no_tracking
      render inline: "OK", layout: true
    end

    def with_tracking
      track_event "Register for site"
      render inline: "OK", layout: true
    end
  end

  context 'visit page without tracking' do
    background { visit '/basic/no_tracking' }
    it_should_behave_like "mixpanel init"
    it_should_behave_like "without distinct id"
  end

  context 'visit page with tracking' do
    background { visit '/basic/with_tracking' }
    it_should_behave_like "mixpanel init"
    it_should_behave_like "without distinct id"
    it_should_behave_like "with event"
  end

  class RedirectsController < ApplicationController
    tracks_event

    def index
      track_event "Register for site"
      redirect_to action: :redirected
    end

    def redirected
      render inline: "OK", layout: true
    end
  end

  context 'track event then redirect' do
    background { visit '/redirects' }
    it_should_behave_like "with event"
  end

  class WithPropertiesController < ApplicationController
    tracks_event

    def index
      track_event "Take an action", property1: "a", property2: 1
      render inline: "OK", layout: true
    end
  end

  context "track event with properties" do
    background { visit "/with_properties" }
    it { should include %Q{mixpanel.track("Take an action", {"property1":"a","property2":1})} }
  end
end
