require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../../sharding_spec_helper.rb')

class Subject
  include Api::V1::AssignmentOverride
  def session; {} end
end

describe "Api::V1::AssignmentOverride" do

  describe "#interpret_assignment_override_data" do

    it "works even with nil date fields" do
      override = {:student_ids => [1],
                  :due_at => nil,
                  :unlock_at => nil,
                  :lock_at => nil
      }
      subj = Subject.new
      subj.stubs(:api_find_all).returns []
      assignment = stub(:context => stub(:students => stub(:active)))
      result = subj.interpret_assignment_override_data(assignment, override,'ADHOC')
      expect(result.first[:due_at]).to eq nil
      expect(result.first[:unlock_at]).to eq nil
      expect(result.first[:lock_at]).to eq nil
    end

    context "sharding" do
      specs_require_sharding

      it "works even with global ids for students" do
        course_with_student

        # Mock sharding data
        @shard1.activate { @user = User.create!(name: "Shardy McShardface")}
        @course.enroll_student @user

        override = { :student_ids => [@student.global_id] }

        subj = Subject.new
        subj.stubs(:api_find_all).returns [@student]
        assignment = stub(:context => stub(:students => stub(:active)))
        result = subj.interpret_assignment_override_data(assignment, override,'ADHOC')
        expect(result[1]).to be_nil
        expect(result.first[:students]).to eq [@student]
      end
    end
  end

  describe 'overrides retrieved for teacher' do
    before :once do
      course_model
      @override = assignment_override_model
      @subj = Subject.new
    end

    context 'in restricted course section' do
      before do
        2.times{ @course.course_sections.create! }
        @section_invisible = @course.active_course_sections[2]
        @section_visible = @course.active_course_sections.second

        @student_invisible = student_in_section(@section_invisible)
        @student_visible = student_in_section(@section_visible, user: user)
        @teacher = teacher_in_section(@section_visible, user: user)

        enrollment = @teacher.enrollments.first
        enrollment.limit_privileges_to_course_section = true
        enrollment.save!
      end

      context '#invisble_users_and_overrides_for_user' do
        before do
          @override.set_type = "ADHOC"
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_visible
          @override_student.save!
        end

        it "returns the invisible_student's id in first param" do
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_invisible
          @override_student.save!

          invisible_ids, _ = @subj.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_ids).to include(@student_invisible.id)
        end

        it "returns the invisible_override in the second param" do
          override_invisible = @override.assignment.assignment_overrides.create
          override_invisible.set_type = "ADHOC"
          override_student = override_invisible.assignment_override_students.build
          override_student.user = @student_invisible
          override_student.save!

          _, invisible_overrides = @subj.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_overrides.first).to eq override_invisible.id
        end
      end
    end

    context 'with no restrictions' do
      before do
        2.times do @course.course_sections.create! end
        @section_invisible = @course.active_course_sections[2]
        @section_visible = @course.active_course_sections.second

        @student_invisible = student_in_section(@section_invisible)
        @student_visible = student_in_section(@section_visible, user: user)
      end

      context '#invisble_users_and_overrides_for_user' do
        before do
          @override.set_type = "ADHOC"
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_visible
          @override_student.save!
        end

        it "does not return the invisible student's param in first param" do
          @override_student = @override.assignment_override_students.build
          @override_student.user = @student_invisible
          @override_student.save!

          invisible_ids, _ = @subj.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_ids).to_not include(@student_invisible.id)
        end

        it "returns no override ids in the second param" do
          override_invisible = @override.assignment.assignment_overrides.create
          override_invisible.set_type = "ADHOC"
          override_student = override_invisible.assignment_override_students.build
          override_student.user = @student_invisible
          override_student.save!

          _, invisible_overrides = @subj.invisible_users_and_overrides_for_user(
            @course, @teacher, @assignment.assignment_overrides.active
          )
          expect(invisible_overrides).to be_empty
        end
      end
    end
  end

  describe '#assignment_overrides_json' do
    before :once do
      course_model
      student_in_course(active_all: true)
      @quiz = quiz_model course: @course
      @override = create_section_override_for_assignment(@quiz)
      @subject = Subject.new
    end
    subject(:assignment_overrides_json) { @subject.assignment_overrides_json([@override], @student) }

    it 'delegates to AssignmentOverride.visible_userse_for' do
      AssignmentOverride.expects(:visible_users_for).once.returns([@student])
      assignment_overrides_json
    end
  end
end
