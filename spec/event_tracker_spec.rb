require "spec_helper"

shared_examples_for "init" do
  subject { page.find("head script").native.content }
  it { should include('mixpanel.init("YOUR_TOKEN")') }
  it { should include(%q{var _kmk = _kmk || 'KISSMETRICS_KEY'}) }
end

shared_examples_for "without distinct id" do
  it { should_not include(%q{_kmq.push(['identify', 'name@email.com']);}) }
  it { should_not include('mixpanel.identify("distinct_id")') }
end

shared_examples_for "with distinct id" do
  it { should include(%q{_kmq.push(['identify', 'name@email.com']);}) }
  it { should include('mixpanel.identify("distinct_id")') }
end

shared_examples_for "without event" do
  it { should_not include('mixpanel.track("Register for site")') }
end

shared_examples_for "with event" do
  it { should include('mixpanel.track("Register for site")') }
  it { should include(%q{_kmq.push(['record', 'Register for site']);}) }
end

feature 'basic integration' do
  subject { page.find("body script").native.content }

  class BasicController < ApplicationController
    around_filter :append_event_tracking_tags
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
    it_should_behave_like "init"
    it_should_behave_like "without distinct id"
    it_should_behave_like "without event"
  end

  context 'visit page with tracking' do
    background { visit '/basic/with_tracking' }
    it_should_behave_like "init"
    it_should_behave_like "without distinct id"
    it_should_behave_like "with event"
  end

  context 'visit page with tracking' do
    background { visit '/basic/in_views' }
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
    around_filter :append_event_tracking_tags

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
    around_filter :append_event_tracking_tags

    def index
      register_properties age: 19
      register_properties gender: "female"
      track_event "Take an action", property1: "a", property2: 1
      render inline: "OK", layout: true
    end
  end

  context "track event with properties" do
    background { visit "/with_properties" }
    it { should include %Q{mixpanel.track("Take an action", {"property1":"a","property2":1})} }
    it { should include %Q{mixpanel.register({"age":19,"gender":"female"})} }
    it { should include %Q{_kmq.push(['record', 'Take an action', {"property1":"a","property2":1}])} }
    it { should include %Q{_kmq.push(['set', {"age":19,"gender":"female"}])} }
  end

  class IdentityController < ApplicationController
    around_filter :append_event_tracking_tags
    def mixpanel_distinct_id
      "distinct_id"
    end

    def kissmetrics_identity
      "name@email.com"
    end

    def index
      render inline: "OK", layout: true
    end
  end

  context "with identity" do
    background { visit "/identity" }
    it_should_behave_like "with distinct id"
  end

  class NameTagController < ApplicationController
    around_filter :append_event_tracking_tags
    def mixpanel_name_tag
      "foo@example.org"
    end

    def index
      render inline: "OK", layout: true
    end
  end

  context "with name tag" do
    background { visit "/name_tag" }
    it { should include(%q{mixpanel.name_tag("foo@example.org")}) }
  end

  class PrivateController < ApplicationController
    around_filter :append_event_tracking_tags
    def index; render inline: "OK", layout: true; end
    private
    def mixpanel_distinct_id; "distinct_id"; end
    def kissmetrics_identity; "name@email.com"; end
  end

  context "with private methods" do
    background { visit "/private" }
    it_should_behave_like "with distinct id"
  end

  class PeopleSetController < ApplicationController
    around_filter :append_event_tracking_tags

    def index
      mixpanel_people_set "$email" => "jsmith@example.com"
      render inline: "OK", layout: true
    end
  end

  context "track event with properties" do
    background { visit "/people_set" }
    it { should include %Q{mixpanel.people.set({"$email":"jsmith@example.com"})} }
  end

  class AliasController < ApplicationController
    around_filter :append_event_tracking_tags

    def index
      mixpanel_alias "jsmith@example.com"
      render inline: "OK", layout: true
    end
  end

  context "track event with properties" do
    background { visit "/alias" }
    it { should include %Q{mixpanel.alias("jsmith@example.com")} }
  end

  context "halting filter chain in a before_filter" do
    background { visit "/before_filter" }
    it_should_behave_like "init"
  end

  class BeforeFilterController < ApplicationController
    around_filter :append_event_tracking_tags
    before_filter :halt_the_chain_and_render

    def index
      render inline: "OK", layout: true
    end

    def halt_the_chain_and_render
      render inline: "OK", layout: true and return
    end

  end

end
