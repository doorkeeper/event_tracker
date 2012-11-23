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

feature 'basic integration' do
  subject { page.find("script").native.content }

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
end
