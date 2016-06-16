# coding: utf-8
#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Assignment do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true, user_name: 'a student')
  end

  it "should create a new instance given valid attributes" do
    @course.assignments.create!(assignment_valid_attributes)
  end

  it "should have a useful state machine" do
    assignment_model(course: @course)
    expect(@a.state).to eql(:published)
    @a.unpublish
    expect(@a.state).to eql(:unpublished)
  end

  it "should always be associated with a group" do
    assignment_model(course: @course)
    @assignment.save!
    expect(@assignment.assignment_group).not_to be_nil
  end

  it "should be associated with a group when the course has no active groups" do
    @course.require_assignment_group
    @course.assignment_groups.first.destroy
    expect(@course.assignment_groups.size).to eq 1
    expect(@course.assignment_groups.active.size).to eq 0
    @assignment = assignment_model(:course => @course)
    expect(@assignment.assignment_group).not_to be_nil
  end

  it "should touch assignment group on create/save" do
    group = @course.assignment_groups.create!(:name => "Assignments")
    AssignmentGroup.where(:id => group).update_all(:updated_at => 1.hour.ago)
    orig_time = group.reload.updated_at.to_i
    a = @course.assignments.build("title"=>"test")
    a.assignment_group = group
    a.save!
    expect(@course.assignments.count).to eq 1
    group.reload
    expect(group.updated_at.to_i).not_to eq orig_time
  end

  it "should be able to submit homework" do
    setup_assignment_with_homework
    expect(@assignment.submissions.size).to eql(1)
    @submission = @assignment.submissions.first
    expect(@submission.user_id).to eql(@user.id)
    expect(@submission.versions.length).to eql(1)
  end

  it "should validate grading_type inclusion" do
    @invalid_grading_type = "invalid"
    @assignment = Assignment.new(assignment_valid_attributes.merge({
      course: @course,
      grading_type: @invalid_grading_type
    }))

    expect(@assignment).not_to be_valid
    expect(@assignment.errors[:grading_type]).not_to be_nil
  end

  describe "#has_student_submissions?" do
    before :once do
      setup_assignment_with_students
    end

    it "does not allow itself to be unpublished if it has student submissions" do
      @assignment.submit_homework @stu1, :submission_type => "online_text_entry"
      expect(@assignment).not_to be_can_unpublish

      @assignment.unpublish
      expect(@assignment).not_to be_valid
      expect(@assignment.errors['workflow_state']).to eq ["Can't unpublish if there are student submissions"]
    end

    it "does allow itself to be unpublished if it has nil submissions" do
      @assignment.submit_homework @stu1, :submission_type => nil
      expect(@assignment).to be_can_unpublish
      @assignment.unpublish
      expect(@assignment.workflow_state).to eq "unpublished"
    end
  end

  describe '#grade_to_score' do
    before(:once) { setup_assignment_without_submission }

    let(:set_type_and_save) do
      lambda do |type|
        @assignment.grading_type = type
        @assignment.save
      end
    end

    # The test cases for grading_type of points, percent,
    # letter_grade, and gpa_scale are covered by the tests of
    # interpret_grade as that is doing the work.  The cases tested
    # here are all contained solely within grade_to_score

    it 'returns nil for a nil grade' do
      expect(@assignment.grade_to_score(nil)).to be_nil
    end

    it 'returns nil for a not_graded assignment' do
      set_type_and_save.call('not_graded')
      expect(@assignment.grade_to_score("3")).to be_nil
    end

    it 'returns an exception for an unknown grading type' do
      set_type_and_save.call("totally_fake_grading")
      expect{@assignment.grade_to_score("3")}.to raise_error
    end

    context 'with a pass/fail assignment' do
      before(:once) do
        @assignment.grading_type = 'pass_fail'
        @assignment.points_possible = 6.0
        @assignment.save
      end

      let(:points_possible) { @assignment.points_possible }

      it "returns points possible for maximum points" do
        expect(@assignment.grade_to_score(points_possible.to_s)).to eql(points_possible)
      end

      it "returns nil for partial points" do
        expect(@assignment.grade_to_score("3")).to be_nil
      end

      it "returns 0.0 for 0 points" do
        expect(@assignment.grade_to_score("0")).to eql(0.0)
      end

      it "returns nil for an empty string" do
        expect(@assignment.grade_to_score("")).to be_nil
      end
    end
  end

  describe '#grade_student' do
    before(:once) { setup_assignment_without_submission }

    context 'with a valid student' do
      before :once do
        @result = @assignment.grade_student(@user, :grade => "10")
        @assignment.reload
      end

      it 'returns an array' do
        expect(@result).to be_is_a(Array)
      end

      it 'now has a submission' do
        expect(@assignment.submissions.size).to eql(1)
      end

      describe 'the submission after grading' do
        subject { @assignment.submissions.first }

        describe '#state' do
          subject { super().state }
          it { is_expected.to eql(:graded) }
        end
        it { is_expected.to eq @result[0] }

        describe '#score' do
          subject { super().score }
          it { is_expected.to eq 10.0 }
        end

        describe '#user_id' do
          subject { super().user_id }
          it { is_expected.to eq @user.id }
        end
        specify { expect(subject.versions.length).to eq 1 }
      end
    end

    context 'with no student' do
      it 'raises an error' do
        expect { @assignment.grade_student(nil) }.to raise_error(Assignment::GradeError, 'Student is required')
      end
    end

    context 'with a student that does not belong' do
      it 'raises an error' do
        expect { @assignment.grade_student(User.new) }.to raise_error(Assignment::GradeError, 'Student must be enrolled in the course as a student to be graded')
      end
    end

    context 'with an invalid initial grade' do
      before :once do
        @result = @assignment.grade_student(@user, :grade => "{")
        @assignment.reload
      end

      it 'does not change the workflow_state to graded' do
        expect(@result.first.grade).to be_nil
        expect(@result.first.workflow_state).not_to eq 'graded'
      end
    end

    context 'with an excused assignment' do
      before :once do
        @result = @assignment.grade_student(@user, :excuse => true)
        @assignment.reload
      end

      it 'excuses the assignment and marks it as graded' do
        expect(@result.first.grade).to be_nil
        expect(@result.first.workflow_state).to eql 'graded'
        expect(@result.first.excused?).to eql true
      end
    end

    context 'with anonymous grading' do
      it 'explicitly sets anonymous grading if given' do
        @assignment.grade_student(@user, :graded_anonymously => true, :grade => "10")
        @assignment.reload
        expect(@assignment.submissions.first.graded_anonymously).to be_truthy
      end

      it 'does not set anonymous grading if not given' do
        @assignment.grade_student(@user, :graded_anonymously => true, :grade => "10")
        @assignment.reload
        @assignment.grade_student(@user, :grade => "10")
        @assignment.reload
        # should still true because grade didn't actually change
        expect(@assignment.submissions.first.graded_anonymously).to be_truthy
      end
    end
  end

  describe "#all_context_module_tags" do
    let(:assignment) { Assignment.new }
    let(:content_tag) { ContentTag.new }

    it "returns the context module tags for a 'normal' assignment " \
      "(non-quiz and non-discussion topic)" do
      assignment.submission_types = "online_text_entry"
      assignment.context_module_tags << content_tag
      expect(assignment.all_context_module_tags).to eq [content_tag]
    end

    it "returns the context_module_tags on the quiz if the assignment is " \
      "associated with a quiz" do
      quiz = assignment.build_quiz
      quiz.context_module_tags << content_tag
      assignment.submission_types = "online_quiz"
      expect(assignment.all_context_module_tags).to eq([content_tag])
    end

    it "returns the context_module_tags on the discussion topic if the " \
      "assignment is associated with a discussion topic" do
      assignment.submission_types = "discussion_topic"
      discussion_topic = assignment.build_discussion_topic
      discussion_topic.context_module_tags << content_tag
      expect(assignment.all_context_module_tags).to eq([content_tag])
    end

    it "doesn't return the context_module_tags on the wiki page if the " \
      "assignment is associated with a wiki page" do
      assignment.submission_types = "wiki_page"
      wiki_page = assignment.build_wiki_page
      wiki_page.context_module_tags << content_tag
      expect(assignment.all_context_module_tags).to eq([])
    end
  end

  describe "#submission_type?" do
    shared_examples_for "submittable" do
      subject(:assignment) { Assignment.new }
      let(:be_type) { "be_#{submission_type}".to_sym }
      let(:build_type) { "build_#{submission_type}".to_sym }

      it "returns false if an assignment does not have a submission" \
        "or matching submission_types" do
        is_expected.not_to send(be_type)
      end

      it "returns true if the assignment has an associated submission, " \
        "and it has matching submission_types" do
        assignment.submission_types = submission_type
        assignment.send(build_type)
        expect(assignment).to send(be_type)
      end

      it "returns false if an assignment does not have its submission_types" \
        "set, even if it has an associated submission" do
        assignment.send(build_type)
        expect(assignment).not_to send(be_type)
      end

      it "returns false if an assignment does not have an associated" \
        "submission even if it has submission_types set" do
        assignment.submission_types = submission_type
        expect(assignment).not_to send(be_type)
      end
    end

    context "topics" do
      let(:submission_type) { "discussion_topic" }

      include_examples "submittable"
    end

    context "pages" do
      let(:submission_type) { "wiki_page" }

      include_examples "submittable"
    end
  end

  it "should update a submission's graded_at when grading it" do
    setup_assignment_with_homework
    @assignment.grade_student(@user, :grade => 1)
    @submission = @assignment.submissions.first
    original_graded_at = @submission.graded_at
    new_time = Time.now + 1.hour
    Time.stubs(:now).returns(new_time)
    @assignment.grade_student(@user, :grade => 2)
    @submission.reload
    expect(@submission.graded_at).not_to eql original_graded_at
  end

  describe "#update_submission" do
    before :once do
      setup_assignment_with_homework
    end

    it "should hide grading comments if assignment is muted and commenter is teacher" do
      @assignment.mute!
      @assignment.update_submission(@user, comment: 'hi', author: @teacher)
      submission = @assignment.submissions.first
      comment = submission.submission_comments.first
      expect(comment).to be_hidden
    end

    it "should not hide grading comments if assignment is not muted even if commenter is teacher" do
      @assignment.update_submission(@user, comment: 'hi', author: @teacher)
      submission = @assignment.submissions.first
      comment = submission.submission_comments.first
      expect(comment).not_to be_hidden
    end

    it "should not hide grading comments if assignment is muted and commenter is student" do
      @assignment.mute!
      @assignment.update_submission(@user, comment: 'hi', author: @student1)
      submission = @assignment.submissions.first
      comment = submission.submission_comments.first
      expect(comment).not_to be_hidden
    end

    it "should not hide grading comments if assignment is muted and no commenter is provided" do
      @assignment.mute!
      @assignment.update_submission(@user, comment: 'hi')
      submission = @assignment.submissions.first
      comment = submission.submission_comments.first
      expect(comment).not_to be_hidden
    end

    it "should hide grading comments if hidden is true" do
      @assignment.update_submission(@user, comment: 'hi', hidden: true)
      submission = @assignment.submissions.first
      comment = submission.submission_comments.first
      expect(comment).to be_hidden
    end

    it "should not hide grading comments even if muted and posted by teacher if hidden is nil" do
      @assignment.mute!
      @assignment.update_submission(@user, comment: 'hi', author: @teacher, hidden: nil)
      submission = @assignment.submissions.first
      comment = submission.submission_comments.first
      expect(comment).not_to be_hidden
    end
  end

  describe "#infer_grading_type" do
    before do
      setup_assignment_without_submission
    end

    it "infers points if none is set" do
      @assignment.grading_type = nil
      @assignment.infer_grading_type
      expect(@assignment.grading_type).to eq 'points'
    end

    it "maintains existing type for vanilla assignments" do
      @assignment.grading_type = 'letter_grade'
      @assignment.infer_grading_type
      expect(@assignment.grading_type).to eq 'letter_grade'
    end

    it "infers pass_fail for attendance assignments" do
      @assignment.grading_type = 'letter_grade'
      @assignment.submission_types = 'attendance'
      @assignment.infer_grading_type
      expect(@assignment.grading_type).to eq 'pass_fail'
    end

    it "infers not_graded for page assignments" do
      wiki_page_assignment_model course: @course
      @assignment.grading_type = 'letter_grade'
      @assignment.infer_grading_type
      expect(@assignment.grading_type).to eq 'not_graded'
    end
  end

  context "needs_grading_count" do
    before :once do
      setup_assignment_with_homework
    end

    it "should update when submissions transition state" do
      expect(@assignment.needs_grading_count).to eql(1)
      @assignment.grade_student(@user, :grade => "0")
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(0)
    end

    it "should not update when non-student submissions transition state" do
      assignment_model(course: @course)
      s = @assignment.find_or_create_submission(@teacher)
      s.submission_type = 'online_quiz'
      s.workflow_state = 'submitted'
      s.save!
      expect(@assignment.needs_grading_count).to eql(0)
      s.workflow_state = 'graded'
      s.save!
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(0)
    end

    it "should update when enrollment changes" do
      expect(@assignment.needs_grading_count).to eql(1)
      @course.enrollments.where(user_id: @user.id).first.destroy
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(0)
      e = @course.enroll_student(@user)
      e.invite
      e.accept
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(1)

      # multiple enrollments should not cause double-counting (either by creating as or updating into "active")
      section2 = @course.course_sections.create!(:name => 's2')
      e2 = @course.enroll_student(@user,
                                  :enrollment_state => 'invited',
                                  :section => section2,
                                  :allow_multiple_enrollments => true)
      e2.accept
      section3 = @course.course_sections.create!(:name => 's2')
      e3 = @course.enroll_student(@user,
                                  :enrollment_state => 'active',
                                  :section => section3,
                                  :allow_multiple_enrollments => true)
      expect(@user.enrollments.where(:workflow_state => 'active').count).to eql(3)
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(1)

      # and as long as one enrollment is still active, the count should not change
      e2.destroy
      e3.complete
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(1)

      # ok, now gone for good
      e.destroy
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(0)
      expect(@user.enrollments.where(:workflow_state => 'active').count).to eql(0)

      # enroll the user as a teacher, it should have no effect
      e4 = @course.enroll_teacher(@user)
      e4.accept
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(0)
      expect(@user.enrollments.where(:workflow_state => 'active').count).to eql(1)
    end

    it "updated_at should be set when needs_grading_count changes due to a submission" do
      expect(@assignment.needs_grading_count).to eql(1)
      old_timestamp = Time.now.utc - 1.minute
      Assignment.where(:id => @assignment).update_all(:updated_at => old_timestamp)
      @assignment.grade_student(@user, :grade => "0")
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(0)
      expect(@assignment.updated_at).to be > old_timestamp
    end

    it "updated_at should be set when needs_grading_count changes due to an enrollment change" do
      old_timestamp = Time.now.utc - 1.minute
      expect(@assignment.needs_grading_count).to eql(1)
      Assignment.where(:id => @assignment).update_all(:updated_at => old_timestamp)
      @course.enrollments.where(user_id: @user).first.destroy
      @assignment.reload
      expect(@assignment.needs_grading_count).to eql(0)
      expect(@assignment.updated_at).to be > old_timestamp
    end
  end

  context "differentiated_assignment visibility" do
    describe "students_with_visibility" do
      before :once do
        setup_differentiated_assignments
      end

      context "differentiated_assignment" do
        it "should return assignments only when a student has overrides" do
          expect(@assignment.students_with_visibility.include?(@student1)).to be_truthy
          expect(@assignment.students_with_visibility.include?(@student2)).to be_falsey
        end

        it "should not return students outside the class" do
          expect(@assignment.students_with_visibility.include?(@student3)).to be_falsey
        end
      end

      context "permissions" do
        before :once do
          @assignment.submission_types = "online_text_entry"
          @assignment.save!
        end

        it "should not allow students without visibility to submit" do
          expect(@assignment.check_policy(@student1)).to include :submit
          expect(@assignment.check_policy(@student2)).not_to include :submit
        end
      end
    end
  end

  context "grading" do
    before :once do
      setup_assignment_without_submission
    end

    context "pass fail assignments" do
      before :once do
        @assignment.grading_type = 'pass_fail'
        @assignment.points_possible = 0.0
        @assignment.save
      end

      let(:submission) { @assignment.submissions.first }

      it "preserves pass with zero points possible" do
        @assignment.grade_student(@user, :grade => 'pass')
        expect(submission.grade).to eql('complete')
      end

      it "preserves fail with zero points possible" do
        @assignment.grade_student(@user, :grade => 'fail')
        expect(submission.grade).to eql('incomplete')
      end

      it "should properly compute pass/fail for nil" do
        @assignment.points_possible = 10
        grade = @assignment.score_to_grade(nil)
        expect(grade).to eql("incomplete")
      end
    end

    it "should preserve letter grades with zero points possible" do
      @assignment.grading_type = 'letter_grade'
      @assignment.points_possible = 0.0
      @assignment.save!

      s = @assignment.grade_student(@user, :grade => 'C')
      expect(s).to be_is_a(Array)
      @assignment.reload
      expect(@assignment.submissions.size).to eql(1)
      @submission = @assignment.submissions.first
      expect(@submission.state).to eql(:graded)
      expect(@submission.score).to eql(0.0)
      expect(@submission.grade).to eql('C')
      expect(@submission.user_id).to eql(@user.id)
    end

    it "should properly calculate letter grades" do
      @assignment.grading_type = 'letter_grade'
      @assignment.points_possible = 10
      grade = @assignment.score_to_grade(8.7)
      expect(grade).to eql("B+")
    end

    it "should properly allow decimal points in grading" do
      @assignment.grading_type = 'letter_grade'
      @assignment.points_possible = 10
      grade = @assignment.score_to_grade(8.6999)
      expect(grade).to eql("B")
    end

    it "should preserve letter grades grades with nil points possible" do
      @assignment.grading_type = 'letter_grade'
      @assignment.points_possible = nil
      @assignment.save!

      s = @assignment.grade_student(@user, :grade => 'C')
      expect(s).to be_is_a(Array)
      @assignment.reload
      expect(@assignment.submissions.size).to eql(1)
      @submission = @assignment.submissions.first
      expect(@submission.state).to eql(:graded)
      expect(@submission.score).to eql(0.0)
      expect(@submission.grade).to eql('C')
      expect(@submission.user_id).to eql(@user.id)
    end

    it "should preserve gpa scale grades with nil points possible" do
      @assignment.grading_type = 'gpa_scale'
      @assignment.points_possible = nil
      @assignment.context.grading_standards.build({title: "GPA"})
      gs = @assignment.context.grading_standards.last
      gs.data = {"4.0" => 0.94,
                 "3.7" => 0.90,
                 "3.3" => 0.87,
                 "3.0" => 0.84,
                 "2.7" => 0.80,
                 "2.3" => 0.77,
                 "2.0" => 0.74,
                 "1.7" => 0.70,
                 "1.3" => 0.67,
                 "1.0" => 0.64,
                 "0" => 0.01,
                 "M" => 0.0 }
      gs.assignments << @assignment
      gs.save!
      @assignment.save!

      s = @assignment.grade_student(@user, :grade => '3.0')
      expect(s).to be_is_a(Array)
      @assignment.reload
      expect(@assignment.submissions.size).to eql(1)
      @submission = @assignment.submissions.first
      expect(@submission.state).to eql(:graded)
      expect(@submission.score).to eql(0.0)
      expect(@submission.grade).to eql('3.0')
      expect(@submission.user_id).to eql(@user.id)
    end

    describe "#grading_standard_or_default" do
      before do
        @gs1 = @course.grading_standards.create! standard_data: {
          a: {name: "OK", value: 100},
          b: {name: "Bad", value: 80},
        }
        @gs2 = @course.grading_standards.create! standard_data: {
          a: {name: "🚀", value: 100},
          b: {name: "🚽", value: 80},
        }
      end

      it "returns the assignment-specific grading standard if there is one" do
        @assignment.update_attribute :grading_standard, @gs1
        expect(@assignment.grading_standard_or_default).to eql @gs1
      end

      it "uses the course default if there is one" do
        @course.update_attribute :default_grading_standard, @gs2
        expect(@assignment.grading_standard_or_default).to eql @gs2
      end

      it "uses the canvas default" do
        expect(@assignment.grading_standard_or_default.title).to eql "Default Grading Scheme"
      end
    end

    it "should preserve gpa scale grades with zero points possible" do
      @assignment.grading_type = 'gpa_scale'
      @assignment.points_possible = 0.0
      @assignment.context.grading_standards.build({title: "GPA"})
      gs = @assignment.context.grading_standards.last
      gs.data = {"4.0" => 0.94,
                 "3.7" => 0.90,
                 "3.3" => 0.87,
                 "3.0" => 0.84,
                 "2.7" => 0.80,
                 "2.3" => 0.77,
                 "2.0" => 0.74,
                 "1.7" => 0.70,
                 "1.3" => 0.67,
                 "1.0" => 0.64,
                 "0" => 0.01,
                 "M" => 0.0 }
      gs.assignments << @assignment
      gs.save!
      @assignment.save!

      s = @assignment.grade_student(@user, :grade => '3.0')
      expect(s).to be_is_a(Array)
      @assignment.reload
      expect(@assignment.submissions.size).to eql(1)
      @submission = @assignment.submissions.first
      expect(@submission.state).to eql(:graded)
      expect(@submission.score).to eql(0.0)
      expect(@submission.grade).to eql('3.0')
      expect(@submission.user_id).to eql(@user.id)
    end

    it "should handle percent grades with nil points possible" do
      @assignment.grading_type = "percent"
      @assignment.points_possible = nil
      grade = @assignment.score_to_grade(5.0)
      expect(grade).to eql('5%')
    end

    it "should round down percent grades to 2 decimal places" do
      @assignment.grading_type = 'percent'
      @assignment.points_possible = 100
      grade = @assignment.score_to_grade(57.8934)
      expect(grade).to eql('57.89%')
    end

    it "should round up percent grades to 2 decimal places" do
      @assignment.grading_type = 'percent'
      @assignment.points_possible = 100
      grade = @assignment.score_to_grade(57.895)
      expect(grade).to eql('57.9%')
    end

    it "should give a grade to extra credit assignments" do
      @assignment.grading_type = 'points'
      @assignment.points_possible = 0.0
      @assignment.save
      s = @assignment.grade_student(@user, :grade => "1")
      expect(s).to be_is_a(Array)
      @assignment.reload
      expect(@assignment.submissions.size).to eql(1)
      @submission = @assignment.submissions.first
      expect(@submission.state).to eql(:graded)
      expect(@submission).to eql(s[0])
      expect(@submission.score).to eql(1.0)
      expect(@submission.grade).to eql("1")
      expect(@submission.user_id).to eql(@user.id)

      @submission.score = 2.0
      @submission.save
      @submission.reload
      expect(@submission.grade).to eql("2")
    end

    it "should be able to grade an already-existing submission" do
      s = @a.submit_homework(@user)
      s2 = @a.grade_student(@user, :grade => "10")
      s.reload
      expect(s).to eql(s2[0])
      # there should only be one version, even though the grade changed
      expect(s.versions.length).to eql(1)
      expect(s2[0].state).to eql(:graded)
    end

    context "group assignments" do
      before :once do
        @student1, @student2 = n_students_in_course(2)
        gc = @course.group_categories.create! name: "asdf"
        group = gc.groups.create! name: "zxcv", context: @course
        [@student1, @student2].each { |u|
          group.group_memberships.create! user: u, workflow_state: "accepted"
        }
        @assignment.update_attribute :group_category, gc
      end

      context "when excusing an assignment" do
        it "marks the assignment as excused" do
          submission, _ = @assignment.grade_student(@student, excuse: true)
          expect(submission).to be_excused
        end

        it "doesn't mark everyone in the group excused" do
          sub1, sub2 = @assignment.grade_student(
            @student1,
            excuse: true,
          )

          expect(sub1.user).to eq @student1
          expect(sub1).to be_excused
          expect(sub2).to be_nil
        end

        context "when trying to grade and excuse simultaneously" do
          it "raises an error" do
            expect(lambda {
              @assignment.grade_student(
                @student1,
                grade: 0,
                excuse: true
              )
            }).to raise_error("Cannot simultaneously grade and excuse an assignment")
          end
        end
      end

      context "when not excusing an assignment" do
        it "grades every member of the group" do
          sub1, sub2 = @assignment.grade_student(
            @student1,
            grade: 38,
            excuse: false,
          )

          expect(sub1.user).to eq @student1
          expect(sub1.grade).to eq "38"
          expect(sub2.user).to eq @student2
          expect(sub2.grade).to eq "38"
        end

        it "doesn't overwrite the grades of group members who have been excused" do
          sub1 = @assignment.grade_student(@student1, excuse: true).first
          expect(sub1).to be_excused

          sub2, sub3 = @assignment.grade_student(@student2, grade: 10)
          expect(sub1.reload).to be_excused
          expect(sub2.user).to eq @student2
          expect(sub2.grade).to eq "10"
          expect(sub3).to be_nil
        end
      end

    end
  end

  describe  "interpret_grade" do
    before :once do
      setup_assignment_without_submission
    end

    it "should return nil when no grade was entered and assignment uses a grading standard (letter grade)" do
      @assignment.points_possible = 100
      expect(@assignment.interpret_grade("")).to be_nil
    end

    it "should allow grading an assignment with nil points_possible" do
      @assignment.points_possible = nil
      expect(@assignment.interpret_grade("100%")).to eq 0
    end

    it "should not round scores" do
      @assignment.points_possible = 15
      expect(@assignment.interpret_grade("88.75%")).to eq 13.3125
    end
  end

  describe '#submit_homework' do
    before(:once) do
      course_with_student(active_all: true)
      @a = @course.assignments.create! title: "blah",
        submission_types: "online_text_entry,online_url",
        points_possible: 10
    end

    it "creates a new version for each submission" do
      setup_assignment_without_submission
      @a.submit_homework(@user)
      @a.submit_homework(@user)
      @a.submit_homework(@user)
      @a.reload
      expect(@a.submissions.first.versions.length).to eql(3)
    end

    it "doesn't mark as submitted if no submission" do
      s = @a.submit_homework(@user)
      expect(s.workflow_state).to eq "unsubmitted"
    end

    it "clears out stale submission information" do
      s = @a.submit_homework(@user, submission_type: "online_url",
                             url: "http://example.com")
      expect(s.submission_type).to eq "online_url"
      expect(s.url).to eq "http://example.com"

      s2 = @a.submit_homework(@user, submission_type: "online_text_entry",
                              body: "blah blah blah blah blah blah blah")
      expect(s2.submission_type).to eq "online_text_entry"
      expect(s2.body).to eq "blah blah blah blah blah blah blah"
      expect(s2.url).to be_nil
      expect(s2.workflow_state).to eq "submitted"

      # comments shouldn't clear out submission data
      s3 = @a.submit_homework(@user, comment: "BLAH BLAH")
      expect(s3.body).to eq "blah blah blah blah blah blah blah"
      expect(s3.submission_comments.first.comment).to eq "BLAH BLAH"
      expect(s3.submission_type).to eq "online_text_entry"
    end
  end

  describe "muting" do
    before :once do
      assignment_model(course: @course)
    end

    it "should default to unmuted" do
      expect(@assignment.muted?).to eql false
    end

    it "should be mutable" do
      expect(@assignment.respond_to?(:mute!)).to eql true
      @assignment.mute!
      expect(@assignment.muted?).to eql true
    end

    it "should be unmutable" do
      expect(@assignment.respond_to?(:unmute!)).to eql true
      @assignment.mute!
      @assignment.unmute!
      expect(@assignment.muted?).to eql false
    end
  end

  describe "infer_times" do
    it "should set to all_day" do
      assignment_model(:due_at => "Sep 3 2008 12:00am",
                      :lock_at => "Sep 3 2008 12:00am",
                      :unlock_at => "Sep 3 2008 12:00am",
                      :course => @course)
      expect(@assignment.all_day).to eql(false)
      @assignment.infer_times
      @assignment.save!
      expect(@assignment.all_day).to eql(true)
      expect(@assignment.due_at.strftime("%H:%M")).to eql("23:59")
      expect(@assignment.lock_at.strftime("%H:%M")).to eql("23:59")
      expect(@assignment.unlock_at.strftime("%H:%M")).to eql("00:00")
      expect(@assignment.all_day_date).to eql(Date.parse("Sep 3 2008"))
    end

    it "should not set to all_day without infer_times call" do
      assignment_model(:due_at => "Sep 3 2008 12:00am",
                       :course => @course)
      expect(@assignment.all_day).to eql(false)
      expect(@assignment.due_at.strftime("%H:%M")).to eql("00:00")
      expect(@assignment.all_day_date).to eql(Date.parse("Sep 3 2008"))
    end
  end

  describe "all_day and all_day_date from due_at" do
    def fancy_midnight(opts={})
      zone = opts[:zone] || Time.zone
      Time.use_zone(zone) do
        time = opts[:time] || Time.zone.now
        time.in_time_zone.midnight + 1.day - 1.minute
      end
    end

    before :once do
      @assignment = assignment_model(course: @course)
    end

    it "should interpret 11:59pm as all day with no prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq true
    end

    it "should interpret 11:59pm as all day with same-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.day
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq true
    end

    it "should interpret 11:59pm as all day with other-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Baghdad')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq true
    end

    it "should interpret 11:59pm as all day with non-all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq true
    end

    it "should not interpret non-11:59pm as all day no prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      expect(@assignment.all_day).to eq false
    end

    it "should not interpret non-11:59pm as all day with same-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq false
    end

    it "should not interpret non-11:59pm as all day with other-tz all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Baghdad')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq false
    end

    it "should not interpret non-11:59pm as all day with non-all-day prior value" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska') + 2.hour
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq false
    end

    it "should preserve all-day when only changing time zone" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      expect(@assignment.all_day).to eq true
    end

    it "should preserve non-all-day when only changing time zone" do
      @assignment.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @assignment.save!
      @assignment.due_at = fancy_midnight(:zone => 'Alaska')
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day).to eq false
    end

    it "should determine date from due_at's timezone" do
      @assignment.due_at = Date.today.in_time_zone('Baghdad') + 1.hour # 01:00:00 AST +03:00 today
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      expect(@assignment.all_day_date).to eq Date.today

      @assignment.due_at = @assignment.due_at.in_time_zone('Alaska') - 2.hours # 12:00:00 AKDT -08:00 previous day
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day_date).to eq Date.today - 1.day
    end

    it "should preserve all-day date when only changing time zone" do
      @assignment.due_at = Date.today.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      @assignment.due_at = @assignment.due_at.in_time_zone('Alaska') # 13:00:00 AKDT -08:00 previous day
      @assignment.time_zone_edited = 'Alaska'
      @assignment.save!
      expect(@assignment.all_day_date).to eq Date.today
    end

    it "should preserve non-all-day date when only changing time zone" do
      @assignment.due_at = Date.today.in_time_zone('Alaska') - 11.hours # 13:00:00 AKDT -08:00 previous day
      @assignment.save!
      @assignment.due_at = @assignment.due_at.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
      @assignment.time_zone_edited = 'Baghdad'
      @assignment.save!
      expect(@assignment.all_day_date).to eq Date.today - 1.day
    end
  end

  it "should destroy group overrides when the group category changes" do
    @assignment = assignment_model(course: @course)
    @assignment.group_category = group_category(context: @assignment.context)
    @assignment.save!

    overrides = 5.times.map do
      override = @assignment.assignment_overrides.scope.new
      override.set = @assignment.group_category.groups.create!(context: @assignment.context)
      override.save!

      expect(override.workflow_state).to eq 'active'
      override
    end
    old_version_number = @assignment.version_number

    @assignment.group_category = group_category(context: @assignment.context, name: "bar")
    @assignment.save!

    overrides.each do |override|
      override.reload

      expect(override.workflow_state).to eq 'deleted'
      expect(override.versions.size).to eq 2
      expect(override.assignment_version).to eq old_version_number
    end
  end

  context "concurrent inserts" do
    before :once do
      assignment_model(course: @course)
      @assignment.context.reload

      @assignment.submissions.scope.delete_all
    end

    def concurrent_inserts
      real_sub = @assignment.submissions.build(user: @user)

      mock_submissions = Submission.none
      mock_submissions.stubs(:build).returns(real_sub).once
      @assignment.stubs(:submissions).returns(mock_submissions)

      sub = nil
      expect {
        sub = yield(@assignment, @user)
      }.not_to raise_error

      expect(sub).not_to be_new_record
      expect(sub).to eql real_sub
    end

    it "should handle them gracefully in find_or_create_submission" do
      concurrent_inserts do |assignment, user|
        assignment.find_or_create_submission(user)
      end
    end

    it "should handle them gracefully in submit_homework" do
      concurrent_inserts do |assignment, user|
        assignment.submit_homework(user, :body => "test")
      end
    end
  end

  context "peer reviews" do
    before :once do
      assignment_model(course: @course)
    end

    context "basic assignment" do
      before :once do
        @users = create_users_in_course(@course, 10.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
        @a.reload
        @submissions = @users.map do |u|
          @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
        end
      end

      it "should assign peer reviews" do
        @a.peer_review_count = 1
        res = @a.assign_peer_reviews
        expect(res.length).to eql(@submissions.length)
        @submissions.each do |s|
          expect(res.map(&:asset)).to be_include(s)
          expect(res.map(&:assessor_asset)).to be_include(s)
        end
      end

      it "should not assign peer reviews to fake students" do
        fake_student = @course.student_view_student
        fake_sub = @a.submit_homework(fake_student, :submission_type => "online_url", :url => "http://www.google.com")

        @a.peer_review_count = 1
        res = @a.assign_peer_reviews
        expect(res.length).to eql(@submissions.length)
        expect(res.map(&:asset)).not_to be_include(fake_sub)
        expect(res.map(&:assessor_asset)).not_to be_include(fake_sub)
      end

      it "should assign when already graded" do
        @users.each do |u|
          @a.grade_student(u, :grader => @teacher, :grade => '100')
        end
        @a.peer_review_count = 1
        res = @a.assign_peer_reviews
        expect(res.length).to eql(@submissions.length)
        @submissions.each do |s|
          expect(res.map{|a| a.asset}).to be_include(s)
          expect(res.map{|a| a.assessor_asset}).to be_include(s)
        end
      end
    end

    it "should schedule auto_assign when variables are right" do
      @a.peer_reviews = true
      @a.automatic_peer_reviews = true
      @a.due_at = Time.zone.now

      expects_job_with_tag('Assignment#do_auto_peer_review') {
        @a.save!
      }
    end

    it "should not schedule auto_assign when skip_schedule_peer_reviews is set" do
      @a.peer_reviews = true
      @a.automatic_peer_reviews = true
      @a.due_at = Time.zone.now
      @a.skip_schedule_peer_reviews = true

      expects_job_with_tag('Assignment#do_auto_peer_review', 0) {
        @a.save!
      }
    end

    it "should reset peer_reviews_assigned when the assign_at time changes" do
      @a.peer_reviews = true
      @a.automatic_peer_reviews = true
      @a.due_at = 1.day.ago
      @a.peer_reviews_assigned = true
      @a.save!

      @a.assign_peer_reviews
      expect(@a.peer_reviews_assigned).to be_truthy

      @a.peer_reviews_assign_at = 1.day.from_now
      @a.save!

      expect(@a.peer_reviews_assigned).to be_falsey
    end

    it "should allow setting peer_reviews_assign_at" do
      now = Time.now
      @assignment.peer_reviews_assign_at = now
      expect(@assignment.peer_reviews_assign_at).to eq now
    end

    it "should assign multiple peer reviews" do
      @a.reload
      @submissions = []
      users = create_users_in_course(@course, 30.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
      users.each do |u|
        @submissions << @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 5
      res = @a.assign_peer_reviews
      expect(res.length).to eql(@submissions.length * @a.peer_review_count)
      @submissions.each do |s|
        assets = res.select{|a| a.asset == s}
        expect(assets.length).to eql(@a.peer_review_count)
        expect(assets.map{|a| a.assessor_id}.uniq.length).to eql(assets.length)

        assessors = res.select{|a| a.assessor_asset == s}
        expect(assessors.length).to eql(@a.peer_review_count)
        expect(assessors.map(&:asset_id).uniq.length).to eq @a.peer_review_count
      end
    end

    it "should assign late peer reviews" do
      @submissions = []
      users = create_users_in_course(@course, 5.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
      users.each do |u|
        #@a.context.reload
        @submissions << @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 2
      res = @a.assign_peer_reviews
      expect(res.length).to eql(@submissions.length * 2)
      user = create_users_in_course(@course, [{name: "new user"}], return_type: :record).first
      @a.reload
      s = @a.submit_homework(user, :submission_type => "online_url", :url => "http://www.google.com")
      res = @a.assign_peer_reviews
      expect(res.length).to be >= 2
      expect(res.any?{|a| a.assessor_asset == s}).to eql(true)
    end

    it "should assign late peer reviews to each other if there is more than one" do
      @a.reload
      @submissions = []
      users = create_users_in_course(@course, 10.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
      users.each do |u|
        @submissions << @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 2
      res = @a.assign_peer_reviews
      expect(res.length).to eql(@submissions.length * 2)

      @late_submissions = []
      users = create_users_in_course(@course, 3.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
      users.each do |u|
        @late_submissions << @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
      end
      res = @a.assign_peer_reviews
      expect(res.length).to be >= 6
      ids = @late_submissions.map{|s| s.user_id}
    end

    context "differentiated_assignments" do
      before :once do
        setup_differentiated_assignments
        @submissions = []
        [@student1, @student2].each do |u|
          @submissions << @assignment.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
        end
      end
      context "feature on" do
        it "should assign peer reviews only to students with visibility" do
          @assignment.peer_review_count = 1
          res = @assignment.assign_peer_reviews
          expect(res.length).to eql(0)
          @submissions.each do |s|
            expect(res.map{|a| a.asset}).not_to be_include(s)
            expect(res.map{|a| a.assessor_asset}).not_to be_include(s)
          end

          # once graded the student will have visibility
          # and will therefore show up in the peer reviews
          @assignment.grade_student(@student2, :grader => @teacher, :grade => '100')

          res = @assignment.assign_peer_reviews
          expect(res.length).to eql(@submissions.length)
          @submissions.each do |s|
            expect(res.map{|a| a.asset}).to be_include(s)
            expect(res.map{|a| a.assessor_asset}).to be_include(s)
          end
        end

      end
    end
  end

  context "grading scales" do
    before :once do
      setup_assignment_without_submission
    end

    context "letter grades" do
      before :once do
        @assignment.update_attributes(:grading_type => 'letter_grade', :points_possible => 20)
      end

      it "should update grades when assignment changes" do
        @enrollment = @student.enrollments.first
        @assignment.reload
        @sub = @assignment.grade_student(@student, :grader => @teacher, :grade => 'C').first
        expect(@sub.grade).to eql('C')
        expect(@sub.score).to eql(15.2)
        expect(@enrollment.reload.computed_current_score).to eq 76

        @assignment.points_possible = 30
        @assignment.save!
        @sub.reload
        expect(@sub.score).to eql(15.2)
        expect(@sub.grade).to eql('F')
        expect(@enrollment.reload.computed_current_score).to eq 50.67
      end

      it "should accept lowercase letter grades" do
        @assignment.reload
        @sub = @assignment.grade_student(@student, :grader => @teacher, :grade => 'c').first
        expect(@sub.grade).to eql('C')
        expect(@sub.score).to eql(15.2)
      end
    end

    context "gpa scale grades" do
      before :once do
        @assignment.update_attributes(:grading_type => 'gpa_scale', :points_possible => 20)
        @course.grading_standards.build({title: "GPA"})
        gs = @course.grading_standards.last
        gs.data = {"4.0" => 0.94,
                   "3.7" => 0.90,
                   "3.3" => 0.87,
                   "3.0" => 0.84,
                   "2.7" => 0.80,
                   "2.3" => 0.77,
                   "2.0" => 0.74,
                   "1.7" => 0.70,
                   "1.3" => 0.67,
                   "1.0" => 0.64,
                   "0" => 0.01,
                   "M" => 0.0 }
        gs.assignments << @a
        gs.save!
      end

      it "should update grades when assignment changes" do
        @enrollment = @student.enrollments.first
        @assignment.reload
        @sub = @assignment.grade_student(@student, :grader => @teacher, :grade => '2.0').first
        expect(@sub.grade).to eql('2.0')
        expect(@sub.score).to eql(15.2)
        expect(@enrollment.reload.computed_current_score).to eq 76

        @assignment.points_possible = 30
        @assignment.save!
        @sub.reload
        expect(@sub.score).to eql(15.2)
        expect(@sub.grade).to eql('0')
        expect(@enrollment.reload.computed_current_score).to eq 50.67
      end

      it "should accept lowercase gpa grades" do
        @assignment.reload
        @sub = @assignment.grade_student(@student, :grader => @teacher, :grade => 'm').first
        expect(@sub.grade).to eql('M')
        expect(@sub.score).to eql(0.0)
      end
    end
  end

  context "as_json" do
    before :once do
      assignment_model(course: @course)
    end

    it "should include permissions if specified" do
      expect(@assignment.to_json).not_to match(/permissions/)
      expect(@assignment.to_json(:permissions => {:user => nil})).to match(/\"permissions\"\s*:\s*\{/)
      expect(@assignment.grants_right?(@teacher, :create)).to eql(true)
      expect(@assignment.to_json(:permissions => {:user => @teacher, :session => nil})).to match(/\"permissions\"\s*:\s*\{\"/)
      hash = @assignment.as_json(:permissions => {:user => @teacher, :session => nil})
      expect(hash["assignment"]).not_to be_nil
      expect(hash["assignment"]["permissions"]).not_to be_nil
      expect(hash["assignment"]["permissions"]).not_to be_empty
      expect(hash["assignment"]["permissions"]["read"]).to eql(true)
    end

    it "should serialize with roots included in nested elements" do
      @course.assignments.create!(:title => "some assignment")
      hash = @course.as_json(:include => :assignments)
      expect(hash["course"]).not_to be_nil
      expect(hash["course"]["assignments"]).not_to be_empty
      expect(hash["course"]["assignments"][0]).not_to be_nil
      expect(hash["course"]["assignments"][0]["assignment"]).not_to be_nil
    end

    it "should serialize with permissions" do
      hash = @course.as_json(:permissions => {:user => @teacher, :session => nil} )
      expect(hash["course"]).not_to be_nil
      expect(hash["course"]["permissions"]).not_to be_nil
      expect(hash["course"]["permissions"]).not_to be_empty
      expect(hash["course"]["permissions"]["read"]).to eql(true)
    end

    it "should exclude root" do
      hash = @course.as_json(:include_root => false, :permissions => {:user => @teacher, :session => nil} )
      expect(hash["course"]).to be_nil
      expect(hash["name"]).to eql(@course.name)
      expect(hash["permissions"]).not_to be_nil
      expect(hash["permissions"]).not_to be_empty
      expect(hash["permissions"]["read"]).to eql(true)
    end

    it "should include group_category" do
      assignment_model(:group_category => "Something", :course => @course)
      hash = @assignment.as_json
      expect(hash["assignment"]["group_category"]).to eq "Something"
    end
  end

  context "ical" do
    it ".to_ics should not fail for null due dates" do
      assignment_model(:due_at => "", :course => @course)
      res = @assignment.to_ics
      expect(res).not_to be_nil
      expect(res.match(/DTSTART/)).to be_nil
    end

    it ".to_ics should not return data for null due dates" do
      assignment_model(:due_at => "", :course => @course)
      res = @assignment.to_ics(in_own_calendar: false)
      expect(res).to be_nil
    end

    it ".to_ics should return string data for assignments with due dates" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :course => @course)
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      res = @assignment.to_ics
      expect(res).not_to be_nil
      expect(res.match(/DTEND:20080903T115500Z/)).not_to be_nil
      expect(res.match(/DTSTART:20080903T115500Z/)).not_to be_nil
      expect(res.match(/DTSTAMP:20080903T120500Z/)).not_to be_nil
    end

    it ".to_ics should return string data for assignments with due dates in correct tz" do
      Time.zone = 'Alaska' # -0800
      assignment_model(:due_at => "Sep 3 2008 11:55am", :course => @course)
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
      res = @assignment.to_ics
      expect(res).not_to be_nil
      expect(res.match(/DTEND:20080903T195500Z/)).not_to be_nil
      expect(res.match(/DTSTART:20080903T195500Z/)).not_to be_nil
      expect(res.match(/DTSTAMP:20080903T200500Z/)).not_to be_nil
    end

    it ".to_ics should return data for assignments with due dates" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :course => @course)
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      res = @assignment.to_ics(in_own_calendar: false)
      expect(res).not_to be_nil
      expect(res.start.icalendar_tzid).to eq 'UTC'
      expect(res.start.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.end.icalendar_tzid).to eq 'UTC'
      expect(res.end.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.dtstamp.icalendar_tzid).to eq 'UTC'
      expect(res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
    end

    it ".to_ics should return data for assignments with due dates in correct tz" do
      Time.zone = 'Alaska' # -0800
      assignment_model(:due_at => "Sep 3 2008 11:55am", :course => @course)
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
      res = @assignment.to_ics(in_own_calendar: false)
      expect(res).not_to be_nil
      expect(res.start.icalendar_tzid).to eq 'UTC'
      expect(res.start.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.end.icalendar_tzid).to eq 'UTC'
      expect(res.end.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.dtstamp.icalendar_tzid).to eq 'UTC'
      expect(res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
    end

    it ".to_ics should return string dates for all_day events" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:59pm", :course => @course)
      expect(@assignment.all_day).to eql(true)
      res = @assignment.to_ics
      expect(res.match(/DTSTART;VALUE=DATE:20080903/)).not_to be_nil
      expect(res.match(/DTEND;VALUE=DATE:20080903/)).not_to be_nil
    end

    it ".to_ics should populate uid and summary fields" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :title => "assignment title", :course => @course)
      ev = @a.to_ics(in_own_calendar: false)
      expect(ev.uid).to eq "event-assignment-#{@a.id}"
      expect(ev.summary).to eq "#{@a.title} [#{@a.context.course_code}]"
      # TODO: ev.url.should == ?
    end

    it ".to_ics should apply due_at override information" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :title => "assignment title", :course => @course)
      @override = @a.assignment_overrides.build
      @override.set = @course.default_section
      @override.override_due_at(Time.zone.parse("Sep 28 2008 11:55am"))
      @override.save!

      assignment = AssignmentOverrideApplicator.assignment_with_overrides(@a, [@override])
      ev = assignment.to_ics(in_own_calendar: false)
      expect(ev.uid).to eq "event-assignment-override-#{@override.id}"
      expect(ev.summary).to eq "#{@a.title} (#{@override.title}) [#{assignment.context.course_code}]"
      #TODO: ev.url.should == ?
    end

    it ".to_ics should not apply non-due_at override information" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :title => "assignment title", :course => @course)
      @override = @a.assignment_overrides.build
      @override.set = @course.default_section
      @override.override_lock_at(Time.zone.parse("Sep 28 2008 11:55am"))
      @override.save!

      assignment = AssignmentOverrideApplicator.assignment_with_overrides(@a, [@override])
      ev = assignment.to_ics(in_own_calendar: false)
      expect(ev.uid).to eq "event-assignment-#{@a.id}"
      expect(ev.summary).to eq "#{@a.title} [#{@a.context.course_code}]"
    end
  end

  context "quizzes" do
    before :once do
      assignment_model(:submission_types => "online_quiz", :course => @course)
    end

    it "should create a quiz if none exists and specified" do
      @a.reload
      expect(@a.submission_types).to eql('online_quiz')
      expect(@a.quiz).not_to be_nil
      expect(@a.quiz.assignment_id).to eql(@a.id)
      @a.due_at = Time.now
      @a.save
      @a.reload
      expect(@a.quiz).not_to be_nil
      expect(@a.quiz.assignment_id).to eql(@a.id)
    end

    it "should delete a quiz if no longer specified" do
      @a.reload
      expect(@a.submission_types).to eql('online_quiz')
      expect(@a.quiz).not_to be_nil
      expect(@a.quiz.assignment_id).to eql(@a.id)
      @a.submission_types = 'on_paper'
      @a.save!
      @a.reload
      expect(@a.quiz).to be_nil
    end

    it "should not delete the assignment when unlinked from a quiz" do
      @a.reload
      expect(@a.submission_types).to eql('online_quiz')
      @quiz = @a.quiz
      @quiz.unpublish!
      expect(@quiz).not_to be_nil
      expect(@quiz.state).to eql(:unpublished)
      expect(@quiz.assignment_id).to eql(@a.id)
      @a.submission_types = 'on_paper'
      @a.save!
      @quiz = Quizzes::Quiz.find(@quiz.id)
      expect(@quiz.assignment_id).to eql(nil)
      expect(@quiz.state).to eql(:deleted)
      @a.reload
      expect(@a.quiz).to be_nil
      expect(@a.state).to eql(:unpublished)
    end

    it "should not delete the quiz if non-empty when unlinked" do
      @a.reload
      expect(@a.submission_types).to eql('online_quiz')
      @quiz = @a.quiz
      expect(@quiz).not_to be_nil
      expect(@quiz.assignment_id).to eql(@a.id)
      @quiz.quiz_questions.create!()
      @quiz.generate_quiz_data
      @quiz.save!
      @a.quiz.reload
      expect(@quiz.root_entries).not_to be_empty
      @a.submission_types = 'on_paper'
      @a.save!
      @a.reload
      expect(@a.quiz).to be_nil
      expect(@a.state).to eql(:published)
      @quiz = Quizzes::Quiz.find(@quiz.id)
      expect(@quiz.assignment_id).to eql(nil)
      expect(@quiz.state).to eql(:available)
    end

    it "should grab the original quiz if unlinked and relinked" do
      @a.reload
      expect(@a.submission_types).to eql('online_quiz')
      @quiz = @a.quiz
      expect(@quiz).not_to be_nil
      expect(@quiz.assignment_id).to eql(@a.id)
      @a.quiz.reload
      @a.submission_types = 'on_paper'
      @a.save!
      @a.submission_types = 'online_quiz'
      @a.save!
      @a.reload
      expect(@a.quiz).to eql(@quiz)
      expect(@a.state).to eql(:published)
      @quiz.reload
      expect(@quiz.state).to eql(:available)
    end

    it "updates the draft state of its associated quiz" do
      @a.reload
      @a.publish
      @a.save!
      expect(@a.quiz.reload).to be_published
      @a.unpublish
      expect(@a.quiz.reload).not_to be_published
    end

    context "#quiz?" do
      it "knows that it is a quiz" do
        @a.reload
        expect(@a.quiz?).to be true
      end

      it "knows that an assignment is not a quiz" do
        @a.reload
        @a.quiz = nil
        @a.submission_types = 'postal_delivery_of_an_elephant'
        expect(@a.quiz?).to be false
      end
    end
  end

  describe "linked submissions" do
    shared_examples_for "submittable" do
      before :once do
        assignment_model(:course => @course, :submission_types => submission_type, :updating_user => @teacher)
      end

      it "should create a record if none exists and specified" do
        expect(@a.submission_types).to eql(submission_type)
        submittable = @a.send(submission_type)
        expect(submittable).not_to be_nil
        expect(submittable.assignment_id).to eql(@a.id)
        expect(submittable.user_id).to eql(@teacher.id)
        @a.due_at = Time.zone.now
        @a.save
        @a.reload
        submittable = @a.send(submission_type)
        expect(submittable).not_to be_nil
        expect(submittable.assignment_id).to eql(@a.id)
        expect(submittable.user_id).to eql(@teacher.id)
      end

      it "should delete a record if no longer specified" do
        expect(@a.submission_types).to eql(submission_type)
        submittable = @a.send(submission_type)
        expect(submittable).not_to be_nil
        expect(submittable.assignment_id).to eql(@a.id)
        @a.submission_types = 'on_paper'
        @a.save!
        @a.reload
        submittable = @a.send(submission_type)
        expect(submittable).to be_nil
      end
    end

    context "topics" do
      let(:submission_type) { "discussion_topic" }
      let(:submission_class) { DiscussionTopic }

      include_examples "submittable"

      it "should not delete the topic if non-empty when unlinked" do
        expect(@a.submission_types).to eql(submission_type)
        @topic = @a.discussion_topic
        expect(@topic).not_to be_nil
        expect(@topic.assignment_id).to eql(@a.id)
        @topic.discussion_entries.create!(:user => @user, :message => "testing")
        @a.discussion_topic.reload
        @a.submission_types = 'on_paper'
        @a.save!
        @a.reload
        expect(@a.discussion_topic).to be_nil
        expect(@a.state).to eql(:published)
        @topic = submission_class.find(@topic.id)
        expect(@topic.assignment_id).to eql(nil)
        expect(@topic.state).to eql(:active)
      end

      it "should grab the original topic if unlinked and relinked" do
        expect(@a.submission_types).to eql(submission_type)
        @topic = @a.discussion_topic
        expect(@topic).not_to be_nil
        expect(@topic.assignment_id).to eql(@a.id)
        @topic.discussion_entries.create!(:user => @user, :message => "testing")
        @a.discussion_topic.reload
        @a.submission_types = 'on_paper'
        @a.save!
        @a.submission_types = 'discussion_topic'
        @a.save!
        @a.reload
        expect(@a.discussion_topic).to eql(@topic)
        expect(@a.state).to eql(:published)
        @topic.reload
        expect(@topic.state).to eql(:active)
      end

      it "should not delete the assignment when unlinked from a topic" do
        expect(@a.submission_types).to eql(submission_type)
        submittable = @a.send(submission_type)
        expect(submittable).not_to be_nil
        expect(submittable.state).to eql(:active)
        expect(submittable.assignment_id).to eql(@a.id)
        @a.submission_types = 'on_paper'
        @a.save!
        submittable = submission_class.find(submittable.id)
        expect(submittable.assignment_id).to eql(nil)
        expect(submittable.state).to eql(:deleted)
        @a.reload
        submittable = @a.send(submission_type)
        expect(submittable).to be_nil
        expect(@a.state).to eql(:published)
      end
    end

    context "pages" do
      let(:submission_type) { "wiki_page" }
      let(:submission_class) { WikiPage }

      context "feature enabled" do
        before(:once) { @course.enable_feature!(:conditional_release) }

        include_examples "submittable"

        it "should not delete the assignment when unlinked from a page" do
          expect(@a.submission_types).to eql(submission_type)
          submittable = @a.send(submission_type)
          expect(submittable).not_to be_nil
          expect(submittable.state).to eql(:active)
          expect(submittable.assignment_id).to eql(@a.id)
          @a.submission_types = 'on_paper'
          @a.save!
          expect(submission_class.exists?(submittable.id)).to be_falsey
          @a.reload
          submittable = @a.send(submission_type)
          expect(submittable).to be_nil
          expect(@a.state).to eql(:published)
        end
      end

      it "should not create a record if feature is disabled" do
        expect do
          assignment_model(:course => @course, :submission_types => 'wiki_page', :updating_user => @teacher)
        end.not_to change { WikiPage.count }
        expect(@a.submission_types).to eql(submission_type)
        submittable = @a.send(submission_type)
        expect(submittable).to be_nil
      end
    end
  end

  context "participants" do
    before :once do
      setup_differentiated_assignments(ta: true)
    end

    it 'returns users with visibility' do
      expect(@assignment.participants.length).to eq(4) #teacher, TA, 2 students
    end

    it 'includes students with visibility' do
      expect(@assignment.participants.include?(@student1)).to be_truthy
    end

    it 'excludes students without visibility' do
      expect(@assignment.participants.include?(@student2)).to be_falsey
    end

    it 'includes admins with visibility' do
      expect(@assignment.participants.include?(@teacher)).to be_truthy
      expect(@assignment.participants.include?(@ta)).to be_truthy
    end

    context "including observers" do
      before do
        oe = @assignment.context.enroll_user(user_with_pseudonym(active_all: true), 'ObserverEnrollment',:enrollment_state => 'active')
        @course_level_observer = oe.user

        oe = @assignment.context.enroll_user(user_with_pseudonym(active_all: true), 'ObserverEnrollment',:enrollment_state => 'active')
        oe.associated_user_id = @student1.id
        oe.save!
        @student1_observer = oe.user

        oe = @assignment.context.enroll_user(user_with_pseudonym(active_all: true), 'ObserverEnrollment',:enrollment_state => 'active')
        oe.associated_user_id = @student2.id
        oe.save!
        @student2_observer = oe.user
      end

      it "should include course_level observers" do
        expect(@assignment.participants(include_observers: true).include?(@course_level_observer)).to be_truthy
      end

      it "should exclude student observers if their student does not have visibility" do
        expect(@assignment.participants(include_observers: true).include?(@student1_observer)).to be_truthy
        expect(@assignment.participants(include_observers: true).include?(@student2_observer)).to be_falsey
      end

      it "should exclude all observers unless opt is given" do
        expect(@assignment.participants.include?(@student1_observer)).to be_falsey
        expect(@assignment.participants.include?(@student2_observer)).to be_falsey
        expect(@assignment.participants.include?(@course_level_observer)).to be_falsey
      end
    end
  end

  context "broadcast policy" do
    context "due date changed" do
      before :once do
        Notification.create(:name => 'Assignment Due Date Changed')
      end

      it "should create a message when an assignment due date has changed" do
        assignment_model(:title => 'Assignment with unstable due date', :course => @course)
        @a.created_at = 1.month.ago
        @a.due_at = Time.now + 60
        @a.save!
        expect(@a.messages_sent).to be_include('Assignment Due Date Changed')
      end

      it "should NOT create a message when everything but the assignment due date has changed" do
        t = Time.parse("Sep 1, 2009 5:00pm")
        assignment_model(:title => 'Assignment with unstable due date', :due_at => t, :course => @course)
        expect(@a.due_at).to eql(t)
        @a.submission_types = "online_url"
        @a.title = "New Title"
        @a.due_at = t + 1
        @a.description = "New description"
        @a.points_possible = 50
        @a.save!
        expect(@a.messages_sent).not_to be_include('Assignment Due Date Changed')
      end
    end

    context "assignment graded" do
      before(:once) { setup_assignment_with_students }

      specify { expect(@assignment).to be_published }

      it "should notify students when their grade is changed" do
        @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
        expect(@sub2.messages_sent).not_to be_empty
        expect(@sub2.messages_sent['Submission Graded']).not_to be_nil
        expect(@sub2.messages_sent['Submission Grade Changed']).to be_nil
        @sub2.update_attributes(:graded_at => Time.now - 60*60)
        @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
        expect(@sub2.messages_sent).not_to be_empty
        expect(@sub2.messages_sent['Submission Graded']).to be_nil
        expect(@sub2.messages_sent['Submission Grade Changed']).not_to be_nil
      end

      it "should notify affected students on a mass-grade change" do
        skip "CNVS-5969 - Setting a default grade should send a 'Submission Graded' notification"
        @assignment.set_default_grade(:default_grade => 10)
        msg_sub1 = @assignment.submissions.detect{|s| s.id = @sub1.id}
        expect(msg_sub1.messages_sent).not_to be_nil
        expect(msg_sub1.messages_sent['Submission Grade Changed']).not_to be_nil
        msg_sub2 = @assignment.submissions.detect{|s| s.id = @sub2.id}
        expect(msg_sub2.messages_sent).not_to be_nil
        expect(msg_sub2.messages_sent['Submission Graded']).not_to be_nil
      end

      describe 'while they are muted' do
        before(:once) { @assignment.mute! }

        specify { expect(@assignment).to be_muted }

        it "should not notify affected students on a mass-grade change if muted" do
          skip "CNVS-5969 - Setting a default grade should send a 'Submission Graded' notification"
          @assignment.set_default_grade(:default_grade => 10)
          expect(@assignment.messages_sent).to be_empty
        end

        it "should not notify students when their grade is changed if muted" do
          @sub2 = @assignment.grade_student(@stu2, :grade => 8).first
          @sub2.update_attributes(:graded_at => Time.now - 60*60)
          @sub2 = @assignment.grade_student(@stu2, :grade => 9).first
          expect(@sub2.messages_sent).to be_empty
        end
      end

      it "should include re-submitted submissions in the list of submissions needing grading" do
        expect(@assignment).to be_published
        expect(@assignment.submissions.size).to eq 1
        expect(Assignment.need_grading_info.where(id: @assignment).first).to be_nil
        @assignment.submit_homework(@stu1, :body => "Changed my mind!")
        @sub1.reload
        expect(@sub1.body).to eq "Changed my mind!"
        expect(Assignment.need_grading_info.where(id: @assignment).first).not_to be_nil
      end
    end

    context "assignment changed" do
      before :once do
        Notification.create(:name => 'Assignment Changed')
        assignment_model(course: @course)
      end

      it "should create a message when an assignment changes after it's been published" do
        @a.created_at = Time.parse("Jan 2 2000")
        @a.description = "something different"
        @a.notify_of_update = true
        @a.save
        expect(@a.messages_sent).to be_include('Assignment Changed')
      end

      it "should NOT create a message when an assignment changes SHORTLY AFTER it's been created" do
        @a.description = "something different"
        @a.save
        expect(@a.messages_sent).not_to be_include('Assignment Changed')
      end

      it "should not create a message when a muted assignment changes" do
        @a.mute!
        @a = Assignment.find(@a.id) # blank slate for messages_sent
        @a.description = "something different"
        @a.save
        expect(@a.messages_sent).to be_empty
      end
    end

    context "assignment created" do
      before :once do
        Notification.create(:name => 'Assignment Created')
      end

      it "should create a message when an assignment is added to a course in process" do
        assignment_model(:course => @course)
        expect(@a.messages_sent).to be_include('Assignment Created')
      end

      it "should not create a message in an unpublished course" do
        Notification.create(:name => 'Assignment Created')
        course_with_teacher(:active_user => true)
        assignment_model(:course => @course)
        expect(@a.messages_sent).not_to be_include('Assignment Created')
      end
    end

    context "assignment unmuted" do
      before :once do
        Notification.create(:name => 'Assignment Unmuted')
      end

      it "should create a message when an assignment is unmuted" do
        assignment_model(:course => @course)
        @assignment.broadcast_unmute_event
        expect(@assignment.messages_sent).to be_include('Assignment Unmuted')
      end

      it "should not create a message in an unpublished course" do
        course
        assignment_model(:course => @course)
        @assignment.broadcast_unmute_event
        expect(@assignment.messages_sent).not_to be_include('Assignment Unmuted')
      end
    end

    context "varied due date notifications" do
      before :once do
        @teacher.communication_channels.create(:path => "teacher@instructure.com").confirm!

        @studentA = user_with_pseudonym(:active_all => true, :name => 'StudentA', :username => 'studentA@instructure.com')
        @ta = user_with_pseudonym(:active_all => true, :name => 'TA1', :username => 'ta1@instructure.com')
        @course.enroll_student(@studentA).update_attribute(:workflow_state, 'active')
        @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :limit_privileges_to_course_section => true)

        @section2 = @course.course_sections.create!(:name => 'section 2')
        @studentB = user_with_pseudonym(:active_all => true, :name => 'StudentB', :username => 'studentB@instructure.com')
        @ta2 = user_with_pseudonym(:active_all => true, :name => 'TA2', :username => 'ta2@instructure.com')
        @section2.enroll_user(@studentB, 'StudentEnrollment', 'active')
        @course.enroll_user(@ta2, 'TaEnrollment', :section => @section2, :enrollment_state => 'active', :limit_privileges_to_course_section => true)

        Time.zone = 'Alaska'
        default_due = DateTime.parse("01 Jan 2011 14:00 AKST")
        section_2_due = DateTime.parse("02 Jan 2011 14:00 AKST")
        @assignment = @course.assignments.build(:title => "some assignment", :due_at => default_due, :submission_types => ['online_text_entry'])
        @assignment.save_without_broadcasting!
        override = @assignment.assignment_overrides.build
        override.set = @section2
        override.override_due_at(section_2_due)
        override.save!
      end

      context "assignment created" do
        before :once do
          Notification.create(:name => 'Assignment Created')
        end

        it "should notify of the correct due date for the recipient, or 'multiple'" do
          @assignment.do_notifications!

          messages_sent = @assignment.messages_sent['Assignment Created']
          expect(messages_sent.detect{|m|m.user_id == @teacher.id}.body).to be_include "Multiple Dates"
          expect(messages_sent.detect{|m|m.user_id == @studentA.id}.body).to be_include "Jan 1, 2011"
          expect(messages_sent.detect{|m|m.user_id == @ta.id}.body).to be_include "Multiple Dates"
          expect(messages_sent.detect{|m|m.user_id == @studentB.id}.body).to be_include "Jan 2, 2011"
          expect(messages_sent.detect{|m|m.user_id == @ta2.id}.body).to be_include "Multiple Dates"
        end

        it "should notify the correct people with differentiated_assignments enabled" do
          section = @course.course_sections.create!(name: 'Lonely Section')
          student = student_in_section(section)
          @assignment.do_notifications!

          messages_sent = @assignment.messages_sent['Assignment Created']
          expect(messages_sent.detect{|m|m.user_id == @teacher.id}.body).to be_include "Multiple Dates"
          expect(messages_sent.detect{|m|m.user_id == @studentA.id}.body).to be_include "Jan 1, 2011"
          expect(messages_sent.detect{|m|m.user_id == @ta.id}.body).to be_include "Multiple Dates"
          expect(messages_sent.detect{|m|m.user_id == @studentB.id}.body).to be_include "Jan 2, 2011"
          expect(messages_sent.detect{|m|m.user_id == @ta2.id}.body).to be_include "Multiple Dates"
          expect(messages_sent.detect{|m|m.user_id == student.id}).to be_nil
        end

        it "should collapse identical instructor due dates" do
          # change the override to match the default due date
          override = @assignment.assignment_overrides.first
          override.override_due_at(@assignment.due_at)
          override.save!
          @assignment.do_notifications!

          # when the override matches the default, show the default and not "Multiple"
          messages_sent = @assignment.messages_sent['Assignment Created']
          messages_sent.each{|m| expect(m.body).to be_include "Jan 1, 2011"}
        end
      end

      context "assignment due date changed" do
        before :once do
          Notification.create(:name => 'Assignment Due Date Changed')
          Notification.create(:name => 'Assignment Due Date Override Changed')
        end

        it "should notify appropriate parties when the default due date changes" do
          @assignment.update_attribute(:created_at, 1.day.ago)

          @assignment.due_at = DateTime.parse("09 Jan 2011 14:00 AKST")
          @assignment.save!

          messages_sent = @assignment.messages_sent['Assignment Due Date Changed']
          expect(messages_sent.detect{|m|m.user_id == @teacher.id}.body).to be_include "Jan 9, 2011"
          expect(messages_sent.detect{|m|m.user_id == @studentA.id}.body).to be_include "Jan 9, 2011"
          expect(messages_sent.detect{|m|m.user_id == @ta.id}.body).to be_include "Jan 9, 2011"
          expect(messages_sent.detect{|m|m.user_id == @studentB.id}).to be_nil
          expect(messages_sent.detect{|m|m.user_id == @ta2.id}.body).to be_include "Jan 9, 2011"
        end

        it "should notify appropriate parties when an override due date changes" do
          @assignment.update_attribute(:created_at, 1.day.ago)

          override = @assignment.assignment_overrides.first.reload
          override.override_due_at(DateTime.parse("11 Jan 2011 11:11 AKST"))
          override.save!

          messages_sent = override.messages_sent['Assignment Due Date Changed']
          expect(messages_sent.detect{|m|m.user_id == @studentA.id}).to be_nil
          expect(messages_sent.detect{|m|m.user_id == @studentB.id}.body).to be_include "Jan 11, 2011"

          messages_sent = override.messages_sent['Assignment Due Date Override Changed']
          expect(messages_sent.detect{|m|m.user_id == @ta.id}).to be_nil
          expect(messages_sent.detect{|m|m.user_id == @teacher.id}.body).to be_include "Jan 11, 2011"
          expect(messages_sent.detect{|m|m.user_id == @ta2.id}.body).to be_include "Jan 11, 2011"
        end
      end

      context "assignment submitted late" do
        before :once do
          Notification.create(:name => 'Assignment Submitted')
          Notification.create(:name => 'Assignment Submitted Late')
        end

        it "should send a late submission notification iff the submit date is late for the submitter" do
          fake_submission_time = Time.parse "Jan 01 17:00:00 -0900 2011"
          Time.stubs(:now).returns(fake_submission_time)
          subA = @assignment.submit_homework @studentA, :submission_type => "online_text_entry", :body => "ooga"
          subB = @assignment.submit_homework @studentB, :submission_type => "online_text_entry", :body => "booga"
          Time.unstub(:now)

          expect(subA.messages_sent["Assignment Submitted Late"]).not_to be_nil
          expect(subB.messages_sent["Assignment Submitted Late"]).to be_nil
        end
      end

      context "group assignment submitted late" do
        before :once do
          Notification.create(:name => 'Group Assignment Submitted Late')
        end

        it "should send a late submission notification iff the submit date is late for the group" do
          @a = assignment_model(:course => @course, :group_category => "Study Groups", :due_at => Time.parse("Jan 01 17:00:00 -0900 2011"), :submission_types => ["online_text_entry"])
          @group1 = @a.context.groups.create!(:name => "Study Group 1", :group_category => @a.group_category)
          @group1.add_user(@studentA)
          @group2 = @a.context.groups.create!(:name => "Study Group 2", :group_category => @a.group_category)
          @group2.add_user(@studentB)
          override = @a.assignment_overrides.new
          override.set = @group2
          override.override_due_at(Time.parse("Jan 03 17:00:00 -0900 2011"))
          override.save!
          fake_submission_time = Time.parse("Jan 02 17:00:00 -0900 2011")
          Time.stubs(:now).returns(fake_submission_time)
          subA = @assignment.submit_homework @studentA, :submission_type => "online_text_entry", :body => "eenie"
          subB = @assignment.submit_homework @studentB, :submission_type => "online_text_entry", :body => "meenie"
          Time.unstub(:now)

          expect(subA.messages_sent["Group Assignment Submitted Late"]).not_to be_nil
          expect(subB.messages_sent["Group Assignment Submitted Late"]).to be_nil
        end
      end
    end
  end

  context "group assignment" do
    before :once do
      setup_assignment_with_group
    end

    it "should submit the homework for all students in the same group" do
      sub = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you")
      expect(sub.user_id).to eql(@u1.id)
      @a.reload
      subs = @a.submissions
      expect(subs.length).to eql(2)
      expect(subs.map(&:group_id).uniq).to eql([@group.id])
      expect(subs.map(&:submission_type).uniq).to eql(['online_text_entry'])
      expect(subs.map(&:body).uniq).to eql(['Some text for you'])
    end

    it "should submit the homework for all students in the group if grading them individually" do
      @a.update_attribute(:grade_group_students_individually, true)
      res = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Test submission")
      @a.reload
      submissions = @a.submissions
      expect(submissions.length).to eql 2
      expect(submissions.map(&:group_id).uniq).to eql [@group.id]
      expect(submissions.map(&:submission_type).uniq).to eql ["online_text_entry"]
      expect(submissions.map(&:body).uniq).to eql ["Test submission"]
    end

    it "should update submission for all students in the same group" do
      res = @a.grade_student(@u1, :grade => "10")
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res.length).to eql(2)
      expect(res.map{|s| s.user}).to be_include(@u1)
      expect(res.map{|s| s.user}).to be_include(@u2)
    end

    it "should create an initial submission comment for only the submitter by default" do
      sub = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you", :comment => "hey teacher, i hate my group. i did this entire project by myself :(")
      expect(sub.user_id).to eql(@u1.id)
      expect(sub.submission_comments.size).to eql 1
      @a.reload
      other_sub = (@a.submissions - [sub])[0]
      expect(other_sub.submission_comments.size).to eql 0
    end

    it "should add a submission comment for only the specified user by default" do
      @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you", :comment => "ohai teacher, we had so much fun working together", :group_comment => "1")
      res = @a.update_submission(@u1, :comment => "woot")
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res.length).to eql(1)
      expect(res.find{|s| s.user == @u1}.submission_comments).not_to be_empty
      expect(res.find{|s| s.user == @u2}).to be_nil #.submission_comments.should be_empty
    end

    it "should update submission for only the individual student if set thay way" do
      @a.update_attribute(:grade_group_students_individually, true)
      res = @a.grade_student(@u1, :grade => "10")
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res.length).to eql(1)
      expect(res[0].user).to eql(@u1)
    end

    it "should create an initial submission comment for all group members if specified" do
      sub = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you", :comment => "ohai teacher, we had so much fun working together", :group_comment => "1")
      expect(sub.user_id).to eql(@u1.id)
      expect(sub.submission_comments.size).to eql 1
      @a.reload
      other_sub = (@a.submissions - [sub])[0]
      expect(other_sub.submission_comments.size).to eql 1
    end

    it "should add a submission comment for all group members if specified" do
      @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you")
      res = @a.update_submission(@u1, :comment => "woot", :group_comment => "1")
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res.length).to eql(2)
      expect(res.find{|s| s.user == @u1}.submission_comments).not_to be_empty
      expect(res.find{|s| s.user == @u2}.submission_comments).not_to be_empty
      # all the comments should have the same group_comment_id, for deletion
      comments = SubmissionComment.for_assignment_id(@a.id).to_a
      expect(comments.size).to eq 2
      group_comment_id = comments[0].group_comment_id
      expect(group_comment_id).to be_present
      expect(comments.all? { |c| c.group_comment_id == group_comment_id }).to be_truthy
    end

    it "return the single submission if the user is not in a group" do
      res = @a.grade_student(@u3, :comment => "woot", :group_comment => "1")
      expect(res).not_to be_nil
      expect(res).not_to be_empty
      expect(res.length).to eql(1)
      res = @a.update_submission(@u3, :comment => "woot", :group_comment => "1")
      comments = res.find{|s| s.user == @u3}.submission_comments
      expect(comments.size).to eq 1
      expect(comments[0].group_comment_id).to be_nil
    end

    it "associates attachments with all submissions" do
      @a.update_attribute :submission_types, "online_upload"
      f = @u1.attachments.create! uploaded_data: StringIO.new('blah'),
        context: @u1,
        filename: 'blah.txt'
      @a.submit_homework(@u1, attachments: [f])
      @a.submissions.reload.each { |s|
        expect(s.attachments).to eq [f]
      }
    end
  end

  context "adheres_to_policy" do
    it "should serialize permissions" do
      @assignment = @course.assignments.create!(:title => "some assignment")
      data = @assignment.as_json(:permissions => {:user => @user, :session => nil}) rescue nil
      expect(data).not_to be_nil
      expect(data['assignment']).not_to be_nil
      expect(data['assignment']['permissions']).not_to be_nil
      expect(data['assignment']['permissions']).not_to be_empty
    end
  end

  describe "sections_with_visibility" do
    before(:once) do
      course_with_teacher(:active_all => true)
      @section = @course.course_sections.create!
      @student = student_in_section(@section)
      @assignment, @assignment2, @assignment3 = (1..3).map{ @course.assignments.create! }

      @assignment.only_visible_to_overrides = true
      create_section_override_for_assignment(@assignment, course_section: @section)

      @assignment2.only_visible_to_overrides = true

      @assignment3.only_visible_to_overrides = false
      create_section_override_for_assignment(@assignment3, course_section: @section)
      [@assignment, @assignment2, @assignment3].each(&:save!)
    end

    it "returns only sections with overrides with differentiated assignments on" do
      expect(@assignment.sections_with_visibility(@teacher)).to eq [@section]
      expect(@assignment2.sections_with_visibility(@teacher)).to eq []
      expect(@assignment3.sections_with_visibility(@teacher)).to eq @course.course_sections
    end
  end

  context "modules" do
    it "should be locked when part of a locked module" do
      ag = @course.assignment_groups.create!
      a1 = ag.assignments.create!(:context => course)
      expect(a1.locked_for?(@user)).to be_falsey

      m = @course.context_modules.create!
      ct = ContentTag.new
      ct.content_id = a1.id
      ct.content_type = 'Assignment'
      ct.context_id = course.id
      ct.context_type = 'Course'
      ct.title = "Assignment"
      ct.tag_type = "context_module"
      ct.context_module_id = m.id
      ct.context_code = "course_#{@course.id}"
      ct.save!

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      expect(a1.locked_for?(@user)).to be_truthy
    end

    it "should be locked when associated discussion topic is part of a locked module" do
      a1 = assignment_model(:course => @course, :submission_types => "discussion_topic")
      a1.reload
      expect(a1.locked_for?(@user)).to be_falsey

      m = @course.context_modules.create!
      m.add_item(:id => a1.discussion_topic.id, :type => 'discussion_topic')

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      expect(a1.locked_for?(@user)).to be_truthy
    end

    it "should be locked when associated wiki page is part of a locked module" do
      @course.enable_feature!(:conditional_release)
      a1 = assignment_model(:course => @course, :submission_types => "wiki_page")
      a1.reload
      expect(a1.locked_for?(@user)).to be_falsey

      m = @course.context_modules.create!
      m.add_item(:id => a1.wiki_page.id, :type => 'wiki_page')

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      expect(a1.locked_for?(@user)).to be_truthy
    end

    it "should not be locked by wiki page when feature is disabled" do
      a1 = wiki_page_assignment_model(:course => @course, :submission_types => "wiki_page")
      a1.reload
      expect(a1.locked_for?(@user)).to be_falsey

      m = @course.context_modules.create!
      m.add_item(:id => a1.wiki_page.id, :type => 'wiki_page')

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      expect(a1.locked_for?(@user)).to be_falsey
    end

    it "should be locked when associated quiz is part of a locked module" do
      a1 = assignment_model(:course => @course, :submission_types => "online_quiz")
      a1.reload
      expect(a1.locked_for?(@user)).to be_falsey

      m = @course.context_modules.create!
      m.add_item(:id => a1.quiz.id, :type => 'quiz')

      m.unlock_at = Time.now.in_time_zone + 1.day
      m.save
      a1.reload
      expect(a1.locked_for?(@user)).to be_truthy
    end
  end

  context "group_students" do
    it "should return [nil, [student]] unless the assignment has a group_category" do
      @assignment = assignment_model(course: @course)
      @student = user_model
      expect(@assignment.group_students(@student)).to eq [nil, [@student]]
    end

    it "should return [nil, [student]] if the context doesn't have any active groups in the same category" do
      @assignment = assignment_model(:group_category => "Fake Category", :course => @course)
      @student = user_model
      expect(@assignment.group_students(@student)).to eq [nil, [@student]]
    end

    it "should return [nil, [student]] if the student isn't in any of the candidate groups" do
      @assignment = assignment_model(:group_category => "Category", :course => @course)
      @group = @course.groups.create(:name => "Group", :group_category => @assignment.group_category)
      @student = user_model
      expect(@assignment.group_students(@student)).to eq [nil, [@student]]
    end

    it "should return [group, [students from group]] if the student is in one of the candidate groups" do
      @assignment = assignment_model(:group_category => "Category", :course => @course)
      @course.enroll_student(@student1 = user_model)
      @course.enroll_student(@student2 = user_model)
      @course.enroll_student(@student3 = user_model)
      @group1 = @course.groups.create(:name => "Group 1", :group_category => @assignment.group_category)
      @group1.add_user(@student1)
      @group1.add_user(@student2)
      @group2 = @course.groups.create(:name => "Group 2", :group_category => @assignment.group_category)
      @group2.add_user(@student3)

      # have to reload because the enrolled students above don't show up in
      # Course#students until the course has been reloaded
      result = @assignment.reload.group_students(@student1)
      expect(result.first).to eq @group1
      expect(result.last.map{ |u| u.id }.sort).to eq [@student1, @student2].map{ |u| u.id }.sort
    end

    it "returns distinct users" do
      s1, s2 = n_students_in_course(2)

      section = @course.course_sections.create! name: "some section"
      e = @course.enroll_user s1, 'StudentEnrollment',
                              section: section,
                              allow_multiple_enrollments: true
      e.update_attribute :workflow_state, 'active'

      gc = @course.group_categories.create! name: "Homework Groups"
      group = gc.groups.create! name: "Group 1", context: @course
      group.add_user(s1)
      group.add_user(s2)

      a = @course.assignments.create! name: "Group Assignment",
                                      group_category_id: gc.id
      g, students = a.group_students(s1)
      expect(g).to eq group
      expect(students.sort_by(&:id)).to eq [s1, s2]
    end
  end

  it "should maintain the deprecated group_category attribute" do
    assignment = assignment_model(course: @course)
    expect(assignment.read_attribute(:group_category)).to be_nil
    assignment.group_category = assignment.context.group_categories.create(:name => "my category")
    assignment.save
    assignment.reload
    expect(assignment.read_attribute(:group_category)).to eql("my category")
    assignment.group_category = nil
    assignment.save
    assignment.reload
    expect(assignment.read_attribute(:group_category)).to be_nil
  end

  it "should provide has_group_category?" do
    assignment = assignment_model(course: @course)
    expect(assignment.has_group_category?).to be_falsey
    assignment.group_category = assignment.context.group_categories.create(:name => "my category")
    expect(assignment.has_group_category?).to be_truthy
    assignment.group_category = nil
    expect(assignment.has_group_category?).to be_falsey
  end

  context "turnitin settings" do
    before(:once) { assignment_model(course: @course) }

    it "should sanitize bad data" do
      assignment = @assignment
      assignment.turnitin_settings = {
        :originality_report_visibility => 'invalid',
        :s_paper_check => '2',
        :internet_check => 1,
        :journal_check => 0,
        :exclude_biblio => true,
        :exclude_quoted => false,
        :exclude_type => '3',
        :exclude_value => 'asdf',
        :bogus => 'haha'
      }
      expect(assignment.turnitin_settings).to eql({
        :originality_report_visibility => 'immediate',
        :s_paper_check => '1',
        :internet_check => '1',
        :journal_check => '0',
        :exclude_biblio => '1',
        :exclude_quoted => '0',
        :exclude_type => '0',
        :exclude_value => '',
        :s_view_report => '1',
        :submit_papers_to => '0'
      })
    end

    it "should persist :created across changes" do
      assignment = @assignment
      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings
      assignment.save
      assignment.turnitin_settings[:created] = true
      assignment.save
      assignment.reload
      expect(assignment.turnitin_settings[:created]).to be_truthy

      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings.merge(:s_paper_check => '0')
      assignment.save
      assignment.reload
      expect(assignment.turnitin_settings[:created]).to be_truthy
    end

    it "should clear out :current" do
      assignment = @assignment
      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings
      assignment.save
      assignment.turnitin_settings[:current] = true
      assignment.save
      assignment.reload
      expect(assignment.turnitin_settings[:current]).to be_truthy

      assignment.turnitin_settings = Turnitin::Client.default_assignment_turnitin_settings.merge(:s_paper_check => '0')
      assignment.save
      assignment.reload
      expect(assignment.turnitin_settings[:current]).to be_nil
    end

    it "should use default originality setting from account" do
      assignment = @assignment
      account = assignment.course.account
      account.turnitin_originality = "after_grading"
      account.save!
      expect(assignment.turnitin_settings[:originality_report_visibility]).to eq('after_grading')
    end
  end

  context "generate comments from submissions" do
    def create_and_submit
      setup_assignment_without_submission

      @attachment = @user.attachments.new :filename => "homework.doc"
      @attachment.content_type = "foo/bar"
      @attachment.size = 10
      @attachment.save!

      @submission = @assignment.submit_homework @user, :submission_type => :online_upload, :attachments => [@attachment]
    end

    it "should infer_comment_context_from_filename" do
      create_and_submit
      ignore_file = "/tmp/._why_macos_why.txt"
      @assignment.instance_variable_set :@ignored_files, []
      expect(@assignment.send(:infer_comment_context_from_filename, ignore_file)).to be_nil
      expect(@assignment.instance_variable_get(:@ignored_files)).to eq [ignore_file]

      filename = [@user.last_name_first, @user.id, @attachment.id, @attachment.display_name].join("_")

      expect(@assignment.send(:infer_comment_context_from_filename, filename)).to eq({
        :user => @user,
        :submission => @submission,
        :filename => filename,
        :display_name => @attachment.display_name
      })
      expect(@assignment.instance_variable_get(:@ignored_files)).to eq [ignore_file]
    end

    it "should ignore when assignment.id does not belog to the user" do
      create_and_submit
      false_attachment = @attachment
      student_in_course(active_all: true, user_name: "other user")
      create_and_submit
      ignore_file = [@user.last_name_first, @user.id, false_attachment.id, @attachment.display_name].join("_")
      @assignment.instance_variable_set :@ignored_files, []
      expect(@assignment.send(:infer_comment_context_from_filename, ignore_file)).to be_nil
      expect(@assignment.instance_variable_get(:@ignored_files)).to eq [ignore_file]
    end

    it "should mark comments as hidden for submission zip uploads" do
      @assignment = @course.assignments.create! name: "Mute Comment Test",
                                                submission_types: %w(online_upload)
      @assignment.update_attribute :muted, true
      submit_homework(@student)

      zip = zip_submissions

      @assignment.generate_comments_from_files(zip.open.path, @user)

      submission = @assignment.submission_for_student(@student)
      expect(submission.submission_comments.last.hidden).to eq true
    end
  end

  context "attribute freezing" do
    before :once do
      @asmnt = @course.assignments.create!(:title => 'lock locky')
      @att_map = {"lock_at" => "yes",
                  "assignment_group" => "no",
                  "title" => "no",
                  "assignment_group_id" => "no",
                  "submission_types" => "yes",
                  "points_possible" => "yes",
                  "description" => "yes",
                  "grading_type" => "yes"}
    end

    def stub_plugin
      PluginSetting.stubs(:settings_for_plugin).returns(@att_map)
    end

    it "should not be frozen if not copied" do
      stub_plugin
      @asmnt.freeze_on_copy = true
      expect(@asmnt.frozen?).to eq false
      @att_map.each_key{|att| expect(@asmnt.att_frozen?(att)).to eq false}
    end

    it "should not be frozen if copied but not frozen set" do
      stub_plugin
      @asmnt.copied = true
      expect(@asmnt.frozen?).to eq false
      @att_map.each_key{|att| expect(@asmnt.att_frozen?(att)).to eq false}
    end

    it "should not be frozen if plugin not enabled" do
      @asmnt.copied = true
      @asmnt.freeze_on_copy = true
      expect(@asmnt.frozen?).to eq false
      @att_map.each_key{|att| expect(@asmnt.att_frozen?(att)).to eq false}
    end

    context "assignments are frozen" do
      before :once do
        @admin = account_admin_user(opts={})
        teacher_in_course(:course => @course)
      end

      before :each do
        stub_plugin
        @asmnt.copied = true
        @asmnt.freeze_on_copy = true
      end

      it "should be frozen" do
        expect(@asmnt.frozen?).to eq true
      end

      it "should flag specific attributes as frozen for no user" do
        @att_map.each_pair do |att, setting|
          expect(@asmnt.att_frozen?(att)).to eq(setting == "yes")
        end
      end

      it "should flag specific attributes as frozen for teacher" do
        @att_map.each_pair do |att, setting|
          expect(@asmnt.att_frozen?(att, @teacher)).to eq(setting == "yes")
        end
      end

      it "should not flag attributes as frozen for admin" do
        @att_map.each_pair do |att, setting|
          expect(@asmnt.att_frozen?(att, @admin)).to eq false
        end
      end

      it "should be frozen for nil user" do
        expect(@asmnt.frozen_for_user?(nil)).to eq true
      end

      it "should not be frozen for admin" do
        expect(@asmnt.frozen_for_user?(@admin)).to eq false
      end

      it "should not validate if saving without user" do
        @asmnt.description = "new description"
        @asmnt.save
        expect(@asmnt.valid?).to eq false
        expect(@asmnt.errors["description"]).to eq ["You don't have permission to edit the locked attribute description"]
      end

      it "should allow teacher to edit unlocked attributes" do
        @asmnt.title = "new title"
        @asmnt.updating_user = @teacher
        @asmnt.save!

        @asmnt.reload
        expect(@asmnt.title).to eq "new title"
      end

      it "should not allow teacher to edit locked attributes" do
        @asmnt.description = "new description"
        @asmnt.updating_user = @teacher
        @asmnt.save

        expect(@asmnt.valid?).to eq false
        expect(@asmnt.errors["description"]).to eq ["You don't have permission to edit the locked attribute description"]

        @asmnt.reload
        expect(@asmnt.description).not_to eq "new title"
      end

      it "should allow admin to edit unlocked attributes" do
        @asmnt.description = "new description"
        @asmnt.updating_user = @admin
        @asmnt.save!

        @asmnt.reload
        expect(@asmnt.description).to eq "new description"
      end

    end

  end

  context "not_locked scope" do
    before :once do
      assignment_quiz([], :course => @course, :user => @user)
      # Setup default values for tests (leave unsaved for easy changes)
      @quiz.unlock_at = nil
      @quiz.lock_at = nil
      @quiz.due_at = 2.days.from_now
    end

    before :each do
      user_session(@user)
    end

    it "should include assignments with no locks" do
      @quiz.save!
      list = Assignment.not_locked.to_a
      expect(list.size).to eql 1
      expect(list.first.title).to eql 'Test Assignment'
    end
    it "should include assignments with unlock_at in the past" do
      @quiz.unlock_at = 1.day.ago
      @quiz.save!
      list = Assignment.not_locked.to_a
      expect(list.size).to eql 1
      expect(list.first.title).to eql 'Test Assignment'
    end
    it "should include assignments where lock_at is future" do
      @quiz.lock_at = 1.day.from_now
      @quiz.save!
      list = Assignment.not_locked.to_a
      expect(list.size).to eql 1
      expect(list.first.title).to eql 'Test Assignment'
    end
    it "should include assignments where unlock_at is in the past and lock_at is future" do
      @quiz.unlock_at = 1.day.ago
      @quiz.lock_at = 1.day.from_now
      @quiz.save!
      list = Assignment.not_locked.to_a
      expect(list.size).to eql 1
      expect(list.first.title).to eql 'Test Assignment'
    end
    it "should not include assignments where unlock_at is in future" do
      @quiz.unlock_at = 1.hour.from_now
      @quiz.save!
      expect(Assignment.not_locked.count).to eq 0
    end
    it "should not include assignments where lock_at is in past" do
      @quiz.lock_at = 1.hours.ago
      @quiz.save!
      expect(Assignment.not_locked.count).to eq 0
    end
  end

  context "due_between_with_overrides" do
    before :once do
      @assignment = @course.assignments.create!(:title => 'assignment', :due_at => Time.now)
      @overridden_assignment = @course.assignments.create!(:title => 'overridden_assignment', :due_at => Time.now)

      override = @assignment.assignment_overrides.build
      override.due_at = Time.now
      override.title = 'override'
      override.save!
    end

    before :each do
      @results = @course.assignments.due_between_with_overrides(Time.now - 1.day, Time.now + 1.day)
    end

    it 'should return assignments between the given dates' do
      expect(@results).to include(@assignment)
    end

    it 'should return overridden assignments that are due between the given dates' do
      expect(@results).to include(@overridden_assignment)
    end
  end

  context "destroy" do
    before :once do
      group_discussion_assignment
    end

    it "destroys the associated page" do
      course
      @course.enable_feature!(:conditional_release)
      wiki_page_assignment_model course: @course
      @assignment.destroy
      expect(WikiPage.exists?(@page.id)).to be_falsey
      expect(@assignment.reload).to be_deleted
    end

    it "does not destroy the associated page" do
      wiki_page_assignment_model
      @assignment.destroy
      expect(WikiPage.exists?(@page.id)).to be_truthy
      expect(@assignment.reload).to be_deleted
    end

    it "destroys the associated discussion topic" do
      @assignment.reload.destroy
      expect(@topic.reload).to be_deleted
      expect(@assignment.reload).to be_deleted
    end

    it "does not revive the discussion if touched after destroyed" do
      @assignment.reload.destroy
      expect(@topic.reload).to be_deleted
      @assignment.touch
      expect(@topic.reload).to be_deleted
    end

    it 'raises an error on validation error' do
      assignment = Assignment.new
      expect {assignment.destroy}.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'refreshes the course participation counts' do
      Progress.any_instance.expects(:process_job)
        .with(@assignment.context, :refresh_content_participation_counts)
      @assignment.destroy
    end
  end

  describe "#too_many_qs_versions" do
    it "returns if there are too many versions to load at once" do
      quiz_with_graded_submission [], :course => @course, :user => @student
      submissions = @quiz.assignment.submissions

      Setting.set('too_many_quiz_submission_versions', 3)
      1.times { @quiz_submission.versions.create! }
      expect(@quiz.assignment.too_many_qs_versions?(submissions)).to be_falsey

      2.times { @quiz_submission.versions.create! }
      expect(@quiz.reload.assignment.too_many_qs_versions?(submissions)).to be_truthy
    end
  end

  describe "#quiz_submission_versions" do
    it "finds quiz submission versions for submissions" do
      quiz_with_graded_submission([], { :course => @course, :user => @student })
      @quiz.save!

      assignment  = @quiz.assignment
      submissions = assignment.submissions
      too_many    = assignment.too_many_qs_versions?(submissions)

      versions = assignment.quiz_submission_versions(submissions, too_many)

      expect(versions[@quiz_submission.id].size).to eq 1
    end
  end

  describe "update_student_submissions" do
    context "pass/fail assignments" do
      before :once do
        @student1, @student2 = create_users_in_course(@course, 2, return_type: :record)
        @assignment = @course.assignments.create! grading_type: "pass_fail",
        points_possible: 5
        @sub1 = @assignment.grade_student(@student1, grade: "complete").first
        @sub2 = @assignment.grade_student(@student2, grade: "incomplete").first
      end

      it "should save a version when changing grades" do
        @assignment.update_attribute :points_possible, 10
        expect(@sub1.reload.version_number).to eq 2
      end

      it "works for pass/fail assignments" do
        @assignment.update_attribute :points_possible, 10
        expect(@sub1.reload.grade).to eq "complete"
        expect(@sub2.reload.grade).to eq "incomplete"
      end

      it "works for pass/fail assignments with 0 points possible" do
        @assignment.update_attribute :points_possible, 0
        expect(@sub1.reload.grade).to eq "complete"
        expect(@sub2.reload.grade).to eq "incomplete"
      end
    end

    context "pass/fail assignments with initial 0 points possible" do
      before :once do
        setup_assignment_without_submission
        @assignment.grading_type = "pass_fail"
        @assignment.points_possible = 0.0
        @assignment.save
      end

      let(:submission) { @assignment.submissions.first }

      it "preserves pass/fail grade when changing from 0 to positive points possible" do
        @assignment.grade_student(@user, :grade => 'pass')
        @assignment.points_possible = 1.0
        @assignment.update_student_submissions

        submission.reload
        expect(submission.grade).to eql('complete')
      end

      it "changes the score of 'complete' pass/fail submissions to match the assignment's possible points" do
        @assignment.grade_student(@user, :grade => 'pass')
        @assignment.points_possible = 3.0
        @assignment.update_student_submissions

        submission.reload
        expect(submission.score).to eql(3.0)
      end

      it "does not change the score of 'incomplete' pass/fail submissions if assignment points possible has changed" do
        @assignment.grade_student(@user, :grade => 'fail')
        @assignment.points_possible = 2.0
        @assignment.update_student_submissions

        submission.reload
        expect(submission.score).to eql(0.0)
      end

    end
  end

  describe '#graded_count' do
    before :once do
      setup_assignment_without_submission
      @assignment.grade_student(@user, :grade => 1)
    end

    it 'counts the submissions that have been graded' do
      expect(@assignment.graded_count).to eq 1
    end

    it 'returns the cached value if present' do
      @assignment = Assignment.select("assignments.*, 50 AS graded_count").where(id: @assignment).first
      expect(@assignment.graded_count).to eq 50
    end
  end

  describe '#submitted_count' do
    before :once do
      setup_assignment_without_submission
      @assignment.grade_student(@user, :grade => 1)
      @assignment.submissions.first.update_attribute(:submission_type, 'online_url')
    end

    it 'counts the submissions that have submission types' do
      expect(@assignment.submitted_count).to eq 1
    end

    it 'returns the cached value if present' do
      @assignment = Assignment.select("assignments.*, 50 AS submitted_count").where(id: @assignment).first
      expect(@assignment.submitted_count).to eq 50
    end
  end

  describe "linking overrides with quizzes" do
    let_once(:assignment) { assignment_model(:course => @course, :due_at => 5.days.from_now).reload }
    let_once(:override) { assignment_override_model(:assignment => assignment) }

    before :once do
      override.override_due_at(7.days.from_now)
      override.save!

      @override_student = override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!
    end

    context "before the assignment has a quiz" do
      context "override" do
        it "has a nil quiz" do
          expect(override.quiz).to be_nil
        end

        it "has an assignment" do
          expect(override.assignment).to eq assignment
        end
      end

      context "override student" do
        it "has a nil quiz" do
          expect(@override_student.quiz).to be_nil
        end

        it "has an assignment" do
          expect(@override_student.assignment).to eq assignment
        end
      end
    end

    context "once the assignment changes to a quiz submission" do
      before :once do
        assignment.submission_types = "online_quiz"
        assignment.save
        assignment.reload
        override.reload
        @override_student.reload
      end

      it "has a quiz" do
        expect(assignment.quiz).to be_present
      end

      context "override" do
        it "has an assignment" do
          expect(override.assignment).to eq assignment
        end

        it "has the assignment's quiz" do
          expect(override.quiz).to eq assignment.quiz
        end
      end

      context "override student" do
        it "has an assignment" do
          expect(@override_student.assignment).to eq assignment
        end

        it "has the assignment's quiz" do
          expect(@override_student.quiz).to eq assignment.quiz
        end
      end
    end
  end

  describe "updating cached due dates" do
    before :once do
      @assignment = assignment_model(course: @course)
      @assignment.due_at = 2.weeks.from_now
      @assignment.save
    end

    it "triggers when assignment is created" do
      new_assignment = @course.assignments.build
      DueDateCacher.expects(:recompute).with(new_assignment)
      new_assignment.save
    end

    it "triggers when due_at changes" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @assignment.due_at = 1.week.from_now
      @assignment.save
    end

    it "triggers when due_at changes to nil" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @assignment.due_at = nil
      @assignment.save
    end

    it "triggers when assignment deleted" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @assignment.destroy
    end

    it "does not trigger when nothing changed" do
      DueDateCacher.expects(:recompute).never
      @assignment.save
    end
  end

  describe "#title_slug" do
    before :once do
      @assignment = assignment_model(course: @course)
    end

    it "should hard truncate at 30 characters" do
      @assignment.title = "a" * 31
      expect(@assignment.title.length).to eq 31
      expect(@assignment.title_slug.length).to eq 30
      expect(@assignment.title).to match /^#{@assignment.title_slug}/
    end

    it "should not change the title" do
      title = "a" * 31
      @assignment.title = title
      expect(@assignment.title_slug).not_to eq @assignment.title
      expect(@assignment.title).to eq title
    end

    it "should leave short titles alone" do
      @assignment.title = 'short title'
      expect(@assignment.title_slug).to eq @assignment.title
    end

    it "should not allow titles over 255 char" do
      @assignment.title = 'qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                           qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                           qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                           qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm
                           qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm'

      expect(lambda { @assignment.save! }).to raise_error("Validation failed: Title is too long (maximum is 255 characters), Title is too long (maximum is 255 characters)")
    end
  end

  describe "external_tool_tag" do
    it "should update the existing tag when updating the assignment" do
      a = @course.assignments.create!(title: "test",
                                      submission_types: 'external_tool',
                                      external_tool_tag_attributes: {url: "http://example.com/launch"})
      tag = a.external_tool_tag
      expect(tag).not_to be_new_record

      a = Assignment.find(a.id)
      a.attributes = {external_tool_tag_attributes: {url: "http://example.com/launch2"}}
      a.save!
      expect(a.external_tool_tag.url).to eq "http://example.com/launch2"
      expect(a.external_tool_tag).to eq tag
    end
  end

  describe "allowed_extensions=" do
    it "should accept a string as input" do
      a = Assignment.new
      a.allowed_extensions = "doc,xls,txt"
      expect(a.allowed_extensions).to eq ["doc", "xls", "txt"]
    end

    it "should accept an array as input" do
      a = Assignment.new
      a.allowed_extensions = ["doc", "xls", "txt"]
      expect(a.allowed_extensions).to eq ["doc", "xls", "txt"]
    end

    it "should sanitize the string" do
      a = Assignment.new
      a.allowed_extensions = ".DOC, .XLS, .TXT"
      expect(a.allowed_extensions).to eq ["doc", "xls", "txt"]
    end

    it "should sanitize the array" do
      a = Assignment.new
      a.allowed_extensions = [".DOC", " .XLS", " .TXT"]
      expect(a.allowed_extensions).to eq ["doc", "xls", "txt"]
    end
  end

  describe '#generate_comments_from_files' do
    before :once do
      @students = create_users_in_course(@course, 3, return_type: :record)

      @assignment = @course.assignments.create! :name => "zip upload test",
                                                :submission_types => %w(online_upload)
    end

    it "should work for individuals" do
      s1 = @students.first
      submit_homework(s1)

      zip = zip_submissions

      comments, ignored = @assignment.generate_comments_from_files(
        zip.open.path,
        @teacher)

      expect(comments.map { |g| g.map { |c| c.submission.user } }).to eq [[s1]]
      expect(ignored).to be_empty
    end

    it "should work for groups" do
      s1, s2 = @students

      gc = @course.group_categories.create! name: "Homework Groups"
      @assignment.update_attributes group_category_id: gc.id,
                                    grade_group_students_individually: false
      g1, g2 = 2.times.map { |i| gc.groups.create! name: "Group #{i}", context: @course }
      g1.add_user(s1)
      g1.add_user(s2)

      submit_homework(s1)
      zip = zip_submissions

      comments, _ = @assignment.generate_comments_from_files(
        zip.open.path,
        @teacher)

      expect(comments.map { |g|
        g.map { |c| c.submission.user }.sort_by(&:id)
      }).to eq [[s1, s2]]
    end
  end

  describe "#restore" do
    it "restores to unpublished if draft state w/ no submissions" do
      assignment_model course: @course
      @a.destroy
      @a.restore
      expect(@a.reload).to be_unpublished
    end

    it "restores to published if draft state w/ submissions" do
      setup_assignment_with_homework
      @assignment.destroy
      @assignment.restore
      expect(@assignment.reload).to be_published
    end

    it 'refreshes the course participation counts' do
      assignment = assignment_model(course: @course)
      assignment.destroy
      Progress.any_instance.expects(:process_job)
        .with(assignment.context, :refresh_content_participation_counts).once
      assignment.restore
    end
  end

  describe '#readable_submission_type' do
    it "should work for on paper assignments" do
      assignment_model(:submission_types => 'on_paper', :course => @course)
      expect(@assignment.readable_submission_types).to eq 'on paper'
    end
  end

  describe '#update_grades_if_details_changed' do
    before :once do
      assignment_model(course: @course)
    end

    it "should update grades if points_possible changes" do
      @assignment.context.expects(:recompute_student_scores).once
      @assignment.points_possible = 3
      @assignment.save!
    end

    it "should update grades if muted changes" do
      @assignment.context.expects(:recompute_student_scores).once
      @assignment.muted = true
      @assignment.save!
    end

    it "should update grades if workflow_state changes" do
      @assignment.context.expects(:recompute_student_scores).once
      @assignment.unpublish
    end

    it "should not update grades otherwise" do
      @assignment.context.expects(:recompute_student_scores).never
      @assignment.title = 'hi'
      @assignment.due_at = 1.hour.ago
      @assignment.description = 'blah'
      @assignment.save!
    end
  end

  describe "#update_submission" do
    let(:assignment) { assignment_model(course: @course) }

    it "raises an error if original_student is nil" do
      expect {
        assignment.update_submission(nil)
      }.to raise_error "Student Required"
    end

    context "when the student is not in a group" do
      let!(:associate_student_and_submission) {
        assignment.submissions.create user: @student
      }
      let(:update_submission_response) { assignment.update_submission(@student) }

      it "returns an Array" do
        expect(update_submission_response.class).to eq Array
      end

      it "returns a collection of submissions" do
        assignment.update_submission(@student).first
        expect(update_submission_response.first.class).to eq Submission
      end
    end

    context "when the student is in a group" do
      let!(:create_a_group_with_a_submitted_assignment) {
        setup_assignment_with_group
        @assignment.submit_homework(
          @u1,
          submission_type: "online_text_entry",
          body: "Some text for you"
        )
      }

      context "when a comment is submitted" do
        let(:update_assignment_with_comment) {
          @assignment.update_submission(
            @u2,
            comment:  "WAT?",
            group_comment: true,
            user_id: @course.teachers.first.id
          )
        }

        it "returns an Array" do
          expect(update_assignment_with_comment).to be_an_instance_of Array
        end

        it "creates a comment for each student in the group" do
          expect {
            update_assignment_with_comment
          }.to change{ SubmissionComment.count }.by(@u1.groups.first.users.count)
        end

        it "creates comments with the same group_comment_id" do
          update_assignment_with_comment
          comments = SubmissionComment.last(@u1.groups.first.users.count)
          expect(comments.first.group_comment_id).to eq comments.last.group_comment_id
        end
      end

      context "when a comment is not submitted" do
        it "returns an Array" do
          expect(@assignment.update_submission(@u2).class).to eq Array
        end
      end
    end
  end

  describe "basic validation" do

    describe "possible points" do

      it "does not allow a negative value" do
        assignment = Assignment.new(points_possible: -1)
        assignment.valid?
        expect(assignment.errors.keys.include?(:points_possible)).to be_truthy
      end

      it "allows a nil value" do
        assignment = Assignment.new(points_possible: nil)
        assignment.valid?
        expect(assignment.errors.keys.include?(:points_possible)).to be_falsey
      end

      it "allows a 0 value" do
        assignment = Assignment.new(points_possible: 0)
        assignment.valid?
        expect(assignment.errors.keys.include?(:points_possible)).to be_falsey
      end

      it "allows a positive value" do
        assignment = Assignment.new(points_possible: 13)
        assignment.valid?
        expect(assignment.errors.keys.include?(:points_possible)).to be_falsey
      end

      it "does not attempt validation unless points_possible has changed" do
        assignment = Assignment.new(points_possible: -13)
        assignment.stubs(:points_possible_changed?).returns(false)
        assignment.valid?
        expect(assignment.errors.keys.include?(:points_possible)).to be_falsey
      end

    end
  end

  describe 'title validation' do
    let(:assignment) { Assignment.new }
    let(:errors) {
      assignment.valid?
      assignment.errors
    }

    it 'must allow a title equal to the maximum length' do
      assignment.title = 'a' * Assignment.maximum_string_length
      expect(errors[:title]).to be_empty
    end

    it 'must not allow a title longer than the maximum length' do
      assignment.title = 'a' * (Assignment.maximum_string_length + 1)
      expect(errors[:title]).not_to be_empty
    end

    it 'must allow a blank title when it is unchanged and was previously blank' do
      assignment = @course.assignments.create!(assignment_valid_attributes)
      assignment.title = ''
      assignment.save(validate: false)

      assignment.valid?
      errors = assignment.errors
      expect(errors[:title]).to be_empty
    end

    it 'must not allow the title to be blank if changed' do
      assignment = @course.assignments.create!(assignment_valid_attributes)
      assignment.title = ' '
      assignment.valid?
      errors = assignment.errors
      expect(errors[:title]).not_to be_empty
    end
  end

  describe "group category validation" do
    before :once do
      @group_category = @course.group_categories.create! name: "groups"
      @groups = 2.times.map { |i|
        @group_category.groups.create! name: "group #{i}", context: @course
      }
    end

    let_once(:a1) { assignment }

    def assignment(group_category = nil)
      a = @course.assignments.build name: "test"
      a.group_category = group_category
      a.tap &:save!
    end

    it "lets you change group category attributes before homework is submitted" do
      a1.group_category = @group_category
      expect(a1).to be_valid

      a2 = assignment(@group_category)
      a2.group_category = nil
      expect(a2).to be_valid
    end

    it "doesn't let you change group category attributes after homework is submitted" do
      a1.submit_homework @student, body: "hello, world"
      a1.group_category = @group_category
      expect(a1).not_to be_valid

      a2 = assignment(@group_category)
      a2.submit_homework @student, body: "hello, world"
      a2.group_category = nil
      expect(a2).not_to be_valid
    end

    it "recognizes if it has submissions and belongs to a deleted group category" do
      a1.group_category = @group_category
      a1.submit_homework @student, body: "hello, world"
      expect(a1.group_category_deleted_with_submissions?).to eq false
      a1.group_category.destroy
      expect(a1.group_category_deleted_with_submissions?).to eq true

      a2 = assignment(@group_category)
      a2.group_category.destroy
      expect(a2.group_category_deleted_with_submissions?).to eq false
    end
  end

  describe "moderated_grading validation" do
    it "does not allow turning on if graded submissions exist" do
      assignment_model(course: @course)
      @assignment.grade_student @student, score: 0
      @assignment.moderated_grading = true
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning on if is also peer reviewed" do
      assignment_model(course: @course)
      @assignment.peer_reviews = true
      @assignment.moderated_grading = true
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning on if also a group assignment" do
      assignment_model(course: @course)
      @assignment.group_category = @course.group_categories.create!(name: "groups")
      @assignment.moderated_grading = true
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning off if graded submissions exist" do
      assignment_model(course: @course, moderated_grading: true)
      expect(@assignment).to be_moderated_grading
      @assignment.grade_student @student, score: 0
      @assignment.moderated_grading = false
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning off if provisional grades exist" do
      assignment_model(course: @course, moderated_grading: true)
      expect(@assignment).to be_moderated_grading
      submission = @assignment.submit_homework @student, body: "blah"
      pg = submission.find_or_create_provisional_grade! scorer: @teacher, score: 0
      @assignment.moderated_grading = false
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning on for an ungraded assignment" do
      assignment_model(course: @course, submission_types: 'not_graded')
      @assignment.moderated_grading = true
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow creating a new ungraded assignment with moderated grading" do
      a = @course.assignments.build
      a.moderated_grading = true
      a.submission_types = 'not_graded'
      expect(a).not_to be_valid
    end

    it "does not consider nil -> false to be a state change" do
      assignment_model(course: @course)
      @assignment.grade_student @student, score: 0
      expect(@assignment.moderated_grading).to be_nil
      @assignment.moderated_grading = false
      @assignment.due_at = 1.day.from_now
      expect(@assignment).to be_valid
    end
  end

  describe "context_module_tag_info" do
    before(:once) do
      @assignment = @course.assignments.create!(:due_at => 1.week.ago,
                                               :points_possible => 100,
                                               :submission_types => 'online_text_entry')
    end

    it "returns past_due if an assignment is due in the past and no submission exists" do
      info = @assignment.context_module_tag_info(@student, @course)
      expect(info[:past_due]).to be_truthy
    end

    it "does not return past_due for assignments that don't expect submissions" do
      @assignment.submission_types = ''
      @assignment.save!
      info = @assignment.context_module_tag_info(@student, @course)
      expect(info[:past_due]).to be_falsey
    end

    it "does not return past_due for assignments that were turned in on time" do
      Timecop.freeze(2.weeks.ago) { @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'blah') }
      info = @assignment.context_module_tag_info(@student, @course)
      expect(info[:past_due]).to be_falsey
    end

    it "does not return past_due for assignments that were turned in late" do
      @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'blah')
      info = @assignment.context_module_tag_info(@student, @course)
      expect(info[:past_due]).to be_falsey
    end
  end

  describe '#touch_submissions_if_muted' do
    before(:once) do
      @assignment = @course.assignments.create! points_possible: 10
      @submission = @assignment.submit_homework(@student, body: "hello")
    end

    it "touches submissions if you mute the assignment" do
      @assignment.mute!
      touched = @submission.reload.updated_at > @assignment.updated_at
      expect(touched).to eq true
    end
  end

  describe '.with_student_submission_count' do
    specs_require_sharding

    it "doesn't reference multiple shards when accessed from a different shard" do
      @assignment = @course.assignments.create! points_possible: 10
      Assignment.connection.stubs(:use_qualified_names?).returns(true)
      @shard1.activate do
        Assignment.connection.stubs(:use_qualified_names?).returns(true)
        sql = @course.assignments.with_student_submission_count.to_sql
        expect(sql).to be_include(Shard.default.name)
        expect(sql).not_to be_include(@shard1.name)
      end
    end
  end

end

def setup_assignment_with_group
  assignment_model(:group_category => "Study Groups", :course => @course)
  @group = @a.context.groups.create!(:name => "Study Group 1", :group_category => @a.group_category)
  @u1 = @a.context.enroll_user(User.create(:name => "user 1")).user
  @u2 = @a.context.enroll_user(User.create(:name => "user 2")).user
  @u3 = @a.context.enroll_user(User.create(:name => "user 3")).user
  @group.add_user(@u1)
  @group.add_user(@u2)
  @assignment.reload
end

def setup_assignment_without_submission
  assignment_model(:course => @course)
  @assignment.reload
end

def setup_assignment_with_homework
  setup_assignment_without_submission
  res = @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
  expect(res).not_to be_nil
  expect(res).to be_is_a(Submission)
  @assignment.reload
end

def setup_assignment_with_students
  @graded_notify = Notification.create!(:name => "Submission Graded")
  @grade_change_notify = Notification.create!(:name => "Submission Grade Changed")
  @stu1 = @student
  @course.enroll_student(@stu2 = user)
  @assignment = @course.assignments.create(:title => "asdf", :points_possible => 10)
  @sub1 = @assignment.grade_student(@stu1, :grade => 9).first
  expect(@sub1.score).to eq 9
  # Took this out until it is asked for
  # @sub1.published_score.should_not == @sub1.score
  expect(@sub1.published_score).to eq @sub1.score
  @assignment.reload
  expect(@assignment.submissions).to be_include(@sub1)
end

def submit_homework(student)
  file_context = @assignment.group_category.group_for(student) if @assignment.has_group_category?
  file_context ||= student
  a = Attachment.create! context: file_context,
                         filename: "homework.pdf",
                         uploaded_data: StringIO.new("blah blah blah")
  @assignment.submit_homework(student, attachments: [a],
                                       submission_type: "online_upload")
  a
end

def zip_submissions
  zip = Attachment.new filename: 'submissions.zip'
  zip.user = @teacher
  zip.workflow_state = 'to_be_zipped'
  zip.context = @assignment
  zip.save!
  ContentZipper.process_attachment(zip, @teacher)
  raise "zip failed" if zip.workflow_state != "zipped"
  zip
end

def setup_differentiated_assignments(opts={})
  if !opts[:course]
    course_with_teacher(active_all: true)
  end

  @section1 = @course.course_sections.create!(name: 'Section One')
  @section2 = @course.course_sections.create!(name: 'Section Two')

  if opts[:ta]
    @ta = course_with_ta(course: @course, active_all: true).user
  end

  @student1, @student2, @student3 = create_users(3, return_type: :record)
  student_in_section(@section1, user: @student1)
  student_in_section(@section2, user: @student2)

  @assignment = assignment_model(course: @course, submission_types: "online_url", workflow_state: "published")
  @override_s1 = differentiated_assignment(assignment: @assignment, course_section: @section1)
  @override_s1.due_at = 1.day.from_now
  @override_s1.save!
end
