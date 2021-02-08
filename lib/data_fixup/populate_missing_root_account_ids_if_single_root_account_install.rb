# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

# In case there were any NULL root_account_id / root_account_ids columns after
# running DataFixup::PopulateRootAccountIdOnModels, if this is a single-root
# account install of Canvas (e.g., OSS Canvas), we assume we can fill in the
# root account ID with that one root account
module DataFixup::PopulateMissingRootAccountIdsIfSingleRootAccountInstall
  module_function

  def run
    # Don't know if this is possible, but lots of code relies on having a site admin:
    return unless Account.site_admin

    return unless Account.site_admin.shard == Shard.current

    populate_site_admin_records

    root_accounts = Account.root_accounts.where.not(id: Account.site_admin.id).limit(2).to_a
    return unless root_accounts.count == 1

    root_account_id = root_accounts.first.id
    return if Course.where.not(root_account_id: root_account_id).any?

    populate_missing_root_account_ids(root_account_id)
  end

  def populate_missing_root_account_ids(root_account_id)
    if Group.where.not(root_account_id: root_account_id).none?
      possibly_group_related_tables.each do |table|
        populate_nils_on_table(table, :root_account_id, root_account_id)
      end
    end

    single_root_account_id_tables.each do |table|
      populate_nils_on_table(table, :root_account_id, root_account_id)
    end

    string_multiple_root_account_ids_tables.each do |table|
      populate_nils_on_table(table, :root_account_ids, root_account_id.to_s)
    end
  end

  def populate_nils_on_table(model, field_name, fill_with)
    while model.where(field_name => nil).limit(10000).update_all(field_name => fill_with) > 0
    end
  end

  def populate_site_admin_records
    # DeveloperKey and AccessToken. Do this by checking account_id of the dev
    # key to be a little safer.
    sa_id = Account.site_admin.id
    loop do
      ids = DeveloperKey.where(root_account_id: nil, account_id: nil).limit(10000).pluck(:id)
      break if ids.empty?

      DeveloperKey.where(id: ids).update_all(root_account_id: sa_id)
      AccessToken.where(developer_key_id: ids).update_all(root_account_id: sa_id)
    end
  end

  def single_root_account_id_tables
    [
      AssignmentGroup,
      AssignmentOverride,
      AssignmentOverrideStudent,
      ContentParticipation,
      ContentParticipationCount,
      ContextModule,
      ContextModuleProgression,
      CustomGradebookColumn,
      CustomGradebookColumnDatum,
      EnrollmentState,
      GradingPeriod,
      GradingPeriodGroup,
      LatePolicy,
      LearningOutcomeQuestionResult,
      LearningOutcomeResult,
      Lti::LineItem,
      Lti::Result,
      MasterCourses::ChildContentTag,
      MasterCourses::ChildSubscription,
      MasterCourses::MasterContentTag,
      MasterCourses::MasterMigration,
      MasterCourses::MasterTemplate,
      MasterCourses::MigrationResult,
      OriginalityReport,
      OutcomeProficiencyRating,
      PostPolicy,
      Quizzes::Quiz,
      Quizzes::QuizGroup,
      Quizzes::QuizQuestion,
      Quizzes::QuizSubmission,
      Quizzes::QuizSubmissionEvent,
      Score,
      ScoreStatistic,
      Submission,
      SubmissionComment,
      SubmissionVersion,
    ]
  end

  def string_multiple_root_account_ids_tables
    [
      Conversation,
      ConversationMessage,
      ConversationMessageParticipant,
      ConversationParticipant,
    ]
  end

  def possibly_group_related_tables
    [
      AttachmentAssociation,
      ContentShare,
      DiscussionEntry,
      DiscussionEntryParticipant,
      DiscussionTopic,
      DiscussionTopicParticipant,
      Favorite,
      GroupMembership,
      Wiki,
      WikiPage,
    ]
  end
end
