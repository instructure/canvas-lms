require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# need tests for:
# overrides that arent date related

describe "differentiated_assignments" do
  def course_with_da_flag(feature_method=:enable_feature!)
    @course = Course.create!
    @course.send(feature_method, :differentiated_assignments)
    @user = user_model
    @course.enroll_user(@user)
    @course.save!
  end

  def course_with_differentiated_assignments_enabled
    course_with_da_flag :enable_feature!
  end

  def course_without_differentiated_assignments_enabled
    course_with_da_flag :disable_feature!
  end

  def make_assignment(opts={})
    @assignment = Assignment.create!({
      context: @course,
      description: 'descript foo',
      only_visible_to_overrides: opts[:ovto],
      points_possible: rand(1000),
      submission_types: "online_text_entry",
      title: "yes_due_date"
    })
    @assignment.publish
    @assignment.save!
  end

  def assignment_with_true_only_visible_to_overrides
    make_assignment({date: nil, ovto: true})
  end

  def assignment_with_false_only_visible_to_overrides
    make_assignment({date: Time.now, ovto: false})
  end

  def assignment_with_null_only_visible_to_overrides
    make_assignment({date: Time.now, ovto: nil})
  end

  def enroller_user_in_section(section, opts={})
    @user = opts[:user] || user_model
    StudentEnrollment.create!(:user => @user, :course => @course, :course_section => section)
  end

  def enroller_user_in_both_sections
    @user = user_model
    StudentEnrollment.create!(:user => @user, :course => @course, :course_section => @section_foo)
    StudentEnrollment.create!(:user => @user, :course => @course, :course_section => @section_bar)
  end

  def add_multiple_sections
    @default_section = @course.default_section
    @section_foo = @course.course_sections.create!(:name => 'foo')
    @section_bar = @course.course_sections.create!(:name => 'bar')
  end

  def create_override_for_assignment(assignment, &block)
    ao = AssignmentOverride.new()
    ao.assignment = assignment
    ao.title = "Lorem"
    ao.workflow_state = "active"
    block.call(ao)
    ao.save!
  end

  def give_section_due_date(assignment, section)
    create_override_for_assignment(assignment) do |ao|
      ao.set = section
      ao.due_at = 3.weeks.from_now
    end
  end

  def ensure_user_does_not_see_assignment
    visibile_assignment_ids = AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id).pluck(:assignment_id)
    expect(visibile_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_falsey
    expect(AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(user_id: [@user.id], course_id: [@course.id])[@user.id]).not_to include(@assignment.id)
  end

  def ensure_user_sees_assignment
    visibile_assignment_ids = AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id).pluck(:assignment_id)
    expect(visibile_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
    expect(AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(user_id: [@user.id], course_id: [@course.id])[@user.id]).to include(@assignment.id)
  end

  context "table" do
    before do
      course_with_differentiated_assignments_enabled
      add_multiple_sections
      assignment_with_true_only_visible_to_overrides
      give_section_due_date(@assignment, @section_foo)
      enroller_user_in_section(@section_foo)
      # at this point there should be an entry in the table
      @visibility_object = AssignmentStudentVisibility.first
    end

    it "returns objects" do
      expect(@visibility_object).not_to be_nil
    end

    it "doesnt allow updates" do
      @visibility_object.user_id = @visibility_object.user_id + 1
      expect {@visibility_object.save!}.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "doesnt allow new records" do
      expect {
        AssignmentStudentVisibility.create!(user_id: @user.id,
                                            assignment_id: @assignment_id,
                                            course_id: @course.id)
        }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "doesnt allow deletion" do
      expect {@visibility_object.destroy}.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

  end

  context "course_with_differentiated_assignments_enabled" do
    before do
      course_with_differentiated_assignments_enabled
      add_multiple_sections
    end
    context "assignment only visibile to overrides" do
      before do
        assignment_with_true_only_visible_to_overrides
        give_section_due_date(@assignment, @section_foo)
      end

      context "user in section with override who then changes sections" do
        before{enroller_user_in_section(@section_foo)}
        it "should keep the assignment visible if there is a grade" do
          @assignment.grade_student(@user, {grade: 10})
          @user.enrollments.each(&:destroy!)
          enroller_user_in_section(@section_bar, {user: @user})
          ensure_user_sees_assignment
        end

        it "should not keep the assignment visible if there is no grade" do
          @assignment.grade_student(@user, {grade: nil})
          @user.enrollments.each(&:destroy!)
          enroller_user_in_section(@section_bar, {user: @user})
          ensure_user_does_not_see_assignment
        end

        it "should keep the assignment visible if the grade is zero" do
          @assignment.grade_student(@user, {grade: 0})
          @user.enrollments.each(&:destroy!)
          enroller_user_in_section(@section_bar, {user: @user})
          ensure_user_sees_assignment
        end
      end

      context "user in default section" do
        it "should hide the assignment from the user" do
          ensure_user_does_not_see_assignment
        end
      end
      context "user in section with override" do
        before{enroller_user_in_section(@section_foo)}
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
        it "should not show unpublished assignments" do
          @assignment.workflow_state = "unpublished"
          @assignment.save!
          ensure_user_does_not_see_assignment
        end
        it "should update when enrollments change" do
          ensure_user_sees_assignment
          enrollments = StudentEnrollment.where(:user_id => @user.id, :course_id => @course.id, :course_section_id => @section_foo.id)
          enrollments.each(&:destroy!)
          ensure_user_does_not_see_assignment
        end
        it "should update when the override is deleted" do
          ensure_user_sees_assignment
          @assignment.assignment_overrides.all.each(&:destroy!)
          ensure_user_does_not_see_assignment
        end
        it "should not return duplicate visibilities with multiple visible sections" do
          enroller_user_in_section(@section_bar, {user: @user})
          give_section_due_date(@assignment, @section_bar)
          visibile_assignment_ids = AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id)
          expect(visibile_assignment_ids.count).to eq 1
        end
      end
      context "user in section with no override" do
        before{enroller_user_in_section(@section_bar)}
        it "should hide the assignment from the user" do
          ensure_user_does_not_see_assignment
        end
      end
      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
    end
    context "assignment with false only_visible_to_overrides" do
      before do
        assignment_with_false_only_visible_to_overrides
        give_section_due_date(@assignment, @section_foo)
      end
      context "user in default section" do
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
        it "should not show deleted assignments" do
          @assignment.destroy
          ensure_user_does_not_see_assignment
        end
      end
      context "user in section with override" do
        before{enroller_user_in_section(@section_foo)}
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
      context "user in section with no override" do
        before{enroller_user_in_section(@section_bar)}
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
    end
    context "assignment with null only_visible_to_overrides" do
      before do
        assignment_with_null_only_visible_to_overrides
        give_section_due_date(@assignment, @section_foo)
      end
      context "user in default section" do
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
      context "user in section with override" do
        before{enroller_user_in_section(@section_foo)}
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
      context "user in section with no override" do
        before{enroller_user_in_section(@section_bar)}
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end
        it "should show the assignment to the user" do
          ensure_user_sees_assignment
        end
      end
    end
  end
end
