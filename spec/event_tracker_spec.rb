require "spec_helper"

class ExampleController < ApplicationController
  def no_tracking
    render inline: "OK", layout: true
  end

  def with_tracking
    render inline: "OK", layout: true
  end
end

shared_examples_for "without distinct id" do
  it { page.find("script:last").text.should_not include('distinct_id') }
end

shared_examples_for "with distinct id" do
  it { page.find("script:last").text.should include('mpq.push(["register", {"distinct_id":1}]);') }
end

shared_examples_for "with event" do
  it { page.find("script:last").text.should include('mpq.push(["track", "Register for site"])') }
end

feature 'mixpanel integration' do
  context 'visit page without tracking' do
    background { visit '/example/no_tracking' }
    it_should_behave_like "without distinct id"
  end
  context 'visit page with tracking' do
    background { visit '/example/with_tracking' }
    it_should_behave_like "without distinct id"
    it_should_behave_like "with event"
  end
end
