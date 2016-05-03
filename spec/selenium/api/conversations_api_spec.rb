require File.expand_path(File.dirname(__FILE__) + '/../../apis/api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/groups_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe ConversationsController, type: :request do
  include_context "in-process server selenium tests"
  include GroupsCommon
  include ConversationsCommon

  before :once do
    course_with_teacher(:active_course => true, :active_enrollment => true, 
                        :user => user_with_pseudonym(:active_user => true))
    @course.update_attribute(:name, "the course")
  end

  it "should add recipients through the API", priority: "2", test_id: 860599 do
    group_test_setup(4,1,1)
    @student = []
    4.times do |i|
      @student << User.create(name: "student #{i}")
      enrollment = @course.enroll_user(@student.last, 'StudentEnrollment')
      enrollment.workflow_state = 'active'
      enrollment.save
      add_user_to_group(@student.last, @testgroup.first)
    end

    cp = conversation(@teacher, @student.first, private: false)
    @convo = cp.conversation
    @convo.add_message(@student.first, "What's this week's homework?")
    api_call(:post, "/api/v1/conversations/#{@convo.id}/add_recipients",
            { :controller => 'conversations', :action => 'add_recipients', :id => @convo.id.to_s, :format => 'json' },
             { :recipients => "group_#{@testgroup.first.id}" })
    user_session(@teacher)
    go_to_inbox_and_select_message
    f('.message-participants-toggle').click
    expect(f('.message-participants').text).to include("student 3, student 2, student 1, student 0")
    expect(f('.message-item-view').text).to include("student 1, student 2, and student 3 were added to the conversation")
  end
end