require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/../selenium/helpers/sis_grade_passback_common')

describe "grade exchange course settings tab" do
  include_examples "in-process server selenium tests"

  it "should support grade submission" do
    skip "spec being rewritten in a refactor"
    grade_passback_setup(false)
  end

  it "should support grade submission and result writeback" do
    skip "spec being rewritten in a refactor"
    grade_passback_setup(true)
    process_csv_data_cleanly(
      "enrollment_id,grade_publishing_status,message",
      "#{getenroll('S1', 'S1').id},published,",
      "#{getenroll('S2', 'S2').id},published,",
      "#{getenroll('S3', 'S2').id},published,Grade modified",
      "#{getenroll('S4', 'S1').id},error,Invalid user",
      "#{Enrollment.where(user_id: @stud5.user.id, course_section_id: getsection("S3").first.id).id},error,Invalid user",
      "#{Enrollment.where(user_id: @stud6.user.id, course_section_id: @sec4.id).first.id},error,")
    keep_trying_until { f("#publish_grades_messages").text.strip.split("\n").to_set == "Error: Invalid user - 2\nPublished - 2\nPublished: Grade modified - 1\nError - 1".split("\n").to_set }
  end
end
