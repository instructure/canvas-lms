require_relative "../spec_helper"
require 'db/migrate/20160805163609_fix_ridiculous_web_conference_durations.rb'

describe FixRidiculousWebConferenceDurations do
  it "sets ridiculously long conferences as long-running" do
    course_with_teacher
    WebConference.stubs(:conference_types).returns([{conference_type: 'test', class_name: 'WebConference'}])
    conf = course.web_conferences.create!(user: @teacher, conference_type: 'test')
    conf.update_attribute(:duration, WebConference::MAX_DURATION + 1)
    FixRidiculousWebConferenceDurations.up
    expect(conf.reload.duration).to be_nil
  end
end
