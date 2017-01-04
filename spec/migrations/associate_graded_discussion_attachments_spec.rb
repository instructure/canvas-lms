require_relative '../spec_helper'

describe DataFixup::AssociateGradedDiscussionAttachments do
  it "should associate graded discussion attachments" do
    course_with_student(:active_all => true)
    assignment = @course.assignments.create!(:title => "asmt")
    topic = @course.discussion_topics.create!(:title => 'topic', :assignment => assignment)

    attachment_model(:context => @student, :uploaded_data => stub_png_data, :filename => "homework.png")
    entry = topic.reply_from(:user => @student, :text => "entry")
    entry.attachment = @attachment
    entry.save!

    sub = assignment.submissions.where(:user_id => @student).first
    Submission.where(:id => sub).update_all(:attachment_ids => nil)
    AttachmentAssociation.where(:attachment_id => @attachment).delete_all

    sub.reload
    expect(sub.attachments).to be_empty

    DataFixup::AssociateGradedDiscussionAttachments.run

    sub.reload
    expect(sub.attachments.to_a).to eq [@attachment]
    expect(AttachmentAssociation.where(:attachment_id => @attachment)).to be_exists
  end
end
