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
  let (:presenter)  { DiscussionTopicPresenter.new(topic) }
  let (:course)     { course_model }
  let (:topic)      { DiscussionTopic.new(:title => 'Test Topic', :assignment => assignment) }
  let (:assignment) {
    Assignment.new(:title => 'Test Topic',
                   :due_at => Time.now,
                   :lock_at => Time.now + 1.week,
                   :unlock_at => Time.now - 1.week)
  }

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
      presenter.lock_at(override: override).should == presenter.datetime_string(override.lock_at)
    end

    it 'should present unlock_at' do
      override.unlock_at = Time.now + 2.weeks
      presenter.unlock_at(override: override).should == presenter.datetime_string(override.unlock_at)
    end

    it 'should present due_at' do
      override.due_at = Time.now + 2.weeks
      presenter.due_at(override: override).should == presenter.datetime_string(override.due_at)
    end
  end
end
