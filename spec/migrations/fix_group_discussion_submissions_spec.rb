require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe 'DataFixup::FixGroupDiscussionSubmissions' do
  it "should populate the missing submissions for graded group discussion entries" do
    course_with_student(:active_all => true)
    group_discussion_assignment
    child_topic = @topic.child_topics.first
    child_topic.context.add_user(@student)
    child_topic.reply_from(:user => @student, :text => "entry")

    submission = @student.submissions.first
    Submission.where(:id => submission.id).delete_all

    DataFixup::FixGroupDiscussionSubmissions.run

    @student.reload
    submission = @student.submissions.first
    expect(submission).to_not be_nil
  end
end
