require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))
require 'db/migrate/20130417153307_fix_dissociated_discussion_topics'

describe DataFixup::AttachDissociatedDiscussionTopics do
  it 'should fix topics missing assignment_id' do
    course     = Course.create!
    assignment = Assignment.create!(title: 'Test topic', description: 'Lorem ipsum /download?', context: course)
    topic      = DiscussionTopic.create!(title: 'Test topic', message: 'Lorem ipsum /download?', context: course)
    topic.update_attribute(:old_assignment_id, assignment.id)

    DataFixup::AttachDissociatedDiscussionTopics.run
    expect(topic.reload.assignment_id).to eq assignment.id
  end

  it 'should not change topics with an existing assignment_id' do
    course     = Course.create!
    assignment = Assignment.create!(title: 'Test topic', description: 'Lorem ipsum ?verifier=', context: course)
    topic      = DiscussionTopic.create!(title: 'Test topic', message: 'Lorem ipsum ?verifier=', context: course, assignment: assignment)
    topic.update_attribute(:old_assignment_id, assignment.id - 1)

    DataFixup::AttachDissociatedDiscussionTopics.run
    expect(topic.reload.assignment_id).to eq assignment.id
  end

  it 'should not change topics that have no file link in their message' do
    course     = Course.create!
    assignment = Assignment.create!(title: 'Test topic', description: 'Lorem ipsum download', context: course)
    topic      = DiscussionTopic.create!(title: 'Test topic', message: 'Lorem ipsum download', context: course)
    topic.update_attribute(:old_assignment_id, assignment.id)

    DataFixup::AttachDissociatedDiscussionTopics.run
    expect(topic.reload.assignment_id).to be_nil
  end
end
