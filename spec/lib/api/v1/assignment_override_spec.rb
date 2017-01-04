require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../../sharding_spec_helper.rb')

class Subject
  include Api::V1::AssignmentOverride
  attr_accessor :current_user
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

  describe "interpret_batch_assignment_overrides_data" do
    before(:once) do
      course_with_teacher(active_all: true)
      @a = assignment_model(course: @course, group_category: 'category1')
      @b = assignment_model(course: @course, group_category: 'category2')
      @a1, @a2 = 2.times.map do
        create_section_override_for_assignment @a, course_section: @course.course_sections.create!
      end
      @b1, @b2, @b3 = 2.times.map do
        create_section_override_for_assignment @b, course_section: @course.course_sections.create!
      end
      @subj = Subject.new
      @subj.current_user = @teacher
    end

    it "should have error if no updates requested" do
      _data, errors = @subj.interpret_batch_assignment_overrides_data(@course, [], true)
      expect(errors[0]).to eq 'no assignment override data present'
    end

    it "should have error if assignments are malformed" do
      _data, errors = @subj.interpret_batch_assignment_overrides_data(
        @course,
        {foo: @a.id, bar: @b.id}.with_indifferent_access,
        true)
      expect(errors[0]).to match(/must specify an array/)
    end

    it "should fail if list of overrides is malformed" do
      _data, errors = @subj.interpret_batch_assignment_overrides_data(@course, [
        { assignment_id: @a.id, override: @a1.id }.with_indifferent_access,
        { title: 'foo' }.with_indifferent_access
      ], true)
      expect(errors[0]).to eq ['must specify an override id']
      expect(errors[1]).to eq ['must specify an assignment id', 'must specify an override id']
    end

    it "should fail if individual overrides are malformed" do
      _data, errors = @subj.interpret_batch_assignment_overrides_data(@course, [
        { assignment_id: @a.id, id: @a1.id, due_at: 'foo' }.with_indifferent_access
      ], true)
      expect(errors[0]).to eq ['invalid due_at "foo"']
    end

    it "should fail if assignment not found" do
      @a.destroy!
      _data, errors = @subj.interpret_batch_assignment_overrides_data(@course, [
        { assignment_id: @a.id, id: @a1.id, title: 'foo'}.with_indifferent_access
      ], true)
      expect(errors[0]).to eq ['assignment not found']
    end

    it "should fail if override not found" do
      @a1.destroy!
      _data, errors = @subj.interpret_batch_assignment_overrides_data(@course, [
        { assignment_id: @a.id, id: @a1.id, title: 'foo'}.with_indifferent_access
      ], true)
      expect(errors[0]).to eq ['override not found']
    end

    it "should succeed if formatted correctly" do
      new_date = Time.zone.now.tomorrow
      data, errors = @subj.interpret_batch_assignment_overrides_data(@course, [
        { assignment_id: @a.id, id: @a1.id, due_at: new_date.to_s }.with_indifferent_access,
        { assignment_id: @a.id, id: @a2.id, lock_at: new_date.to_s }.with_indifferent_access,
        { assignment_id: @b.id, id: @b2.id, unlock_at: new_date.to_s }.with_indifferent_access
      ], true)
      expect(errors).to be_blank
      expect(data[0][:due_at].to_date).to eq new_date.to_date
      expect(data[1][:lock_at].to_date).to eq new_date.to_date
      expect(data[2][:unlock_at].to_date).to eq new_date.to_date
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
        @student_visible = student_in_section(@section_visible, user: user_factory)
        @teacher = teacher_in_section(@section_visible, user: user_factory)

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
        @student_visible = student_in_section(@section_visible, user: user_factory)
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

    it 'delegates to AssignmentOverride.visible_enrollments_for' do
      AssignmentOverride.expects(:visible_enrollments_for).once.returns(Enrollment.none)
      assignment_overrides_json
    end
  end
end
