require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

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

  def make_quiz(opts={})
    @quiz = Quizzes::Quiz.create!({
      context: @course,
      description: 'descript foo',
      only_visible_to_overrides: opts[:ovto],
      points_possible: rand(1000),
      title: "I am a quiz"
    })
    @quiz.publish
    @quiz.save!
    @assignment = @quiz.assignment
  end

  def quiz_with_true_only_visible_to_overrides
    make_quiz({date: nil, ovto: true})
  end

  def quiz_with_false_only_visible_to_overrides
    make_quiz({date: Time.now, ovto: false})
  end

  def quiz_with_null_only_visible_to_overrides
    make_quiz({date: Time.now, ovto: nil})
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

  def create_override_for_quiz(quiz, &block)
    ao = AssignmentOverride.new()
    ao.quiz = quiz
    ao.title = "Lorem"
    ao.workflow_state = "active"
    block.call(ao)
    ao.save!
  end

  def give_section_foo_due_date(quiz)
    create_override_for_quiz(quiz) do |ao|
      ao.set = @section_foo
      ao.due_at = 3.weeks.from_now
    end
  end

  def ensure_user_does_not_see_quiz
    visibile_quiz_ids = Quizzes::QuizStudentVisibility.where(user_id: @user.id, course_id: @course.id).pluck(:quiz_id)
    expect(visibile_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_falsey
    expect(Quizzes::QuizStudentVisibility.visible_quiz_ids_in_course_by_user(user_id: [@user.id], course_id: [@course.id])[@user.id]).not_to include(@quiz.id)
  end

  def ensure_user_sees_quiz
    visibile_quiz_ids = Quizzes::QuizStudentVisibility.where(user_id: @user.id, course_id: @course.id).pluck(:quiz_id)
    expect(visibile_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_truthy
    expect(Quizzes::QuizStudentVisibility.visible_quiz_ids_in_course_by_user(user_id: [@user.id], course_id: [@course.id])[@user.id]).to include(@quiz.id)
  end

  context "table" do
    before do
      course_with_differentiated_assignments_enabled
      add_multiple_sections
      quiz_with_true_only_visible_to_overrides
      give_section_foo_due_date(@quiz)
      enroller_user_in_section(@section_foo)
      # at this point there should be an entry in the table
      @visibility_object = Quizzes::QuizStudentVisibility.first
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
        Quizzes::QuizStudentVisibility.create!(user_id: @user.id,
                                            quiz_id: @quiz_id,
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
    context "quiz only visibile to overrides" do
      before do
        quiz_with_true_only_visible_to_overrides
        give_section_foo_due_date(@quiz)
      end

      context "user in section with override who then changes sections" do
        before{enroller_user_in_section(@section_foo)}
        it "should keep the quiz visible if there is a grade" do
          @quiz.assignment.grade_student(@user, {grade: 10})
          @user.enrollments.each(&:destroy!)
          enroller_user_in_section(@section_bar, {user: @user})
          ensure_user_sees_quiz
        end

        it "should not keep the quiz visible if there is no score, even if it has a grade" do
          @quiz.assignment.grade_student(@user, {grade: 10})
          @quiz.assignment.submissions.last.update_attribute("score", nil)
          @quiz.assignment.submissions.last.update_attribute("grade", 10)
          @user.enrollments.each(&:destroy!)
          enroller_user_in_section(@section_bar, {user: @user})
          ensure_user_does_not_see_quiz
        end

        it "should keep the quiz visible if the grade is zero" do
          @quiz.assignment.grade_student(@user, {grade: 0})
          @user.enrollments.each(&:destroy!)
          enroller_user_in_section(@section_bar, {user: @user})
          ensure_user_sees_quiz
        end
      end

      context "user in default section" do
        it "should hide the quiz from the user" do
          ensure_user_does_not_see_quiz
        end
      end
      context "user in section with override" do
        before{enroller_user_in_section(@section_foo)}
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
        it "should update when enrollments change" do
          ensure_user_sees_quiz
          enrollments = StudentEnrollment.where(:user_id => @user.id, :course_id => @course.id, :course_section_id => @section_foo.id)
          enrollments.each(&:destroy!)
          ensure_user_does_not_see_quiz
        end
        it "should update when the override is deleted" do
          ensure_user_sees_quiz
          @quiz.assignment_overrides.all.each(&:destroy!)
          ensure_user_does_not_see_quiz
        end
      end
      context "user in section with no override" do
        before{enroller_user_in_section(@section_bar)}
        it "should hide the quiz from the user" do
          ensure_user_does_not_see_quiz
        end
      end
      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
    end
    context "quiz with false only_visible_to_overrides" do
      before do
        quiz_with_false_only_visible_to_overrides
        give_section_foo_due_date(@quiz)
      end
      context "user in default section" do
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
      context "user in section with override" do
        before{enroller_user_in_section(@section_foo)}
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
      context "user in section with no override" do
        before{enroller_user_in_section(@section_bar)}
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
    end
    context "quiz with null only_visible_to_overrides" do
      before do
        quiz_with_null_only_visible_to_overrides
        give_section_foo_due_date(@quiz)
      end
      context "user in default section" do
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
      context "user in section with override" do
        before{enroller_user_in_section(@section_foo)}
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
      context "user in section with no override" do
        before{enroller_user_in_section(@section_bar)}
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end
        it "should show the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
    end
  end
end
