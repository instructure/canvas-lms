require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do
  include_examples "in-process server selenium tests"

  def setup_sections_and_overrides_all_future
    # All in the future by default
    @unlock_at = Time.now.utc + 6.days
    @due_at    = Time.now.utc + 10.days
    @lock_at   = Time.now.utc + 11.days

    @assignment.due_at    = @due_at
    @assignment.unlock_at = @unlock_at
    @assignment.lock_at   = @lock_at
    @assignment.save!
    # 2 course sections, student in second section.
    @section1 = @course.course_sections.create!(:name => 'Section A')
    @section2 = @course.course_sections.create!(:name => 'Section B')
    @course.student_enrollments.scoped.delete_all  # get rid of existing student enrollments, mess up section enrollment
    # Overridden lock dates for 2nd section - different dates, but still in future
    @override = assignment_override_model(:assignment => @assignment, :set => @section2,
                                          :lock_at => @lock_at + 12.days,
                                          :unlock_at => Time.now.utc + 3.days)
  end

  context "as observer" do
    before :each do
      @course   = course(:active_all => true)
      @student  = user(:active_all => true, :active_state => 'active')
      @observer = user(:active_all => true, :active_state => 'active')
      user_session(@observer)

      @due_date = Time.now.utc + 12.days
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => @due_date)

      setup_sections_and_overrides_all_future
    end

    context "when not linked to student" do
      before :each do
        @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active')
      end

      it "should see own section's lock dates" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        expect(f('#content')).to include_text "locked until #{expected_unlock}."
      end

      context "with multiple section enrollments in same course" do
        it "should have the earliest 'lock until' date and the latest 'lock after' date" do
          @assignment.update_attributes :lock_at => @lock_at + 22.days
          @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section1, :enrollment_state => 'active')
          extend TextHelper
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
          expected_lock_at = datetime_string(@assignment.lock_at).gsub(/\s+/, ' ')   # later than section2
          expect(f('#content')).to include_text "locked until #{expected_unlock}."
        end
      end
    end

    context "when linked to student" do
      before :each do
        @student_enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :section => @section2)
        @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :section => @section2)
        @observer_enrollment.update_attribute(:associated_user_id, @student.id)
      end

      it "should return student's lock dates" do
        extend TextHelper
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
        expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
        expect(f('#content')).to include_text "locked until #{expected_unlock}."
      end

      context "overridden lock_at" do
        before :each do
          setup_sections_and_overrides_all_future
          @course.enroll_user(@student, 'StudentEnrollment', :section => @section2, :enrollment_state => 'active')
        end

        it "should show overridden lock dates for student" do
          extend TextHelper
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expected_unlock = datetime_string(@override.unlock_at).gsub(/\s+/, ' ')
          expected_lock_at = datetime_string(@override.lock_at).gsub(/\s+/, ' ')
          expect(f('#content')).to include_text "locked until #{expected_unlock}."
        end
      end
    end
  end
end