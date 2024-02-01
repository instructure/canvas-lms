# frozen_string_literal: true

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

require "lti2_course_spec_helper"
require_relative "../helpers/k5_common"

describe Course do
  include K5Common

  context "with basic course" do
    before :once do
      Account.default
      Account.default.default_enrollment_term
    end

    before do
      @course = Account.default.courses.build
      @course.workflow_state = "claimed"
      @course.root_account = Account.default
      @course.enrollment_term = Account.default.default_enrollment_term
    end

    context "outcome imports" do
      include_examples "outcome import context examples"

      describe "relationships" do
        it { is_expected.to have_one(:late_policy).dependent(:destroy).inverse_of(:course) }
        it { is_expected.to have_one(:default_post_policy).inverse_of(:course) }

        it { is_expected.to have_many(:post_policies).dependent(:destroy).inverse_of(:course) }
        it { is_expected.to have_many(:assignment_post_policies).inverse_of(:course) }
        it { is_expected.to have_many(:feature_flags) }
        it { is_expected.to have_many(:lti_resource_links).class_name("Lti::ResourceLink") }
      end

      describe "lti2 proxies" do
        include_context "lti2_course_spec_helper"

        it "has many tool proxies" do
          tool_proxy # need to do this so that the tool_proxy is instantiated
          expect(course.tool_proxies.size).to eq 1
        end
      end

      it_behaves_like "a learning outcome context"
    end

    it "re-runs SubmissionLifecycleManager if enrollment term changes" do
      @course.save!
      @course.enrollment_term = EnrollmentTerm.create!(root_account: Account.default, workflow_state: :active)
      expect(SubmissionLifecycleManager).to receive(:recompute_course).with(@course)
      @course.save!
    end

    it "recalculates grades if enrollment term changes" do
      @course.save!
      teacher = User.create!
      @course.enroll_teacher(teacher, enrollment_state: "active")
      student = User.create!
      student_enrollment = @course.enroll_student(student, enrollment_state: "active")
      now = Time.zone.now
      first_period_assignment = @course.assignments.create!(
        due_at: 1.day.from_now(now),
        points_possible: 10,
        submission_types: "online_text_entry"
      )
      first_period_assignment.grade_student(student, grade: 10, grader: teacher)
      second_period_assignment = @course.assignments.create!(
        due_at: 25.days.from_now(now),
        points_possible: 10,
        submission_types: "online_text_entry"
      )
      second_period_assignment.grade_student(student, grade: 8, grader: teacher)
      new_term = EnrollmentTerm.create!(root_account: @course.root_account, workflow_state: "active")
      grading_period_set = @course.root_account.grading_period_groups.create!(weighted: true)
      grading_period_set.enrollment_terms << new_term
      grading_period_set.grading_periods.create!(
        title: "A Grading Period",
        start_date: 10.days.ago(now),
        end_date: 10.days.from_now(now),
        weight: 60
      )
      grading_period_set.grading_periods.create!(
        title: "Another Grading Period",
        start_date: 20.days.from_now(now),
        end_date: 30.days.from_now(now),
        weight: 40
      )
      score = student_enrollment.scores.find_by(course_score: true)
      expect { @course.update!(enrollment_term: new_term) }.to change {
        score.reload.current_score
      }.from(90).to(92)
    end

    it "does not re-run SubmissionLifecycleManager if enrollment term does not change" do
      @course.save!
      expect(SubmissionLifecycleManager).not_to receive(:recompute_course)
      @course.save!
    end

    it "identifies a course as active correctly" do
      @course.enrollment_term = EnrollmentTerm.create!(root_account: Account.default, workflow_state: :active)
      expect(@course.inactive?).to be false
    end

    it "identifies a destroyed course as not active" do
      @course.enrollment_term = EnrollmentTerm.create!(root_account: Account.default, workflow_state: :active)
      @course.destroy!
      expect(@course.inactive?).to be true
    end

    it "identifies concluded course as not active" do
      @course.complete!
      expect(@course.inactive?).to be true
    end

    describe "#assigned_assignment_ids_by_user" do
      before do
        @course.save!
        @student = User.create!
        @course.enroll_student(@student, enrollment_state: "active")
        @another_student = User.create!
        @course.enroll_student(@another_student, enrollment_state: "active")
        @assignment = @course.assignments.create!(title: "assigned to everyone")
        @override_assignment = @course.assignments.create!(title: "assigned to one student", only_visible_to_overrides: true)
        create_adhoc_override_for_assignment(@override_assignment, @another_student)
      end

      it "returns a hash with student IDs for keys and a set of assigned assignment IDs for values" do
        expect(@course.assigned_assignment_ids_by_user).to include(
          @student.id => Set[@assignment.id],
          @another_student.id => Set[@assignment.id, @override_assignment.id]
        )
      end

      it "excludes soft-deleted assignments" do
        @assignment.destroy

        aggregate_failures do
          expect(@course.assigned_assignment_ids_by_user).to include(
            @another_student.id => Set[@override_assignment.id]
          )
          expect(@course.assigned_assignment_ids_by_user).not_to include(
            @student.id
          )
        end
      end
    end

    describe "#grading_standard_or_default" do
      it "returns the grading scheme being used by the course, if one exists" do
        @course.save!
        standard = grading_standard_for(@course)
        @course.update!(grading_standard: standard)
        expect(@course.grading_standard_or_default).to be standard
      end

      it "returns the Canvas default grading scheme if the course is not using a grading scheme" do
        expect(@course.grading_standard_or_default.data).to eq GradingStandard.default_grading_standard
      end
    end

    describe "#moderated_grading_max_grader_count" do
      before(:once) do
        @course = Course.create!
      end

      it "returns 1 if the course has no instructors" do
        expect(@course.moderated_grading_max_grader_count).to eq 1
      end

      it "returns 1 if the course has one instructor" do
        teacher = User.create!
        @course.enroll_teacher(teacher)
        expect(@course.moderated_grading_max_grader_count).to eq 1
      end

      it "returns 10 if the course has more than 11 instructors" do
        create_users_in_course(@course, 6, enrollment_type: "TeacherEnrollment")
        create_users_in_course(@course, 6, enrollment_type: "TaEnrollment")
        expect(@course.moderated_grading_max_grader_count).to eq 10
      end

      it "returns N-1 if the course has between 1 < N < 12 instructors" do
        create_users_in_course(@course, 2, enrollment_type: "TeacherEnrollment")
        @course.enroll_ta(User.create!, enrollment_state: "active")
        expect { @course.enroll_ta(User.create!, enrollment_state: "active") }.to change {
          @course.moderated_grading_max_grader_count
        }.from(2).to(3)
      end

      it "ignores deactivated instructors" do
        create_users_in_course(@course, 2, enrollment_type: "TeacherEnrollment")
        @course.enroll_ta(User.create!, enrollment_state: "active").deactivate
        expect(@course.moderated_grading_max_grader_count).to eq 1
      end

      it "ignores concluded instructors" do
        create_users_in_course(@course, 2, enrollment_type: "TeacherEnrollment")
        @course.enroll_ta(User.create!, enrollment_state: "active").conclude
        expect(@course.moderated_grading_max_grader_count).to eq 1
      end

      it "ignores deleted instructors" do
        create_users_in_course(@course, 2, enrollment_type: "TeacherEnrollment")
        @course.enroll_ta(User.create!, enrollment_state: "active").destroy
        expect(@course.moderated_grading_max_grader_count).to eq 1
      end

      it "ignores non-instructors" do
        create_users_in_course(@course, 2, enrollment_type: "TeacherEnrollment")
        @course.enroll_student(User.create!, enrollment_state: "active")
        expect(@course.moderated_grading_max_grader_count).to eq 1
      end
    end

    describe "#membership_for_user" do
      it "returns active enrollments" do
        course = Course.create!(name: "the best")
        user = User.create!(name: "the best")
        course.enroll_teacher(user, enrollment_state: :completed)
        course.enroll_student(user, enrollment_state: :active)
        expect(course.membership_for_user(user).active?).to be true
      end
    end

    describe "#moderators" do
      before(:once) do
        @course = Course.create!
        @teacher = User.create!
        @course.enroll_teacher(@teacher, enrollment_state: :active)
        @ta = User.create!
        @course.enroll_ta(@ta, enrollment_state: :active)
      end

      it "includes active teachers" do
        expect(@course.moderators).to include @teacher
      end

      it "includes active TAs" do
        expect(@course.moderators).to include @ta
      end

      it "only includes a user once when they are enrolled multiple times in a course" do
        section = @course.course_sections.create!
        @course.enroll_teacher(@teacher, section:, allow_multiple_enrollments: true, enrollment_state: :active)
        expect(@course.moderators.count { |user| user == @teacher }).to eq 1
      end

      it "excludes invited teachers" do
        @course.enrollments.find_by!(user: @teacher).update!(workflow_state: :invited)
        expect(@course.moderators).not_to include @teacher
      end

      it "excludes invited TAs" do
        @course.enrollments.find_by!(user: @ta).update!(workflow_state: :invited)
        expect(@course.moderators).not_to include @ta
      end

      it 'excludes active teachers if teachers have "Select Final Grade" priveleges revoked' do
        @course.root_account.role_overrides.create!(permission: "select_final_grade", role: teacher_role, enabled: false)
        expect(@course.moderators).not_to include @teacher
      end

      it 'excludes active TAs if TAs have "Select Final Grade" priveleges revoked' do
        @course.root_account.role_overrides.create!(permission: "select_final_grade", role: ta_role, enabled: false)
        expect(@course.moderators).not_to include @ta
      end

      it "excludes inactive teachers" do
        @course.enrollments.find_by!(user: @teacher).deactivate
        expect(@course.moderators).not_to include @teacher
      end

      it "excludes concluded teachers" do
        @course.enrollments.find_by!(user: @teacher).conclude
        expect(@course.moderators).not_to include @teacher
      end

      it "excludes inactive TAs" do
        @course.enrollments.find_by!(user: @ta).deactivate
        expect(@course.moderators).not_to include @ta
      end

      it "excludes concluded TAs" do
        @course.enrollments.find_by!(user: @ta).conclude
        expect(@course.moderators).not_to include @ta
      end

      it "excludes admins" do
        admin = account_admin_user
        expect(@course.moderators).not_to include admin
      end
    end

    describe "#allow_final_grade_override?" do
      before :once do
        @course = Account.default.courses.create!
      end

      before do
        @course.enable_feature!(:final_grades_override)
        @course.allow_final_grade_override = true
      end

      it "returns true when the feature is enabled and the setting is allowed" do
        expect(@course.allow_final_grade_override?).to be true
      end

      it "returns false when the feature is enabled and the setting is not allowed" do
        @course.allow_final_grade_override = false
        expect(@course.allow_final_grade_override?).to be false
      end

      it "returns false when the feature is disabled" do
        @course.disable_feature!(:final_grades_override)
        expect(@course.allow_final_grade_override?).to be false
      end
    end

    describe "#hide_sections_on_course_users_page?" do
      before :once do
        course_with_student
      end

      context "Setting is set to On" do
        before do
          @course.update!(hide_sections_on_course_users_page: true)
        end

        it "returns true when there is more than one section" do
          @course.course_sections.create!
          expect(@course.sections_hidden_on_roster_page?(current_user: @user)).to be true
        end

        it "returns false when there is only one section" do
          expect(@course.sections_hidden_on_roster_page?(current_user: @user)).to be false
        end

        it "returns false when the user has at least one non-student enrollment" do
          teacher = User.create!
          @course.enroll_teacher(teacher, enrollment_state: :active)
          @course.enroll_student(teacher, enrollment_state: :active)
          expect(@course.sections_hidden_on_roster_page?(current_user: teacher)).to be false
        end

        it "returns false when the user has no enrollments (like an admin)" do
          admin = account_admin_user
          expect(@course.sections_hidden_on_roster_page?(current_user: admin)).to be false
        end
      end

      context "Setting is set to Off" do
        before do
          @course.update!(hide_sections_on_course_users_page: false)
        end

        it "returns false" do
          expect(@course.sections_hidden_on_roster_page?(current_user: @user)).to be false
        end
      end
    end

    describe "#filter_speed_grader_by_student_group?" do
      before :once do
        @course = Account.default.courses.create!
        @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
        @course.filter_speed_grader_by_student_group = true
      end

      it "returns true when the setting is on" do
        expect(@course).to be_filter_speed_grader_by_student_group
      end

      it "returns false when setting is off" do
        @course.filter_speed_grader_by_student_group = false
        expect(@course).not_to be_filter_speed_grader_by_student_group
      end

      it "returns false when the 'Filter SpeedGrader by Student Group' root account setting is off" do
        @course.root_account.disable_feature!(:filter_speed_grader_by_student_group)
        expect(@course).not_to be_filter_speed_grader_by_student_group
      end
    end

    describe "#recompute_student_scores" do
      it "uses all student ids except concluded and deleted if none are passed" do
        @course.save!
        course_with_student(course: @course).update!(workflow_state: :completed)
        course_with_student(course: @course).update!(workflow_state: :inactive)
        @user1 = @user
        course_with_student(course: @course, active_all: true)
        @user2 = @user
        expect(Enrollment).to receive(:recompute_final_score) do |student_ids, course_id, opts|
          expect(student_ids.sort).to eq [@user1.id, @user2.id]
          expect(course_id).to eq @course.id
          expect(opts).to eq({ grading_period_id: nil, update_all_grading_period_scores: true })
        end.and_return(nil)
        @course.recompute_student_scores
      end

      it "recomputes nothing if no students are visible" do
        @course.save!
        enrollment = course_with_student(course: @course, active_all: true)
        enrollment.destroy
        3.times { enrollment_model(workflow_state: "registered", course: @course, user: user_model) }
        expect(Enrollment).to receive(:recompute_final_score).with([], any_args)
        @course.recompute_student_scores([enrollment.user_id])
      end

      it "does not use student ids for users enrolled in other courses, even if they are explicitly passed" do
        @course.save!
        first_course = @course
        enrollment = course_with_student(active_all: true)
        expect(Enrollment).to receive(:recompute_final_score).with([], any_args)
        first_course.recompute_student_scores([enrollment.user_id])
      end

      it "triggers a delayed job by default" do
        expect(@course).to receive(:delay_if_production).and_return(@course)
        expect(@course).to receive(:recompute_student_scores_without_send_later)

        @course.recompute_student_scores
      end

      it "does not trigger a delayed job when passed run_immediately: true" do
        expect(@course).not_to receive(:delay)

        @course.recompute_student_scores(nil, run_immediately: true)
      end

      it "calls recompute_student_scores_without_send_later when passed run_immediately: true" do
        expect(@course).to receive(:recompute_student_scores_without_send_later)
        @course.recompute_student_scores(nil, run_immediately: true)
      end
    end

    it "properly determines if group weights are active" do
      @course.update_attribute(:group_weighting_scheme, nil)
      expect(@course.apply_group_weights?).to be false
      @course.update_attribute(:group_weighting_scheme, "equal")
      expect(@course.apply_group_weights?).to be false
      @course.update_attribute(:group_weighting_scheme, "percent")
      expect(@course.apply_group_weights?).to be true
    end

    it "returns course visibility flag" do
      @course.update_attribute(:is_public, nil)
      @course.update_attribute(:is_public_to_auth_users, nil)

      expect(@course.course_visibility).to eq("course")
      @course.update_attribute(:is_public, nil)
      @course.update_attribute(:is_public_to_auth_users, nil)

      @course.update_attribute(:is_public_to_auth_users, true)
      expect(@course.course_visibility).to eq("institution")

      @course.update_attribute(:is_public, true)
      expect(@course.course_visibility).to eq("public")
    end

    it "returns syllabus visibility flag" do
      @course.update_attribute(:public_syllabus, nil)
      @course.update_attribute(:public_syllabus_to_auth, nil)
      expect(@course.syllabus_visibility_option).to eq("course")

      @course.update_attribute(:public_syllabus, nil)
      @course.update_attribute(:public_syllabus_to_auth, true)
      expect(@course.syllabus_visibility_option).to eq("institution")

      @course.update_attribute(:public_syllabus, true)
      expect(@course.syllabus_visibility_option).to eq("public")
    end

    it "defaults public_syllabus to false" do
      @course.update_attribute(:is_public, nil)
      @course.update_attribute(:settings, @course.settings.except(:public_syllabus))
      expect(@course.public_syllabus).to be false
    end

    it "returns offline web export flag" do
      expect(@course.enable_offline_web_export?).to be false
      account = Account.default
      account.settings[:enable_offline_web_export] = true
      account.save
      expect(@course.enable_offline_web_export?).to be true
      @course.update_attribute(:enable_offline_web_export, false)
      expect(@course.enable_offline_web_export?).to be false
    end

    describe "soft-concluded?" do
      before :once do
        @term = Account.default.enrollment_terms.create!
      end

      before do
        @course.enrollment_term = @term
      end

      context "without term end date" do
        it "knows if it has been soft-concluded" do
          @course.update({ conclude_at: nil, restrict_enrollments_to_course_dates: true })
          expect(@course).not_to be_soft_concluded

          @course.update_attribute(:conclude_at, 1.week.from_now)
          expect(@course).not_to be_soft_concluded

          @course.update_attribute(:conclude_at, 1.week.ago)
          expect(@course).to be_soft_concluded
        end
      end

      context "with term end date in the past" do
        before do
          @course.enrollment_term.update_attribute(:end_at, 1.week.ago)
        end

        it "knows if it has been soft-concluded" do
          @course.update({ conclude_at: nil, restrict_enrollments_to_course_dates: true })
          expect(@course).to be_soft_concluded

          @course.update_attribute(:conclude_at, 1.week.from_now)
          expect(@course).not_to be_soft_concluded

          @course.update_attribute(:conclude_at, 1.week.ago)
          expect(@course).to be_soft_concluded
        end
      end

      context "with term end date in the future" do
        before do
          @course.enrollment_term.update_attribute(:end_at, 1.week.from_now)
        end

        it "knows if it has been soft-concluded" do
          @course.update({ conclude_at: nil, restrict_enrollments_to_course_dates: true })
          expect(@course).not_to be_soft_concluded

          @course.update_attribute(:conclude_at, 1.week.from_now)
          expect(@course).not_to be_soft_concluded

          @course.update_attribute(:conclude_at, 1.week.ago)
          expect(@course).to be_soft_concluded
        end
      end

      context "with coures dates not overriding term dates" do
        before do
          @course.update_attribute(:conclude_at, 1.week.from_now)
        end

        it "ignores course dates if not set to override term dates when calculating soft-concluded state" do
          @course.enrollment_term.update_attribute(:end_at, nil)
          expect(@course).not_to be_soft_concluded

          @course.enrollment_term.update_attribute(:end_at, 1.week.from_now)
          expect(@course).not_to be_soft_concluded

          @course.enrollment_term.update_attribute(:end_at, 1.week.ago)
          expect(@course).to be_soft_concluded
        end
      end

      it "tests conclusion for a specific enrollment type" do
        @term.set_overrides(@course.account, "StudentEnrollment" => { end_at: 1.week.ago })
        expect(@course).not_to be_soft_concluded
        expect(@course).not_to be_concluded
        expect(@course).to be_soft_concluded("StudentEnrollment")
        expect(@course).to be_concluded("StudentEnrollment")
      end
    end

    describe "allow_student_forum_attachments" do
      it "defaults to true" do
        expect(@course.allow_student_forum_attachments).to be true
      end

      it "allows setting and getting" do
        @course.allow_student_forum_attachments = false
        @course.save!
        expect(@course.allow_student_forum_attachments).to be false
      end
    end

    describe "allow_student_discussion_reporting" do
      it "defaults to true" do
        expect(@course.allow_student_discussion_reporting).to be true
      end

      it "allows setting and getting" do
        @course.allow_student_discussion_reporting = false
        @course.save!
        expect(@course.allow_student_discussion_reporting).to be false
      end
    end

    describe "allow_student_anonymous_discussion_topics" do
      it "defaults to false" do
        expect(@course.allow_student_anonymous_discussion_topics).to be false
      end

      it "allows setting and getting" do
        @course.allow_student_anonymous_discussion_topics = true
        @course.save!
        expect(@course.allow_student_anonymous_discussion_topics).to be true
      end
    end

    describe "allow_student_discussion_topics" do
      it "defaults true" do
        expect(@course.allow_student_discussion_topics).to be true
      end

      it "sets and get" do
        @course.allow_student_discussion_topics = false
        @course.save!
        expect(@course.allow_student_discussion_topics).to be false
      end
    end

    describe "#grading_periods?" do
      it "returns true if course has grading periods" do
        @course.save!
        Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
        expect(@course.grading_periods?).to be true
      end

      it "returns true if account has grading periods for course term" do
        @course.save!
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.enrollment_terms << @course.enrollment_term
        expect(@course.grading_periods?).to be true
      end

      it "returns false if account has grading periods without course term" do
        @course.save!
        Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        expect(@course.grading_periods?).to be false
      end

      it "returns false if neither course nor account have grading periods" do
        expect(@course.grading_periods?).to be false
      end
    end

    describe "#relevant_grading_period_group" do
      it "favors legacy over enrollment term grading_period_groups" do
        @course.save!
        account_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        account_group.enrollment_terms << @course.enrollment_term
        grading_period_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
        expect(@course.relevant_grading_period_group).to eq(grading_period_group)
      end

      it "returns a legacy grading_period_group" do
        @course.save!
        grading_period_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
        expect(@course.relevant_grading_period_group).to eq(grading_period_group)
      end

      it "returns an enrollment term grading_period_group" do
        @course.save!
        grading_period_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        grading_period_group.enrollment_terms << @course.enrollment_term
        expect(@course.relevant_grading_period_group).to eq(grading_period_group)
      end

      it "returns nil when there are no relevant grading_period_group" do
        @course.save!
        expect(@course.relevant_grading_period_group).to be_nil
      end
    end

    describe "#weighted_grading_periods?" do
      it "returns false if course has legacy grading periods" do
        @course.save!
        account_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        account_group.enrollment_terms << @course.enrollment_term
        group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
        group.weighted = true
        group.save!
        expect(@course.weighted_grading_periods?).to be false
      end

      it "returns false if account has unweighted grading periods for course term" do
        @course.save!
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.enrollment_terms << @course.enrollment_term
        expect(@course.weighted_grading_periods?).to be false
      end

      it "returns false if account has weighted grading periods without course term" do
        @course.save!
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.weighted = true
        group.save!
        expect(@course.weighted_grading_periods?).to be false
      end

      it "returns true if account has weighted grading periods for course term" do
        @course.save!
        legacy_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
        legacy_group.destroy
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.enrollment_terms << @course.enrollment_term
        group.weighted = true
        group.save!
        expect(@course.weighted_grading_periods?).to be true
      end
    end

    describe "#display_totals_for_all_grading_periods?" do
      before do
        @course.save!
      end

      it "returns false for a course without an associated grading period group" do
        expect(@course).not_to be_display_totals_for_all_grading_periods
      end

      it "returns false for a course with an associated grading period group that is soft-deleted" do
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.enrollment_terms << @course.enrollment_term
        group.update!(display_totals_for_all_grading_periods: true)
        group.destroy
        expect(@course).not_to be_display_totals_for_all_grading_periods
      end

      it "returns true if the associated grading period group has the setting enabled" do
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.enrollment_terms << @course.enrollment_term
        group.update!(display_totals_for_all_grading_periods: true)
        expect(@course).to be_display_totals_for_all_grading_periods
      end

      it "returns false if the associated grading period group has the setting disabled" do
        group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.root_account)
        group.enrollment_terms << @course.enrollment_term
        expect(@course).not_to be_display_totals_for_all_grading_periods
      end

      context "legacy grading periods support" do
        before do
          @group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
        end

        it "returns true if the associated grading period group has the setting enabled" do
          @group.update!(display_totals_for_all_grading_periods: true)
          expect(@course).to be_display_totals_for_all_grading_periods
        end

        it "returns false if the associated grading period group has the setting disabled" do
          expect(@course).not_to be_display_totals_for_all_grading_periods
        end

        it "returns false for a course with an associated grading period group that is soft-deleted" do
          @group.update!(display_totals_for_all_grading_periods: true)
          @group.destroy
          expect(@course).not_to be_display_totals_for_all_grading_periods
        end
      end
    end

    describe "#time_zone" do
      it "uses provided value when set, regardless of root account setting" do
        @root_account = Account.default
        @root_account.default_time_zone = "America/Chicago"
        @course.time_zone = "America/New_York"
        expect(@course.time_zone).to eq ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
      end

      it "defaults to root account value if not set" do
        @root_account = Account.default
        @root_account.default_time_zone = "America/Chicago"
        expect(@course.time_zone).to eq ActiveSupport::TimeZone["Central Time (US & Canada)"]
      end
    end

    context "validation" do
      it "creates a new instance given valid attributes" do
        expect { course_model }.not_to raise_error
      end

      it "does not allow creating on site_admin" do
        expect { course_model(account: Account.site_admin) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "does not expect site_admin to exist" do
        allow(Account).to receive(:site_admin).and_return nil
        course = Course.new(root_account_id: Account.default.id)
        expect(course.validate_not_on_siteadmin).to be_nil
      end

      it "does not allow updating account to site_admin" do
        course = course_model
        course.root_account = Account.site_admin
        expect(course).to_not be_valid
      end

      it "requires unique sis_source_id" do
        other_course = course_factory
        other_course.sis_source_id = "sisid"
        other_course.save!

        new_course = course_factory
        new_course.sis_source_id = other_course.sis_source_id
        expect(new_course).to_not be_valid
        new_course.sis_source_id = nil
        expect(new_course).to be_valid
      end

      it "requires unique integration_id" do
        other_course = course_factory
        other_course.integration_id = "intid"
        other_course.save!

        new_course = course_factory
        new_course.integration_id = other_course.integration_id
        expect(new_course).to_not be_valid
        new_course.integration_id = nil
        expect(new_course).to be_valid
      end

      it "validates the license" do
        course = course_factory
        course.license = "blah"
        course.save!
        expect(course.reload.license).to eq "private"

        course.license = "cc_by_sa"
        course.save!
        expect(course.reload.license).to eq "cc_by_sa"
      end
    end

    it "creates a unique course." do
      @course = Course.create_unique
      expect(@course.name).to eql("My Course")
      @uuid = @course.uuid
      @course2 = Course.create_unique(@uuid)
      expect(@course).to eql(@course2)
    end

    it "only changes the course code using the course name if the code is nil or empty" do
      @course = Course.create_unique
      code = @course.course_code
      @course.name = "test123"
      @course.save
      expect(code).to eql(@course.course_code)
      @course.course_code = nil
      @course.save
      expect(code).to_not eql(@course.course_code)
    end

    it "removes carriage returns from the name" do
      @course = Course.create_unique
      @course.name = "Hello\r\nWorld"
      @course.save
      expect(@course.name).to eql("Hello\nWorld")
    end

    it "throws error for long sis id" do
      # should throw rails validation error instead of db invalid statement error
      @course = Course.create_unique
      @course.sis_source_id = "qwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnmqwertyuiopasdfghjklzxcvbnm"
      expect { @course.save! }.to raise_error("Validation failed: Sis source is too long (maximum is 255 characters)")
    end

    it "always has a uuid, if it was created" do
      @course.save!
      expect(@course.uuid).not_to be_nil
    end

    context "permissions" do
      def clear_permissions_cache
        @course.clear_permissions_cache(@teacher)
        @course.clear_permissions_cache(@designer)
        @course.clear_permissions_cache(@ta)
        @course.clear_permissions_cache(@admin1)
        @course.clear_permissions_cache(@admin2)
      end

      it "follows account chain when looking for generic permissions from AccountUsers" do
        account = Account.create!
        sub_account = Account.create!(parent_account: account)
        sub_sub_account = Account.create!(parent_account: sub_account)
        user = account_admin_user(account: sub_account)
        course = Course.create!(account: sub_sub_account)
        expect(course.grants_right?(user, :manage)).to be_truthy
      end

      # we have to reload the users after each course change here to catch the
      # enrollment changes that are applied directly to the db with update_all
      it "grants delete to the proper individuals" do
        @course.root_account.disable_feature!(:granular_permissions_manage_courses)
        @role1 = custom_account_role("managecourses", account: Account.default)
        @role2 = custom_account_role("managesis", account: Account.default)
        account_admin_user_with_role_changes(role: @role1, role_changes: { manage_courses: true, change_course_state: true })
        @admin1 = @admin
        account_admin_user_with_role_changes(role: @role2, role_changes: { manage_sis: true, change_course_state: true })
        @admin2 = @admin
        course_with_teacher(active_all: true)
        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!
        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        # active, non-sis course
        expect(@course.grants_right?(@teacher, :delete)).to be_truthy
        expect(@course.grants_right?(@designer, :delete)).to be_truthy
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey

        # active, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_truthy

        # completed, non-sis course
        @course.sis_source_id = nil
        @course.complete!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_truthy
        expect(@course.grants_right?(@designer, :delete)).to be_truthy
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey
        @course.clear_permissions_cache(@user)

        # completed, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_truthy
      end

      # we have to reload the users after each course change here to catch the
      # enrollment changes that are applied directly to the db with update_all
      it "grants delete to the proper individuals (granular permissions)" do
        @course.root_account.enable_feature!(:granular_permissions_manage_courses)
        @role1 = custom_account_role("managecourses", account: Account.default)
        @role2 = custom_account_role("managesis", account: Account.default)
        account_admin_user_with_role_changes(role: @role1, role_changes: { manage_courses_delete: true })
        @admin1 = @admin
        account_admin_user_with_role_changes(role: @role2, role_changes: { manage_courses_delete: false })
        @admin2 = @admin
        course_with_teacher(active_all: true)
        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!
        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        # active, non-sis course
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey

        ro = Account.default.role_overrides.create!(role: teacher_role, permission: :manage_courses_delete, enabled: true)
        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_truthy
        ro.update(enabled: false)

        # active, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey

        # completed, non-sis course
        @course.sis_source_id = nil
        @course.complete!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey
        @course.clear_permissions_cache(@user)

        # completed, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@ta, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_truthy
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey
      end

      # :change_course_state is deprecated
      it "does not grant delete to anyone without :change_course_state rights (non-granular)" do
        @course.root_account.disable_feature!(:granular_permissions_manage_courses)
        @role1 = custom_account_role("managecourses", account: Account.default)
        @role2 = custom_account_role("managesis", account: Account.default)
        account_admin_user_with_role_changes(role: @role1, role_changes: { manage_courses: true })
        @admin1 = @admin
        account_admin_user_with_role_changes(role: @role2, role_changes: { manage_sis: true })
        @admin2 = @admin
        course_with_teacher(active_all: true)
        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!

        Account.default.role_overrides.create!(role: teacher_role, permission: :change_course_state, enabled: false)
        Account.default.role_overrides.create!(role: designer_role, permission: :change_course_state, enabled: false)

        # active, non-sis course
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_falsey
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey

        # active, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_falsey
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey

        # completed, non-sis course
        @course.sis_source_id = nil
        @course.complete!
        [@course, @teacher, @designer, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_falsey
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey
        @course.clear_permissions_cache(@user)

        # completed, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :delete)).to be_falsey
        expect(@course.grants_right?(@designer, :delete)).to be_falsey
        expect(@course.grants_right?(@admin1, :delete)).to be_falsey
        expect(@course.grants_right?(@admin2, :delete)).to be_falsey
      end

      it "grants reset_content to the proper individuals" do
        @course.root_account.disable_feature!(:granular_permissions_manage_courses)
        @role1 = custom_account_role("managecourses", account: Account.default)
        @role2 = custom_account_role("managesis", account: Account.default)
        account_admin_user_with_role_changes(role: @role1, role_changes: { manage_courses: true })
        @admin1 = @admin
        account_admin_user_with_role_changes(role: @role2, role_changes: { manage_sis: true })
        @admin2 = @admin
        course_with_teacher(active_all: true)
        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!
        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        # active, non-sis course
        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_truthy
        expect(@course.grants_right?(@designer, :reset_content)).to be_truthy
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

        # active, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_truthy
        expect(@course.grants_right?(@designer, :reset_content)).to be_truthy
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

        # completed, non-sis course
        @course.sis_source_id = nil
        @course.complete!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
        expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

        # completed, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
        expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey
      end

      it "grants reset_content to the proper individuals (granular permissions)" do
        @course.root_account.enable_feature!(:granular_permissions_manage_courses)
        @role1 = custom_account_role("managecourses", account: Account.default)
        @role2 = custom_account_role("managesis", account: Account.default)
        account_admin_user_with_role_changes(role: @role1, role_changes: { manage_courses_reset: true })
        @admin1 = @admin
        account_admin_user_with_role_changes(role: @role2, role_changes: { manage_sis: true })
        @admin2 = @admin
        course_with_teacher(active_all: true)
        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!
        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        # active, non-sis course
        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
        expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

        # active, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
        expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

        # completed, non-sis course
        @course.sis_source_id = nil
        @course.complete!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
        expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey

        # completed, sis course
        @course.sis_source_id = "sis_id"
        @course.save!
        [@course, @teacher, @designer, @ta, @admin1, @admin2].each(&:reload)

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :reset_content)).to be_falsey
        expect(@course.grants_right?(@designer, :reset_content)).to be_falsey
        expect(@course.grants_right?(@ta, :reset_content)).to be_falsey
        expect(@course.grants_right?(@admin1, :reset_content)).to be_truthy
        expect(@course.grants_right?(@admin2, :reset_content)).to be_falsey
      end

      it "grants create_tool_manually to the proper individuals" do
        course_with_teacher(active_all: true)
        @course.root_account.disable_feature!(:granular_permissions_manage_lti)
        @teacher = user_factory(active_all: true)
        @course.enroll_teacher(@teacher).accept!

        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!

        @student = user_factory(active_all: true)
        @course.enroll_student(@student).accept!

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :create_tool_manually)).to be_truthy
        expect(@course.grants_right?(@ta, :create_tool_manually)).to be_truthy
        expect(@course.grants_right?(@designer, :create_tool_manually)).to be_truthy
        expect(@course.grants_right?(@student, :create_tool_manually)).to be_falsey
      end

      it "grants manage_lti_* to the proper individuals (granular permissions)" do
        course_with_teacher(active_all: true)
        @course.root_account.enable_feature!(:granular_permissions_manage_lti)
        @teacher = user_factory(active_all: true)
        @course.enroll_teacher(@teacher).accept!

        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!

        @student = user_factory(active_all: true)
        @course.enroll_student(@student).accept!

        clear_permissions_cache
        expect(@course.grants_right?(@teacher, :manage_lti_add)).to be_truthy
        expect(@course.grants_right?(@ta, :manage_lti_add)).to be_truthy
        expect(@course.grants_right?(@designer, :manage_lti_add)).to be_truthy
        expect(@course.grants_right?(@student, :manage_lti_add)).to be_falsey
        expect(@course.grants_right?(@teacher, :manage_lti_edit)).to be_truthy
        expect(@course.grants_right?(@ta, :manage_lti_edit)).to be_truthy
        expect(@course.grants_right?(@designer, :manage_lti_edit)).to be_truthy
        expect(@course.grants_right?(@student, :manage_lti_edit)).to be_falsey
        expect(@course.grants_right?(@teacher, :manage_lti_delete)).to be_truthy
        expect(@course.grants_right?(@ta, :manage_lti_delete)).to be_truthy
        expect(@course.grants_right?(@designer, :manage_lti_delete)).to be_truthy
        expect(@course.grants_right?(@student, :manage_lti_delete)).to be_falsey
      end

      def make_date_completed
        @enrollment.reload
        @enrollment.start_at = 4.days.ago
        @enrollment.end_at = 2.days.ago
        @enrollment.save!
        @enrollment.reload
        expect(@enrollment.state_based_on_date).to eq :completed
      end

      context "as a teacher" do
        let_once :c do
          course_with_teacher(active_all: 1)
          @course
        end

        it "grants read_as_admin and read_forum to date-completed teacher" do
          make_date_completed
          expect(c.prior_enrollments).to eq []
          expect(c.grants_right?(@teacher, :read_as_admin)).to be_truthy
          expect(c.grants_right?(@teacher, :read_forum)).to be_truthy
        end

        it "grants read_as_admin and read to date-completed teacher of unpublished course" do
          course_factory.update_attribute(:workflow_state, "claimed")
          make_date_completed
          expect(c.prior_enrollments).to eq []
          expect(c.grants_right?(@teacher, :read_as_admin)).to be_truthy
          expect(c.grants_right?(@teacher, :read)).to be_truthy
        end

        it "grants read_rubric to date-completed teacher" do
          make_date_completed
          expect(c.grants_right?(@teacher, :read_rubrics)).to be_truthy
        end

        it "grants :read_outcomes to teachers in the course" do
          expect(c.grants_right?(@teacher, :read_outcomes)).to be_truthy
        end

        it "grants :read_rubric to teachers in the course" do
          expect(c.grants_right?(@teacher, :read_rubrics)).to be_truthy
        end
      end

      context "as a designer" do
        let_once :c do
          course_factory(active_all: true)
          @designer = user_factory(active_all: true)
          @enrollment = @course.enroll_designer(@designer)
          @enrollment.accept!
          @course
        end

        it "grants read_as_admin, read, manage, and update to date-active designer" do
          expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
          expect(c.grants_right?(@designer, :read)).to be_truthy
          expect(c.grants_right?(@designer, :manage)).to be_truthy
          expect(c.grants_right?(@designer, :update)).to be_truthy
        end

        it "grants permissions for unpublished courses" do
          c.claim!
          expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
          expect(c.grants_right?(@designer, :read)).to be_truthy
          expect(c.grants_right?(@designer, :manage)).to be_truthy
          expect(c.grants_right?(@designer, :update)).to be_truthy
          expect(c.grants_right?(@designer, :read_roster)).to be_truthy
        end

        it "grants read_as_admin, read_roster, and read_prior_roster to date-completed designer" do
          @enrollment.start_at = 4.days.ago
          @enrollment.end_at = 2.days.ago
          @enrollment.save!
          expect(@enrollment.reload.state_based_on_date).to eq :completed
          expect(c.prior_enrollments).to eq []
          expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
          expect(c.grants_right?(@designer, :read_roster)).to be_truthy
          expect(c.grants_right?(@designer, :read_prior_roster)).to be_truthy
        end

        it "grants be able to disable read_roster to date-completed designer" do
          Account.default.role_overrides.create!(permission: :read_roster, role: designer_role, enabled: false)
          @enrollment.start_at = 4.days.ago
          @enrollment.end_at = 2.days.ago
          @enrollment.save!
          expect(@enrollment.reload.state_based_on_date).to eq :completed
          expect(c.prior_enrollments).to eq []
          expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
          expect(c.grants_right?(@designer, :read_roster)).to be_falsey
          expect(c.grants_right?(@designer, :read_prior_roster)).to be_falsey
        end

        it "grants read_as_admin and read to date-completed designer of unpublished course" do
          c.update_attribute(:workflow_state, "claimed")
          make_date_completed
          expect(c.prior_enrollments).to eq []
          expect(c.grants_right?(@designer, :read_as_admin)).to be_truthy
          expect(c.grants_right?(@designer, :read)).to be_truthy
        end

        it "does not grant read_user_notes or view_all_grades to designer" do
          expect(c.grants_right?(@designer, :read_user_notes)).to be_falsey
          expect(c.grants_right?(@designer, :view_all_grades)).to be_falsey
        end
      end

      context "as a 'student view' student" do
        it "grants read rights for unpublished courses" do
          course_factory
          test_student = @course.student_view_student

          expect(@course.grants_right?(test_student, :read)).to be_truthy
          expect(@course.grants_right?(test_student, :read_grades)).to be_truthy
          expect(@course.grants_right?(test_student, :read_forum)).to be_truthy
        end
      end

      context "as a student" do
        let_once :c do
          course_with_student(active_user: 1)
          @course
        end

        it "grants read_grades read_forum to date-completed student" do
          c.offer!
          make_date_completed
          expect(c.prior_enrollments).to eq []
          expect(c.grants_right?(@student, :read_grades)).to be_truthy
          expect(c.grants_right?(@student, :read_forum)).to be_truthy
        end

        it "does not grant read_forum to date-completed student if disabled by role override" do
          c.root_account.role_overrides.create!(role: student_role, permission: :read_forum, enabled: false)
          c.offer!
          make_date_completed
          expect(c.prior_enrollments).to eq []
          expect(c.grants_right?(@student, :read_forum)).to be_falsey
        end

        it "does not grant permissions to active students of an unpublished course" do
          expect(c).to be_created

          @enrollment.update_attribute(:workflow_state, "active")

          expect(c.grants_right?(@student, :read)).to be_falsey
          expect(c.grants_right?(@student, :read_grades)).to be_falsey
          expect(c.grants_right?(@student, :read_forum)).to be_falsey
        end

        it "does not grant read to completed students of an unpublished course" do
          expect(c).to be_created
          @enrollment.update_attribute(:workflow_state, "completed")
          expect(@enrollment).to be_completed
          expect(c.grants_right?(@student, :read)).to be_falsey
        end

        it "does not grant read to soft-completed students of an unpublished course" do
          c.restrict_enrollments_to_course_dates = true
          c.start_at = 4.days.ago
          c.conclude_at = 2.days.ago
          c.save!
          expect(c).to be_created
          @enrollment.update_attribute(:workflow_state, "active")
          expect(@enrollment.state_based_on_date).to eq :completed
          expect(c.grants_right?(@student, :read)).to be_falsey
        end

        it "grants :read_outcomes to students in the course" do
          c.offer!
          expect(c.grants_right?(@student, :read_outcomes)).to be_truthy
        end
      end

      context "as an admin" do
        it "grants :read_outcomes to account admins" do
          course_factory(active_all: true)
          account_admin_user(account: @course.account)
          expect(@course.grants_right?(@admin, :read_outcomes)).to be_truthy
        end
      end
    end

    describe "#reset_content" do
      before(:once) do
        course_with_student
      end

      it "clears content" do
        @course.root_account.allow_self_enrollment!

        @course.discussion_topics.create!
        @course.quizzes.create!
        @course.assignments.create!
        @course.wiki.set_front_page_url!("front-page")
        @course.wiki.front_page.save!
        @course.self_enrollment = true
        @course.sis_source_id = "sis_id"
        @course.lti_context_id = "lti_context_id"
        @course.stuck_sis_fields = [].to_set
        gs = @course.grading_standards.create!(title: "Standard eh", data: [["Eh", 0.93], ["Eff", 0]])
        @course.grading_standard = gs
        profile = @course.profile
        profile.description = "description"
        profile.save!
        @course.save!
        @course.reload
        @course.update!(latest_outcome_import:
          OutcomeImport.create!(context: @course))

        expect(@course.course_sections).not_to be_empty
        expect(@course.students).to eq [@student]
        expect(@course.stuck_sis_fields).to eq [].to_set
        self_enrollment_code = @course.self_enrollment_code
        expect(self_enrollment_code).not_to be_nil

        @new_course = @course.reset_content

        @course.reload
        expect(@course.stuck_sis_fields).to eq [:workflow_state].to_set
        expect(@course.course_sections).to be_empty
        expect(@course.students).to be_empty
        expect(@course.sis_source_id).to be_nil
        expect(@course.self_enrollment_code).to be_nil
        expect(@course.lti_context_id).not_to be_nil

        @new_course.reload
        expect(@new_course.grading_standard).to be_nil
        expect(@new_course).to be_created
        expect(@new_course.course_sections).not_to be_empty
        expect(@new_course.students).to eq [@student]
        expect(@new_course.discussion_topics).to be_empty
        expect(@new_course.quizzes).to be_empty
        expect(@new_course.assignments).to be_empty
        expect(@new_course.sis_source_id).to eq "sis_id"
        expect(@new_course.syllabus_body).to be_blank
        expect(@new_course.stuck_sis_fields).to eq [].to_set
        expect(@new_course.self_enrollment_code).to eq self_enrollment_code
        expect(@new_course.lti_context_id).to be_nil

        expect(@course.uuid).not_to eq @new_course.uuid
        expect(@course.wiki_id).not_to eq @new_course.wiki_id
        expect(@course.replacement_course_id).to eq @new_course.id
      end

      it "does not have self enrollment enabled if account setting disables it" do
        @course.self_enrollment = true
        @course.save!
        expect(@course.self_enrollment_enabled?).to be false

        account = @course.root_account
        account.allow_self_enrollment!
        @course.self_enrollment = true
        @course.save!
        expect(@course.reload.self_enrollment_enabled?).to be true

        account.settings.delete(:self_enrollment)
        account.save!
        expect(@course.reload.self_enrollment_enabled?).to be false
      end

      it "retains original course profile" do
        data = { something: "special here" }
        description = "simple story"
        expect(@course.profile).not_to be_nil
        @course.profile.tap do |p|
          p.description = description
          p.data = data
          p.save!
        end
        @course.reload

        @new_course = @course.reset_content

        expect(@new_course.profile.data[:something]).to eq data[:something]
        expect(@new_course.profile.description).to eq description
      end

      it "preserves sticky fields" do
        sub = @course.root_account.sub_accounts.create
        @course.sis_source_id = "sis_id"
        @course.course_code = "cid"
        @course.stuck_sis_fields = [].to_set
        @course.save!
        @course.reload
        @course.name = "course_name"
        expect(@course.stuck_sis_fields).to eq [:name].to_set
        profile = @course.profile
        profile.description = "description"
        profile.save!
        @course.account = sub
        @course.save!
        expect(@course.stuck_sis_fields).to eq [:name, :account_id].to_set

        @course.reload

        @new_course = @course.reset_content

        @course.reload
        expect(@course.stuck_sis_fields).to eq %i[workflow_state name account_id].to_set
        expect(@course.sis_source_id).to be_nil

        @new_course.reload
        expect(@new_course.sis_source_id).to eq "sis_id"
        expect(@new_course.stuck_sis_fields).to eq [:name, :account_id].to_set

        expect(@course.uuid).not_to eq @new_course.uuid
        expect(@course.replacement_course_id).to eq @new_course.id
      end

      it "transfers favorites with the enrollments" do
        student_in_course(course: @course)
        fav = @student.favorites.create!(context: @course)

        @course.reload

        @new_course = @course.reset_content
        expect(fav.reload.context).to eq @new_course
      end
    end

    context "group_categories" do
      let_once(:course) { course_model }

      it "group_categories should not include deleted categories" do
        expect(course.group_categories.count).to eq 0
        category1 = course.group_categories.create(name: "category 1")
        category2 = course.group_categories.create(name: "category 2")
        expect(course.group_categories.count).to eq 2
        category1.destroy
        course.reload
        expect(course.group_categories.count).to eq 1
        expect(course.group_categories.to_a).to eq [category2]
      end

      it "all_group_categories should include deleted categories" do
        expect(course.all_group_categories.count).to eq 0
        category1 = course.group_categories.create(name: "category 1")
        course.group_categories.create(name: "category 2")
        expect(course.all_group_categories.count).to eq 2
        category1.destroy
        course.reload
        expect(course.all_group_categories.count).to eq 2
      end
    end

    context "turnitin" do
      it "returns turnitin_originality" do
        @course.account.turnitin_originality = "after_grading"
        @course.account.save!
        expect(@course.turnitin_originality).to eq("after_grading")
      end
    end

    describe "#quiz_lti_tool" do
      before do
        @course.save!
        @tool = ContextExternalTool.new(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )
      end

      it "returns the quiz LTI tool for the course" do
        @course.context_external_tools << @tool
        expect(@course.quiz_lti_tool).to eq @tool
      end

      it "returns the quiz LTI tool for the account if not set up on the course" do
        @course.account.context_external_tools << @tool
        expect(@course.quiz_lti_tool).to eq @tool
      end

      it "returns nil if no quiz LTI tool is configured" do
        expect(@course.quiz_lti_tool).to be_nil
      end
    end

    describe "#post_manually?" do
      let_once(:course) { Course.create! }

      it "returns true if a policy with manual posting is attached to the course" do
        course.default_post_policy.update!(post_manually: true)
        expect(course).to be_post_manually
      end

      it "returns false if a policy without manual posting is attached to the course" do
        course.default_post_policy.update!(post_manually: false)
        expect(course).not_to be_post_manually
      end
    end

    describe "#apply_post_policy!" do
      let_once(:course) { Course.create! }

      it "sets the post policy for the course" do
        course.apply_post_policy!(post_manually: true)
        expect(course.reload).to be_post_manually
      end

      it "explicitly sets a post policy for assignments without one" do
        assignment = course.assignments.create!

        course.apply_post_policy!(post_manually: true)
        expect(assignment.reload.post_policy).to be_post_manually
      end

      it "updates the post policy for assignments with an existing-but-different policy" do
        assignment = course.assignments.create!
        assignment.ensure_post_policy(post_manually: false)

        course.apply_post_policy!(post_manually: true)
        expect(assignment.reload.post_policy).to be_post_manually
      end

      it "does not update assignments that have an equivalent post policy" do
        assignment = course.assignments.create!
        assignment.ensure_post_policy(post_manually: true)

        expect do
          course.apply_post_policy!(post_manually: true)
        end.not_to change {
          PostPolicy.find_by!(assignment:).updated_at
        }
      end

      it "does not change the post policy for anonymous assignments" do
        course.apply_post_policy!(post_manually: true)
        anonymous_assignment = course.assignments.create!(anonymous_grading: true)

        expect do
          course.apply_post_policy!(post_manually: false)
        end.not_to change {
          PostPolicy.find_by!(assignment: anonymous_assignment).post_manually
        }
      end

      it "does not change the post policy for moderated assignments" do
        course.apply_post_policy!(post_manually: true)
        moderated_assignment = course.assignments.create!(
          final_grader: course.enroll_teacher(User.create!, enrollment_state: :active).user,
          grader_count: 2,
          moderated_grading: true
        )

        expect do
          course.apply_post_policy!(post_manually: false)
        end.not_to change {
          PostPolicy.find_by(assignment: moderated_assignment).post_manually
        }
      end
    end

    describe "post policy defaults" do
      it "a post policy is created when a newly-created course is saved with no policy" do
        course = Course.create!

        aggregate_failures do
          expect(course.default_post_policy).not_to be_nil
          expect(course.default_post_policy).not_to be_post_manually
        end
      end

      it "a course retains its existing post policy when saved if one is set" do
        course = Course.new
        course.build_default_post_policy(assignment_id: nil, post_manually: true)

        course.save!
        expect(course.reload.default_post_policy).to be_post_manually
      end
    end

    it "destroys associated gradebook filters when the course is soft-deleted" do
      course_with_teacher(active_all: true)
      @course.gradebook_filters.create!(user: @teacher, course: @course, name: "First filter", payload: { foo: :bar })
      @course.destroy
      expect(@course.gradebook_filters.count).to eq 0
    end
  end

  context "users_not_in_groups" do
    before :once do
      @course = course_factory(active_all: true)
      @user1 = user_model
      @user2 = user_model
      @user3 = user_model
      @enrollment1 = @course.enroll_user(@user1)
      @enrollment2 = @course.enroll_user(@user2)
      @enrollment3 = @course.enroll_user(@user3)
    end

    it "does not include users through deleted/rejected/completed enrollments" do
      @enrollment1.destroy
      expect(@course.users_not_in_groups([]).size).to eq 2
    end

    it "does not include users in one of the groups" do
      group = @course.groups.create
      group.add_user(@user1)
      users = @course.users_not_in_groups([group])
      expect(users.size).to eq 2
      expect(users).not_to include(@user1)
    end

    it "includes users otherwise" do
      group = @course.groups.create
      group.add_user(@user1)
      users = @course.users_not_in_groups([group])
      expect(users).to include(@user2)
      expect(users).to include(@user3)
    end

    it "allows ordering by user's sortable name" do
      @user1.sortable_name = "jonny"
      @user1.save
      @user2.sortable_name = "bob"
      @user2.save
      @user3.sortable_name = "richard"
      @user3.save
      users = @course.users_not_in_groups([], order: User.sortable_name_order_by_clause("users"))
      expect(users.map(&:id)).to eq [@user2.id, @user1.id, @user3.id]
    end
  end

  context "events_for" do
    before :once do
      course_with_teacher(active_all: true)
      @event1 = @course.calendar_events.create
      @event2 = @course.calendar_events.build child_event_data: [{ start_at: "2012-01-01", end_at: "2012-01-02", context_code: @course.default_section.asset_string }]
      @event2.updating_user = @teacher
      @event2.save!
      @event3 = @event2.child_events.first
      @appointment_group = AppointmentGroup.create! title: "ag", contexts: [@course]
      @appointment_group.publish!
      @assignment = @course.assignments.create!
    end

    it "returns appropriate events" do
      events = @course.events_for(@teacher)
      expect(events).to include @event1
      expect(events).not_to include @event2
      expect(events).to include @event3
      expect(events).to include @appointment_group
      expect(events).to include @assignment
    end

    it "returns appropriate events when no user is supplied" do
      events = @course.events_for(nil)
      expect(events).to include @event1
      expect(events).not_to include @event2
      expect(events).not_to include @event3
      expect(events).not_to include @appointment_group
      expect(events).to include @assignment
    end
  end

  it "is marshal-able" do
    c = Course.new(name: "c1")
    expect { Marshal.dump(c) }.not_to raise_error
    c.save!
    expect { Marshal.dump(c) }.not_to raise_error
  end

  describe "course_section_visibility" do
    before :once do
      @course = Account.default.courses.create!
      @section1 = @course.course_sections.create!(name: "Section 1")
      @section2 = @course.course_sections.create!(name: "Section 2")
    end

    it "returns all for admins" do
      admin = account_admin_user(account: @course.root_account, role: admin_role, active_user: true)
      expect(@course.course_section_visibility(admin)).to eq :all
    end

    it "returns correct sections for students" do
      student = User.create!(name: "Student")
      @course.enroll_student(student, section: @section1)
      expect(@course.course_section_visibility(student)).to eq [@section1.id]
    end

    it "correctly limits visibilities for a limited teacher" do
      limited_teacher = User.create(name: "Limited Teacher")
      @course.enroll_teacher(limited_teacher,
                             limit_privileges_to_course_section: true,
                             section: @section2)
      expect(@course.course_section_visibility(limited_teacher)).to eq [@section2.id]
    end

    it "unlimited teachers can see everything" do
      unlimited_teacher = User.create(name: "Unlimited Teacher")
      @course.enroll_teacher(unlimited_teacher, section: @section2)
      expect(@course.course_section_visibility(unlimited_teacher)).to eq :all
    end

    it "returns none for a user with no visibility" do
      user_with_no_visibility = User.create(name: "Sans Connexion")
      expect(@course.course_section_visibility(user_with_no_visibility)).to eq []
    end
  end

  context "resolved_outcome_proficiency" do
    it "retrieves account's outcome proficiency" do
      course_model
      method = outcome_proficiency_model(@course.root_account)
      expect(@course.resolved_outcome_proficiency).to eq method
    end

    it "can retrieve own proficiency" do
      root_account = Account.create!
      outcome_proficiency_model(root_account)
      course = course_model(account: root_account)
      course_method = outcome_proficiency_model(course)
      expect(course.outcome_proficiency).to eq course_method
      expect(course.resolved_outcome_proficiency).to eq course_method
    end

    it "can retrieve ancestor account's proficiency" do
      root_account = Account.create!
      root_method = outcome_proficiency_model(root_account)
      subaccount = root_account.sub_accounts.create!
      course = course_model(account: subaccount)
      expect(course.outcome_proficiency).to be_nil
      expect(course.resolved_outcome_proficiency).to eq root_method
    end

    it "ignores soft deleted proficiencies" do
      root_account = Account.create!
      account_method = outcome_proficiency_model(root_account)
      course = course_model(account: root_account)
      course_method = outcome_proficiency_model(course)
      course_method.destroy
      expect(course.outcome_proficiency).to eq course_method
      expect(course.resolved_outcome_proficiency).to eq account_method
    end

    context "with the account_level_mastery_scales FF enabled" do
      it "returns the account default if no record exists" do
        root_account = Account.create!
        root_account.enable_feature!(:account_level_mastery_scales)
        course = course_model(account: root_account)
        expect(course.outcome_proficiency).to be_nil
        expect(course.resolved_outcome_proficiency).to eq OutcomeProficiency.find_or_create_default!(root_account)
      end
    end

    context "with the account_level_mastery_scales FF disabled" do
      it "returns nil if no record exists" do
        root_account = Account.create!
        root_account.disable_feature!(:account_level_mastery_scales)
        course = course_model(account: root_account)
        expect(course.outcome_proficiency).to be_nil
        expect(course.resolved_outcome_proficiency).to be_nil
      end
    end
  end

  context "resolved_outcome_calculation_method" do
    it "retrieves account's outcome calculation method" do
      root_account = Account.create!
      method = OutcomeCalculationMethod.create! context: root_account, calculation_method: :highest
      course = course_model(account: root_account)
      expect(course.outcome_calculation_method).to be_nil
      expect(course.resolved_outcome_calculation_method).to eq method
    end

    it "can retrieve ancestor account's outcome calculation method" do
      root_account = Account.create!
      subaccount = root_account.sub_accounts.create!
      method = OutcomeCalculationMethod.create! context: root_account, calculation_method: :highest
      course = course_model(account: subaccount)
      expect(course.outcome_calculation_method).to be_nil
      expect(course.resolved_outcome_calculation_method).to eq method
    end

    it "can retrieve own outcome calculation method" do
      root_account = Account.create!
      OutcomeCalculationMethod.create! context: root_account, calculation_method: :highest
      course = course_model(account: root_account)
      course_method = OutcomeCalculationMethod.create! context: course, calculation_method: :latest
      expect(course.outcome_calculation_method).to eq course_method
      expect(course.resolved_outcome_calculation_method).to eq course_method
    end

    it "ignores soft deleted calculation methods" do
      root_account = Account.create!
      account_method = OutcomeCalculationMethod.create! context: root_account, calculation_method: :highest
      course = course_model(account: root_account)
      course_method = OutcomeCalculationMethod.create! context: course, calculation_method: :latest, workflow_state: :deleted
      expect(course.outcome_calculation_method).to eq course_method
      expect(course.resolved_outcome_calculation_method).to eq account_method
    end

    context "with the account_level_mastery_scales FF enabled" do
      it "returns the account default if no record exists" do
        root_account = Account.create!
        root_account.enable_feature!(:account_level_mastery_scales)
        course = course_model(account: root_account)
        expect(course.outcome_calculation_method).to be_nil
        expect(course.resolved_outcome_calculation_method).to eq OutcomeCalculationMethod.find_or_create_default!(root_account)
      end
    end

    context "with the account_level_mastery_scales FF disabled" do
      it "returns nil if no record exists" do
        root_account = Account.create!
        root_account.disable_feature!(:account_level_mastery_scales)
        course = course_model(account: root_account)
        expect(course.outcome_calculation_method).to be_nil
        expect(course.resolved_outcome_calculation_method).to be_nil
      end
    end
  end

  context "participants" do
    before :once do
      @course = Course.create(name: "some_name")
      se = @course.enroll_student(user_with_pseudonym, enrollment_state: "active")
      tae = @course.enroll_ta(user_with_pseudonym, enrollment_state: "active")
      te = @course.enroll_teacher(user_with_pseudonym, enrollment_state: "active")
      @student, @ta, @teach = [se, tae, te].map(&:user)
    end

    context "vanilla usage" do
      it "returns participating_admins and participating_students" do
        [@student, @ta, @teach].each { |usr| expect(@course.participants).to include(usr) }
      end

      it "uses date-based logic if requested" do
        expect(@course.participating_students_by_date).to include(@student)
        expect(@course.participants(by_date: true)).to include(@student)

        @course.reload
        @course.start_at = 2.days.from_now
        @course.conclude_at = 4.days.from_now
        @course.restrict_enrollments_to_course_dates = true
        @course.save!

        participants = @course.participants
        expect(participants).to include(@student)

        expect(@course.participating_students_by_date).to_not include(@student)
        expect(@course.participating_admins_by_date).to include(@ta)

        by_date = @course.participants(by_date: true)
        expect(by_date).to_not include(@student)
        expect(by_date).to include(@ta)

        @course.enrollment_term.set_overrides(@course.root_account, "TaEnrollment" => { start_at: 3.days.ago, end_at: 2.days.ago })
        @course.reload
        expect(@course.participants(by_date: true)).to_not include(@ta)
        expect(@course.participating_admins_by_date).to_not include(@ta)
      end
    end

    context "including obervers" do
      before :once do
        oe = @course.enroll_user(user_with_pseudonym, "ObserverEnrollment", enrollment_state: "active")
        @course_level_observer = oe.user

        oe = @course.enroll_user(user_with_pseudonym, "ObserverEnrollment", enrollment_state: "active")
        oe.associated_user_id = @student.id
        oe.save!
        @student_following_observer = oe.user
      end

      it "returns participating_admins, participating_students, and observers" do
        participants = @course.participants(include_observers: true)
        [@student, @ta, @teach, @course_level_observer, @student_following_observer].each do |usr|
          expect(participants).to include(usr)
        end
      end

      context "excluding specific students" do
        it "rejects observers only following one of the excluded students" do
          partic = @course.participants(include_observers: true, excluded_user_ids: [@student.id, @student_following_observer.id])
          [@student, @student_following_observer].each { |usr| expect(partic).to_not include(usr) }
        end

        it "includes admins and course level observers" do
          partic = @course.participants(include_observers: true, excluded_user_ids: [@student.id, @student_following_observer.id])
          [@ta, @teach, @course_level_observer].each { |usr| expect(partic).to include(usr) }
        end
      end
    end

    it "excludes some student when passed their id" do
      partic = @course.participants(include_observers: false, excluded_user_ids: [@student.id])
      [@ta, @teach].each { |usr| expect(partic).to include(usr) }
      expect(partic).to_not include(@student)
    end
  end

  describe "enroll" do
    before :once do
      @course = Course.create(name: "some_name")
      @user = user_with_pseudonym
    end

    context "students" do
      before :once do
        @se = @course.enroll_student(@user)
      end

      it "is able to enroll a student" do
        expect(@se.user_id).to eql(@user.id)
        expect(@se.course_id).to eql(@course.id)
      end

      it "enrolls a student as creation_pending if the course isn't published" do
        expect(@se).to be_creation_pending
      end
    end

    context "tas" do
      before :once do
        Notification.create(name: "Enrollment Registration", category: "registration")
        @tae = @course.enroll_ta(@user)
      end

      it "is able to enroll a TA" do
        expect(@tae.user_id).to eql(@user.id)
        expect(@tae.course_id).to eql(@course.id)
      end

      it "enrolls a ta as invited if the course isn't published" do
        expect(@tae).to be_invited
        expect(@tae.messages_sent).to include("Enrollment Registration")
      end
    end

    context "teachers" do
      before :once do
        Notification.create(name: "Enrollment Registration", category: "registration")
        @te = @course.enroll_teacher(@user)
      end

      it "is able to enroll a teacher" do
        expect(@te.user_id).to eql(@user.id)
        expect(@te.course_id).to eql(@course.id)
      end

      it "enrolls a teacher as invited if the course isn't published" do
        expect(@te).to be_invited
        expect(@te.messages_sent).to include("Enrollment Registration")
      end
    end

    it "is able to enroll a designer" do
      @course.enroll_designer(@user)
      @de = @course.enrollments.where(type: "DesignerEnrollment").first
      expect(@de.user_id).to eql(@user.id)
      expect(@de.course_id).to eql(@course.id)
    end

    it "scopes correctly when including teachers from course" do
      account = @course.account
      @course.enroll_student(@user)
      scope = account.associated_courses.active.select([:id, :name]).eager_load(:teachers).joins(:teachers).where(enrollments: { workflow_state: "active" })
      sql = scope.to_sql
      expect(sql).to match(/"enrollments"\."type" = 'TeacherEnrollment'/)
    end
  end

  describe "#assignment_groups" do
    it "orders groups by position" do
      course_model
      @course.assignment_groups.create!(name: "B Group", position: 3)
      @course.assignment_groups.create!(name: "A Group", position: 2)
      @course.assignment_groups.create!(name: "C Group", position: 1)

      groups = @course.assignment_groups

      expect(groups[0].name).to eq("C Group")
      expect(groups[1].name).to eq("A Group")
      expect(groups[2].name).to eq("B Group")
    end

    it "orders groups by name when positions are equal" do
      course_model

      @course.assignment_groups.create!(name: "B Group", position: 1)
      @course.assignment_groups.create!(name: "A Group", position: 2)
      @course.assignment_groups.create!(name: "D Group", position: 3)
      @course.assignment_groups.create!(name: "C Group", position: 3)

      @course.reload
      expect(AssignmentGroup).to receive(:best_unicode_collation_key).with("assignment_groups.name").at_least(1).and_call_original
      groups = @course.assignment_groups

      expect(groups[0].name).to eq("B Group")
      expect(groups[1].name).to eq("A Group")
      expect(groups[2].name).to eq("C Group")
      expect(groups[3].name).to eq("D Group")
    end
  end

  describe "#score_to_grade" do
    it "maps scores to grades correctly" do
      default = GradingStandard.default_grading_standard
      expect(default.to_json).to eq([["A", 0.94], ["A-", 0.90], ["B+", 0.87], ["B", 0.84], ["B-", 0.80], ["C+", 0.77], ["C", 0.74], ["C-", 0.70], ["D+", 0.67], ["D", 0.64], ["D-", 0.61], ["F", 0.0]].to_json)
      course_model
      expect(@course.score_to_grade(95)).to be_nil
      @course.grading_standard_id = 0
      expect(@course.score_to_grade(1005)).to eql("A")
      expect(@course.score_to_grade(105)).to eql("A")
      expect(@course.score_to_grade(100)).to eql("A")
      expect(@course.score_to_grade(99)).to eql("A")
      expect(@course.score_to_grade(94)).to eql("A")
      expect(@course.score_to_grade(93.999)).to eql("A-")
      expect(@course.score_to_grade(93.001)).to eql("A-")
      expect(@course.score_to_grade(93)).to eql("A-")
      expect(@course.score_to_grade(92.999)).to eql("A-")
      expect(@course.score_to_grade(90)).to eql("A-")
      expect(@course.score_to_grade(89)).to eql("B+")
      expect(@course.score_to_grade(87)).to eql("B+")
      expect(@course.score_to_grade(86)).to eql("B")
      expect(@course.score_to_grade(85)).to eql("B")
      expect(@course.score_to_grade(83)).to eql("B-")
      expect(@course.score_to_grade(80)).to eql("B-")
      expect(@course.score_to_grade(79)).to eql("C+")
      expect(@course.score_to_grade(76)).to eql("C")
      expect(@course.score_to_grade(73)).to eql("C-")
      expect(@course.score_to_grade(71)).to eql("C-")
      expect(@course.score_to_grade(69)).to eql("D+")
      expect(@course.score_to_grade(67)).to eql("D+")
      expect(@course.score_to_grade(66)).to eql("D")
      expect(@course.score_to_grade(65)).to eql("D")
      expect(@course.score_to_grade(62)).to eql("D-")
      expect(@course.score_to_grade(60)).to eql("F")
      expect(@course.score_to_grade(59)).to eql("F")
      expect(@course.score_to_grade(0)).to eql("F")
      expect(@course.score_to_grade(-100)).to eql("F")
    end
  end

  describe "#gradebook_to_csv" do
    before :once do
      course_with_student active_all: true
      teacher_in_course active_all: true
    end

    it "generates gradebook csv" do
      @group = @course.assignment_groups.create!(name: "Some Assignment Group", group_weight: 100)
      @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
      @assignment.grade_student(@student, grade: "10", grader: @teacher)
      @assignment2 = @course.assignments.create!(title: "Some Assignment 2", points_possible: 10, assignment_group: @group)
      @course.recompute_student_scores
      @student.reload
      @course.reload

      csv = GradebookExporter.new(@course, @teacher).to_csv
      expect(csv).not_to be_nil
      rows = CSV.parse(csv, headers: true)
      expect(rows.length).to equal(2)
      expect(rows[0]["Unposted Final Score"]).to eq "(read only)"
      expect(rows[1]["Unposted Final Score"]).to eq "50.00"
      expect(rows[0]["Final Score"]).to eq "(read only)"
      expect(rows[1]["Final Score"]).to eq "50.00"
      expect(rows[0]["Unposted Current Score"]).to eq "(read only)"
      expect(rows[1]["Unposted Current Score"]).to eq "100.00"
      expect(rows[0]["Current Score"]).to eq "(read only)"
      expect(rows[1]["Current Score"]).to eq "100.00"
    end

    it "orders assignments and groups by position" do
      @assignment_group_1, @assignment_group_2 = [@course.assignment_groups.create!(name: "Some Assignment Group 1", group_weight: 100), @course.assignment_groups.create!(name: "Some Assignment Group 2", group_weight: 100)].sort_by(&:id)

      now = Time.now

      g1a1 = @course.assignments.create!(title: "Assignment 01", due_at: now + 1.day, position: 3, assignment_group: @assignment_group_1, points_possible: 10)
      @course.assignments.create!(title: "Assignment 02", due_at: now + 1.day, position: 1, assignment_group: @assignment_group_1, points_possible: 10)
      @course.assignments.create!(title: "Assignment 03", due_at: now + 1.day, position: 2, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 05", due_at: now + 4.days, position: 4, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 04", due_at: now + 5.days, position: 5, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 06", due_at: now + 7.days, position: 6, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 07", due_at: now + 6.days, position: 7, assignment_group: @assignment_group_1)
      g2a1 = @course.assignments.create!(title: "Assignment 08", due_at: now + 8.days, position: 1, assignment_group: @assignment_group_2, points_possible: 10)
      @course.assignments.create!(title: "Assignment 09", due_at: now + 8.days, position: 9, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 10", due_at: now + 8.days, position: 10, assignment_group: @assignment_group_2, points_possible: 10)
      @course.assignments.create!(title: "Assignment 12", due_at: now + 11.days, position: 11, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 14", due_at: nil, position: 14, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 11", due_at: now + 11.days, position: 11, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 13", due_at: now + 11.days, position: 11, assignment_group: @assignment_group_1)
      @course.assignments.create!(title: "Assignment 99", position: 1, assignment_group: @assignment_group_1, submission_types: "not_graded")
      @course.recompute_student_scores
      @student.reload
      @course.reload

      g1a1.grade_student(@student, grade: 10, grader: @teacher)
      g2a1.grade_student(@student, grade: 5, grader: @teacher)

      csv = GradebookExporter.new(@course, @teacher).to_csv
      expect(csv).not_to be_nil
      rows = CSV.parse(csv, headers: true)
      expect(rows.length).to equal(2)
      assignments, groups = [], []
      rows.headers.each do |column|
        assignments << column.sub(/ \([0-9]+\)/, "") if /Assignment \d+/.match?(column)
        groups << column if column.include?("Some Assignment Group")
      end
      expect(assignments).to eq ["Assignment 02", "Assignment 03", "Assignment 01", "Assignment 05", "Assignment 04", "Assignment 06", "Assignment 07", "Assignment 09", "Assignment 11", "Assignment 12", "Assignment 13", "Assignment 14", "Assignment 08", "Assignment 10"]
      expect(groups).to eq [
        "Some Assignment Group 1 Current Points",
        "Some Assignment Group 1 Final Points",
        "Some Assignment Group 1 Current Score",
        "Some Assignment Group 1 Unposted Current Score",
        "Some Assignment Group 1 Final Score",
        "Some Assignment Group 1 Unposted Final Score",
        "Some Assignment Group 2 Current Points",
        "Some Assignment Group 2 Final Points",
        "Some Assignment Group 2 Current Score",
        "Some Assignment Group 2 Unposted Current Score",
        "Some Assignment Group 2 Final Score",
        "Some Assignment Group 2 Unposted Final Score"
      ]

      expect(rows[1]["Some Assignment Group 1 Current Score"]).to eq "100.00"
      expect(rows[1]["Some Assignment Group 1 Final Score"]).to eq "50.00"
      expect(rows[1]["Some Assignment Group 2 Current Score"]).to eq "50.00"
      expect(rows[1]["Some Assignment Group 2 Final Score"]).to eq "25.00"
    end

    it "handles nil assignment due_dates if the group and position are the same" do
      course_with_student(active_all: true)

      assignment_group = @course.assignment_groups.create!(name: "Some Assignment Group 1")

      now = Time.now

      @course.assignments.create!(title: "Assignment 01", due_at: now + 1.day, position: 1, assignment_group:, points_possible: 10)
      @course.assignments.create!(title: "Assignment 02", due_at: nil, position: 1, assignment_group:, points_possible: 10)

      @course.recompute_student_scores
      @student.reload
      @course.reload

      csv = GradebookExporter.new(@course, @teacher).to_csv
      rows = CSV.parse(csv)
      assignments = rows[0].each_with_object([]) do |column, collection|
        collection << column.sub(/ \([0-9]+\)/, "") if /Assignment \d+/.match?(column)
      end

      expect(csv).not_to be_nil
      # make sure they retain the correct order
      expect(assignments).to eq ["Assignment 01", "Assignment 02"]
    end

    context "sort order" do
      before :once do
        course_with_teacher active_all: true
        _, zed, _ = ["Ned Ned", "Zed Zed", "Aardvark Aardvark"].map do |name|
          student_in_course(name:)
          @student
        end
        zed.update_attribute :sortable_name, "aaaaaa zed"

        test_student_enrollment = student_in_course(name: "Test Student")
        test_student_enrollment.type = "StudentViewEnrollment"
        test_student_enrollment.save!
      end

      it "alphabetizes by sortable name with the test student at the end" do
        csv = GradebookExporter.new(@course, @teacher).to_csv
        rows = CSV.parse(csv)
        expect([rows[2][0],
                rows[3][0],
                rows[4][0],
                rows[5][0]]).to eq ["aaaaaa zed", "Aardvark, Aardvark", "Ned, Ned", "Student, Test"]
      end
    end

    it "marks excused assignments" do
      a = @course.assignments.create! name: "asdf", points_possible: 10
      a.grade_student(@student, grader: @teacher, excuse: true)
      csv = CSV.parse(GradebookExporter.new(@course, @teacher).to_csv)
      _name, _id, _section, _sis_login_id, score, _ = csv[-1]
      expect(score).to eq "EX"
    end

    it "includes all section names in alphabetical order" do
      course_with_teacher(active_all: true)
      sections = []
      students = []
      ["COMPSCI 123 LEC 001", "COMPSCI 123 DIS 101", "COMPSCI 123 DIS 102"].each do |section_name|
        add_section(section_name)
        sections << @course_section
      end
      3.times { |i| students << student_in_section(sections[0], user: user_factory(name: "Student #{i}")) }

      @course.enroll_user(students[0], "StudentEnrollment", section: sections[1], enrollment_state: "active", allow_multiple_enrollments: true)
      @course.enroll_user(students[2], "StudentEnrollment", section: sections[1], enrollment_state: "active", allow_multiple_enrollments: true)
      @course.enroll_user(students[2], "StudentEnrollment", section: sections[2], enrollment_state: "active", allow_multiple_enrollments: true)

      csv = GradebookExporter.new(@course, @teacher).to_csv
      expect(csv).not_to be_nil
      rows = CSV.parse(csv)
      expect(rows.length).to equal(5)
      expect(rows[2][3]).to eq "COMPSCI 123 DIS 101 and COMPSCI 123 LEC 001"
      expect(rows[3][3]).to eq "COMPSCI 123 LEC 001"
      expect(rows[4][3]).to eq "COMPSCI 123 DIS 101, COMPSCI 123 DIS 102, and COMPSCI 123 LEC 001"
    end

    it "generates csv with final grade if enabled" do
      course_with_student(active_all: true)
      @course.grading_standard_id = 0
      @course.save!
      @group = @course.assignment_groups.create!(name: "Some Assignment Group", group_weight: 100)
      @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
      @assignment.grade_student(@student, grade: "10", grader: @teacher)
      @assignment2 = @course.assignments.create!(title: "Some Assignment 2", points_possible: 10, assignment_group: @group)
      @assignment2.grade_student(@student, grade: "8", grader: @teacher)
      @course.recompute_student_scores
      @student.reload
      @course.reload

      csv = GradebookExporter.new(@course, @teacher).to_csv
      expect(csv).not_to be_nil
      rows = CSV.parse(csv, headers: true)
      expect(rows.length).to equal(2)
      expect(rows[0]["Unposted Final Grade"]).to eq "(read only)"
      expect(rows[1]["Unposted Final Grade"]).to eq "A-"
      expect(rows[0]["Final Grade"]).to eq "(read only)"
      expect(rows[1]["Final Grade"]).to eq "A-"
      expect(rows[0]["Unposted Current Grade"]).to eq "(read only)"
      expect(rows[1]["Unposted Current Grade"]).to eq "A-"
      expect(rows[0]["Current Grade"]).to eq "(read only)"
      expect(rows[1]["Current Grade"]).to eq "A-"
      expect(rows[0]["Unposted Final Score"]).to eq "(read only)"
      expect(rows[1]["Unposted Final Score"]).to eq "90.00"
      expect(rows[0]["Final Score"]).to eq "(read only)"
      expect(rows[1]["Final Score"]).to eq "90.00"
      expect(rows[0]["Unposted Current Score"]).to eq "(read only)"
      expect(rows[1]["Unposted Current Score"]).to eq "90.00"
      expect(rows[0]["Current Score"]).to eq "(read only)"
      expect(rows[1]["Current Score"]).to eq "90.00"
    end

    describe "sis_ids" do
      before(:once) do
        @account = Account.create!(name: "A new root")
        course_factory(active_all: true, account: @account)
        @user1 = user_with_managed_pseudonym(active_all: true,
                                             name: "Brian",
                                             username: "brianp@instructure.com",
                                             account: @account,
                                             sis_user_id: "SISUSERID",
                                             integration_id: "int1")
        student_in_course(user: @user1)
        @user2 = user_with_pseudonym(active_all: true, name: "Cody", username: "cody@instructure.com", account: @account)
        student_in_course(user: @user2)
        @user3 = user_factory(active_all: true, name: "JT")
        student_in_course(user: @user3)
        @group = @course.assignment_groups.create!(name: "Some Assignment Group", group_weight: 100)
        @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
        @assignment.grade_student(@user1, grade: "10", grader: @teacher)
        @assignment.grade_student(@user2, grade: "9", grader: @teacher)
        @assignment.grade_student(@user3, grade: "9", grader: @teacher)
        @assignment2 = @course.assignments.create!(title: "Some Assignment 2", points_possible: 10, assignment_group: @group)
        @course.recompute_student_scores
        @course.reload
      end

      it "includes sis ids if enabled" do
        csv = GradebookExporter.new(@course, @teacher, include_sis_id: true).to_csv
        expect(csv).not_to be_nil
        rows = CSV.parse(csv)
        expect(rows.length).to eq 5
        expect(rows.first.length).to eq 19
        expect(rows[0][1]).to eq "ID"
        expect(rows[0][2]).to eq "SIS User ID"
        expect(rows[0][3]).to eq "SIS Login ID"
        expect(rows[0][4]).to eq "Section"
        expect(rows[1][2]).to be_nil
        expect(rows[1][3]).to be_nil
        expect(rows[1][4]).to be_nil
        expect(rows[1][-1]).to eq "(read only)"
        expect(rows[2][1]).to eq @user1.id.to_s
        expect(rows[2][2]).to eq "SISUSERID"
        expect(rows[2][3]).to eq @user1.pseudonym.unique_id
        expect(rows[3][1]).to eq @user2.id.to_s
        expect(rows[3][2]).to be_nil
        expect(rows[3][3]).to eq @user2.pseudonym.unique_id
        expect(rows[4][1]).to eq @user3.id.to_s
        expect(rows[4][2]).to be_nil
        expect(rows[4][3]).to be_nil
      end

      it "includes integration ids if enabled" do
        @account.settings[:include_integration_ids_in_gradebook_exports] = true
        @account.save!
        csv = GradebookExporter.new(@course, @teacher, include_sis_id: true).to_csv
        rows = CSV.parse(csv)
        expect(rows.first.length).to eq 20
        expect(rows[0][1]).to eq "ID"
        expect(rows[0][2]).to eq "SIS User ID"
        expect(rows[0][3]).to eq "SIS Login ID"
        expect(rows[0][4]).to eq "Integration ID"
        expect(rows[2][1]).to eq @user1.id.to_s
        expect(rows[2][2]).to eq "SISUSERID"
        expect(rows[2][4]).to eq "int1"
      end
    end

    it "includes primary domain if a trust exists" do
      course_factory(active_all: true)
      @user1 = user_with_pseudonym(active_all: true, name: "Brian", username: "brianp@instructure.com")
      student_in_course(user: @user1)
      account2 = account_model
      @user2 = user_with_pseudonym(active_all: true, name: "Cody", username: "cody@instructure.com", account: account2)
      student_in_course(user: @user2)
      @user3 = user_factory(active_all: true, name: "JT")
      student_in_course(user: @user3)
      @user1.pseudonym.sis_user_id = "SISUSERID"
      @user1.pseudonym.save!
      @user2.pseudonym.sis_user_id = "SISUSERID"
      @user2.pseudonym.save!
      @course.reload
      allow(@course.root_account).to receive(:trust_exists?).and_return(true)
      allow_any_instantiation_of(@course.root_account).to receive(:trusted_account_ids).and_return([account2.id])
      allow_any_instantiation_of(@user2.pseudonyms.first).to receive(:works_for_account?).and_return(true)
      expect(HostUrl).to receive(:context_host).with(@course.root_account).and_return("school1")
      expect(HostUrl).to receive(:context_host).with(account2).and_return("school2")

      csv = GradebookExporter.new(@course, @teacher, include_sis_id: true).to_csv
      expect(csv).not_to be_nil
      rows = CSV.parse(csv)
      expect(rows.length).to eq 5
      expect(rows[0][1]).to eq "ID"
      expect(rows[0][2]).to eq "SIS User ID"
      expect(rows[0][3]).to eq "SIS Login ID"
      expect(rows[0][4]).to eq "Root Account"
      expect(rows[0][5]).to eq "Section"
      expect(rows[1][2]).to be_nil
      expect(rows[1][3]).to be_nil
      expect(rows[1][4]).to be_nil
      expect(rows[1][5]).to be_nil
      expect(rows[2][1]).to eq @user1.id.to_s
      expect(rows[2][2]).to eq "SISUSERID"
      expect(rows[2][3]).to eq @user1.pseudonym.unique_id
      expect(rows[2][4]).to eq "school1"
      expect(rows[3][1]).to eq @user2.id.to_s
      expect(rows[3][2]).to eq "SISUSERID"
      expect(rows[3][3]).to eq @user2.pseudonym.unique_id
      expect(rows[3][4]).to eq "school2"
      expect(rows[4][1]).to eq @user3.id.to_s
      expect(rows[4][2]).to be_nil
      expect(rows[4][3]).to be_nil
      expect(rows[4][4]).to be_nil
    end

    it "can include concluded enrollments" do
      e = course_with_student active_all: true
      e.update_attribute :workflow_state, "completed"

      expect(GradebookExporter.new(@course, @teacher).to_csv).not_to include @student.name

      @teacher.preferences[:gradebook_settings] =
        { @course.id =>
          {
            "show_inactive_enrollments" => "false",
            "show_concluded_enrollments" => "true"
          } }
      @teacher.save!
      expect(GradebookExporter.new(@course, @teacher).to_csv).to include @student.name
    end

    context "accumulated points" do
      before :once do
        a = @course.assignments.create! title: "Blah", points_possible: 10
        a.grade_student @student, grade: 8, grader: @teacher
      end

      it "includes points for unweighted courses" do
        csv = CSV.parse(GradebookExporter.new(@course, @teacher).to_csv, headers: true)
        expect(csv[0]["Assignments Current Points"]).to eq "(read only)"
        expect(csv[1]["Assignments Current Points"]).to eq "8.00"
        expect(csv[0]["Assignments Final Points"]).to eq "(read only)"
        expect(csv[1]["Assignments Final Points"]).to eq "8.00"
        expect(csv[0]["Current Points"]).to eq "(read only)"
        expect(csv[1]["Current Points"]).to eq "8.00"
        expect(csv[0]["Final Points"]).to eq "(read only)"
        expect(csv[1]["Final Points"]).to eq "8.00"
      end

      it "doesn't include points for weighted courses" do
        @course.update_attribute(:group_weighting_scheme, "percent")
        csv = CSV.parse(GradebookExporter.new(@course, @teacher).to_csv)
        expect(csv[0][-8]).not_to eq "Assignments Current Points"
        expect(csv[0][-7]).not_to eq "Assignments Final Points"
        expect(csv[0][-4]).not_to eq "Current Points"
        expect(csv[0][-3]).not_to eq "Final Points"
      end
    end

    it "only includes students once" do
      # students might have multiple enrollments in a course
      course_factory(active_all: true)
      @user1 = user_with_pseudonym(active_all: true, name: "Brian", username: "brianp@instructure.com")
      student_in_course(user: @user1)
      @user2 = user_with_pseudonym(active_all: true, name: "Cody", username: "cody@instructure.com")
      student_in_course(user: @user2)
      @s2 = @course.course_sections.create!(name: "section2")
      StudentEnrollment.create!(user: @user1, course: @course, course_section: @s2)
      @course.reload
      csv = GradebookExporter.new(@course, @teacher, include_sis_id: true).to_csv
      rows = CSV.parse(csv)
      expect(rows.length).to eq 4
    end

    it "includes manual posting if any assignments are manually-posted" do
      course_factory(active_all: true)
      @user1 = user_with_pseudonym(active_all: true, name: "Brian", username: "brianp@instructure.com")
      student_in_course(user: @user1)
      @user2 = user_with_pseudonym(active_all: true, name: "Cody", username: "cody@instructure.com")
      student_in_course(user: @user2)
      @user3 = user_factory(active_all: true, name: "JT")
      student_in_course(user: @user3)
      @user1.pseudonym.sis_user_id = "SISUSERID"
      @user1.pseudonym.save!
      @group = @course.assignment_groups.create!(name: "Some Assignment Group", group_weight: 100)
      @assignment = @course.assignments.create!(title: "Some Assignment", points_possible: 10, assignment_group: @group)
      @assignment.ensure_post_policy(post_manually: true)
      @assignment.grade_student(@user1, grade: "10", grader: @teacher)
      @assignment.grade_student(@user2, grade: "9", grader: @teacher)
      @assignment.grade_student(@user3, grade: "9", grader: @teacher)
      @assignment2 = @course.assignments.create!(title: "Some Assignment 2", points_possible: 10, assignment_group: @group)
      @assignment2.ensure_post_policy(post_manually: false)
      @course.recompute_student_scores
      @course.reload

      csv = GradebookExporter.new(@course, @teacher, include_sis_id: true).to_csv
      expect(csv).not_to be_nil
      rows = CSV.parse(csv)
      expect(rows.length).to eq 6
      expect(rows[0][1]).to eq "ID"
      expect(rows[0][2]).to eq "SIS User ID"
      expect(rows[0][3]).to eq "SIS Login ID"
      expect(rows[0][4]).to eq "Section"
      expect(rows[1][0]).to be_nil
      expect(rows[1][5]).to eq "Manual Posting"
      expect(rows[1][6]).to be_nil
      expect(rows[2][2]).to be_nil
      expect(rows[2][3]).to be_nil
      expect(rows[2][4]).to be_nil
      expect(rows[2][-1]).to eq "(read only)"
      expect(rows[3][1]).to eq @user1.id.to_s
      expect(rows[3][2]).to eq "SISUSERID"
      expect(rows[3][3]).to eq @user1.pseudonym.unique_id
      expect(rows[4][1]).to eq @user2.id.to_s
      expect(rows[4][2]).to be_nil
      expect(rows[4][3]).to eq @user2.pseudonym.unique_id
      expect(rows[5][1]).to eq @user3.id.to_s
      expect(rows[5][2]).to be_nil
      expect(rows[5][3]).to be_nil
    end

    it "only includes students from the appropriate section for a section limited teacher" do
      course_factory(active_all: true)
      teacher_in_course(active_all: true)
      @teacher.enrollments.first.update_attribute(:limit_privileges_to_course_section, true)
      @section = @course.course_sections.create!(name: "section 2")
      @user1 = user_with_pseudonym(active_all: true, name: "Brian", username: "brianp@instructure.com")
      @section.enroll_user(@user1, "StudentEnrollment", "active")
      @user2 = user_with_pseudonym(active_all: true, name: "Jeremy", username: "jeremy@instructure.com")
      @course.enroll_student(@user2)

      csv = GradebookExporter.new(@course, @teacher).to_csv
      expect(csv).not_to be_nil
      rows = CSV.parse(csv)
      # two header rows, and one student row
      expect(rows.length).to eq 3
      expect(rows[2][1]).to eq @user2.id.to_s
    end

    it "shows gpa_scale grades instead of points" do
      a = @course.assignments.create! grading_type: "gpa_scale",
                                      points_possible: 10,
                                      title: "blah"
      a.publish
      a.grade_student(@student, grade: "C", grader: @teacher)
      rows = CSV.parse(GradebookExporter.new(@course, @teacher).to_csv)
      expect(rows[2][4]).to eql "C"
    end

    context "differentiated assignments" do
      def setup_DA
        @course_section = @course.course_sections.create
        user_attrs = [{ name: "student1" }, { name: "student2" }, { name: "student3" }]
        @student1, @student2, @student3 = create_users(user_attrs, return_type: :record)
        @assignment = @course.assignments.create!(title: "a1", only_visible_to_overrides: true)
        @course.enroll_student(@student3, enrollment_state: "active")
        @section = @course.course_sections.create!(name: "section1")
        @section2 = @course.course_sections.create!(name: "section2")
        student_in_section(@section, user: @student1)
        student_in_section(@section2, user: @student2)
        create_section_override_for_assignment(@assignment, { course_section: @section })
        @assignment2 = @course.assignments.create!(title: "a2", only_visible_to_overrides: true)
        create_section_override_for_assignment(@assignment2, { course_section: @section2 })
        @course.reload
      end

      before :once do
        course_with_teacher(active_all: true)
        setup_DA
        @assignment.grade_student(@student1, grade: "3", grader: @teacher)
        @assignment2.grade_student(@student2, grade: "3", grader: @teacher)
      end

      it "inserts N/A for non-visible assignments" do
        csv = GradebookExporter.new(@course, @teacher).to_csv
        expect(csv).not_to be_nil
        rows = CSV.parse(csv)
        expect(rows[2][4]).to eq "3.00"
        expect(rows[2][5]).to eq "N/A"

        expect(rows[3][4]).to eq "N/A"
        expect(rows[3][5]).to eq "3.00"

        expect(rows[4][4]).to eq "N/A"
        expect(rows[4][5]).to eq "N/A"
      end
    end
  end

  describe "#gradebook_to_csv_in_background" do
    context "sharding" do
      specs_require_sharding

      it "works for cross-shard users for courses on birth shard" do
        s3_storage!

        @shard1.activate do
          @shard1_user = user_factory(active_all: true)
        end

        Shard.default.activate do
          student_in_course(active_all: true)
          @attachment_id = @course.gradebook_to_csv_in_background("asdf", @shard1_user)[:attachment_id]
        end

        @shard1.activate do
          expect do
            Attachment.find(@attachment_id).public_download_url
          end.not_to raise_error
        end
      end
    end

    it "create_attachment uses inst-fs if inst-fs is enabled" do
      @uuid = "1234-abcd"
      allow(InstFS).to receive_messages(direct_upload: @uuid, enabled?: true)
      @user = user_factory(active_all: true)
      student_in_course(active_all: true)

      attachment = @user.attachments.build
      attachment.content_type = "text/csv"
      attachment.file_state = "hidden"
      attachment.filename = "exported file"
      attachment.save!

      @course.create_attachment(attachment, "some, csv, data, up, in, here")
      expect(attachment.instfs_uuid).to eq(@uuid)
    end
  end

  describe "#update_account_associations" do
    it "updates account associations correctly" do
      account1 = Account.create!(name: "first")
      account2 = Account.create!(name: "second")

      @c = Course.create!(account: account1)
      expect(@c.associated_accounts.length).to be(1)
      expect(@c.associated_accounts.first).to eql(account1)

      @c.account = account2
      @c.save!
      @c.reload
      expect(@c.associated_accounts.length).to be(1)
      expect(@c.associated_accounts.first).to eql(account2)
    end

    it "acts like it's associated to its account and root account, even if associations are busted" do
      account1 = Account.default.sub_accounts.create!
      c = account1.courses.create!
      c.course_account_associations.scope.delete_all
      expect(c.associated_accounts).to eq [account1, Account.default]
    end

    it "is reentrant" do
      Course.skip_updating_account_associations do
        Course.skip_updating_account_associations { nil }
        expect(Course.skip_updating_account_associations?).to be_truthy
      end
    end
  end

  describe "#tabs_available" do
    context "teachers" do
      before :once do
        course_with_teacher(active_all: true)
      end

      let_once(:default_tab_ids) { Course.default_tabs.pluck(:id) }

      describe "TAB_CONFERENCES" do
        context "when WebConferences are enabled" do
          before do
            allow(WebConference).to receive(:plugins).and_return(
              [
                web_conference_plugin_mock("big_blue_button", { domain: "bbb.instructure.com", secret_dec: "secret" }),
                web_conference_plugin_mock("wimba", { domain: "wimba.test" }),
                web_conference_plugin_mock("broken_plugin", { foor: :bar })
              ]
            )
          end

          it "returns the plugin names" do
            tabs = @course.tabs_available(@user)
            expect(tabs.find { |t| t[:css_class] == "conferences" }[:label]).to eq("Big blue button Wimba")
          end
        end

        context "when WebConferences are not enabled" do
          it "returns Conferences" do
            tabs = @course.tabs_available(@user)
            expect(tabs.find { |t| t[:css_class] == "conferences" }[:label]).to eq("Conferences")
          end
        end
      end

      describe "TAB_COURSE_PACES" do
        it "is included when course paces is enabled" do
          @course.account.enable_feature!(:course_paces)
          @course.enable_course_paces = true
          @course.save!
          tabs = @course.tabs_available(@user).pluck(:id)
          expect(tabs).to include(Course::TAB_COURSE_PACES)
        end

        it "is not included if the flag is off" do
          @course.account.disable_feature!(:course_paces)
          @course.enable_course_paces = true
          @course.save!
          tabs = @course.tabs_available(@user).pluck(:id)
          expect(tabs).not_to include(Course::TAB_COURSE_PACES)
        end

        it "is not included if the course has it disabled" do
          @course.account.enable_feature!(:course_paces)
          @course.enable_course_paces = false
          @course.save!
          tabs = @course.tabs_available(@user).pluck(:id)
          expect(tabs).not_to include(Course::TAB_COURSE_PACES)
        end
      end

      it "returns the defaults if nothing specified" do
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to eql(default_tab_ids)
        expect(tab_ids.length).to eql(default_tab_ids.length)
      end

      it "returns K-6 tabs if feature flag is enabled for teachers" do
        @course.enable_feature!(:canvas_k6_theme)
        tabs = @course.tabs_available(@user)
        expect(tabs.count { |t| !t[:hidden] }).to eq 5
        expect(tabs.count { |t| t[:hidden] }).to eq 12
      ensure
        @course.disable_feature!(:canvas_k6_theme)
      end

      it "defaults tab configuration to an empty array" do
        course = Course.new
        expect(course.tab_configuration).to eq []
      end

      it "overwrites the order of tabs if configured" do
        @course.tab_configuration = [{ id: Course::TAB_COLLABORATIONS }]
        available_tabs = @course.tabs_available(@user).pluck(:id)
        custom_tabs    = @course.tab_configuration.pluck(:id)
        expected_tabs  = (custom_tabs + default_tab_ids).uniq
        # Home tab always comes first
        home_tab = default_tab_ids[0]
        expected_tabs.insert(0, expected_tabs.delete(home_tab))

        expect(available_tabs).to        eq expected_tabs
        expect(available_tabs.length).to eq default_tab_ids.length
      end

      it "does not blow up if somehow nils got in there" do
        course = Course.new
        course.tab_configuration = [{ "id" => 1 }, nil]
        expect(course.tab_configuration).to eq [{ "id" => 1 }]
      end

      context "when a tool tab is part of the tab configuration list" do
        before do
          @tool = @course.context_external_tools.create!(name: "a", domain: "example.com", consumer_key: "key", shared_secret: "secret")
          @tool.course_navigation = {
            "canvas_icon_class" => "test-icon",
            "icon_url" => "https://example.com/a.png",
            "text" => "Test Tool",
            "windowTarget" => "_blank",
            "url" => "https://example.com/launch"
          }
          @tool.save!
          @tab_id = "context_external_tool_#{@tool.id}"

          @course.tab_configuration = [{ "id" => @tab_id }]
        end

        it "does not omit the target attribute for an external tool tab that is part of the tab configuration list" do
          tab = @course.tabs_available(@user).find { |t| t[:id] == @tab_id }
          expect(tab[:target]).to eq("_blank")
        end

        context "when the course is on a different shard than the currently activated shard" do
          specs_require_sharding

          it "matches the tool tab with the tab in the tab configuration list" do
            @shard2.activate do
              tab = @course.tabs_available(@user).find { |t| t[:id] == @tab_id }
              expect(tab[:target]).to eq("_blank")
            end
          end
        end
      end

      it "removes ids for tabs not in the default list" do
        @course.tab_configuration = [{ "id" => 912 }]
        expect(@course.tabs_available(@user).pluck(:id)).not_to include(912)
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to eql(default_tab_ids)
        expect(tab_ids.length).to be > 0
        expect(@course.tabs_available(@user).filter_map { |t| t[:label] }.length).to eql(tab_ids.length)
      end

      it "handles hidden_unused correctly for discussions" do
        tabs = @course.uncached_tabs_available(@teacher, include_hidden_unused: true)
        dtab = tabs.detect { |t| t[:id] == Course::TAB_DISCUSSIONS }
        expect(dtab[:hidden_unused]).to be_falsey

        @course.allow_student_discussion_topics = false
        tabs = @course.uncached_tabs_available(@teacher, include_hidden_unused: true)
        dtab = tabs.detect { |t| t[:id] == Course::TAB_DISCUSSIONS }
        expect(dtab[:hidden_unused]).to be_truthy

        @course.allow_student_discussion_topics = true
        discussion_topic_model
        tabs = @course.uncached_tabs_available(@teacher, include_hidden_unused: true)
        dtab = tabs.detect { |t| t[:id] == Course::TAB_DISCUSSIONS }
        expect(dtab[:hidden_unused]).to be_falsey
      end

      it "does not hide tabs for completed teacher enrollments" do
        @user.enrollments.where(course_id: @course).first.complete!
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to eql(default_tab_ids)
      end

      it "does not include Announcements without read_announcements rights" do
        @course.account.role_overrides.create!(role: teacher_role, permission: "read_announcements", enabled: false)
        tab_ids = @course.uncached_tabs_available(@teacher, include_hidden_unused: true).pluck(:id)
        expect(tab_ids).to_not include(Course::TAB_ANNOUNCEMENTS)
      end

      it "shows people tab with granular permissions if hidden" do
        @course.root_account.enable_feature!(:granular_permissions_manage_users)
        @course.tab_configuration = [{
          id: Course::TAB_PEOPLE,
          label: "People",
          css_class: "people",
          href: :course_users_path,
          hidden: true
        }]
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to include(Course::TAB_PEOPLE)
      end

      it "enables the home tab and puts it first if it was hidden" do
        @course.tab_configuration = [
          { id: Course::TAB_PEOPLE },
          { id: Course::TAB_ASSIGNMENTS },
          { id: Course::TAB_HOME, hidden: true }
        ]
        available_tabs = @course.tabs_available(@user)
        expect(available_tabs.pluck(:id)[0]).to eq(Course::TAB_HOME)
        expect(available_tabs.select { |t| t[:hidden] }).to be_empty
      end

      it "includes item banks tab for active external tools" do
        @course.context_external_tools.create!(
          url: "http://example.com/ims/lti",
          consumer_key: "asdf",
          shared_secret: "hjkl",
          name: "external tool 1",
          course_navigation: {
            text: "Item Banks",
            url: "http://example.com/ims/lti",
            default: false,
          }
        )

        tabs = @course.tabs_available(@user, include_external: true).pluck(:label)

        expect(tabs).to include("Item Banks")
      end

      describe "with canvas_for_elementary account setting on" do
        context "homeroom course" do
          before :once do
            toggle_k5_setting(@course.account)
            @course.homeroom_course = true
            @course.save!
          end

          it "hides most tabs for homeroom courses" do
            tab_ids = @course.tabs_available(@user).pluck(:id)
            expect(tab_ids).to eq [Course::TAB_ANNOUNCEMENTS, Course::TAB_SYLLABUS, Course::TAB_PEOPLE, Course::TAB_FILES, Course::TAB_SETTINGS]
          end

          it "renames the syllabus tab to important info" do
            syllabus_tab = @course.tabs_available(@user).find { |t| t[:id] == Course::TAB_SYLLABUS }
            expect(syllabus_tab[:label]).to eq("Important Info")
          end

          it "hides external tools in nav" do
            @course.context_external_tools.create!(
              url: "http://example.com/ims/lti",
              consumer_key: "asdf",
              shared_secret: "hjkl",
              name: "external tool 1",
              course_navigation: {
                text: "blah",
                url: "http://example.com/ims/lti",
                default: false,
              }
            )
            @course.tab_configuration = [{ id: Course::TAB_ANNOUNCEMENTS }, { id: "context_external_tool_8" }]
            tab_ids = @course.tabs_available(@user).pluck(:id)
            expect(tab_ids).to eq [Course::TAB_ANNOUNCEMENTS, Course::TAB_SYLLABUS, Course::TAB_PEOPLE, Course::TAB_FILES, Course::TAB_SETTINGS]
          end
        end

        context "subject course" do
          before :once do
            toggle_k5_setting(@course.account)
          end

          it "returns default course tabs without home if course_subject_tabs option is not passed" do
            course_elementary_nav_tabs = default_tab_ids.reject { |id| id == Course::TAB_HOME }
            length = course_elementary_nav_tabs.length
            tab_ids = @course.tabs_available(@user).pluck(:id)
            expect(tab_ids).to eql(course_elementary_nav_tabs)
            expect(tab_ids.length).to eql(length)
          end

          it "renames the syllabus tab to important info" do
            syllabus_tab = @course.tabs_available(@user).find { |t| t[:id] == Course::TAB_SYLLABUS }
            expect(syllabus_tab[:label]).to eq("Important Info")
          end

          it "does not include manually-hidden external tools" do
            @course.context_external_tools.create!(
              url: "http://example.com/1",
              consumer_key: "key",
              shared_secret: "abcd",
              name: "visible tool",
              course_navigation: {
                text: "visible tool",
                url: "http://example.com/1",
                default: false
              }
            )
            hidden_tool = @course.context_external_tools.create!(
              url: "http://example.com/2",
              consumer_key: "key",
              shared_secret: "abcd",
              name: "hidden tool",
              course_navigation: {
                text: "hidden tool",
                url: "http://example.com/2",
                default: false
              }
            )

            @course.tab_configuration = [{ "id" => hidden_tool.asset_string, "hidden" => true }]
            @course.save!

            tabs = @course.tabs_available(@user, include_external: true).pluck(:label)
            expect(tabs).to include("visible tool")
            expect(tabs).not_to include("hidden tool")
          end

          context "with course_subject_tabs option" do
            it "returns subject tabs only by default" do
              length = Course.course_subject_tabs.length
              tab_ids = @course.tabs_available(@user, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).to eql(Course.course_subject_tabs.pluck(:id))
              expect(tab_ids.length).to eql(length)
            end

            it "respects saved tab configuration ordering" do
              @course.tab_configuration = [
                { id: Course::TAB_HOME },
                { id: Course::TAB_ANNOUNCEMENTS },
                { id: Course::TAB_MODULES },
                { id: Course::TAB_GRADES },
                { id: Course::TAB_SETTINGS },
                { id: Course::TAB_GROUPS },
              ]
              available_tabs = @course.tabs_available(@user, course_subject_tabs: true).pluck(:id)
              expected_tabs = [
                Course::TAB_HOME,
                Course::TAB_SCHEDULE,
                Course::TAB_MODULES,
                Course::TAB_GRADES,
                Course::TAB_GROUPS
              ]

              expect(available_tabs).to eq expected_tabs
            end

            it "always puts external tools last" do
              tools = []
              2.times do |n|
                tools << @course.context_external_tools.create!(
                  url: "http://example.com/ims/lti",
                  consumer_key: "asdf",
                  shared_secret: "hjkl",
                  name: "external tool #{n + 1}",
                  course_navigation: {
                    text: "blah",
                    url: "http://example.com/ims/lti",
                    default: false,
                  }
                )
              end
              t1, t2 = tools
              @course.tab_configuration = [
                { id: Course::TAB_HOME },
                { id: t1.asset_string },
                { id: Course::TAB_ANNOUNCEMENTS, hidden: true },
                { id: t2.asset_string, hidden: true }
              ]
              available_tabs = @course.tabs_available(@user, course_subject_tabs: true, include_external: true, for_reordering: true)
              expected_tab_ids = Course.course_subject_tabs.pluck(:id) + [t1.asset_string, t2.asset_string]
              expect(available_tabs.pluck(:id)).to eql(expected_tab_ids)
            end

            it "includes modules tab even if there's no modules" do
              course_with_student_logged_in(active_all: true)
              tab_ids = @course.tabs_available(@student, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).to eq [Course::TAB_HOME, Course::TAB_SCHEDULE, Course::TAB_MODULES, Course::TAB_GRADES]
            end

            it "includes groups if the user is a student and there are active groups" do
              course_with_student_logged_in(active_all: true)
              @course.groups.create!
              tab_ids = @course.tabs_available(@student, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).to include Course::TAB_GROUPS
            end

            it "doesn't include groups if the user is a student and there are no active groups" do
              course_with_student_logged_in(active_all: true)
              tab_ids = @course.tabs_available(@student, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).not_to include Course::TAB_GROUPS
            end

            it "includes groups if the user is a teacher, even if there are no active groups" do
              tab_ids = @course.tabs_available(@teacher, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).to include Course::TAB_GROUPS
            end

            it "places groups after external items when it is not re-ordered" do
              @course.context_external_tools.create!(name: "bob",
                                                     consumer_key: "🔑",
                                                     shared_secret: "🤫",
                                                     domain: "example.com",
                                                     course_navigation: { text: "Blah", url: "https://google.com" })
              last_tab_id = @course.tabs_available(@user, course_subject_tabs: true, include_external: true).last[:id]
              expect(last_tab_id).to equal Course::TAB_GROUPS
            end

            it "does not place groups after external items when it has been re-ordered" do
              @course.context_external_tools.create!(name: "bob",
                                                     consumer_key: "🔑",
                                                     shared_secret: "🤫",
                                                     domain: "example.com",
                                                     course_navigation: { text: "Blah", url: "https://google.com" })
              @course.tab_configuration = [{ id: Course::TAB_GROUPS }]
              last_tab_id = @course.tabs_available(@user, course_subject_tabs: true, include_external: true).last[:id]
              expect(last_tab_id).to start_with "context_external_tool_"
            end
          end

          context "public k5 subject" do
            before :once do
              @course.update(is_public: true, indexed: true)
              @course.groups.create!
            end

            it "does not show groups tabs without a current user" do
              tab_ids = @course.tabs_available(nil, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).not_to include(Course::TAB_GROUPS)
            end

            it "does not show groups tabs to a user not enrolled in the class" do
              user_factory
              tab_ids = @course.tabs_available(@user, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).not_to include(Course::TAB_GROUPS)
            end

            it "shows the groups tab to an enrolled user" do
              @course.enroll_student(user_factory).accept!
              tab_ids = @course.tabs_available(@user, course_subject_tabs: true).pluck(:id)
              expect(tab_ids).to include(Course::TAB_GROUPS)
            end
          end
        end
      end
    end

    context "students" do
      before do
        course_with_student(active_all: true)
      end

      describe "TAB_COURSE_PACES" do
        it "is not included" do
          @course.account.enable_feature!(:course_paces)
          @course.enable_course_paces = true
          @course.save!
          tabs = @course.tabs_available(@user).pluck(:id)
          expect(tabs).not_to include(Course::TAB_COURSE_PACES)
        end
      end

      it "returns K-6 tabs if feature flag is enabled for students" do
        @course.enable_feature!(:canvas_k6_theme)
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to eq [Course::TAB_HOME, Course::TAB_GRADES]
      ensure
        @course.disable_feature!(:canvas_k6_theme)
      end

      it "hides unused tabs if not an admin" do
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_SETTINGS)
        expect(tab_ids.length).to be > 0
      end

      it "hides people tab with granular permissions if hidden" do
        @course.root_account.enable_feature!(:granular_permissions_manage_users)
        @course.tab_configuration = [{
          id: Course::TAB_PEOPLE,
          label: "People",
          css_class: "people",
          href: :course_users_path,
          hidden: true
        }]
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_PEOPLE)
      end

      it "shows grades tab for students" do
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to include(Course::TAB_GRADES)
      end

      it "includes tabs for active external tools" do
        tools = []
        2.times do |n|
          tools << @course.context_external_tools.create!(
            url: "http://example.com/ims/lti",
            consumer_key: "asdf",
            shared_secret: "hjkl",
            name: "external tool #{n + 1}",
            course_navigation: {
              text: "blah",
              url: "http://example.com/ims/lti",
              default: false,
            }
          )
        end
        t1, t2 = tools

        t2.workflow_state = "deleted"
        t2.save!

        tabs = @course.tabs_available.pluck(:id)

        expect(tabs).to include(t1.asset_string)
        expect(tabs).not_to include(t2.asset_string)
      end

      it "does not include item banks tab for active external tools" do
        @course.context_external_tools.create!(
          url: "http://example.com/ims/lti",
          consumer_key: "asdf",
          shared_secret: "hjkl",
          name: "external tool 1",
          course_navigation: {
            text: "Item Banks",
            url: "http://example.com/ims/lti",
            default: false,
          }
        )

        tabs = @course.tabs_available(@user, include_external: true).pluck(:label)

        expect(tabs).not_to include("Item Banks")
      end

      context "when 'Item Banks' has been added to the course navigation links" do
        let!(:quiz_lti_tool) do
          @course.context_external_tools.create!(
            url: "http://example.com/ims/lti",
            consumer_key: "asdf",
            shared_secret: "hjkl",
            name: "external tool 1",
            course_navigation: {
              text: "Item Banks",
              url: "http://example.com/ims/lti",
              default: false,
            }
          )
        end

        before do
          @course.update!(tab_configuration: [{ id: "context_external_tool_#{quiz_lti_tool.id}" }])
        end

        it "does not make the item banks tab available for students" do
          external_tool_tabs = @course.external_tool_tabs({}, @user).pluck(:label)
          expect(external_tool_tabs).to include("Item Banks")

          available_tabs = @course.tabs_available(@user, include_external: true).pluck(:label)
          expect(available_tabs).not_to include("Item Banks")
        end
      end

      it "sets the target value on the tab if the external tool has a windowTarget" do
        tool = @course.context_external_tools.create!(
          url: "http://example.com/ims/lti",
          consumer_key: "asdf",
          shared_secret: "hjkl",
          name: "external tools",
          course_navigation: {
            text: "blah",
            url: "http://example.com/ims/lti",
            default: false,
          }
        )
        tool.settings[:windowTarget] = "_blank"
        tool.save!
        tabs = @course.tabs_available
        tab = tabs.find { |t| t[:id] == tool.asset_string }
        expect(tab[:target]).to eq "_blank"
      end

      it 'includes in the args "display: borderless" if a target is set' do
        tool = @course.context_external_tools.create!(
          url: "http://example.com/ims/lti",
          consumer_key: "asdf",
          shared_secret: "hjkl",
          name: "external tools",
          course_navigation: {
            text: "blah",
            url: "http://example.com/ims/lti",
            default: false,
          }
        )
        tool.settings[:windowTarget] = "_blank"
        tool.save!
        tabs = @course.tabs_available
        tab = tabs.find { |t| t[:id] == tool.asset_string }
        expect(tab[:args]).to include({ display: "borderless" })
      end

      it 'does not let value other than "_blank" be set for target' do
        tool = @course.context_external_tools.create!(
          url: "http://example.com/ims/lti",
          consumer_key: "asdf",
          shared_secret: "hjkl",
          name: "external tools",
          course_navigation: {
            text: "blah",
            url: "http://example.com/ims/lti",
            default: false,
          }
        )
        tool.settings[:windowTarget] = "parent"
        tool.save!
        tabs = @course.tabs_available
        tab = tabs.find { |t| t[:id] == tool.asset_string }
        expect(tab.keys).not_to include :target
      end

      it "does not include tabs for external tools if opt[:include_external] is false" do
        t1 = @course.context_external_tools.create!(
          url: "http://example.com/ims/lti",
          consumer_key: "asdf",
          shared_secret: "hjkl",
          name: "external tool 1",
          course_navigation: {
            text: "blah",
            url: "http://example.com/ims/lti",
            default: false,
          }
        )

        tabs = @course.tabs_available(nil, include_external: false).pluck(:id)

        expect(tabs).not_to include(t1.asset_string)
      end

      it "includes message handlers if opt[:include_external] is true" do
        mock_tab = {
          id: "1234",
          label: "my_label",
          css_class: "1234",
          href: :launch_path_helper,
          visibility: nil,
          external: true,
          hidden: false,
          args: [1, 2]
        }
        allow(Lti::MessageHandler).to receive(:lti_apps_tabs).and_return([mock_tab])
        expect(@course.tabs_available(nil, include_external: true)).to include(mock_tab)
      end

      # no spec for student homeroom because students should never navigate to the homeroom course
    end

    context "observers" do
      before :once do
        course_with_student(active_all: true)
        @student = @user
        user_factory(active_all: true)
        @oe = @course.enroll_user(@user, "ObserverEnrollment")
        @oe.accept
        @oe.associated_user_id = @student.id
        @oe.save!
        @user.reload
      end

      it "does not show grades tab for observers" do
        @oe.associated_user_id = nil
        @oe.save!
        @user.reload
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_GRADES)
      end

      it "shows grades tab for observers if they are linked to a student" do
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to include(Course::TAB_GRADES)
      end

      it "shows discussion tab for observers by default" do
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to include(Course::TAB_DISCUSSIONS)
      end

      it "does not show discussion tab for observers without read_forum" do
        RoleOverride.create!(context: @course.account,
                             permission: "read_forum",
                             role: observer_role,
                             enabled: false)
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_DISCUSSIONS)
      end

      it "recognizes active_course_level_observers" do
        user = user_with_pseudonym
        observer_enrollment = @course.enroll_user(user, "ObserverEnrollment", enrollment_state: "active")
        @course_level_observer = observer_enrollment.user

        course_observers = @course.active_course_level_observers
        expect(course_observers).to include(@course_level_observer)
        expect(course_observers).to_not include(@oe.user)
      end
    end

    context "a public course" do
      before :once do
        course_factory(active_all: true).update(is_public: true, indexed: true)
        @course.announcements.create!(title: "Title", message: "Message")
        default_group = @course.root_outcome_group
        outcome = @course.created_learning_outcomes.create!(title: "outcome")
        default_group.add_outcome(outcome)
      end

      it "does not show announcements tabs without a current user" do
        tab_ids = @course.tabs_available(nil).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_ANNOUNCEMENTS)
      end

      it "does not show announcements to a user not enrolled in the class" do
        user_factory
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_ANNOUNCEMENTS)
      end

      it "shows the announcements tab to an enrolled user" do
        @course.enroll_student(user_factory).accept!
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to include(Course::TAB_ANNOUNCEMENTS)
      end

      it "does not show outcomes tabs without a current user" do
        tab_ids = @course.tabs_available(nil).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_OUTCOMES)
      end

      it "does not show outcomes to a user not enrolled in the class" do
        user_factory
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).not_to include(Course::TAB_OUTCOMES)
      end

      it "shows the outcomes tab to an enrolled user" do
        @course.enroll_student(user_factory).accept!
        tab_ids = @course.tabs_available(@user).pluck(:id)
        expect(tab_ids).to include(Course::TAB_OUTCOMES)
      end
    end
  end

  context "grade_publishing" do
    before :once do
      @course = Course.new
      @course.root_account_id = Account.default.id
      @course.save!
      @course_section = @course.default_section
    end

    after do
      Course.valid_grade_export_types.delete("test_export")
    end

    context "mocked plugin settings" do
      before do
        @plugin_settings = Canvas::Plugin.find!("grade_export").default_settings.clone
        @plugin = double
        allow(Canvas::Plugin).to receive(:find!).with("grade_export").and_return(@plugin)
        allow(@plugin).to receive(:settings).and_return(@plugin_settings)
      end

      context "grade_publishing_status_translation" do
        it "works with nil statuses and messages" do
          expect(@course.grade_publishing_status_translation(nil, nil)).to eq "Not Synced"
          expect(@course.grade_publishing_status_translation(nil, "hi")).to eq "Not Synced: hi"
          expect(@course.grade_publishing_status_translation("published", nil)).to eq "Synced"
          expect(@course.grade_publishing_status_translation("published", "hi")).to eq "Synced: hi"
        end

        it "works with invalid statuses" do
          expect(@course.grade_publishing_status_translation("bad_status", nil)).to eq "Unknown status, bad_status"
          expect(@course.grade_publishing_status_translation("bad_status", "what what")).to eq(
            "Unknown status, bad_status: what what"
          )
        end

        it "works with empty string statuses and messages" do
          expect(@course.grade_publishing_status_translation("", "")).to eq "Not Synced"
          expect(@course.grade_publishing_status_translation("", "hi")).to eq "Not Synced: hi"
          expect(@course.grade_publishing_status_translation("published", "")).to eq "Synced"
          expect(@course.grade_publishing_status_translation("published", "hi")).to eq "Synced: hi"
        end

        it "works with all known statuses" do
          expect(@course.grade_publishing_status_translation("error", nil)).to eq "Error"
          expect(@course.grade_publishing_status_translation("error", "hi")).to eq "Error: hi"
          expect(@course.grade_publishing_status_translation("unpublished", nil)).to eq "Not Synced"
          expect(@course.grade_publishing_status_translation("unpublished", "hi")).to eq "Not Synced: hi"
          expect(@course.grade_publishing_status_translation("pending", nil)).to eq "Pending"
          expect(@course.grade_publishing_status_translation("pending", "hi")).to eq "Pending: hi"
          expect(@course.grade_publishing_status_translation("publishing", nil)).to eq "Syncing"
          expect(@course.grade_publishing_status_translation("publishing", "hi")).to eq "Syncing: hi"
          expect(@course.grade_publishing_status_translation("published", nil)).to eq "Synced"
          expect(@course.grade_publishing_status_translation("published", "hi")).to eq "Synced: hi"
          expect(@course.grade_publishing_status_translation("unpublishable", nil)).to eq "Unsyncable"
          expect(@course.grade_publishing_status_translation("unpublishable", "hi")).to eq "Unsyncable: hi"
        end
      end

      def make_student_enrollments
        @student_enrollments = create_enrollments(@course, create_users(9), return_type: :record)
        @student_enrollments[0].tap do |enrollment|
          enrollment.grade_publishing_status = "published"
          enrollment.save!
        end
        @student_enrollments[2].tap do |enrollment|
          enrollment.grade_publishing_status = "unpublishable"
          enrollment.save!
        end
        @student_enrollments[1].tap do |enrollment|
          enrollment.grade_publishing_status = "error"
          enrollment.grade_publishing_message = "cause of this reason"
          enrollment.save!
        end
        @student_enrollments[3].tap do |enrollment|
          enrollment.grade_publishing_status = "error"
          enrollment.grade_publishing_message = "cause of that reason"
          enrollment.save!
        end
        @student_enrollments[4].tap do |enrollment|
          enrollment.grade_publishing_status = "unpublishable"
          enrollment.save!
        end
        @student_enrollments[5].tap do |enrollment|
          enrollment.grade_publishing_status = "unpublishable"
          enrollment.save!
        end
        @student_enrollments[6].tap do |enrollment|
          enrollment.workflow_state = "inactive"
          enrollment.save!
        end
        @student_enrollments
      end

      def grade_publishing_user(sis_user_id = "U1")
        @user = user_with_pseudonym
        @pseudonym.account_id = @course.root_account_id
        @pseudonym.sis_user_id = sis_user_id
        @pseudonym.save!
        @user
      end

      context "grade_publishing_statuses" do
        before :once do
          make_student_enrollments
        end

        it "generates enrollments categorized by grade publishing message" do
          messages, overall_status = @course.grade_publishing_statuses
          expect(overall_status).to eq "error"
          expect(messages.count).to eq 5
          expect(messages["Not Synced"].sort_by(&:id)).to eq [
            @student_enrollments[7],
            @student_enrollments[8]
          ].sort_by(&:id)
          expect(messages["Synced"]).to eq [
            @student_enrollments[0]
          ]
          expect(messages["Error: cause of this reason"]).to eq [
            @student_enrollments[1]
          ]
          expect(messages["Error: cause of that reason"]).to eq [
            @student_enrollments[3]
          ]
          expect(messages["Unsyncable"].sort_by(&:id)).to eq [
            @student_enrollments[2],
            @student_enrollments[4],
            @student_enrollments[5]
          ].sort_by(&:id)
        end

        it "figures out the overall status with no enrollments correctly" do
          @course = course_factory
          expect(@course.grade_publishing_statuses).to eq [{}, "unpublished"]
        end

        it "figures out the overall status with invalid enrollment statuses correctly" do
          @student_enrollments.each do |e|
            e.grade_publishing_status = "invalid status"
            e.save!
          end
          messages, overall_status = @course.grade_publishing_statuses
          expect(overall_status).to eq "error"
          expect(messages.count).to eq 3
          expect(messages["Unknown status, invalid status: cause of this reason"]).to eq [@student_enrollments[1]]
          expect(messages["Unknown status, invalid status: cause of that reason"]).to eq [@student_enrollments[3]]
          expect(messages["Unknown status, invalid status"].sort_by(&:id)).to eq [
            @student_enrollments[0],
            @student_enrollments[2],
            @student_enrollments[4],
            @student_enrollments[5],
            @student_enrollments[7],
            @student_enrollments[8]
          ].sort_by(&:id)
        end

        it "falls back to the right overall status" do
          @student_enrollments.each do |e|
            e.grade_publishing_status = "unpublishable"
            e.grade_publishing_message = nil
            e.save!
          end
          expect(@course.reload.grade_publishing_statuses[1]).to eq "unpublishable"
          @student_enrollments[0].tap do |e|
            e.grade_publishing_status = "published"
            e.save!
          end
          expect(@course.reload.grade_publishing_statuses[1]).to eq "published"
          @student_enrollments[1].tap do |e|
            e.grade_publishing_status = "publishing"
            e.save!
          end
          expect(@course.reload.grade_publishing_statuses[1]).to eq "publishing"
          @student_enrollments[2].tap do |e|
            e.grade_publishing_status = "pending"
            e.save!
          end
          expect(@course.reload.grade_publishing_statuses[1]).to eq "pending"
          @student_enrollments[3].tap do |e|
            e.grade_publishing_status = "unpublished"
            e.save!
          end
          expect(@course.reload.grade_publishing_statuses[1]).to eq "unpublished"
          @student_enrollments[4].tap do |e|
            e.grade_publishing_status = "error"
            e.save!
          end
          expect(@course.reload.grade_publishing_statuses[1]).to eq "error"
        end
      end

      context "publish_final_grades" do
        before :once do
          @grade_publishing_user = grade_publishing_user
        end

        it "checks whether or not grade export is enabled - success" do
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, nil).and_return(nil)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @course.publish_final_grades(@user)
        end

        it "checks whether or not grade export is enabled - failure" do
          allow(@plugin).to receive(:enabled?).and_return(false)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          expect { @course.publish_final_grades(@user) }.to raise_error("final grade publishing disabled")
        end

        it "updates all student enrollments with pending and a last update status" do
          @course = course_factory
          make_student_enrollments
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[published error unpublishable error unpublishable unpublishable unpublished unpublished unpublished]
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil, "cause of this reason", nil, "cause of that reason", nil, nil, nil, nil, nil]
          expect(@student_enrollments.map(&:workflow_state)).to eq (["active"] * 6) + ["inactive"] + (["active"] * 2)
          expect(@student_enrollments.map(&:last_publish_attempt_at)).to eq [nil] * 9
          grade_publishing_user("U2")
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, nil).and_return(nil)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @course.publish_final_grades(@user)
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq (["pending"] * 6) + ["unpublished"] + (["pending"] * 2)
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
          expect(@student_enrollments.map(&:workflow_state)).to eq (["active"] * 6) + ["inactive"] + (["active"] * 2)
          @student_enrollments.map(&:last_publish_attempt_at).each_with_index do |time, i|
            if i == 6
              expect(time).to be_nil
            else
              expect(time).to be >= @course.created_at
            end
          end
        end

        it "kicks off the actual grade send" do
          expect(@course).to receive(:delay).and_return(@course)
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, nil)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @course.publish_final_grades(@user)
        end

        it "kicks off the actual grade send for a specific user" do
          make_student_enrollments
          expect(@course).to receive(:delay).and_return(@course)
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, @student_enrollments.first.user_id)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @course.publish_final_grades(@user, @student_enrollments.first.user_id)
          expect(@student_enrollments.first.reload.grade_publishing_status).to eq "pending"
        end

        it "kicks off the timeout when a success timeout is defined and waiting is configured" do
          expect(@course).to receive(:delay).and_return(@course)
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, nil)
          current_time = Time.now.utc
          allow(Time).to receive(:now).and_return(current_time)
          allow(current_time).to receive(:utc).and_return(current_time)
          expect(@course).to receive(:delay).with(run_at: current_time + 1.second).and_return(@course)
          expect(@course).to receive(:expire_pending_grade_publishing_statuses).with(current_time).and_return(nil)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings.merge!({
                                    publish_endpoint: "http://localhost/endpoint",
                                    success_timeout: "1",
                                    wait_for_success: "yes"
                                  })
          @course.publish_final_grades(@user)
        end

        it "does not kick off the timeout when a success timeout is defined and waiting is not configured" do
          expect(@course).to receive(:delay).and_return(@course)
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, nil)
          current_time = Time.now.utc
          allow(Time).to receive(:now).and_return(current_time)
          allow(current_time).to receive(:utc).and_return(current_time)
          expect(@course).not_to receive(:delay)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings.merge!({
                                    publish_endpoint: "http://localhost/endpoint",
                                    success_timeout: "1",
                                    wait_for_success: "no"
                                  })
          @course.publish_final_grades(@user)
        end

        it "does not kick off the timeout when a success timeout is not defined and waiting is not configured" do
          expect(@course).to receive(:delay_if_production).and_return(@course)
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, nil)
          current_time = Time.now.utc
          allow(Time).to receive(:now).and_return(current_time)
          allow(current_time).to receive(:utc).and_return(current_time)
          expect(@course).not_to receive(:delay)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings.merge!({
                                    publish_endpoint: "http://localhost/endpoint",
                                    success_timeout: "",
                                    wait_for_success: "no"
                                  })
          @course.publish_final_grades(@user)
        end

        it "does not kick off the timeout when a success timeout is not defined and waiting is configured" do
          expect(@course).to receive(:delay_if_production).and_return(@course)
          expect(@course).to receive(:send_final_grades_to_endpoint).with(@user, nil)
          current_time = Time.now.utc
          allow(Time).to receive(:now).and_return(current_time)
          allow(current_time).to receive(:utc).and_return(current_time)
          expect(@course).not_to receive(:delay)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings.merge!({
                                    publish_endpoint: "http://localhost/endpoint",
                                    success_timeout: "no",
                                    wait_for_success: "yes"
                                  })
          @course.publish_final_grades(@user)
        end
      end

      context "should_kick_off_grade_publishing_timeout?" do
        it "covers all the necessary cases" do
          @plugin_settings[:success_timeout] = "no"
          @plugin_settings[:wait_for_success] = "yes"
          expect(@course.should_kick_off_grade_publishing_timeout?).to be_falsey
          @plugin_settings[:success_timeout] = ""
          @plugin_settings[:wait_for_success] = "no"
          expect(@course.should_kick_off_grade_publishing_timeout?).to be_falsey
          @plugin_settings[:success_timeout] = "1"
          @plugin_settings[:wait_for_success] = "no"
          expect(@course.should_kick_off_grade_publishing_timeout?).to be_falsey
          @plugin_settings[:success_timeout] = "1"
          @plugin_settings[:wait_for_success] = "yes"
          expect(@course.should_kick_off_grade_publishing_timeout?).to be_truthy
        end
      end

      context "valid_grade_export_types" do
        it "supports instructure_csv" do
          expect(Course.valid_grade_export_types["instructure_csv"][:name]).to eq "Instructure formatted CSV"
          course = double
          enrollments = [double, double]
          publishing_pseudonym = double
          publishing_user = double
          allow(course).to receive(:allow_final_grade_override?).and_return false
          expect(course).to receive(:generate_grade_publishing_csv_output).with(
            enrollments, publishing_user, publishing_pseudonym, include_final_grade_overrides: false
          ).and_return 42
          expect(Course.valid_grade_export_types["instructure_csv"][:callback].call(course,
                                                                                    enrollments,
                                                                                    publishing_user,
                                                                                    publishing_pseudonym)).to eq 42
          expect(Course.valid_grade_export_types["instructure_csv"][:requires_grading_standard]).to be_falsey
          expect(Course.valid_grade_export_types["instructure_csv"][:requires_publishing_pseudonym]).to be_falsey
        end
      end

      context "send_final_grades_to_endpoint" do
        before(:once) do
          make_student_enrollments
          grade_publishing_user
        end

        it "clears the grade publishing message of unpublishable enrollments" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "test_format"
          @ase = @student_enrollments.find_all { |e| e.workflow_state == "active" }
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "test_format" => {
                                                                             callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                                                                               expect(course).to eq @course
                                                                               expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                               expect(publishing_pseudonym).to eq @pseudonym
                                                                               expect(publishing_user).to eq @user
                                                                               [
                                                                                 [[@ase[2].id, @ase[5].id],
                                                                                  "post1",
                                                                                  "test/mime1"],
                                                                                 [[@ase[4].id, @ase[7].id],
                                                                                  "post2",
                                                                                  "test/mime2"]
                                                                               ]
                                                                             end
                                                                           }
                                                                         })
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {})
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {})
          @course.send_final_grades_to_endpoint @user
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[unpublishable unpublishable published unpublishable published published unpublished unpublishable published]
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
        end

        it "tries to publish appropriate enrollments" do
          plugin_settings = Course.valid_grade_export_types["instructure_csv"]
          allow(Course).to receive(:valid_grade_export_types).and_return(plugin_settings.merge({
                                                                                                 "instructure_csv" => { requires_grading_standard: true, requires_publishing_pseudonym: true }
                                                                                               }))
          @course.grading_standard_enabled = true
          @course.save!
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "instructure_csv"
          @checked = false
          allow(Course).to receive(:valid_grade_export_types).and_return(
            {
              "instructure_csv" => {
                callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                  expect(course).to eq @course
                  expect(enrollments.sort_by(&:id)).to eq(@student_enrollments.sort_by(&:id).find_all { |e| e.workflow_state == "active" })
                  expect(publishing_pseudonym).to eq @pseudonym
                  expect(publishing_user).to eq @user
                  @checked = true
                  []
                end
              }
            }
          )
          @course.send_final_grades_to_endpoint @user
          expect(@checked).to be_truthy
        end

        it "tries to publish appropriate enrollments (limited users)" do
          plugin_settings = Course.valid_grade_export_types["instructure_csv"]
          allow(Course).to receive(:valid_grade_export_types).and_return(plugin_settings.merge({
                                                                                                 "instructure_csv" => { requires_grading_standard: true, requires_publishing_pseudonym: true }
                                                                                               }))
          @course.grading_standard_enabled = true
          @course.save!
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "instructure_csv"
          @checked = false
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "instructure_csv" => {
                                                                             callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                                                                               expect(course).to eq @course
                                                                               expect(enrollments).to eq [@student_enrollments.first]
                                                                               expect(publishing_pseudonym).to eq @pseudonym
                                                                               expect(publishing_user).to eq @user
                                                                               @checked = true
                                                                               []
                                                                             end
                                                                           }
                                                                         })
          @course.send_final_grades_to_endpoint @user, @student_enrollments.first.user_id
          expect(@checked).to be_truthy
        end

        it "makes sure grade publishing is enabled" do
          allow(@plugin).to receive(:enabled?).and_return(false)
          expect { @course.send_final_grades_to_endpoint nil }.to raise_error("final grade publishing disabled")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq (["error"] * 6) + ["unpublished"] + (["error"] * 2)
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq (["final grade publishing disabled"] * 6) + [nil] + (["final grade publishing disabled"] * 2)
        end

        it "makes sure an endpoint is defined" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = ""
          expect { @course.send_final_grades_to_endpoint nil }.to raise_error("endpoint undefined")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq (["error"] * 6) + ["unpublished"] + (["error"] * 2)
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq (["endpoint undefined"] * 6) + [nil] + (["endpoint undefined"] * 2)
        end

        it "makes sure the publishing user can publish" do
          plugin_settings = Course.valid_grade_export_types["instructure_csv"]
          allow(Course).to receive(:valid_grade_export_types).and_return(plugin_settings.merge({
                                                                                                 "instructure_csv" => { requires_grading_standard: false, requires_publishing_pseudonym: true }
                                                                                               }))
          @user = user_factory
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          expect { @course.send_final_grades_to_endpoint @user }.to raise_error("publishing disallowed for this publishing user")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq (["error"] * 6) + ["unpublished"] + (["error"] * 2)
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq (["publishing disallowed for this publishing user"] * 6) + [nil] + (["publishing disallowed for this publishing user"] * 2)
        end

        it "makes sure there's a grading standard" do
          plugin_settings = Course.valid_grade_export_types["instructure_csv"]
          allow(Course).to receive(:valid_grade_export_types).and_return(plugin_settings.merge({
                                                                                                 "instructure_csv" => { requires_grading_standard: true, requires_publishing_pseudonym: false }
                                                                                               }))
          @user = user_factory
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          expect { @course.send_final_grades_to_endpoint @user }.to raise_error("grade publishing requires a grading standard")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq (["error"] * 6) + ["unpublished"] + (["error"] * 2)
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq (["grade publishing requires a grading standard"] * 6) + [nil] + (["grade publishing requires a grading standard"] * 2)
        end

        it "makes sure the format type is supported" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "invalid_Format"
          expect { @course.send_final_grades_to_endpoint @user }.to raise_error("unknown format type: invalid_Format")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq (["error"] * 6) + ["unpublished"] + (["error"] * 2)
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq (["unknown format type: invalid_Format"] * 6) + [nil] + (["unknown format type: invalid_Format"] * 2)
        end

        def sample_grade_publishing_request(published_status)
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "test_format"
          @ase = @student_enrollments.find_all { |e| e.workflow_state == "active" }
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "test_format" => {
                                                                             callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                                                                               expect(course).to eq @course
                                                                               expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                               expect(publishing_pseudonym).to eq @pseudonym
                                                                               expect(publishing_user).to eq @user
                                                                               [
                                                                                 [[@ase[1].id, @ase[3].id],
                                                                                  "post1",
                                                                                  "test/mime1"],
                                                                                 [[@ase[4].id, @ase[7].id],
                                                                                  "post2",
                                                                                  "test/mime2"]
                                                                               ]
                                                                             end
                                                                           }
                                                                         })
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {})
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {})
          @course.send_final_grades_to_endpoint @user
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq ["unpublishable", published_status, "unpublishable", published_status, published_status, "unpublishable", "unpublished", "unpublishable", published_status]
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
        end

        it "makes callback's requested posts and mark requested enrollment ids ignored" do
          sample_grade_publishing_request("published")
        end

        it "recomputes final grades" do
          expect(@course).to receive(:recompute_student_scores_without_send_later)
          sample_grade_publishing_request("published")
        end

        it "does not set the status to publishing if a timeout didn't kick off - timeout, wait" do
          @plugin_settings[:success_timeout] = "1"
          @plugin_settings[:wait_for_success] = "yes"
          sample_grade_publishing_request("publishing")
        end

        it "does not set the status to publishing if a timeout didn't kick off - timeout, no wait" do
          @plugin_settings[:success_timeout] = "2"
          @plugin_settings[:wait_for_success] = "false"
          sample_grade_publishing_request("published")
        end

        it "does not set the status to publishing if a timeout didn't kick off - no timeout, wait" do
          @plugin_settings[:success_timeout] = "no"
          @plugin_settings[:wait_for_success] = "yes"
          sample_grade_publishing_request("published")
        end

        it "does not set the status to publishing if a timeout didn't kick off - no timeout, no wait" do
          @plugin_settings[:success_timeout] = "false"
          @plugin_settings[:wait_for_success] = "no"
          sample_grade_publishing_request("published")
        end

        it "tries and make all posts even if one of the postings fails" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "test_format"
          @ase = @student_enrollments.find_all { |e| e.workflow_state == "active" }
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "test_format" => {
                                                                             callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                                                                               expect(course).to eq @course
                                                                               expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                               expect(publishing_pseudonym).to eq @pseudonym
                                                                               expect(publishing_user).to eq @user
                                                                               [
                                                                                 [[@ase[1].id, @ase[3].id],
                                                                                  "post1",
                                                                                  "test/mime1"],
                                                                                 [[@ase[4].id, @ase[7].id],
                                                                                  "post2",
                                                                                  "test/mime2"],
                                                                                 [[@ase[2].id, @ase[0].id],
                                                                                  "post3",
                                                                                  "test/mime3"]
                                                                               ]
                                                                             end
                                                                           }
                                                                         })
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {})
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {}).and_raise("waaah fail")
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post3", "test/mime3", {})
          expect { @course.send_final_grades_to_endpoint(@user) }.to raise_error("waaah fail")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[published published published published error unpublishable unpublished unpublishable error]
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq ([nil] * 4) + ["waaah fail"] + ([nil] * 3) + ["waaah fail"]
        end

        it "tries and make all posts even if two of the postings fail" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "test_format"
          @ase = @student_enrollments.find_all { |e| e.workflow_state == "active" }
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "test_format" => {
                                                                             callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                                                                               expect(course).to eq @course
                                                                               expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                               expect(publishing_pseudonym).to eq @pseudonym
                                                                               expect(publishing_user).to eq @user
                                                                               [
                                                                                 [[@ase[1].id, @ase[3].id],
                                                                                  "post1",
                                                                                  "test/mime1"],
                                                                                 [[@ase[4].id, @ase[7].id],
                                                                                  "post2",
                                                                                  "test/mime2"],
                                                                                 [[@ase[2].id, @ase[0].id],
                                                                                  "post3",
                                                                                  "test/mime3"]
                                                                               ]
                                                                             end
                                                                           }
                                                                         })
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", {}).and_raise("waaah fail")
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {}).and_raise("waaah fail")
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post3", "test/mime3", {})
          expect { @course.send_final_grades_to_endpoint(@user) }.to raise_error("waaah fail")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[published error published error error unpublishable unpublished unpublishable error]
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil, "waaah fail", nil, "waaah fail", "waaah fail", nil, nil, nil, "waaah fail"]
        end

        it "fails gracefully when the posting generator fails" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "test_format"
          @ase = @student_enrollments.find_all { |e| e.workflow_state == "active" }
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "test_format" => {
                                                                             callback: lambda do |*|
                                                                               raise "waaah fail"
                                                                             end
                                                                           }
                                                                         })
          expect { @course.send_final_grades_to_endpoint(@user) }.to raise_error("waaah fail")
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[error error error error error error unpublished error error]
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq (["waaah fail"] * 6) + [nil] + (["waaah fail"] * 2)
        end

        it "passes header parameters to post" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "test_format"
          @ase = @student_enrollments.find_all { |e| e.workflow_state == "active" }
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "test_format" => {
                                                                             callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                                                                               expect(course).to eq @course
                                                                               expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                               expect(publishing_pseudonym).to eq @pseudonym
                                                                               expect(publishing_user).to eq @user
                                                                               [
                                                                                 [[@ase[1].id, @ase[3].id],
                                                                                  "post1",
                                                                                  "test/mime1",
                                                                                  { "header_param" => "header_value" }],
                                                                                 [[@ase[4].id, @ase[5].id],
                                                                                  "post2",
                                                                                  "test/mime2"]
                                                                               ]
                                                                             end
                                                                           }
                                                                         })
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post1", "test/mime1", { "header_param" => "header_value" })
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "post2", "test/mime2", {})
          @course.send_final_grades_to_endpoint(@user)
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[unpublishable published unpublishable published published published unpublished unpublishable unpublishable]
        end

        it "updates enrollment status if no resource provided" do
          allow(@plugin).to receive(:enabled?).and_return(true)
          @plugin_settings[:publish_endpoint] = "http://localhost/endpoint"
          @plugin_settings[:format_type] = "test_format"
          @ase = @student_enrollments.find_all { |e| e.workflow_state == "active" }
          allow(Course).to receive(:valid_grade_export_types).and_return({
                                                                           "test_format" => {
                                                                             callback: lambda do |course, enrollments, publishing_user, publishing_pseudonym|
                                                                               expect(course).to eq @course
                                                                               expect(enrollments.sort_by(&:id)).to eq @ase.sort_by(&:id)
                                                                               expect(publishing_pseudonym).to eq @pseudonym
                                                                               expect(publishing_user).to eq @user
                                                                               [
                                                                                 [[@ase[1].id, @ase[3].id],
                                                                                  nil,
                                                                                  nil],
                                                                                 [[@ase[4].id, @ase[7].id],
                                                                                  nil,
                                                                                  nil]
                                                                               ]
                                                                             end
                                                                           }
                                                                         })
          expect(SSLCommon).not_to receive(:post_data)
          @course.send_final_grades_to_endpoint @user
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[unpublishable published unpublishable published published unpublishable unpublished unpublishable published]
          expect(@student_enrollments.map(&:grade_publishing_message)).to eq [nil] * 9
        end
      end

      context "generate_grade_publishing_csv_output" do
        before :once do
          make_student_enrollments
          grade_publishing_user
          @course.assignment_groups.create(name: "Assignments")
          a1 = @course.assignments.create!(title: "A1", points_possible: 10)
          a2 = @course.assignments.create!(title: "A2", points_possible: 10)
          @course.enroll_teacher(@user).tap { |e| e.update!(workflow_state: "active") }
          @ase = @course.student_enrollments.active

          add_pseudonym(@ase[2], Account.default, "student2", nil)
          add_pseudonym(@ase[3], Account.default, "student3", "student3")
          add_pseudonym(@ase[4], Account.default, "student4a", "student4a")
          add_pseudonym(@ase[4], Account.default, "student4b", "student4b")
          another_account = account_model
          add_pseudonym(@ase[5], another_account, "student5", nil)
          add_pseudonym(@ase[6], another_account, "student6", "student6")
          add_pseudonym(@ase[7], Account.default, "student7a", "student7a")
          add_pseudonym(@ase[7], Account.default, "student7b", "student7b")

          a1.grade_student(@ase[0].user, { grade: "9", grader: @user })
          a2.grade_student(@ase[0].user, { grade: "10", grader: @user })
          a1.grade_student(@ase[1].user, { grade: "6", grader: @user })
          a2.grade_student(@ase[1].user, { grade: "7", grader: @user })
          a1.grade_student(@ase[7].user, { grade: "8", grader: @user })
          a2.grade_student(@ase[7].user, { grade: "9", grader: @user })
        end

        def add_pseudonym(enrollment, account, unique_id, sis_user_id)
          pseudonym = account.pseudonyms.build
          pseudonym.user = enrollment.user
          pseudonym.unique_id = unique_id
          pseudonym.sis_user_id = sis_user_id
          pseudonym.save!
        end

        it "generates valid csv without a grading standard" do
          @course.recompute_student_scores_without_send_later
          expect(@course.generate_grade_publishing_csv_output(@ase, @user, @pseudonym)).to eq [
            [@ase.map(&:id), <<~CSV, "text/csv"]]
              publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score
              #{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95.0
              #{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65.0
              #{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85.0
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85.0
            CSV
        end

        it "generates valid csv without a publishing pseudonym" do
          @course.recompute_student_scores_without_send_later
          expect(@course.generate_grade_publishing_csv_output(@ase, @user, nil)).to eq [
            [@ase.map(&:id), <<~CSV, "text/csv"]]
              publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score
              #{@user.id},,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95.0
              #{@user.id},,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65.0
              #{@user.id},,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0.0
              #{@user.id},,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0.0
              #{@user.id},,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0.0
              #{@user.id},,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0.0
              #{@user.id},,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0.0
              #{@user.id},,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0.0
              #{@user.id},,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85.0
              #{@user.id},,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85.0
            CSV
        end

        it "generates valid csv with a section id" do
          @course_section.sis_source_id = "section1"
          @course_section.save!
          @course.recompute_student_scores_without_send_later
          expect(@course.generate_grade_publishing_csv_output(@ase, @user, @pseudonym)).to eq [
            [@ase.map(&:id), <<~CSV, "text/csv"]]
              publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score
              #{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},section1,#{@ase[0].user.id},,#{@ase[0].id},active,95.0
              #{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},section1,#{@ase[1].user.id},,#{@ase[1].id},active,65.0
              #{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},section1,#{@ase[2].user.id},,#{@ase[2].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},section1,#{@ase[3].user.id},student3,#{@ase[3].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},section1,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},section1,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},section1,#{@ase[5].user.id},,#{@ase[5].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},section1,#{@ase[6].user.id},,#{@ase[6].id},active,0.0
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},section1,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85.0
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},section1,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85.0
            CSV
        end

        it "generates valid csv with a grading standard" do
          @course.grading_standard_id = 0
          @course.save!
          @course.recompute_student_scores_without_send_later
          expect(@course.generate_grade_publishing_csv_output(@ase, @user, @pseudonym)).to eq [
            [@ase.map(&:id), <<~CSV, "text/csv"]]
              publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score,grade
              #{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95.0,A
              #{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,65.0,D
              #{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[3].course_section_id},,#{@ase[3].user.id},student3,#{@ase[3].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4a,#{@ase[4].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[4].course_section_id},,#{@ase[4].user.id},student4b,#{@ase[4].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85.0,B
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85.0,B
            CSV
        end

        it "generates valid csv and skip users with no computed final score" do
          @course.grading_standard_id = 0
          @course.save!
          @course.recompute_student_scores_without_send_later
          @ase.map(&:reload)

          @ase[1].scores.update_all(final_score: nil)
          @ase[3].scores.update_all(final_score: nil)
          @ase[4].scores.update_all(final_score: nil)

          expect(@course.generate_grade_publishing_csv_output(@ase, @user, @pseudonym)).to eq [
            [@ase.map(&:id) - [@ase[1].id, @ase[3].id, @ase[4].id], <<~CSV, "text/csv"]]
              publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score,grade
              #{@user.id},U1,#{@course.id},,#{@ase[0].course_section_id},,#{@ase[0].user.id},,#{@ase[0].id},active,95.0,A
              #{@user.id},U1,#{@course.id},,#{@ase[2].course_section_id},,#{@ase[2].user.id},,#{@ase[2].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[5].course_section_id},,#{@ase[5].user.id},,#{@ase[5].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[6].course_section_id},,#{@ase[6].user.id},,#{@ase[6].id},active,0.0,F
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7a,#{@ase[7].id},active,85.0,B
              #{@user.id},U1,#{@course.id},,#{@ase[7].course_section_id},,#{@ase[7].user.id},student7b,#{@ase[7].id},active,85.0,B
            CSV
        end

        context "sharding" do
          specs_require_sharding

          it "generates valid csv with a sis_user_id from out-of-shard" do
            u = @shard1.activate { User.create! }
            @course.root_account.pseudonyms.create!(user: u, unique_id: "user", sis_user_id: "sis_id")
            enrollment = @course.enroll_student(u, enrollment_state: "active")
            ase = @ase.to_a << enrollment
            @course.assignments.first.grade_student(u, { grade: "10", grader: @user })
            @course.recompute_student_scores_without_send_later

            expect(@course.generate_grade_publishing_csv_output(ase, @user, @pseudonym)).to eq [
              [
                ase.map(&:id),
                (
                  "publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id," \
                  "student_id,student_sis_id,enrollment_id,enrollment_status," + "score\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[0].course_section_id},,#{ase[0].user.id},,#{ase[0].id},active,95.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[1].course_section_id},,#{ase[1].user.id},,#{ase[1].id},active,65.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[2].course_section_id},,#{ase[2].user.id},,#{ase[2].id},active,0.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[3].course_section_id},,#{ase[3].user.id},student3,#{ase[3].id},active,0.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[4].course_section_id},,#{ase[4].user.id},student4a,#{ase[4].id},active,0.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[4].course_section_id},,#{ase[4].user.id},student4b,#{ase[4].id},active,0.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[5].course_section_id},,#{ase[5].user.id},,#{ase[5].id},active,0.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[6].course_section_id},,#{ase[6].user.id},,#{ase[6].id},active,0.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[7].course_section_id},,#{ase[7].user.id},student7a,#{ase[7].id},active,85.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[7].course_section_id},,#{ase[7].user.id},student7b,#{ase[7].id},active,85.0\n" \
                                                                                 "#{@user.id},U1,#{@course.id},,#{ase[8].course_section_id},,#{ase[8].user.id},sis_id,#{ase[8].id},active,50.0\n"
                ),
                "text/csv"
              ]
            ]
          end
        end

        context "when including final grade overrides" do
          before(:once) do
            @course.update!(grading_standard_id: 0)
            Account.site_admin.disable_feature!(:custom_gradebook_statuses)
          end

          before do
            @course.enable_feature!(:final_grades_override)
            @course.update!(allow_final_grade_override: true)
          end

          def csv_output(include_final_grade_overrides: true)
            @course.generate_grade_publishing_csv_output(
              @ase,
              @user,
              @pseudonym,
              include_final_grade_overrides:
            )
          end

          it "does not use the final grade override if final grades override feature is not allowed" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: 0, override_score: 100)
            @course.update!(allow_final_grade_override: false)
            expect(csv_output[0][1]).to include(
              "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,0.0,F\n"
            )
          end

          it "does not use the final grade override if final grades override feature is not enabled" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: 0, override_score: 100)
            @course.disable_feature!(:final_grades_override)
            expect(csv_output[0][1]).to include(
              "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,0.0,F\n"
            )
          end

          it "uses the final grade override over the computed final grade if the final grades override feature is enabled" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: 0, override_score: 100)
            expect(csv_output[0][1]).to include(
              "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,100.0,A\n"
            )
          end

          it "does not skip users with no computed final score when they have an override score" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: nil, override_score: 100)
            enrollment_ids = csv_output[0][1]
            expect(enrollment_ids).to include(
              "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,100.0,A\n"
            )
          end

          it "skips users with no computed final score and no override score" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: nil, override_score: nil)
            enrollment_ids = csv_output[0][0]
            expect(enrollment_ids).not_to include @ase[1].id
          end

          context "when including custom grade statuses" do
            before do
              Account.site_admin.enable_feature!(:custom_gradebook_statuses)
              @custom_grade_status = CustomGradeStatus.create!(name: "new status", color: "#000000", root_account_id: @course.root_account_id, created_by: user_model)
              @ase[1].scores.find_by(course_score: true).update!(final_score: 0, override_score: 100, custom_grade_status: @custom_grade_status)
            end

            it "includes custom_grade_status in the csv output" do
              output = csv_output[0][1]
              expect(output).to include("custom_grade_status")
              expect(output).to include(
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,100.0,A,#{@custom_grade_status.name}\n"
              )
            end

            it "does not include custom_grade_status in the csv output if include_final_grade_overrides is disabled" do
              @course.update!(allow_final_grade_override: false)
              output = csv_output(include_final_grade_overrides: false)[0][1]
              expect(output).to include(
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,0.0,F\n"
              )
              expect(output).not_to include("custom_grade_status")
              expect(output).not_to include(@custom_grade_status.name)
            end

            it "does not include custom_grade_status if feature flag is disabled" do
              Account.site_admin.disable_feature!(:custom_gradebook_statuses)
              output = csv_output[0][1]
              expect(output).to include(
                "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,100.0,A\n"
              )
              expect(output).not_to include("custom_grade_status")
              expect(output).not_to include(@custom_grade_status.name)
            end
          end
        end

        context "when not including final grade overrides" do
          before(:once) do
            @course.update!(grading_standard_id: 0)
          end

          before do
            @course.enable_feature!(:final_grades_override)
          end

          def csv_output
            @course.generate_grade_publishing_csv_output(@ase, @user, @pseudonym)
          end

          it "does not use the final grade override if final grades override feature is not enabled" do
            @course.disable_feature!(:final_grades_override)
            @ase[1].scores.find_by(course_score: true).update!(final_score: 0, override_score: 100)
            expect(csv_output[0][1]).to include(
              "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,0.0,F\n"
            )
          end

          it "does not use the final grade override if the final grades override feature is enabled" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: 0, override_score: 100)
            expect(csv_output[0][1]).to include(
              "#{@user.id},U1,#{@course.id},,#{@ase[1].course_section_id},,#{@ase[1].user.id},,#{@ase[1].id},active,0.0,F\n"
            )
          end

          it "skip users with no computed final score when they have an override score" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: nil, override_score: 100)
            enrollment_ids = csv_output[0][0]
            expect(enrollment_ids).not_to include @ase[1].id
          end

          it "skips users with no computed final score when they have no override score" do
            @ase[1].scores.find_by(course_score: true).update!(final_score: nil, override_score: nil)
            enrollment_ids = csv_output[0][0]
            expect(enrollment_ids).not_to include @ase[1].id
          end
        end
      end

      context "expire_pending_grade_publishing_statuses" do
        it "updates the right enrollments" do
          make_student_enrollments
          first_time = Time.now.utc
          second_time = first_time + 2.seconds
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[published error unpublishable error unpublishable unpublishable unpublished unpublished unpublished]
          @student_enrollments[0].grade_publishing_status = "pending"
          @student_enrollments[0].last_publish_attempt_at = first_time
          @student_enrollments[1].grade_publishing_status = "publishing"
          @student_enrollments[1].last_publish_attempt_at = first_time
          @student_enrollments[2].grade_publishing_status = "pending"
          @student_enrollments[2].last_publish_attempt_at = second_time
          @student_enrollments[3].grade_publishing_status = "publishing"
          @student_enrollments[3].last_publish_attempt_at = second_time
          @student_enrollments[4].grade_publishing_status = "published"
          @student_enrollments[4].last_publish_attempt_at = first_time
          @student_enrollments[5].grade_publishing_status = "unpublished"
          @student_enrollments[5].last_publish_attempt_at = first_time
          @student_enrollments.map(&:save)
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[pending publishing pending publishing published unpublished unpublished unpublished unpublished]
          @course.expire_pending_grade_publishing_statuses(first_time)
          expect(@student_enrollments.each(&:reload).map(&:grade_publishing_status)).to eq %w[error error pending publishing published unpublished unpublished unpublished unpublished]
        end
      end

      context "grading_standard_enabled" do
        it "works for a number of boolean representations" do
          expect(@course.grading_standard_enabled?).to be_falsey
          expect(@course.grading_standard_enabled).to be_falsey
          [[false, false],
           [true, true],
           ["false", false],
           ["true", true],
           ["0", false],
           [0, false],
           ["1", true],
           [1, true],
           ["off", false],
           ["on", true],
           ["yes", true],
           ["no", false]].each do |val, enabled|
            @course.grading_standard_enabled = val
            expect(@course.grading_standard_enabled?).to eq enabled
            expect(@course.grading_standard_enabled).to eq enabled
            expect(@course.grading_standard_id).to be_nil unless enabled
            expect(@course.grading_standard_id).not_to be_nil if enabled
            expect(@course.bool_res(val)).to eq enabled
          end
        end
      end
    end

    context "integration suite" do
      def quick_sanity_check(user, expect_success = true)
        Course.valid_grade_export_types["test_export"] = {
          name: "test export",
          callback: lambda do |course, _enrollments, publishing_user, publishing_pseudonym|
                      expect(course).to eq @course
                      expect(publishing_pseudonym).to eq @pseudonym
                      expect(publishing_user).to eq @user
                      [[[], "test-jt-data", "application/jtmimetype"]]
                    end,
          requires_grading_standard: false,
          requires_publishing_pseudonym: true
        }

        @plugin = Canvas::Plugin.find!("grade_export")
        @ps = PluginSetting.new(name: @plugin.id, settings: @plugin.default_settings)
        @ps.posted_settings = @plugin.default_settings.merge({
                                                               format_type: "test_export",
                                                               wait_for_success: "no",
                                                               publish_endpoint: "http://localhost/endpoint"
                                                             })
        @ps.save!

        @course.grading_standard_id = 0
        if expect_success
          expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", "test-jt-data", "application/jtmimetype", {})
        else
          expect(SSLCommon).not_to receive(:post_data)
        end
        @course.publish_final_grades(user)
      end

      it "passes a quick sanity check" do
        @user = user_with_pseudonym
        @pseudonym.account_id = @course.root_account_id
        @pseudonym.sis_user_id = "U1"
        @pseudonym.save!
        quick_sanity_check(@user)
      end

      it "does not allow grade publishing for a user that is disallowed" do
        @user = User.new
        expect { quick_sanity_check(@user, false) }.to raise_error("publishing disallowed for this publishing user")
      end

      it "does not allow grade publishing for a user with a pseudonym in the wrong account" do
        @user = user_with_pseudonym
        @pseudonym.account = account_model
        @pseudonym.sis_user_id = "U1"
        @pseudonym.save!
        expect { quick_sanity_check(@user, false) }.to raise_error("publishing disallowed for this publishing user")
      end

      it "does not allow grade publishing for a user with a pseudonym without a sis id" do
        @user = user_with_pseudonym
        @pseudonym.account_id = @course.root_account_id
        @pseudonym.sis_user_id = nil
        @pseudonym.save!
        expect { quick_sanity_check(@user, false) }.to raise_error("publishing disallowed for this publishing user")
      end

      it "does not publish empty csv" do
        @user = user_with_pseudonym
        @pseudonym.sis_user_id = "U1"
        @pseudonym.account_id = @course.root_account_id
        @pseudonym.save!

        @plugin = Canvas::Plugin.find!("grade_export")
        @ps = PluginSetting.new(name: @plugin.id, settings: @plugin.default_settings)
        @ps.posted_settings = @plugin.default_settings.merge({
                                                               format_type: "instructure_csv",
                                                               wait_for_success: "no",
                                                               publish_endpoint: "http://localhost/endpoint"
                                                             })
        @ps.save!

        @course.grading_standard_id = 0
        expect(SSLCommon).to_not receive(:post_data) # like c'mon dude why send an empty csv file
        @course.publish_final_grades(@user)
      end

      it "publishes grades" do
        process_csv_data_cleanly(
          "user_id,login_id,password,first_name,last_name,email,status",
          "T1,Teacher1,,T,1,t1@example.com,active",
          "S1,Student1,,S,1,s1@example.com,active",
          "S2,Student2,,S,2,s2@example.com,active",
          "S3,Student3,,S,3,s3@example.com,active",
          "S4,Student4,,S,4,s4@example.com,active",
          "S5,Student5,,S,5,s5@example.com,active",
          "S6,Student6,,S,6,s6@example.com,active"
        )
        process_csv_data_cleanly(
          "course_id,short_name,long_name,account_id,term_id,status",
          "C1,C1,C1,,,active"
        )
        @course = Course.where(sis_source_id: "C1").first
        @course.assignment_groups.create(name: "Assignments")
        process_csv_data_cleanly(
          "section_id,course_id,name,status,start_date,end_date",
          "S1,C1,S1,active,,",
          "S2,C1,S2,active,,",
          "S3,C1,S3,active,,",
          "S4,C1,S4,active,,"
        )
        process_csv_data_cleanly(
          "course_id,user_id,role,section_id,status",
          ",T1,teacher,S1,active",
          ",S1,student,S1,active",
          ",S2,student,S2,active",
          ",S3,student,S2,active",
          ",S4,student,S1,active",
          ",S5,student,S3,active",
          ",S6,student,S4,active"
        )
        a1 = @course.assignments.create!(title: "A1", points_possible: 10)
        a2 = @course.assignments.create!(title: "A2", points_possible: 10)

        def getpseudonym(user_sis_id)
          pseudo = Pseudonym.where(sis_user_id: user_sis_id).first
          expect(pseudo).not_to be_nil
          pseudo
        end

        def getuser(user_sis_id)
          user = getpseudonym(user_sis_id).user
          expect(user).not_to be_nil
          user
        end

        def getsection(section_sis_id)
          section = CourseSection.where(sis_source_id: section_sis_id).first
          expect(section).not_to be_nil
          section
        end

        def getenroll(user_sis_id, section_sis_id)
          e = Enrollment.where(user_id: getuser(user_sis_id), course_section_id: getsection(section_sis_id)).first
          expect(e).not_to be_nil
          e
        end

        a1.grade_student(getuser("S1"), { grade: "6", grader: getuser("T1") })
        a1.grade_student(getuser("S2"), { grade: "6", grader: getuser("T1") })
        a1.grade_student(getuser("S3"), { grade: "7", grader: getuser("T1") })
        a1.grade_student(getuser("S5"), { grade: "7", grader: getuser("T1") })
        a1.grade_student(getuser("S6"), { grade: "8", grader: getuser("T1") })
        a2.grade_student(getuser("S1"), { grade: "8", grader: getuser("T1") })
        a2.grade_student(getuser("S2"), { grade: "9", grader: getuser("T1") })
        a2.grade_student(getuser("S3"), { grade: "9", grader: getuser("T1") })
        a2.grade_student(getuser("S5"), { grade: "10", grader: getuser("T1") })
        a2.grade_student(getuser("S6"), { grade: "10", grader: getuser("T1") })

        stud5, stud6, sec4 = nil, nil, nil
        Pseudonym.where(sis_user_id: "S5").first.tap do |p|
          stud5 = p
          p.sis_user_id = nil
          p.save
        end

        Pseudonym.where(sis_user_id: "S6").first.tap do |p|
          stud6 = p
          p.sis_user_id = nil
          p.save
        end

        getsection("S4").tap do |s|
          sec4 = s
          s.save
        end

        GradeCalculator.recompute_final_score(%w[S1 S2 S3 S4].map { |x| getuser(x).id }, @course.id)
        @course.reload

        teacher = Pseudonym.where(sis_user_id: "T1").first
        expect(teacher).not_to be_nil

        @plugin = Canvas::Plugin.find!("grade_export")
        @ps = PluginSetting.new(name: @plugin.id, settings: @plugin.default_settings)
        @ps.posted_settings = @plugin.default_settings.merge({
                                                               format_type: "instructure_csv",
                                                               wait_for_success: "no",
                                                               publish_endpoint: "http://localhost/endpoint"
                                                             })
        @ps.save!

        csv = <<~CSV
          publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70.0
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75.0
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80.0
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0.0
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.where(user_id: stud5.user, course_section_id: getsection("S3")).first.id},active,85.0
          #{teacher.user.id},T1,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.where(user_id: stud6.user, course_section_id: sec4.id).first.id},active,90.0
        CSV
        expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
        @course.publish_final_grades(teacher.user)

        @course.grading_standard_id = 0
        @course.save

        csv = <<~CSV
          publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score,grade
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70.0,C-
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75.0,C
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80.0,B-
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0.0,F
          #{teacher.user.id},T1,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.where(user_id: stud5.user, course_section_id: getsection("S3")).first.id},active,85.0,B
          #{teacher.user.id},T1,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.where(user_id: stud6.user, course_section_id: sec4.id).first.id},active,90.0,A-
        CSV
        expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
        @course.publish_final_grades(teacher.user)

        admin = user_model

        csv = <<~CSV
          publisher_id,publisher_sis_id,course_id,course_sis_id,section_id,section_sis_id,student_id,student_sis_id,enrollment_id,enrollment_status,score,grade
          #{admin.id},,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S1").user.id},S1,#{getenroll("S1", "S1").id},active,70.0,C-
          #{admin.id},,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S2").user.id},S2,#{getenroll("S2", "S2").id},active,75.0,C
          #{admin.id},,#{@course.id},C1,#{getsection("S2").id},S2,#{getpseudonym("S3").user.id},S3,#{getenroll("S3", "S2").id},active,80.0,B-
          #{admin.id},,#{@course.id},C1,#{getsection("S1").id},S1,#{getpseudonym("S4").user.id},S4,#{getenroll("S4", "S1").id},active,0.0,F
          #{admin.id},,#{@course.id},C1,#{getsection("S3").id},S3,#{stud5.user.id},,#{Enrollment.where(user_id: stud5.user, course_section_id: getsection("S3")).first.id},active,85.0,B
          #{admin.id},,#{@course.id},C1,#{sec4.id},S4,#{stud6.user.id},,#{Enrollment.where(user_id: stud6.user, course_section_id: sec4.id).first.id},active,90.0,A-
        CSV
        expect(SSLCommon).to receive(:post_data).with("http://localhost/endpoint", csv, "text/csv", {})
        @course.publish_final_grades(admin)
      end
    end
  end

  describe Course, "tabs_available" do
    before :once do
      course_model
    end

    def new_external_tool(context)
      context.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "example.com")
    end

    it "does not include external tools if not configured for course navigation" do
      tool = new_external_tool @course
      tool.user_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be false
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)
    end

    it "includes external tools if configured on the course" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be true
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tab = tabs.detect { |t| t[:id] == tool.asset_string }
      expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
      expect(tab[:href]).to eq :course_external_tool_path
      expect(tab[:args]).to eq [@course.id, tool.id]
    end

    it "includes external tools if configured on the account" do
      @account = @course.root_account.sub_accounts.create!(name: "sub-account")
      @course.account = @account
      @course.save!
      tool = new_external_tool @account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be true
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tab = tabs.detect { |t| t[:id] == tool.asset_string }
      expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
      expect(tab[:href]).to eq :course_external_tool_path
      expect(tab[:args]).to eq [@course.id, tool.id]
    end

    it "includes external tools if configured on the root account" do
      @account = @course.root_account.sub_accounts.create!(name: "sub-account")
      @course.account = @account
      @course.save!
      tool = new_external_tool @account.root_account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be true
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tab = tabs.detect { |t| t[:id] == tool.asset_string }
      expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
      expect(tab[:href]).to eq :course_external_tool_path
      expect(tab[:args]).to eq [@course.id, tool.id]
    end

    it "only includes admin-only external tools for course admins" do
      @course.offer
      @course.is_public = true
      @course.save!
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL", visibility: "admins" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be true
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      @student = user_model
      @student.register!
      @course.enroll_student(@student).accept
      tabs = @course.tabs_available(nil)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)
      tabs = @course.tabs_available(@student)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tab = tabs.detect { |t| t[:id] == tool.asset_string }
      expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
      expect(tab[:href]).to eq :course_external_tool_path
      expect(tab[:args]).to eq [@course.id, tool.id]
    end

    it "does not include member-only external tools for unauthenticated users" do
      @course.offer
      @course.is_public = true
      @course.save!
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL", visibility: "members" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be true
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      @student = user_model
      @student.register!
      @course.enroll_student(@student).accept
      tabs = @course.tabs_available(nil)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)
      tabs = @course.tabs_available(@student)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
      tab = tabs.detect { |t| t[:id] == tool.asset_string }
      expect(tab[:label]).to eq tool.settings[:course_navigation][:text]
      expect(tab[:href]).to eq :course_external_tool_path
      expect(tab[:args]).to eq [@course.id, tool.id]
    end

    it "allows reordering external tool position in course navigation" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be true
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      @course.tab_configuration = Course.default_tabs.map { |t| { id: t[:id] } }.insert(1, { id: tool.asset_string })
      @course.save!
      tabs = @course.tabs_available(@teacher)
      expect(tabs[1][:id]).to eq tool.asset_string
    end

    it "does not show external tools that are hidden in course navigation" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(tool.has_placement?(:course_navigation)).to be true
      @teacher = user_model
      @course.enroll_teacher(@teacher).accept
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).to include(tool.asset_string)

      @course.tab_configuration = Course.default_tabs.map { |t| { id: t[:id] } }.insert(1, { id: tool.asset_string, hidden: true })
      @course.save!
      @course = Course.find(@course.id)
      tabs = @course.tabs_available(@teacher)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)

      tabs = @course.tabs_available(@teacher, for_reordering: true)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
    end

    it "uses extension default values" do
      tool = new_external_tool @course
      tool.course_navigation = {}
      tool.settings[:url] = "http://www.example.com"
      tool.settings[:visibility] = "members"
      tool.settings[:default] = "disabled"
      tool.save!

      expect(tool.course_navigation(:url)).to eq "http://www.example.com"
      expect(tool.has_placement?(:course_navigation)).to be true

      settings = @course.external_tool_tabs({}, User.new).first
      expect(settings).to include(visibility: "members")
      expect(settings).to include(hidden: true)
    end

    it "prefers extension settings over default values" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", visibility: "admins", default: "active" }
      tool.settings[:visibility] = "members"
      tool.settings[:default] = "disabled"
      tool.save!

      expect(tool.course_navigation(:url)).to eq "http://www.example.com"
      expect(tool.has_placement?(:course_navigation)).to be true

      settings = @course.external_tool_tabs({}, User.new).first
      expect(settings).to include(visibility: "admins")
      expect(settings).to include(hidden: false)
    end

    it "hides tabs for feature flagged external tools" do
      tool = analytics_2_tool_factory

      tabs = @course.external_tool_tabs({}, User.new)
      expect(tabs.pluck(:id)).not_to include(tool.asset_string)

      @course.enable_feature!(:analytics_2)
      tabs = @course.external_tool_tabs({}, User.new)
      expect(tabs.pluck(:id)).to include(tool.asset_string)
    end
  end

  describe "#external_tool_tabs" do
    subject { @course.external_tool_tabs({}, user).pluck(:id) }

    before :once do
      course_model
    end

    let(:course_tool) do
      t = external_tool_model(context: @course)
      t.course_navigation = { enabled: true }
      t.save!
      t
    end
    let(:account_tool) do
      t = external_tool_model(context: @course.account)
      t.course_navigation = { enabled: true }
      t.save!
      t
    end
    let(:wrong_tool) { external_tool_model(context: @course) }
    let(:user) { User.new }

    before do
      account_tool
      course_tool
      wrong_tool
    end

    it "ignores tools without course_navigation" do
      expect(subject).not_to include(wrong_tool.asset_string)
    end

    it "returns tools associated with the course" do
      expect(subject).to include(course_tool.asset_string)
    end

    it "returns tools from course's account chain" do
      expect(subject).to include(account_tool.asset_string)
    end

    context "when request is made from different shard by cross-shard user" do
      specs_require_sharding

      let(:cross_shard_account) do
        @shard1.activate do
          account_model
        end
      end
      let(:user) do
        u = @shard1.activate { User.create! }
        @course.enroll_student(u, enrollment_state: "active")
        u
      end

      it "returns tools from course's account chain" do
        @shard1.activate do
          expect(subject).to include(@course.shard.activate { account_tool.asset_string })
        end
      end
    end
  end

  describe "#tab_hidden?" do
    before :once do
      course_model
    end

    it "does not have any hidden tabs by default" do
      Course.default_tabs.each do |tab|
        expect(@course.tab_hidden?(tab[:id])).to be_falsey
      end
    end

    it "hides certain tabs when canvas_k6_theme feature flag is enabled" do
      @course.enable_feature!(:canvas_k6_theme)
      Course.default_tabs.each do |tab|
        hidden = !Course::CANVAS_K6_TAB_IDS.include?(tab[:id])
        expect(@course.tab_hidden?(tab[:id])).to(hidden ? be_truthy : be_falsey)
      end
    ensure
      @course.disable_feature!(:canvas_k6_theme)
    end
  end

  describe "scoping" do
    it "searches by multiple fields" do
      c1 = Course.new
      c1.root_account = Account.create
      c1.name = "name1"
      c1.sis_source_id = "sisid1"
      c1.course_code = "code1"
      c1.save
      c2 = Course.new
      c2.root_account = Account.create
      c2.name = "name2"
      c2.course_code = "code2"
      c2.sis_source_id = "sisid2"
      c2.save
      expect(Course.name_like("name1").map(&:id)).to eq [c1.id]
      expect(Course.name_like("sisid2").map(&:id)).to eq [c2.id]
      expect(Course.name_like("code1").map(&:id)).to eq [c1.id]
    end
  end

  describe "#manageable_by_user" do
    it "includes courses associated with the user's active accounts" do
      account = Account.create!
      sub_account = Account.create!(parent_account: account)
      sub_sub_account = Account.create!(parent_account: sub_account)
      user = account_admin_user(account: sub_account)
      course = Course.create!(account: sub_sub_account)

      expect(Course.manageable_by_user(user.id).map(&:id)).to include(course.id)

      user.account_users.first.destroy!
      expect(Course.manageable_by_user(user.id)).to_not be_exists
    end

    it "includes courses the user is actively enrolled in as a teacher" do
      course = Course.create
      user = user_with_pseudonym
      course.enroll_teacher(user)
      e = course.teacher_enrollments.first
      e.accept

      expect(Course.manageable_by_user(user.id).map(&:id)).to include(course.id)
    end

    it "includes courses the user is actively enrolled in as a ta" do
      course = Course.create
      user = user_with_pseudonym
      course.enroll_ta(user)
      e = course.ta_enrollments.first
      e.accept

      expect(Course.manageable_by_user(user.id).map(&:id)).to include(course.id)
    end

    it "includes courses the user is actively enrolled in as a designer" do
      course = Course.create
      user = user_with_pseudonym
      course.enroll_designer(user).accept

      expect(Course.manageable_by_user(user.id).map(&:id)).to include(course.id)
    end

    it "does not include courses the user is enrolled in when the enrollment is non-active" do
      course = Course.create
      user = user_with_pseudonym
      course.enroll_teacher(user)
      e = course.teacher_enrollments.first

      # it's only invited at this point
      expect(Course.manageable_by_user(user.id)).to be_empty

      e.destroy
      expect(Course.manageable_by_user(user.id)).to be_empty
    end

    it "does not include deleted courses the user was enrolled in" do
      course = Course.create
      user = user_with_pseudonym
      course.enroll_teacher(user)
      e = course.teacher_enrollments.first
      e.accept

      course.destroy
      expect(Course.manageable_by_user(user.id)).to be_empty
    end
  end

  context "conclusions" do
    it "grants concluded users read but not participate" do
      enrollment = course_with_student(active_all: 1)
      @course.reload

      # active
      expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({ read: true, participate_as_student: true })
      @course.clear_permissions_cache(@user)

      # soft conclusion
      enrollment.start_at = 4.days.ago
      enrollment.end_at = 2.days.ago
      enrollment.save!
      @course.reload
      @user.reload
      @user.cached_currentish_enrollments

      expect(enrollment.reload.state).to eq :active
      expect(enrollment.state_based_on_date).to eq :completed
      expect(enrollment).not_to be_participating_student

      expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({ read: true, participate_as_student: false })
      @course.clear_permissions_cache(@user)

      # hard enrollment conclusion
      enrollment.start_at = enrollment.end_at = nil
      enrollment.workflow_state = "completed"
      enrollment.save!
      @course.reload
      @user.reload
      @user.cached_currentish_enrollments
      expect(enrollment.state).to eq :completed
      expect(enrollment.state_based_on_date).to eq :completed

      expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({ read: true, participate_as_student: false })
      @course.clear_permissions_cache(@user)

      # course conclusion
      enrollment.workflow_state = "active"
      enrollment.save!
      @course.reload
      @course.complete!
      @user.reload
      @user.cached_currentish_enrollments
      enrollment.reload
      expect(enrollment.state).to eq :completed
      expect(enrollment.state_based_on_date).to eq :completed

      expect(@course.rights_status(@user, :read, :participate_as_student)).to eq({ read: true, participate_as_student: false })
    end

    context "appointment cancellation" do
      before :once do
        course_with_student(active_all: true)
        @ag = AppointmentGroup.create!(title: "test", contexts: [@course], new_appointments: [["2010-01-01 13:00:00", "2010-01-01 14:00:00"], ["#{Time.now.year + 1}-01-01 13:00:00", "#{Time.now.year + 1}-01-01 14:00:00"]])
        @ag.appointments.each do |a|
          a.reserve_for(@user, @user)
        end
      end

      it "cancels all future appointments when concluding an enrollment" do
        @enrollment.conclude
        expect(@ag.appointments_participants.size).to be 1
        expect(@ag.appointments_participants.current.size).to be 0
      end

      it "cancels all future appointments when deleting an enrollment" do
        @enrollment.destroy
        expect(@ag.appointments_participants.size).to be 1
        expect(@ag.appointments_participants.current.size).to be 0
      end

      it "cancels all future appointments when concluding all enrollments" do
        @course.complete!
        expect(@ag.appointments_participants.size).to be 1
        expect(@ag.appointments_participants.current.size).to be 0
      end
    end
  end

  describe "#inherited_assessment_question_banks" do
    it "includes the course's banks if include_self is true" do
      @account = Account.create
      @course = Course.create(account: @account)
      expect(@course.inherited_assessment_question_banks(true)).to be_empty

      bank = @course.assessment_question_banks.create
      expect(@course.inherited_assessment_question_banks(true)).to eq [bank]
    end

    it "includes all banks in the account hierarchy" do
      @root_account = Account.create
      root_bank = @root_account.assessment_question_banks.create

      @account = Account.new
      @account.root_account = @root_account
      @account.save
      account_bank = @account.assessment_question_banks.create

      @course = Course.create(account: @account)
      expect(@course.inherited_assessment_question_banks.sort_by(&:id)).to eq [root_bank, account_bank]
    end

    it "returns a useful scope" do
      @root_account = Account.create
      root_bank = @root_account.assessment_question_banks.create

      @account = Account.new
      @account.root_account = @root_account
      @account.save
      account_bank = @account.assessment_question_banks.create

      @course = Course.create(account: @account)
      bank = @course.assessment_question_banks.create

      banks = @course.inherited_assessment_question_banks(true)
      expect(banks.order(:id)).to eq [root_bank, account_bank, bank]
      expect(banks.where(id: bank).first).to eql bank
      expect(banks.where(id: account_bank).first).to eql account_bank
      expect(banks.where(id: root_bank).first).to eql root_bank
    end
  end

  context "section_visibility" do
    before :once do
      @course = course_factory(active_course: true)
      @course.default_section
      @other_section = @course.course_sections.create

      @teacher = User.create
      @course.enroll_teacher(@teacher)

      @ta = User.create
      @course.enroll_user(@ta, "TaEnrollment", limit_privileges_to_course_section: true)

      @student1 = User.create
      @course.enroll_user(@student1, "StudentEnrollment", enrollment_state: "active")

      @student2 = User.create
      @course.enroll_user(@student2, "StudentEnrollment", section: @other_section, enrollment_state: "active")

      @observer = User.create
      @course.enroll_user(@observer, "ObserverEnrollment").update_attribute(:associated_user_id, @student1.id)
    end

    it "returns a scope from sections_visible_to" do
      # can't use "should respond_to", because that delegates to the instantiated Array
      expect { @course.sections_visible_to(@teacher).all }.not_to raise_exception
    end

    context "full" do
      it "returns rejected enrollments if passed :priors_and_deleted" do
        @course.student_enrollments.find_by(user_id: @student1).update!(workflow_state: "rejected")
        visible_student_ids = @course.students_visible_to(@teacher, include: :priors_and_deleted).pluck(:id)
        expect(visible_student_ids).to include @student1.id
      end

      it "returns deleted enrollments if passed :priors_and_deleted" do
        @course.student_enrollments.find_by(user_id: @student1).destroy
        visible_student_ids = @course.students_visible_to(@teacher, include: :priors_and_deleted).pluck(:id)
        expect(visible_student_ids).to include @student1.id
      end

      it "returns students from all sections" do
        expect(@course.students_visible_to(@teacher).sort_by(&:id)).to eql [@student1, @student2]
        expect(@course.students_visible_to(@student1).sort_by(&:id)).to eql [@student1, @student2]
      end

      it "returns all sections if a teacher" do
        expect(@course.sections_visible_to(@teacher).sort_by(&:id)).to eql [@course.default_section, @other_section]
      end

      it "returns user's sections if a student" do
        expect(@course.sections_visible_to(@student1)).to eq [@course.default_section]
      end

      it "ignores concluded sections if option is given" do
        @student1 = student_in_section(@other_section, { active_all: true })
        @student1.enrollments.each(&:conclude)

        all_sections = @course.course_sections
        expect(@course.sections_visible_to(@student1, all_sections, excluded_workflows: ["deleted", "completed"])).to be_empty
      end

      it "includes concluded secitions if no options" do
        @student1 = student_in_section(@other_section, { active_all: true })
        @student1.enrollments.each(&:conclude)

        all_sections = @course.course_sections
        expect(@course.sections_visible_to(@student1, all_sections)).to eq [@other_section]
      end

      it "returns users from all sections" do
        expect(@course.users_visible_to(@teacher).sort_by(&:id)).to eql [@teacher, @ta, @student1, @student2, @observer]
        expect(@course.users_visible_to(@ta).sort_by(&:id)).to      eql [@teacher, @ta, @student1, @observer]
      end

      it "returns users including inactive when included from all sections" do
        enrollment = @course.enrollments.where(user: @student2).first
        enrollment.deactivate

        expect(@course.users_visible_to(@teacher, include: [:inactive])).to include(@student2)
      end

      it "does not return inactive users when not included from all sections" do
        enrollment = @course.enrollments.where(user: @student2).first
        enrollment.deactivate

        expect(@course.users_visible_to(@teacher)).not_to include(@student2)
      end

      it "returns users including concluded when included from all sections" do
        enrollment = @course.enrollments.where(user: @student2).first
        enrollment.conclude

        expect(@course.users_visible_to(@teacher, include: [:completed])).to include(@student2)
      end

      it "does not return concluded users when not included from all sections" do
        enrollment = @course.enrollments.where(user: @student2).first
        enrollment.conclude

        expect(@course.users_visible_to(@teacher)).not_to include(@student2)
      end

      it "does not return observers to section-restricted students" do
        section2 = @course.course_sections.create!
        limited_student = user_factory(active_all: true)
        @course.enroll_user(limited_student,
                            "StudentEnrollment",
                            enrollment_state: "active",
                            section: section2,
                            limit_privileges_to_course_section: true)

        limited_teacher = user_factory(active_all: true)
        @course.enroll_user(limited_teacher,
                            "TeacherEnrollment",
                            enrollment_state: "active",
                            section: section2,
                            limit_privileges_to_course_section: true)

        observer = user_factory(active_all: true)
        @course.enroll_user(observer, "ObserverEnrollment", enrollment_state: "active", section: section2)
        expect(@course.users_visible_to(limited_student)).not_to include(observer)
        expect(@course.users_visible_to(limited_teacher)).to include(observer)
      end

      it "returns student view students to account admins" do
        @course.student_view_student
        @admin = account_admin_user
        visible_enrollments = @course.apply_enrollment_visibility(@course.student_enrollments, @admin)
        expect(visible_enrollments.map(&:user)).to include(@course.student_view_student)
      end

      it "is safely empty for a nil user" do
        visible_enrollments = @course.apply_enrollment_visibility(@course.student_enrollments, nil)
        expect(visible_enrollments.count).to eq(0)
      end

      it "returns student view students to account admins who are also observers for some reason" do
        @course.student_view_student
        @admin = account_admin_user

        @course.enroll_user(@admin, "ObserverEnrollment")

        visible_enrollments = @course.apply_enrollment_visibility(@course.student_enrollments, @admin)
        expect(visible_enrollments.map(&:user)).to include(@course.student_view_student)
      end

      it "returns student view students to student view students" do
        visible_enrollments = @course.apply_enrollment_visibility(@course.student_enrollments, @course.student_view_student)
        expect(visible_enrollments.map(&:user)).to include(@course.student_view_student)
      end
    end

    context "sections" do
      it "returns students from user's sections" do
        expect(@course.students_visible_to(@ta)).to eq [@student1]
      end

      it "returns user's sections" do
        expect(@course.sections_visible_to(@ta)).to eq [@course.default_section]
      end

      it "returns non-limited admins from other sections" do
        expect(@course.apply_enrollment_visibility(@course.teachers, @ta)).to eq [@teacher]
      end
    end

    context "restricted" do
      it "returns no students except self and the observed" do
        expect(@course.students_visible_to(@observer)).to eq [@student1]
        RoleOverride.create!(context: @course.account,
                             permission: "read_roster",
                             role: student_role,
                             enabled: false)
        expect(@course.students_visible_to(@student1)).to eq [@student1]
      end

      it "returns student's sections" do
        expect(@course.sections_visible_to(@observer)).to eq [@course.default_section]
        RoleOverride.create!(context: @course.account,
                             permission: "read_roster",
                             role: student_role,
                             enabled: false)
        expect(@course.sections_visible_to(@student1)).to eq [@course.default_section]
      end
    end

    context "require_message_permission" do
      it "checks the message permission" do
        expect(@course.enrollment_visibility_level_for(@teacher, @course.section_visibilities_for(@teacher), require_message_permission: true)).to be :full
        expect(@course.enrollment_visibility_level_for(@observer, @course.section_visibilities_for(@observer), require_message_permission: true)).to be :restricted
        RoleOverride.create!(context: @course.account,
                             permission: "send_messages",
                             role: student_role,
                             enabled: false)
        expect(@course.enrollment_visibility_level_for(@student1, @course.section_visibilities_for(@student1), require_message_permission: true)).to be :restricted
      end
    end
  end

  context "enrollments" do
    it "updates enrollments' root_account_id when necessary" do
      a1 = Account.create!
      a2 = Account.create!

      course_with_student
      @course.root_account = a1
      @course.save!

      expect(@course.student_enrollments.map(&:root_account_id)).to eq [a1.id]
      expect(@course.course_sections.reload.map(&:root_account_id)).to eq [a1.id]

      @course.root_account = a2
      @course.save!
      expect(@course.student_enrollments.reload.map(&:root_account_id)).to eq [a2.id]
      expect(@course.course_sections.reload.map(&:root_account_id)).to eq [a2.id]
    end
  end

  describe "#sync_homeroom_enrollments" do
    before :once do
      @homeroom_course = course_factory(active_course: true)
      toggle_k5_setting(@homeroom_course.account, true)
      @homeroom_course.homeroom_course = true
      @homeroom_course.save!

      @teacher = user_with_pseudonym
      @homeroom_course.enroll_teacher(@teacher).accept

      @ta = user_with_pseudonym
      @homeroom_course.enroll_user(@ta, "TaEnrollment").accept

      @student = user_with_pseudonym
      @homeroom_course.enroll_user(@student, "StudentEnrollment").accept

      @observer = user_with_pseudonym
      @homeroom_course.enroll_user(@observer, "ObserverEnrollment", associated_user_id: @student.id).accept

      @course = course_factory(active_course: true, account: @homeroom_course.account)
      @course.sync_enrollments_from_homeroom = true
      @course.homeroom_course_id = @homeroom_course.id
      @course.save!
    end

    it "copies enrollments the homeroom course" do
      expect(@course.user_is_instructor?(@teacher)).to be(false)
      expect(@course.user_is_instructor?(@ta)).to be(false)
      expect(@course.user_is_student?(@student)).to be(false)
      expect(@course.user_has_been_observer?(@observer)).to be(false)
      @course.sync_homeroom_enrollments
      expect(@course.user_is_instructor?(@teacher)).to be(true)
      expect(@course.user_is_instructor?(@ta)).to be(true)
      expect(@course.user_is_student?(@student)).to be(true)
      expect(@course.user_has_been_observer?(@observer)).to be(true)
      expect(@course.observer_enrollments.first.associated_user_id).to eq(@student.id)
    end

    it "readds enrollments deleted on subject courses" do
      @course.sync_homeroom_enrollments
      @course.enrollments.find_by(user: @teacher).destroy
      expect(@course.user_is_instructor?(@teacher)).to be(false)
      @course.sync_homeroom_enrollments
      expect(@course.user_is_instructor?(@teacher)).to be(true)
    end

    it "removes enrollments on subject courses when removed on the homeroom" do
      @course.sync_homeroom_enrollments
      expect(@course.user_is_instructor?(@teacher)).to be(true)
      @homeroom_course.enrollments.find_by(user: @teacher).destroy
      @course.sync_homeroom_enrollments
      expect(@course.user_is_instructor?(@teacher)).to be(false)
    end

    it "copies custom roles and enrollment dates" do
      role = Account.default.roles.create!(name: "Cool Student", base_role_type: "StudentEnrollment")
      e1 = @homeroom_course.enroll_student(@student, role:, start_at: 1.day.ago.beginning_of_day, end_at: 1.day.from_now.beginning_of_day, allow_multiple_enrollments: true)
      e1.conclude
      @course.sync_homeroom_enrollments
      expect(@course.enrollments.where(user_id: @student.id).size).to eq 2
      e2 = @course.enrollments.where(user_id: @student.id, role_id: role.id).take
      expect(e2.role_id).to eq role.id
      expect(e2.start_at).to eq e1.start_at
      expect(e2.end_at).to eq e1.end_at
      expect(e2.completed_at).to eq e1.completed_at
    end

    it "returns false unless course is an elementary subject and sync setting is on and homeroom_course_id is set" do
      @course.sync_enrollments_from_homeroom = false
      @course.save!
      expect(@course.sync_homeroom_enrollments).to be(false)
      @course.sync_enrollments_from_homeroom = true
      @course.homeroom_course_id = nil
      @course.save!
      expect(@course.sync_homeroom_enrollments).to be(false)
      @course.homeroom_course_id = @homeroom_course.id
      @course.save!
      expect(@course.sync_homeroom_enrollments).not_to be(false)
    end

    it "returns false if course has a SIS batch id" do
      batch = @course.root_account.sis_batches.create!
      @course.sis_batch_id = batch.id
      @course.save!
      expect(@course.sync_homeroom_enrollments).to be(false)
    end

    it "returns false if linked homeroom course is deleted" do
      @homeroom_course.destroy!
      expect(@course.sync_homeroom_enrollments).to be(false)
    end

    it "returns false if linked homeroom course is no longer a homeroom course" do
      @homeroom_course.homeroom_course = false
      @homeroom_course.save!
      expect(@course.sync_homeroom_enrollments).to be(false)
    end

    it "works with linked observers observing multiple students" do
      student2 = user_with_pseudonym
      UserObservationLink.create_or_restore(observer: @observer, student: @student, root_account: @course.root_account)
      UserObservationLink.create_or_restore(observer: @observer, student: student2, root_account: @course.root_account)
      @homeroom_course.enroll_user(student2, "StudentEnrollment").accept
      @course.sync_homeroom_enrollments
      expect(@observer.enrollments.where(course_id: @course).pluck(:associated_user_id)).to match_array([@student.id, student2.id])
    end

    context "cross-shard" do
      specs_require_sharding

      before :once do
        @shard1.activate do
          account = Account.create!
          toggle_k5_setting(account, true)
          @cross_shard_course = course_factory(account:, active_course: true)
          @cross_shard_course.sync_enrollments_from_homeroom = true
          @cross_shard_course.homeroom_course_id = @homeroom_course.id
          @cross_shard_course.save!
        end
      end

      it "syncs enrollments across shards" do
        expect(@cross_shard_course.user_is_instructor?(@teacher)).to be(false)
        expect(@cross_shard_course.user_is_instructor?(@ta)).to be(false)
        expect(@cross_shard_course.user_is_student?(@student)).to be(false)
        expect(@cross_shard_course.user_has_been_observer?(@observer)).to be(false)
        @cross_shard_course.sync_homeroom_enrollments
        expect(@cross_shard_course.user_is_instructor?(@teacher)).to be(true)
        expect(@cross_shard_course.user_is_instructor?(@ta)).to be(true)
        expect(@cross_shard_course.user_is_student?(@student)).to be(true)
        expect(@cross_shard_course.user_has_been_observer?(@observer)).to be(true)
      end
    end
  end

  describe "#sync_homeroom_participation" do
    before :once do
      @homeroom_course = course_factory(active_course: true)
      toggle_k5_setting(@homeroom_course.account, true)
      @homeroom_course.homeroom_course = true
      @homeroom_course.save!

      @course = course_factory(active_course: true, account: @homeroom_course.account)
      @course.sync_enrollments_from_homeroom = true
      @course.homeroom_course_id = @homeroom_course.id
      @course.save!
    end

    it "syncs enrollment term from homeroom" do
      homeroom_term = @homeroom_course.account.enrollment_terms.create!(end_at: 1.week.ago, name: "homeroom term")
      @homeroom_course.restrict_enrollments_to_course_dates = false
      @homeroom_course.enrollment_term = homeroom_term
      @homeroom_course.save!
      @course.sync_homeroom_participation
      expect(@course.restrict_enrollments_to_course_dates).to be_falsey
      expect(@course.enrollment_term.name).to eql @homeroom_course.enrollment_term.name
    end

    it "syncs course dates from homeroom" do
      @homeroom_course.restrict_enrollments_to_course_dates = true
      @homeroom_course.start_at = 7.days.ago
      @homeroom_course.conclude_at = 1.day.ago
      @homeroom_course.save!
      @course.sync_homeroom_participation
      expect(@course.restrict_enrollments_to_course_dates).to be_truthy
      expect(@course.start_at).to eq @homeroom_course.start_at
      expect(@course.conclude_at).to eq @homeroom_course.conclude_at
    end

    it "does not sync participation settings if course has a SIS batch id" do
      batch = @course.root_account.sis_batches.create!
      @course.sis_batch_id = batch.id
      @course.save!
      @homeroom_course.restrict_enrollments_to_course_dates = true
      @homeroom_course.save!
      @course.sync_homeroom_participation
      expect(@course.restrict_enrollments_to_course_dates).to be_falsey
    end

    it "does not sync participation settings if linked homeroom course is deleted" do
      @homeroom_course.restrict_enrollments_to_course_dates = true
      @homeroom_course.save!
      @homeroom_course.destroy!
      @course.sync_homeroom_participation
      expect(@course.restrict_enrollments_to_course_dates).to be_falsey
    end

    it "does not sync participation settings if linked homeroom course is no longer a homeroom course" do
      @homeroom_course.restrict_enrollments_to_course_dates = true
      @homeroom_course.homeroom_course = false
      @homeroom_course.save!
      @course.sync_homeroom_participation
      expect(@course.restrict_enrollments_to_course_dates).to be_falsey
    end

    it "doesn't process courses with no linked homeroom" do
      @course.homeroom_course_id = nil
      @course.save!
      expect { Course.sync_with_homeroom }.not_to raise_error
    end
  end

  describe "#user_is_instructor?" do
    before :once do
      @course = Course.create
      user_with_pseudonym
    end

    it "is true for teachers" do
      course = @course
      teacher = @user
      course.enroll_teacher(teacher).accept
      expect(course.user_is_instructor?(teacher)).to be_truthy
    end

    it "is true for tas" do
      course = @course
      ta = @user
      course.enroll_ta(ta).accept
      expect(course.user_is_instructor?(ta)).to be_truthy
    end

    it "is false for designers" do
      course = @course
      designer = @user
      course.enroll_designer(designer).accept
      expect(course.user_is_instructor?(designer)).to be_falsey
    end
  end

  describe "#user_has_been_instructor?" do
    it "is true for teachers, past or present" do
      e = course_with_teacher(active_all: true)
      expect(@course.user_has_been_instructor?(@teacher)).to be_truthy

      e.conclude
      expect(e.reload.workflow_state).to eq "completed"
      expect(@course.user_has_been_instructor?(@teacher)).to be_truthy

      @course.complete
      expect(@course.user_has_been_instructor?(@teacher)).to be_truthy
    end

    it "is true for tas" do
      course_with_ta(active_all: true)
      expect(@course.user_has_been_instructor?(@ta)).to be_truthy
    end
  end

  describe "#user_has_been_admin?" do
    it "is true for teachers, past or present" do
      e = course_with_teacher(active_all: true)
      expect(@course.user_has_been_admin?(@teacher)).to be_truthy

      e.conclude
      expect(e.reload.workflow_state).to eq "completed"
      expect(@course.user_has_been_admin?(@teacher)).to be_truthy

      @course.complete
      expect(@course.user_has_been_admin?(@teacher)).to be_truthy
    end

    it "is true for tas" do
      course_with_ta(active_all: true)
      expect(@course.user_has_been_admin?(@ta)).to be_truthy
    end

    it "is true for designers" do
      course_with_designer(active_all: true)
      expect(@course.user_has_been_admin?(@designer)).to be_truthy
    end
  end

  describe "#user_has_been_student?" do
    it "is true for students, past or present" do
      e = course_with_student(active_all: true)
      expect(@course.user_has_been_student?(@student)).to be_truthy

      e.conclude
      expect(e.reload.workflow_state).to eq "completed"
      expect(@course.user_has_been_student?(@student)).to be_truthy

      @course.complete
      expect(@course.user_has_been_student?(@student)).to be_truthy
    end
  end

  describe "#user_has_been_observer?" do
    it "is false for teachers" do
      course_with_teacher(active_all: true)
      expect(@course.user_has_been_observer?(@teacher)).to be_falsey
    end

    it "is false for tas" do
      course_with_ta(active_all: true)
      expect(@course.user_has_been_observer?(@ta)).to be_falsey
    end

    it "is true for observers" do
      course_with_observer(active_all: true)
      expect(@course.user_has_been_observer?(@observer)).to be_truthy
    end
  end

  describe Course, "#student_view_student" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "creates a default section when enrolling for student view student" do
      student_view_course = Course.create!
      expect(student_view_course.course_sections).to be_empty

      student_view_student = student_view_course.student_view_student

      expect(student_view_course.enrollments.map(&:user_id)).to include(student_view_student.id)
    end

    it "does not create a section if a section already exists" do
      student_view_course = Course.create!
      not_default_section = student_view_course.course_sections.create! name: "not default section"
      expect(not_default_section).not_to be_default_section
      student_view_student = student_view_course.student_view_student
      expect(student_view_course.reload.course_sections.active.count).to be 1
      expect(not_default_section.enrollments.map(&:user_id)).to include(student_view_student.id)
    end

    it "creates and return the student view student for a course" do
      expect { @course.student_view_student }.to change(User, :count).by(1)
    end

    it "finds and return the student view student on successive calls" do
      @course.student_view_student
      expect { @course.student_view_student }.not_to change(User, :count)
    end

    it "creates enrollments for each section" do
      @section2 = @course.course_sections.create!
      expect { @fake_student = @course.student_view_student }.to change(Enrollment, :count).by(2)
      expect(@fake_student.enrollments.all?(&:fake_student?)).to be_truthy
    end

    it "syncs enrollments after being created" do
      @course.student_view_student
      @section2 = @course.course_sections.create!
      expect { @course.student_view_student }.to change(Enrollment, :count).by(1)
    end

    it "creates a pseudonym for the fake student" do
      expect { @fake_student = @course.student_view_student }.to change(Pseudonym, :count).by(1)
      expect(@fake_student.pseudonyms).not_to be_empty
    end

    it "allows two different student view users for two different courses" do
      @course1 = @course
      @teacher1 = @teacher
      course_with_teacher(active_all: true)
      @course2 = @course
      @teacher2 = @teacher

      @fake_student1 = @course1.student_view_student
      @fake_student2 = @course2.student_view_student

      expect(@fake_student1.id).not_to eql @fake_student2.id
      expect(@fake_student1.pseudonym.id).not_to eql @fake_student2.pseudonym.id
    end

    it "gives fake student active student permissions even if enrollment wouldn't otherwise be active" do
      @course.enrollment_term.update(start_at: 2.days.from_now, end_at: 4.days.from_now)
      @fake_student = @course.student_view_student
      expect(@course.grants_right?(@fake_student, nil, :read_forum)).to be_truthy
    end

    it "does not update the fake student's enrollment state to 'invited' in a concluded course" do
      @course.student_view_student
      @course.enrollment_term.update(start_at: 4.days.ago, end_at: 2.days.ago)
      @fake_student = @course.student_view_student
      expect(@fake_student.enrollments.where(course_id: @course).map(&:workflow_state)).to eql(["active"])
    end
  end

  describe "#user_list_search_mode_for" do
    it "is open for anyone if open registration is turned on" do
      account = Account.default
      account.settings = { open_registration: true }
      account.save!
      course_factory
      expect(@course.user_list_search_mode_for(nil)).to eq :open
      expect(@course.user_list_search_mode_for(user_factory)).to eq :open
    end

    it "is preferred for account admins" do
      account = Account.default
      course_factory
      expect(@course.user_list_search_mode_for(nil)).to eq :closed
      expect(@course.user_list_search_mode_for(user_factory)).to eq :closed
      user_factory
      account.account_users.create!(user: @user)
      expect(@course.user_list_search_mode_for(@user)).to eq :preferred
    end

    it "is preferred if delegated authentication is configured" do
      account = Account.create!
      account.authentication_providers.create!(auth_type: "cas")
      account.authentication_providers.first.move_to_bottom
      account.settings[:open_registration] = true
      account.save!
      course_factory(account:)
      expect(@course.user_list_search_mode_for(nil)).to eq :preferred
      expect(@course.user_list_search_mode_for(user_factory)).to eq :preferred
    end
  end

  context "self_enrollment" do
    let_once(:c1) do
      Account.default.allow_self_enrollment!
      course_factory
    end
    it "generates a unique code" do
      expect(c1.self_enrollment_code).to be_nil # normally only set when self_enrollment is enabled
      c1.update_attribute(:self_enrollment, true)
      expect(c1.self_enrollment_code).not_to be_nil
      expect(c1.self_enrollment_code).to match(/\A[A-Z0-9]{6}\z/)

      c2 = course_factory
      c2.update_attribute(:self_enrollment, true)
      expect(c2.self_enrollment_code).to match(/\A[A-Z0-9]{6}\z/)
      expect(c1.self_enrollment_code).not_to eq c2.self_enrollment_code
    end

    it "generates a code on demand for existing self enrollment courses" do
      Course.where(id: @course).update_all(self_enrollment: true)
      c1.reload
      expect(c1.read_attribute(:self_enrollment_code)).to be_nil
      expect(c1.self_enrollment_code).not_to be_nil
      expect(c1.self_enrollment_code).to match(/\A[A-Z0-9]{6}\z/)
    end
  end

  describe "permission policies" do
    before :once do
      @course = course_model
    end

    before do
      @course.write_attribute(:workflow_state, "available")
      @course.write_attribute(:is_public, true)
    end

    it "can be read by a nil user if public and available" do
      expect(@course.check_policy(nil)).to eq %i[read read_outcomes read_syllabus read_files]
    end

    it "cannot be read by a nil user if public but not available" do
      @course.write_attribute(:workflow_state, "created")
      expect(@course.check_policy(nil)).to eq []
    end

    describe "when course is unpublished" do
      before do
        @course.write_attribute(:workflow_state, "claimed")
        @course.write_attribute(:is_public, false)
      end

      let_once(:user) { user_model }

      it "does not allow students to read files" do
        user.student_enrollments.create!(workflow_state: "active", course: @course)
        expect(@course.check_policy(user)).to_not include :read_files
      end

      it "allows teachers to read files" do
        user.teacher_enrollments.create!(workflow_state: "active", course: @course)
        expect(@course.check_policy(user)).to include :read_files
      end
    end

    describe "when course is not public" do
      before do
        @course.write_attribute(:is_public, false)
      end

      let_once(:user) { user_model }

      it "cannot be read by a nil user" do
        expect(@course.check_policy(nil)).to eq []
      end

      it "cannot be read by an unaffiliated user" do
        expect(@course.check_policy(user)).to eq []
      end

      it "can be read by a prior user" do
        user.student_enrollments.create!(workflow_state: "completed", course: @course)
        expect(@course.check_policy(user).sort).to eq %i[read read_announcements read_as_member read_files read_forum read_grades read_outcomes read_syllabus]
      end

      it "can have its forum read by an observer" do
        enrollment = user.observer_enrollments.create!(workflow_state: "completed", course: @course)
        enrollment.update_attribute(:associated_user_id, user.id)
        expect(@course.check_policy(user)).to include :read_forum
      end

      describe "an instructor policy" do
        subject { @course.check_policy(instructor) }

        let(:instructor) do
          user.teacher_enrollments.create!(workflow_state: "completed", course: @course)
          user
        end

        it { is_expected.to include :read_prior_roster }
        it { is_expected.to include :view_all_grades }

        it "without granular permissions" do
          @course.root_account.disable_feature!(:granular_permissions_manage_courses)
          expect(subject).to include :delete
        end

        it "with granular permissions" do
          @course.root_account.enable_feature!(:granular_permissions_manage_courses)
          expect(subject).not_to include :delete
        end
      end
    end

    describe "direct_share permission" do
      it "returns false for a student in an active course" do
        student_in_course(active_all: true)
        expect(@course.grants_right?(@student, :direct_share)).to be(false)
      end

      it "returns false for a student in a concluded course" do
        @course.complete!
        student_in_course(active_all: true)
        expect(@course.grants_right?(@student, :direct_share)).to be(false)
      end

      it "returns true for an account admin" do
        account_admin_user(active_all: true, account: @course.account)
        expect(@course.grants_right?(@user, :direct_share)).to be(true)
      end

      it "returns true for teacher with manage_course_content_add" do
        teacher_in_course(active_all: true)
        expect(@course.grants_right?(@teacher, :direct_share)).to be(true)
      end

      it "returns false for teacher in active course without manage_course_content_add" do
        RoleOverride.create!(context: @course.account, permission: "manage_course_content_add", role: teacher_role, enabled: false)
        teacher_in_course(active_all: true)
        expect(@course.grants_right?(@teacher, :direct_share)).to be(false)
      end

      it "returns true for teacher in concluded course without manage_course_content_add" do
        RoleOverride.create!(context: @course.account, permission: "manage_course_content_add", role: teacher_role, enabled: false)
        @course.complete!
        teacher_in_course
        expect(@course.grants_right?(@teacher, :direct_share)).to be(true)
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "properly returns site admin permissions from another shard" do
      enable_cache do
        @shard1.activate do
          acct = Account.create!
          course_with_student(active_all: 1, account: acct)
          @course.root_account.disable_feature!(:granular_permissions_manage_course_content)
        end
        @site_admin = user_factory
        site_admin = Account.site_admin
        site_admin.account_users.create!(user: @user)

        @shard1.activate do
          expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
          expect(@course.grants_right?(@teacher, :manage_content)).to be_truthy
          expect(@course.grants_right?(@student, :manage_content)).to be_falsey
        end

        expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
      end

      enable_cache do
        # do it in a different order
        @shard1.activate do
          expect(@course.grants_right?(@student, :manage_content)).to be_falsey
          expect(@course.grants_right?(@teacher, :manage_content)).to be_truthy
          expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
        end

        expect(@course.grants_right?(@site_admin, :manage_content)).to be_truthy
      end
    end

    it "properly returns site admin permissions from another shard (granular permissions)" do
      enable_cache do
        @shard1.activate do
          acct = Account.create!
          course_with_student(active_all: 1, account: acct)
          @course.root_account.enable_feature!(:granular_permissions_manage_course_content)
        end
        @site_admin = user_factory
        site_admin = Account.site_admin
        site_admin.account_users.create!(user: @user)

        @shard1.activate do
          expect(@course.grants_all_rights?(@site_admin, :manage_course_content_add)).to be_truthy
          expect(@course.grants_all_rights?(@teacher, :manage_course_content_add)).to be_truthy
          expect(@course.grants_all_rights?(@student, :manage_course_content_add)).to be_falsey
        end

        expect(@course.grants_all_rights?(@site_admin, :manage_course_content_add)).to be_truthy
      end

      enable_cache do
        # do it in a different order
        @shard1.activate do
          expect(@course.grants_all_rights?(@student, :manage_course_content_add)).to be_falsey
          expect(@course.grants_all_rights?(@teacher, :manage_course_content_add)).to be_truthy
          expect(@course.grants_all_rights?(@site_admin, :manage_course_content_add)).to be_truthy
        end

        expect(@course.grants_all_rights?(@site_admin, :manage_course_content_add)).to be_truthy
      end
    end

    it "activates shard for new student view students" do
      course_model
      @shard1.activate do
        expect { @course.student_view_student }.not_to raise_error
      end
    end

    it "grants enrollment-based permissions regardless of shard" do
      @shard1.activate do
        account = Account.create!
        course_factory(active_course: true, account:)
      end

      @shard2.activate do
        user_factory(active_user: true)
      end

      student_in_course(user: @user, active_all: true)

      @shard1.activate do
        expect(@course.grants_right?(@user, :send_messages)).to be_truthy
      end

      @shard2.activate do
        expect(@course.grants_right?(@user, :send_messages)).to be_truthy
      end
    end
  end

  context "named scopes" do
    context "enrollments" do
      before :once do
        account_model
        # has enrollments
        @course1a = course_with_student(account: @account, course_name: "A").course
        @course1b = course_with_student(account: @account, course_name: "B").course

        # has no enrollments
        @course2a = Course.create!(account: @account, name: "A")
        @course2b = Course.create!(account: @account, name: "B")
      end

      describe "#with_enrollments" do
        it "includes courses with enrollments" do
          expect(@account.courses.with_enrollments.sort_by(&:id)).to eq [@course1a, @course1b]
        end

        it "plays nice with other scopes" do
          expect(@account.courses.with_enrollments.where(name: "A")).to eq [@course1a]
        end

        it "is disjoint with #without_enrollments" do
          expect(@account.courses.with_enrollments.without_enrollments).to be_empty
        end
      end

      describe "#without_enrollments" do
        it "includes courses without enrollments" do
          expect(@account.courses.without_enrollments.sort_by(&:id)).to eq [@course2a, @course2b]
        end

        it "plays nice with other scopes" do
          expect(@account.courses.without_enrollments.where(name: "A")).to eq [@course2a]
        end
      end
    end

    context "completion" do
      before :once do
        account_model
        # non-concluded
        @c1 = Course.create!(account: @account)

        @c2 = Course.create!(account: @account, conclude_at: 1.week.from_now)
        @c2.enrollment_term = @c2.account.enrollment_terms.create! end_at: 2.weeks.ago
        @c2.save!

        # concluded in various ways
        @c3 = Course.create!(account: @account, conclude_at: 1.week.ago)

        @c4 = Course.create!(account: @account)
        term = @c4.account.enrollment_terms.create! end_at: 2.weeks.ago
        @c4.enrollment_term = term
        @c4.save!

        @c5 = Course.create!(account: @account)
        @c5.complete!

        @c6 = Course.create!(account: @account, conclude_at: 1.week.ago)
        @c6.enrollment_term = @c6.account.enrollment_terms.create! end_at: 2.weeks.from_now
        @c6.save!
      end

      describe "#completed" do
        it "includes completed courses" do
          expect(@account.courses.completed.sort_by(&:id)).to eq [@c3, @c4, @c5, @c6]
        end

        it "plays nice with other scopes" do
          expect(@account.courses.completed.where(conclude_at: nil)).to eq [@c4]
        end

        it "is disjoint with #not_completed" do
          expect(@account.courses.completed.not_completed).to be_empty
        end
      end

      describe "#not_completed" do
        it "includes non-completed courses" do
          expect(@account.courses.not_completed.sort_by(&:id)).to eq [@c1, @c2]
        end

        it "plays nice with other scopes" do
          expect(@account.courses.not_completed.where(conclude_at: nil)).to eq [@c1]
        end
      end
    end

    describe "#by_teachers" do
      before :once do
        account_model
        @course1a = course_with_teacher(account: @account, name: "teacher A's first course").course
        @teacherA = @teacher
        @course1b = course_with_teacher(account: @account, name: "teacher A's second course", user: @teacherA).course
        @course2 = course_with_teacher(account: @account, name: "teacher B's course").course
        @teacherB = @teacher
        @course3 = course_with_teacher(account: @account, name: "teacher C's course").course
        @teacherC = @teacher
      end

      it "filters courses by teacher" do
        expect(@account.courses.by_teachers([@teacherA.id]).sort_by(&:id)).to eq [@course1a, @course1b]
      end

      it "supports multiple teachers" do
        expect(@account.courses.by_teachers([@teacherB.id, @teacherC.id]).sort_by(&:id)).to eq [@course2, @course3]
      end

      it "works with an empty array" do
        expect(@account.courses.by_teachers([])).to be_empty
      end

      it "does not follow student enrollments" do
        @course3.enroll_student(user_model)
        expect(@account.courses.by_teachers([@user.id])).to be_empty
      end

      it "does not follow deleted enrollments" do
        @teacherC.enrollments.each(&:destroy)
        expect(@account.courses.by_teachers([@teacherB.id, @teacherC.id]).sort_by(&:id)).to eq [@course2]
      end

      it "returns no results when the user is not enrolled in the course" do
        user_model
        expect(@account.courses.by_teachers([@user.id])).to be_empty
      end

      it "plays nice with other scopes" do
        @course1a.complete!
        expect(@account.courses.by_teachers([@teacherA.id]).completed).to eq [@course1a]
      end
    end

    describe "#by_associated_accounts" do
      before :once do
        @root_account = account_model
        @sub = account_model(name: "sub", parent_account: @root_account, root_account: @root_account)
        @subA = account_model(name: "subA", parent_account: @sub1, root_account: @root_account)
        @courseA1 = course_model(account: @subA, name: "A1")
        @courseA2 = course_model(account: @subA, name: "A2")
        @subB = account_model(name: "subB", parent_account: @sub1, root_account: @root_account)
        @courseB = course_model(account: @subB, name: "B")
        @other_root_account = account_model(name: "other")
        @courseC = course_model(account: @other_root_account)
      end

      it "filters courses by root account" do
        expect(Course.by_associated_accounts([@root_account.id]).sort_by(&:id)).to eq [@courseA1, @courseA2, @courseB]
      end

      it "filters courses by subaccount" do
        expect(Course.by_associated_accounts([@subA.id]).sort_by(&:id)).to eq [@courseA1, @courseA2]
      end

      it "returns no results if already scoped to an unrelated account" do
        expect(@other_root_account.courses.by_associated_accounts([@root_account.id])).to be_empty
      end

      it "accepts multiple account IDs" do
        expect(Course.by_associated_accounts([@subB.id, @other_root_account.id]).sort_by(&:id)).to eq [@courseB, @courseC]
      end

      it "plays nice with other scopes" do
        @courseA1.complete!
        expect(Course.by_associated_accounts([@subA.id]).not_completed).to eq [@courseA2]
      end
    end
  end

  describe "#includes_student" do
    let_once(:course) { course_model }

    it "returns true when the provided user is a student" do
      student = user_model
      student.student_enrollments.create!(course:)
      expect(course.includes_student?(student)).to be_truthy
    end

    it "returns false when the provided user is not a student" do
      expect(course.includes_student?(User.create!)).to be_falsey
    end

    it "returns false when the user is not yet even in the database" do
      expect(course.includes_student?(User.new)).to be_falsey
    end

    it "returns false when the provided user is nil" do
      expect(course.includes_student?(nil)).to be_falsey
    end
  end

  context "re-enrollments" do
    it "updates concluded enrollment on re-enrollment" do
      @course = course_factory(active_all: true)

      @user1 = user_model
      @user1.sortable_name = "jonny"
      @user1.save
      @course.enroll_user(@user1)

      enrollment_count = @course.enrollments.count

      @course.complete
      @course.unconclude

      @course.enroll_user(@user1)

      expect(@course.enrollments.count).to eq enrollment_count
    end

    it "does not set an active enrollment back to invited on re-enrollment" do
      course_factory(active_all: true)
      user_factory
      enrollment = @course.enroll_user(@user)
      enrollment.accept!

      expect(enrollment).to be_active

      @course.enroll_user(@user)

      enrollment.reload
      expect(enrollment).to be_active
    end

    it "allows deleted enrollments to be resurrected as active" do
      course_with_student({ active_enrollment: true })
      @enrollment.destroy
      @enrollment = @course.enroll_user(@user, "StudentEnrollment", { enrollment_state: "active" })
      expect(@enrollment.workflow_state).to eql "active"
    end

    context "SIS re-enrollments" do
      before :once do
        course_with_student({ active_enrollment: true })
        batch = Account.default.sis_batches.create!
        # Both of these need to be defined, as they're both involved in SIS imports
        # and expected manual enrollment behavior
        @enrollment.sis_batch_id = batch.id
        @enrollment.save
      end

      it "retains SIS attributes if re-enrolled, but the SIS enrollment is still active" do
        e2 = @course.enroll_student @user
        expect(e2.sis_batch_id).not_to eql nil
      end

      it "removes SIS attributes from enrollments when re-created manually" do
        @enrollment.destroy
        @enrollment = @course.enroll_student @user
        expect(@enrollment.sis_batch_id).to be_nil
      end
    end

    context "unique enrollments" do
      before :once do
        course_factory(active_all: true)
        user_factory
        @section2 = @course.course_sections.create!
        @course.enroll_user(@user, "StudentEnrollment", section: @course.default_section).reject!
        @course.enroll_user(@user, "StudentEnrollment", section: @section2, allow_multiple_enrollments: true).reject!
      end

      it "does not cause problems moving a user between sections (s1)" do
        expect(@user.enrollments.count).to eq 2
        # this should not cause a unique constraint violation
        @course.enroll_user(@user, "StudentEnrollment", section: @course.default_section)
      end

      it "does not cause problems moving a user between sections (s2)" do
        expect(@user.enrollments.count).to eq 2
        # this should not cause a unique constraint violation
        @course.enroll_user(@user, "StudentEnrollment", section: @section2)
      end
    end

    describe "already_enrolled" do
      before :once do
        course_factory
        user_factory
      end

      it "is not set for a new enrollment" do
        expect(@course.enroll_user(@user).already_enrolled).not_to be_truthy
      end

      it "is set for an updated enrollment" do
        @course.enroll_user(@user)
        expect(@course.enroll_user(@user).already_enrolled).to be_truthy
      end
    end

    context "custom roles" do
      before :once do
        @account = Account.default
        course_factory
        user_factory
        @lazy_role = custom_student_role("LazyStudent")
        @honor_role = custom_student_role("HonorStudent") # ba-dum-tssh
      end

      it "re-uses an enrollment with the same role" do
        enrollment1 = @course.enroll_user(@user, "StudentEnrollment", role: @honor_role)
        enrollment2 = @course.enroll_user(@user, "StudentEnrollment", role: @honor_role)
        expect(@user.enrollments.count).to be 1
        expect(enrollment1).to eql enrollment2
      end

      it "does not re-use an enrollment with a different role" do
        enrollment1 = @course.enroll_user(@user, "StudentEnrollment", role: @lazy_role)
        enrollment2 = @course.enroll_user(@user, "StudentEnrollment", role: @honor_role)
        expect(@user.enrollments.count).to be 2
        expect(enrollment1).to_not eql enrollment2
      end

      it "does not re-use an enrollment with no role when enrolling with a role" do
        enrollment1 = @course.enroll_user(@user, "StudentEnrollment")
        enrollment2 = @course.enroll_user(@user, "StudentEnrollment", role: @honor_role)
        expect(@user.enrollments.count).to be 2
        expect(enrollment1).to_not eql enrollment2
      end

      it "does not re-use an enrollment with a role when enrolling with no role" do
        enrollment1 = @course.enroll_user(@user, "StudentEnrollment", role: @lazy_role)
        enrollment2 = @course.enroll_user(@user, "StudentEnrollment")
        expect(@user.enrollments.count).to be 2
        expect(enrollment1).not_to eql enrollment2
      end
    end
  end

  describe "short_name_slug" do
    before :once do
      @course = course_factory(active_all: true)
    end

    it "hards truncate at 30 characters" do
      @course.short_name = "a" * 31
      expect(@course.short_name.length).to eq 31
      expect(@course.short_name_slug.length).to eq 30
      expect(@course.short_name).to match(/^#{@course.short_name_slug}/)
    end

    it "does not change the short_name" do
      short_name = "a" * 31
      @course.short_name = short_name
      expect(@course.short_name_slug).not_to eq @course.short_name
      expect(@course.short_name).to eq short_name
    end

    it "leaves short short_names alone" do
      @course.short_name = "short short_name"
      expect(@course.short_name_slug).to eq @course.short_name
    end
  end

  describe "re_send_invitations!" do
    before :once do
      @notification = Notification.create!(name: "Enrollment Invitation")
    end

    it "sends invitations" do
      course_factory(active_all: true)
      user1 = user_with_pseudonym(active_all: true)
      user2 = user_with_pseudonym(active_all: true)
      @course.enroll_student(user1)
      @course.enroll_student(user2).accept!

      dm_count = DelayedMessage.count
      count1 = DelayedMessage.where(communication_channel_id: user1.communication_channels.first).count
      @course.re_send_invitations!(@teacher)

      expect(DelayedMessage.count).to eq dm_count + 1
      expect(DelayedMessage.where(communication_channel_id: user1.communication_channels.first).count).to eq count1 + 1
    end

    it "respects section restrictions" do
      course_factory(active_all: true)
      section2 = @course.course_sections.create! name: "section2"
      user1 = user_with_pseudonym(active_all: true)
      user2 = user_with_pseudonym(active_all: true)
      ta = user_with_pseudonym(active_all: true)
      @course.enroll_student(user1)
      @course.enroll_student(user2, section: section2)
      @course.enroll_ta(ta, active_all: true, section: section2, limit_privileges_to_course_section: true)

      count1 = user1.communication_channel.delayed_messages.where(notification_id: @notification).count
      count2 = user2.communication_channel.delayed_messages.where(notification_id: @notification).count

      @course.re_send_invitations!(ta)

      expect(user1.communication_channel.delayed_messages.where(notification_id: @notification).count).to eq count1
      expect(user2.communication_channel.delayed_messages.where(notification_id: @notification).count).to eq count2 + 1
    end
  end

  describe "grade weight notification" do
    before :once do
      course_with_student(active_all: true)
      communication_channel(@student, { username: "test@example.com", active_cc: true })
      n = Notification.create!(name: "Grade Weight Changed", category: "TestImmediately")
      NotificationPolicy.create!(notification: n, communication_channel: @student.communication_channel, frequency: "immediately")
    end

    it "sends a notification when the course scheme changes" do
      @course.update_attribute(:apply_assignment_group_weights, true)
      expect(@course.messages_sent["Grade Weight Changed"]).to be_present
    end

    it "doesn't sends a notification when the course scheme doesn't functionally change" do
      @course.update_attribute(:apply_assignment_group_weights, false) # already is functionally false but will still save a column explicitly
      expect(@course.messages_sent["Grade Weight Changed"]).to be_blank
    end
  end

  it "creates a scope that returns deleted courses" do
    @course1 = Course.create!
    @course1.workflow_state = "deleted"
    @course1.save!
    @course2 = Course.create!

    expect(Course.deleted.count).to eq 1
  end

  describe "visibility_limited_to_course_sections?" do
    before :once do
      course_factory
      @limited = { limit_privileges_to_course_section: true }
      @full = { limit_privileges_to_course_section: false }
    end

    it "is true if all visibilities are limited" do
      expect(@course.visibility_limited_to_course_sections?(nil, [@limited, @limited])).to be_truthy
    end

    it "is false if only some visibilities are limited" do
      expect(@course.visibility_limited_to_course_sections?(nil, [@limited, @full])).to be_falsey
    end

    it "is false if no visibilities are limited" do
      expect(@course.visibility_limited_to_course_sections?(nil, [@full, @full])).to be_falsey
    end

    it "is true if no visibilities are given" do
      expect(@course.visibility_limited_to_course_sections?(nil, [])).to be_truthy
    end
  end

  context "#unpublishable?" do
    it "is not unpublishable if there are active graded submissions" do
      course_with_teacher(active_all: true)
      @student = student_in_course(active_user: true).user
      expect(@course.unpublishable?).to be_truthy
      @assignment = @course.assignments.new(title: "some assignment")
      @assignment.submission_types = "online_text_entry"
      @assignment.workflow_state = "published"
      @assignment.save
      @submission = @assignment.submit_homework(@student, body: "some message")
      expect(@course.unpublishable?).to be_truthy
      @assignment.grade_student(@student, { grader: @teacher, grade: 1 })
      expect(@course.unpublishable?).to be_falsey
      @assignment.destroy
      expect(@course.unpublishable?).to be_truthy
    end
  end

  describe "#multiple_sections?" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "returns false for a class with one section" do
      expect(@course.multiple_sections?).to be_falsey
    end

    it "returns true for a class with more than one active section" do
      @course.course_sections.create!
      expect(@course.multiple_sections?).to be_truthy
    end
  end

  describe "#default_section" do
    it "creates the default section" do
      c = Course.create!
      s = c.default_section
      expect(c.course_sections.pluck(:id)).to eql [s.id]
    end

    it "unless we ask it not to" do
      c = Course.create!
      s = c.default_section(no_create: true)
      expect(s).to be_nil
      expect(c.course_sections.pluck(:id)).to be_empty
    end
  end

  describe "#student_annotation_documents_folder" do
    before do
      @course = Course.create!
    end

    it "creates a folder if not already existent" do
      expect do
        @course.student_annotation_documents_folder
      end.to change {
        Folder.where(course: @course, name: "Student Annotation Documents").count
      }.by(1)
    end

    it "initially sets the folder workflow_state to hidden" do
      folder = @course.student_annotation_documents_folder
      expect(folder.workflow_state).to eq "hidden"
    end

    it "creates a folder with a unique type" do
      folder = @course.student_annotation_documents_folder
      expect(folder.unique_type).to eq Folder::STUDENT_ANNOTATION_DOCUMENTS_UNIQUE_TYPE
    end

    it "creates a folder with the root folder as the parent folder" do
      folder = @course.student_annotation_documents_folder
      root_folder = Folder.root_folders(@course).first
      expect(folder.parent_folder).to eq root_folder
    end

    it "returns the existing folder for student annotation documents" do
      newly_made_folder = @course.student_annotation_documents_folder
      existing_folder = @course.student_annotation_documents_folder
      expect(existing_folder).to eq newly_made_folder
    end

    it "creates a new folder if one was destroyed in the past" do
      old_folder = @course.student_annotation_documents_folder
      old_folder.destroy

      expect do
        @course.student_annotation_documents_folder
      end.to change {
        Folder.where(course: @course, name: "Student Annotation Documents").count
      }.by(1)
    end
  end

  describe "#touch_root_folder_if_necessary" do
    before(:once) do
      course_with_student(active_all: true)
      @root_folder = Folder.root_folders(@course).first
    end

    it "invalidates cached permissions on the root folder when hiding or showing the files tab" do
      enable_cache do
        Timecop.freeze(2.minutes.ago) do
          @root_folder.touch
          expect(@root_folder.grants_right?(@student, :read_contents)).to be_truthy
        end

        Timecop.freeze(1.minute.ago) do
          @course.tab_configuration = [{ "id" => Course::TAB_FILES, "hidden" => true }]
          @course.save!
          AdheresToPolicy::Cache.clear # this happens between requests; we're testing the Rails cache
          expect(@root_folder.reload.grants_right?(@student, :read_contents)).to be_falsey
        end

        @course.tab_configuration = [{ "id" => Course::TAB_FILES }]
        @course.save!
        AdheresToPolicy::Cache.clear
        expect(@root_folder.reload.grants_right?(@student, :read_contents)).to be_truthy
      end
    end

    context "inheritable settings" do
      shared_examples "inherited setting should inherit" do
        before do
          account_model
          course_factory(account: @account)
        end

        def set_value(value)
          @course.send(:"#{setting}=", value)
        end

        def calculated_value
          @course.send(:"#{setting}?")
        end

        it "inherits account values by default" do
          expect(calculated_value).to be_falsey

          @account.settings[setting] = { locked: false, value: true }
          @account.save!

          expect(calculated_value).to be_truthy

          set_value(false)
          @course.save!

          expect(calculated_value).to be_falsey
        end

        it "is overridden by locked values from the account" do
          @account.settings[setting] = { locked: true, value: true }
          @account.save!

          expect(calculated_value).to be_truthy

          # explicitly setting shouldn't change anything
          set_value(false)
          @course.save!

          expect(calculated_value).to be_truthy
        end
      end

      describe "restrict_student_future_view" do
        let(:setting) { :restrict_student_future_view }

        include_examples "inherited setting should inherit"
      end

      describe "restrict_student_past_view" do
        let(:setting) { :restrict_student_past_view }

        include_examples "inherited setting should inherit"
      end

      describe "lock_all_announcements" do
        let(:setting) { :lock_all_announcements }

        include_examples "inherited setting should inherit"
      end

      describe "usage_rights_required" do
        let(:setting) { :usage_rights_required }

        include_examples "inherited setting should inherit"
      end
    end
  end

  describe "#invited_count_visible_to" do
    it "counts newly created students" do
      course_with_teacher
      student_in_course
      expect(@student.enrollments.where(course_id: @course).first).to be_creation_pending
      expect(@course.invited_count_visible_to(@teacher)).to eq(2)
    end
  end

  describe "#favorite_for_user?" do
    before :once do
      @courses = []
      @courses << course_with_student(active_all: true, course_name: "Course 0").course
      @courses << course_with_student(course_name: "Course 1", user: @user, active_all: true).course
      @user.favorites.build(context: @courses[0])
      @user.save
    end

    it "returns true if a user has a course set as a favorite" do
      expect(@courses[0].favorite_for_user?(@user)).to be(true)
    end

    it "returns false if a user has not set a course to be a favorite" do
      expect(@courses[1].favorite_for_user?(@user)).to be(false)
    end
  end

  describe "#modules_visible_to" do
    before :once do
      course_with_teacher active_all: true
      student_in_course active_enrollment: true
      @m1 = @course.context_modules.create!(name: "published 1")
      @m2 = @course.context_modules.create!(name: "published 2")
      @m3 = @course.context_modules.create!(name: "unpublished", workflow_state: "unpublished")
    end

    it "shows published modules to students" do
      expect(@course.modules_visible_to(@student).pluck(:name)).to contain_exactly("published 1", "published 2")
    end

    it "shows all modules to teachers" do
      expect(@course.modules_visible_to(@teacher).pluck(:name)).to contain_exactly("published 1", "published 2", "unpublished")
    end

    it "shows all modules to teachers even when course is concluded" do
      @course.complete!
      expect(@course.grants_right?(@teacher, :manage_content)).to be(false)
      expect(@course.modules_visible_to(@teacher).pluck(:name)).to contain_exactly("published 1", "published 2", "unpublished")
    end

    context "when the differentiated_modules flag is enabled" do
      before :once do
        Account.site_admin.enable_feature! :differentiated_modules
        @m2.assignment_overrides.create!
      end

      it "shows only modules that don't have overrides to student" do
        expect(@course.modules_visible_to(@student).pluck(:name)).to contain_exactly("published 1")
      end

      it "shows published modules with overrides as long as student has an override" do
        @m2.assignment_overrides.create!(set: @course.default_section)
        @m3.assignment_overrides.create!(set: @course.default_section)
        expect(@course.modules_visible_to(@student).pluck(:name)).to contain_exactly("published 1", "published 2")
      end

      it "shows all modules to teachers regardless of visibility status" do
        expect(@course.modules_visible_to(@teacher).pluck(:name)).to contain_exactly("published 1", "published 2", "unpublished")
      end
    end
  end

  describe "#module_items_visible_to" do
    before :once do
      course_with_teacher active_all: true
      student_in_course active_enrollment: true
      @module = @course.context_modules.create!
      @module.add_item(type: "sub_header", title: "published").publish!
      @module.add_item(type: "sub_header", title: "unpublished")
    end

    it "shows published items to students" do
      expect(@course.module_items_visible_to(@student).map(&:title)).to match_array %w[published]
    end

    it "shows all items to teachers" do
      expect(@course.module_items_visible_to(@teacher).map(&:title)).to match_array %w[published unpublished]
    end

    it "shows all items to teachers even when course is concluded" do
      @course.complete!
      expect(@course.module_items_visible_to(@teacher).map(&:title)).to match_array %w[published unpublished]
    end

    context "with section specific discussions" do
      before :once do
        @other_section = @course.course_sections.create!
        @other_section_student = user_factory(active_all: true)
        @course.enroll_user(@other_section_student, "StudentEnrollment", section: @other_section, enrollment_state: "active")
        @topic = @course.discussion_topics.create!(course_sections: [@other_section], is_section_specific: true)
        @topic_tag = @module.add_item(type: "discussion_topic", id: @topic.id)
      end

      it "shows to student in section" do
        expect(@course.module_items_visible_to(@other_section_student)).to include(@topic_tag)
      end

      it "does not show to student not in section" do
        expect(@course.module_items_visible_to(@student)).to_not include(@topic_tag)
      end

      it "does not show to student if visibiilty is deleted" do
        @topic.discussion_topic_section_visibilities.destroy_all
        expect(@course.module_items_visible_to(@other_section_student)).to_not include(@topic_tag)
      end

      it "shows to teacher" do
        expect(@course.module_items_visible_to(@teacher)).to include(@topic_tag)
      end
    end

    context "sharding" do
      specs_require_sharding

      it "does not kersplud on a different shard" do
        @shard1.activate do
          expect(@course.module_items_visible_to(@student).first.title).to eq "published"
        end
      end
    end
  end

  describe "#update_enrolled_users" do
    it "updates user associations when deleted" do
      course_with_student(active_all: true)
      expect(@user.associated_accounts).to be_present
      @course.destroy
      @user.reload
      expect(@user.associated_accounts).to be_blank
    end
  end

  describe "#apply_nickname_for!" do
    before(:once) do
      @course = Course.create! name: "some terrible name"
      @user = User.create!
      @user.set_preference(:course_nicknames, @course.id, "nickname")
    end

    it "sets name to user's nickname (non-persistently)" do
      @course.apply_nickname_for!(@user)
      expect(@course.name).to eq "nickname"
      @course.save!
      expect(Course.find(@course.id).name).to eq "some terrible name"
    end

    it "undoes the change with nil user" do
      @course.apply_nickname_for!(@user)
      @course.apply_nickname_for!(nil)
      expect(@course.name).to eq "some terrible name"
    end

    it "prefers the subject name if present and k5 is enabled" do
      @course.friendly_name = "drama"
      @course.save!

      @course.apply_nickname_for!(@user)
      expect(@course.name).to eq "nickname"

      @course.account.enable_as_k5_account!

      @course.apply_nickname_for!(@user)
      expect(@course.name).to eq "drama"

      @course.apply_nickname_for!(nil)
      expect(@course.name).to eq "some terrible name"
    end
  end

  describe "#image" do
    before(:once) do
      course_with_teacher(active_all: true)
      attachment_with_context(@course)
    end

    it "returns the image_url when image_url is set" do
      url = "http://example.com"
      @course.image_url = url
      @course.banner_image_url = url
      @course.save!
      expect(@course.image).to eq url
      expect(@course.banner_image).to eq url
    end

    it "returns the download_url for a course file if image_id is set" do
      @course.image_id = @attachment.id
      @course.banner_image_id = @attachment.id
      @course.save!
      expect(@course.image).to eq @attachment.public_download_url
      expect(@course.banner_image).to eq @attachment.public_download_url
    end

    it "returns nil if image_id and image_url are not set" do
      expect(@course.image).to be_nil
      expect(@course.banner_image).to be_nil
    end

    it "throws an error if both image_id and image_url are set" do
      url = "http://example.com"
      @course.image_id = @attachment.id
      @course.image_url = url
      @course.banner_image_id = @attachment.id
      @course.banner_image_url = url
      @course.validate
      expect(@course.errors[:image]).to include "image_url and image_id cannot both be set."
      expect(@course.errors[:banner_image]).to include "banner_image_url and banner_image_id cannot both be set."
    end
  end

  describe "#filter_users_by_permission" do
    it "filters out course users that don't have a permission based on their enrollment roles" do
      permission = :moderate_forum # happens to be true for ta's, but available to students
      super_student_role = custom_student_role("superstudent", account: Account.default)
      Account.default.role_overrides.create!(role: super_student_role, permission:, enabled: true)
      unsuper_ta_role = custom_ta_role("unsuperta", account: Account.default)
      Account.default.role_overrides.create!(role: unsuper_ta_role, permission:, enabled: false)

      course_factory(active_all: true)
      reg_student = student_in_course(course: @course).user
      super_student = student_in_course(course: @course, role: super_student_role).user
      reg_ta = ta_in_course(course: @course).user
      unsuper_ta = ta_in_course(course: @course, role: unsuper_ta_role).user

      users = [reg_student, super_student, reg_ta, unsuper_ta]
      expect(@course.filter_users_by_permission(users, :read_forum)).to eq users # should be on by default for all
      expect(@course.filter_users_by_permission(users, :moderate_forum)).to eq [super_student, reg_ta]

      @course.complete!

      expect(@course.filter_users_by_permission(users, :read_forum)).to eq users # should still work since it is a retroactive permission
      expect(@course.filter_users_by_permission(users, :moderate_forum)).to be_empty # unlike this one
    end
  end

  describe "#any_assignment_in_closed_grading_period?" do
    it "delegates to EffectiveDueDates#any_in_closed_grading_period?" do
      test_course = Course.create!
      edd = EffectiveDueDates.for_course(test_course)
      expect(EffectiveDueDates).to receive(:for_course).with(test_course).and_return(edd)
      expect(edd).to receive(:any_in_closed_grading_period?).and_return(true)
      expect(test_course.any_assignment_in_closed_grading_period?).to be(true)
    end
  end

  describe "#default_home_page" do
    let(:course) { Course.create! }

    it "defaults to 'modules'" do
      expect(course.default_home_page).to eq "modules"
    end

    it "is set assigned to 'default_view' on creation'" do
      expect(course.default_view).to eq "modules"
    end
  end

  describe "#show_total_grade_as_points?" do
    before(:once) do
      @course = Course.create!
    end

    it "returns true if the course settings include show_total_grade_as_points: true" do
      @course.update!(show_total_grade_as_points: true)
      expect(@course).to be_show_total_grade_as_points
    end

    it "returns false if the course settings include show_total_grade_as_points: false" do
      @course.update!(show_total_grade_as_points: false)
      expect(@course).not_to be_show_total_grade_as_points
    end

    it "returns false if the course settings do not include show_total_grade_as_points" do
      expect(@course).not_to be_show_total_grade_as_points
    end

    context "course settings include show_total_grade_as_points: true" do
      before(:once) do
        @course.update!(show_total_grade_as_points: true)
      end

      it "returns true if assignment groups are not weighted" do
        @course.group_weighting_scheme = "equal"
        expect(@course).to be_show_total_grade_as_points
      end

      it "returns false if assignment groups are weighted" do
        @course.group_weighting_scheme = "percent"
        expect(@course).not_to be_show_total_grade_as_points
      end

      context "assignment groups are not weighted" do
        before(:once) do
          @course.update!(group_weighting_scheme: "equal")
        end

        it "returns true if the associated grading period group is not weighted" do
          group = @course.account.grading_period_groups.create!
          group.enrollment_terms << @course.enrollment_term
          expect(@course).to be_show_total_grade_as_points
        end

        it "returns false if the associated grading period group is weighted" do
          group = @course.account.grading_period_groups.create!(weighted: true)
          group.enrollment_terms << @course.enrollment_term
          expect(@course).not_to be_show_total_grade_as_points
        end
      end
    end

    describe "#gradebook_backwards_incompatible_features_enabled?" do
      let(:course) { Course.create! }

      it "returns false if there are no policies nor is final_grade_override enabled" do
        expect(course).not_to be_gradebook_backwards_incompatible_features_enabled
      end

      it "returns true if a late policy is enabled" do
        course.late_policy = LatePolicy.new(late_submission_deduction_enabled: true)

        expect(course.gradebook_backwards_incompatible_features_enabled?).to be true
      end

      it "returns true if a missing policy is enabled" do
        course.late_policy = LatePolicy.new(missing_submission_deduction_enabled: true)

        expect(course.gradebook_backwards_incompatible_features_enabled?).to be true
      end

      it "is backward incompatible if final_grades_override is enabled" do
        course.enable_feature!(:final_grades_override)
        expect(course).to be_gradebook_backwards_incompatible_features_enabled
      end

      it "returns true if both a late and missing policy are enabled" do
        course.late_policy =
          LatePolicy.new(late_submission_deduction_enabled: true, missing_submission_deduction_enabled: true)

        expect(course.gradebook_backwards_incompatible_features_enabled?).to be true
      end

      it "returns false if both policies are disabled" do
        course.late_policy =
          LatePolicy.new(late_submission_deduction_enabled: false, missing_submission_deduction_enabled: false)

        expect(course.gradebook_backwards_incompatible_features_enabled?).to be false
      end

      context "With submissions" do
        let(:student) { student_in_course(course:).user }
        let!(:assignment) { course.assignments.create!(title: "assignment", points_possible: 10) }
        let(:submission) { assignment.submissions.find_by(user: student) }

        it "returns true if they are any submissions with a late_policy_status of none" do
          submission.late_policy_status = "none"
          submission.save!

          expect(course.gradebook_backwards_incompatible_features_enabled?).to be true
        end

        it "returns true if they are any submissions with a late_policy_status of missing" do
          submission.late_policy_status = "missing"
          submission.save!

          expect(course.gradebook_backwards_incompatible_features_enabled?).to be true
        end

        it "returns true if they are any submissions with a late_policy_status of late" do
          submission.late_policy_status = "late"
          submission.save!

          expect(course.gradebook_backwards_incompatible_features_enabled?).to be true
        end

        it "returns false if there are no policies and no submissions with late_policy_status" do
          expect(course.gradebook_backwards_incompatible_features_enabled?).to be false
        end
      end
    end

    context "cached_account_users_for" do
      specs_require_cache(:redis_cache_store)

      before :once do
        @course = Course.create!
        @user = User.create!
      end

      def cached_account_users
        Course.find(@course.id).cached_account_users_for(@user)
      end

      it "caches" do
        expect_any_instantiation_of(@course).to receive(:account_users_for).once.and_return([])
        2.times { cached_account_users }
      end

      it "clears if an account user is added to the user" do
        cached_account_users
        au = AccountUser.create!(account: Account.default, user: @user)
        expect(cached_account_users).to eq [au]
      end

      it "clears if the course is moved to another account" do
        sub_account = Account.default.sub_accounts.create!
        au = AccountUser.create!(account: sub_account, user: @user)
        expect(cached_account_users).to eq []
        @course.update_attribute(:account, sub_account)
        expect(cached_account_users).to eq [au]
      end

      it "clears if the sub_account is moved" do
        sub_account1 = Account.default.sub_accounts.create!
        au = AccountUser.create!(account: sub_account1, user: @user)

        sub_account2 = Account.default.sub_accounts.create!
        @course.update_attribute(:account, sub_account2)
        expect(cached_account_users).to eq []

        sub_account2.update_attribute(:parent_account, sub_account1)
        expect(cached_account_users).to eq [au]
      end
    end

    describe "#can_become_template?" do
      it "is true for an empty course" do
        course = Course.create!
        expect(course.can_become_template?).to be true
        course.template = true
        expect(course).to be_valid
      end

      it "is false once there's an enrollment" do
        course_with_teacher
        expect(@course.can_become_template?).to be false
        @course.template = true
        expect(@course).not_to be_valid
      end
    end

    describe "#can_stop_being_template?" do
      it "is false for unattached courses" do
        course = Course.create!(template: true)
        expect(course.can_stop_being_template?).to be true
        course.template = false
        expect(course).to be_valid
      end

      it "is true for courses attached to accounts" do
        course = Course.create!(template: true)
        course.account.update!(course_template: course)
        expect(course.can_stop_being_template?).to be false
        course.template = false
        expect(course).not_to be_valid
      end
    end

    describe "#copy_from_course_template" do
      it "copies unpublished content" do
        course = Course.create!(template: true)
        course.root_account.enable_feature!(:course_templates)
        course.account.update!(course_template: course)
        a = course.assignments.create!(title: "bob", workflow_state: "unpublished")
        expect(a).to be_unpublished
        q = course.quizzes.create!(title: "joe", workflow_state: "unpublished")
        expect(q).to be_unpublished
        wp = course.wiki_pages.create!(title: "george", workflow_state: "unpublished")
        expect(wp).to be_unpublished
        dt = course.discussion_topics.create!(title: "phil", workflow_state: "unpublished")
        expect(dt).to be_unpublished

        course2 = Course.create!
        run_jobs

        expect(course2.assignments.pluck(:title)).to eq ["bob"]
        expect(course2.quizzes.pluck(:title)).to eq ["joe"]
        expect(course2.wiki_pages.pluck(:title)).to eq ["george"]
        expect(course2.discussion_topics.pluck(:title)).to eq ["phil"]
      end
    end
  end

  describe "#has_modules?" do
    before(:once) do
      @course = Course.create!
    end

    it "returns false when the course has no modules" do
      expect(@course).not_to be_has_modules
    end

    it "returns false when all modules are soft-deleted" do
      @course.context_modules.create!(workflow_state: "deleted")
      expect(@course).not_to be_has_modules
    end

    it "returns true when at least one not-deleted module exists" do
      @course.context_modules.create!
      expect(@course).to be_has_modules
    end
  end

  describe "#create_or_update_quiz_migration_alert" do
    before do
      @course = Course.create!
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @content_migration = ContentMigration.create(context: @course)
      @content_migration2 = ContentMigration.create(context: @course)
    end

    context "when there are not quiz migration alerts that belong to the provided user" do
      it "creates a quiz migration alert" do
        expect do
          @course.create_or_update_quiz_migration_alert(@teacher.id, @content_migration)
        end.to change { QuizMigrationAlert.count }.from(0).to(1)
      end
    end

    context "when there are quiz migration alerts that belong to the provided user with a different migration_id" do
      before do
        @quiz_migration_alert =
          QuizMigrationAlert.create(user_id: @teacher.id, course_id: @course.id, migration: @content_migration)
      end

      it "updates the migration_id on the quiz migration alert" do
        expect do
          @course.create_or_update_quiz_migration_alert(@teacher.id, @content_migration2)
          @quiz_migration_alert.reload
        end.to change { @quiz_migration_alert.migration }.from(@content_migration).to(@content_migration2)
      end
    end
  end

  describe "#instructors_in_charge_of" do
    it "excludes section-limited instructors from Section A when the student is concluded in Section B" do
      course = Course.create!
      section1 = course.course_sections.create!(name: "Section 1")
      section2 = course.course_sections.create!(name: "Section 2")
      student = User.create!
      student_enrollment = course.enroll_student(
        student,
        section: section1,
        enrollment_state: "active"
      )
      limited_teacher = User.create!
      course.enroll_teacher(
        limited_teacher,
        limit_privileges_to_course_section: true,
        section: section2,
        enrollment_state: "active"
      )
      student_enrollment.conclude
      expect(course.instructors_in_charge_of(student.id)).not_to include limited_teacher
    end
  end

  describe "statsd logging for course actions" do
    context "timing when course is published" do
      let(:publish_time) { 300_000 }

      before :once do
        Account.default.enable_feature!(:course_paces)
      end

      it "logs the timing of a course to statsd with course pacing enabled" do
        allow(InstStatsd::Statsd).to receive(:timing)

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 0)) do
          a_course = Course.create!
          a_course.enable_course_paces = true
          a_course.save!
        end

        new_course = Course.last

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 5)) do
          new_course.offer!
        end

        expect(InstStatsd::Statsd).to have_received(:timing).with("course.paced.create_to_publish_time", publish_time).once
      end

      it "doesn't log timing if moving from concluded back to available in paced course" do
        allow(InstStatsd::Statsd).to receive(:timing)

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 0)) do
          a_course = Course.create!
          a_course.update!(enable_course_paces: true, workflow_state: "completed")
        end

        new_course = Course.last

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 5)) do
          new_course.offer!
        end

        expect(InstStatsd::Statsd).not_to have_received(:timing).with("course.paced.create_to_publish_time", publish_time)
      end

      it "log timing if moving publishing from claimed in paced course" do
        allow(InstStatsd::Statsd).to receive(:timing)

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 0)) do
          a_course = Course.create!
          a_course.update!(enable_course_paces: true, workflow_state: "claimed")
        end

        new_course = Course.last

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 5)) do
          new_course.offer!
        end

        expect(InstStatsd::Statsd).to have_received(:timing).with("course.paced.create_to_publish_time", publish_time).once
      end

      it "logs the timing of a course to statsd with course pacing not enabled" do
        allow(InstStatsd::Statsd).to receive(:timing)

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 0)) do
          Course.create!
        end

        new_course = Course.last

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 5)) do
          new_course.offer!
        end

        expect(InstStatsd::Statsd).to have_received(:timing).with("course.unpaced.create_to_publish_time", publish_time).once
      end

      it "doesn't log timing if moving from concluded back to available in unpaced course" do
        allow(InstStatsd::Statsd).to receive(:timing)

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 0)) do
          a_course = Course.create!
          a_course.update!(workflow_state: "completed")
        end

        new_course = Course.last

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 5)) do
          new_course.offer!
        end

        expect(InstStatsd::Statsd).not_to have_received(:timing).with("course.unpaced.create_to_publish_time", publish_time)
      end

      it "log timing if moving publishing from claimed in unpaced course" do
        allow(InstStatsd::Statsd).to receive(:timing)

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 0)) do
          a_course = Course.create!
          a_course.update!(workflow_state: "claimed")
        end

        new_course = Course.last

        Timecop.freeze(Time.utc(2022, 3, 1, 12, 5)) do
          new_course.offer!
        end

        expect(InstStatsd::Statsd).to have_received(:timing).with("course.unpaced.create_to_publish_time", publish_time).once
      end
    end

    context "assignment count when course is published" do
      before do
        Account.default.enable_feature!(:course_paces)
        allow(InstStatsd::Statsd).to receive(:count)
        @course = Course.create!
        create_assignments([@course.id], 2)
      end

      it "logs assignment count in the paced bucket if course pacing is enabled" do
        @course.offer!
        expect(InstStatsd::Statsd).to have_received(:count).with("course.unpaced.assignment_count", 2).once
      end

      it "only logs published assignments" do
        @course.assignments.last.unpublish
        @course.offer!
        expect(InstStatsd::Statsd).to have_received(:count).with("course.unpaced.assignment_count", 1).once
      end

      it "logs assignment count in the unpaced bucket if course pacing is enabled" do
        @course.enable_course_paces = true
        @course.save!
        @course.offer!
        expect(InstStatsd::Statsd).to have_received(:count).with("course.paced.assignment_count", 2).once
      end
    end

    context "end date stats on date change or publishing" do
      it "increments and decrements on end date existence change" do
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:decrement)

        Course.create!(restrict_enrollments_to_course_dates: true, conclude_at: Time.now, settings: { enable_course_paces: true }).offer!
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.has_end_date").once

        Course.last.update! restrict_enrollments_to_course_dates: false
        expect(InstStatsd::Statsd).to have_received(:decrement).with("course.paced.has_end_date").once
      end

      it "increments and decrements on pace status change" do
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:decrement)

        Course.create!(restrict_enrollments_to_course_dates: true, conclude_at: Time.now).offer!
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.has_end_date").once

        Course.last.update! settings: { enable_course_paces: true }
        expect(InstStatsd::Statsd).to have_received(:decrement).with("course.unpaced.has_end_date").once
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.has_end_date").once
      end

      it "increments and decrements on pace status and end date existence concurrently" do
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:decrement)
        Course.create!(restrict_enrollments_to_course_dates: true, conclude_at: Time.now).offer!
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.has_end_date").once

        Course.last.update! restrict_enrollments_to_course_dates: false, settings: { enable_course_paces: true }
        expect(InstStatsd::Statsd).to have_received(:decrement).with("course.unpaced.has_end_date").once
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.paced.has_end_date")

        Course.last.update! restrict_enrollments_to_course_dates: true, settings: { enable_course_paces: false }
        expect(InstStatsd::Statsd).not_to have_received(:decrement).with("course.paced.has_end_date")
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.has_end_date").twice
      end

      it "ignores unpublished date having changes" do
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:decrement)
        Course.create!(restrict_enrollments_to_course_dates: true, conclude_at: Time.now)
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.unpaced.has_end_date")
        Course.last.update! settings: { enable_course_paces: true }
        expect(InstStatsd::Statsd).not_to have_received(:decrement).with("course.unpaced.has_end_date")
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.paced.has_end_date")
      end
    end

    context "course with course pacing on or off" do
      before do
        Account.default.enable_feature!(:course_paces)
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:decrement)
        @course = Course.create!
      end

      it "increments count for a course paced course when initially published" do
        @course.enable_course_paces = true
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.paced_courses").once
      end

      it "does not increment when only option is updated" do
        @course.enable_course_paces = true
        @course.save!

        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.paced.paced_courses")
      end

      it "increments count for non-paced course when initially published" do
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.paced_courses").once
      end

      it "increments paced count on already published course from when going from unpaced to paced" do
        @course.offer!
        @course.enable_course_paces = true
        @course.save!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.paced_courses").once
      end

      it "increments paced count on already published course from when going from paced to unpaced" do
        @course.enable_course_paces = true
        @course.save!
        @course.offer!
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.paced_courses").once

        @course.enable_course_paces = false
        @course.save!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.paced_courses").once
      end

      it "increments the appropriate bucket when republishing" do
        @course.enable_course_paces = true
        @course.save!
        @course.offer!
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.paced_courses").once
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.unpaced.paced_courses")

        @course.claim!

        @course.enable_course_paces = false
        @course.save!
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.unpaced.paced_courses")

        @course.offer!
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.paced_courses").once
      end
    end

    context "course format logging" do
      before do
        Account.default.enable_feature!(:course_paces)
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:decrement)
        @course = Course.create!
      end

      it "increments the course format count for unset when unpaced course published for the first time" do
        @course.course_format = nil
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.unset").once
      end

      it "increments the course format count for unset when paced course published for the first time" do
        @course.course_format = nil
        @course.enable_course_paces = true
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.unset").once
      end

      it "increments the course format count for blended when unpaced course published for the first time" do
        @course.course_format = "blended"
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.blended").once
        expect(InstStatsd::Statsd).not_to have_received(:decrement).with("course.unpaced.blended")
      end

      it "increments the course format count for blended when paced course published for the first time" do
        @course.course_format = "blended"
        @course.enable_course_paces = true
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.blended").once
      end

      it "increments the course format count for on_campus when unpaced course published for the first time" do
        @course.course_format = "on_campus"
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.on_campus").once
      end

      it "increments the course format count for on_campus when paced course published for the first time" do
        @course.course_format = "on_campus"
        @course.enable_course_paces = true
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.on_campus").once
      end

      it "increments the course format count for online when unpaced course published for the first time" do
        @course.course_format = "online"
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.online").once
      end

      it "increments the course format count for online when paced course published for the first time" do
        @course.course_format = "online"
        @course.enable_course_paces = true
        @course.save!
        @course.offer!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.online").once
      end

      it "does not increment unpaced stat when only option is updated and not published" do
        @course.course_format = nil
        @course.save!

        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.unpaced.unset")
      end

      it "does not increment paced stat when only option is updated and not published" do
        @course.course_format = nil
        @course.enable_course_paces = true
        @course.save!

        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.paced.unset")
      end

      it "increments unset count on already published unpaced course" do
        @course.offer!
        @course.enable_course_paces = true
        @course.save!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.unset").once
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.unset").once
      end

      it "increments change to online on unpaced course" do
        @course.offer!
        @course.course_format = "online"
        @course.save!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.unset").once
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.online").once
      end

      it "increments blended count on already published paced course" do
        @course.enable_course_paces = true
        @course.save!
        @course.offer!
        @course.course_format = "blended"
        @course.save!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.unset").once
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.blended").once
      end

      it "paced course starts blended goes to unpaced and format unset" do
        @course.enable_course_paces = true
        @course.course_format = "blended"
        @course.save!
        expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.paced.blended")

        @course.offer!
        expect(InstStatsd::Statsd).to have_received(:increment).with("course.paced.blended").once

        @course.course_format = nil
        @course.enable_course_paces = false
        @course.save!

        expect(InstStatsd::Statsd).to have_received(:increment).with("course.unpaced.unset").once
      end
    end
  end

  describe "#batch_update_context_modules" do
    before do
      @course = course_model
      @test_modules = (1..4).map { |x| @course.context_modules.create! name: "test module #{x}" }
      @test_modules[2..3].each { |m| m.update_attribute(:workflow_state, "unpublished") }
      @modules_to_update = [@test_modules[1], @test_modules[3]]

      @wiki_page = @course.wiki_pages.create(title: "Wiki Page Title")
      @wiki_page.unpublish!
      @wiki_page_tag = @test_modules[3].add_item(id: @wiki_page.id, type: "wiki_page")
      @wiki_page_tag.trigger_unpublish!

      @ids_to_update = @modules_to_update.map(&:id)
    end

    context "with publish event" do
      it "publishes the modules" do
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :publish)
        @modules_to_update.each do |m|
          expect(m.reload).to be_published
        end
      end

      it "publishes the items" do
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :publish)
        @modules_to_update.each do |m|
          expect(m.reload).to be_published
          m.content_tags.each do |tag|
            expect(tag.reload).to be_published
          end
        end
      end

      it "does not publish the items when skip_content_tags is true" do
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :publish, skip_content_tags: true)
        @modules_to_update.each do |m|
          expect(m.reload).to be_published
          m.content_tags.each do |tag|
            expect(tag.reload).not_to be_published
          end
        end
      end
    end

    context "with unpublish event" do
      it "unpublishes the modules" do
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :unpublish)
        @modules_to_update.each do |m|
          expect(m.reload).to be_unpublished
        end
      end

      it "unpublishes the items" do
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :unpublish)
        @modules_to_update.each do |m|
          expect(m.reload).to be_unpublished
          m.content_tags.each do |tag|
            expect(tag.reload).to be_unpublished
          end
        end
      end

      it "does not unpublish the items when skip_content_tags is true" do
        @wiki_page_tag.trigger_publish!
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :unpublish, skip_content_tags: true)
        @modules_to_update.each do |m|
          expect(m.reload).to be_unpublished
          m.content_tags.each do |tag|
            expect(tag.reload).not_to be_unpublished
          end
        end
      end
    end

    context "with delete event" do
      it "deletes the modules" do
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :delete)
        @modules_to_update.each do |m|
          expect(m.reload).to be_deleted
        end
      end

      it "deletes the items" do
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :delete)
        @modules_to_update.each do |m|
          expect(m.reload).to be_deleted
          m.content_tags.each do |tag|
            expect(tag.reload).to be_deleted
          end
        end
      end

      it "deletes the content tags even if skip_content_tags is true" do
        @wiki_page_tag.trigger_publish!
        @course.batch_update_context_modules(module_ids: @ids_to_update, event: :delete, skip_content_tags: true)
        @modules_to_update.each do |m|
          expect(m.reload).to be_deleted
          m.content_tags.each do |tag|
            expect(tag.reload).to be_deleted
          end
        end
      end
    end

    it "increments the progress" do
      progress = Progress.create!(context: @course, tag: "context_module_batch_update", user: @teacher)
      expect(progress).to receive(:increment_completion!).twice
      @course.batch_update_context_modules(progress, module_ids: @ids_to_update, event: :publish)
    end

    it "returns the completed_ids" do
      completed_ids = @course.batch_update_context_modules(module_ids: @ids_to_update, event: :publish)
      expect(completed_ids).to eq @ids_to_update
    end
  end

  describe "restrict quantitative data" do
    before do
      @root = Account.default
      @course = Account.default.courses.build
      @course.update(root_account_id: @root.id)
      @admin = account_admin_user
      @teacher = user_model
      @course.enroll_teacher(@teacher, enrollment_state: "active")
      @student = user_model
      @course.enroll_student(@student, enrollment_state: "active")
      @observer = user_model
      @course.enroll_user(@observer, "ObserverEnrollment").update_attribute(:associated_user_id, @student.id)
      @ta = user_model
      @course.enroll_ta(@ta, enrollment_state: "active")
      @designer = user_model
      @course.enroll_designer(@designer, enrollment_state: "active")
    end

    describe "with no user" do
      it "calls restrict_quantitative_data with no user" do
        expect(@course.restrict_quantitative_data?).to be false
      end
    end

    describe "with feature flag on" do
      before do
        @root.enable_feature!(:restrict_quantitative_data)
      end

      describe "restrict_quantitative_data_setting_changeable?" do
        it "returns false if the feature flag is off" do
          @root.disable_feature!(:restrict_quantitative_data)
          expect(@course.restrict_quantitative_data_setting_changeable?).to be_falsey
        end

        it "returns false if the account setting is on and locked and the course setting is on" do
          @course.settings = @course.settings.merge(restrict_quantitative_data: true)
          @root.settings[:restrict_quantitative_data] = { locked: true, value: true }
          expect(@course.restrict_quantitative_data_setting_changeable?).to be_falsey
        end

        it "returns false if the account setting is off and the course setting is false" do
          @course.settings = @course.settings.merge(restrict_quantitative_data: false)
          @root.settings[:restrict_quantitative_data] = { locked: false, value: false }
          expect(@course.restrict_quantitative_data_setting_changeable?).to be_falsey
        end

        it "returns true if the account setting is on and unlocked" do
          @root.settings[:restrict_quantitative_data] = { locked: false, value: true }
          expect(@course.restrict_quantitative_data_setting_changeable?).to be_truthy
        end

        it "returns true if the account setting is on and locked and the course setting is false" do
          @course.settings = @course.settings.merge(restrict_quantitative_data: false)
          @root.settings[:restrict_quantitative_data] = { locked: true, value: true }
          expect(@course.restrict_quantitative_data_setting_changeable?).to be_truthy
        end

        it "returns true if the account setting is off and the course setting is true" do
          @course.settings = @course.settings.merge(restrict_quantitative_data: true)
          @root.settings[:restrict_quantitative_data] = { locked: false, value: false }
          expect(@course.restrict_quantitative_data_setting_changeable?).to be_truthy
        end
      end

      context "relation to account restrict_quantitative_data setting" do
        it "is unaffected by account setting for existing courses" do
          expect(@course.restrict_quantitative_data).to be false
          @course.account.settings[:restrict_quantitative_data] = { locked: true, value: true }
          @course.account.save!
          @course.reload
          expect(@course.restrict_quantitative_data).to be false
        end

        it "sets restrict_quantitative_data to true for newly created courses when account setting is true and locked" do
          Account.default.settings[:restrict_quantitative_data] = { locked: true, value: true }
          Account.default.save!
          crs = Course.create!(account: Account.default)
          expect(crs.restrict_quantitative_data).to be true
        end

        it "does not set restrict_quantitative_data for newly created courses when account setting is true and not locked" do
          Account.default.settings[:restrict_quantitative_data] = { locked: false, value: true }
          Account.default.save!
          crs = Course.create!(account: Account.default)
          expect(crs.restrict_quantitative_data).to be false
        end

        it "sets restrict_quantitative_data for newly created courses in sub accounts when account setting is true and locked" do
          @sub_account = Account.create(parent_account: @root, name: "English")
          @root.settings[:restrict_quantitative_data] = { locked: true, value: true }
          @root.save!
          crs = Course.create!(account: @sub_account)
          expect(crs.restrict_quantitative_data).to be true
        end
      end

      describe "updates metric if setting is enabled/disabled" do
        before do
          allow(InstStatsd::Statsd).to receive(:increment)
        end

        it "increments enabled log when setting is turned on" do
          expect(@course.restrict_quantitative_data).to be false
          @course.settings = @course.settings.merge(restrict_quantitative_data: true)
          @course.save!
          expect(@course.restrict_quantitative_data).to be true

          expect(InstStatsd::Statsd).to have_received(:increment).with("course.settings.restrict_quantitative_data.enabled").once
        end

        it "increments disabled log when setting is turned off" do
          expect(@course.restrict_quantitative_data).to be false
          @course.settings = @course.settings.merge(restrict_quantitative_data: true)
          @course.save!
          expect(@course.restrict_quantitative_data).to be true
          @course.settings = @course.settings.merge(restrict_quantitative_data: false)
          @course.save!
          expect(@course.restrict_quantitative_data).to be false

          expect(InstStatsd::Statsd).to have_received(:increment).with("course.settings.restrict_quantitative_data.enabled").once.ordered
          expect(InstStatsd::Statsd).to have_received(:increment).with("course.settings.restrict_quantitative_data.disabled").once.ordered
        end

        it "doesn't increment either log when settings update but RQD setting is unchanged" do
          expect(@course.hide_final_grade).to be false
          @course.settings = @course.settings.merge(hide_final_grade: true)
          @course.save!
          expect(@course.hide_final_grade).to be true

          expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.settings.restrict_quantitative_data.enabled")
          expect(InstStatsd::Statsd).not_to have_received(:increment).with("course.settings.restrict_quantitative_data.disabled")
        end
      end

      describe "with setting turned on" do
        before do
          @course.restrict_quantitative_data = true
          @course.save!
        end

        # Admins are the only role to return false when the setting is on
        it "does not restrict quantitative data for admin" do
          expect(@course.restrict_quantitative_data?(@admin)).to be false
        end

        it "restricts quantitative data for students" do
          expect(@course.restrict_quantitative_data?(@student)).to be true
        end

        it "restricts quantitative data for teacher" do
          expect(@course.restrict_quantitative_data?(@teacher)).to be true
        end

        it "restricts quantitative data for observers" do
          expect(@course.restrict_quantitative_data?(@observer)).to be true
        end

        it "restricts quantitative data for designer" do
          expect(@course.restrict_quantitative_data?(@designer)).to be true
        end

        it "restricts quantitative data for ta" do
          expect(@course.restrict_quantitative_data?(@ta)).to be true
        end

        # By default, only students and observers should be restricted when extra permissions are checked
        context "with check_extra_permissions" do
          it "restricts quantitative data for students" do
            expect(@course.restrict_quantitative_data?(@student, check_extra_permissions: true)).to be true
          end

          it "restricts quantitative data for observers" do
            expect(@course.restrict_quantitative_data?(@observer, check_extra_permissions: true)).to be true
          end

          it "does not restrict quantitative data for admin" do
            expect(@course.restrict_quantitative_data?(@admin, check_extra_permissions: true)).to be false
          end

          it "does not restrict quantitative data for teacher" do
            expect(@course.restrict_quantitative_data?(@teacher, check_extra_permissions: true)).to be false
          end

          it "does not restrict quantitative data for ta" do
            expect(@course.restrict_quantitative_data?(@ta, check_extra_permissions: true)).to be false
          end

          it "does not restrict quantitative data for designer" do
            expect(@course.restrict_quantitative_data?(@designer, check_extra_permissions: true)).to be false
          end
        end
      end

      describe "with setting turned off" do
        it "restricts quantitative data for students" do
          expect(@course.restrict_quantitative_data?(@student)).to be false
        end

        it "restricts quantitative data for teacher" do
          expect(@course.restrict_quantitative_data?(@teacher)).to be false
        end

        it "restricts quantitative data for admin" do
          expect(@course.restrict_quantitative_data?(@admin)).to be false
        end
      end
    end

    describe "with feature flag off" do
      it "sets restrict_quantitative_data setting to false by default" do
        expect(@course.restrict_quantitative_data).to be false
      end

      describe "with setting turned on" do
        before do
          @course.settings = @course.settings.merge(restrict_quantitative_data: true)
          @course.save!
        end

        it "restricts quantitative data for students" do
          expect(@course.restrict_quantitative_data?(@student)).to be false
        end

        it "restricts quantitative data for teacher" do
          expect(@course.restrict_quantitative_data?(@teacher)).to be false
        end

        it "restricts quantitative data for admin" do
          expect(@course.restrict_quantitative_data?(@admin)).to be false
        end
      end

      describe "with setting turned off" do
        it "restricts quantitative data for students" do
          expect(@course.restrict_quantitative_data?(@student)).to be false
        end

        it "restricts quantitative data for teacher" do
          expect(@course.restrict_quantitative_data?(@teacher)).to be false
        end

        it "restricts quantitative data for admin" do
          expect(@course.restrict_quantitative_data?(@admin)).to be false
        end
      end
    end
  end

  describe "#default_grading_standard" do
    before do
      @root = Account.default
      @course = Account.default.courses.build
      @course.update(root_account_id: @root.id)
    end

    def default_scheme(context)
      gs = GradingStandard.new(context:, title: "My Grading Standard", data: { "A" => 0.94, "B" => 0, })
      gs.save!
      gs
    end

    it "returns nil if no grading standards exist" do
      expect(@course.default_grading_standard).to be_nil
    end

    it "returns the default grading standard if one exists" do
      grading_standard = default_scheme(@course)
      @course.grading_standard = grading_standard
      @course.save!
      expect(@course.default_grading_standard).to eq grading_standard
    end

    it "returns the account default grading standard if no course default exists" do
      grading_standard = default_scheme(@course.account)
      @course.account.grading_standard = grading_standard
      @course.account.save!
      expect(@course.default_grading_standard).to eq grading_standard
    end
  end

  describe "#grading_standard_enabled" do
    before do
      @root = Account.default
      @course = Account.default.courses.build
      @course.update(root_account_id: @root.id)
    end

    def default_scheme(context)
      gs = GradingStandard.new(context:, title: "My Grading Standard", data: { "A" => 0.94, "B" => 0, })
      gs.save!
      gs
    end

    it "returns false if no grading standards exist" do
      expect(@course.grading_standard_enabled).to be_falsey
    end

    it "returns true if a grading standard exists" do
      @course.grading_standard = default_scheme(@course)
      @course.save!
      expect(@course.grading_standard_enabled).to be_truthy
    end

    it "returns true if the account has a grading standard" do
      @course.account.grading_standard = default_scheme(@course.account)
      @course.account.save!
      expect(@course.grading_standard_enabled).to be_truthy
    end
  end

  describe "#course_grading_standard_enabled" do
    before do
      @root = Account.default
      @course = Account.default.courses.build
      @course.update(root_account_id: @root.id)
    end

    def default_scheme(context)
      gs = GradingStandard.new(context:, title: "My Grading Standard", data: { "A" => 0.94, "B" => 0, })
      gs.save!
      gs
    end

    it "returns false if no course grading standard" do
      expect(@course.course_grading_standard_enabled).to be_falsey
    end

    it "returns true if a course grading standard exists" do
      @course.grading_standard = default_scheme(@course)
      @course.save!

      expect(@course.course_grading_standard_enabled).to be_truthy
    end

    it "returns false even if the account has a grading standard" do
      @course.account.grading_standard = default_scheme(@course.account)
      @course.account.save!

      expect(@course.course_grading_standard_enabled).to be_falsey
    end
  end

  describe "#destroy" do
    it "records deleted_at" do
      course_model
      expect { @course.destroy }.to change { @course.reload.deleted_at }.from(nil).to be_truthy
    end
  end
end
