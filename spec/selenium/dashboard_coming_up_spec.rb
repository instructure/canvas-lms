#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "dashboard" do
  include_context "in-process server selenium tests"

  context "as a student" do
    before (:each) do
      course_with_student_logged_in(:active_all => true)
    end

    it "should display calendar events in the coming up list", priority: "1", test_id: 216392 do
      calendar_event_model({
                               :title => "super fun party",
                               :description => 'celebrating stuff',
                               :start_at => 5.minutes.from_now,
                               :end_at => 10.minutes.from_now
                           })
      get "/"
      expect(f('.events_list .event a')).to include_text(@event.title)
    end

    it "should put locked graded discussions / quizzes in the coming up list only", priority: "1", test_id: 216393 do
      check_list_text = ->(list_element, text, should_have_text = true) do
        if should_have_text
          expect(list_element).to include_text(text)
        else
          expect(list_element).to_not include_text(text)
        end
      end

      due_date = Time.now.utc + 2.days
      names = ['locked discussion assignment', 'locked quiz']
      @course.assignments.create(name: names[0],
                                 submission_types: 'discussion',
                                 due_at: due_date,
                                 lock_at: 1.week.from_now,
                                 unlock_at: due_date)
      q = @course.quizzes.create!(title: names[1], due_at: due_date, lock_at: 1.week.from_now, unlock_at: due_date)
      q.workflow_state = 'available'
      q.save
      q.reload
      get "/"

      # No "To Do" list shown
      expect(f("#content")).not_to contain_css('.right-side-list.to-do-list')
      coming_up_list = f('.right-side-list.events')

      2.times { |i| check_list_text.call(coming_up_list, names[i]) }
    end

    it "should display assignment in coming up list", priority: "1", test_id: 216394 do
      due_date = Time.now.utc + 2.days
      @assignment = assignment_model({:due_at => due_date, :course => @course})
      get "/"
      event = f('.events_list .event a')
      expect(event).to include_text(@assignment.title)
      # use jQuery to get the text since selenium can't figure it out when the elements aren't displayed
      expect(event).to include_text(@course.short_name)
    end

    it "should display quiz submissions with essay questions with points in coming up list", priority: "1", test_id: 216395 do
      quiz_with_graded_submission([:question_data => {:id => 31,
                                                      :name => "Quiz Essay Question 1",
                                                      :question_type => 'essay_question',
                                                      :question_text => 'qq1',
                                                      :points_possible => 10}],
                                  {:user => @student, :course => @course}) do
        {
            "question_31" => "<p>abeawebawebae</p>",
            "question_text" => "qq1"
        }
      end

      @assignment.due_at = Time.now.utc + 1.week
      @assignment.save!

      get "/"
      expect(f('.events_list .event-details')).to include_text '10 points'
    end
  end
end
