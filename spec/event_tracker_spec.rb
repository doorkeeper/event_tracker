require "spec_helper"

shared_examples_for "mixpanel init" do
  it { should include('mixpanel.init("YOUR_TOKEN")') }
end

shared_examples_for "without distinct id" do
  it { should_not include('mixpanel.identify("distinct_id")') }
end

shared_examples_for "with distinct id" do
  it { should include('mixpanel.identify("distinct_id")') }
end

shared_examples_for "without event" do
  it { should_not include('mixpanel.track("Register for site")') }
end

shared_examples_for "with event" do
  it { should include('mixpanel.track("Register for site")') }
end

feature 'basic integration' do
  subject { page.find("script").native.content }

  class BasicController < ApplicationController
    after_filter :append_event_tracking_tags
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
    it_should_behave_like "without event"
  end

  context 'visit page with tracking' do
    background { visit '/basic/with_tracking' }
    it_should_behave_like "mixpanel init"
    it_should_behave_like "without distinct id"
    it_should_behave_like "with event"
  end

  context 'visit page with tracking then without tracking' do
    background do
      visit '/basic/with_tracking'
      visit '/basic/no_tracking'
    end
    it_should_behave_like "without event"
  end

  class RedirectsController < ApplicationController
    after_filter :append_event_tracking_tags

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
    after_filter :append_event_tracking_tags

    def index
      register_property "age", 19
      register_property "gender", "female"
      track_event "Take an action", property1: "a", property2: 1
      render inline: "OK", layout: true
    end
  end

  context "track event with properties" do
    background { visit "/with_properties" }
    it { should include %Q{mixpanel.track("Take an action", {"property1":"a","property2":1})} }
    it { should include %Q{mixpanel.register({"age":19,"gender":"female"})} }
  end

  class IdentityController < ApplicationController
    after_filter :append_event_tracking_tags
    def event_tracker_identity
      "distinct_id"
    end

    def index
      render inline: "OK", layout: true
    end
  end

  context "with identity" do
    background { visit "/identity" }
    it_should_behave_like "with distinct id"
  end
end
