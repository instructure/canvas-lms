#
# Copyright (C) 2011 - present Instructure, Inc.
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

require 'spec_helper'
require_relative '../selenium/helpers/groups_common'
require_relative '../lti2_spec_helper'

describe Assignment do
  include_context 'lti2_spec_helper'

  describe 'relationships' do
    it { is_expected.to have_one(:score_statistic).dependent(:destroy) }
    it { is_expected.to have_many(:moderation_graders) }
    it { is_expected.to have_many(:moderation_grader_users) }
    it { is_expected.to have_one(:post_policy).dependent(:destroy).inverse_of(:assignment) }
  end

  before :once do
    course_with_teacher(active_all: true)
    @initial_student = student_in_course(active_all: true, user_name: 'a student').user
  end

  # workaround for our version of shoulda-matchers not having the 'optional' method
  it { is_expected.to belong_to(:grader_section).class_name('CourseSection') }
  it { is_expected.not_to validate_presence_of(:grader_section) }
  it { is_expected.to belong_to(:final_grader).class_name('User') }
  it { is_expected.not_to validate_presence_of(:final_grader) }

  it "should create a new instance given valid attributes" do
    course = @course.assignments.create!(assignment_valid_attributes)
    expect(course).to be_valid
  end

  it "should set the lti_context_id on create" do
    assignment = @course.assignments.create!(assignment_valid_attributes)
    expect(assignment.lti_context_id).to be_present
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

  describe 'default values' do
    it 'sets grader_count to 0' do
      assignment = Assignment.create!(
        course: @course,
        name: 'some assignment',
        anonymous_grading: true
      )
      expect(assignment.grader_count).to be 0
    end
  end

  describe 'callbacks' do
    describe 'apply_late_policy' do
      it "calls apply_late_policy for the assignment if points_possible changes" do
        assignment = @course.assignments.new(assignment_valid_attributes)
        expect(LatePolicyApplicator).to receive(:for_assignment).with(assignment)

        assignment.update!(points_possible: 3.14)
      end

      it 'invokes the LatePolicyApplicator for this assignment if grading type changes but due dates do not' do
        assignment = @course.assignments.new(assignment_valid_attributes)

        allow(assignment).to receive(:update_cached_due_dates?).and_return(false)
        allow(assignment).to receive(:saved_change_to_grading_type?).and_return(true)
        expect(LatePolicyApplicator).to receive(:for_assignment).with(assignment)

        assignment.save!
      end

      it 'invokes the LatePolicyApplicator only once if grading type changes and due dates also change' do
        assignment = @course.assignments.new(assignment_valid_attributes)

        allow(assignment).to receive(:update_cached_due_dates?).and_return(true)
        allow(assignment).to receive(:saved_change_to_grading_type?).and_return(true)
        expect(LatePolicyApplicator).to receive(:for_assignment).with(assignment).once

        assignment.save!
      end

      it 'does not invoke the LatePolicyApplicator if neither grading type nor due dates change' do
        assignment = @course.assignments.new(assignment_valid_attributes)

        allow(assignment).to receive(:update_cached_due_dates?).and_return(false)
        allow(assignment).to receive(:saved_change_to_grading_type?).and_return(false)
        expect(LatePolicyApplicator).not_to receive(:for_assignment).with(assignment)

        assignment.save!
      end

      it 'invokes the LatePolicyApplicator only once if grading type does not change but due dates change' do
        assignment = @course.assignments.new(assignment_valid_attributes)

        allow(assignment).to receive(:update_cached_due_dates?).and_return(true)
        allow(assignment).to receive(:saved_change_to_grading_type?).and_return(false)
        expect(LatePolicyApplicator).to receive(:for_assignment).with(assignment).once

        assignment.save!
      end
    end

    describe 'update_cached_due_dates' do
      it 'invokes DueDateCacher if due_at is changed' do
        assignment = @course.assignments.new(assignment_valid_attributes)
        expect(DueDateCacher).to receive(:recompute).with(assignment, update_grades: true)

        assignment.update!(due_at: assignment.due_at + 1.day)
      end

      it 'invokes DueDateCacher if workflow_state is changed' do
        assignment = @course.assignments.new(assignment_valid_attributes)
        expect(DueDateCacher).to receive(:recompute).with(assignment, update_grades: true)

        assignment.destroy
      end

      it 'invokes DueDateCacher if only_visible_to_overrides is changed' do
        assignment = @course.assignments.new(assignment_valid_attributes)
        expect(DueDateCacher).to receive(:recompute).with(assignment, update_grades: true)

        assignment.update!(only_visible_to_overrides: !assignment.only_visible_to_overrides?)
      end

      it 'invokes DueDateCacher if moderated_grading is changed' do
        assignment = @course.assignments.new(assignment_valid_attributes)
        expect(DueDateCacher).to receive(:recompute).with(assignment, update_grades: true)

        assignment.update!(moderated_grading: !assignment.moderated_grading, grader_count: 2)
      end

      it 'invokes DueDateCacher after save when moderated_grading becomes enabled' do
        assignment = @course.assignments.create!(assignment_valid_attributes)
        assignment.reload

        expect(DueDateCacher).to receive(:recompute).with(assignment, update_grades: true)

        assignment.moderated_grading = true
        assignment.grader_count = 2

        assignment.update_cached_due_dates
      end

      it 'invokes DueDateCacher if called in a before_save context' do
        assignment = @course.assignments.new(assignment_valid_attributes)
        allow(assignment).to receive(:update_cached_due_dates?).and_return(true)
        expect(DueDateCacher).to receive(:recompute).with(assignment, update_grades: true)

        assignment.save!
      end

      it 'invokes DueDateCacher if called in an after_save context' do
        assignment = @course.assignments.new(assignment_valid_attributes)

        Assignment.suspend_callbacks(:update_cached_due_dates) do
          assignment.update!(due_at: assignment.due_at + 1.day)
        end

        expect(DueDateCacher).to receive(:recompute).with(assignment, update_grades: true)

        assignment.update_cached_due_dates
      end
    end

    describe "automatic setting of post policies" do
      let(:teacher) { @course.enroll_teacher(User.create!, enrollment_state: :active).user }

      it "newly-created anonymous assignments are set to post manually" do
        assignment = @course.assignments.create!(title: 'hi', anonymous_grading: true)
        expect(assignment.post_policy).to be_post_manually
      end

      it "existing assignments are set to post manually if anonymous grading is enabled" do
        assignment = @course.assignments.create!(title: 'hi')
        assignment.post_policy.update!(post_manually: false)

        assignment.update!(anonymous_grading: true)
        expect(assignment.post_policy).to be_post_manually
      end

      it "newly-created moderated assignments are set to post manually" do
        assignment = @course.assignments.create!(
          final_grader: teacher,
          grader_count: 5,
          title: 'hi',
          moderated_grading: true
        )
        expect(assignment.post_policy).to be_post_manually
      end

      it "existing assignments are set to post manually if moderated grading is enabled" do
        assignment = @course.assignments.create!(title: 'hi')
        assignment.post_policy.update!(post_manually: false)

        assignment.update!(moderated_grading: true, grader_count: 5, final_grader: teacher)
        expect(assignment.post_policy).to be_post_manually
      end

      context "for newly-created non-anonymous, non-moderated assignments" do
        it "the post policy is set to manual for a manually-posted course" do
          @course.default_post_policy.update!(post_manually: true)
          assignment = @course.assignments.create!
          expect(assignment.post_policy).to be_post_manually
        end

        it "the post policy is set to automatic for a automatically-posted course" do
          @course.default_post_policy.update!(post_manually: false)
          assignment = @course.assignments.create!
          expect(assignment.post_policy).not_to be_post_manually
        end

        it "the post policy is set to automatic if the course has no post policy" do
          @course.default_post_policy.destroy
          assignment = @course.assignments.create!
          expect(assignment.post_policy).not_to be_post_manually
        end

        it "the assignment receives its own PostPolicy object" do
          assignment = @course.assignments.create!
          expect(assignment.post_policy).to be_present
        end
      end

      context "when muting an assignment" do
        it "sets the post policy of the assignment to manual" do
          assignment = @course.assignments.create!
          assignment.update!(muted: false)
          assignment.mute!

          expect(assignment.post_policy).to be_post_manually
        end
      end

      context "when unmuting an assignment" do
        it "does not change the post policy for anonymous assignments" do
          assignment = @course.assignments.create!(anonymous_grading: true)
          assignment.unmute!

          expect(assignment.post_policy).to be_post_manually
        end

        it "sets the post policy of non-anonymous moderated assignments to automatic" do
          assignment = @course.assignments.create!(final_grader: teacher, grader_count: 2, moderated_grading: true)
          assignment.unmute!

          expect(assignment.post_policy).not_to be_post_manually
        end

        it "sets the post policy of non-anonymous non-moderated assignments to automatic" do
          assignment = @course.assignments.create!
          assignment.unmute!

          expect(assignment.post_policy).not_to be_post_manually
        end
      end
    end

    describe "#update_submittable" do
      before(:each) do
        Timecop.freeze(1.day.ago) do
          assignment_quiz([], course: @course)
        end
      end

      let(:assignment) { @assignment }
      let(:quiz) { @quiz }

      context "for an assignment with an associated quiz" do
        it "updates the quiz when the assignment is updated normally" do
          expect {
            assignment.update!(title: "a new and even better title")
          }.to change { quiz.reload.updated_at }
        end

        it "does not attempt to update the quiz when posting/hiding changes the assignment's muted status" do
          expect {
            assignment.hide_submissions(submission_ids: assignment.submissions.pluck(:id))
          }.not_to change { quiz.reload.updated_at }
        end
      end
    end

    describe 'sets root_account_id from Context' do
      it 'sets root_account_id before_create' do
        assignment = Assignment.create!(
          course: @course,
          name: 'some assignment',
        )
        expect(assignment.root_account_id).to eq @course.root_account_id
      end
    end
  end

  describe "scope: expects_submissions" do
    it 'includes assignments expecting online submissions' do
      assignment_model(submission_types: "online_text_entry,online_url,online_upload", course: @course)
      expect(Assignment.submittable).not_to be_empty
    end

    it 'excludes submissions for assignments expecting on_paper submissions' do
      assignment_model(submission_types: "on_paper", course: @course)
      expect(Assignment.submittable).to be_empty
    end

    it 'excludes submissions for assignments expecting external_tool submissions' do
      assignment_model(submission_types: "external_tool", course: @course)
      expect(Assignment.submittable).to be_empty
    end

    it 'excludes submissions for assignments expecting wiki_page submissions' do
      assignment_model(submission_types: "wiki_page", course: @course)
      expect(Assignment.submittable).to be_empty
    end

    it 'excludes submissions for assignments not expecting submissions' do
      assignment_model(submission_types: "none", course: @course)
      expect(Assignment.submittable).to be_empty
    end
  end

  describe '#ordered_moderation_graders_with_slot_taken' do
    let(:teacher1) { @course.enroll_teacher(User.create!, enrollment_state: :active).user }
    let(:teacher2) { @course.enroll_teacher(User.create!, enrollment_state: :active).user }
    let(:assignment) do
      @course.assignments.create!(
        moderated_grading: true,
        grader_count: 3,
        final_grader: @teacher
      )
    end

    it 'returns moderation graders ordered by anonymous id' do
      assignment.grade_student(@student, grader: teacher1, provisional: true, score: 0)
      assignment.grade_student(@student, grader: teacher2, provisional: true, score: 5)
      assignment.grade_student(@student, grader: @teacher, provisional: true, score: 10)
      ordered_moderation_graders_with_slot_taken = assignment.moderation_graders.with_slot_taken.order(:anonymous_id)
      expect(assignment.ordered_moderation_graders_with_slot_taken).to eq ordered_moderation_graders_with_slot_taken
    end
  end

  describe '#moderation_grader_users_with_slot_taken' do
    before(:once) do
      @teacher = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: :active)
      @student = User.create!
      @course.enroll_student(@student, enrollment_state: :active)
      @assignment = @course.assignments.create!(moderated_grading: true, grader_count: 3, final_grader: @teacher)
    end

    it 'includes users that have filled a grader slot' do
      @assignment.create_moderation_grader(@teacher, occupy_slot: true)
      expect(@assignment.moderation_grader_users_with_slot_taken).to include @teacher
    end

    it 'excludes users that have not filled a grader slot' do
      @assignment.create_moderation_grader(@teacher, occupy_slot: false)
      expect(@assignment.moderation_grader_users_with_slot_taken).not_to include @teacher
    end

    it 'excludes users that do not have a moderation grader record for the assignment' do
      expect(@assignment.moderation_grader_users_with_slot_taken).not_to include @teacher
    end
  end

  describe '#anonymous_grader_identities_by_user_id' do
    before(:once) do
      @teacher = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: :active)
      @assignment = @course.assignments.create!(moderated_grading: true, grader_count: 2, final_grader: @teacher)
    end

    it 'includes users that have taken a grader slot' do
      @assignment.create_moderation_grader(@teacher, occupy_slot: true)
      expect(@assignment.anonymous_grader_identities_by_user_id).to have_key @teacher.id
    end

    it 'assigns grader names based on the ordered anonymous IDs' do
      second_teacher = User.create!
      @course.enroll_teacher(second_teacher, enrollment_state: :active)
      @assignment.moderation_graders.create!(user: @teacher, anonymous_id: 'bbbbb', slot_taken: true)
      @assignment.moderation_graders.create!(user: second_teacher, anonymous_id: 'aaaaa', slot_taken: true)
      anonymous_name = @assignment.anonymous_grader_identities_by_user_id.dig(second_teacher.id, :name)
      expect(anonymous_name).to eq 'Grader 1'
    end

    it 'excludes users that have not taken a grader slot' do
      @assignment.create_moderation_grader(@teacher, occupy_slot: false)
      expect(@assignment.anonymous_grader_identities_by_user_id).not_to have_key @teacher.id
    end

    it 'excludes users that do not have a moderation grader record for the assignment' do
      expect(@assignment.anonymous_grader_identities_by_user_id).not_to have_key @teacher.id
    end
  end

  describe '#anonymous_grader_identities_by_anonymous_id' do
    before(:once) do
      @teacher = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: :active)
      @assignment = @course.assignments.create!(moderated_grading: true, grader_count: 2, final_grader: @teacher)
    end

    it 'includes users that have taken a grader slot' do
      grader = @assignment.create_moderation_grader(@teacher, occupy_slot: true)
      expect(@assignment.anonymous_grader_identities_by_anonymous_id).to have_key grader.anonymous_id
    end

    it 'assigns grader names based on the ordered anonymous IDs' do
      second_teacher = User.create!
      @course.enroll_teacher(second_teacher, enrollment_state: :active)
      @assignment.moderation_graders.create!(user: @teacher, anonymous_id: 'bbbbb', slot_taken: true)
      grader = @assignment.moderation_graders.create!(user: second_teacher, anonymous_id: 'aaaaa', slot_taken: true)
      anonymous_name = @assignment.anonymous_grader_identities_by_anonymous_id.dig(grader.anonymous_id, :name)
      expect(anonymous_name).to eq 'Grader 1'
    end

    it 'excludes users that have not taken a grader slot' do
      grader = @assignment.create_moderation_grader(@teacher, occupy_slot: false)
      expect(@assignment.anonymous_grader_identities_by_anonymous_id).not_to have_key grader.anonymous_id
    end

    it 'excludes users that do not have a moderation grader record for the assignment' do
      expect(@assignment.anonymous_grader_identities_by_anonymous_id).not_to have_key @teacher.id
    end
  end

  describe '#permits_moderation?' do
    before(:once) do
      @assignment = @course.assignments.create!(
        moderated_grading: true,
        grader_count: 2,
        final_grader: @teacher
      )
    end

    it 'returns false if the user is not the final grader and not an admin' do
      assistant = User.create!
      @course.enroll_ta(assistant, enrollment_state: 'active')
      expect(@assignment.permits_moderation?(assistant)).to be false
    end

    it 'returns false if user is nil' do
      expect(@assignment.permits_moderation?(nil)).to be false
    end

    it 'returns true if the user is the final grader' do
      expect(@assignment.permits_moderation?(@teacher)).to be true
    end

    it 'returns true if the user is an admin with "select final grader for moderation" privileges' do
      expect(@assignment.permits_moderation?(account_admin_user)).to be true
    end

    it 'returns false if the user is an admin without "select final grader for moderation" privileges' do
      @course.account.role_overrides.create!(role: admin_role, enabled: false, permission: :select_final_grade)
      expect(@assignment.permits_moderation?(account_admin_user)).to be false
    end
  end

  describe '#can_view_other_grader_identities?' do
    let_once(:admin) do
      admin = account_admin_user
      @course.enroll_teacher(admin, enrollment_state: 'active')
      admin
    end
    let_once(:ta) do
      ta = User.create!
      @course.enroll_ta(ta, enrollment_state: 'active')
      ta
    end
    let_once(:assignment) { @course.assignments.create!(final_grader: @teacher, grader_count: 2, moderated_grading: true) }

    shared_examples "grader anonymity does not apply" do
      it 'returns true when the user has permission to manage grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: true, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(assignment.can_view_other_grader_identities?(@teacher)).to be true
      end

      it 'returns true when the user has permission to view all grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: true, role: teacher_role)
        expect(assignment.can_view_other_grader_identities?(@teacher)).to be true
      end

      it 'returns false when the user does not have sufficient privileges' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(assignment.can_view_other_grader_identities?(@teacher)).to be false
      end
    end

    context 'when the assignment is anonymously graded' do
      before(:once) do
        assignment.update!(anonymous_grading: true)
      end

      context 'when the assignment is not moderated' do
        before :once do
          assignment.update!(moderated_grading: false)
        end

        it_behaves_like "grader anonymity does not apply"
      end

      context 'when the assignment is not anonymously graded' do
        before :once do
          assignment.update!(anonymous_grading: false, grader_names_visible_to_final_grader: true)
        end

        it_behaves_like "grader anonymity does not apply"
      end

      context 'when grader comments are visible to other graders' do
        before :once do
          assignment.update!(grader_comments_visible_to_graders: true)
        end

        context 'when graders are not anonymous' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: true, graders_anonymous_to_graders: false)
          end

          it_behaves_like "grader anonymity does not apply"
        end

        context 'when graders are anonymous to each other and the final grader' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: false, graders_anonymous_to_graders: true)
          end

          it 'returns false when the user is not the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(ta)).to be false
          end

          it 'returns false when the user is the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(@teacher)).to be false
          end

          it 'returns true when the user is an admin and not the final grader' do
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          it 'returns false when the user is an admin and also the final grader' do
            assignment.update!(final_grader_id: admin.id)
            expect(assignment.can_view_other_grader_identities?(admin)).to be false
          end
        end

        context 'when graders are anonymous only to each other' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: true, graders_anonymous_to_graders: true)
          end

          it 'returns false when the user is not the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(ta)).to be false
          end

          it 'returns true when the user is the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(@teacher)).to be true
          end

          it 'returns true when the user is an admin and not the final grader' do
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          it 'returns true when the user is an admin and also the final grader' do
            assignment.update!(final_grader_id: admin.id)
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          context 'when the assignment is published' do
            before(:once) { assignment.update!(grades_published_at: Time.zone.now) }

            it 'returns true when the user is not the final grader and not an admin' do
              expect(assignment.can_view_other_grader_identities?(ta)).to be true
            end

            it 'returns true when the user is the final grader and not an admin' do
              expect(assignment.can_view_other_grader_identities?(@teacher)).to be true
            end

            it 'returns true when the user is an admin and not the final grader' do
              expect(assignment.can_view_other_grader_identities?(admin)).to be true
            end

            it 'returns true when the user is an admin and also the final grader' do
              assignment.update!(final_grader_id: admin.id)
              expect(assignment.can_view_other_grader_identities?(admin)).to be true
            end
          end
        end

        context 'when graders are anonymous only to the final grader' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: false, graders_anonymous_to_graders: false)
          end

          it 'returns true when the user is not the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(ta)).to be true
          end

          it 'returns false when the user is the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(@teacher)).to be false
          end

          it 'returns true when the user is an admin and not the final grader' do
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          it 'returns false when the user is an admin and also the final grader' do
            assignment.update!(final_grader_id: admin.id)
            expect(assignment.can_view_other_grader_identities?(admin)).to be false
          end
        end
      end

      context 'when grader comments are hidden to other graders' do
        # When comments are hidden, grader names are also not displayed (effectively anonymous).
        # This does not apply when the final grader explicitly can view grader names.

        before :once do
          assignment.update!(grader_comments_visible_to_graders: false)
        end

        context 'when graders are not anonymous' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: true, graders_anonymous_to_graders: false)
          end

          it 'returns false when the user is not the final grader and not an admin' do
            # grader comments must be visible for graders to not be anonymous to other graders
            expect(assignment.can_view_other_grader_identities?(ta)).to be false
          end

          it 'returns true when the user is the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(@teacher)).to be true
          end

          it 'returns true when the user is an admin and not the final grader' do
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          it 'returns true when the user is an admin and also the final grader' do
            assignment.update!(final_grader_id: admin.id)
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end
        end

        context 'when graders are anonymous to each other and the final grader' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: false, graders_anonymous_to_graders: true)
          end

          it 'returns false when the user is not the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(ta)).to be false
          end

          it 'returns false when the user is the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(@teacher)).to be false
          end

          it 'returns true when the user is an admin and not the final grader' do
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          it 'returns false when the user is an admin and also the final grader' do
            assignment.update!(final_grader_id: admin.id)
            expect(assignment.can_view_other_grader_identities?(admin)).to be false
          end
        end

        context 'when graders are anonymous only to each other' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: true, graders_anonymous_to_graders: true)
          end

          it 'returns false when the user is not the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(ta)).to be false
          end

          it 'returns true when the user is the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(@teacher)).to be true
          end

          it 'returns true when the user is an admin and not the final grader' do
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          it 'returns true when the user is an admin and also the final grader' do
            assignment.update!(final_grader_id: admin.id)
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end
        end

        context 'when graders are anonymous only to the final grader' do
          before :once do
            assignment.update!(grader_names_visible_to_final_grader: false, graders_anonymous_to_graders: false)
          end

          it 'returns false when the user is not the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(ta)).to be false
          end

          it 'returns false when the user is the final grader and not an admin' do
            expect(assignment.can_view_other_grader_identities?(@teacher)).to be false
          end

          it 'returns true when the user is an admin and not the final grader' do
            expect(assignment.can_view_other_grader_identities?(admin)).to be true
          end

          it 'returns false when the user is an admin and also the final grader' do
            assignment.update!(final_grader_id: admin.id)
            expect(assignment.can_view_other_grader_identities?(admin)).to be false
          end
        end
      end
    end
  end

  describe '#can_view_other_grader_comments?' do
    let_once(:admin) do
      admin = account_admin_user
      @course.enroll_teacher(admin, enrollment_state: 'active')
      admin
    end
    let_once(:ta) do
      ta = User.create!
      @course.enroll_ta(ta, enrollment_state: 'active')
      ta
    end
    let_once(:assignment) { @course.assignments.create!(final_grader: @teacher, grader_count: 2, moderated_grading: true, anonymous_grading: true) }

    shared_examples "grader comment hiding does not apply" do
      it 'returns true when the user has permission to manage grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: true, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(assignment.can_view_other_grader_comments?(@teacher)).to be true
      end

      it 'returns true when the user has permission to view all grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: true, role: teacher_role)
        expect(assignment.can_view_other_grader_comments?(@teacher)).to be true
      end

      it 'returns false when the user does not have sufficient privileges' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(assignment.can_view_other_grader_comments?(@teacher)).to be false
      end
    end

    context 'when the assignment is not moderated' do
      before :once do
        assignment.update!(moderated_grading: false)
      end

      it_behaves_like "grader comment hiding does not apply"
    end

    context 'when grader comments are visible to other graders' do
      before :once do
        assignment.update!(
          grader_comments_visible_to_graders: true,
          grader_names_visible_to_final_grader: true
        )
      end

      it_behaves_like "grader comment hiding does not apply"

      it 'returns true when the user is not the final grader and not an admin' do
        expect(assignment.can_view_other_grader_comments?(ta)).to be true
      end

      it 'returns true when the user is the final grader' do
        expect(assignment.can_view_other_grader_comments?(@teacher)).to be true
      end

      it 'returns true when the user is an admin' do
        expect(assignment.can_view_other_grader_comments?(admin)).to be true
      end
    end

    context 'when grader comments are hidden to other graders' do
      before :once do
        assignment.update!(
          grader_comments_visible_to_graders: false,
          grader_names_visible_to_final_grader: true
        )
      end

      it 'returns false when the user is not the final grader and not an admin' do
        expect(assignment.can_view_other_grader_comments?(ta)).to be false
      end

      it 'returns true when the user is the final grader' do
        # The final grader must always be able to see grader comments.
        expect(assignment.can_view_other_grader_comments?(@teacher)).to be true
      end

      it 'returns true when the user is an admin' do
        expect(assignment.can_view_other_grader_comments?(admin)).to be true
      end
    end
  end

  describe '#anonymize_students?' do
    before(:once) do
      @assignment = @course.assignments.create!
    end

    it 'returns false when the assignment is not graded anonymously' do
      expect(@assignment).not_to be_anonymize_students
    end

    context 'when the assignment is anonymously graded' do
      before(:once) do
        @assignment.update!(anonymous_grading: true)
      end

      context "when the assignment is moderated" do
        before(:each) do
          @assignment.moderated_grading = true
        end

        it 'returns true when the assignment is moderated and grades are unpublished' do
          expect(@assignment).to be_anonymize_students
        end

        it 'returns false when the assignment is moderated and grades are published' do
          @assignment.grades_published_at = Time.zone.now
          expect(@assignment).not_to be_anonymize_students
        end
      end

      context "when the assignment is unmoderated" do
        let(:course) { @assignment.course }
        let(:active_student) { User.create! }
        let(:student2) { User.create! }
        let(:student3) { User.create! }

        before(:each) do
          course.enroll_student(active_student, workflow_state: :active)
          course.enroll_student(student2, workflow_state: :active)
          course.enroll_student(student3, workflow_state: :active)
        end

        it "returns true when at least one active student has an unposted submission" do
          expect(@assignment).to be_anonymize_students
        end

        it "returns false when all active submissions are posted" do
          student2.enrollments.find_by(course: course).conclude
          student3.enrollments.find_by(course: course).deactivate

          @assignment.post_submissions
          expect(@assignment).not_to be_anonymize_students
        end

        it "returns false when all submissions are posted" do
          @assignment.post_submissions
          expect(@assignment).not_to be_anonymize_students
        end
      end
    end
  end

  describe '#can_view_student_names?' do
    let_once(:admin) do
      admin = account_admin_user
      @course.enroll_teacher(admin, enrollment_state: 'active')
      admin
    end
    let_once(:ta) do
      ta = User.create!
      @course.enroll_ta(ta, enrollment_state: 'active')
      ta
    end
    let_once(:assignment) { @course.assignments.create!(final_grader: @teacher, anonymous_grading: true) }

    shared_examples "student anonymity does not apply" do
      it 'returns true when the user has permission to manage grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: true, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(assignment.can_view_student_names?(@teacher)).to be true
      end

      it 'returns true when the user has permission to view all grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: true, role: teacher_role)
        expect(assignment.can_view_student_names?(@teacher)).to be true
      end

      it 'returns false when the user does not have sufficient privileges' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(assignment.can_view_student_names?(@teacher)).to be false
      end
    end

    context 'when the assignment is not anonymously graded' do
      before :once do
        assignment.update!(anonymous_grading: false)
      end

      it_behaves_like "student anonymity does not apply"
    end

    context 'when the assignment is anonymously graded' do
      context "when the assignment is unmoderated" do
        let(:course) { assignment.course }
        let(:active_student) { User.create! }
        let(:student2) { User.create! }
        let(:student3) { User.create! }

        before(:each) do
          course.enroll_student(active_student, workflow_state: :active)
          course.enroll_student(student2, workflow_state: :active)
          course.enroll_student(student3, workflow_state: :active)
        end

        it "returns false for a teacher when at least one active student has an unposted submission" do
          expect(assignment.can_view_student_names?(@teacher)).to be false
        end

        it "returns false for an admin when at least one active student has an unposted submission" do
          expect(assignment.can_view_student_names?(admin)).to be false
        end

        it "returns true when all active submissions are posted" do
          student2.enrollments.find_by(course: course).conclude
          student3.enrollments.find_by(course: course).deactivate

          assignment.post_submissions
          expect(assignment.can_view_student_names?(admin)).to be true
        end

        it "returns true when all submissions are posted" do
          assignment.post_submissions
          expect(assignment.can_view_student_names?(admin)).to be true
        end
      end

      context 'when the assignment is moderated' do
        before(:once) do
          assignment.moderated_grading = true
        end

        it 'returns false when the user is not an admin' do
          expect(assignment.can_view_student_names?(@teacher)).to be false
        end

        it 'returns true when the user is an admin and grades are published' do
          assignment.grades_published_at = Time.zone.now
          expect(assignment.can_view_student_names?(admin)).to be true
        end

        it 'returns false when the user is an admin and grades are unpublished' do
          expect(assignment.can_view_student_names?(admin)).to be false
        end
      end
    end
  end

  describe '#tool_settings_resource_codes' do
    let(:expected_hash) do
      {
        product_code: product_family.product_code,
        vendor_code: product_family.vendor_code,
        resource_type_code: resource_handler.resource_type_code
      }
    end

    let(:assignment) { Assignment.create!(name: 'assignment with tool settings', context: course) }

    before do
      allow_any_instance_of(Lti::AssignmentSubscriptionsHelper).to receive(:create_subscription) { SecureRandom.uuid }
      allow_any_instance_of(Lti::AssignmentSubscriptionsHelper).to receive(:destroy_subscription) { {} }
    end

    it 'returns a hash of three identifying lti codes' do
      assignment.tool_settings_tool = message_handler
      assignment.save!
      expect(assignment.tool_settings_resource_codes).to eq expected_hash
    end
  end

  describe '#tool_settings_tool_name' do
    let(:assignment) { Assignment.create!(name: 'assignment with tool settings', context: course) }

    before do
      allow_any_instance_of(Lti::AssignmentSubscriptionsHelper).to receive(:create_subscription) { SecureRandom.uuid }
      allow_any_instance_of(Lti::AssignmentSubscriptionsHelper).to receive(:destroy_subscription) { {} }
    end

    it 'returns the name of the tool proxy' do
      expected_name = 'test name'
      message_handler.tool_proxy.update!(name: expected_name)
      setup_assignment_with_homework
      course.assignments << @assignment
      @assignment.tool_settings_tool = message_handler
      @assignment.save!
      expect(@assignment.tool_settings_tool_name).to eq expected_name
    end

    it 'returns the name of the context external tool' do
      expected_name = 'test name'
      setup_assignment_with_homework
      tool = @course.context_external_tools.create!(name: expected_name, url: "http://www.google.com", consumer_key: '12345', shared_secret: 'secret')
      @assignment.tool_settings_tool = tool
      @assignment.save
      expect(@assignment.tool_settings_tool_name).to eq(expected_name)
    end
  end

  describe '#tool_settings_tool=' do
    let(:stub_response){ double(code: 200, body: {}.to_json, parsed_response: {'Id' => 'test-id'}, ok?: true) }
    let(:subscription_helper){ class_double(Lti::AssignmentSubscriptionsHelper).as_stubbed_const }
    let(:subscription_helper_instance){ double(destroy_subscription: true, create_subscription: true) }

    before(:each) do
      allow(subscription_helper).to receive_messages(new: subscription_helper_instance)
    end

    it "should allow ContextExternalTools through polymorphic association" do
      setup_assignment_with_homework
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: '12345', shared_secret: 'secret')
      @assignment.tool_settings_tool = tool
      @assignment.save
      expect(@assignment.tool_settings_tool).to eq(tool)
    end

    it 'destroys subscriptions when they exist' do
      setup_assignment_with_homework
      expect(subscription_helper_instance).to receive(:destroy_subscription)
      course.assignments << @assignment
      @assignment.tool_settings_tool = message_handler
      @assignment.save!
      @assignment.tool_settings_tool = nil
      @assignment.save!
    end

    it "destroys tool unless tool is 'ContextExternalTool'" do
      setup_assignment_with_homework
      expect(subscription_helper_instance).not_to receive(:destroy_subscription)
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: '12345', shared_secret: 'secret')
      @assignment.tool_settings_tool = tool
      @assignment.save!
      @assignment.tool_settings_tool = nil
      @assignment.save!
    end

    context 'when the tool proxy is account-level' do
      it 'sets the lookup context_type to Account when the tool proxy is account-level' do
        setup_assignment_with_homework
        course.assignments << @assignment
        @assignment.tool_settings_tool = message_handler
        @assignment.save!
        lookup = @assignment.assignment_configuration_tool_lookups.last
        expect(lookup.context_type).to eq('Account')
      end
    end

    context 'when the tool proxy is course-level' do
      let(:tool_proxy_context) { course }

      it 'sets the lookup context_type to Course when the tool proxy' do
        setup_assignment_with_homework
        course.assignments << @assignment
        @assignment.tool_settings_tool = message_handler
        @assignment.save!
        lookup = @assignment.assignment_configuration_tool_lookups.last
        expect(lookup.context_type).to eq('Course')
      end
    end
  end

  describe "#duplicate" do
    it "duplicates the assignment" do
      assignment = wiki_page_assignment_model({ :title => "Wiki Assignment" })
      rubric = @course.rubrics.create! { |r| r.user = @teacher }
      rubric_association_params = HashWithIndifferentAccess.new({
        hide_score_total: "0",
        purpose: "grading",
        skip_updating_points_possible: false,
        update_if_existing: true,
        use_for_grading: "1",
        association_object: assignment
      })

      rubric_assoc = RubricAssociation.generate(@teacher, rubric, @course, rubric_association_params)
      assignment.rubric_association = rubric_assoc
      assignment.attachments.push(Attachment.new)
      assignment.submissions.push(Submission.new)
      assignment.ignores.push(Ignore.new)
      assignment.turnitin_asset_string
      new_assignment = assignment.duplicate
      expect(new_assignment.id).to be_nil
      expect(new_assignment.new_record?).to be true
      expect(new_assignment.attachments.length).to be(0)
      expect(new_assignment.submissions.length).to be(0)
      expect(new_assignment.ignores.length).to be(0)
      expect(new_assignment.rubric_association).not_to be_nil
      expect(new_assignment.title).to eq "Wiki Assignment Copy"
      expect(new_assignment.wiki_page.title).to eq "Wiki Assignment Copy"
      expect(new_assignment.duplicate_of).to eq assignment
      expect(new_assignment.workflow_state).to eq "unpublished"
      new_assignment.save!
      new_assignment2 = assignment.duplicate
      expect(new_assignment2.title).to eq "Wiki Assignment Copy 2"
      new_assignment2.save!
      expect(assignment.duplicates).to match_array [new_assignment, new_assignment2]
      # Go back to the first new assignment to test something just ending in
      # "Copy"
      new_assignment3 = new_assignment.duplicate
      expect(new_assignment3.title).to eq "Wiki Assignment Copy 3"
    end

    it "does not duplicate grades_published_at" do
      assignment = @course.assignments.create!(title: "whee", points_possible: 10)
      assignment.grades_published_at = Time.zone.now
      assignment.save!
      new_assignment = assignment.reload.duplicate
      expect(new_assignment.grades_published_at).to be_nil
    end

    it "should not explode duplicating a mismatched rubric association" do
      assmt = @course.assignments.create!(:title => "assmt", :points_possible => 3)
      rubric = @course.rubrics.new(:title => "rubric")
      rubric.update_with_association(@teacher, {
        criteria: {"0" => {description: "correctness", points: 15, ratings: {"0" => {points: 15, description: "a description"}}, }, },
      }, @course, {
        association_object: assmt, update_if_existing: true,
        use_for_grading: "1", purpose: "grading", skip_updating_points_possible: true
      })
      new_assmt = assmt.reload.duplicate
      new_assmt.save!
      expect(new_assmt.points_possible).to eq 3
    end

    context "with an assignment that can't be duplicated" do
      let(:assignment) { @course.assignments.create!(assignment_valid_attributes) }

      before { allow(assignment).to receive(:can_duplicate?).and_return(false) }

      it "raises an exception" do
        expect { assignment.duplicate }.to raise_error(RuntimeError)
      end
    end

    context "with an assignment that uses an external tool" do
      let_once(:assignment) do
        @course.assignments.create!(
          submission_types: 'external_tool',
          external_tool_tag_attributes: { url: 'http://example.com/launch' },
          **assignment_valid_attributes
        )
      end

      before { allow(assignment).to receive(:can_duplicate?).and_return(true) }

      it "duplicates the assignment's external_tool_tag" do
        new_assignment = assignment.duplicate
        new_assignment.save!
        expect(new_assignment.external_tool_tag).to be_present
        expect(new_assignment.external_tool_tag.content).to eq(assignment.external_tool_tag.content)
      end

      it "sets the assignment's state to 'duplicating'" do
        expect(assignment.duplicate.workflow_state).to eq('duplicating')
      end

      it "sets duplication_started_at to the current time" do
        expect(assignment.duplicate.duplication_started_at).to be_within(5).of(Time.zone.now)
      end
    end

    context 'with a plagiarism detection tool' do
      subject { assignment.duplicate.assignment_configuration_tool_lookups.first }

      let(:assignment) { assignment_model }
      let(:lookup) { assignment.assignment_configuration_tool_lookups.first }
      let(:subscription_helper) { double(create_subscription: SecureRandom.uuid) }

      before do
        allow(Lti::AssignmentSubscriptionsHelper).to receive(:new).and_return(subscription_helper)
        assignment.assignment_configuration_tool_lookups.create!(
          context_type: 'Account',
          tool_vendor_code: product_family.vendor_code,
          tool_product_code: product_family.product_code,
          tool_resource_type_code: resource_handler.resource_type_code,
          tool_type: 'Lti::MessageHandler'
        )
      end

      it 'uses the correct product code' do
        expect(subject.tool_product_code).to eq product_family.product_code
      end

      it 'uses the correct vendor code' do
        expect(subject.tool_vendor_code).to eq product_family.vendor_code
      end

      it 'uses the correct resource type code' do
        expect(subject.tool_resource_type_code).to eq resource_handler.resource_type_code
      end
    end
  end

  describe "#can_duplicate?" do
    subject { assignment.can_duplicate? }

    let(:assignment) { @course.assignments.create!(assignment_valid_attributes) }

    context "with a regular assignment" do
      it { is_expected.to be true }
    end

    context "with a quiz" do
      before { allow(assignment).to receive(:quiz?).and_return(true) }

      it { is_expected.to be false }
    end

    context "with an assignment that uses an external tool" do
      let_once(:assignment) do
        @course.assignments.create!(
          submission_types: 'external_tool',
          external_tool_tag_attributes: { url: 'http://example.com/launch' },
          **assignment_valid_attributes
        )
      end

      it { is_expected.to be false }

      context "quiz_lti" do
        before { allow(assignment).to receive(:quiz_lti?).and_return(true) }

        it { is_expected.to be true }
      end
    end
  end

  describe "scope: duplicating_for_too_long" do
    subject { described_class.duplicating_for_too_long }

    let_once(:unpublished_assignment) do
      @course.assignments.create!(workflow_state: 'unpublished', **assignment_valid_attributes)
    end
    let_once(:new_duplicating_assignment) do
      @course.assignments.create!(
        workflow_state: 'duplicating',
        duplication_started_at: 5.seconds.ago,
        **assignment_valid_attributes
      )
    end
    let_once(:old_duplicating_assignment) do
      @course.assignments.create!(
        workflow_state: 'duplicating',
        duplication_started_at: 20.minutes.ago,
        **assignment_valid_attributes
      )
    end

    it { is_expected.to eq([old_duplicating_assignment]) }
  end

  describe ".clean_up_duplicating_assignments" do
    before { allow(described_class).to receive(:duplicating_for_too_long).and_return(double()) }

    it "marks all assignments that have been duplicating for too long as failed_to_duplicate" do
      now = double('now')
      expect(Time.zone).to receive(:now).and_return(now)
      expect(described_class.duplicating_for_too_long).to receive(:update_all).with(
        duplication_started_at: nil,
        workflow_state: 'failed_to_duplicate',
        updated_at: now
      )
      described_class.clean_up_duplicating_assignments
    end
  end

  describe "scope: importing_for_too_long" do
    subject { described_class.importing_for_too_long }

    let_once(:unpublished_assignment) do
      @course.assignments.create!(workflow_state: 'unpublished', **assignment_valid_attributes)
    end
    let_once(:new_importing_assignment) do
      @course.assignments.create!(
        workflow_state: 'importing',
        importing_started_at: 5.seconds.ago,
        **assignment_valid_attributes
      )
    end
    let_once(:old_importing_assignment) do
      @course.assignments.create!(
        workflow_state: 'importing',
        importing_started_at: 20.minutes.ago,
        **assignment_valid_attributes
      )
    end

    it { is_expected.to eq([old_importing_assignment]) }
  end

  describe ".cleanup_importing_assignments" do
    before { allow(described_class).to receive(:importing_for_too_long).and_return(double()) }

    it "marks all assignments that have been importing for too long as failed_to_import" do
      now = double('now')
      expect(Time.zone).to receive(:now).and_return(now)
      expect(described_class.importing_for_too_long).to receive(:update_all).with(
        importing_started_at: nil,
        workflow_state: 'failed_to_import',
        updated_at: now
      )
      described_class.clean_up_importing_assignments
    end
  end

  describe "scope: migrating_for_too_long" do
    subject { described_class.migrating_for_too_long }

    let_once(:unpublished_assignment) do
      @course.assignments.create!(workflow_state: 'unpublished', **assignment_valid_attributes)
    end
    let_once(:new_migrating_assignment) do
      @course.assignments.create!(
        workflow_state: 'migrating',
        duplication_started_at: 5.seconds.ago,
        **assignment_valid_attributes
      )
    end
    let_once(:old_migrating_assignment) do
      @course.assignments.create!(
        workflow_state: 'migrating',
        duplication_started_at: 20.minutes.ago,
        **assignment_valid_attributes
      )
    end

    it { is_expected.to eq([old_migrating_assignment]) }

    describe ".clean_up_migrating_assignments" do
      it "marks all assignments that have been migrating for too long as failed_to_migrate" do
        expect(old_migrating_assignment.duplication_started_at).not_to be_nil
        expect(old_migrating_assignment.workflow_state).to eq 'migrating'
        described_class.clean_up_migrating_assignments
        expect(
          old_migrating_assignment.reload.duplication_started_at
        ).to be_nil
        expect(old_migrating_assignment.workflow_state).to eq 'failed_to_migrate'
      end
    end
  end

  describe "#representatives" do
    context "individual students" do
      it "sorts by sortable_name" do
        student_one = student_in_course(
          active_all: true, name: 'Frodo Bravo', sortable_name: 'Bravo, Frodo'
        ).user
        student_two = student_in_course(
          active_all: true, name: 'Alfred Charlie', sortable_name: 'Charlie, Alfred'
        ).user
        student_three = student_in_course(
          active_all: true, name: 'Beauregard Alpha', sortable_name: 'Alpha, Beauregard'
        ).user

        expect(User).to receive(:best_unicode_collation_key).with('sortable_name').and_call_original

        assignment = @course.assignments.create!(assignment_valid_attributes)
        representatives = assignment.representatives(user: @teacher)

        expect(representatives[0].name).to eql(student_three.name)
        expect(representatives[1].name).to eql(student_one.name)
        expect(representatives[2].name).to eql(student_two.name)
      end
    end

    context "group assignments with all students assigned to a group" do
      include GroupsCommon
      it "sorts by group name" do
        student_one = student_in_course(
          active_all: true, name: 'Frodo Bravo', sortable_name: 'Bravo, Frodo'
        ).user
        student_two = student_in_course(
          active_all: true, name: 'Alfred Charlie', sortable_name: 'Charlie, Alfred'
        ).user
        student_three = student_in_course(
          active_all: true, name: 'Beauregard Alpha', sortable_name: 'Alpha, Beauregard'
        ).user

        group_category = @course.group_categories.create!(name: "Test Group Set")
        group_one = @course.groups.create!(name: "Group B", group_category: group_category)
        group_two = @course.groups.create!(name: "Group A", group_category: group_category)
        group_three = @course.groups.create!(name: "Group C", group_category: group_category)

        add_user_to_group(student_one, group_one, true)
        add_user_to_group(student_two, group_two, true)
        add_user_to_group(student_three, group_three, true)
        add_user_to_group(@initial_student, group_three, true)

        assignment = @course.assignments.create!(
          assignment_valid_attributes.merge(
            group_category: group_category,
            grade_group_students_individually: false
          )
        )

        expect(Canvas::ICU).to receive(:collate_by).and_call_original

        representatives = assignment.representatives(user: @teacher)

        expect(representatives[0].name).to eql(group_two.name)
        expect(representatives[1].name).to eql(group_one.name)
        expect(representatives[2].name).to eql(group_three.name)
      end
    end

    context "group assignments with no students assigned to a group" do
      it "sorts by sortable_name" do
        student_one = student_in_course(
          active_all: true, name: 'Frodo Bravo', sortable_name: 'Bravo, Frodo'
        ).user
        student_two = student_in_course(
          active_all: true, name: 'Alfred Charlie', sortable_name: 'Charlie, Alfred'
        ).user
        student_three = student_in_course(
          active_all: true, name: 'Beauregard Alpha', sortable_name: 'Alpha, Beauregard'
        ).user

        group_category = @course.group_categories.create!(name: "Test Group Set")

        assignment = @course.assignments.create!(
          assignment_valid_attributes.merge(
            group_category: group_category,
            grade_group_students_individually: false
          )
        )

        expect(Canvas::ICU).to receive(:collate_by).and_call_original

        representatives = assignment.representatives(user: @teacher)

        expect(representatives[0].name).to eql(student_three.name)
        expect(representatives[1].name).to eql(student_one.name)
        expect(representatives[2].name).to eql(student_two.name)
        expect(representatives[3].name).to eql(@initial_student.name)
      end
    end

    context "group assignments with some students assigned to a group and some not" do
      include GroupsCommon
      it "sorts by student name and group name" do
        student_one = student_in_course(
          active_all: true, name: 'Frodo Bravo', sortable_name: 'Bravo, Frodo'
        ).user
        student_two = student_in_course(
          active_all: true, name: 'Alfred Charlie', sortable_name: 'Charlie, Alfred'
        ).user
        student_three = student_in_course(
          active_all: true, name: 'Beauregard Alpha', sortable_name: 'Alpha, Beauregard'
        ).user

        group_category = @course.group_categories.create!(name: "Test Group Set")
        group_one = @course.groups.create!(name: "Group B", group_category: group_category)
        group_two = @course.groups.create!(name: "Group A", group_category: group_category)

        add_user_to_group(student_one, group_one, true)
        add_user_to_group(student_two, group_two, true)

        assignment = @course.assignments.create!(
          assignment_valid_attributes.merge(
            group_category: group_category,
            grade_group_students_individually: false
          )
        )

        expect(Canvas::ICU).to receive(:collate_by).and_call_original

        representatives = assignment.representatives(user: @teacher)

        expect(representatives[0].name).to eql(student_three.name)
        expect(representatives[1].name).to eql(group_two.name)
        expect(representatives[2].name).to eql(group_one.name)
        expect(representatives[3].name).to eql(@initial_student.name)
      end
    end
  end

  context "group assignments with all students assigned to a group and grade_group_students_individually set to true" do
    include GroupsCommon
    it "sorts by sortable_name" do
      student_one = student_in_course(
        active_all: true, name: 'Frodo Bravo', sortable_name: 'Bravo, Frodo'
      ).user
      student_two = student_in_course(
        active_all: true, name: 'Alfred Charlie', sortable_name: 'Charlie, Alfred'
      ).user
      student_three = student_in_course(
        active_all: true, name: 'Beauregard Alpha', sortable_name: 'Alpha, Beauregard'
      ).user

      group_category = @course.group_categories.create!(name: "Test Group Set")
      group_one = @course.groups.create!(name: "Group B", group_category: group_category)
      group_two = @course.groups.create!(name: "Group A", group_category: group_category)
      group_three = @course.groups.create!(name: "Group C", group_category: group_category)

      add_user_to_group(student_one, group_one, true)
      add_user_to_group(student_two, group_two, true)
      add_user_to_group(student_three, group_three, true)
      add_user_to_group(@initial_student, group_three, true)

      assignment = @course.assignments.create!(
        assignment_valid_attributes.merge(
          group_category: group_category,
          grade_group_students_individually: true
        )
      )

      expect(User).to receive(:best_unicode_collation_key).with('sortable_name').and_call_original

      representatives = assignment.representatives(user: @teacher)

      expect(representatives[0].name).to eql(student_three.name)
      expect(representatives[1].name).to eql(student_one.name)
      expect(representatives[2].name).to eql(student_two.name)
      expect(representatives[3].name).to eql(@initial_student.name)
    end
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

  describe '#secure_params' do
    before { setup_assignment_without_submission }

    it 'contains the lti_context_id' do
      assignment = Assignment.new

      new_lti_assignment_id = Canvas::Security.decode_jwt(assignment.secure_params)[:lti_assignment_id]
      old_lti_assignment_id = Canvas::Security.decode_jwt(@assignment.secure_params)[:lti_assignment_id]

      expect(new_lti_assignment_id).to be_present
      expect(old_lti_assignment_id).to be_present
    end

    it 'uses the existing lti_context_id if present' do
      lti_context_id = SecureRandom.uuid
      assignment = Assignment.new(lti_context_id: lti_context_id)
      decoded = Canvas::Security.decode_jwt(assignment.secure_params)
      expect(decoded[:lti_assignment_id]).to eq(lti_context_id)
    end

    it 'returns a jwt' do
      expect(Canvas::Security.decode_jwt(@assignment.secure_params)).to be
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
      expect{@assignment.grade_to_score("3")}.to raise_error("oops, we need to interpret a new grading_type. get coding.")
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
    let_once(:now) { Time.zone.now }
    let_once(:student) { User.create!.tap {|u| course.enroll_student(u, enrollment_state: 'active') } }
    let_once(:teacher) { User.create!.tap {|u| course.enroll_teacher(u, enrollment_state: 'active') } }
    let_once(:assignment) { course.assignments.create! }
    let_once(:course) do
      course = Account.default.courses.create!
      course.offer!
      course
    end

    describe 'grade_posting_in_progress' do
      let(:submission) { instance_double("Submission") }

      before do
        allow(assignment).to receive(:find_or_create_submissions).
          with([student], Submission.preload(:grading_period, :stream_item)).
          and_yield([submission])
      end

      it 'sets grade_posting_in_progress to false when absent' do
        expect(assignment).to receive(:save_grade_to_submission).
          with([submission], student, nil, grade: 10, grader: teacher)
        assignment.grade_student(student, grade: 10, grader: teacher)
      end

      it 'sets grade_posting_in_progress to true when present' do
        expect(assignment).to receive(:save_grade_to_submission).
          with([submission], student, nil, grade: 10, grader: teacher, grade_posting_in_progress: true)
        assignment.grade_student(student, grade: 10, grader: teacher, grade_posting_in_progress: true)
      end

      it 'sets grade_posting_in_progress to false when present' do
        expect(assignment).to receive(:save_grade_to_submission).
          with([submission], student, nil, grade: 10, grader: teacher, grade_posting_in_progress: false)
        assignment.grade_student(student, grade: 10, grader: teacher, grade_posting_in_progress: false)
      end
    end

    it 'raises a GradeError when grader does not have permission' do
      expect {
        assignment.grade_student(student, grade: 42, grader: student)
      }.to raise_error(Assignment::GradeError)
    end

    context 'with a submission that has an existing grade' do
      around(:once) do |block|
        Timecop.freeze(now) do
          block.call
        end
      end

      before(:once) do
        assignment.update!(points_possible: 100, due_at: 36.hours.ago(now), submission_types: %w[online_text_entry])
        late_policy_factory(course: course, deduct: 15.0, every: :day, missing: 80.0)
        assignment.submit_homework(student, submission_type: :online_text_entry, body: :foo)
      end

      it 'applies the late penalty to a full credit grade' do
        submission, * = assignment.grade_student(student, grade: "100", grader: teacher)
        expect(submission.grade).to eql('70')
      end

      it 'applies the late penalty to a grade less than full credit' do
        submission, * = assignment.grade_student(student, grade: '70', grader: teacher)
        expect(submission.grade).to eql('40')
      end
    end

    context 'with a submission' do
      subject_once { submissions }
      let_once(:submissions) { assignment.grade_student(student, grade: "10", grader: teacher) }

      it { is_expected.to be_an Array }

      it 'now has a submission' do
        assignment.reload
        expect(assignment.submissions.count).to be 1
      end

      describe 'the submission after grading' do
        subject_once(:submission) { submissions.first }

        describe '#state' do
          it { expect(submission.state).to be :graded }
        end

        describe '#score' do
          it { expect(submission.score).to eq 10.0 }
        end

        describe '#user_id' do
          it { expect(submission.user_id).to eq student.id }
        end

        it 'has a version length of one' do
          expect(submission.versions.length).to eq 1
        end
      end
    end

    context 'with no student' do
      it 'raises an error' do
        expect { assignment.grade_student(nil) }.to raise_error(Assignment::GradeError, 'Student is required')
      end
    end

    context 'with a student that does not belong' do
      it 'raises an error' do
        expect { assignment.grade_student(User.new) }.to raise_error(Assignment::GradeError, 'Student must be enrolled in the course as a student to be graded')
      end
    end

    context 'with an invalid initial grade' do
      before :once do
        @result = assignment.grade_student(student, grade: "{", grader: teacher)
        assignment.reload
      end

      it 'does not change the workflow_state to graded' do
        expect(@result.first.grade).to be_nil
        expect(@result.first.workflow_state).not_to eq 'graded'
      end
    end

    context "moderated assignment" do
      let_once(:assignment) do
        course.assignments.create!(moderated_grading: true, grader_count: 1, final_grader: teacher)
      end
      let_once(:ta) { course_with_user("TaEnrollment", course: course, active_all: true, name: "Ta").user }
      let(:pg) { @result.first.provisional_grades.find_by!(scorer: ta) }

      before(:each) do
        @result = assignment.grade_student(student, grade: "10", grader: ta, provisional: true)
      end

      it "allows for grades to be deleted" do
        expect{
          assignment.grade_student(student, grade: "", grader: ta, provisional: true)
        }.to change{
          pg.reload.grade
        }.from("10").to(nil)
      end

      it "keeps the provisional grader's slot after grade deletion" do
        assignment.grade_student(student, grade: "10", grader: ta, provisional: true)
        expect{
          assignment.grade_student(student, grade: "", grader: ta, provisional: true)
        }.not_to change{
          assignment.provisional_moderation_graders.first.slot_taken
        }
      end

      it "does not allow grade to be deleted if grade was selected" do
        selection = assignment.moderated_grading_selections.where(student_id: student.id).first
        selection.provisional_grade = pg
        selection.save!

        expect{
          assignment.grade_student(student, grade: "", grader: ta, provisional: true)
        }.to raise_error(Assignment::GradeError) do |error|
          expect(error.error_code).to eq Assignment::GradeError::PROVISIONAL_GRADE_MODIFY_SELECTED
        end
      end

      it "does not allow grade to be changed if grade was selected" do
        selection = assignment.moderated_grading_selections.where(student_id: student.id).first
        selection.provisional_grade = pg
        selection.save!

        expect{
          assignment.grade_student(student, grade: "23", grader: ta, provisional: true)
        }.to raise_error(Assignment::GradeError) do |error|
          expect(error.error_code).to eq Assignment::GradeError::PROVISIONAL_GRADE_MODIFY_SELECTED
        end
      end
    end

    context 'with an excused assignment' do
      before :once do
        @result = assignment.grade_student(student, grader: teacher, excuse: true)
        assignment.reload
      end

      it 'excuses the assignment and marks it as graded' do
        expect(@result.first.grade).to be_nil
        expect(@result.first.workflow_state).to eql 'graded'
        expect(@result.first.excused?).to eql true
      end
    end

    context 'with anonymous grading' do
      it 'explicitly sets anonymous grading if given' do
        assignment.grade_student(student, graded_anonymously: true, grade: "10", grader: teacher)
        assignment.reload
        expect(assignment.submissions.first.graded_anonymously).to be_truthy
      end

      it 'does not set anonymous grading if not given' do
        assignment.grade_student(student, graded_anonymously: true, grade: "10", grader: teacher)
        assignment.reload
        assignment.grade_student(student, grade: "10", grader: teacher)
        assignment.reload
        # should still true because grade didn't actually change
        expect(assignment.submissions.first.graded_anonymously).to be_truthy
      end
    end

    context 'for a moderated assignment' do
      before(:once) do
        student_in_course
        teacher_in_course
        @first_teacher = @teacher

        teacher_in_course
        @second_teacher = @teacher

        assignment_model(course: @course, moderated_grading: true, grader_count: 2)
      end

      it 'allows addition of provisional graders up to the set grader count' do
        @assignment.grade_student(@student, grader: @first_teacher, provisional: true, score: 1)
        @assignment.grade_student(@student, grader: @second_teacher, provisional: true, score: 2)

        expect(@assignment.moderation_graders).to have(2).items
      end

      it 'does not allow provisional graders beyond the set grader count' do
        @assignment.grade_student(@student, grader: @first_teacher, provisional: true, score: 1)
        @assignment.grade_student(@student, grader: @second_teacher, provisional: true, score: 2)

        teacher_in_course
        @superfluous_teacher = @teacher

        expect { @assignment.grade_student(@student, grader: @superfluous_teacher, provisional: true, score: 2) }.
          to raise_error(Assignment::MaxGradersReachedError)
      end

      it 'allows the same grader to re-grade an assignment' do
        @assignment.grade_student(@student, grader: @first_teacher, provisional: true, score: 1)

        expect(@assignment.moderation_graders).to have(1).item
      end

      it 'creates at most one entry per grader' do
        first_student = @student

        student_in_course
        second_student = @student

        @assignment.grade_student(first_student, grader: @first_teacher, provisional: true, score: 1)
        @assignment.grade_student(second_student, grader: @first_teacher, provisional: true, score: 2)

        expect(@assignment.moderation_graders).to have(1).item
      end

      it 'raises an error if an invalid score is passed for a provisional grade' do
        expect { @assignment.grade_student(@student, grader: @first_teacher, provisional: true, grade: 'bad') }.
          to raise_error(Assignment::GradeError) do |error|
            expect(error.error_code).to eq Assignment::GradeError::PROVISIONAL_GRADE_INVALID_SCORE
          end
      end

      context 'with a final grader' do
        before(:once) do
          teacher_in_course(active_all: true)
          @final_grader = @teacher

          @assignment.update!(final_grader: @final_grader)
        end

        it 'allows the moderator to issue a grade regardless of the current grader count' do
          @assignment.grade_student(@student, grader: @first_teacher, provisional: true, score: 1)
          @assignment.grade_student(@student, grader: @second_teacher, provisional: true, score: 2)
          @assignment.grade_student(@student, grader: @final_grader, provisional: true, score: 10)

          expect(@assignment.moderation_graders).to have(3).items
        end

        it 'excludes the moderator from the current grader count when considering provisional graders' do
          @assignment.grade_student(@student, grader: @final_grader, provisional: true, score: 10)
          @assignment.grade_student(@student, grader: @first_teacher, provisional: true, score: 1)
          @assignment.grade_student(@student, grader: @second_teacher, provisional: true, score: 2)

          expect(@assignment.moderation_graders).to have(3).items
        end

        describe 'excusing a moderated assignment' do
          it 'does not accept an excusal from a provisional grader' do
            expect { @assignment.grade_student(@student, grader: @first_teacher, provisional: true, excused: true) }.
              to raise_error(Assignment::GradeError)
          end

          it 'does not allow a provisional grader to un-excuse an assignment' do
            @assignment.grade_student(@student, grader: @final_grader, provisional: true, excused: true)
            @assignment.grade_student(@student, grader: @first_teacher, provisional: true, excused: false)
            expect(@assignment).to be_excused_for(@student)
          end

          it 'accepts an excusal from the final grader' do
            @assignment.grade_student(@student, grader: @final_grader, provisional: true, excused: true)
            expect(@assignment).to be_excused_for(@student)
          end

          it 'allows the final grader to un-excuse an assignment if a score is provided' do
            @assignment.grade_student(@student, grader: @final_grader, provisional: true, excused: true)
            @assignment.grade_student(@student, grader: @final_grader, provisional: true, excused: false, score: 100)
            expect(@assignment).not_to be_excused_for(@student)
          end

          it 'accepts an excusal from an admin' do
            admin = account_admin_user
            @assignment.grade_student(@student, grader: admin, provisional: true, excused: true)
            expect(@assignment).to be_excused_for(@student)
          end

          it 'allows an admin to un-excuse an assignment if a score is provided' do
            admin = account_admin_user
            @assignment.grade_student(@student, grader: @final_grader, provisional: true, excused: true)
            @assignment.grade_student(@student, grader: admin, provisional: true, excused: false, score: 100)
            expect(@assignment).not_to be_excused_for(@student)
          end
        end
      end
    end

    describe 'AnonymousOrModerationEvent creation on grading a submission' do
      let_once(:assignment) do
        course.assignments.create!(
          anonymous_grading: true,
          grading_type: 'letter_grade',
          points_possible: 100
        )
      end

      let(:last_event) do
        AnonymousOrModerationEvent.where(assignment: assignment, event_type: 'submission_updated').last
      end

      it 'creates an event when a grader changes a grade' do
        expect {
          assignment.grade_student(student, grader: teacher, grade: 'C-')
        }.to change {
          AnonymousOrModerationEvent.where(assignment: assignment, event_type: 'submission_updated').count
        }.by(1)
      end

      it 'creates an event when a grader changes a score' do
        expect {
          assignment.grade_student(student, grader: teacher, score: 60)
        }.to change {
          AnonymousOrModerationEvent.where(assignment: assignment, event_type: 'submission_updated').count
        }.by(1)
      end

      it 'creates an event when a grader excuses a submission' do
        expect {
          assignment.grade_student(student, grader: teacher, excused: true)
        }.to change {
          AnonymousOrModerationEvent.where(assignment: assignment, event_type: 'submission_updated').count
        }.by(1)
      end

      it 'includes the affected submission on the event' do
        submission, * = assignment.grade_student(student, grader: teacher, score: 75)
        expect(last_event.submission_id).to eq submission.id
      end

      it 'includes the grader as the user on the event' do
        assignment.grade_student(student, grader: teacher, score: 91)
        expect(last_event.user_id).to eq teacher.id
      end

      it 'includes an event type of submission_updated' do
        assignment.grade_student(student, grader: teacher, score: -10)
        expect(last_event.event_type).to eq 'submission_updated'
      end

      describe 'payload contents' do
        it 'includes changes to "score" in the payload if changed' do
          assignment.grade_student(student, grader: teacher, score: 22)
          assignment.grade_student(student, grader: teacher, score: 11)
          expect(last_event.payload['score']).to eq [22, 11]
        end

        it 'includes changes to "grade" in the payload if changed' do
          assignment.grade_student(student, grader: teacher, grade: 'B+')
          assignment.grade_student(student, grader: teacher, grade: 'C+')
          expect(last_event.payload['grade']).to eq ['B+', 'C+']
        end

        it 'includes changes to "excused" in the payload if changed' do
          assignment.grade_student(student, grader: teacher, excused: true)
          assignment.grade_student(student, grader: teacher, grade: 'F')
          expect(last_event.payload['excused']).to eq [true, false]
        end
      end

      context "for a moderated assignment" do
        let(:moderated_assignment) do
          course.assignments.create!(
            title: 'zzz',
            points_possible: 100,
            moderated_grading: true,
            final_grader: teacher,
            grader_count: 1
          )
        end
        let(:last_event) do
          AnonymousOrModerationEvent.where(
            assignment: moderated_assignment,
            event_type: 'submission_updated'
          ).last
        end

        context "when changing the assignment's excused status as a moderator" do
          it "creates a submission_changed event when excusing the assignment" do
            moderated_assignment.grade_student(student, grader: teacher, provisional: true, excuse: true)

            expect(last_event.payload['excused']).to eq [nil, true]
          end

          it "creates a submission_changed event when unexcusing the assignment" do
            moderated_assignment.grade_student(student, grader: teacher, provisional: true, excuse: true)
            moderated_assignment.grade_student(student, grader: teacher, provisional: true, score: 40)

            expect(last_event.payload['excused']).to eq [true, false]
          end

          it "does not capture score changes in the submission_changed event" do
            moderated_assignment.grade_student(student, grader: teacher, provisional: true, excuse: true)
            moderated_assignment.grade_student(student, grader: teacher, provisional: true, score: 40)

            expect(last_event.payload).not_to include('score')
          end
        end

        it "does not create a submission_changed event when issuing a score via a provisional grade" do
          expect {
            moderated_assignment.grade_student(student, grader: teacher, provisional: true, score: 80)
          }.not_to change {
            AnonymousOrModerationEvent.where(event_type: 'submission_changed').count
          }
        end
      end
    end

    describe "submission posting" do
      context "when the submission is unposted" do
        it "posts the submission if a grade is assigned" do
          submission, * = assignment.grade_student(student, grader: teacher, score: 50)
          expect(submission).to be_posted
        end

        it "posts the submission if an excusal is granted" do
          submission, * = assignment.grade_student(student, grader: teacher, excused: true)
          expect(submission).to be_posted
        end

        it "does not post the submission for a manually-posted assignment" do
          assignment.post_policy.update!(post_manually: true)
          submission, * = assignment.grade_student(student, grader: teacher, score: 50)
          expect(submission).not_to be_posted
        end

        it "does not post the submission if the grade is provisional" do
          moderated_assignment = course.assignments.create!(
            title: "hi",
            moderated_grading: true,
            final_grader: teacher,
            grader_count: 2
          )
          submission, * = moderated_assignment.grade_student(student, grader: teacher, provisional: true, score: 40)
          expect(submission).not_to be_posted
        end
      end

      it "does not update the posted_at date for a previously-posted submission" do
        submission = assignment.submissions.find_by!(user: student)
        submission.update!(posted_at: 1.day.ago)

        expect {
          assignment.grade_student(student, grader: teacher, score: 50)
        }.not_to change {
          submission.reload.posted_at
        }
      end
    end

    describe "grade change audit records" do
      context "when assignment posts manually" do
        before(:each) do
          assignment.ensure_post_policy(post_manually: true)
        end

        it "inserts a record" do
          expect(Auditors::GradeChange::Stream).to receive(:insert).once
          assignment.grade_student(student, grade: 10, grader: teacher)
        end
      end

      context "when assignment posts automatically" do
        before(:each) do
          assignment.ensure_post_policy(post_manually: false)
        end

        it "inserts a record" do
          expect(Auditors::GradeChange::Stream).to receive(:insert).once
          assignment.grade_student(student, grade: 10, grader: teacher)
        end
      end
    end

    describe "grade change live events" do
      let(:student) { course.enroll_student(User.create!, enrollment_state: :active).user }
      let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: :active).user }

      context "when assignment posts manually" do
        before(:each) do
          assignment.ensure_post_policy(post_manually: true)
        end

        it "emits an event" do
          expect(Canvas::LiveEvents).to receive(:grade_changed).once
          assignment.grade_student(student, grade: 10, grader: teacher)
        end
      end

      context "when assignment posts automatically" do
        before(:each) do
          assignment.ensure_post_policy(post_manually: false)
        end

        it "emits two events when grading: one for grading and one for posting" do
          expect(Canvas::LiveEvents).to receive(:grade_changed).twice
          assignment.grade_student(student, grade: 10, grader: teacher)
        end
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
    @assignment.grade_student(@user, grade: 1, grader: @teacher)
    @submission = @assignment.submissions.first
    original_graded_at = @submission.graded_at
    new_time = Time.zone.now + 1.hour
    allow(Time).to receive(:now).and_return(new_time)
    @assignment.grade_student(@user, grade: 2, grader: @teacher)
    @submission.reload
    expect(@submission.graded_at).not_to eql original_graded_at
  end

  describe "#update_submission" do
    before :once do
      setup_assignment_with_homework
      @assignment.unmute!
    end

    it "should hide grading comments if assignment is muted and commenter is teacher" do
      @assignment.mute!
      @assignment.update_submission(@user, comment: 'hi', author: @teacher)
      submission = @assignment.submissions.first
      comment = submission.submission_comments.first
      expect(comment).to be_hidden
    end

    it "hides grading comments if commenter is teacher and assignment is muted after commenting" do
      @assignment.update_submission(@user, comment: 'hi', author: @teacher)
      @assignment.mute!
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

    it "does not hide grading comments if commenter is student and assignment is muted after commenting" do
      @assignment.update_submission(@user, comment: 'hi', author: @student1)
      @assignment.mute!
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

    context 'for moderated assignments' do
      before(:once) do
        teacher_in_course
        @first_teacher = @teacher

        teacher_in_course
        @second_teacher = @teacher

        assignment_model(course: @course, moderated_grading: true, grader_count: 2)
      end

      let(:submission) { @assignment.submissions.first }

      it 'allows graders to submit comments up to the set grader count' do
        @assignment.update_submission(@student, commenter: @first_teacher, comment: 'hi', provisional: true)
        @assignment.update_submission(@student, commenter: @second_teacher, comment: 'hi', provisional: true)

        expect(@assignment.moderation_graders).to have(2).items
      end

      it 'does not allow graders to comment beyond the set grader count' do
        @assignment.update_submission(@student, commenter: @first_teacher, comment: 'hi', provisional: true)
        @assignment.update_submission(@student, commenter: @second_teacher, comment: 'hi', provisional: true)

        teacher_in_course
        @superfluous_teacher = @teacher

        expect { @assignment.update_submission(@student, commenter: @superfluous_teacher, comment: 'hi', provisional: true) }.
          to raise_error(Assignment::MaxGradersReachedError)
      end

      it 'allows the same grader to issue multiple comments' do
        @assignment.update_submission(@student, commenter: @first_teacher, comment: 'hi', provisional: true)

        expect(@assignment.moderation_graders).to have(1).item
      end

      it 'creates at most one entry per grader' do
        first_student = @student

        student_in_course
        second_student = @student

        @assignment.update_submission(first_student, commenter: @first_teacher, comment: 'hi', provisional: true)
        @assignment.update_submission(second_student, commenter: @first_teacher, comment: 'hi', provisional: true)

        expect(@assignment.moderation_graders).to have(1).item
      end

      it 'creates at most one entry when a grader both grades and comments' do
        @assignment.update_submission(@student, commenter: @first_teacher, comment: 'hi', provisional: true)
        @assignment.grade_student(@student, grader: @first_teacher, provisional: true, score: 10)

        expect(@assignment.moderation_graders).to have(1).item
      end

      context 'with a final grader' do
        before(:once) do
          teacher_in_course(active_all: true)
          @final_grader = @teacher

          @assignment.update!(final_grader: @final_grader)
        end

        it 'allows the moderator to comment regardless of the current grader count' do
          @assignment.update_submission(@student, commenter: @first_teacher, comment: 'hi', provisional: true)
          @assignment.update_submission(@student, commenter: @second_teacher, comment: 'hi', provisional: true)
          @assignment.update_submission(@student, commenter: @final_grader, comment: 'hi', provisional: true)

          expect(@assignment.moderation_graders).to have(3).items
        end

        it 'excludes the moderator from the current grader count when considering provisional graders' do
          @assignment.update_submission(@student, commenter: @final_grader, comment: 'hi', provisional: true)
          @assignment.update_submission(@student, commenter: @first_teacher, comment: 'hi', provisional: true)
          @assignment.update_submission(@student, commenter: @second_teacher, comment: 'hi', provisional: true)

          expect(@assignment.moderation_graders).to have(3).items
        end
      end
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

    it "should delegate to NeedsGradingCountQuery" do
      query = double('Assignments::NeedsGradingCountQuery')
      expect(query).to receive(:manual_count)
      expect(Assignments::NeedsGradingCountQuery).to receive(:new).with(@assignment).and_return(query)
      @assignment.needs_grading_count
    end

    it "should update when section (and its enrollments) are moved" do
      @assignment.update_attribute(:updated_at, 1.minute.ago)
      expect(@assignment.needs_grading_count).to eql(1)
      enable_cache do
        expect(Assignments::NeedsGradingCountQuery.new(@assignment, nil).manual_count).to be(1)
        course2 = @course.account.courses.create!
        e = @course.enrollments.where(user_id: @user.id).first.course_section
        e.move_to_course(course2)
        @assignment.reload
        expect(Assignments::NeedsGradingCountQuery.new(@assignment, nil).manual_count).to be(0)
      end
      expect(@assignment.needs_grading_count).to eql(0)
    end

    it "updated_at should be set when needs_grading_count changes due to a submission" do
      expect(@assignment.needs_grading_count).to eql(1)
      old_timestamp = Time.now.utc - 1.minute
      Assignment.where(:id => @assignment).update_all(:updated_at => old_timestamp)
      @assignment.grade_student(@user, grade: "0", grader: @teacher)
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
        @assignment.grade_student(@user, grade: 'pass', grader: @teacher)
        expect(submission.grade).to eql('complete')
      end

      it "preserves fail with zero points possible" do
        @assignment.grade_student(@user, grade: 'fail', grader: @teacher)
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

      s = @assignment.grade_student(@user, grade: 'C', grader: @teacher)
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

      s = @assignment.grade_student(@user, grade: 'C', grader: @teacher)
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

      s = @assignment.grade_student(@user, grade: '3.0', grader: @teacher)
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
          b: {name: "Bad", value: 0},
        }
        @gs2 = @course.grading_standards.create! standard_data: {
          a: {name: "🚀", value: 100},
          b: {name: "🚽", value: 0},
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

    it "converts using numbers sensitive to floating point errors" do
      @assignment.grading_type = "letter_grade"
      @assignment.points_possible = 100
      gs = @assignment.context.grading_standards.build({title: "Numerical"})
      gs.data = {"A" => 0.29, "F" => 0.00}
      gs.assignments << @assignment
      gs.save!
      @assignment.save!

      # 0.29 * 100 = 28.999999999999996 in ruby, which matches F instead of A
      expect(@assignment.score_to_grade(29)).to eq("A")
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

      s = @assignment.grade_student(@user, grade: '3.0', grader: @teacher)
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
      s = @assignment.grade_student(@user, grade: "1", grader: @teacher)
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
      s2 = @a.grade_student(@user, grade: "10", grader: @teacher)
      s.reload
      expect(s).to eql(s2[0])
      # there should only be one version, even though the grade changed
      expect(s.versions.length).to eql(1)
      expect(s2[0].state).to eql(:graded)
    end

    context "group assignments" do
      before :once do
        @student1, @student2 = n_students_in_course(2, course: @course)
        gc = @course.group_categories.create! name: "a name"
        group = gc.groups.create! name: "zxcv", context: @course
        [@student1, @student2].each { |u|
          group.group_memberships.create! user: u, workflow_state: "accepted"
        }
        @assignment.update_attribute :group_category, gc
      end

      context "when excusing an assignment" do
        it "marks the assignment as excused" do
          submission, = @assignment.grade_student(@student, grader: @teacher, excuse: true)
          expect(submission).to be_excused
        end

        it "doesn't mark everyone in the group excused" do
          sub1, sub2 = @assignment.grade_student(@student1, grader: @teacher, excuse: true)

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
            grader: @teacher,
            excuse: false,
          )

          expect(sub1.user).to eq @student1
          expect(sub1.grade).to eq "38"
          expect(sub2.user).to eq @student2
          expect(sub2.grade).to eq "38"
        end

        it "doesn't overwrite the grades of group members who have been excused" do
          sub1 = @assignment.grade_student(@student1, grader: @teacher, excuse: true).first
          expect(sub1).to be_excused

          sub2, sub3 = @assignment.grade_student(@student2, grade: 10, grader: @teacher)
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

    context "with alphanumeric grades" do
      before(:once) do
        @assignment.update!(grading_type: 'letter_grade', points_possible: 10.0)
        grading_standard = @course.grading_standards.build(title: "Number Before Letter")
        grading_standard.data = {
          "1A" => 0.9,
          "2B" => 0.8,
          "3C" => 0.7,
          "4D" => 0.6,
          "5+" => 0.5,
          "5F" => 0
        }
        grading_standard.assignments << @assignment
        grading_standard.save!
      end

      it "does not treat maximum grade as a number" do
        expect(@assignment.interpret_grade("1A")).to eq 10.0
      end

      it "does not treat lower grade as a number" do
        expect(@assignment.interpret_grade("2B")).to eq 8.9
      end

      it "does not treat number followed by plus symbol as a number" do
        expect(@assignment.interpret_grade("5+")).to eq 5.9
      end

      it "treats unsigned integer score as a number" do
        expect(@assignment.interpret_grade("7")).to eq 7.0
      end

      it "treats negative score with decimals as a number" do
        expect(@assignment.interpret_grade("-.2")).to eq (-0.2)
      end

      it "treats positive score with decimals as a number" do
        expect(@assignment.interpret_grade("+0.35")).to eq 0.35
      end

      it "treats number with percent symbol as a percentage" do
        expect(@assignment.interpret_grade("75.2%")).to eq 7.52
      end
    end

    context "with gpa_scale" do
      before(:once) do
        @assignment.update!(grading_type: 'gpa_scale', points_possible: 10.0)
      end

      it "accepts numbers" do
        expect(@assignment.interpret_grade("9.5")).to eq 9.5
      end
    end
  end

  describe '#submit_homework' do
    before(:once) do
      course_with_student(active_all: true)
      @a = @course.assignments.create! title: "blah",
        submission_types: "online_text_entry,online_url",
        points_possible: 10
    end

    it "sets the 'eula_agreement_timestamp'" do
      setup_assignment_without_submission
      timestamp = Time.now.to_i.to_s
      @a.submit_homework(@user, {eula_agreement_timestamp: timestamp})
      expect(@a.submissions.first.turnitin_data[:eula_agreement_timestamp]).to eq timestamp
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
      @a.submissions.find_by(user: @user).update(
        late_policy_status: 'late',
        seconds_late_override: 120
      )
      s = @a.submit_homework(@user, submission_type: "online_url",
                             url: "http://example.com")
      expect(s.submission_type).to eq "online_url"
      expect(s.url).to eq "http://example.com"
      expect(s.late_policy_status).to be nil
      expect(s.seconds_late_override).to be nil

      s2 = @a.submit_homework(@user, submission_type: "online_text_entry",
                              body: "blah blah blah blah blah blah blah")
      expect(s2.submission_type).to eq "online_text_entry"
      expect(s2.body).to eq "blah blah blah blah blah blah blah"
      expect(s2.url).to be_nil
      expect(s2.workflow_state).to eq "submitted"

      @a.submissions.find_by(user: @user).update(
        late_policy_status: 'late',
        seconds_late_override: 120
      )
      # comments shouldn't clear out submission data
      s3 = @a.submit_homework(@user, comment: "BLAH BLAH")
      expect(s3.body).to eq "blah blah blah blah blah blah blah"
      expect(s3.submission_comments.first.comment).to eq "BLAH BLAH"
      expect(s3.submission_type).to eq "online_text_entry"
      expect(s3.late_policy_status).to eq "late"
      expect(s3.seconds_late_override).to eq 120
    end

    it "sets the submission's 'lti_user_id'" do
      setup_assignment_without_submission
      submission = @a.submit_homework(@user)
      expect(submission.lti_user_id).to eq @user.lti_context_id
    end
  end

  describe "muting" do
    before :once do
      assignment_model(course: @course)
      @student = @course.enroll_student(User.create!, enrollment_state: :active).user
      @teacher = @course.enroll_teacher(User.create!, enrollment_state: :active).user
    end

    it "defaults to muted" do
      expect(@course.assignments.create!).to be_muted
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

    it 'mutes assignments when they are update from non-anonymous to anonymous' do
      assignment = @course.assignments.create!
      assignment.update!(muted: false)
      expect { assignment.update!(anonymous_grading: true) }.to change {
        assignment.muted?
      }.from(false).to(true)
    end

    it 'does not mute assignments when they are updated from anonymous to non-anonymous' do
      assignment = @course.assignments.create!(anonymous_grading: true)
      assignment.update!(muted: false)
      expect { assignment.update!(anonymous_grading: false) }.not_to change {
        assignment.muted?
      }.from(false)
    end

    describe "grade change audit records" do
      it "continues to insert grade change records when assignment is muted" do
        expect(Auditors::GradeChange::Stream).to receive(:insert).once
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
      end

      it "does not insert a grade change event when muting" do
        @assignment.unmute!
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        expect(Auditors::GradeChange::Stream).not_to receive(:insert)
        @assignment.mute!
      end
    end

    describe "grade change live events" do
      it "emits an event for graded submissions when muting" do
        @assignment.unmute!
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        expect(Canvas::LiveEvents).to receive(:grade_changed).once
        @assignment.mute!
      end
    end
  end

  describe "#unmute!" do
    before :once do
      @assignment = assignment_model(course: @course)
      @student = @course.enroll_student(User.create!, enrollment_state: :active).user
      @teacher = @course.enroll_teacher(User.create!, enrollment_state: :active).user
      @assignment.unmute!
    end

    it "returns falsey when assignment is not muted" do
      expect(@assignment.unmute!).to be_falsey
    end

    context "when assignment is anonymously graded" do
      before :once do
        @assignment.update(moderated_grading: true, anonymous_grading: true, grader_count: 1)
        @assignment.mute!
      end

      context "when grades have not been published" do
        it "does not unmute the assignment" do
          @assignment.unmute!
          expect(@assignment).to be_muted
        end

        it "adds an error for 'muted'" do
          @assignment.unmute!
          expect(@assignment.errors["muted"]).to eq(["Anonymous moderated assignments cannot be unmuted until grades are posted"])
        end

        it "returns false" do
          expect(@assignment.unmute!).to eq(false)
        end
      end

      context "when grades have been published" do
        before :once do
          @assignment.update_attribute(:grades_published_at, Time.now.utc)
        end

        it "unmutes the assignment" do
          @assignment.unmute!
          expect(@assignment).not_to be_muted
        end

        it "returns true" do
          expect(@assignment.unmute!).to eq(true)
        end
      end
    end

    context "when assignment is anonymously graded and not moderated" do
      before :once do
        @assignment.update(moderated_grading: false, anonymous_grading: true)
        @assignment.mute!
      end

      it "unmutes the assignment" do
        @assignment.unmute!
        expect(@assignment).not_to be_muted
      end

      it "returns true" do
        expect(@assignment.unmute!).to eq(true)
      end
    end

    context "when assignment is not anonymously graded" do
      before :once do
        @assignment.update(moderated_grading: true, anonymous_grading: false, grader_count: 1)
        @assignment.mute!
      end

      it "unmutes the assignment" do
        @assignment.unmute!
        expect(@assignment).not_to be_muted
      end

      it "returns true" do
        expect(@assignment.unmute!).to eq(true)
      end
    end

    it "does not insert a grade change audit record when unmuting" do
      @assignment.mute!
      @assignment.grade_student(@student, grade: 10, grader: @teacher)
      expect(Auditors::GradeChange::Stream).not_to receive(:insert)
      @assignment.unmute!
    end

    it "emits a grade change live event for graded submissions when unmuting" do
      @assignment.mute!
      @assignment.grade_student(@student, grade: 10, grader: @teacher)
      expect(Canvas::LiveEvents).to receive(:grade_changed).once
      @assignment.unmute!
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
      allow(mock_submissions).to receive(:build).and_return(real_sub).once
      allow(@assignment).to receive(:submissions).and_return(mock_submissions)

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

  describe "#peer_reviews_assigned" do
    before :once do
      @assignment = assignment_model(course: @course)
      @assignment.peer_reviews = true
      @assignment.automatic_peer_reviews = true
      @assignment.due_at = 1.day.ago
      @assignment.peer_reviews_assigned = true
      @assignment.save!
    end

    it "is set to `true` when all peer reviews have been assigned" do
      @assignment.assign_peer_reviews
      expect(@assignment.peer_reviews_assigned).to be true
    end

    it "is set to `false` when the #assign_at time changes" do
      @assignment.assign_peer_reviews
      @assignment.peer_reviews_assign_at = 1.day.from_now
      @assignment.save!
      expect(@assignment.peer_reviews_assigned).to be false
    end
  end

  describe "#peer_reviews_assign_at" do
    it "is writeable" do
      assignment_model(course: @course)
      now = Time.zone.now
      @assignment.peer_reviews_assign_at = now
      expect(@assignment.peer_reviews_assign_at).to eq now
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

    describe '"auto-assign" scheduling' do
      before :each do
        @a.peer_reviews = true
        @a.automatic_peer_reviews = true
        @a.due_at = Time.zone.now
      end

      it "schedules a 'do_auto_peer_review' job when saved" do
        expects_job_with_tag('Assignment#do_auto_peer_review', 1) {
          @a.save!
        }
      end

      it "schedules review assignment using the assignment due date" do
        @a.peer_reviews_due_at = 1.day.from_now
        @a.save!
        job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
        expect(job.run_at).to eq @a.peer_reviews_due_at
      end

      it "re-schedules the existing job when the assignment due date changes" do
        @a.peer_reviews_due_at = 1.day.from_now
        @a.save!
        job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
        @a.peer_reviews_due_at = 2.days.from_now
        @a.save!
        job.reload
        expect(job.run_at).to eq @a.peer_reviews_due_at
      end

      it "does not schedule a job when #skip_schedule_peer_reviews is set" do
        @a.skip_schedule_peer_reviews = true

        expects_job_with_tag('Assignment#do_auto_peer_review', 0) {
          @a.save!
        }
      end
    end

    it "should assign multiple peer reviews" do
      @a.reload
      @submissions = []
      users = create_users_in_course(@course, 4.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
      users.each do |u|
        @submissions << @a.submit_homework(u, :submission_type => "online_url", :url => "http://www.google.com")
      end
      @a.peer_review_count = 2
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
    end

    it "should not assign out of group for graded group-discussions" do
      # (as opposed to group assignments)
      group_discussion_assignment

      users = create_users_in_course(@course, 6.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
      [@group1, @group2].each do |group|
        users.pop(3).each do |user|
          group.add_user(user)
          @topic.child_topic_for(user).reply_from(:user => user, :text => "entry from #{user.name}")
        end
      end

      @assignment.reload
      @assignment.peer_review_count = 2
      @assignment.save!
      requests = @assignment.assign_peer_reviews
      expect(requests.count).to eq 12
      requests.each do |req|
        group = @group1.users.include?(req.user) ? @group1 : @group2
        expect(group.users).to include(req.assessor)
      end
    end

    context "intra group peer reviews" do
      it "should not assign peer reviews to members of the same group when disabled" do
        @submissions = []
        gc = @course.group_categories.create! name: "Groupy McGroupface"
        @a.update group_category_id: gc.id,
                             grade_group_students_individually: false
        users = create_users_in_course(@course, 8.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
        ["group_1", "group_2"].each do |group_name|
          group = gc.groups.create! name: group_name, context: @course
          users.pop(4).each{|user| group.add_user(user)}
        end

        @a.submit_homework(gc.groups[0].users.first, :submission_type => "online_url", :url => "http://www.google.com")
        @a.peer_review_count = 3

        res = @a.assign_peer_reviews
        expect(res.length).to be 0
      end

      it "should assign peer reviews to members of the same group when enabled" do
        @submissions = []
        gc = @course.group_categories.create! name: "Groupy McGroupface"
        @a.update group_category_id: gc.id,
                             grade_group_students_individually: false
        users = create_users_in_course(@course, 8.times.map{ |i| {name: "user #{i}"} }, return_type: :record)
        ["group_1", "group_2"].each do |group_name|
          group = gc.groups.create! name: group_name, context: @course
          users.pop(4).each{|user| group.add_user(user)}
        end

        @a.submit_homework(gc.groups[0].users.first, :submission_type => "online_url", :url => "http://www.google.com")
        @a.peer_review_count = 3
        @a.intra_group_peer_reviews = true
        res = @a.assign_peer_reviews
        expect(res.length).to be 12
        expect((res.map(&:user_id) - gc.groups[1].users.map(&:id)).length).to be res.length
      end
    end

    context "when using assignment overrides and manual peer review assignment" do
      before :once do
        @assignment = assignment_model(
          automatic_peer_reviews: false,
          course: @course,
          due_at: 1.day.from_now,
          only_visible_to_overrides: false,
          peer_review_count: 1,
          peer_reviews: true,
          submission_types: "online_url",
          workflow_state: "published"
        )

        @section1 = @course.course_sections.create!(name: 'Section One')
        @section2 = @course.course_sections.create!(name: 'Section Two')

        @override_s1 = @assignment.assignment_overrides.build
        @override_s1.set = @section1
        @override_s1.due_at = 2.days.from_now
        @override_s1.save!
      end

      context "when the assignment is assigned to everyone" do
        before :once do
          @student1, @student2, @student3, @student4 = create_users(4, return_type: :record)
          student_in_section(@section1, user: @student1)
          student_in_section(@section2, user: @student2)
          student_in_section(@section1, user: @student3)
          student_in_section(@section2, user: @student4)

          # Submit homework for review. Only submitted homework is considered for review.
          @assignment.submit_homework(@student1, submission_type: 'online_url', url: 'http://www.google.com')
          @assignment.submit_homework(@student2, submission_type: 'online_url', url: 'http://www.google.com')
          @assignment.submit_homework(@student3, submission_type: 'online_url', url: 'http://www.google.com')
          @assignment.submit_homework(@student4, submission_type: 'online_url', url: 'http://www.google.com')
        end

        it "assigns every student a peer for review" do
          assessment_requests = @assignment.assign_peer_reviews
          expect(assessment_requests.map(&:assessor_id)).to contain_exactly(
            @student1.id,
            @student2.id,
            @student3.id,
            @student4.id
          )
        end

        it "assigns every student as a peer to review" do
          assessment_requests = @assignment.assign_peer_reviews
          expect(assessment_requests.map(&:user_id)).to contain_exactly(
            @student1.id,
            @student2.id,
            @student3.id,
            @student4.id
          )
        end
      end

      context "when the assignment is assigned only to some students" do
        before :once do
          @assignment.only_visible_to_overrides = true
          @assignment.save!

          @student1, @student2, @student3, @student4 = create_users(4, return_type: :record)
          student_in_section(@section1, user: @student1)
          student_in_section(@section2, user: @student2)
          student_in_section(@section1, user: @student3)
          student_in_section(@section2, user: @student4)

          # Submit homework for review. Only submitted homework is considered for review.
          @assignment.submit_homework(@student1, submission_type: 'online_url', url: 'http://www.google.com')
          @assignment.submit_homework(@student3, submission_type: 'online_url', url: 'http://www.google.com')
        end

        it "assigns only assigned students a peer for review" do
          assessment_requests = @assignment.assign_peer_reviews
          expect(assessment_requests.map(&:assessor_id)).to contain_exactly(
            @student1.id,
            @student3.id
          )
        end

        it "assigns only assigned students as a peer to review" do
          assessment_requests = @assignment.assign_peer_reviews
          expect(assessment_requests.map(&:user_id)).to contain_exactly(
            @student1.id,
            @student3.id
          )
        end
      end

      it "does not assign peer reviews when not enough students have submitted" do
        @student1, @student2 = create_users(2, return_type: :record)
        student_in_section(@section1, user: @student1)
        student_in_section(@section2, user: @student2)

        # Submit homework for review. Only submitted homework is considered for review.
        @assignment.submit_homework(@student1, submission_type: 'online_url', url: 'http://www.google.com')

        assessment_requests = @assignment.assign_peer_reviews
        expect(assessment_requests).to be_empty
      end
    end

    describe '"auto-assign" scheduling with assignment overrides' do
      before :once do
        @assignment = assignment_model(
          automatic_peer_reviews: false,
          course: @course,
          only_visible_to_overrides: false,
          peer_review_count: 1,
          peer_reviews: true,
          submission_types: "online_url",
          workflow_state: "published"
        )

        @assignment.automatic_peer_reviews = true

        @section1 = @course.course_sections.create!(name: 'Section One')
        @section2 = @course.course_sections.create!(name: 'Section Two')

        @override_s1 = @assignment.assignment_overrides.create!(
          due_at: 2.days.from_now,
          due_at_overridden: true,
          set: @section1
        )

        @student1, @student2, @student3, @student4 = create_users(4, return_type: :record)
        student_in_section(@section1, user: @student1)
        student_in_section(@section2, user: @student2)
        student_in_section(@section1, user: @student3)
        student_in_section(@section2, user: @student4)

        # Submit homework for review. Only submitted homework is considered for review.
        @sub1 = @assignment.submit_homework(@student1, submission_type: 'online_url', url: 'http://www.google.com')
        @sub2 = @assignment.submit_homework(@student2, submission_type: 'online_url', url: 'http://www.google.com')
        @sub3 = @assignment.submit_homework(@student3, submission_type: 'online_url', url: 'http://www.google.com')
        @sub4 = @assignment.submit_homework(@student4, submission_type: 'online_url', url: 'http://www.google.com')
      end

      context "when reviews are automatically assigned using the 'assign_at' date" do
        before :each do
          @assignment.due_at = 1.day.from_now
          @assignment.peer_reviews_assign_at = 1.day.from_now
        end

        it "schedules a 'do_auto_peer_review' job when saved" do
          expects_job_with_tag('Assignment#do_auto_peer_review', 1) {
            @assignment.save!
          }
        end

        it "schedules the job using the 'assign_at' date" do
          @assignment.save!
          job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
          expect(job.run_at).to eq @assignment.peer_reviews_assign_at
        end

        context "when the job runs" do
          it "assigns peer reviews to all students" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(1.day.from_now) do
              job.invoke_job
              # assessment_requests = @assignment.assign_peer_reviews
              expect(AssessmentRequest.count).to be(4)
            end
          end

          it "does not schedule another job" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            expect do
              Timecop.freeze(1.day.from_now) do
                job.invoke_job
              end
            end.not_to change { Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last.run_at }
          end

          it "sets #peer_reviews_assigned to `true`" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(1.day.from_now) do
              job.invoke_job
              expect(@assignment.reload.peer_reviews_assigned).to be(true)
            end
          end
        end
      end

      context "when reviews are assigned using due dates" do
        before :each do
          @assignment.due_at = 1.day.from_now
          @assignment.peer_reviews_assign_at = nil
        end

        # schedules a 'do_auto_peer_review' job for the earliest
        # assigns all reviews when the 'assign_at' date has passed
        # does not schedule additional jobs
        # sets #peer_reviews_assigned to `true`

        it "schedules a 'do_auto_peer_review' job when saved" do
          expects_job_with_tag('Assignment#do_auto_peer_review', 1) {
            @assignment.save!
          }
        end

        context "when the 'due_at' date of the assignment is the earliest due date" do
          it "schedules the job using the 'due_at' date of the assignment" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            expect(job.run_at).to eq @assignment.due_at
          end

          it "assigns peer reviews to all students assigned directly to the assignment" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(1.day.from_now) do
              job.invoke_job
              assessment_requests = AssessmentRequest.all.to_a
              expect(assessment_requests.map(&:assessor_id)).to contain_exactly(
                @student2.id,
                @student4.id
              )
            end
          end

          it "schedules another job" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            expect do
              Timecop.freeze(1.day.from_now) do
                job.invoke_job
              end
            end.to change { Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last.run_at }
          end

          it "uses the next due date when scheduling the next job" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(1.day.from_now) do
              job.invoke_job
            end
            expect(job.reload.run_at).to eq @override_s1.due_at
          end

          it "sets #peer_reviews_assigned to `false`" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(1.day.from_now) do
              job.invoke_job
            end
            expect(@assignment.reload.peer_reviews_assigned).to be(false)
          end
        end

        context "when the 'due_at' date of an override is the earliest due date" do
          before :each do
            @assignment.due_at = 3.days.from_now
          end

          it "schedules the job using the 'due_at' date of the override" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            expect(job.run_at).to eq @override_s1.due_at
          end

          it "assigns peer reviews to all students assigned with the override" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(2.days.from_now) do
              job.invoke_job
              assessment_requests = AssessmentRequest.all.to_a
              expect(assessment_requests.map(&:assessor_id)).to contain_exactly(
                @student1.id,
                @student3.id
              )
            end
          end

          it "schedules another job" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            expect do
              Timecop.freeze(2.days.from_now) do
                job.invoke_job
              end
            end.to change { Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last.run_at }
          end

          it "uses the next due date when scheduling the next job" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(2.days.from_now) do
              job.invoke_job
            end
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            expect(job.run_at).to eq @assignment.due_at
          end

          it "sets #peer_reviews_assigned to `false`" do
            @assignment.save!
            job = Delayed::Job.where(tag: "Assignment#do_auto_peer_review").last
            Timecop.freeze(2.days.from_now) do
              job.invoke_job
            end
            expect(@assignment.reload.peer_reviews_assigned).to be(false)
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
        @assignment.update(:grading_type => 'letter_grade', :points_possible => 20)
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
        @assignment.update(:grading_type => 'gpa_scale', :points_possible => 20)
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

  describe "#grants_right?" do
    before(:once) do
      assignment_model(course: @course)
      @admin = account_admin_user()
      teacher_in_course(:course => @course)
      @grading_period_group = @course.root_account.grading_period_groups.create!(title: "Example Group")
      @grading_period_group.enrollment_terms << @course.enrollment_term
      @course.enrollment_term.save!
      @assignment.reload

      @grading_period_group.grading_periods.create!({
        title: "Closed Grading Period",
        start_date: 5.weeks.ago,
        end_date: 3.weeks.ago,
        close_date: 1.week.ago
      })
      @grading_period_group.grading_periods.create!({
        title: "Open Grading Period",
        start_date: 3.weeks.ago,
        end_date: 1.week.ago,
        close_date: 1.week.from_now
      })
    end

    context "to attach submission comment files" do
      it 'is true when a student can read an assignment but the assignment is locked' do
        @assignment.lock_at = 1.week.ago
        @assignment.submission_types = 'online_upload'
        @assignment.save!
        expect(@assignment.grants_right?(@student, :attach_submission_comment_files)).to be true
      end
    end

    context "to delete" do
      context "when there are no grading periods" do
        it "is true for admins" do
          allow(@course).to receive(:grading_periods?).and_return false
          expect(@assignment.reload.grants_right?(@admin, :delete)).to be true
        end

        it "is false for teachers" do
          allow(@course).to receive(:grading_periods?).and_return false
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to be true
        end
      end

      context "when the assignment is due in a closed grading period" do
        before(:once) do
          @assignment.update(due_at: 4.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(false)
        end
      end

      context "when the assignment is due in an open grading period" do
        before(:once) do
          @assignment.update(due_at: 2.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is due after all grading periods" do
        before(:once) do
          @assignment.update(due_at: 1.day.from_now)
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is due before all grading periods" do
        before(:once) do
          @assignment.update(due_at: 6.weeks.ago)
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment has no due date" do
        before(:once) do
          @assignment.update(due_at: nil)
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is due in a closed grading period for a student" do
        before(:once) do
          @assignment.update(due_at: 2.days.from_now)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.override_due_at(4.weeks.ago)
          override.save!
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(false)
        end
      end

      context "when the assignment is overridden with no due date for a student" do
        before(:once) do
          @assignment.update(due_at: nil)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.save!
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment has a deleted override in a closed grading period for a student" do
        before(:once) do
          @assignment.update(due_at: 2.days.from_now)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.override_due_at(4.weeks.ago)
          override.save!
          override.destroy
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is true for teachers" do
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(true)
        end
      end

      context "when the assignment is overridden with no due date and is only visible to overrides" do
        before(:once) do
          @assignment.update(due_at: 4.weeks.ago, only_visible_to_overrides: true)
          override = @assignment.assignment_overrides.build
          override.set = @course.default_section
          override.save!
        end

        it "is true for admins" do
          expect(@assignment.reload.grants_right?(@admin, :delete)).to eql(true)
        end

        it "is false for teachers" do
          # since the override does not have the due date overridden, we fall
          # back to using the assignment's due_at, which falls in a closed grading period
          expect(@assignment.reload.grants_right?(@teacher, :delete)).to eql(false)
        end
      end
    end

    describe "to update" do
      before(:each) do
        @course.enable_feature!(:moderated_grading)

        @ta = ta_in_course(course: @course, active_all: true).user
        @moderator = teacher_in_course(course: @course, active_all: true).user

        @moderated_assignment = @course.assignments.create!(
          moderated_grading: true,
          grader_count: 3,
          final_grader: @moderator
        )
      end

      it "allows the designated moderator to update a moderated assignment" do
        expect(@moderated_assignment.grants_right?(@moderator, :update)).to eq(true)
      end

      it "allows non-moderators with Select Final Grade permission to update a moderated assignment" do
        expect(@moderated_assignment.grants_right?(@ta, :update)).to eq(true)
      end

      it "allows an admin to update a moderated assignment" do
        expect(@moderated_assignment.grants_right?(@admin, :update)).to eq(true)
      end

      it "does not allow users without Select Final Grade permission to update a moderated assignment" do
        @course.account.role_overrides.create!(permission: :select_final_grade, role: ta_role, enabled: false)
        expect(@moderated_assignment.grants_right?(@ta, :update)).to be false
      end

      it "allows an instructor to update a moderated assignment with no moderator selected" do
        @course.account.role_overrides.create!(permission: :select_final_grade, role: ta_role, enabled: false)
        @moderated_assignment.update!(final_grader: nil)
        expect(@moderated_assignment.grants_right?(@ta, :update)).to eq(true)
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

    it ".to_ics should return correct dates even with different time_zone_edited" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:55am", :course => @course, :time_zone_edited => 'EST')
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      res = @assignment.to_ics
      expect(res).not_to be_nil
      expect(res.match(/DTEND:20080903T115500Z/)).not_to be_nil
      expect(res.match(/DTSTART:20080903T115500Z/)).not_to be_nil
      expect(res.match(/DTSTAMP:20080903T120500Z/)).not_to be_nil
    end

    it ".to_ics should return correct dates even with different timezone on call midnight" do
      Time.zone = 'UTC'
      assignment_model(:due_at => "Sep 3 2008 11:59pm", :course => @course, :time_zone_edited => 'EST')
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      Time.zone = 'HST'
      res = @assignment.to_ics
      expect(res).not_to be_nil
      expect(res.match(/DTEND:20080903T235900Z/)).not_to be_nil
      expect(res.match(/DTSTART:20080903T235900Z/)).not_to be_nil
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
      expect(res.dtstart.tz_utc).to eq true
      expect(res.dtstart.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.dtend.tz_utc).to eq true
      expect(res.dtend.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.dtstamp.tz_utc).to eq true
      expect(res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
    end

    it ".to_ics should return data for assignments with due dates in correct tz" do
      Time.zone = 'Alaska' # -0800
      assignment_model(:due_at => "Sep 3 2008 11:55am", :course => @course)
      # force known value so we can check serialization
      @assignment.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
      res = @assignment.to_ics(in_own_calendar: false)
      expect(res).not_to be_nil
      expect(res.dtstart.tz_utc).to eq true
      expect(res.dtstart.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.dtend.tz_utc).to eq true
      expect(res.dtend.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      expect(res.dtstamp.tz_utc).to eq true
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

  describe "#quiz_lti?" do
    before :once do
      assignment_model(:submission_types => "external_tool", :course => @course)
    end

    context "when quizzes 2 external tool not present" do
      it "returns false" do
        expect(@a.quiz_lti?).to be false
      end
    end

    context "when quizzes 2 external tool is present" do
      before do
        tool = @c.context_external_tools.create!(
          :name => 'Quizzes.Next',
          :consumer_key => 'test_key',
          :shared_secret => 'test_secret',
          :tool_id => 'Quizzes 2',
          :url => 'http://example.com/launch'
        )
        @a.external_tool_tag_attributes = { :content => tool }
      end

      it "returns true" do
        expect(@a.quiz_lti?).to be true
      end
    end
  end

  describe "#quiz_lti!" do
    before :once do
      assignment_model(:submission_types => "online_quiz", :course => @course)
      tool = @c.context_external_tools.create!(
        :name => 'Quizzes.Next',
        :consumer_key => 'test_key',
        :shared_secret => 'test_secret',
        :tool_id => 'Quizzes 2',
        :url => 'http://example.com/launch'
      )
      @a.external_tool_tag_attributes = { :content => tool }
    end

    it "changes submission_types and break assignment's tie to quiz" do
      expect(@a.reload.quiz).not_to be nil
      expect(@a.submission_types).to eq 'online_quiz'
      @a.quiz_lti! && @a.save!
      expect(@a.reload.quiz).to be nil
      expect(@a.submission_types).to eq 'external_tool'
    end
  end

  describe "scope :type_quiz_lti" do
    context "with a quiz_lti assignment" do
      before :once do
        assignment_model(:submission_types => "external_tool", :course => @course)
        tool = @c.context_external_tools.create!(
          :name => 'Quizzes.Next',
          :consumer_key => 'test_key',
          :shared_secret => 'test_secret',
          :tool_id => 'Quizzes 2',
          :url => 'http://example.com/launch'
        )
        @a.external_tool_tag_attributes = { :content => tool }
        @a.save!
      end

      it "includes the quiz_lti quiz" do
        expect(Assignment.type_quiz_lti).not_to be_empty
      end
    end

    context "without any quiz_lti assignments" do
      before :once do
        assignment_model(:submission_types => "external_tool", :course => @course)
        tool = @c.context_external_tools.create!(
          :name => 'Some.Other.Tool',
          :consumer_key => 'test_key',
          :shared_secret => 'test_secret',
          :tool_id => 'some-other-tool-id',
          :url => 'http://example.com/launch'
        )
        @a.external_tool_tag_attributes = { :content => tool }
        @a.save!
      end

      it "returns an empty scope" do
        expect(Assignment.type_quiz_lti).to be_empty
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

      it "should not delete the assignment when unlinked" do
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
    end

    context "pages" do
      let(:submission_type) { "wiki_page" }
      let(:submission_class) { WikiPage }

      context "feature enabled" do
        before(:once) { @course.enable_feature!(:conditional_release) }

        include_examples "submittable"
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

    it 'excludes students with inactive enrollments' do
      @student1.student_enrollments.first.deactivate
      expect(@assignment.participants.include?(@student1)).to be_falsey
    end

    it 'excludes students with completed enrollments' do
      @student1.student_enrollments.first.complete!
      expect(@assignment.participants.include?(@student1)).to be_falsey
    end

    it 'excludes students with completed enrollments by date' do
      @course.start_at = 2.days.ago
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!
      expect(@assignment.participants.include?(@student1)).to be_falsey
    end

    it 'excludes students with completed enrollments by date when not differentiated' do
      @course.update!(
        conclude_at: 1.day.ago,
        restrict_enrollments_to_course_dates: true,
        start_at: 2.days.ago
      )
      # reload the course to clear any cached results of the participating_students_by_date scope
      @course.reload

      @assignment.update!(only_visible_to_overrides: false)
      expect(@assignment.participants(by_date: true)).not_to include(@student1)
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
        expect(@a.messages_sent['Assignment Due Date Changed'].first.from_name).to eq @course.name
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
        @sub2 = @assignment.grade_student(@stu2, grade: 8, grader: @teacher).first
        expect(@sub2.messages_sent).not_to be_empty
        expect(@sub2.messages_sent['Submission Graded']).to be_present
        expect(@sub2.messages_sent['Submission Graded'].first.from_name).to eq @course.name
        expect(@sub2.messages_sent['Submission Grade Changed']).to be_nil
        @sub2.update(:graded_at => Time.zone.now - 60*60)
        @sub2 = @assignment.grade_student(@stu2, grade: 9, grader: @teacher).first
        expect(@sub2.messages_sent).not_to be_empty
        expect(@sub2.messages_sent['Submission Graded']).to be_nil
        expect(@sub2.messages_sent['Submission Grade Changed']).to be_present
        expect(@sub2.messages_sent['Submission Grade Changed'].first.from_name).to eq @course.name
      end

      it "should not notify students when their grade is changed when grades are not yet posted" do
        @assignment.ensure_post_policy(post_manually: true)
        @sub2 = @assignment.grade_student(@stu2, grade: 8, grader: @teacher).first
        @sub2.update(:graded_at => Time.zone.now - 60*60)
        @sub2 = @assignment.grade_student(@stu2, grade: 9, grader: @teacher).first
        expect(@sub2.messages_sent).to be_empty
      end
    end

    context "assignment changed" do
      before :once do
        Notification.create(:name => 'Assignment Changed')
        assignment_model(course: @course)
        @a.unmute!
      end

      it "should create a message when an assignment changes after it's been published" do
        @a.created_at = Time.parse("Jan 2 2000")
        @a.description = "something different"
        @a.notify_of_update = true
        @a.save
        expect(@a.messages_sent).to be_include('Assignment Changed')
        expect(@a.messages_sent['Assignment Changed'].first.from_name).to eq @course.name
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
        expect(@a.messages_sent['Assignment Created'].first.from_name).to eq @course.name
      end

      it "should not create a message in an unpublished course" do
        Notification.create(:name => 'Assignment Created')
        course_with_teacher(:active_user => true)
        assignment_model(:course => @course)
        expect(@a.messages_sent).not_to be_include('Assignment Created')
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

        it "preload user roles for much fasterness" do
          expect(@assignment.context).to receive(:preloaded_user_has_been?).at_least(:once)

          @assignment.do_notifications!
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
          @assignment.reload

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
          allow(Time).to receive(:now).and_return(fake_submission_time)
          subA = @assignment.submit_homework @studentA, :submission_type => "online_text_entry", :body => "ooga"
          subB = @assignment.submit_homework @studentB, :submission_type => "online_text_entry", :body => "booga"

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
          allow(Time).to receive(:now).and_return(fake_submission_time)
          subA = @assignment.submit_homework @studentA, :submission_type => "online_text_entry", :body => "eenie"
          subB = @assignment.submit_homework @studentB, :submission_type => "online_text_entry", :body => "meenie"

          expect(subA.messages_sent["Group Assignment Submitted Late"]).not_to be_nil
          expect(subB.messages_sent["Group Assignment Submitted Late"]).to be_nil
        end
      end
    end
  end

  context "group assignment" do
    before :once do
      setup_assignment_with_group
      @a.unmute!
    end

    it "should submit the homework for all students in the same group" do
      sub = @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Some text for you")
      expect(sub.user_id).to eql(@u1.id)
      @a.reload
      subs = @a.submissions.not_placeholder
      expect(subs.length).to eql(2)
      expect(subs.map(&:group_id).uniq).to eql([@group.id])
      expect(subs.map(&:submission_type).uniq).to eql(['online_text_entry'])
      expect(subs.map(&:body).uniq).to eql(['Some text for you'])
    end

    it "should submit the homework for all students in the group if grading them individually" do
      @a.update_attribute(:grade_group_students_individually, true)
      @a.submit_homework(@u1, :submission_type => "online_text_entry", :body => "Test submission")
      @a.reload
      submissions = @a.submissions.not_placeholder
      expect(submissions.length).to eql 2
      expect(submissions.map(&:group_id).uniq).to eql [@group.id]
      expect(submissions.map(&:submission_type).uniq).to eql ["online_text_entry"]
      expect(submissions.map(&:body).uniq).to eql ["Test submission"]
    end

    it "should update submission for all students in the same group" do
      res = @a.grade_student(@u1, grade: "10", grader: @teacher)
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
      res = @a.grade_student(@u1, grade: "10", grader: @teacher)
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
      other_sub = (@a.submissions.not_placeholder - [sub])[0]
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

    it "hides grading comments for all group members if commenter is teacher and grades are hidden after commenting" do
      @a.update_submission(@u1, :comment => "woot", :group_comment => "1", author: @teacher)
      @a.mute!

      comments = @a.submissions.preload(:submission_comments).map(&:submission_comments).flatten
      expect(comments.map(&:hidden?)).to all(be true)
    end

    it "does not hide grading comments for all group members if commenter is student and assignment is muted after commenting" do
      @a.update_submission(@u1, :comment => "woot", :group_comment => "1", author: @u1)
      @a.mute!

      comments = @a.submissions.preload(:submission_comments).map(&:submission_comments).flatten
      expect(comments.map(&:hidden?)).to all(be false)
    end

    it "shows grading comments for all group members if commenter is teacher and assignment is unmuted" do
      @a.mute!
      @a.update_submission(@u1, :comment => "woot", :group_comment => "1", author: @teacher)
      @a.unmute!

      comments = @a.submissions.preload(:submission_comments).map(&:submission_comments).flatten
      expect(comments.map(&:hidden?)).to all(be false)
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
      @a.submissions.reload.not_placeholder.each { |s|
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
      a1 = ag.assignments.create!(:context => course_factory)
      expect(a1.locked_for?(@user)).to be_falsey

      m = @course.context_modules.create!
      ct = ContentTag.new
      ct.content_id = a1.id
      ct.content_type = 'Assignment'
      ct.context_id = course_factory.id
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
      a1 = wiki_page_assignment_model(:course => @course)
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
        :exclude_value => 'poiuopiuuiop',
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

    describe "newly-created comments" do
      before(:each) do
        @assignment = @course.assignments.create!(name: "Mute Comment Test", submission_types: %w(online_upload))
      end

      let(:zip) { zip_submissions_legacy }
      let(:added_comment) { @assignment.submission_for_student(@student).submission_comments.last }

      context "for a manually-posted assignment" do
        before(:each) do
          @assignment.post_policy.update!(post_manually: true)
        end

        it "hides new comments if the submission is not posted" do
          submit_homework(@student)

          @assignment.generate_comments_from_files_legacy(zip.open.path, @user)
          expect(added_comment).to be_hidden
        end

        it "shows new comments if the submission is posted" do
          submit_homework(@student)
          @assignment.post_submissions

          @assignment.generate_comments_from_files_legacy(zip.open.path, @user)
          expect(added_comment).not_to be_hidden
        end
      end

      context "for a automatically-posted assignment" do
        it "shows new comments if the submission is posted" do
          submit_homework(@student)
          @assignment.post_submissions

          @assignment.generate_comments_from_files_legacy(zip.open.path, @user)
          expect(added_comment).not_to be_hidden
        end

        it "hides new comments if the submission is graded but not posted" do
          submit_homework(@student)
          @assignment.grade_student(@student, grade: 1, grader: @teacher)
          @assignment.hide_submissions

          @assignment.generate_comments_from_files_legacy(zip.open.path, @user)
          expect(added_comment).to be_hidden
        end

        it "shows new comments if the submission is neither graded nor posted" do
          submit_homework(@student)

          @assignment.generate_comments_from_files_legacy(zip.open.path, @user)
          expect(added_comment).not_to be_hidden
        end
      end
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
      allow(PluginSetting).to receive(:settings_for_plugin).and_return(@att_map)
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
        @admin = account_admin_user()
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
      @quiz.due_at = 1.hour.ago
      @quiz.lock_at = 1.day.from_now
      @quiz.save!
      list = Assignment.not_locked.to_a
      expect(list.size).to be 1
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

  context "with_latest_due_date" do
    before :once do
      course_factory
      @s2 = @course.course_sections.create! name: 'other section'
      @dates = (0..7).map { |x| DateTime.new(2020, 1, 10 + x, 12, 0, 0) }
      @a1 = @course.assignments.create!(title: 'no due date')
      @a2 = @course.assignments.create!(title: 'no overrides', due_at: @dates[0])
      @a3 = @course.assignments.create!(title: 'latest is override', due_at: @dates[1])
      assignment_override_model(assignment: @a3, set: @course.default_section, due_at: @dates[2])
      @a4 = @course.assignments.create!(title: 'latest is base', due_at: @dates[4])
      assignment_override_model(assignment: @a4, set: @course.default_section, due_at: @dates[3])
      @a5 = @course.assignments.create!(title: 'two overrides', due_at: @dates[5])
      assignment_override_model(assignment: @a5, set: @course.default_section, due_at: @dates[4])
      assignment_override_model(assignment: @a5, set: @s2, due_at: @dates[6])
      @a6 = @course.assignments.create!(title: 'only overrides')
      assignment_override_model(assignment: @a6, set: @s2, due_at: @dates[6])
      assignment_override_model(assignment: @a6, set: @course.default_section, due_at: @dates[7])
    end

    it "returns the latest override in each circumstance" do
      assignments = @course.assignments.with_latest_due_date.reorder('latest_due_date').to_a
      expect(assignments.map { |a| [a.title, a.latest_due_date] }).to eq([
        ['no overrides', @dates[0]],
        ['latest is override', @dates[2]],
        ['latest is base', @dates[4]],
        ['two overrides', @dates[6]],
        ['only overrides', @dates[7]],
        ['no due date', nil]
      ])
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

    it "destroys the associated page if enabled" do
      course_factory
      @course.enable_feature!(:conditional_release)
      wiki_page_assignment_model course: @course
      @assignment.destroy
      expect(@page.reload).to be_deleted
      expect(@assignment.reload).to be_deleted
    end

    it "does not destroy the associated page" do
      wiki_page_assignment_model
      @assignment.destroy
      expect(@page.reload).not_to be_deleted
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
      expect_any_instance_of(Progress).to receive(:process_job)
        .with(@assignment.context, :refresh_content_participation_counts,
              singleton: "refresh_content_participation_counts:#{@assignment.context.global_id}")
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
    context "grade change events" do
      before(:once) do
        @assignment = @course.assignments.create!
        @assignment.grade_student(@student, grade: 5, grader: @teacher)
        @assistant = User.create!
        @course.enroll_ta(@assistant, enrollment_state: "active")
      end

      it "triggers a grade change event with the grader_id as the updating_user" do
        @assignment.updating_user = @assistant

        expect(Auditors::GradeChange).to receive(:record).once do |args|
          expect(args.fetch(:submission).grader_id).to eq @assistant.id
        end
        @assignment.update_student_submissions
      end

      it "triggers a grade change event using the grader_id on the submission if no updating_user is present" do
        expect(Auditors::GradeChange).to receive(:record).once do |args|
          expect(args.fetch(:submission).grader_id).to eq @teacher.id
        end

        @assignment.update_student_submissions
      end
    end

    context "pass/fail assignments" do
      before :once do
        @student1, @student2 = create_users_in_course(@course, 2, return_type: :record)
        @assignment = @course.assignments.create! grading_type: "pass_fail",
        points_possible: 5
        @sub1 = @assignment.grade_student(@student1, grade: "complete", grader: @teacher).first
        @sub2 = @assignment.grade_student(@student2, grade: "incomplete", grader: @teacher).first
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
        @assignment.grade_student(@user, grade: 'pass', grader: @teacher)
        @assignment.points_possible = 1.0
        @assignment.update_student_submissions

        submission.reload
        expect(submission.grade).to eql('complete')
      end

      it "changes the score of 'complete' pass/fail submissions to match the assignment's possible points" do
        @assignment.grade_student(@user, grade: 'pass', grader: @teacher)
        @assignment.points_possible = 3.0
        @assignment.update_student_submissions

        submission.reload
        expect(submission.score).to eql(3.0)
      end

      it "does not change the score of 'incomplete' pass/fail submissions if assignment points possible has changed" do
        @assignment.grade_student(@user, grade: 'fail', grader: @teacher)
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
      @assignment.grade_student(@user, grade: 1, grader: @teacher)
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
      @assignment.grade_student(@user, grade: 1, grader: @teacher)
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
      expect(DueDateCacher).to receive(:recompute).with(new_assignment, hash_including(update_grades: true))
      new_assignment.save
    end

    it "triggers when due_at changes" do
      expect(DueDateCacher).to receive(:recompute).with(@assignment, hash_including(update_grades: true))
      @assignment.due_at = 1.week.from_now
      @assignment.save
    end

    it "triggers when due_at changes to nil" do
      expect(DueDateCacher).to receive(:recompute).with(@assignment, hash_including(update_grades: true))
      @assignment.due_at = nil
      @assignment.save
    end

    it "triggers when assignment deleted" do
      expect(DueDateCacher).to receive(:recompute).with(@assignment, hash_including(update_grades: true))
      @assignment.destroy
    end

    it "does not trigger when nothing changed" do
      expect(DueDateCacher).to receive(:recompute).never
      @assignment.save
    end
  end

  describe "#title_slug" do
    before :once do
      @assignment = assignment_model(course: @course)
    end

    let(:errors) do
      @assignment.valid?
      @assignment.errors
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
      @assignment.title = 'a' * 256
      expect(errors[:title]).not_to be_empty
    end
  end

  describe "due_date" do
    let(:assignment) do
      @course.assignments.new(assignment_valid_attributes)
    end

    it "is valid when due_date_ok? is true" do
      allow(AssignmentUtil).to receive(:due_date_ok?).and_return(true)
      expect(assignment.valid?).to eq(true)
    end

    it "is not valid when due_date_ok? is false" do
      allow(AssignmentUtil).to receive(:due_date_ok?).and_return(false)
      expect(assignment.valid?).to eq(false)
    end
  end

  describe "validate_assignment_overrides_due_date" do
    let(:section_1) { @course.course_sections.create!(name: "section 1") }
    let(:section_2) { @course.course_sections.create!(name: "section 2") }

    let(:assignment) do
      @course.assignments.create!(assignment_valid_attributes)
    end

    describe "when an override has no due date" do
      before do
        # Create an override with a due date
        create_section_override_for_assignment(assignment, course_section: section_1)

        # Create an override without a due date
        override = create_section_override_for_assignment(assignment, course_section: section_2)
        override.due_at = nil
        override.save
      end

      it "is not valid when AssignmentUtil.due_date_required? is true" do
        allow(AssignmentUtil).to receive(:due_date_required?).and_return(true)
        expect(assignment.valid?).to eq(false)
      end

      it "is valid when AssignmentUtil.due_date_required? is false" do
        allow(AssignmentUtil).to receive(:due_date_required?).and_return(false)
        expect(assignment.valid?).to eq(true)
      end
    end

    describe "when all overrides have a due date" do
      before do
        # Create 2 overrides with due dates
        create_section_override_for_assignment(assignment, course_section: section_1)
        create_section_override_for_assignment(assignment, course_section: section_2)
      end

      it "is valid when AssignmentUtil.due_date_required? is true" do
        allow(AssignmentUtil).to receive(:due_date_required?).and_return(true)
        expect(assignment.valid?).to eq(true)
      end

      it "is valid when AssignmentUtil.due_date_required? is false" do
        allow(AssignmentUtil).to receive(:due_date_required?).and_return(false)
        expect(assignment.valid?).to eq(true)
      end
    end
  end

  describe "due_date_required?" do
    let(:assignment) do
      @course.assignments.create!(assignment_valid_attributes)
    end

    it "is true when due_date_required? is true" do
      allow(AssignmentUtil).to receive(:due_date_required?).and_return(true)
      expect(assignment.due_date_required?).to eq(true)
    end

    it "is false when due_date_required? is false" do
      allow(AssignmentUtil).to receive(:due_date_required?).and_return(false)
      expect(assignment.due_date_required?).to eq(false)
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

  describe '#generate_comments_from_files_legacy' do
    before :once do
      @students = create_users_in_course(@course, 3, return_type: :record)

      @assignment = @course.assignments.create! :name => "zip upload test",
                                                :submission_types => %w(online_upload)
    end

    it "should work for individuals" do
      s1 = @students.first
      submit_homework(s1)

      zip = zip_submissions_legacy

      comments, ignored = @assignment.generate_comments_from_files_legacy(
        zip.open.path,
        @teacher)

      expect(comments.map { |g| g.map { |c| c.submission.user } }).to eq [[s1]]
      expect(ignored).to be_empty
    end

    it "should work for groups" do
      s1, s2 = @students

      gc = @course.group_categories.create! name: "Homework Groups"
      @assignment.update group_category_id: gc.id,
                                    grade_group_students_individually: false
      g1, g2 = 2.times.map { |i| gc.groups.create! name: "Group #{i}", context: @course }
      g1.add_user(s1)
      g1.add_user(s2)

      submit_homework(s1)
      zip = zip_submissions_legacy

      comments, _ = @assignment.generate_comments_from_files_legacy(
        zip.open.path,
        @teacher)

      expect(comments.map { |g|
        g.map { |c| c.submission.user }.sort_by(&:id)
      }).to eq [[s1, s2]]
    end

    it "excludes student names from filenames when anonymous grading is enabled" do
      @assignment.update!(anonymous_grading: true)

      s1 = @students.first
      att = submit_homework(s1)
      sub = @assignment.submissions.where(:user_id => s1).first

      zip = zip_submissions_legacy
      filename = Zip::File.new(zip.open).entries.map(&:name).first
      expect(filename).to eq "anon_#{sub.anonymous_id}_#{att.id}_homework.pdf"

      comments, ignored = @assignment.generate_comments_from_files_legacy(
        zip.open.path,
        @teacher)

      expect(comments.map { |g| g.map { |c| c.submission.user } }).to eq [[s1]]
      expect(ignored).to be_empty
    end
  end

  describe "generating comments from files" do
    let(:attachment_data) { {uploaded_data: stub_file_data("submissions.zip", "", "application/zip")} }

    before :once do
      Account.site_admin.enable_feature!(:submissions_reupload_status_page)
      @students = create_users_in_course(@course, 3, return_type: :record)

      @assignment = @course.assignments.create! name: "zip upload test",
                                                submission_types: %w(online_upload)
    end

    def zip_submissions
      zip = Attachment.new filename: 'submissions.zip'
      zip.user = @teacher
      zip.workflow_state = 'to_be_zipped'
      zip.context = @assignment
      zip.save!

      # add all submissions from the assignment to the zip file
      ContentZipper.process_attachment(zip, @teacher)
      raise "zip failed" if zip.workflow_state != "zipped"

      # return a tempfile for use in generating comments
      zip.open
    end

    def generate_comments(user)
      tempfile = zip_submissions

      # create an uploaded file with the zipped submissions, as would be uploaded by the user
      uploaded_data = ActionDispatch::Http::UploadedFile.new(tempfile: tempfile, filename: "submissions.zip")

      @assignment.generate_comments_from_files_later(
        {uploaded_data: uploaded_data},
        user
      )

      # invoke the job that was created by the previous step
      job = Delayed::Job.where(tag: "Assignment#generate_comments_from_files").order(:id).last
      job.invoke_job
    end

    it "should work for individuals" do
      s1 = @students.first
      submit_homework(s1)

      generate_comments(@teacher)
      results = @assignment.submission_reupload_progress.results

      expect(results[:comments].map { |c| c[:submission][:user_id] }).to eq [s1.id]
      expect(results[:ignored_files]).to be_empty
    end

    it "should work for groups" do
      s1, s2 = @students

      gc = @course.group_categories.create! name: "Homework Groups"
      @assignment.update group_category_id: gc.id,
                                    grade_group_students_individually: false
      g1, g2 = 2.times.map { |i| gc.groups.create! name: "Group #{i}", context: @course }
      g1.add_user(s1)
      g1.add_user(s2)

      submit_homework(s1)

      generate_comments(@teacher)
      results = @assignment.submission_reupload_progress.results
      submission_user_ids = results[:comments].map { |c| c[:submission][:user_id] }

      expect(submission_user_ids.sort).to eq [s1.id, s2.id]
    end

    it "excludes student names from filenames when anonymous grading is enabled" do
      @assignment.update!(anonymous_grading: true)

      s1 = @students.first
      submit_homework(s1)

      generate_comments(@teacher)
      results = @assignment.submission_reupload_progress.results

      expect(results[:comments].map { |c| c[:submission][:user_id] }).to eq [s1.id]
      expect(results[:ignored_files]).to be_empty
    end

    describe "newly-created comments" do
      before(:each) do
        @assignment = @course.assignments.create!(name: "Mute Comment Test", submission_types: %w(online_upload))
      end

      let(:added_comment) { @assignment.submission_for_student(@student).submission_comments.last }

      context "for a manually-posted assignment" do
        before(:each) do
          @assignment.post_policy.update!(post_manually: true)
        end

        it "hides new comments if the submission is not posted" do
          submit_homework(@student)
          generate_comments(@user)
          expect(added_comment).to be_hidden
        end

        it "shows new comments if the submission is posted" do
          submit_homework(@student)
          @assignment.post_submissions

          generate_comments(@user)
          expect(added_comment).not_to be_hidden
        end
      end

      context "for a automatically-posted assignment" do
        it "shows new comments if the submission is posted" do
          submit_homework(@student)
          @assignment.post_submissions

          generate_comments(@user)
          expect(added_comment).not_to be_hidden
        end

        it "hides new comments if the submission is graded but not posted" do
          submit_homework(@student)
          @assignment.grade_student(@student, grade: 1, grader: @teacher)
          @assignment.hide_submissions

          generate_comments(@user)
          expect(added_comment).to be_hidden
        end

        it "shows new comments if the submission is neither graded nor posted" do
          submit_homework(@student)

          generate_comments(@user)
          expect(added_comment).not_to be_hidden
        end
      end
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
      expect_any_instance_of(Progress).to receive(:process_job)
        .with(assignment.context, :refresh_content_participation_counts,
              singleton: "refresh_content_participation_counts:#{assignment.context.global_id}").
          once
      assignment.restore
    end
  end

  describe '#readable_submission_type' do
    it "should work for on paper assignments" do
      assignment_model(:submission_types => 'on_paper', :course => @course)
      expect(@assignment.readable_submission_types).to eq 'on paper'
    end
  end

  describe '#update_grading_period_grades with no grading periods' do
    before :once do
      assignment_model(course: @course)
    end

    it 'should not update grades when due_at changes' do
      expect(@assignment.context).to receive(:recompute_student_scores).never
      @assignment.due_at = 6.months.ago
      @assignment.save!
    end
  end

  describe '#update_grading_period_grades' do
    before :once do
      assignment_model(course: @course)
      @grading_period_group = @course.root_account.grading_period_groups.create!(title: "Example Group")
      @grading_period_group.enrollment_terms << @course.enrollment_term
      @grading_period_group.grading_periods.create!(
        title: 'GP1',
        start_date: 9.months.ago,
        end_date: 5.months.ago
      )
      @grading_period_group.grading_periods.create!(
        title: 'GP2',
        start_date: 4.months.ago,
        end_date: 2.months.from_now
      )
      @course.enrollment_term.save!
      @assignment.reload
    end

    it 'should update grades when due_at changes to a grading period' do
      expect(@assignment.context).to receive(:recompute_student_scores).twice
      @assignment.due_at = 6.months.ago
      @assignment.save!
    end

    it 'should update grades twice when due_at changes to another grading period' do
      @assignment.due_at = 1.month.ago
      @assignment.save!
      expect(@assignment.context).to receive(:recompute_student_scores).twice
      @assignment.due_at = 6.months.ago
      @assignment.save!
    end

    it 'should not update grades if grading period did not change' do
      @assignment.due_at = 1.month.ago
      @assignment.save!
      expect(@assignment.context).to receive(:recompute_student_scores).never
      @assignment.due_at = 2.months.ago
      @assignment.save!
    end
  end

  describe '#update_submissions_and_grades_if_details_changed' do
    before :once do
      @assignment = @course.assignments.create! grading_type: "points", points_possible: 5
      student1, student2 = create_users_in_course(@course, 2, return_type: :record)
      @assignment.grade_student(student1, grade: 3, grader: @teacher).first
      @assignment.grade_student(student2, grade: 2, grader: @teacher).first
    end

    it "should update grades if points_possible changes" do
      expect(@assignment.context).to receive(:recompute_student_scores).once
      @assignment.points_possible = 3
      @assignment.save!
    end

    it "should update grades if workflow_state changes" do
      expect(@assignment.context).to receive(:recompute_student_scores).once
      @assignment.unpublish
    end

    it "updates when omit_from_final_grade changes" do
      expect(@assignment.context).to receive(:recompute_student_scores).once
      @assignment.update_attribute :omit_from_final_grade, true
    end

    it "updates when grading_type changes" do
      expect(@assignment.context).to receive(:recompute_student_scores).once
      @assignment.update_attribute :grading_type, "percent"
    end

    it "should not update grades otherwise" do
      expect(@assignment.context).to receive(:recompute_student_scores).never
      @assignment.title = 'hi'
      @assignment.due_at = 1.hour.ago
      @assignment.description = 'blah'
      @assignment.save!
    end
  end

  describe '#add_submission_comment' do
    let(:assignment) { assignment_model(course: @course) }

    it 'raises an error if original_student is nil' do
      expect {
        assignment.add_submission_comment(nil)
      }.to raise_error 'Student Required'
    end

    context 'when the student is not in a group' do
      let!(:associate_student_and_submission) {
        assignment.submissions.find_by user: @student
      }
      let(:update_submission_response) {
        assignment.add_submission_comment(@student, comment: 'WAT?')
      }

      it 'returns an Array' do
        expect(update_submission_response.class).to eq Array
      end

      it 'returns a collection of submission comments' do
        expect(update_submission_response.first.class).to eq SubmissionComment
      end
    end

    context 'when the student is in a group' do
      let!(:create_a_group_with_a_submitted_assignment) {
        setup_assignment_with_group
        @assignment.submit_homework(
          @u1,
          submission_type: 'online_text_entry',
          body: 'Some text for you'
        )
      }

      context 'when a comment is submitted' do
        let(:update_assignment_with_comment) {
          @assignment.add_submission_comment(
            @u2,
            comment: 'WAT?',
            group_comment: true,
            user_id: @course.teachers.first.id
          )
        }

        it 'returns an Array' do
          expect(update_assignment_with_comment).to be_an_instance_of Array
        end

        it 'creates a comment for each student in the group' do
          expect {
            update_assignment_with_comment
          }.to change{ SubmissionComment.count }.by(@u1.groups.first.users.count)
        end

        it 'creates comments with the same group_comment_id' do
          comments = update_assignment_with_comment
          expect(comments.first.group_comment_id).to eq comments.last.group_comment_id
        end
      end

      context 'when a comment is not submitted' do
        it 'returns an Array' do
          expect(@assignment.add_submission_comment(@u2).class).to eq Array
        end
      end
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
        assignment.submissions.find_by user: @student
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

  describe '#in_closed_grading_period?' do
    subject(:assignment) { @course.assignments.create! }

    context 'when there are no grading periods' do
      it { is_expected.not_to be_in_closed_grading_period }
    end

    context 'when there is a past and current grading period' do
      before(:once) do
        @old, @current = create_grading_periods_for(@course, grading_periods: [:old, :current])
      end

      context 'when there are no submissions in a closed grading period' do
        it { is_expected.not_to be_in_closed_grading_period }
      end

      context 'when there are at least one submission in a closed grading period' do
        before { assignment.update!(due_at: 3.months.ago) }

        it { is_expected.to be_in_closed_grading_period }

        context 'when a grading period is deleted for a submission' do
          before { @old.grading_period_group.destroy }
          it { is_expected.not_to be_in_closed_grading_period }
        end
      end

      context 'when a single submission is in a closed grading period via overrides' do
        let(:user) { student_in_course(active_all: true, user_name: 'another student').user }

        before { create_adhoc_override_for_assignment(assignment, user, due_at: 3.months.ago) }

        it { is_expected.to be_in_closed_grading_period }
      end

      context 'when there is a soft deleted closed grading period pointed at by concluded submissions' do
        before do
          # We need to set up a situation where a submission owned by
          # a concluded enrollment points at a soft deleted grading
          # period that would be considered closed.
          student_enrollment = student_in_course(course: assignment.context, active_all: true, user_name: 'another student')
          current_dup = @current.dup
          assignment.update(due_at: 45.days.ago(Time.zone.now))
          @current.update!(end_date: 1.month.ago(Time.zone.now))
          student_enrollment.conclude
          @current.destroy!
          current_dup.save!
        end

        context "without preloaded submissions" do
          it { is_expected.not_to be_in_closed_grading_period }
        end

        context "with preloaded submissions" do
          before { assignment.submissions.load }
          it { is_expected.not_to be_in_closed_grading_period }
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
        allow(assignment).to receive(:points_possible_changed?).and_return(false)
        assignment.valid?
        expect(assignment.errors.keys.include?(:points_possible)).to be_falsey
      end
    end
  end

  describe '#a2_enabled?' do
    before do
      allow(@course).to receive(:feature_enabled?) { false }
      allow(@course).to receive(:feature_enabled?).with(:assignments_2_student) { true }
    end

    let(:assignment) do
      @course.assignments.create!(assignment_valid_attributes)
    end

    it 'returns false if the assignment_2_student flag is not enabled' do
      allow(@course).to receive(:feature_enabled?).with(:assignments_2_student) { false }
      assignment.submission_types = 'online_text_entry'

      expect(assignment.a2_enabled?).to be(false)
    end

    [
      'discussion_topic',
      'external_tool',
      'on_paper',
      'online_quiz',
      'none',
      'not_graded',
      'wiki_page',
      ''
    ].each do |type|
      it "returns false if submission type is set to #{type}" do
        assignment.build_wiki_page
        assignment.build_discussion_topic
        assignment.build_quiz
        assignment.submission_types = type

        expect(assignment.a2_enabled?).to be(false)
      end
    end

    [
      'online_text_entry',
      'online_upload',
      'online_url'
    ].each do |type|
      it "returns true if the flag is on and the submission type is #{type}" do
        assignment.submission_types = type
        expect(assignment.a2_enabled?).to be(true)
      end
    end
  end

  describe 'title validation' do
    let(:assignment) do
      @course.assignments.create!(assignment_valid_attributes)
    end
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
      assignment.title = ''
      assignment.save(validate: false)

      assignment.valid?
      errors = assignment.errors
      expect(errors[:title]).to be_empty
    end

    it 'must not allow the title to be blank if changed' do
      assignment.title = ' '
      assignment.valid?
      errors = assignment.errors
      expect(errors[:title]).not_to be_empty
    end
  end

  describe "#ensure_post_to_sis_valid" do
    let(:assignment) { assignment_model(course: @course, post_to_sis: true) }

    it "sets post_to_sis to false if the assignment is not_graded" do
      assignment.submission_types = 'not_graded'
      assignment.save!

      expect(assignment.post_to_sis).to eq false
    end

    it "sets post_to_sis to false if the assignment is a wiki_page" do
      assignment.submission_types = 'wiki_page'
      assignment.save!

      expect(assignment.post_to_sis).to eq false
    end

    it "does not set post_to_sis to false for other assignments" do
      expect(assignment.post_to_sis).to eq true
    end
  end

  describe "validate_overrides_for_sis" do
    def api_create_assignment_in_course(course,assignment_params)
      api_call(:post,
               "/api/v1/courses/#{course.id}/assignments.json",
               {
                 :controller => 'assignments_api',
                 :action => 'create',
                 :format => 'json',
                 :course_id => course.id.to_s
               }, {:assignment => assignment_params })
    end

    let(:assignment) do
      @course.assignments.new(assignment_valid_attributes)
    end

    before do
      assignment.post_to_sis = true
      allow(assignment.context.account).to receive(:sis_syncing).and_return({value: true})
      allow(assignment.context.account).to receive(:feature_enabled?).with('new_sis_integrations').and_return(true)
      allow(assignment.context.account).to receive(:sis_require_assignment_due_date).and_return({value: true})
    end

    it "raises an invalid record error if overrides are invalid" do
      overrides = [{
          'course_section_id' => @course.default_section.id,
          'due_at' => nil
      }]
      expect{assignment.validate_overrides_for_sis(overrides)}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "when sis sync with required due dates is enabled" do
    before :each do
      @assignment = assignment_model(course: @course)
      @overrides = {
          :overrides_to_create=>[],
          :overrides_to_update=>[],
          :overrides_to_delete=>[],
          :override_errors=>[]
      }
      allow(AssignmentUtil).to receive(:due_date_required?).and_return(true)
      allow(AssignmentUtil).to receive(:due_date_required_for_account?).and_return(true)
      allow(AssignmentUtil).to receive(:sis_integration_settings_enabled?).and_return(true)
    end

    it "can duplicate" do
      create_section_override_for_assignment(@assignment)
      assignment_duplicate = @assignment.duplicate
      expect(assignment_duplicate.save).to eq(true)
    end

    context "checking if overrides are valid" do
      it "is valid if a new override has a due date" do
        override = assignment_override_model(assignment: @assignment, due_at: 2.days.from_now)
        @overrides[:overrides_to_create].push(override)
        expect{@assignment.validate_overrides_for_sis(@overrides)}.not_to raise_error
      end

      it "is valid if an override has a due date and everyone else does not have a due date" do
        @assignment.due_at = nil
        create_section_override_for_assignment(@assignment)
        expect{@assignment.validate_overrides_for_sis(@overrides)}.not_to raise_error
      end

      it "is invalid if a new override does not have a due date" do
        override = assignment_override_model(assignment: @assignment, due_at: nil, due_at_overridden: false)
        @overrides[:overrides_to_create].push(override)
        expect{@assignment.validate_overrides_for_sis(@overrides)}.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "is invalid if an active existing override does not have a due date" do
        create_section_override_for_assignment(@assignment, due_at: nil, due_at_overridden: false)
        expect{@assignment.validate_overrides_for_sis(@overrides)}.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "is valid if a deleted existing override does not have a due date" do
        create_section_override_for_assignment(@assignment, due_at: nil, due_at_overridden: false,
                                               workflow_state: 'deleted')
        expect{@assignment.validate_overrides_for_sis(@overrides)}.not_to raise_error
      end

      it "is invalid if updating an override to not set a due date" do
        db_override = create_section_override_for_assignment(@assignment)
        update_override = db_override.clone
        update_override[:id] = db_override[:id]
        update_override[:due_at] = nil
        @overrides[:overrides_to_update].push(update_override)
        expect{@assignment.validate_overrides_for_sis(@overrides)}.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "is valid if an existing override has no due date, but the update sets a due date" do
        db_override = assignment_override_model(assignment: @assignment, due_at: nil)
        update_override = db_override.clone
        update_override[:id] = db_override[:id]
        update_override[:due_at] = 2.days.from_now
        @overrides[:overrides_to_update].push(update_override)
        expect{@assignment.validate_overrides_for_sis(@overrides)}.not_to raise_error
      end
    end
  end

  describe "max_name_length" do
    let(:assignment) do
      @course.assignments.new(assignment_valid_attributes)
    end

    it "returns custom name length if sis_assignment_name_length_input is present" do
      assignment.post_to_sis = true
      allow(assignment.context.account).to receive(:sis_syncing).and_return({value: true})
      allow(assignment.context.account).to receive(:sis_assignment_name_length).and_return({value: true})
      allow(assignment.context.account).to receive(:feature_enabled?).with('new_sis_integrations').and_return(true)
      allow(assignment.context.account).to receive(:sis_assignment_name_length_input).and_return({value: 15})
      expect(assignment.max_name_length).to eq(15)
    end

    it "returns default of 255 if sis_assignment_name_length_input is not present " do
      expect(assignment.max_name_length).to eq(255)
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

    context 'when anonymous grading is enabled from before' do
      before :each do
        a1.group_category = nil
        a1.anonymous_grading = true
        a1.save!

        a1.group_category = @group_category
      end

      it 'invalidates the record' do
        expect(a1).not_to be_valid
      end

      it 'adds a validation error on the group category field' do
        a1.valid?

        expected_validation_error = "Anonymously graded assignments can't be group assignments"
        expect(a1.errors[:group_category_id]).to eq([expected_validation_error])
      end
    end
  end

  describe 'anonymous grading validation' do
    before :once do
      @group_category = @course.group_categories.create! name: "groups"
      @groups = Array.new(2) do |i|
        @group_category.groups.create! name: "group #{i}", context: @course
      end

      @assignment = @course.assignments.build(name: "Assignment")
      @assignment.save!
    end

    context 'when group_category is enabled from before' do
      before :each do
        @assignment.group_category = @group_category
        @assignment.save!

        @assignment.anonymous_grading = true
      end

      it 'invalidates the record' do
        expect(@assignment).not_to be_valid
      end

      it 'adds a validation error on the anonymous grading field' do
        @assignment.valid?

        expected_validation_error = "Group assignments can't be anonymously graded"
        expect(@assignment.errors[:anonymous_grading]).to eq([expected_validation_error])
      end
    end
  end

  describe 'group category and anonymous grading co-validation' do
    before :once do
      @group_category = @course.group_categories.create! name: "groups"
      @groups = Array.new(2) do |i|
        @group_category.groups.create! name: "group #{i}", context: @course
      end

      @assignment = @course.assignments.build(name: "Assignment")
      @assignment.save!

      @assignment.group_category = @group_category
      @assignment.anonymous_grading = true
    end

    it 'invalidates the record' do
      expect(@assignment).not_to be_valid
    end

    it 'adds a validation error on the base record' do
      @assignment.valid?

      expected_validation_error = "Can't enable anonymous grading and group assignments together"
      expect(@assignment.errors[:base]).to eq([expected_validation_error])
    end

    it 'does not add a validation error on the anonymous grading field' do
      @assignment.valid?

      expect(@assignment.errors[:anonymous_grading]).to be_empty
    end
  end

  describe "moderated_grading validation" do
    it "does not allow turning on if graded submissions exist" do
      assignment_model(course: @course)
      @assignment.grade_student @student, score: 0, grader: @teacher
      @assignment.moderated_grading = true
      @assignment.grader_count = 1
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning on if is also peer reviewed" do
      assignment_model(course: @course)
      @assignment.peer_reviews = true
      @assignment.moderated_grading = true
      @assignment.grader_count = 1
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning on if also a group assignment" do
      assignment_model(course: @course)
      @assignment.group_category = @course.group_categories.create!(name: "groups")
      @assignment.moderated_grading = true
      @assignment.grader_count = 1
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning off if graded submissions exist" do
      assignment_model(course: @course, moderated_grading: true, grader_count: 2, final_grader: @teacher)
      expect(@assignment).to be_moderated_grading
      @assignment.grade_student @student, score: 0, grader: @teacher
      @assignment.moderated_grading = false
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning off if provisional grades exist" do
      assignment_model(course: @course, moderated_grading: true, grader_count: 2)
      expect(@assignment).to be_moderated_grading
      submission = @assignment.submit_homework @student, body: "blah"
      submission.find_or_create_provisional_grade!(@teacher, score: 0)
      @assignment.moderated_grading = false
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow turning on for an ungraded assignment" do
      assignment_model(course: @course, submission_types: 'not_graded')
      @assignment.moderated_grading = true
      @assignment.grader_count = 1
      expect(@assignment.save).to eq false
      expect(@assignment.errors[:moderated_grading]).to be_present
    end

    it "does not allow creating a new ungraded assignment with moderated grading" do
      a = @course.assignments.build
      a.moderated_grading = true
      a.grader_count = 1
      a.submission_types = 'not_graded'
      expect(a).not_to be_valid
    end

  end

  describe "context_module_tag_info" do
    before(:once) do
      @assignment = @course.assignments.create!(:due_at => 1.week.ago,
                                               :points_possible => 100,
                                               :submission_types => 'online_text_entry')
    end

    it "returns past_due if an assignment is due in the past and no submission exists" do
      info = @assignment.context_module_tag_info(@student, @course, has_submission: false)
      expect(info[:past_due]).to be_truthy
    end

    it "does not return past_due for assignments that don't expect submissions" do
      @assignment.submission_types = ''
      @assignment.save!
      info = @assignment.context_module_tag_info(@student, @course, has_submission: false)
      expect(info[:past_due]).to be_falsey
    end

    it "does not return past_due for assignments that were turned in on time" do
      Timecop.freeze(2.weeks.ago) { @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'blah') }
      info = @assignment.context_module_tag_info(@student, @course, has_submission: true)
      expect(info[:past_due]).to be_falsey
    end

    it "does not return past_due for assignments that were turned in late" do
      @assignment.submit_homework(@student, :submission_type => 'online_text_entry', :body => 'blah')
      info = @assignment.context_module_tag_info(@student, @course, has_submission: true)
      expect(info[:past_due]).to be_falsey
    end
  end

  describe '#touch_submissions_if_muted' do
    before(:once) do
      @assignment = @course.assignments.create! points_possible: 10
      @submission = @assignment.submit_homework(@student, body: "hello")
      @assignment.ensure_post_policy(post_manually: true)
    end

    it "touches submissions if you mute the assignment" do
      @assignment.update!(muted: false)
      @submission_last_updated_at = @submission.reload.updated_at
      @assignment.mute!
      expect(@submission.reload.updated_at).to be > @submission_last_updated_at
    end

    context "calls assignment_muted_changed" do
      it "for graded submissions" do
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        @called = false
        allow_any_instance_of(Submission).to receive(:assignment_muted_changed) do
          @called = true
          expect(self.submission_model).to eq @submission
        end

        @assignment.unmute!
        expect(@called).to eq true
      end

      it "does not dispatch update for ungraded submissions" do
        expect_any_instance_of(Submission).to receive(:assignment_muted_changed).never
        @assignment.unmute!
      end
    end
  end

  describe '.remove_user_as_final_grader' do
    it 'calls .remove_user_as_final_grader_immediately in a delayed job' do
      expect(Assignment).to receive(:send_later_if_production_enqueue_args).
        with(:remove_user_as_final_grader_immediately, any_args)
      Assignment.remove_user_as_final_grader(@teacher.id, @course.id)
    end

    it 'runs the job in a strand, stranded by the root account ID' do
      delayed_job_args = {
        strand: "Assignment.remove_user_as_final_grader:#{@course.root_account.global_id}",
        max_attempts: 1,
        priority: Delayed::LOW_PRIORITY
      }

      expect(Assignment).to receive(:send_later_if_production_enqueue_args).
        with(:remove_user_as_final_grader_immediately, delayed_job_args, any_args)
      Assignment.remove_user_as_final_grader(@teacher.id, @course.id)
    end
  end

  describe '.remove_user_as_final_grader_immediately' do
    it 'removes the user as final grader in all assignments in the given course' do
      2.times { @course.assignments.create!(moderated_grading: true, grader_count: 2, final_grader: @teacher) }
      og_teacher = @teacher
      another_teacher = teacher_in_course(course: @course, active_all: true).user
      @course.enroll_teacher(another_teacher, active_all: true)
      @course.assignments.create!(moderated_grading: true, grader_count: 2, final_grader: another_teacher)
      expect { Assignment.remove_user_as_final_grader_immediately(og_teacher.id, @course.id) }.to change {
        @course.assignments.order(:created_at).pluck(:final_grader_id)
      }.from([og_teacher.id, og_teacher.id, another_teacher.id]).to([nil, nil, another_teacher.id])
    end

    it 'includes soft-deleted assignments when removing the user as final grader' do
      assignment = @course.assignments.create!(moderated_grading: true, grader_count: 2, final_grader: @teacher)
      assignment.destroy
      expect { Assignment.remove_user_as_final_grader_immediately(@teacher.id, @course.id) }.to change {
        assignment.reload.final_grader_id
      }.from(@teacher.id).to(nil)
    end
  end

  describe '.suspend_due_date_caching' do
    it 'suspends the update_cached_due_dates after_save callback on Assignment' do
      Assignment.suspend_due_date_caching do
        expect(Assignment.send(:suspended_callback?, :update_cached_due_dates, :save, :after)).to be true
      end
    end

    it 'suspends the update_cached_due_dates after_commit callback on AssignmentOverride' do
      Assignment.suspend_due_date_caching do
        expect(AssignmentOverride.send(:suspended_callback?, :update_cached_due_dates, :commit, :after)).to be true
      end
    end

    it 'suspends the update_cached_due_dates after_create callback on AssignmentOverrideStudent' do
      Assignment.suspend_due_date_caching do
        expect(AssignmentOverrideStudent.send(:suspended_callback?, :update_cached_due_dates, :create, :after)).to be true
      end
    end

    it 'suspends the update_cached_due_dates after_destroy callback on AssignmentOverrideStudent' do
      Assignment.suspend_due_date_caching do
        expect(AssignmentOverrideStudent.send(:suspended_callback?, :update_cached_due_dates, :destroy, :after)).to be true
      end
    end
  end

  describe '.with_student_submission_count' do
    require_relative '../sharding_spec_helper'
    specs_require_sharding

    it "doesn't reference multiple shards when accessed from a different shard" do
      @assignment = @course.assignments.create! points_possible: 10
      allow(Assignment.connection).to receive(:use_qualified_names?).and_return(true)
      @shard1.activate do
        allow(Assignment.connection).to receive(:use_qualified_names?).and_return(true)
        sql = @course.assignments.with_student_submission_count.to_sql
        expect(sql).to be_include(Shard.default.name)
        expect(sql).not_to be_include(@shard1.name)
      end
    end
  end

  describe '#lti_resource_link_id' do
    subject { assignment.lti_resource_link_id }

    context 'without external tool tag' do
      let(:assignment) do
        @course.assignments.create!(assignment_valid_attributes)
      end

      it { is_expected.to be_nil }
    end

    context 'with external tool tag' do
      let(:assignment) do
        @course.assignments.create!(submission_types: 'external_tool',
                                    external_tool_tag_attributes: { url: 'http://example.com/launch' },
                                    **assignment_valid_attributes)
      end

      it 'calls ContextExternalTool.opaque_identifier_for with the external tool tag and assignment shard' do
        lti_resource_link_id = SecureRandom.hex
        expect(ContextExternalTool).to receive(:opaque_identifier_for).with(
          assignment.external_tool_tag,
          assignment.shard
        ).and_return(lti_resource_link_id)
        expect(assignment.lti_resource_link_id).to eq(lti_resource_link_id)
      end
    end
  end

  describe '#available_moderators' do
    before(:once) do
      @course = Course.create!
      @first_teacher = User.create!
      @second_teacher = User.create!
      [@first_teacher, @second_teacher].each { |user| @course.enroll_teacher(user, enrollment_state: 'active') }
      @first_ta = User.create!
      @second_ta = User.create
      [@first_ta, @second_ta].each { |user| @course.enroll_ta(user, enrollment_state: 'active') }
      @assignment = @course.assignments.create!(
        final_grader: @first_teacher,
        grader_count: 2,
        moderated_grading: true
      )
    end

    it 'returns a list of active, available moderators in the course' do
      expected_moderator_ids = [@first_teacher, @second_teacher, @first_ta, @second_ta].map(&:id)
      expect(@assignment.available_moderators.map(&:id)).to match_array expected_moderator_ids
    end

    it 'excludes admins' do
      admin = account_admin_user
      expect(@course.moderators).not_to include admin
    end

    it 'excludes deactivated moderators in the course (see exception below)' do
      @course.enrollments.find_by(user: @second_teacher).deactivate
      expected_moderator_ids = [@first_teacher, @first_ta, @second_ta].map(&:id)
      expect(@assignment.available_moderators.map(&:id)).to match_array expected_moderator_ids
    end

    it 'excludes concluded moderators in the course (see exception below)' do
      @course.enrollments.find_by(user: @second_teacher).conclude
      expected_moderator_ids = [@first_teacher, @first_ta, @second_ta].map(&:id)
      expect(@assignment.available_moderators.map(&:id)).to match_array expected_moderator_ids
    end

    it 'excludes TAs if they do not have "Select Final Grade" permissions' do
      @course.root_account.role_overrides.create!(permission: 'select_final_grade', role: ta_role, enabled: false)
      expected_moderator_ids = [@first_teacher, @second_teacher].map(&:id)
      expect(@assignment.available_moderators.map(&:id)).to match_array expected_moderator_ids
    end

    it 'excludes teachers if they do not have "Select Final Grade" permissions' do
      @assignment.update!(final_grader: @first_ta)
      @course.root_account.role_overrides.create!(permission: 'select_final_grade', role: teacher_role, enabled: false)
      expected_moderator_ids = [@first_ta, @second_ta].map(&:id)
      expect(@assignment.available_moderators.map(&:id)).to match_array expected_moderator_ids
    end

    it 'includes an inactive user in the list if that user was picked as the final grader before being deactivated' do
      @course.enrollments.find_by(user: @first_teacher).deactivate
      expected_moderator_ids = [@first_teacher, @second_teacher, @first_ta, @second_ta].map(&:id)
      expect(@assignment.available_moderators.map(&:id)).to match_array expected_moderator_ids
    end

    it 'includes a concluded user in the list if that user was picked as the final grader before being concluded' do
      @course.enrollments.find_by(user: @first_teacher).conclude
      expected_moderator_ids = [@first_teacher, @second_teacher, @first_ta, @second_ta].map(&:id)
      expect(@assignment.available_moderators.map(&:id)).to match_array expected_moderator_ids
    end
  end

  describe '#moderated_grading_max_grader_count' do
    let_once(:course) { Course.create! }
    let_once(:teacher) { course.enroll_teacher(User.create!, enrollment_state: 'active').user }
    let_once(:assignment) {
      course.assignments.create!(
        final_grader: teacher,
        grader_count: 1,
        moderated_grading: true
      )
    }

    before(:once) do
      teacher2 = User.create!
      @teacher2_enrollment = course.enroll_teacher(teacher2, enrollment_state: 'active')
      course.enroll_teacher(User.create!, enrollment_state: 'active')
      assignment.update!(grader_count: 2)
    end

    it 'returns the number of active instructors minus one' do
      expect(assignment.moderated_grading_max_grader_count).to eq 2
    end

    it 'returns the number of active instructors minus one when a grader is deactivated' do
      @teacher2_enrollment.deactivate
      expect(assignment.moderated_grading_max_grader_count).to eq 1
    end

    it 'returns number of active instructors minus 1 when number of graders > available graders count' do
      assignment.update!(grader_count: 7)
      expect(assignment.moderated_grading_max_grader_count).to eq 2
    end

    it 'returns available graders count when number of graders is set to the max possible' do
      assignment.update!(grader_count: 9)
      course.enroll_teacher(User.create!, enrollment_state: 'active')
      course.enroll_teacher(User.create!, enrollment_state: 'active')
      expect(assignment.moderated_grading_max_grader_count).to eq 4
    end
  end

  describe '#moderated_grader_limit_reached?' do
    before(:once) do
      @course = Course.create!
      @teacher = User.create!
      second_teacher = User.create!
      @ta = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: :active)
      @course.enroll_teacher(second_teacher, enrollment_state: :active)
      @course.enroll_ta(@ta, enrollment_state: :active)
      @course.enroll_student(@student, enrollment_state: :active)
      @assignment = @course.assignments.create!(
        final_grader: @teacher,
        grader_count: 2,
        moderated_grading: true
      )
      @assignment.grade_student(@student, grader: second_teacher, provisional: true, score: 5)
    end

    it 'returns false if all provisional grader slots are not filled' do
      expect(@assignment.moderated_grader_limit_reached?).to eq false
    end

    it 'returns true if all provisional grader slots are filled' do
      @assignment.grade_student(@student, grader: @ta, provisional: true, score: 10)
      expect(@assignment.moderated_grader_limit_reached?).to eq true
    end

    it 'ignores grades issued by the final grader when determining if slots are filled' do
      @assignment.grade_student(@student, grader: @teacher, provisional: true, score: 10)
      expect(@assignment.moderated_grader_limit_reached?).to eq false
    end

    it 'returns false if moderated grading is off' do
      @assignment.grade_student(@student, grader: @ta, provisional: true, score: 10)
      @assignment.moderated_grading = false
      expect(@assignment.moderated_grader_limit_reached?).to eq false
    end
  end

  describe '#can_be_moderated_grader?' do
    before(:once) do
      @course = Course.create!
      @teacher = User.create!
      @second_teacher = User.create!
      @final_teacher = User.create!
      student = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: :active)
      @course.enroll_teacher(@second_teacher, enrollment_state: :active)
      @course.enroll_teacher(@final_teacher, enrollment_state: :active)
      @course.enroll_student(student, enrollment_state: :active)
      @assignment = @course.assignments.create!(
        final_grader: @final_teacher,
        grader_count: 2,
        moderated_grading: true,
        points_possible: 10
      )
      @assignment.grade_student(student, grader: @second_teacher, provisional: true, score: 10)
    end

    shared_examples 'grader permissions are checked' do
      it 'returns true when the user has default teacher permissions' do
        expect(@assignment.can_be_moderated_grader?(@teacher)).to be true
      end

      it 'returns true when the user has permission to only manage grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: true, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(@assignment.can_be_moderated_grader?(@teacher)).to be true
      end

      it 'returns true when the user has permission to only view all grades' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: true, role: teacher_role)
        expect(@assignment.can_be_moderated_grader?(@teacher)).to be true
      end

      it 'returns false when the user does not have sufficient privileges' do
        @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
        @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
        expect(@assignment.can_be_moderated_grader?(@teacher)).to be false
      end
    end

    context 'when the assignment is not moderated' do
      before :once do
        @assignment.update!(moderated_grading: false)
      end

      it_behaves_like 'grader permissions are checked'
    end

    context 'when the assignment is moderated' do
      it_behaves_like 'grader permissions are checked'

      context 'and moderator limit is reached' do
        before :once do
          @assignment.update!(grader_count: 1)
        end

        it 'returns false' do
          expect(@assignment.can_be_moderated_grader?(@teacher)).to be false
        end

        it 'returns true if user is one of the moderators' do
          expect(@assignment.can_be_moderated_grader?(@second_teacher)).to be true
        end

        it 'returns true if user is the final grader' do
          expect(@assignment.can_be_moderated_grader?(@final_teacher)).to be true
        end
      end
    end
  end

  describe '#user_is_moderation_grader?' do
    before(:once) do
      @course = Course.create!
      @teacher = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: :active)
      @assignment = @course.assignments.create!(moderated_grading: true, grader_count: 2)
    end

    it 'returns true if the user is a moderation grader occupying a grader slot' do
      @assignment.create_moderation_grader(@teacher, occupy_slot: true)
      expect(@assignment.user_is_moderation_grader?(@teacher)).to be true
    end

    it 'returns true if the user is a moderation grader not occupying a grader slot' do
      @assignment.create_moderation_grader(@teacher, occupy_slot: false)
      expect(@assignment.user_is_moderation_grader?(@teacher)).to be true
    end

    it 'returns false if the user is not a moderation grader' do
      expect(@assignment.user_is_moderation_grader?(@teacher)).to be false
    end
  end

  describe '#can_view_speed_grader?' do
    before :once do
      @course = Course.create!
      @teacher = User.create!
      @course.enroll_teacher(@teacher, enrollment_state: 'active')
      @assignment = @course.assignments.create!(
        final_grader: @teacher,
        grader_count: 2,
        moderated_grading: true
      )
    end

    it 'returns false when the course does not allow speed grader' do
      expect(@assignment.context).to receive(:allows_speed_grader?).and_return false
      expect(@assignment.can_view_speed_grader?(@teacher)).to be false
    end

    it 'returns false when the user cannot view or manage grades' do
      @course.root_account.role_overrides.create!(permission: 'manage_grades', enabled: false, role: teacher_role)
      @course.root_account.role_overrides.create!(permission: 'view_all_grades', enabled: false, role: teacher_role)
      expect(@assignment.context).to receive(:allows_speed_grader?).and_return true
      expect(@assignment.can_view_speed_grader?(@teacher)).to be false
    end

    it 'returns true when the course allows speed grader and user can manage grades' do
      expect(@assignment.context).to receive(:allows_speed_grader?).and_return true
      expect(@assignment.can_view_speed_grader?(@teacher)).to be true
    end
  end

  describe '#can_view_audit_trail?' do
    before :once do
      @admin = account_admin_user
      @assignment = @course.assignments.create!(
        final_grader: @teacher,
        grader_count: 2,
        grades_published_at: 2.days.ago,
        moderated_grading: true
      )
      @assignment.update!(muted: false)
    end

    it 'returns true for an auditor when the assignment is moderated, not muted, and grades have been posted' do
      expect(@assignment.can_view_audit_trail?(@admin)).to be true
    end

    it 'returns true for an auditor when the assignment is graded anonymously, not muted, and grades have been posted' do
      @assignment.update!(anonymous_grading: true, moderated_grading: false)
      @assignment.update!(muted: false)
      expect(@assignment.can_view_audit_trail?(@admin)).to be true
    end

    it "returns false when the user's role does not allow viewing the assignment audit trail" do
      @course.root_account.role_overrides.create!(enabled: false, permission: :view_audit_trail, role: admin_role)
      expect(@assignment.can_view_audit_trail?(@admin)).to be false
    end

    it 'returns false when the assignment is neither moderated nor anonymous' do
      @assignment.update!(moderated_grading: false)
      @assignment.update!(muted: false)
      expect(@assignment.can_view_audit_trail?(@admin)).to be false
    end

    it 'returns false when the assignment is muted' do
      @assignment.update!(muted: true)
      expect(@assignment.can_view_audit_trail?(@admin)).to be false
    end

    it 'returns false when the assignment grades have not been posted' do
      @assignment.update!(grades_published_at: nil)
      expect(@assignment.can_view_audit_trail?(@admin)).to be false
    end
  end

  describe '#auditable?' do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: 'hi') }
    let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: 'active').user }

    it 'is true if the assignment is anonymous' do
      assignment.update!(anonymous_grading: true, moderated_grading: false)
      expect(assignment).to be_auditable
    end

    it 'is true if the assignment is moderated' do
      assignment.update!(
        anonymous_grading: false,
        moderated_grading: true,
        grader_count: 1,
        final_grader: teacher
      )
      expect(assignment).to be_auditable
    end

    it "is true if an anonymous assignment just became non-anonymous" do
      assignment.update!(anonymous_grading: true)
      assignment.update!(anonymous_grading: false)
      expect(assignment).to be_auditable
    end

    it "is true if an anonymous assignment just became non-moderated" do
      assignment.update!(moderated_grading: true, grader_count: 1, final_grader: teacher)
      assignment.update!(moderated_grading: false)
      expect(assignment).to be_auditable
    end

    it 'is false if the assignment is neither anonymous nor moderated' do
      expect(assignment).not_to be_auditable
    end
  end

  describe "#effective_post_policy" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: 'hi') }

    it "returns the post policy for the course if the assignment has no policy attached" do
      assignment.post_policy.destroy
      expect(assignment.reload.effective_post_policy).to eq(course.default_post_policy)
    end

    it "returns the post policy for the assignment if present" do
      assignment.post_policy.update!(post_manually: false)

      expect(assignment.effective_post_policy).to eq(assignment.post_policy)
    end
  end

  describe "#post_manually?" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(title: 'hello') }

    context "when the assignment has a post policy" do
      it "returns true if the assignment's post policy has manual posting enabled" do
        assignment.post_policy.update!(post_manually: true)
        expect(assignment).to be_post_manually
      end

      it "returns false if the assignment's post policy has manual posting disabled" do
        assignment.post_policy.update!(post_manually: false)
        expect(assignment).not_to be_post_manually
      end
    end

    context "when the assignment has no post policy but the course does" do
      it "returns true if the course's post policy has manual posting enabled" do
        course.default_post_policy.update!(post_manually: true)
        assignment.post_policy.destroy
        expect(assignment.reload).to be_post_manually
      end

      it "returns false if the course's post policy has manual posting disabled" do
        course.default_post_policy.update!(post_manually: false)
        assignment.post_policy.destroy
        expect(assignment).not_to be_post_manually
      end
    end

    it "returns false if neither the assignment nor the course has a post policy attached" do
      course.default_post_policy.destroy
      assignment.post_policy.destroy
      expect(assignment).not_to be_post_manually
    end
  end

  describe "posting and unposting submissions" do
    let(:assignment) { @course.assignments.create!(title: 'hi') }

    let(:student1) { @course.enroll_student(User.create!, active_all: true).user }
    let(:student2) { @course.enroll_student(User.create!, active_all: true).user }
    let(:student1_submission) { assignment.submission_for_student(student1) }
    let(:student2_submission) { assignment.submission_for_student(student2) }

    let(:teacher) { @course.enroll_teacher(User.create!, active_all: true).user }

    before(:each) do
      student1
      student2
    end

    describe "#post_submissions" do
      it "updates the posted_at field of the specified submissions" do
        update_time = Time.zone.now
        Timecop.freeze(update_time) do
          assignment.post_submissions
        end

        expect(student1_submission.reload.posted_at).to eq(update_time)
      end

      it "does not update the posted_at field of submissions that were not specified" do
        assignment.post_submissions(submission_ids: [student1_submission.id])

        expect(student2_submission).not_to be_posted
      end

      it "reveals hidden comments on specified submissions" do
        comment = student1_submission.add_comment(author: teacher, hidden: true, comment: 'ok')
        assignment.post_submissions

        expect(comment.reload).not_to be_hidden
      end

      it "does not update the posted_at field if skip_updating_timestamp is passed" do
        expect {
          assignment.post_submissions(skip_updating_timestamp: true)
        }.not_to change {
          assignment.submission_for_student(student1).posted_at
        }
      end

      it "calls broadcast_notifications for submissions" do
        expect(Submission.broadcast_policy_list).to receive(:broadcast).with(student1_submission)
        assignment.post_submissions(submission_ids: [student1_submission.id])
      end

      describe "grade change audit records" do
        context "when assignment posts manually" do
          before(:once) do
            assignment.ensure_post_policy(post_manually: true)
          end

          it "inserts a single grade change record" do
            expect(Auditors::GradeChange::Stream).to receive(:insert).once
            assignment.grade_student(student1, grade: 10, grader: teacher)
          end

          it "does not insert a grade change record when posting" do
            expect(Auditors::GradeChange::Stream).not_to receive(:insert)
            assignment.post_submissions
          end

          it "does not insert a grade change record when hiding" do
            assignment.post_submissions
            expect(Auditors::GradeChange::Stream).not_to receive(:insert)
            assignment.hide_submissions
          end
        end

        context "when assignment posts automatically" do
          before(:once) do
            assignment.ensure_post_policy(post_manually: false)
          end

          it "inserts a single grade change record" do
            expect(Auditors::GradeChange::Stream).to receive(:insert).once
            assignment.grade_student(student1, grade: 10, grader: teacher)
          end
        end
      end

      describe "grade changed live events" do
        context "when assignment posts manually" do
          before(:each) do
            assignment.ensure_post_policy(post_manually: true)
          end

          it "emits an event when grading" do
            expect(Canvas::LiveEvents).to receive(:grade_changed).once
            assignment.grade_student(student1, grade: 10, grader: teacher)
          end

          it "emits an event when posting graded submissions" do
            assignment.grade_student(student1, grade: 10, grader: teacher)
            expect(Canvas::LiveEvents).to receive(:grade_changed).once
            assignment.post_submissions
          end

          it "emits an event when hiding graded submissions" do
            assignment.grade_student(student1, grade: 10, grader: teacher)
            assignment.post_submissions
            expect(Canvas::LiveEvents).to receive(:grade_changed).once
            assignment.hide_submissions
          end
        end

        context "when assignment posts automatically" do
          before(:each) do
            assignment.ensure_post_policy(post_manually: false)
          end

          it "emits two events when grading: one for grading and one for posting" do
            expect(Canvas::LiveEvents).to receive(:grade_changed).twice
            assignment.grade_student(student1, grade: 10, grader: teacher)
          end
        end
      end

      describe "Submissions Posted notification" do
        let_once(:notification) { Notification.find_or_create_by!(category: "Grading", name: "Submissions Posted") }
        let(:context) { { current_user: teacher } }
        let(:teacher_enrollment) { @course.teacher_enrollments.find_by!(user: teacher) }
        let(:section1) { @course.course_sections.create! }
        let(:submissions_posted_messages) do
          Message.where(
            notification: notification
          )
        end

        before(:each) do
          section1.enroll_user(student1, "StudentEnrollment", "active")
          student1.update!(email: "studentemail@example.com", workflow_state: :registered)
          student1.email_channel.update!(workflow_state: :active)
          teacher.update!(email: "teacheremail@example.com", workflow_state: :registered)
          teacher.email_channel.update!(workflow_state: :active)
          teacher_enrollment.update!(workflow_state: :active)
        end

        it "does not broadcast a notification when not including posting_params" do
          expect { assignment.post_submissions }.not_to change { submissions_posted_messages.count }
        end

        it "does not broadcast a notification for students" do
          expect {
            assignment.post_submissions(posting_params: { graded_only: false })
          }.not_to change {
            submissions_posted_messages.where(communication_channel: student1.communication_channels).count
          }
        end

        it "broadcasts a notification for teachers" do
          expect {
            assignment.post_submissions(posting_params: { graded_only: false })
          }.to change {
            submissions_posted_messages.where(communication_channel: teacher.communication_channels).count
          }.by(1)
        end

        it "broadcasts a notification when posting to everyone" do
          assignment.post_submissions(posting_params: { graded_only: false })
          body_text = "Grade changes and comments have been released for everyone."
          expect(submissions_posted_messages.order(:id).last.body).to include body_text
        end

        it "broadcasts a notification when posting to everyone graded" do
          assignment.grade_student(student1, grader: teacher, score: 1)
          assignment.post_submissions(posting_params: { graded_only: true })
          body_text = "Grade changes and comments have been released for everyone graded."
          expect(submissions_posted_messages.order(:id).last.body).to include body_text
        end

        it "broadcasts a notification when posting to everyone in sections" do
          assignment.post_submissions(posting_params: { graded_only: false, section_names: ["section 1"] })
          body_text = "Grade changes and comments have been released for everyone in sections: section 1."
          expect(submissions_posted_messages.order(:id).last.body).to include body_text
        end

        it "broadcasts a notification when posting to everyone graded in sections" do
          assignment.grade_student(student1, grader: teacher, score: 1)
          assignment.post_submissions(posting_params: { graded_only: true, section_names: ["section 1"] })
          body_text = "Grade changes and comments have been released for everyone graded in sections: section 1."
          expect(submissions_posted_messages.order(:id).last.body).to include body_text
        end
      end

      context "when given a Progress" do
        before(:each) do
          @progress = @course.progresses.create!(tag: "post_submissions")
        end

        it "sets the assignment id in the results" do
          assignment.post_submissions(progress: @progress, submission_ids: [student1_submission.id])
          expect(@progress.results[:assignment_id]).to eq assignment.id
        end

        it "sets the posted_at in the results" do
          assignment.post_submissions(progress: @progress, submission_ids: [student1_submission.id])
          expect(@progress.results[:posted_at]).to eq student1_submission.reload.posted_at
        end

        it "sets the user ids in the results" do
          assignment.post_submissions(progress: @progress, submission_ids: [student1_submission.id])
          expect(@progress.results[:user_ids]).to match_array [student1.id]
        end
      end

      context "when post policies are enabled" do
        it "unmutes the assignment if all submissions are now posted" do
          assignment.mute!

          assignment.post_submissions
          expect(assignment).not_to be_muted
        end

        it "leaves the assignment muted if some submissions remain unposted" do
          assignment.mute!

          assignment.post_submissions(submission_ids: [student1_submission.id])
          expect(assignment).to be_muted
        end

        it "recomputes grades for the affected students" do
          assignment.mute!

          expect(@course).to receive(:recompute_student_scores).with([student1.id])
          assignment.post_submissions(submission_ids: [student1_submission.id])
        end
      end

      describe "context module progressions" do
        let(:context_module) { @course.context_modules.create! }
        let(:student1) { @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
        let(:student2) { @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
        let(:tag) { context_module.add_item({id: assignment.id, type: "assignment"}) }

        before(:each) do
          context_module.update!(completion_requirements: {tag.id => {type: "min_score", min_score: 90}})
          # Have a manual post policy to stop the evaluation of the requirement
          # until post_submissions is called.
          assignment.ensure_post_policy(post_manually: true)
        end

        it "updates the met requirements" do
          assignment.grade_student(student1, grader: teacher, score: 100)
          assignment.post_submissions
          progression = context_module.context_module_progressions.find_by(user: student1)
          requirement = {id: tag.id, type: "min_score", min_score: 90.0}
          expect(progression.requirements_met).to include requirement
        end

        it "does not update the met requirements for students that did not meet requirement" do
          assignment.grade_student(student1, grader: teacher, score: 20)
          assignment.post_submissions
          progression = context_module.context_module_progressions.find_by(user: student1)
          requirement = {id: tag.id, type: "min_score", min_score: 90.0, score: 20.0}
          expect(progression.incomplete_requirements).to include requirement
        end

        it "does not update the met requirements for students not included" do
          assignment.grade_student(student1, grader: teacher, score: 100)
          assignment.grade_student(student2, grader: teacher, score: 100)
          student1_sub = assignment.submissions.find_by(user: student1)
          assignment.post_submissions(submission_ids: [student1_sub])
          progression = context_module.context_module_progressions.find_by(user: student2)
          requirement = {id: tag.id, type: "min_score", min_score: 90.0, score: nil}
          expect(progression.incomplete_requirements).to include requirement
        end
      end
    end

    describe "#hide_submissions" do
      before(:each) { assignment.post_submissions }

      it "nullifies the posted_at field of the specified submissions" do
        assignment.hide_submissions
        expect(student1_submission.reload.posted_at).to be_nil
      end

      it "does not nullify the posted_at field of submissions that were not specified" do
        expect {
          assignment.hide_submissions(submission_ids: [student1_submission.id])
        }.not_to change {
          student2_submission.posted_at
        }
      end

      it "hides instructor comments on specified submissions" do
        comment = student1_submission.add_comment(author: teacher, hidden: false, comment: 'ok')
        assignment.hide_submissions

        expect(comment.reload).to be_hidden
      end

      it "does not update the posted_at field if skip_updating_timestamp is passed" do
        student1_submission.update!(posted_at: 1.day.ago)

        expect {
          assignment.hide_submissions(skip_updating_timestamp: true)
        }.not_to change {
          assignment.submission_for_student(student1).posted_at
        }
      end

      context "when given a Progress" do
        before(:each) do
          @progress = @course.progresses.create!(tag: "hide_submissions")
        end

        it "sets the assignment id in the results" do
          assignment.hide_submissions(progress: @progress, submission_ids: [student1_submission.id])
          expect(@progress.results[:assignment_id]).to eq assignment.id
        end

        it "sets the posted_at to nil in the results" do
          assignment.hide_submissions(progress: @progress, submission_ids: [student1_submission.id])
          expect(@progress.results[:posted_at]).to be_nil
        end

        it "sets the user ids in the results" do
          assignment.hide_submissions(progress: @progress, submission_ids: [student1_submission.id])
          expect(@progress.results[:user_ids]).to match_array [student1.id]
        end
      end

      context "when post policies are enabled" do
        it "mutes the assignment if any submissions are now unposted" do
          assignment.hide_submissions
          expect(assignment).to be_muted
        end

        it "leaves the assignment unmuted if all submissions remain posted" do
          assignment.hide_submissions(submission_ids: [])
          expect(assignment).not_to be_muted
        end

        it "recomputes grades for the affected students" do
          expect(@course).to receive(:recompute_student_scores).with([student1.id])
          assignment.hide_submissions(submission_ids: [student1_submission.id])
        end
      end
    end
  end

  describe 'Anonymous Moderated Marking setting validation' do
    before(:once) do
      assignment_model(course: @course)
    end

    describe 'Moderated Grading validation' do
      context 'when moderated_grading is not enabled' do
        subject(:assignment) { @course.assignments.build }

        it { is_expected.to validate_absence_of(:grader_section) }
        it { is_expected.to validate_absence_of(:final_grader) }

        it 'before validation, sets final_grader_id to nil if it is present' do
          teacher = User.create!
          @course.enroll_teacher(teacher, active_all: true)
          assignment.final_grader_id = teacher.id
          assignment.validate
          expect(assignment.final_grader_id).to be_nil
        end

        it 'before validation, sets grader_count to 0 if it is present' do
          teacher = User.create!
          @course.enroll_teacher(teacher, active_all: true)
          assignment.grader_count = nil
          assignment.validate
          expect(assignment.grader_count).to be 0
        end
      end

      context 'when moderated_grading is enabled' do
        before(:each) do
          @section1 = @course.course_sections.first
          @section1_ta = ta_in_section(@section1)

          @section2 = @course.course_sections.create!(name: 'other section')
          @section2_ta = ta_in_section(@section2)

          @assignment.moderated_grading = true
          @assignment.grader_count = 1
          @assignment.final_grader = @section1_ta
        end

        let(:errors) { @assignment.errors }

        describe 'basic field validation' do
          subject { @course.assignments.create(moderated_grading: true, grader_count: 1, final_grader: @section1_ta) }

          it { is_expected.to be_muted }
          it { is_expected.to validate_numericality_of(:grader_count).is_greater_than(0) }
        end

        describe 'grader_section validation' do
          let(:error_message) { 'must be active and in same course as assignment' }

          it 'allows an active grader section from the course to be set' do
            @assignment.grader_section = @section1
            expect(@assignment).to be_valid
          end

          it 'does not allow a non-active grader section from the course' do
            @section2.destroy
            @assignment.grader_section = @section2
            @assignment.final_grader = @section2_ta
            @assignment.valid?

            expect(errors[:grader_section]).to eq [error_message]
          end

          it 'does not allow a grader section from a different course' do
            other_course = Course.create!(name: 'other course')
            @assignment.grader_section = other_course.course_sections.create!(name: 'other course section')
            @assignment.valid?

            expect(errors[:grader_section]).to eq [error_message]
          end
        end

        describe 'final_grader validation' do
          it 'allows a final grader from the selected grader section' do
            @assignment.grader_section = @section1
            @assignment.final_grader = @section1_ta

            expect(@assignment).to be_valid
          end

          it 'allows a final grader from the course if no section is set' do
            @assignment.final_grader = @section2_ta

            expect(@assignment).to be_valid
          end

          it 'does not allow a final grader from a different section' do
            @assignment.grader_section = @section1
            @assignment.final_grader = @section2_ta
            @assignment.valid?

            expect(errors[:final_grader]).to eq ['must be enrolled in selected section']
          end

          it 'does not allow a non-instructor final grader' do
            @assignment.final_grader = @initial_student
            @assignment.valid?

            expect(errors[:final_grader]).to eq ['must be an instructor in this course']
          end

          it 'does not allow changing final grader to an inactive user' do
            @section1_ta.enrollments.first.deactivate
            @assignment.final_grader = @section1_ta
            expect(@assignment).to be_invalid
          end

          it 'allows a non-active final grader if the final grader was set when the user was active' do
            @assignment.update!(final_grader: @section1_ta)
            @section1_ta.enrollments.first.deactivate
            expect(@assignment).to be_valid
          end

          it 'does not allow a final grader not in the course' do
            other_course = Course.create!(name: 'other course')
            other_course_ta = ta_in_course(course: other_course).user

            @assignment.final_grader = other_course_ta
            @assignment.valid?

            expect(errors[:final_grader]).to eq ['must be an instructor in this course']
          end
        end

        describe 'graders_anonymous_to_graders' do
          it 'cannot be set to true when grader_comments_visible_to_graders is false' do
            @assignment.update!(grader_comments_visible_to_graders: false, graders_anonymous_to_graders: true)
            expect(@assignment).not_to be_graders_anonymous_to_graders
          end

          it 'can be set to true when grader_comments_visible_to_graders is true' do
            @assignment.update!(grader_comments_visible_to_graders: true, graders_anonymous_to_graders: true)
            expect(@assignment).to be_graders_anonymous_to_graders
          end
        end
      end
    end
  end

  describe 'allowed_attempts validation' do
    before(:once) do
      assignment_model(course: @course)
    end

    it { is_expected.to validate_numericality_of(:allowed_attempts).allow_nil }

    it 'should allow -1' do
      @assignment.allowed_attempts = -1
      expect(@assignment).to be_valid
    end

    it 'should disallow 0' do
      @assignment.allowed_attempts = 0
      expect(@assignment).to_not be_valid
    end

    it 'should disallow values less than -1' do
      @assignment.allowed_attempts = -2
      expect(@assignment).to_not be_valid
    end

    it 'should allow values greater than 0' do
      @assignment.allowed_attempts = 2
      expect(@assignment).to be_valid
    end
  end

  describe "after create callbacks" do
    subject(:event) { AnonymousOrModerationEvent.where(assignment: assignment).last }

    let(:course) { @course }

    it "does not create an AnonymousOrModerationEvent when assignment is neither anonymous nor moderated" do
      expect{ course.assignments.create!(updating_user: @teacher) }.not_to change{ AnonymousOrModerationEvent.count }
    end

    it "does not create an AnonymousOrModerationEvent when assignment does not have an updating user" do
      expect{ course.assignments.create!(anonymous_grading: true) }.not_to change{ AnonymousOrModerationEvent.count }
    end

    context "for an anonymous assignment" do
      let(:assignment) do
        course.assignments.create!(anonymous_grading: true, updating_user: @teacher)
      end

      it "creates only one AnonymousOrModerationEvent on creation" do
        expect {
          course.assignments.create!(anonymous_grading: true, updating_user: @teacher)
        }.to change { AnonymousOrModerationEvent.count }.by(1)
      end

      it "creates an AnonymousOrModerationEvent with event_type assignment_created on assignment creation" do
        course.assignments.create!(anonymous_grading: true, updating_user: @teacher)
        expect(event.event_type).to eq "assignment_created"
      end

      describe "event payload" do
        subject { event.payload }

        it { is_expected.to include("anonymous_grading" => true) }
        it { is_expected.to include("anonymous_instructor_annotations" => false) }
        it { is_expected.to include("grader_comments_visible_to_graders" => true) }
        it { is_expected.to include("grader_count" => 0) }
        it { is_expected.to include("grader_names_visible_to_final_grader" => true) }
        it { is_expected.to include("graders_anonymous_to_graders" => false) }
        it { is_expected.to include("moderated_grading" => false) }
        it { is_expected.to include("muted" => true) }
        it { is_expected.to include("omit_from_final_grade" => false) }
      end
    end

    context "for a moderated assignment" do
      let(:assignment) do
        course.assignments.create!(params)
      end

      let(:params) { { moderated_grading: true, final_grader: @teacher, grader_count: 2, updating_user: @teacher } }

      it "creates exactly one AnonymousOrModerationEvent on creation " do
        expect {
          course.assignments.create!(params)
        }.to change { AnonymousOrModerationEvent.count }.by(1)
      end

      it "creates an AnonymousOrModerationEvent with event_type assignment_created on assignment creation" do
        course.assignments.create!(params)
        expect(event.event_type).to eq "assignment_created"
      end

      describe "event_payload" do
        subject { event.payload }

        it { is_expected.to include("anonymous_grading" => false) }
        it { is_expected.to include("anonymous_instructor_annotations" => false) }
        it { is_expected.to include("final_grader_id" => @teacher.id) }
        it { is_expected.to include("grader_comments_visible_to_graders" => true) }
        it { is_expected.to include("grader_count" => 2) }
        it { is_expected.to include("grader_names_visible_to_final_grader" => true) }
        it { is_expected.to include("graders_anonymous_to_graders" => false) }
        it { is_expected.to include("moderated_grading" => true) }
        it { is_expected.to include("muted" => true) }
        it { is_expected.to include("omit_from_final_grade" => false) }
      end
    end
  end

  describe 'after save callbacks' do
    let(:course) { @course }

    before(:once) { @ta = ta_in_course(course: @course, enrollment_state: :active).user }

    context "non-anonymous and non-moderated assignments" do
      let(:assignment) { course.assignments.create!(updating_user: @teacher) }

      context "when becoming an anonymous assignment" do
        subject do
          assignment.update!(anonymous_grading: true)
          AnonymousOrModerationEvent.where(assignment: assignment).last.payload
        end

        it { is_expected.to include("anonymous_grading" => [false, true]) }
        it { is_expected.to include("anonymous_instructor_annotations" => [false, false]) }
        it { is_expected.to include("grader_comments_visible_to_graders" => [true, true]) }
        it { is_expected.to include("grader_count" => [0, 0]) }
        it { is_expected.to include("grader_names_visible_to_final_grader" => [true, true]) }
        it { is_expected.to include("graders_anonymous_to_graders" => [false, false]) }
        it { is_expected.to include("moderated_grading" => [false, false]) }
        it { is_expected.to include("muted" => [true, true]) }
        it { is_expected.to include("omit_from_final_grade" => [false, false]) }
      end

      context "when becoming a moderated assignment" do
        subject(:payload) do
          assignment.update!(moderated_grading: true, grader_count: 1, final_grader: @ta)
          AnonymousOrModerationEvent.where(assignment: assignment).last.payload
        end

        it { is_expected.to include("anonymous_grading" => [false, false]) }
        it { is_expected.to include("anonymous_instructor_annotations" => [false, false]) }
        it { is_expected.to include("final_grader_id" => [nil, @ta.id]) }
        it { is_expected.to include("grader_comments_visible_to_graders" => [true, true]) }
        it { is_expected.to include("grader_count" => [0, 1]) }
        it { is_expected.to include("grader_names_visible_to_final_grader" => [true, true]) }
        it { is_expected.to include("graders_anonymous_to_graders" => [false, false]) }
        it { is_expected.to include("moderated_grading" => [false, true]) }
        it { is_expected.to include("muted" => [true, true]) }
        it { is_expected.to include("omit_from_final_grade" => [false, false]) }
      end
    end

    context 'given an anonymous assignment' do
      subject(:event) { AnonymousOrModerationEvent.where(assignment: assignment).last }

      let(:assignment) { course.assignments.create!(anonymous_grading: true, updating_user: @teacher) }

      describe 'create a grades_posted event' do
        context "when grades were posted" do
          let(:event_type) { :grades_posted }
          let(:now) { Time.zone.now }

          it "creates an AnonymousOrModerationEvent with an 'event_type' of 'grades_posted'" do
            expect { assignment.update!(grades_published_at: now) }.to change {
              AnonymousOrModerationEvent.where(assignment: assignment).count
            }.by(1)
          end

          it "sets the event user to the 'updating_user' on the assignment" do
            assignment.update!(grades_published_at: now, updating_user: @ta)
            expect(event).to have_attributes(user_id: @ta.id)
          end

          it "includes the 'grades_published_at' attribute in the event data" do
            assignment.update!(grades_published_at: now)
            expect(event.payload).to include('grades_published_at' => [nil, now.iso8601])
          end

          it "has no other values in the payload" do
            assignment.update!(grades_published_at: now)
            expect(event.payload.keys).to eq ['grades_published_at']
          end
        end
      end

      describe 'create an assignment_updated event' do
        let(:event_type) { :assignment_updated }

        it 'creates only one AnonymousOrModerationEvent on update' do
          assignment = course.assignments.create!(anonymous_grading: true, updating_user: @teacher)
          expect {
            assignment.update!(muted: false)
          }.to change { AnonymousOrModerationEvent.count }.by(1)
        end

        it 'creates an AnonymousOrModerationEvent with assignment changes when muted is changed' do
          assignment.update!(muted: false)
          expect(event.payload).to include('muted' => [true, false])
        end

        it 'creates an AnonymousOrModerationEvent with assignment changes when due_at is changed' do
          now = Time.zone.now
          assignment.update!(due_at: now)
          expect(event.payload).to include('due_at' => [nil, now.iso8601])
        end

        it 'creates an AnonymousOrModerationEvent with assignment changes when anonymous_grading is changed' do
          assignment.update!(anonymous_grading: false)
          expect(event.payload).to include('anonymous_grading' => [true, false])
        end

        it 'creates an AnonymousOrModerationEvent with assignment changes when omit_from_final_grade is changed' do
          assignment.update!(omit_from_final_grade: true)
          expect(event.payload).to include('omit_from_final_grade' => [false, true])
        end

        it 'creates an AnonymousOrModerationEvent with assignment changes when anonymous_instructor_annotations is changed' do
          assignment.update!(anonymous_instructor_annotations: true)
          expect(event.payload).to include('anonymous_instructor_annotations' => [false, true])
        end

        it "does not create an AnonymousOrModerationEvent when non-grading-related attributes are updated" do
          expect { assignment.update!(title: "Different Name") }.not_to change {
            AnonymousOrModerationEvent.where(assignment: assignment).count
          }
        end
      end
    end

    context 'given a moderated assignment' do
      subject(:event) { AnonymousOrModerationEvent.where(assignment: assignment).last }

      let(:event_type) { :assignment_updated }
      let(:assignment) { course.assignments.create!(params) }
      let(:params) {
        {
          moderated_grading: true,
          final_grader: @teacher,
          grader_count: 2,
          updating_user: @teacher
        }
      }

      it 'creates only one AnonymousOrModerationEvent on update' do
        assignment = course.assignments.create!(params)
        expect {
          assignment.update!(muted: false)
        }.to change { AnonymousOrModerationEvent.count }.by(1)
      end

      it "creates an AnonymousOrModerationEvent with event_type assignment_updated on assignment update" do
        assignment.update!(points_possible: 23)
        expect(event.event_type).to eq "assignment_updated"
      end

      it 'creates an AnonymousOrModerationEvent with assignment changes when points_possible is changed' do
        assignment.update!(points_possible: 23)
        expect(event.payload).to include('points_possible' => [nil, 23.0])
      end

      it 'creates an AnonymousOrModerationEvent with assignment changes when moderated_grading is changed' do
        assignment.update!(moderated_grading: false)
        expect(event.payload).to include('moderated_grading' => [true, false])
      end

      it 'creates an AnonymousOrModerationEvent with assignment changes when final_grader_id is changed' do
        assignment.update!(final_grader: @ta)
        expect(event.payload).to include('final_grader_id' => [@teacher.id, @ta.id])
      end

      it 'creates an AnonymousOrModerationEvent with assignment changes when grader_count is changed' do
        assignment.update!(grader_count: 70)
        expect(event.payload).to include('grader_count' => [2, 70])
      end

      it 'creates an AnonymousOrModerationEvent with assignment changes when grader_names_visible_to_final_grader is changed' do
        assignment.update!(grader_names_visible_to_final_grader: false)
        expect(event.payload).to include('grader_names_visible_to_final_grader' => [true, false])
      end

      it 'creates an AnonymousOrModerationEvent with assignment changes when grader_comments_visible_to_graders is changed' do
        assignment.update!(grader_comments_visible_to_graders: false)
        expect(event.payload).to include('grader_comments_visible_to_graders' => [true, false])
      end

      it 'creates an AnonymousOrModerationEvent with assignment changes when graders_anonymous_to_graders is changed' do
        assignment.update!(graders_anonymous_to_graders: true)
        expect(event.payload).to include('graders_anonymous_to_graders' => [false, true])
      end
    end

    describe '#update_line_items' do
      let(:use_1_3) { true }
      let(:dev_key) { DeveloperKey.create! }
      let(:tool) do
        course.context_external_tools.create!(
          consumer_key: 'key',
          shared_secret: 'secret',
          name: 'test tool',
          url: 'http://www.tool.com/launch',
          settings: { use_1_3: use_1_3 },
          workflow_state: 'public',
          developer_key: dev_key
        )
      end
      let(:assignment) do
        @course.assignments.create!(submission_types: 'external_tool',
                                    external_tool_tag_attributes: { content: tool },
                                    **assignment_valid_attributes)
      end

      shared_examples 'line item and resource link existence check' do
        it 'has a line item and a resource link referencing the currently bound tool' do
          expect(assignment.line_items.length).to eq 1
          expect(assignment.line_items.first.label).to eq assignment.title
          expect(assignment.line_items.first.score_maximum).to eq assignment.points_possible
          expect(assignment.line_items.first.resource_link).not_to be_nil
          expect(assignment.line_items.first.resource_link.resource_link_id).to eq assignment.lti_context_id
          expect(assignment.line_items.first.resource_link.current_external_tool(assignment.context)).to eq tool
          expect(assignment.external_tool_tag.content).to eq tool
          expect(assignment.line_items.first.resource_link.line_items.first).to eq assignment.line_items.first
        end
      end

      shared_examples 'assignment to line item attribute sync check' do
        it 'synchronizes assignment title and points_possible changes to the primary line item' do
          # create a secondary line item (i.e. one that should not be synchronized)
          previous_title = assignment.title
          previous_points_possible = assignment.points_possible
          first_line_item = assignment.line_items.first
          line_item_two = assignment.line_items.create!(
            label: previous_title,
            score_maximum: previous_points_possible,
            resource_link: first_line_item.resource_link
          )
          line_item_two.update!(created_at: first_line_item.created_at + 1.minute)
          assignment.title += " edit"
          assignment.points_possible += 10
          assignment.save!
          assignment.reload
          expect(assignment.line_items.length).to eq 2
          expect(assignment.line_items.find(&:assignment_line_item?).label).to eq assignment.title
          expect(assignment.line_items.find(&:assignment_line_item?).score_maximum).to eq assignment.points_possible
          expect(assignment.line_items.find { |li| !li.assignment_line_item? }.label).to eq previous_title
          expect(assignment.line_items.find { |li| !li.assignment_line_item? }.score_maximum).to eq previous_points_possible
        end
      end

      context 'given an assignment bound to a LTI 1.3 tool' do

        it_behaves_like 'line item and resource link existence check'
        it_behaves_like 'assignment to line item attribute sync check'

        context 'and no resource link or line item exist' do
          let(:resource_link) { subject.line_items.first.resource_link }
          let(:line_item) { subject.line_items.first }

          before do
            resource_link
            line_item
            subject.line_items.destroy_all
            resource_link.destroy!
            subject.update!(lti_context_id: SecureRandom.uuid)
            subject.create_assignment_line_item!
          end

          describe '#create_assignment_line_item!' do
            subject { assignment }

            it 'sets a line item' do
              expect(subject.line_items.active.count).to eq 1
            end

            it 'creates a new assignment line item' do
              expect(subject.line_items.first).not_to eq line_item
            end

            it 'sets a resource link' do
              expect(subject.line_items.first.resource_link).to be_present
            end

            it 'creates a new resource link' do
              expect(subject.line_items.first.resource_link).not_to eq resource_link
            end
          end
        end

        context 'and resource link and line item exist' do
          let(:resource_link) { subject.line_items.first.resource_link }
          let(:line_item) { subject.line_items.first }

          describe '#create_assignment_line_item!' do
            subject { assignment }

            before { subject.create_assignment_line_item! }

            it 'does not add a new line item' do
              expect(subject.line_items.count).to eq 1
            end

            it 'does not replace the existing line item' do
              expect(subject.line_items.first).to eq line_item
            end

            it 'does not replace the existing resource link' do
              expect(subject.line_items.first.resource_link).to eq resource_link
            end
          end
        end

        context 'and the tool binding is changed' do
          let(:different_tool_use_1_3) { true }
          let!(:different_tool) do
            course.context_external_tools.create!(
              consumer_key: 'key2',
              shared_secret: 'secret2',
              name: 'test tool 2',
              url: 'http://www.tool2.com/launch',
              settings: { use_1_3: different_tool_use_1_3 },
              workflow_state: 'public'
            )
          end

          before(:each) do
            assignment.update!(external_tool_tag_attributes: { content: different_tool })
            assignment.reload
          end

          shared_examples 'unchanged line item and resource link check' do
            it 'does not change nor add to the line item nor resource link' do
              expect(assignment.line_items.length).to eq 1
              expect(assignment.line_items.first.resource_link.current_external_tool(assignment.context)).to eq tool
              # some sanity checks to make sure the update did what we thought it did
              expect(different_tool.id).not_to eq tool.id
              expect(assignment.external_tool_tag.content.id).to eq different_tool.id
            end
          end

          # rubocop:disable RSpec/NestedGroups
          context 'to a different LTI 1.3 tool' do
            it_behaves_like 'unchanged line item and resource link check'
            it_behaves_like 'assignment to line item attribute sync check'
          end

          context 'to a different non-LTI 1.3 tool' do
            let(:different_tool_use_1_3) { false }

            it_behaves_like 'unchanged line item and resource link check'
            it_behaves_like 'assignment to line item attribute sync check'
          end
          # rubocop:enable RSpec/NestedGroups
        end

        context 'and the tool binding is abandoned' do
          it 'does not delete the line item nor resource link' do
            assignment.update!(submission_types: 'none')
            assignment.reload
            expect(assignment.line_items.length).to eq 1
            expect(assignment.line_items.first.resource_link.current_external_tool(assignment.context)).to eq tool
          end

          it_behaves_like 'assignment to line item attribute sync check'
        end
      end

      context 'given an assignment bound to a non-LTI 1.3 tool' do
        let(:use_1_3) { false }

        it 'does not create line items and resource links' do
          expect(assignment.line_items).to be_empty
        end

        describe "#create_assignment_line_items!" do
          subject { assignment }

          it 'does not create a new line item' do
            expect do
              subject.create_assignment_line_item!
            end.not_to change { Lti::LineItem.count }
          end

          it 'does not associate a line item with the assignment' do
            expect(subject.line_items).to be_empty
          end

          it 'does not create a new resource link' do
            expect do
              subject.create_assignment_line_item!
            end.not_to change { Lti::ResourceLink.count }
          end
        end
      end

      context 'given an assignment not yet bound to a LTI 1.3 tool' do
        let(:assignment) do
          @course.assignments.create!(submission_types: 'external_tool',
                                      **assignment_valid_attributes)
        end

        it 'initially has no line items nor resource links' do
          expect(assignment.line_items).to be_empty
        end

        context 'but when a LTI 1.3 tool is subsequently added' do
          before do
            assignment.update!(external_tool_tag_attributes: { content: tool })
          end

          it_behaves_like 'line item and resource link existence check'
        end
      end
    end
  end

  describe 'sis_source_id' do
    it 'is unique' do
      Assignment.create!(course: @course, name: 'some assignment', sis_source_id: 'BLAH')
      expect {
        Assignment.create!(course: @course, name: 'some assignment', sis_source_id: 'BLAH')
      }.to raise_error(ActiveRecord::RecordNotUnique)
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
    @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
    @assignment.reload
  end

  def setup_assignment_with_students
    @graded_notify = Notification.create!(:name => "Submission Graded")
    @grade_change_notify = Notification.create!(:name => "Submission Grade Changed")
    @stu1 = @student
    communication_channel(@stu1, active_cc: true)
    @course.enroll_student(@stu2 = user_factory(active_user: true, active_cc: true))
    @assignment = @course.assignments.create(:title => "a title", :points_possible => 10)

    [@stu1, @stu2].each do |stu|
      [@graded_notify, @grade_change_notify].each do |notification|
        notification_policy_model(
          notification: notification,
          communication_channel: stu.communication_channels.first
        )
      end
    end

    @sub1 = @assignment.grade_student(@stu1, grade: 9, grader: @teacher).first
    @assignment.reload
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

  def zip_submissions_legacy
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

  describe Assignment::MaxGradersReachedError do
    subject { Assignment::MaxGradersReachedError.new }

    it { is_expected.to be_a Assignment::GradeError }

    it 'has an error_code of MAX_GRADERS_REACHED' do
      expect(subject.error_code).to eq 'MAX_GRADERS_REACHED'
    end
  end
end
