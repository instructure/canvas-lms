require File.expand_path(File.dirname(__FILE__) + '/common')

describe "dashboard" do
  include_examples "in-process server selenium tests"

  context "as a student" do
    before (:each) do
      course_with_student_logged_in(:active_all => true)
    end

    it "should display calendar events in the coming up list" do
      calendar_event_model({
                               :title => "super fun party",
                               :description => 'celebrating stuff',
                               :start_at => 5.minutes.from_now,
                               :end_at => 10.minutes.from_now
                           })
      get "/"
      expect(f('.events_list .event a')).to include_text(@event.title)
    end

    it "should put locked graded discussions / quizzes in the coming up list only" do
      check_list_text = ->(list_element, text, should_have_text = true) do
        if should_have_text
          expect(list_element).to include_text(text)
        else
          expect(list_element).to_not include_text(text)
        end
      end

      due_date = Time.now.utc + 2.days
      names = ['locked discussion assignment', 'locked quiz']
      @course.assignments.create(:name => names[0], :submission_types => 'discussion', :due_at => due_date, :lock_at => Time.now, :unlock_at => due_date)
      q = @course.quizzes.create!(:title => names[1], :due_at => due_date, :lock_at => Time.now, :unlock_at => due_date)
      q.workflow_state = 'available'
      q.save
      q.reload
      get "/"

      # No "To Do" list shown
      expect(f('.right-side-list.to-do-list')).to be_nil
      coming_up_list = f('.right-side-list.events')

      2.times { |i| check_list_text.call(coming_up_list, names[i]) }
    end

    it "should display assignment in to do list" do
      due_date = Time.now.utc + 2.days
      @assignment = assignment_model({:due_at => due_date, :course => @course})
      get "/"
      expect(f('.events_list .event a')).to include_text(@assignment.title)
      # use jQuery to get the text since selenium can't figure it out when the elements aren't displayed
      expect(driver.execute_script("return $('.event a .tooltip_text').text()")).to match(@course.short_name)
    end

    it "should display quiz submissions with essay questions as submitted in coming up list" do
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
      keep_trying_until { expect(ffj(".events_list .event .tooltip_wrap").size).to be > 0 }
      driver.execute_script("$('.events_list .event .tooltip_wrap, .events_list .event .tooltip_text').css('visibility', 'visible')")
      expect(f('.events_list .event .tooltip_wrap')).to include_text 'submitted'
    end
  end
end