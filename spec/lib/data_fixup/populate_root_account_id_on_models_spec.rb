# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe DataFixup::PopulateRootAccountIdOnModels do
  before :once do
    course_model
    @cm = @course.context_modules.create!
    @cm.update_columns(root_account_id: nil)
    user_model
    Account.ensure_dummy_root_account
  end

  # add additional models here as they are calculated and added to migration_tables.
  context "models" do
    shared_examples_for "a datafixup that populates root_account_id" do
      let(:record) { raise "set in examples" }
      let(:reference_record) { raise "set in examples" }
      let(:sharded) { false }

      before { record.update_columns(root_account_id: nil) }

      it "populates the root_account_id" do
        expected_root_account_id =
          if reference_record.reload.is_a?(Account)
            reference_record.resolved_root_account_id
          else
            reference_record.root_account_id
          end

        expected_root_account_id = Account.find(expected_root_account_id).global_id if sharded

        expect do
          DataFixup::PopulateRootAccountIdOnModels.run
        end.to change { record.reload.root_account_id }.from(nil).to(expected_root_account_id)
        expect(expected_root_account_id).to be_present
      end
    end

    shared_examples_for "a datafixup that populates root_account_id to 0" do
      let(:record) { raise "set in examples" }
      before { record.update_columns(root_account_id: nil) }

      before do
        # Ensure dummy account exists (done in migration but may be undone by specs)
        Account.find_or_create_by!(id: 0)
               .update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
      end

      it "populates the root_account_id to 0" do
        expect do
          DataFixup::PopulateRootAccountIdOnModels.run
        end.to change { record.reload.root_account_id }.from(nil).to(0)
      end
    end

    shared_examples_for "a datafixup that does not populate root_account_id" do
      let(:record) { raise "set in examples" }
      before { record.update_columns(root_account_id: nil) }

      it "populates the root_account_id to 0" do
        expect(record.reload.root_account_id).to be_nil
        DataFixup::PopulateRootAccountIdOnModels.run
        expect(record.reload.root_account_id).to be_nil
      end
    end

    it "populates root_account_id on AssessmentQuestion" do
      aq = assessment_question_model(bank: AssessmentQuestionBank.create!(context: @course))
      aq.update_columns(root_account_id: nil)
      expect(aq.reload.root_account_id).to be_nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(aq.reload.root_account_id).to eq @course.root_account_id
    end

    it "populates root_account_id on AssessmentQuestionBank" do
      aqb = AssessmentQuestionBank.create!(context: @course)
      aqb.update_columns(root_account_id: nil)
      expect(aqb.reload.root_account_id).to be_nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(aqb.reload.root_account_id).to eq @course.root_account_id

      account = account_model(root_account: account_model)
      aqb = AssessmentQuestionBank.create!(context: account)
      aqb.update_columns(root_account_id: nil)
      expect(aqb.reload.root_account_id).to be_nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(aqb.reload.root_account_id).to eq account.root_account_id
    end

    it "populates the root_account_id on AssignmentGroup" do
      ag = @course.assignment_groups.create!(name: "AssignmentGroup!")
      ag.update_columns(root_account_id: nil)
      expect(ag.root_account_id).to be_nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(ag.reload.root_account_id).to eq @course.root_account_id
    end

    it "populates the root_account_id on AssignmentOverride" do
      assignment_model(course: @course)
      @course.enroll_student(@user)
      override1 = create_adhoc_override_for_assignment(@assignment, @user)
      override1.update_columns(root_account_id: nil)
      expect(override1.attributes["root_account_id"]).to be_nil

      quiz_model(course: @course)
      override2 = create_adhoc_override_for_assignment(@quiz, @user)
      override2.update_columns(root_account_id: nil)
      expect(override2.attributes["root_account_id"]).to be_nil

      DataFixup::PopulateRootAccountIdOnModels.run
      expect(override1.reload.attributes["root_account_id"]).to eq @course.root_account_id
      expect(override2.reload.attributes["root_account_id"]).to eq @course.root_account_id
    end

    it "populates the root_account_id on AssignmentOverrideStudent" do
      @course.enroll_student(@user)
      assignment_model(course: @course)
      create_adhoc_override_for_assignment(@assignment, @user)
      @override_student.update_columns(root_account_id: nil)
      os1 = @override_student
      expect(os1.root_account_id).to be_nil

      quiz_model(course: @course)
      create_adhoc_override_for_assignment(@quiz, @user)
      @override_student.update_columns(root_account_id: nil)
      os2 = @override_student
      expect(os2.root_account_id).to be_nil

      DataFixup::PopulateRootAccountIdOnModels.run
      expect(os1.reload.root_account_id).to eq @course.root_account_id
      expect(os2.reload.root_account_id).to eq @course.root_account_id
    end

    context "with AttachmentAssociation with a non-ConversationMessage context" do
      let(:other_root_account) { account_model(root_account_id: nil) }
      let(:attachment_association) do
        AttachmentAssociation.create!(
          attachment: attachment_model(context: other_root_account),
          context: reference_record
        )
      end

      context "with a Course context" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { attachment_association }
          let(:reference_record) { @course }
        end
      end

      context "with a Group context" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { attachment_association }
          let(:reference_record) { group_model }
        end
      end

      context "with a Submission context" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { attachment_association }
          let(:reference_record) { submission_model }
        end
      end
    end

    context "with AssignmentAssocation with a ConverationMessage context" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:attachment) { attachment_model(context: account_model(root_account_id: nil)) }
        let(:conversation_message) do
          conversation(@user).messages.first.tap do |msg|
            msg.update!(root_account_ids: [@course.root_account_id])
          end
        end
        let(:record) do
          AttachmentAssociation.create!(attachment:, context: conversation_message)
        end
        let(:reference_record) { attachment }
      end
    end

    context "with CalendarEvent" do
      context "when context is Course" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { CalendarEvent.create!(context: @course) }
          let(:reference_record) { @course }
        end
      end

      context "when context is Group" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { CalendarEvent.create!(context: group_model(context: @course)) }
          let(:reference_record) { @course }
        end
      end

      context "when context is CourseSection" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { CalendarEvent.create!(context: CourseSection.create!(course: @course)) }
          let(:reference_record) { @course }
        end
      end

      context "when context is User" do
        context "when effective_context_code is null" do
          it_behaves_like "a datafixup that populates root_account_id to 0" do
            let(:record) { CalendarEvent.create!(context: @user, effective_context_code: nil) }
          end
        end

        context "when effective_context_code is a something else" do
          it_behaves_like "a datafixup that does not populate root_account_id" do
            let(:record) { CalendarEvent.create!(context: @user, effective_context_code: "foobar_123") }
          end
        end

        context "when effective_context_code is null but root_account_id is already filled" do
          it "doesn't re-set the root_account_id to 0" do
            # Some CalendarEvent with nil root_account_id is needed to instigate the backfill
            other_ce = CalendarEvent.create!(context: @course)
            other_ce.update_columns(root_account_id: nil)

            # This is what we are testing:
            ce = CalendarEvent.create!(context: @user, effective_context_code: nil)
            ce.update_columns(root_account_id: @course.root_account_id)
            expect(ce.reload.root_account_id).to be > 0
            DataFixup::PopulateRootAccountIdOnModels.run
            expect(ce.reload.root_account_id).to eq(@course.root_account_id)
          end
        end
      end

      context "when context is a Course that does not exist" do
        it_behaves_like "a datafixup that populates root_account_id to 0" do
          let(:record) do
            CalendarEvent.create!(context: @course).tap do |ce|
              ce.update_columns(context_id: Course.last.id.to_i + 9999)
            end
          end
        end
      end

      context "when context is a Course that does not exist but it is already filled" do
        it "doesn't re-set the root_account_id to 0" do
          # Some CalendarEvent with nil root_account_id is needed to instigate the backfill
          other_ce = CalendarEvent.create!(context: @course)
          other_ce.update_columns(root_account_id: nil)

          # This is what we are testing:
          ce = CalendarEvent.create!(context: @course)
          ce.update_columns(context_id: Course.last.id.to_i + 9999)
          expect(ce.reload.root_account_id).to eq(@course.root_account_id)
          expect(ce.root_account_id).to be > 0
          DataFixup::PopulateRootAccountIdOnModels.run
          expect(ce.reload.root_account_id).to eq(@course.root_account_id)
        end
      end

      context "when context is a CourseSection that does not exist" do
        it_behaves_like "a datafixup that populates root_account_id to 0" do
          let(:record) do
            CalendarEvent.create!(context: CourseSection.create!(course: @course)).tap do |ce|
              ce.update_columns(context_id: CourseSection.last.id.to_i + 9999)
            end
          end
        end
      end

      context "when context is a Group that does not exist" do
        it_behaves_like "a datafixup that populates root_account_id to 0" do
          let(:record) do
            CalendarEvent.create!(context: group_model(context: @course)).tap do |ce|
              ce.update_columns(context_id: Group.last.id.to_i + 9999)
            end
          end
        end
      end

      context "when context is something not handled by any of our backfills" do
        it_behaves_like "a datafixup that does not populate root_account_id" do
          let(:record) do
            CalendarEvent.create!(context: @user).tap do |ce|
              ce.update_columns(context_type: "Submission", context_id: submission_model.id)
            end
          end
        end
      end
    end

    context "with ContentMigration" do
      it "populates the root_account_id" do
        cm = @course.content_migrations.create!(user: @user)
        cm.update_columns(root_account_id: nil)
        expect(cm.root_account_id).to be_nil
        DataFixup::PopulateRootAccountIdOnModels.run
        expect(cm.reload.root_account_id).to eq @course.root_account_id

        account = account_model(root_account: account_model)
        cm = account.content_migrations.create!(user: @user)
        cm.update_columns(root_account_id: nil)
        expect(cm.root_account_id).to be_nil
        DataFixup::PopulateRootAccountIdOnModels.run
        expect(cm.reload.root_account_id).to eq account.root_account_id

        group_model
        cm = @group.content_migrations.create!(user: @user)
        cm.update_columns(root_account_id: nil)
        expect(cm.root_account_id).to be_nil
        DataFixup::PopulateRootAccountIdOnModels.run
        expect(cm.reload.root_account_id).to eq @group.root_account_id
      end

      context "with a User context" do
        it_behaves_like "a datafixup that populates root_account_id to 0" do
          let(:record) { @user.content_migrations.create! }
        end
      end

      context "with sharding" do
        specs_require_sharding

        it "does not fill the root_account_id using cross-shard associations" do
          # There are for some strange reason a small amount of these. ignore them.
          account = @shard1.activate { account_model }
          @shard2.activate do
            cm = ContentMigration.create(context: account_model)
            cm.update_columns(context_id: account.global_id, root_account_id: nil)
            expect(cm.reload.root_account_id).to be_nil
            expect(cm.shard.id).to_not eq(cm.context.shard.id)
            DataFixup::PopulateRootAccountIdOnModels.run
            expect(cm.reload.root_account_id).to be_nil
          end
        end
      end
    end

    context "with ContentParticipation" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) do
          ContentParticipation.create(content: reference_record, user: @user)
        end
        let(:reference_record) { submission_model }
      end
    end

    context "with ContentParticipationCount" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { @course.content_participation_counts.create! }
        let(:reference_record) { @course }
      end
    end

    it "populates the root_account_id on ContentShare" do
      ce = @course.content_exports.create!
      cs = ce.received_content_shares.create!(user: user_model, read_state: "read", name: "test")
      cs.update_columns(root_account_id: nil)
      expect(cs.root_account_id).to be_nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(cs.reload.root_account_id).to eq @course.root_account_id

      group_model
      ce = @group.content_exports.create!
      cs = ce.received_content_shares.create!(user: user_model, read_state: "read", name: "test")
      cs.update_columns(root_account_id: nil)
      expect(cs.root_account_id).to be_nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(cs.reload.root_account_id).to eq @group.root_account_id
    end

    it "populates the root_account_id on ContextModule" do
      expect(@cm.root_account_id).to be_nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@cm.reload.root_account_id).to eq @course.root_account_id
    end

    context "with ContextModuleProgression" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { reference_record.context_module_progressions.create!(user: @user) }
        let(:reference_record) { @course.context_modules.create! }
      end
    end

    context "with CustomGradebookColumn" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) do
          CustomGradebookColumn.create!(course: @course, title: "foo")
        end
        let(:reference_record) { @course }
      end
    end

    context "with CustomGradebookColumnDatum" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) do
          reference_record.custom_gradebook_column_data.create!(content: "hi", user_id: @user.id)
        end
        let(:reference_record) { CustomGradebookColumn.create!(course: @course, title: "foo") }
      end
    end

    context "with GradingPeriod" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { grading_periods(count: 1).first }
        let(:reference_record) { record.grading_period_group }
      end
    end

    context "with GradingPeriodGroup" do
      context "when it is for a course" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) do
            Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@course)
          end
          let(:reference_record) { @course }
        end
      end

      context "when it is for a (root) account" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) do
            Factories::GradingPeriodGroupHelper.new.create_for_account(reference_record)
          end
          let(:reference_record) { account_model(root_account_id: nil) }
        end
      end
    end

    context "with GradingStandard with course context" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { grading_standard_for(@course) }
        let(:reference_record) { @course }
      end
    end

    context "with GradingStandard with account context" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { grading_standard_for(reference_record) }
        let(:reference_record) { account_model }
      end
    end

    context "with LatePolicy" do
      it_behaves_like "a datafixup that populates root_account_id" do
        # for some reason late_policy_model doesn't save the record
        let(:record) { late_policy_model(course: @course).tap(&:save!) }
        let(:reference_record) { @course }
      end
    end

    context "with learning outcomes" do
      let(:outcome) { outcome_model }
      let(:alignment) { outcome.align(assignment, @course) }
      let(:assignment) { assignment_model(course: @course) }
      let(:rubric_association) do
        rubric = outcome_with_rubric(context: @course, outcome:)
        rubric.associate_with(assignment, @course, purpose: "grading")
      end
      let(:outcome_result) do
        LearningOutcomeResult.create!(
          context: course2,
          association_type: "RubricAssociation",
          association_id: rubric_association.id,
          learning_outcome: outcome,
          user: @user,
          alignment:
        )
      end
      let(:course2) { course_model(account: account_model(root_account_id: nil)) }

      it "populates root_account_ids on LearningOutcome" do
        lo = LearningOutcome.create!(context: @course, short_description: "test")
        lo.update_columns(root_account_ids: nil)
        DataFixup::PopulateRootAccountIdOnModels.run
        expect(lo.reload.root_account_ids).to eq [@course.root_account_id]
      end

      context "with LearningOutcomeGroup" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { outcome_group_model(context: @course) }
          let(:reference_record) { @course }
        end
      end

      context "with a global LearningOutcomeGroup (null context)" do
        it_behaves_like "a datafixup that populates root_account_id to 0" do
          let(:record) do
            outcome_group_model(context: @course).tap do |og|
              og.update_columns(context_id: nil, context_type: nil)
            end
          end
        end
      end

      context "with LearningOutcomeQuestionResult" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) do
            loqr = outcome_result.learning_outcome_question_results.first_or_initialize
            loqr.save!
            loqr
          end
          let(:reference_record) { outcome_result }
        end
      end

      context "with LearningOutcomeResult" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { outcome_result }
          let(:reference_record) { course2 }
        end
      end
    end

    context "with MasterCourses::*" do
      let(:content_migration) { @course.content_migrations.create!(user: @user) }
      let(:child_course) { course_model(account: @course.account) }

      let(:master_template) { MasterCourses::MasterTemplate.create!(course: @course) }
      let(:master_migration) { MasterCourses::MasterMigration.create!(master_template:) }
      let(:child_subscription) do
        MasterCourses::ChildSubscription.create!(master_template:, child_course:)
      end

      context "with MasterCourses::ChildContentTag" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) do
            MasterCourses::ChildContentTag.create!(
              child_subscription:, content: assignment_model
            )
          end
          let(:reference_record) { child_subscription }
        end
      end

      context "with MasterCourses::ChildSubscription" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { child_subscription }
          let(:reference_record) { master_template }
        end
      end

      context "with MasterCourses::MasterContentTag" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) do
            MasterCourses::MasterContentTag.create!(
              master_template:, content: assignment_model
            )
          end
          let(:reference_record) { master_template }
        end
      end

      context "with MasterCourses::MasterMigration" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { master_migration }
          let(:reference_record) { master_template }
        end
      end

      context "with MasterCourses::MigrationResult" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) do
            MasterCourses::MigrationResult.create!(
              master_migration:,
              content_migration:,
              child_subscription:,
              import_type: :full,
              state: :queued
            )
          end
          let(:reference_record) { master_migration }
        end
      end

      context "with MasterCourses::MasterTemplate" do
        it_behaves_like "a datafixup that populates root_account_id" do
          let(:record) { master_template }
          let(:reference_record) { @course }
        end
      end
    end

    context "with OutcomeProficiency" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { outcome_proficiency_model(reference_record) }
        let(:reference_record) { account_model }
      end
    end

    context "with OutcomeProficiencyRating" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { reference_record.outcome_proficiency_ratings.first }
        let(:reference_record) { outcome_proficiency_model(account_model) }
      end
    end

    context "with PostPolicy" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { PostPolicy.create!(course: @course) }
        let(:reference_record) { @course }
      end
    end

    context "with Quizzes::Quiz" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { quiz_model(course: @course) }
        let(:reference_record) { @course }
      end
    end

    context "with Quizzes::QuizGroup" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) do
          reference_record.quiz_groups.create!
        end
        let(:reference_record) { quiz_model }
      end
    end

    context "with Quizzes::QuizQuestion" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) do
          reference_record.quiz_questions.create!(question_data: test_quiz_data.first)
        end
        let(:reference_record) { quiz_model }
      end
    end

    context "with Quizzes::QuizSubmission" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { quiz_with_submission }
        let(:reference_record) { record.quiz }
      end
    end

    context "with Quizzes::QuizSubmissionEvent" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:quiz_submission) { quiz_with_submission }
        let(:record) { quiz_submission.record_creation_event }
        let(:reference_record) { record.quiz_submission }
      end
    end

    context "with Score" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { reference_record.scores.create! }
        let(:reference_record) { enrollment_model }
      end
    end

    context "with ScoreStatistic" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) do
          ScoreStatistic.create!(
            assignment: reference_record, maximum: 100, minimum: 5, mean: 60, count: 10, lower_q: 20, median: 50, upper_q: 80
          )
        end
        let(:reference_record) { assignment_model }
      end
    end

    context "with Submission" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:submission) { submission_model }
        let(:record) { submission }
        let(:reference_record) { submission.assignment }
      end
    end

    context "with SubmissionVersion" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:assignment) { assignment_model }
        let(:record) do
          SubmissionVersion.create!(
            course: @course,
            version: Version.create!(versionable: assignment),
            assignment: assignment_model,
            user_id: @user.id
          )
        end
        let(:reference_record) { @course }
      end
    end

    context "with Rubric (course-context)" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { rubric_model(context: @course) }
        let(:reference_record) { @course }
      end
    end

    context "with Rubric (root account-context)" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { rubric_model(context: reference_record) }
        let(:reference_record) { account_model(root_account: nil) }
      end
    end

    context "with Rubric (subaccount-context)" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { rubric_model(context: reference_record) }
        let(:reference_record) { account_model(root_account: account_model) }
      end
    end

    context "with RubricAssociation (account-context)" do
      it_behaves_like "a datafixup that populates root_account_id" do
        # Gets it from the context, not the rubric
        let(:rubric) { rubric_model(context: account_model(root_account: nil)) }
        let(:record) { rubric_association_model(context: reference_record, rubric:) }
        let(:reference_record) { account_model }
      end
    end

    context "with RubricAssociation (course-context)" do
      it_behaves_like "a datafixup that populates root_account_id" do
        # Gets it from the context, not the rubric
        let(:rubric) { rubric_model(context: account_model(root_account: nil)) }
        let(:record) { rubric_association_model(context: reference_record, rubric:) }
        let(:reference_record) { @course }
      end
    end

    context "with RubricAssessment" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { rubric_assessment_model(rubric: reference_record, user: @user) }
        let(:reference_record) { rubric_model }
      end
    end

    context "with SubmissionComment" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:submission) { submission_model }
        let(:record) { submission_comment_model(submission:) }
        let(:reference_record) { submission.assignment.context }
      end
    end

    context "with Wiki (course)" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { Wiki.create!(course: @course) }
        let(:reference_record) { @course }
      end
    end

    context "with Wiki (group)" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { Wiki.create!(group: reference_record) }
        let(:reference_record) { group_model }
      end
    end

    context "with WikiPage with course context" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { wiki_page_model(context: @course) }
        let(:reference_record) { @course }
      end
    end

    context "with WikiPage with group context" do
      it_behaves_like "a datafixup that populates root_account_id" do
        let(:record) { wiki_page_model(context: reference_record) }
        let(:reference_record) { group_model }
      end
    end
  end

  describe "#run" do
    it "creates delayed jobs to backfill root_account_ids for the table" do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:delay_if_production).at_least(:once).and_return(DataFixup::PopulateRootAccountIdOnModels)
      DataFixup::PopulateRootAccountIdOnModels.run
    end

    it "creates delayed jobs for override methods for the table" do
      ContextModule.delete_all
      LearningOutcome.create!(context: @course, short_description: "test")
      LearningOutcome.update_all(root_account_ids: nil)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:populate_root_account_ids_override).at_least(:once)
      expect(DataFixup::PopulateRootAccountIdOnModels).not_to receive(:populate_root_account_ids)
      DataFixup::PopulateRootAccountIdOnModels.run
    end
  end

  describe "#clean_and_filter_tables" do
    it "removes tables from the hash that were backfilled a while ago" do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ Assignment => :course, ContextModule => :course })
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end

    it "removes tables from the hash that are in progress" do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ ContentTag => :context, ContextModule => :course })
      DataFixup::PopulateRootAccountIdOnModels.delay(priority: Delayed::MAX_PRIORITY,
                                                     n_strand: ["root_account_id_backfill", Shard.current.database_server.id])
                                              .populate_root_account_ids(ContentTag, { course: :root_account_id }, 1, 2)
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end

    it "replaces polymorphic associations with direction associations" do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ ContextModule => :context })
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end

    it "removes tables from the hash that have all their root account ids filled in" do
      DeveloperKey.create!(account: @course.account)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ DeveloperKey => :account, ContextModule => :course })
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end

    it "removes tables if all the objects with given associations have root_account_ids, even if some objects do not" do
      ContentTag.create!(assignment: assignment_model, root_account_id: @assignment.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ ContentTag => :assignment, ContextModule => :course })
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end

    it "filters tables whose prereqs are not filled with root_account_ids" do
      OriginalityReport.create!(submission: submission_model)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ OriginalityReport => :submission, ContextModule => :course })
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end

    it "filters tables whose prereqs are not direct associations and are not filled" do
      LearningOutcome.create!(context: @course, short_description: "test")
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ LearningOutcome => :content_tag, ContextModule => :course })
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end

    it "does not filter tables whose prereqs are filled with root_account_ids" do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables)
        .and_return({ ContextModule => :course })
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ ContextModule => { course: :root_account_id } })
    end
  end

  describe "in_progress_tables" do
    describe "with sharding" do
      specs_require_sharding

      it "only returns tables that are in progress for this shard" do
        @shard1.activate do
          DataFixup::PopulateRootAccountIdOnModels.delay(priority: Delayed::MAX_PRIORITY,
                                                         n_strand: ["root_account_id_backfill", Shard.current.database_server.id])
                                                  .populate_root_account_ids(ContentTag, { course: :root_account_id }, 1, 2)
        end
        DataFixup::PopulateRootAccountIdOnModels.delay(priority: Delayed::MAX_PRIORITY,
                                                       n_strand: ["root_account_id_backfill", Shard.current.database_server.id])
                                                .populate_root_account_ids(ContextModule, { course: :root_account_id }, 1, 2)
        expect(DataFixup::PopulateRootAccountIdOnModels.in_progress_tables).to eq([ContextModule])
      end
    end
  end

  describe "#hash_association" do
    it "builds a hash association when only given a table name" do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association(:assignment)).to eq(
        { assignment: :root_account_id }
      )
    end

    it "builds a hash association when only given a hash" do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association({ assignment: :id })).to eq(
        { assignment: :id }
      )
    end

    it "builds a hash association when given an array of strings/symbols" do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([:submission, :assignment])).to eq(
        { submission: :root_account_id, assignment: :root_account_id }
      )
    end

    it "builds a hash association when given an array of hashes" do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([{ submission: :id }, { assignment: :id }])).to eq(
        { submission: :id, assignment: :id }
      )
    end

    it "builds a hash association when given a mixed array" do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([{ submission: :id }, :assignment])).to eq(
        { submission: :id, assignment: :root_account_id }
      )
    end
  end

  describe "#replace_polymorphic_associations" do
    it "leaves non-polymorphic associations alone" do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(ContextModule,
                                                                                       { course: :root_account_id })).to eq({ course: :root_account_id })
    end

    it "leaves non-association dependencies alone" do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(LearningOutcome,
                                                                                       { content_tag: :root_account_id })).to eq({})
    end

    it "replaces polymorphic associations in the hash (in original order)" do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
               ContentTag, { context: [:root_account_id, :id], context_module: :root_account_id }
             )).to eq(
               {
                 course: [:root_account_id, :id],
                 learning_outcome_group: [:root_account_id, :id],
                 assignment: [:root_account_id, :id],
                 account: Account.resolved_root_account_id_sql,
                 quiz: [:root_account_id, :id],
                 context_module: :root_account_id
               }
             )
    end

    it "allows overwriting for a previous association included in a polymorphic association" do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
               ContentTag, { context: :root_account_id, course: [:root_account_id, :id] }
             )).to eq(
               {
                 course: [:root_account_id, :id],
                 learning_outcome_group: :root_account_id,
                 assignment: :root_account_id,
                 account: Account.resolved_root_account_id_sql,
                 quiz: :root_account_id
               }
             )
    end

    it "accounts for associations that have a polymorphic_prefix" do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
               CalendarEvent, { context: :root_account_id }
             )).to eq(
               {
                 context_account: "COALESCE(NULLIF(\"accounts\".root_account_id, 0), \"accounts\".\"id\")",
                 context_appointment_group: :root_account_id,
                 context_course: :root_account_id,
                 context_course_section: :root_account_id,
                 context_group: :root_account_id,
                 context_user: :root_account_id,
               }
             )
    end

    it "replaces account association with both root_account_id and id" do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
               ContextExternalTool, { course: :root_account_id, account: :root_account_id }
             )).to eq(
               {
                 account: Account.resolved_root_account_id_sql,
                 course: :root_account_id
               }
             )
    end
  end

  describe "#check_if_table_has_root_account" do
    it "returns correctly for tables with root_account_id" do
      DeveloperKey.create!(account: @course.account)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(DeveloperKey, [:account])).to be true

      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(ContextModule, [:course])).to be false
    end

    it "returns correctly for tables where we only care about certain associations" do
      # this is meant to be used for models like Attachment where we may not populate root
      # account if the context is User, but we still want to work under the assumption that
      # the table is completely backfilled

      # User-context event doesn't have root account id so we use the user's account
      event = CalendarEvent.create!(context: user_model)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
               CalendarEvent, %i[context_course context_group context_appointment_group context_course_section]
             )).to be true

      # manually adding makes the check method think it does, though
      event.update_columns(root_account_id: @course.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
               CalendarEvent, %i[context_course context_group context_appointment_group context_course_section]
             )).to be true

      # adding another User-context event should make it return false,
      # except we are explicitly ignoring User-context events
      CalendarEvent.create(context: user_model)
      CalendarEvent.create(context: @course, root_account_id: @course.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
               CalendarEvent, %i[context_course context_group context_appointment_group context_course_section]
             )).to be true
    end

    it "returns correctly for tables with root_account_ids" do
      LearningOutcome.create!(context: @course, short_description: "test")
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(LearningOutcome, [])).to be true
      LearningOutcome.update_all(root_account_ids: nil)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(LearningOutcome, [])).to be false
    end
  end

  describe "#check_if_association_has_root_account" do
    it "ignores nil reflections" do
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_association_has_root_account(LearningOutcome, nil)).to be true
    end
  end

  describe "#populate_root_account_ids" do
    it "only updates models with an id in the given range" do
      cm2 = @course.context_modules.create!
      cm2.update_columns(root_account_id: nil)

      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, { course: :root_account_id }, cm2.id, cm2.id)
      expect(@cm.reload.root_account_id).to be_nil
      expect(cm2.reload.root_account_id).to eq @course.root_account_id
    end

    it "restarts the table fixup job if there are no other root account populate delayed jobs of this type still running" do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:run).once
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, { course: :root_account_id }, @cm.id, @cm.id)
    end

    it "does not restart the table fixup job if there are items in this table that do not have root_account_id" do
      cm2 = @course.context_modules.create!
      cm2.update_columns(root_account_id: nil)

      expect(DataFixup::PopulateRootAccountIdOnModels).not_to receive(:run)
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, { course: :root_account_id }, cm2.id, cm2.id)
    end
  end

  describe "#populate_root_account_ids_override" do
    it "calls #populate on the provided module" do
      lo = LearningOutcome.create!(context: @course, short_description: "test")

      expect(DataFixup::PopulateRootAccountIdsOnLearningOutcomes).to receive(:populate).once
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids_override(LearningOutcome, DataFixup::PopulateRootAccountIdsOnLearningOutcomes, lo.id, lo.id)
    end

    it "restarts the table fixup job if there are no other delayed jobs of this type still running" do
      lo = LearningOutcome.create!(context: @course, short_description: "test")
      LearningOutcome.create!(context: @course, short_description: "test2")

      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:run).once
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids_override(LearningOutcome, DataFixup::PopulateRootAccountIdsOnLearningOutcomes, lo.id, lo.id)
    end

    it "does not restart the table fixup job if there are items in this table that do not have root_account_id" do
      LearningOutcome.create!(context: @course, short_description: "test")
      lo2 = LearningOutcome.create!(context: @course, short_description: "test2")
      lo2.update_columns(root_account_ids: nil)

      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:run).once
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids_override(LearningOutcome, DataFixup::PopulateRootAccountIdsOnLearningOutcomes, lo2.id, lo2.id)
    end
  end

  describe "#create_column_names" do
    it "creates a single column name" do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(Assignment.reflections["course"], :root_account_id)).to eq(
        "courses.root_account_id"
      )
    end

    it "coalesces multiple column names on a table" do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(Course.reflections["account"], [:root_account_id, :id])).to eq(
        "COALESCE(accounts.root_account_id, accounts.id)"
      )
    end

    it "uses actual table names for strangely named columns" do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(AssetUserAccess.reflections["context_course"], :root_account_id)).to eq(
        "courses.root_account_id"
      )
    end
  end

  describe ".scope_for_association_does_not_exist" do
    context "for specific associations of a polymorphic association" do
      it "returns the records for when the referenced record doesn't exist" do
        # Different association, not returned:
        f1 = Folder.create!(user: @user)

        # Course does not exist. Folder record returned.
        f2 = Folder.create!(context: @course)
        f2.update_columns(context_id: Course.last.id + 9999)

        # Cross-shard -- to be ignored (can't tell if it exists or not easily)
        f3 = Folder.create!(context: @course)
        f3.update_columns(context_id: ((Shard.last&.id.to_i + 99_999) * Shard::IDS_PER_SHARD) + 1)

        # Course exists. Not returned.
        f4 = Folder.create!(context: @course)
        result = described_class.scope_for_association_does_not_exist(Folder, :course).pluck(:id)

        expect(result).to_not include(f1.id)
        expect(result).to include(f2.id)
        expect(result).to_not include(f3.id)
        expect(result).to_not include(f4.id)
      end
    end

    context "for simple associations" do
      it "returns the records for when the referenced record doesn't exist" do
        # Just need some simple association w/o an FK constraint to test
        # this ... root_account on Favorite will do
        f1 = Favorite.create!(context: @course, user: @user)
        f1.update_columns(root_account_id: Account.last.id.to_i + 9999)
        f2 = Favorite.create!(context: @course, user: user_model)
        expect(f2.root_account_id).to_not be_nil
        result = described_class.scope_for_association_does_not_exist(Favorite, :root_account).pluck(:id)
        expect(result).to include(f1.id)
        expect(result).to_not include(f2.id)
      end
    end
  end
end
