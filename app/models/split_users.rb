# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class SplitUsers
  class UnsafeSplitError < StandardError; end

  ENROLLMENT_DATA_UPDATES = [
    { table: "asset_user_accesses",
      scope: -> { where(context_type: "Course") } }.freeze,
    { table: "asset_user_accesses",
      scope: -> { joins(:context_group).where(groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "calendar_events",
      scope: -> { where(context_type: "Course") } }.freeze,
    { table: "calendar_events",
      scope: -> { joins(:context_group).where(groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "collaborations",
      scope: -> { where(context_type: "Course") } }.freeze,
    { table: "collaborations",
      scope: -> { joins(:group).where(groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "context_module_progressions",
      scope: -> { joins(:context_module) },
      context_id: "context_modules.context_id" }.freeze,
    { table: "discussion_entries",
      scope: -> { joins(:discussion_topic).where(discussion_topics: { context_type: "Course" }) },
      context_id: "discussion_topics.context_id" }.freeze,
    { table: "discussion_entries",
      scope: -> { joins({ discussion_topic: :group }).where(groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "discussion_entries",
      foreign_key: :editor_id,
      scope: -> { joins(:discussion_topic).where(discussion_topics: { context_type: "Course" }) },
      context_id: "discussion_topics.context_id" }.freeze,
    { table: "discussion_entries",
      foreign_key: :editor_id,
      scope: -> { joins({ discussion_topic: :group }).where(groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "discussion_topics",
      scope: -> { where(context_type: "Course") } }.freeze,
    { table: "discussion_topics",
      scope: -> { joins(:group).where(groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "discussion_topics",
      foreign_key: :editor_id,
      scope: -> { where(context_type: "Course") } }.freeze,
    { table: "discussion_topics",
      foreign_key: :editor_id,
      scope: -> { joins(:group).where(groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "page_views",
      scope: -> { where(context_type: "Course") } }.freeze,
    { table: "rubric_assessments",
      scope: -> { joins({ submission: :assignment }) },
      context_id: "assignments.context_id" }.freeze,
    { table: "rubric_assessments",
      foreign_key: :assessor_id,
      scope: -> { joins({ submission: :assignment }) },
      context_id: "assignments.context_id" }.freeze,
    { table: "submission_comments", foreign_key: :author_id }.freeze,
    { table: "web_conference_participants",
      scope: -> { joins(:web_conference).where(web_conferences: { context_type: "Course" }) },
      context_id: "web_conferences.context_id" }.freeze,
    { table: "web_conference_participants",
      scope: -> { joins({ web_conference: :group }).where(web_conferences: { context_type: "Course" }, groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "web_conferences",
      scope: -> { where(context_type: "Course") } }.freeze,
    { table: "web_conferences",
      scope: -> { joins(:group).where(web_conferences: { context_type: "Course" }, groups: { context_type: "Course" }) },
      context_id: "groups.context_id" }.freeze,
    { table: "wiki_pages",
      scope: -> { joins({ wiki: :course }) },
      context_id: "courses.id" }.freeze
  ].freeze

  attr_accessor :source_user, :restored_user, :merge_data

  def initialize(source_user, merge_data)
    @source_user = source_user
    @merge_data = merge_data
    @restored_user = nil
  end

  def self.split_db_users(user, merge_data = nil)
    if merge_data
      users = new(user, merge_data).split_users
    else
      users = []
      UserMergeData.active.splitable.where(user_id: user).shard(user).order(created_at: :desc).uniq(&:from_user_id).each do |data|
        splitters = new(user, data).split_users
        users = splitters | users
      end
    end
    users
  end

  def split_users
    source_user.shard.activate do
      ActiveRecord::Base.transaction do
        @restored_user = User.find(merge_data.from_user_id)
        records = merge_data.records
        pseudonyms = restore_users
        records = check_and_update_local_ids(records) if merge_data.from_user_id > Shard::IDS_PER_SHARD
        records = records.preload(:context)
        restore_merge_items
        undo_move_lti_ids
        move_records_to_old_user(records, pseudonyms)
        # update account associations for each split out user
        users = [restored_user, source_user]
        User.update_account_associations(users, all_shards: (restored_user.shard != source_user.shard))
        merge_data.destroy
        User.where(id: users).touch_all
        users
      end
    end
  end

  private

  MERGE_ITEM_TYPES = { access_token: :user_id,
                       conversation_message: :author_id,
                       favorite: :user_id,
                       ignore: :user_id,
                       user_past_lti_id: :user_id,
                       "Polling::Poll": :user_id }.freeze

  def restore_merge_items
    Shard.with_each_shard(restored_user.associated_shards + restored_user.associated_shards(:weak) + restored_user.associated_shards(:shadow)) do
      UserPastLtiId.where(user: source_user, user_lti_id: restored_user.lti_id).delete_all
    end
    source_user.shard.activate do
      ConversationParticipant.where(id: merge_data.items.where(item_type: "conversation_ids").take&.item).find_each { |c| c.move_to_user(restored_user) }
    end
    MERGE_ITEM_TYPES.each do |klass, user_attr|
      ids = merge_data.items.where(item_type: klass.to_s + "_ids").take&.item
      Shard.partition_by_shard(ids) { |shard_ids| klass.to_s.classify.constantize.where(id: shard_ids).update_all(user_attr => restored_user.id) } if ids
    end
  end

  def undo_move_lti_ids
    old_lti_id = merge_data.items.where(item_type: "lti_id").pick(:item)
    old_uuid = merge_data.items.where(item_type: "uuid").pick(:item)
    if old_lti_id && old_uuid
      # if these merge items are here, we moved LTI IDs as part of the merge
      # and we need to move them back now
      UserMerge.from(source_user).move_lti_ids_to(restored_user)
      # ask for a real sub-transaction to avoid rolling back the parent transaction
      User.transaction(requires_new: true) do
        source_user.override_lti_id_lock = true
        source_user.update!(lti_id: old_lti_id, uuid: old_uuid)
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # if we get a unique constraint failure, track via a statsd counter
    # and move on. this is a rare case, but it can happen if we swap source user lti/uuid
    # values (to the restored/target user) that match the merge data items we're trying to restore
    # to the source user.
    InstStatsd::Statsd.increment("split_users.undo_move_lti_ids.unique_constraint_failure")
  end

  def check_and_update_local_ids(records)
    # if both users have the same local id, this isn't a safe guess to make
    return records if source_user.local_id == restored_user.local_id

    if records.where("previous_user_id<?", Shard::IDS_PER_SHARD).where(previous_user_id: restored_user.local_id).exists?
      records.where(previous_user_id: restored_user.local_id).update_all(previous_user_id: restored_user.global_id)
    end
    records.reload
  end

  def move_records_to_old_user(records, pseudonyms)
    fix_communication_channels(records.where(context_type: "CommunicationChannel"))
    move_user_observers(records.where(context_type: ["UserObserver", "UserObservationLink"], previous_user_id: restored_user))
    move_attachments(records.where(context_type: "Attachment"))
    handle_submissions(records)
    enrollment_ids = records.where(context_type: "Enrollment", previous_user_id: restored_user).pluck(:context_id)
    Shard.partition_by_shard(enrollment_ids) do |enrollments|
      restore_enrollments(enrollments)
    end
    Shard.partition_by_shard(pseudonyms) do |shard_pseudonyms|
      move_new_enrollments(enrollment_ids, shard_pseudonyms)
    end
    recompute_due_dates

    account_users_ids = records.where(context_type: "AccountUser").pluck(:context_id)

    Shard.partition_by_shard(account_users_ids) do |shard_account_user_ids|
      AccountUser.where(id: shard_account_user_ids).update_all(user_id: restored_user.id)
    end
    restore_workflow_states_from_records(records)
  end

  def restore_enrollments(enrollments)
    enrollments = Enrollment.where(id: enrollments).where.not(user: restored_user)
    move_enrollments(enrollments)
  end

  def move_new_enrollments(enrollment_ids, pseudonyms)
    new_enrollments = Enrollment.where.not(id: enrollment_ids).where.not(user: restored_user)
                                .where(sis_pseudonym_id: pseudonyms).shard(pseudonyms.first.shard)
    move_enrollments(new_enrollments)
  end

  def move_enrollments(enrollments)
    enrollments_to_update = filter_enrollments(enrollments)
    Enrollment.where(id: enrollments_to_update).update_all(user_id: restored_user.id, updated_at: Time.now.utc)
    courses = enrollments_to_update.map(&:course_id)
    transfer_enrollment_data(Course.where(id: courses))
    move_submissions(enrollments_to_update)
  end

  def filter_enrollments(enrollments)
    enrollments.reject do |e|
      # skip conflicting enrollments
      Enrollment.where(user_id: restored_user,
                       course_section_id: e.course_section_id,
                       type: e.type,
                       role_id: e.role_id).where.not(id: e).shard(e.shard).exists?
    end
  end

  def fix_communication_channels(cc_records)
    if source_user.shard != restored_user.shard
      source_user.shard.activate do
        # remove communication channels that didn't exist prior to the merge
        ccs = CommunicationChannel.where(id: cc_records.where(previous_workflow_state: "non_existent").pluck(:context_id))
        DelayedMessage.where(communication_channel_id: ccs).delete_all
        NotificationPolicy.where(communication_channel: ccs).delete_all
        NotificationPolicyOverride.where(communication_channel: ccs).delete_all
        ccs.delete_all
      end
    end

    # in cases where there are conflicting records
    # between the source and target (of merge) comm records,
    # we can eliminate some errors by detecting these and destroying
    # the source record if it's already retired (because the one from
    # the merge is about to overwrite it)
    cc_records.where(previous_user_id: restored_user).each do |cr|
      target_cc = cr.context
      # if this cc didn't get moved, we don't need to worry
      # about deconflicting it with the source users.
      next unless target_cc&.user_id == source_user.id

      conflict_cc = restored_user.communication_channels.detect do |c|
        c.path.casecmp?(target_cc.path) && c.path_type == target_cc.path_type
      end
      if conflict_cc
        # we need to resolve before we can un-merge
        if conflict_cc.retired? || conflict_cc.unconfirmed?
          # when the comm channel from the target record gets moved back, it will
          # get restored to whatever state it needs.  This one is in a useless state,
          # so we could just blast this one away safely.
          conflict_cc.destroy_permanently!
        else
          raise UnsafeSplitError, "Unsafe to decide automatically which CC to delete (for now): ( #{target_cc.id} , #{conflict_cc.id} ) from merge record #{cr.id}"
        end
      end
    end

    # move moved communication channels back
    max_position = restored_user.communication_channels.last&.position&.+(1) || 0
    scope = source_user.communication_channels.where(id: cc_records.where(previous_user_id: restored_user).pluck(:context_id))
    # passing the array to update_all so we can get postgres to add the position for us.
    unless scope.empty?
      scope.update_all(["user_id=?, position=position+?, root_account_ids='{?}'",
                        restored_user.id,
                        max_position,
                        restored_user.root_account_ids])
    end

    cc_records.where.not(previous_workflow_state: "non existent").each do |cr|
      CommunicationChannel.where(id: cr.context_id).update_all(workflow_state: cr.previous_workflow_state)
    end
  end

  def move_user_observers(records)
    # skip when the user observer is between the two users. Just undelete the record
    not_obs = UserObservationLink.where(user_id: [source_user, restored_user], observer_id: [source_user, restored_user])
    obs = UserObservationLink.where(id: records.pluck(:context_id)).where.not(id: not_obs)

    not_obs.update(workflow_state: "active")
    Shard.partition_by_shard(obs) do |shard_obs|
      UserObservationLink.where(user_id: source_user.id, id: shard_obs).update_all(user_id: restored_user.id)
      UserObservationLink.where(observer_id: source_user.id, id: shard_obs).update_all(observer_id: restored_user.id)
    end

    delete_ids = merge_data.records.where(context_type: "UserObservationLink", previous_workflow_state: "non_existent", previous_user_id: source_user).pluck(:context_id)
    Shard.partition_by_shard(delete_ids) do |sharded_ids|
      UserObservationLink.where(user_id: source_user.id).where(id: sharded_ids).delete_all
      UserObservationLink.where(observer_id: source_user.id).where(id: sharded_ids).delete_all
    end
  end

  def move_attachments(records)
    attachments = source_user.attachments.where(id: records.pluck(:context_id))
    Attachment.migrate_attachments(source_user, restored_user, attachments)
  end

  def restore_users
    restore_source_user
    pseudonyms_ids = merge_data.records.where(context_type: "Pseudonym").pluck(:context_id)
    pseudonyms = Pseudonym.where(id: pseudonyms_ids)
    # the where.not needs to be used incase that user is actually deleted
    name =
      merge_data.items.where.not(user_id: source_user).where(item_type: "user_name").take&.item
    prefs =
      merge_data.items.where.not(user_id: source_user).where(item_type: "user_preferences").take&.item
    @restored_user ||= User.new
    @restored_user.name = name || pseudonyms.first&.unique_id || "restored user"
    @restored_user.preferences = prefs if prefs
    @restored_user.workflow_state = "registered"
    shard = Shard.shard_for(merge_data.from_user_id)
    shard ||= source_user.shard
    @restored_user.shard = shard if @restored_user.new_record?
    @restored_user.save!
    return [] unless pseudonyms.exists?

    move_pseudonyms_to_user(pseudonyms)
    pseudonyms
  end

  def restore_source_user
    %i[avatar_image_source avatar_image_url avatar_image_updated_at avatar_state].each do |attr|
      avatar_item = merge_data.items.where.not(user_id: source_user).where(item_type: attr).take&.item
      # we only move avatar items if there were no avatar on the source_user,
      # so now we only restore it if they match what was on the from_user.
      source_user[attr] = avatar_item if source_user[attr] == avatar_item
    end
    source_user.name = merge_data.items.where(user_id: source_user, item_type: "user_name").take&.item
    # we will leave the merged preferences on the user, most of them are for a
    # specific context that will not be there, but it will keep new
    # preferences except for terms_of_use.
    source_user.preferences[:accepted_terms] = merge_data.items
                                                         .where(user_id: source_user).where(item_type: "user_preferences").take&.item&.dig(:accepted_terms)
    source_user.preferences = {} if source_user.preferences == { accepted_terms: nil }
    source_user.save! if source_user.changed?
  end

  def move_pseudonyms_to_user(pseudonyms)
    pseudonyms.each do |pseudonym|
      pseudonym.update_attribute(:user_id, restored_user.id)
    end
  end

  def transfer_enrollment_data(courses)
    # use a partition proc so that we only run on the actual course shard, not all
    # shards associated with the course
    Shard.partition_by_shard(courses, ->(course) { course.shard }) do |shard_course|
      source_user_id = source_user.id
      target_user_id = restored_user.id
      ENROLLMENT_DATA_UPDATES.each do |update|
        relation = update[:table].classify.constantize.all
        relation = relation.instance_exec(&update[:scope]) if update[:scope]

        relation
          .where(update[:context_id] || :context_id => shard_course,
                 update[:foreign_key] || :user_id => source_user_id)
          .update_all(update[:foreign_key] || :user_id => target_user_id)
      end
    end
  end

  # enrollments are enrollments that have been created since the merge event,
  # but for a pseudonym that was moved back to the old user.
  # Also work that has happened since the merge event should moved if the
  # enrollment is moved.
  def move_submissions(enrollments)
    # NOTE: this is called (indirectly) inside partition_by_shard, so it only needs to deal with Shard.current,
    # which is the shard the enrollments and associated submissions are in.
    source_user_submissions = source_user.submissions.shard(Shard.current).where(course_id: enrollments.map(&:course_id))
    restored_user_submissions = restored_user.all_submissions.shard(Shard.current)

    # move submissions to the restored user, swapping any conflicting deleted/unsubmitted submissions
    # back to the source user to satisfy unique constraints and foreign keys
    # and leaving other submissions alone
    ids_to_swap = restored_user_submissions
                  .where(assignment_id: source_user_submissions.select(:assignment_id),
                         workflow_state: %w[deleted unsubmitted])
                  .pluck(:id)
    ids_to_move = source_user_submissions
                  .where.not(assignment_id: restored_user_submissions.where.not(id: ids_to_swap).select(:assignment_id))
                  .pluck(:id)
    swap_records(Submission, ids_to_move, ids_to_swap)

    # since unsubmitted quiz submissions aren't a thing, just move over everything that doesn't clash
    source_user.quiz_submissions.shard(Shard.current).where(quiz_id: Quizzes::Quiz.where(context_id: enrollments.map(&:course_id)))
               .where.not(quiz_id: restored_user.quiz_submissions.shard(Shard.current).select(:quiz_id))
               .update_all(user_id: restored_user.id)
  end

  def handle_submissions(records)
    [Submission, Quizzes::QuizSubmission].each do |model|
      ids_by_shard = records.where(context_type: model.to_s, previous_user_id: restored_user).pluck(:context_id).group_by { |id| Shard.shard_for(id) }
      other_ids_by_shard = records.where(context_type: model.to_s, previous_user_id: source_user).pluck(:context_id).group_by { |id| Shard.shard_for(id) }

      (ids_by_shard.keys + other_ids_by_shard.keys).uniq.each do |shard|
        ids = ids_by_shard[shard] || []
        other_ids = other_ids_by_shard[shard] || []
        shard.activate do
          if model == Submission
            # also swap restored user's deleted/unsubmitted submissions that need to be moved out of the way
            other_ids += model.where(user_id: restored_user,
                                     workflow_state: %w[deleted unsubmitted],
                                     assignment_id: model.where(id: ids).select(:assignment_id))
                              .where.not(id: other_ids)
                              .pluck(:id)
            # Delete existing source_user unsubmitted/deleted submissions that would otherwise
            # clash with the restored_user submission user_id swap to the source_user.
            # Exclude known submission ids present in the user merge data records.
            conflicting_submissions = model.where(user_id: source_user,
                                                  workflow_state: %w[deleted unsubmitted],
                                                  assignment_id: model.where(id: other_ids).select(:assignment_id))
                                           .where.not(id: ids)
            conflicting_submissions.delete_all if conflicting_submissions.exists?
          end
          swap_records(model, ids, other_ids)
        end
      end
    end
  end

  def swap_records(model, ids_to_restored_user, ids_to_source_user)
    if ids_to_source_user.any?
      foreign_key = case model.to_s
                    when "Submission" then "fk_rails_8d85741475"
                    when "Quizzes::QuizSubmission" then "fk_rails_04850db4b4"
                    end
      model.transaction(requires_new: true) do
        # defer foreign key checks so we can swap the user_ids (which are themselves subject to unique constraint)
        model.connection.execute("SET CONSTRAINTS #{model.connection.quote_table_name(foreign_key)} DEFERRED") if foreign_key
        model.where(id: ids_to_restored_user).update_all(user_id: -restored_user.id)
        model.where(id: ids_to_source_user).update_all(user_id: source_user.id)
        model.where(id: ids_to_restored_user).update_all(user_id: restored_user.id)
      end
    else
      # don't go through the swap rigamarole if we don't have to
      model.where(id: ids_to_restored_user).update_all(user_id: restored_user.id)
    end
  end

  def restore_workflow_states_from_records(records)
    records.each do |r|
      c = r.context
      next unless c && c.class.columns_hash.key?("workflow_state")

      c.workflow_state = r.previous_workflow_state unless c.instance_of?(Attachment)
      c.file_state = r.previous_workflow_state if c.instance_of?(Attachment)
      c.save! if c.changed? && c.valid?
    end
  end

  def recompute_due_dates
    Enrollment.delay.recompute_due_dates_and_scores(source_user.id)
    Enrollment.delay.recompute_due_dates_and_scores(restored_user.id)
  end
end
