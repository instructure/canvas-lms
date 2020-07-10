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

require 'spec_helper'

describe DataFixup::PopulateRootAccountIdOnModels do
  before :once do
    course_model
    @cm = @course.context_modules.create!
    @cm.update_columns(root_account_id: nil)
    user_model
  end

  # add additional models here as they are calculated and added to migration_tables.
  context 'models' do
    shared_examples_for 'a datafixup that populates root_account_id' do
      let(:record) { raise 'set in examples' }
      let(:reference_record) { raise 'set in examples' }

      before { record.update_columns(root_account_id: nil) }

      it 'should populate the root_account_id' do
        expected_root_account_id =
          if reference_record.reload.is_a?(Account)
            reference_record.resolved_root_account_id
          else
            reference_record.root_account_id
          end

        expect {
          DataFixup::PopulateRootAccountIdOnModels.run
        }.to change { record.reload.root_account_id }.from(nil).to(expected_root_account_id)
        expect(expected_root_account_id).to be_present
      end
    end

    it 'should populate the root_account_id on AccountUser' do
      au = AccountUser.create!(account: @course.account, user: @user)
      au.update_columns(root_account_id: nil)
      expect(au.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(au.reload.root_account_id).to eq @course.root_account_id

      account = account_model(root_account: account_model)
      au = AccountUser.create!(account: account, user: @user)
      au.update_columns(root_account_id: nil)
      expect(au.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(au.reload.root_account_id).to eq account.root_account_id
    end

    it 'should populate root_account_id on AssessmentQuestion' do
      aq = assessment_question_model(bank: AssessmentQuestionBank.create!(context: @course))
      aq.update_columns(root_account_id: nil)
      expect(aq.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(aq.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate root_account_id on AssessmentQuestionBank' do
      aqb = AssessmentQuestionBank.create!(context: @course)
      aqb.update_columns(root_account_id: nil)
      expect(aqb.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(aqb.reload.root_account_id).to eq @course.root_account_id

      account = account_model(root_account: account_model)
      aqb = AssessmentQuestionBank.create!(context: account)
      aqb.update_columns(root_account_id: nil)
      expect(aqb.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(aqb.reload.root_account_id).to eq account.root_account_id
    end

    it 'should populate the root_account_id on AssetUserAccess with non-user context' do
      auac = AssetUserAccess.create!(context: @course, user: @user)
      auac.update_columns(root_account_id: nil)
      expect(auac.reload.root_account_id).to eq nil

      auaa = AssetUserAccess.create!(context: @course.root_account, user: @user)
      auaa.update_columns(root_account_id: nil)
      expect(auaa.reload.root_account_id).to eq nil

      auag = AssetUserAccess.create!(context: group_model(context: @course), user: @user)
      auag.update_columns(root_account_id: nil)
      expect(auag.reload.root_account_id).to eq nil

      DataFixup::PopulateRootAccountIdOnModels.run
      expect(auac.reload.root_account_id).to eq @course.root_account_id
      expect(auaa.reload.root_account_id).to eq @course.root_account_id
      expect(auag.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on AssignmentGroup' do
      ag = @course.assignment_groups.create!(name: 'AssignmentGroup!')
      ag.update_columns(root_account_id: nil)
      expect(ag.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(ag.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on AssignmentOverride' do
      assignment_model(course: @course)
      @course.enroll_student(@user)
      create_adhoc_override_for_assignment(@assignment, @user)
      @override.update_columns(root_account_id: nil)
      expect(@override.attributes["root_account_id"]).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@override.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on AssignmentOverrideStudent' do
      assignment_model(course: @course)
      @course.enroll_student(@user)
      create_adhoc_override_for_assignment(@assignment, @user)
      @override_student.update_columns(root_account_id: nil)
      expect(@override_student.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@override_student.reload.root_account_id).to eq @course.root_account_id
    end

    context 'with ContextExternalTool' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { external_tool_model(context: @course) }
        let(:reference_record) { @course }
      end

      context 'when the tool context is a root account' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { external_tool_model(context: @course.root_account) }
          let(:reference_record) { @course }
        end
      end
    end

    it 'should populate the root_account_id on ContentMigration' do
      cm = @course.content_migrations.create!(user: @user)
      cm.update_columns(root_account_id: nil)
      expect(cm.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(cm.reload.root_account_id).to eq @course.root_account_id

      account = account_model(root_account: account_model)
      cm = account.content_migrations.create!(user: @user)
      cm.update_columns(root_account_id: nil)
      expect(cm.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(cm.reload.root_account_id).to eq account.root_account_id

      group_model
      cm = @group.content_migrations.create!(user: @user)
      cm.update_columns(root_account_id: nil)
      expect(cm.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(cm.reload.root_account_id).to eq @group.root_account_id
    end

    context 'with ContentParticipation' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) do
          ContentParticipation.create(content: reference_record, user: @user)
        end
        let(:reference_record) { submission_model }
      end
    end

    context 'with ContentParticipationCount' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { @course.content_participation_counts.create! }
        let(:reference_record) { @course }
      end
    end

    it 'should populate the root_account_id on ContentShare' do
      ce = @course.content_exports.create!
      cs = ce.received_content_shares.create!(user: user_model, read_state: 'read', name: 'test')
      cs.update_columns(root_account_id: nil)
      expect(cs.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(cs.reload.root_account_id).to eq @course.root_account_id

      group_model
      ce = @group.content_exports.create!
      cs = ce.received_content_shares.create!(user: user_model, read_state: 'read', name: 'test')
      cs.update_columns(root_account_id: nil)
      expect(cs.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(cs.reload.root_account_id).to eq @group.root_account_id
    end

    it 'should populate the root_account_id on ContextModule' do
      expect(@cm.root_account_id).to be nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@cm.reload.root_account_id).to eq @course.root_account_id
    end

    context 'with ContextModuleProgression' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { reference_record.context_module_progressions.create!(user: @user) }
        let(:reference_record) { @course.context_modules.create! }
      end
    end

    context 'with CourseAccountAssociation' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) do
          CourseAccountAssociation.create!(
            course: course_model(account: account_model(root_account_id: nil)),
            account: reference_record,
            depth: 1
          )
        end
        let(:reference_record) { account_model(root_account_id: nil) }
      end
    end

    context 'with CustomGradebookColumn' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) do
          CustomGradebookColumn.create!(course: @course, title: 'foo')
        end
        let(:reference_record) { @course }
      end
    end

    context 'with CustomGradebookColumnDatum' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) do
          reference_record.custom_gradebook_column_data.create!(content: 'hi', user_id: @user.id)
        end
        let(:reference_record) { CustomGradebookColumn.create!(course: @course, title: 'foo') }
      end
    end

    context 'with ContentTag' do
      let(:content_tag) { ContentTag.create!(context: context, content: content) }

      context 'when context is a Course' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:context) { @course }
          let(:content) { assignment_model(course: @course) }
          let(:record) { content_tag }
          let(:reference_record) { @course }
        end
      end

      context 'when context is a LearningOutcomeGroup' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:context) { outcome_group_model(context: @course) }
          let(:content) { assignment_model(course: @course) }
          let(:record) { content_tag }
          let(:reference_record) { @course }
        end
      end

      context 'when context is an Assignment' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:context) { assignment_model(course: @course) }
          let(:content) { attachment_model }
          let(:record) { content_tag }
          let(:reference_record) { @course }
        end
      end

      context 'when context is an Account' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:context) { @course.account }
          let(:content) { attachment_model }
          let(:record) { content_tag }
          let(:reference_record) { @course.account }
        end
      end

      context 'when context is a Quizzes::Quiz' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:context) { quiz_model(course: @course) }
          let(:content) { attachment_model }
          let(:record) { content_tag }
          let(:reference_record) { @course }
        end
      end
    end

    it 'should populate the root_account_id on DeveloperKey' do
      dk = DeveloperKey.create!(account: @course.account)
      dk.update_columns(root_account_id: nil)
      expect(dk.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dk.reload.root_account_id).to eq @course.root_account_id

      account = account_model(root_account: account_model)
      dk = DeveloperKey.create!(account: account)
      dk.update_columns(root_account_id: nil)
      expect(dk.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dk.reload.root_account_id).to eq account.root_account_id
    end

    it 'should populate the root_account_id on DeveloperKeyAccountBinding' do
      account_model
      dk = DeveloperKey.create!(account: @course.account)
      dkab = DeveloperKeyAccountBinding.create!(account: @account, developer_key: dk)
      dkab.update_columns(root_account_id: nil)
      expect(dkab.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dkab.reload.root_account_id).to eq @account.id
    end

    it 'should populate the root_account_id on DiscussionEntry' do
      discussion_topic_model(context: @course)
      de = @topic.discussion_entries.create!(user: user_model)
      de.update_columns(root_account_id: nil)
      expect(de.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(de.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on DiscussionEntryParticipant' do
      discussion_topic_model(context: @course)
      de = @topic.discussion_entries.create!(user: user_model)
      dep = de.discussion_entry_participants.create!(user: user_model)
      dep.update_columns(root_account_id: nil)
      expect(dep.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dep.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should populate the root_account_id on DiscussionTopic' do
      discussion_topic_model(context: @course)
      @topic.update_columns(root_account_id: nil)
      expect(@topic.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@topic.reload.root_account_id).to eq @course.root_account_id

      discussion_topic_model(context: group_model)
      @topic.update_columns(root_account_id: nil)
      expect(@topic.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@topic.reload.root_account_id).to eq @group.root_account_id
    end

    it 'should populate the root_account_id on DiscussionTopicParticipants' do
      discussion_topic_model
      dtp = @topic.discussion_topic_participants.create!(user: user_model)
      dtp.update_columns(root_account_id: nil)
      expect(dtp.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(dtp.reload.root_account_id).to eq @topic.root_account_id
    end

    context 'with EnrollmentState' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { reference_record.enrollment_state }
        let(:reference_record) { enrollment_model }
      end
    end

    context 'with GradingStandard with course context' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { grading_standard_for(@course) }
        let(:reference_record) { @course }
      end
    end

    context 'with GradingStandard with account context' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { grading_standard_for(reference_record) }
        let(:reference_record) { account_model }
      end
    end

    context 'with GroupCategory with course context' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { group_category(context: @course) }
        let(:reference_record) { @course }
      end
    end

    context 'with GroupCategory with account context' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { group_category(context: reference_record) }
        let(:reference_record) { account_model }
      end
    end

    context 'with GroupMembership' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { group_membership_model(group: reference_record) }
        let(:reference_record) { group_model }
      end
    end

    context 'with Lti::LineItem' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { line_item_model(course: @course) }
        let(:reference_record) { @course }
      end
    end

    context 'with learning outcomes' do
      let(:outcome) { outcome_model }
      let(:alignment) { outcome.align(assignment, @course) }
      let(:assignment) { assignment_model(course: @course) }
      let(:rubric_association) do
        rubric = outcome_with_rubric context: @course, outcome: outcome
        rubric.associate_with(assignment, @course, purpose: 'grading')
      end
      let(:outcome_result) do
        LearningOutcomeResult.create!(
          context: course2, association_type: 'RubricAssociation',
          association_id: rubric_association.id,
          learning_outcome: outcome, user: @user, alignment: alignment,
        )
      end
      let(:course2) { course_model(account: account_model(root_account_id: nil)) }

      context 'with LearningOutcomeGroup' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { outcome_group_model(context: @course) }
          let(:reference_record) { @course }
        end
      end

      context 'with LearningOutcomeQuestionResult' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) do
            loqr = outcome_result.learning_outcome_question_results.first_or_initialize
            loqr.save!
            loqr
          end
          let(:reference_record) { outcome_result }
        end
      end

      context 'with LearningOutcomeResult' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { outcome_result }
          let(:reference_record) { course2 }
        end
      end
    end

    context 'with LatePolicy' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        # for some reason late_policy_model doesn't save the record
        let(:record) { late_policy_model(course: @course).tap(&:save!) }
        let(:reference_record) { @course }
      end
    end

    context 'with Lti::LineItem' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { line_item_model(course: @course) }
        let(:reference_record) { @course }
      end
    end

    context 'with Lti::Result' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { lti_result_model(course: @course) }
        let(:reference_record) { record.submission }
      end
    end

    context 'with Lti::ResourceLink' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { resource_link_model(overrides: {context: @course}) }
        let(:reference_record) { @course }
      end
    end

    context 'with MasterCourses::*' do
      let(:content_migration) { @course.content_migrations.create!(user: @user) }
      let(:child_course) { course_model(account: @course.account) }

      let(:master_template) { MasterCourses::MasterTemplate.create!(course: @course) }
      let(:master_migration) { MasterCourses::MasterMigration.create!(master_template: master_template) }
      let(:child_subscription) do
        MasterCourses::ChildSubscription.create!(master_template: master_template, child_course: child_course)
      end

      context 'with MasterCourses::ChildContentTag' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) do
            MasterCourses::ChildContentTag.create!(
              child_subscription: child_subscription, content: assignment_model
            )
          end
          let(:reference_record) { child_subscription }
        end
      end

      context 'with MasterCourses::ChildSubscription' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { child_subscription }
          let(:reference_record) { master_template }
        end
      end

      context 'with MasterCourses::MasterContentTag' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) do
            MasterCourses::MasterContentTag.create!(
              master_template: master_template, content: assignment_model
            )
          end
          let(:reference_record) { master_template }
        end
      end

      context 'with MasterCourses::MasterMigration' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { master_migration }
          let(:reference_record) { master_template }
        end
      end

      context 'with MasterCourses::MigrationResult' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) do
            MasterCourses::MigrationResult.create!(
              master_migration: master_migration, content_migration: content_migration,
              child_subscription: child_subscription, import_type: :full, state: :queued
            )
          end
          let(:reference_record) { master_migration }
        end
      end

      context 'with MasterCourses::MasterTemplate' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { master_template }
          let(:reference_record) { @course }
        end
      end
    end

    context 'with OriginalityReport' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:submission) { submission_model }
        let(:record) { OriginalityReport.create!(submission: submission, workflow_state: :pending) }
        let(:reference_record) { submission }
      end
    end

    context 'with OutcomeProficiency' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { outcome_proficiency_model(reference_record) }
        let(:reference_record) { account_model }
      end
    end

    context 'with OutcomeProficiencyRating' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { reference_record.outcome_proficiency_ratings.first }
        let(:reference_record) { outcome_proficiency_model(account_model) }
      end
    end

    context 'with PostPolicy' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { PostPolicy.create!(course: @course) }
        let(:reference_record) { @course }
      end
    end

    it 'should populate the root_account_id on Quizzes::Quiz' do
      quiz_model(course: @course)
      @quiz.update_columns(root_account_id: nil)
      expect(@quiz.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(@quiz.reload.root_account_id).to eq @course.root_account_id
    end

    context 'with RoleOverride' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { RoleOverride.create!(account: reference_record, role: Role.first) }
        let(:reference_record) { account_model }
      end
    end

    context 'with Score' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { reference_record.scores.create! }
        let(:reference_record) { enrollment_model }
      end
    end

    context 'with ScoreStatistic' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) do
          ScoreStatistic.create!(
            assignment: reference_record, maximum: 100, minimum: 5, mean: 60, count: 10
          )
        end
        let(:reference_record) { assignment_model }
      end
    end

    context 'with Submission' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:submission) { submission_model }
        let(:record) { submission }
        let(:reference_record) { submission.assignment }
      end
    end

    context 'with SubmissionVersion' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:assignment) { assignment_model }
        let(:record) do
          SubmissionVersion.create!(
            course: @course, version: Version.create!(versionable: assignment),
            assignment: assignment_model, user_id: @user.id
          )
        end
        let(:reference_record) { @course }
      end
    end

    it 'should populate the root_account_id on UserAccountAssociation' do
      uaa = UserAccountAssociation.create!(account: @course.root_account, user: user_model)
      uaa.update_columns(root_account_id: nil)
      expect(uaa.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(uaa.reload.root_account_id).to eq @course.root_account_id

      account = account_model(root_account: account_model)
      uaa = UserAccountAssociation.create!(account: account, user: @user)
      uaa.update_columns(root_account_id: nil)
      expect(uaa.reload.root_account_id).to eq nil
      DataFixup::PopulateRootAccountIdOnModels.run
      expect(uaa.reload.root_account_id).to eq account.root_account_id
    end

    context 'with Rubric (course-context)' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { rubric_model(context: @course) }
        let(:reference_record) { @course }
      end
    end

    context 'with Rubric (root account-context)' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { rubric_model(context: reference_record) }
        let(:reference_record) { account_model(root_account: nil) }
      end
    end

    context 'with Rubric (subaccount-context)' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { rubric_model(context: reference_record) }
        let(:reference_record) { account_model(root_account: account_model) }
      end
    end

    context 'with RubricAssociation (account-context)' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        # Gets it from the context, not the rubric
        let(:rubric) { rubric_model(context: account_model(root_account: nil)) }
        let(:record) { rubric_association_model(context: reference_record, rubric: rubric) }
        let(:reference_record) { account_model }
      end
    end

    context 'with RubricAssociation (course-context)' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        # Gets it from the context, not the rubric
        let(:rubric) { rubric_model(context: account_model(root_account: nil)) }
        let(:record) { rubric_association_model(context: reference_record, rubric: rubric) }
        let(:reference_record) { @course }
      end
    end

    context 'with RubricAssessment' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { rubric_assessment_model(rubric: reference_record, user: @user) }
        let(:reference_record) { rubric_model }
      end
    end

    context 'with SubmissionComment' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:submission) { submission_model }
        let(:record) { submission_comment_model(submission: submission) }
        let(:reference_record) { submission.assignment.context }
      end
    end

    context 'with WebConference*' do
      let(:conference) do
        allow(WebConference).to receive(:plugins).and_return([web_conference_plugin_mock("wimba", {:domain => "wimba.test"})])
        WimbaConference.create!(title: "my conference", user: @user, context: @course)
      end

      context 'with WebConference' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { conference }
          let(:reference_record) { @course }
        end
      end

      context 'with WebConferenceParticipant' do
        it_behaves_like 'a datafixup that populates root_account_id' do
          let(:record) { conference.web_conference_participants.create!(user: user_model) }
          let(:reference_record) { conference }
        end
      end
    end

    context 'with Wiki (course)' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { Wiki.create!(course: @course) }
        let(:reference_record) { @course }
      end
    end

    context 'with Wiki (group)' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { Wiki.create!(group: reference_record) }
        let(:reference_record) { group_model }
      end
    end

    context 'with WikiPage with course context' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { wiki_page_model(context: @course) }
        let(:reference_record) { @course }
      end
    end

    context 'with WikiPage with group context' do
      it_behaves_like 'a datafixup that populates root_account_id' do
        let(:record) { wiki_page_model(context: reference_record) }
        let(:reference_record) { group_model }
      end
    end
  end

  describe '#run' do
    it 'should create delayed jobs to backfill root_account_ids for the table' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:send_later_if_production_enqueue_args)
      DataFixup::PopulateRootAccountIdOnModels.run
    end
  end

  describe '#clean_and_filter_tables' do
    it 'should remove tables from the hash that were backfilled a while ago' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({Assignment => :course, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should remove tables from the hash that are in progress' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContentTag => :context, ContextModule => :course})
      DataFixup::PopulateRootAccountIdOnModels.send_later_enqueue_args(:populate_root_account_ids,
        {
          priority: Delayed::MAX_PRIORITY,
          n_strand: ["root_account_id_backfill", Shard.current.database_server.id]
        },
        ContentTag, {course: :root_account_id}, 1, 2)
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should replace polymorphic associations with direction associations' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContextModule => :context})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should remove tables from the hash that have all their root account ids filled in' do
      DeveloperKey.create!(account: @course.account)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({DeveloperKey => :account, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should remove tables if all the objects with given associations have root_account_ids, even if some objects do not' do
      ContentTag.create!(assignment: assignment_model, root_account_id: @assignment.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContentTag => :assignment, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should filter tables whose prereqs are not filled with root_account_ids' do
      OriginalityReport.create!(submission: submission_model)
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({OriginalityReport => :submission, ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end

    it 'should not filter tables whose prereqs are filled with root_account_ids' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:migration_tables).
        and_return({ContextModule => :course})
      expect(DataFixup::PopulateRootAccountIdOnModels.clean_and_filter_tables).to eq({ContextModule => {course: :root_account_id}})
    end
  end

  describe 'in_progress_tables' do
    describe 'with sharding' do
      specs_require_sharding

      it 'should only return tables that are in progress for this shard' do
        @shard1.activate do
          DataFixup::PopulateRootAccountIdOnModels.send_later_enqueue_args(:populate_root_account_ids,
            {
              priority: Delayed::MAX_PRIORITY,
              n_strand: ["root_account_id_backfill", Shard.current.database_server.id]
            },
            ContentTag, {course: :root_account_id}, 1, 2)
        end
        DataFixup::PopulateRootAccountIdOnModels.send_later_enqueue_args(:populate_root_account_ids,
          {
            priority: Delayed::MAX_PRIORITY,
            n_strand: ["root_account_id_backfill", Shard.current.database_server.id]
          },
          ContextModule, {course: :root_account_id}, 1, 2)
        expect(DataFixup::PopulateRootAccountIdOnModels.in_progress_tables).to eq([ContextModule])
      end
    end
  end

  describe '#hash_association' do
    it 'should build a hash association when only given a table name' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association(:assignment)).to eq(
        {assignment: :root_account_id}
      )
    end

    it 'should build a hash association when only given a hash' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association({assignment: :id})).to eq(
        {assignment: :id}
      )
    end

    it 'should build a hash association when given an array of strings/symbols' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([:submission, :assignment])).to eq(
        {submission: :root_account_id, assignment: :root_account_id}
      )
    end

    it 'should build a hash association when given an array of hashes' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([{submission: :id}, {assignment: :id}])).to eq(
        {submission: :id, assignment: :id}
      )
    end

    it 'should build a hash association when given a mixed array' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association([{submission: :id}, :assignment])).to eq(
        {submission: :id, assignment: :root_account_id}
      )
    end

    it 'should turn string associations/columns into symbols' do
      expect(DataFixup::PopulateRootAccountIdOnModels.hash_association(
        [{'submission' => ['root_account_id', 'id']}, 'assignment']
      )).to eq({submission: [:root_account_id, :id], assignment: :root_account_id})
    end
  end

  describe '#replace_polymorphic_associations' do
    it 'should leave non-polymorphic associations alone' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(ContextModule,
        {course: :root_account_id})).to eq({course: :root_account_id})
    end

    it 'should replace polymorphic associations in the hash (in original order)' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        ContentTag, {context: [:root_account_id, :id], context_module: :root_account_id}
      )).to eq(
        {
          course: [:root_account_id, :id],
          learning_outcome_group: [:root_account_id, :id],
          assignment: [:root_account_id, :id],
          account: [:root_account_id, :id],
          quiz: [:root_account_id, :id],
          context_module: :root_account_id
        }
      )
    end

    it 'should allow overwriting for a previous association included in a polymorphic association' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        ContentTag, {context: :root_account_id, course: [:root_account_id, :id]}
      )).to eq(
        {
          course: [:root_account_id, :id],
          learning_outcome_group: :root_account_id,
          assignment: :root_account_id,
          account: [:root_account_id, :id],
          quiz: :root_account_id
        }
      )
    end

    it 'should account for associations that have a polymorphic_prefix' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        CalendarEvent, {context: :root_account_id}
      )).to eq(
        {
          :context_appointment_group => :root_account_id,
          :context_course => :root_account_id,
          :context_course_section => :root_account_id,
          :context_group => :root_account_id,
          :context_user => :root_account_id,
        }
      )
    end

    it 'should replace account association with both root_account_id and id' do
      expect(DataFixup::PopulateRootAccountIdOnModels.replace_polymorphic_associations(
        ContextExternalTool, {course: :root_account_id, account: :root_account_id}
      )).to eq(
        {
          :account=>[:root_account_id, :id],
          :course=>:root_account_id
        }
      )
    end
  end

  describe '#check_if_table_has_root_account' do
    it 'should return correctly for tables with root_account_id' do
      DeveloperKey.create!(account: @course.account)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(DeveloperKey)).to be true

      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(ContextModule)).to be false
    end

    it 'should return correctly for tables where we only care about certain associations' do
      # this is meant to be used for models like Attachment where we may not populate root
      # account if the context is User, but we still want to work under the assumption that
      # the table is completely backfilled

      # User-context event doesn't have root account id so we use the user's account
      event = CalendarEvent.create!(context: user_model)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
        CalendarEvent
      )).to be true

      # manually adding makes the check method think it does, though
      event.update_columns(root_account_id: @course.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
        CalendarEvent
      )).to be true

      # adding another User-context event should make it return false,
      # except we are explicitly ignoring User-context events
      CalendarEvent.create(context: user_model)
      CalendarEvent.create(context: @course, root_account_id: @course.root_account_id)
      expect(DataFixup::PopulateRootAccountIdOnModels.check_if_table_has_root_account(
        CalendarEvent, [:context_course, :context_group, :context_appointment_group, :context_course_section]
      )).to be true
    end
  end

  describe '#populate_root_account_ids' do
    it 'should only update models with an id in the given range' do
      cm2 = @course.context_modules.create!
      cm2.update_columns(root_account_id: nil)

      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, {course: :root_account_id}, cm2.id, cm2.id)
      expect(@cm.reload.root_account_id).to be nil
      expect(cm2.reload.root_account_id).to eq @course.root_account_id
    end

    it 'should restart the table fixup job if there are no other root account populate delayed jobs of this type still running' do
      expect(DataFixup::PopulateRootAccountIdOnModels).to receive(:run).once
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, {course: :root_account_id}, @cm.id, @cm.id)
    end

    it 'should not restart the table fixup job if there are items in this table that do not have root_account_id' do
      cm2 = @course.context_modules.create!
      cm2.update_columns(root_account_id: nil)

      expect(DataFixup::PopulateRootAccountIdOnModels).not_to receive(:run)
      DataFixup::PopulateRootAccountIdOnModels.populate_root_account_ids(ContextModule, {course: :root_account_id}, cm2.id, cm2.id)
    end
  end

  describe '#create_column_names' do
    it 'should create a single column name' do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(Assignment.reflections["course"], 'root_account_id')).to eq(
        'courses.root_account_id'
      )
    end

    it 'should coalesce multiple column names on a table' do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(Course.reflections["account"], ['root_account_id', :id])).to eq(
        "COALESCE(accounts.root_account_id, accounts.id)"
      )
    end

    it 'should use actual table names for strangely named columns' do
      expect(DataFixup::PopulateRootAccountIdOnModels.create_column_names(AssetUserAccess.reflections["context_course"], 'root_account_id')).to eq(
        'courses.root_account_id'
      )
    end
  end
end
