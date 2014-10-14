require File.expand_path(File.dirname(__FILE__)+'/../../../../spec/spec_helper')
require_relative('../../../../spec/models/web_conference_spec_helper')

module Wiziq

describe WiziqConference do
  include Wiziq

  include_examples 'WebConference'

  before(:each) do
    PluginSetting.create!(:name => 'wiziq', :settings => { :api_url => 'http://wiziq.com/', :access_key => 'test_access_key', :secret_key => 'test_secret_key' })
    WebConference.stubs(:plugins).returns(
        [OpenObject.new(:id => "wiziq", :settings => {:api_url => "http://test.wiziq.com/",:access_key => "test_access_key",:secret_key => "test_secret_key"}, :valid_settings? => true, :enabled? => true)])
    course_with_teacher(:active_all => true)
  end

  it 'should schedule a new conference' do
    AgliveComUtil.any_instance.expects(:schedule_class).with(has_entries({
      'title' => 'my test conference',
      'presenter_id' => @user.id,
      'presenter_name' => 'User',
      'duration' => 300,
      'course_id' => @course.id,
    })).returns({
      'code' => 0,
      'class_id' => '12345',
      'presenters' => [{ 'presenter_url' => 'http://example.com/presenter_url', }],
    })
    conference = factory_with_protected_attributes(WiziqConference, :title => "my test conference", :user => @user, :context => @course)
    expect(conference.admin_join_url(@user,"http://www.instructure.com")).to eq "http://example.com/presenter_url"
    expect(conference.conference_key).to eq '12345'
  end

  it "should get presenter url for an existing conference" do
    AgliveComUtil.any_instance.expects(:get_class_presenter_info).with('12345').returns({
      'presenter_url' => 'http://example.com/presenter_url',
    })
    conference = factory_with_protected_attributes(WiziqConference, :title => "my test conference", :user => @user, :context => @course, :conference_key => '12345')
    expect(conference.admin_join_url(@user,"http://www.instructure.com")).to eq "http://example.com/presenter_url"
  end

  it 'should get participant urls and allow re-joining' do
    @s1 = student_in_course.user
    @s2 = student_in_course.user
    AgliveComUtil.any_instance.expects(:add_attendee_to_session).with('12345', @s1.id, @s1.name).returns({
      'attendee_url' => 'http://example.com/attendee_url?1',
    })
    AgliveComUtil.any_instance.expects(:add_attendee_to_session).with('12345', @s2.id, @s2.name).returns({
      'attendee_url' => 'http://example.com/attendee_url?2',
    })
    AgliveComUtil.any_instance.expects(:add_attendee_to_session).with('12345', @s1.id, @s1.name).returns({
      'attendee_url' => 'http://example.com/attendee_url?1',
    })
    conference = factory_with_protected_attributes(WiziqConference, :title => "my test conference", :user => @user, :context => @course, :conference_key => '12345')
    expect(conference.participant_join_url(@s1,"http://www.instructure.com")).to eq "http://example.com/attendee_url?1"
    expect(conference.participant_join_url(@s2,"http://www.instructure.com")).to eq "http://example.com/attendee_url?2"
    expect(conference.participant_join_url(@s1,"http://www.instructure.com")).to eq "http://example.com/attendee_url?1"
  end

  it "should confirm valid config" do
    expect(WiziqConference.new.valid_config?).to be_truthy
    expect(WiziqConference.new(:conference_type => "Wiziq").valid_config?).to be_truthy
  end
end

end
