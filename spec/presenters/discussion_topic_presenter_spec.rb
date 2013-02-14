#
# Copyright (C) 2013 Instructure, Inc.
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
  let (:presenter)  { DiscussionTopicPresenter.new(topic, user_model) }
  let (:course)     { course_model }
  let (:assignment) {
    Assignment.new(:title => 'Test Topic',
                   :due_at => Time.now,
                   :lock_at => Time.now + 1.week,
                   :unlock_at => Time.now - 1.week,
                   :submission_types => 'discussion_topic')
  }

  it 'should override the topic assignment when given a user' do
    topic.for_assignment?.should == 0
    presenter.assignment.overridden_for_user.id.should == @user.id
  end
  
  it 'should present an unoverridden copy' do
    presenter.unoverridden.assignment.overridden_for_user.should be_nil
  end

  context 'a topic with no overrides' do
    context 'with dates' do
      it 'should present lock_at' do
        presenter.lock_at.should == presenter.datetime_string(assignment.lock_at)
      end

      it 'should present unlock_at' do
        presenter.unlock_at.should == presenter.datetime_string(assignment.unlock_at)
      end

      it 'should present due_at' do
        presenter.due_at.should == presenter.datetime_string(assignment.due_at)
      end

      context 'that are all day' do
        before(:each) do
          Time.zone = 'UTC'
          Assignment.any_instance.stubs(:unlock_at).returns Time.zone.now.end_of_day
          Assignment.any_instance.stubs(:lock_at).returns   Time.zone.now.end_of_day
          Assignment.any_instance.stubs(:due_at).returns    Time.zone.now.end_of_day
        end

        it 'should present lock_at' do
          presenter.lock_at.should == presenter.date_string(assignment.lock_at)
        end

        it 'should present unlock_at' do
          presenter.unlock_at.should == presenter.date_string(assignment.unlock_at)
        end

        it 'should present due_at' do
          presenter.due_at.should == presenter.date_string(assignment.due_at)
        end
      end
    end

    context 'with no dates' do
      before(:each) do
        Assignment.any_instance.stubs(:unlock_at).returns(nil)
        Assignment.any_instance.stubs(:lock_at).returns(nil)
        Assignment.any_instance.stubs(:due_at).returns(nil)
      end

      it 'should present lock_at' do
        presenter.lock_at.should == '-'
      end

      it 'should present unlock_at' do
        presenter.unlock_at.should == '-'
      end

      it 'should present due_at' do
        presenter.due_at.should == '-'
      end

    end
  end

  context 'a topic with overrides' do
    let(:override) { assignment_override_model }

    it 'should present lock_at' do
      override.lock_at = Time.now + 2.weeks
      presenter.lock_at(:override => override).should == presenter.datetime_string(override.lock_at)
    end

    it 'should present unlock_at' do
      override.unlock_at = Time.now + 2.weeks
      presenter.unlock_at(:override => override).should == presenter.datetime_string(override.unlock_at)
    end

    it 'should present due_at' do
      override.due_at = Time.now + 2.weeks
      presenter.due_at(:override => override).should == presenter.datetime_string(override.due_at)
    end
  end

  context 'an announcement' do
    let(:announcement) { course.announcements.new(:title => 'test', :message => 'body') }
    let(:presenter)    { DiscussionTopicPresenter.new(announcement) }

    it "should know if comments are not disabled" do
      presenter.comments_disabled?.should be_false
    end

    it "should know if comments are disabled" do
      Course.any_instance.stubs(:settings).returns(:lock_all_announcements => true)
      presenter.comments_disabled?.should be_true
    end
  end
end
