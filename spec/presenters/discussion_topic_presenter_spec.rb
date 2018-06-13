#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DiscussionTopicPresenter do
  let (:topic)      { DiscussionTopic.new(:title => 'Test Topic', :assignment => assignment) }
  let (:user)       { user_model }
  let (:presenter)  { DiscussionTopicPresenter.new(topic, user) }
  let (:course)     { course_model }
  let (:assignment) {
    Assignment.new(:title => 'Test Topic',
                   :due_at => Time.now,
                   :lock_at => Time.now + 1.week,
                   :unlock_at => Time.now - 1.week,
                   :submission_types => 'discussion_topic')
  }

  before do
    allow(AssignmentOverrideApplicator).to receive(:assignment_overridden_for).
      with(topic.assignment,user).and_return assignment
  end

  describe "#initialize" do
    context "when no arguments passed" do
      it "creates a discussion topic and current_user for you" do
        presenter = DiscussionTopicPresenter.new
        expect(presenter.topic.is_a?(DiscussionTopic)).to eq true
        expect(presenter.user.is_a?(User)).to eq true
      end
    end

    context "when discussion_topic and current_user args passed" do
      it "returns the overridden assignment if topic is for assignment" do
        expect(AssignmentOverrideApplicator).to receive(:assignment_overridden_for).
          with(topic.assignment,user).and_return assignment
        presenter = DiscussionTopicPresenter.new(topic,user)
        expect(presenter.assignment).to eq assignment
      end

      it "will have a nil assignment if topic not for grading" do
        expect(DiscussionTopicPresenter.new(
          DiscussionTopic.new(:title => "no assignment")
        ).assignment).to be_nil
      end
    end
  end

  describe "#has_attached_rubric?" do
    it "returns true if assignment has a rubric association with a rubric" do
      expect(assignment).to receive(:rubric_association).
        and_return double(:try => double(:rubric => double))
      expect(presenter.has_attached_rubric?).to eq true
    end

    it "returns false if assignment has nil rubric association" do
      expect(assignment).to receive(:rubric_association).and_return nil
      expect(presenter.has_attached_rubric?).to eq false
    end

    it "returns false if assignment has a rubric association but no rubric" do
      expect(assignment).to receive(:rubric_association).and_return double(:rubric => nil)
      expect(presenter.has_attached_rubric?).to eq false
    end
  end

  describe "#should_show_rubric?" do
    it "returns false if no assignment on the topic" do
        expect(DiscussionTopicPresenter.new(
          DiscussionTopic.new(:title => "no assignment")
        ).should_show_rubric?(user)).to eq false
    end

    it "returns true if has_attached_rubric? is false" do
      expect(assignment).to receive(:rubric_association).and_return double(:rubric => double)
      expect(presenter.should_show_rubric?(user)).to eq true
    end

    context "no rubric association or rubric for the topic's assignment" do
      before { allow(assignment).to receive(:rubric_association).and_return nil }

      it "returns true when the assignment grants the user update privs" do
        expect(assignment).to receive(:grants_right?).with(user, :update).and_return true
        expect(presenter.should_show_rubric?(user)).to eq true
      end

      it "returns false when the assignment grants the user update privs" do
        expect(assignment).to receive(:grants_right?).with(user, :update).and_return false
        expect(presenter.should_show_rubric?(user)).to eq false
      end
    end

  end

  describe "#comments_disabled?" do
    it "only returns true when topic is assignment, its context is a course, "+
      "and the course settings lock all announcements" do
      course_factory
      @course.lock_all_announcements = true
      @course.save!
      announcement = Announcement.new(:title => "Announcement", :context => @course)
      expect(DiscussionTopicPresenter.new(announcement).comments_disabled?).
        to eq true
    end

    it "returns false for announcements or other criteria not met" do
      expect(presenter.comments_disabled?).to eq false
      course_factory
      announcement = Announcement.new(:title => "b", :context => @course)
      expect(DiscussionTopicPresenter.new(announcement).comments_disabled?).
        to eq false
    end
  end

  describe "#large_roster?" do
    it "returns true when context responds to large_roster and context " +
      "has a large roster" do
      topic.context = Course.new(:name => "Canvas")
      topic.context.large_roster = true
      expect(presenter.large_roster?).to eq true
    end

    it "returns false when context responds to large roster and context " +
      "doesn't have a large roster" do
      topic.context = Course.new(:name => "Canvas")
      topic.context.large_roster = false
      expect(presenter.large_roster?).to eq false
    end

    context "topic's context isn't a course" do

      before do
        @group = Group.new(:name => "Canvas")
        topic.context = @group
        @group.context = Course.new(:name => "Canvas")
        @group.context.large_roster = true
      end

      it "returns false if topic's context's context is nil" do
        @group.context = nil
        expect(presenter.large_roster?).to eq false
      end

      it "returns true if topic's context's context has large_roster?" do
        expect(presenter.large_roster?).to eq true
      end

    end
  end

  describe "#allows_speed_grader?" do

    it "returns false when course is large roster" do
      topic.context = Course.new(name: 'Canvas')
      topic.context.large_roster = true
      expect(presenter.allows_speed_grader?).to eq false
    end

    context "with assignment" do

      before do
        course = topic.context = Course.create!(name: 'Canvas')
        assignment.context = course
        assignment.save!
        topic.assignment = assignment
      end

      it "returns false when assignment unpublished" do
        assignment.unpublish
        expect(presenter.allows_speed_grader?).to eq false
      end

      it "returns true when assignment published" do
        expect(presenter.allows_speed_grader?).to eq true
      end
    end
  end

end
