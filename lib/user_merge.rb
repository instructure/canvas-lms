# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class UserMerge
  class UnsafeMergeError < StandardError; end

  def self.from(user)
    new(user)
  end

  attr_reader :from_user
  attr_accessor :target_user, :data, :merge_data

  def initialize(from_user)
    @from_user = from_user
    @target_user = nil
    @merge_data = nil
    @data = []
  end

  def into(target_user, merger: nil, source: nil)
    return unless target_user
    return if target_user == from_user
    raise "cannot merge a test student" if from_user.preferences[:fake_student] || target_user.preferences[:fake_student]

    if UserMergeData.active.splitable.where(user_id: target_user, from_user_id: from_user).exists?
      raise UnsafeMergeError,
            "There is already an existing active user merge for target user, from user: (#{target_user.id}, #{from_user.id})}"
    end

    @target_user = target_user
    target_user.associate_with_shard(from_user.shard, :shadow)
    # we also store records for the from_user on the target shard for a split
    from_user.associate_with_shard(target_user.shard, :shadow)
    target_user.shard.activate do
      @merge_data = UserMergeData.create!(user: target_user, from_user:, workflow_state: "merging")
      @merge_data.items.create!(user: target_user, item_type: "logs", item: { merger_id: merger.id, source: }.to_s) if merger || source

      items = []
      if target_user.avatar_state == :none && from_user.avatar_state != :none
        %i[avatar_image_source avatar_image_url avatar_image_updated_at avatar_state].each do |attr|
          items << merge_data.items.new(user: from_user, item_type: attr.to_s, item: from_user[attr]) if from_user[attr]
          target_user[attr] = from_user[attr]
        end
      end

      # record the users names and preferences in case of split.
      items << merge_data.items.new(user: from_user, item_type: "user_name", item: from_user.name)
      items << merge_data.items.new(user: target_user, item_type: "user_name", item: target_user.name)
      UserMergeDataItem.bulk_insert_objects(items)

      # bulk insert doesn't play nice with the hash values of preferences.
      merge_data.items.create!(user: from_user, item_type: "user_preferences", item: from_user.preferences)
      merge_data.items.create!(user: target_user, item_type: "user_preferences", item: target_user.preferences)

      copy_migrated_preferences # uses new rows to store preferences
      prefs = from_user.preferences
      target_user.preferences = target_user.preferences.merge(prefs)
      target_user.save if target_user.changed?

      { access_token_ids: from_user.access_tokens.shard(from_user).pluck(:id),
        conversation_messages_ids: ConversationMessage.where(author_id: from_user, conversation_id: nil).shard(from_user).pluck(:id),
        conversation_ids: from_user.all_conversations.shard(from_user).pluck(:id),
        ignore_ids: from_user.ignores.shard(from_user).pluck(:id),
        user_past_lti_id_ids: from_user.past_lti_ids.shard(from_user).pluck(:id),
        "Polling::Poll_ids": from_user.polls.shard(from_user).pluck(:id) }.each do |k, ids|
        merge_data.items.create!(user: from_user, item_type: k, item: ids) unless ids.empty?
      end
    end

    %i[strong weak shadow].each do |strength|
      from_user.associated_shards(strength).each do |shard|
        target_user.associate_with_shard(shard, strength)
      end
    end

    # moving LTI IDs to the new user is preferable if possible, so launches from new enrollments or global nav
    # will continue using the same ID as before - but if the target user has already done LTI launches,
    # we need to use the past lti id system instead
    if can_move_lti_ids?
      move_lti_ids
    else
      populate_past_lti_ids
    end

    copy_favorites
    handle_communication_channels
    destroy_conflicting_module_progressions
    move_enrollments
    move_observees

    Shard.with_each_shard(from_user.associated_shards + from_user.associated_shards(:weak) + from_user.associated_shards(:shadow)) do
      max_position = Pseudonym.where(user_id: target_user).ordered.last.try(:position) || 0
      pseudonyms_to_move = Pseudonym.where(user_id: from_user)
      merge_data.add_more_data(pseudonyms_to_move)
      pseudonyms_to_move.update_all(["updated_at=NOW(), user_id=?, position=position+?", target_user, max_position])

      target_user.communication_channels.email.unretired.each do |cc|
        Rails.cache.delete([cc.path, "invited_enrollments2"].cache_key)
      end

      handle_submissions

      from_user.all_conversations.find_each { |c| c.move_to_user(target_user) }

      # all topics changing ownership or with entries changing ownership need to be
      # flagged as updated so the materialized views update
      begin
        entries = DiscussionEntry.where(user_id: from_user)
        DiscussionTopic.where(id: entries.select(["discussion_topic_id"])).touch_all
        entries.update_all(user_id: target_user.id)
        DiscussionTopic.where(user_id: from_user).update_all(user_id: target_user.id, updated_at: Time.now.utc)
      rescue => e
        Rails.logger.error "migrating discussions failed: #{e}"
      end

      account_users = AccountUser.where(user_id: from_user)
      merge_data.add_more_data(account_users)
      account_users.update_all(user_id: target_user.id, updated_at: Time.now.utc)

      attachments = Attachment.where(user_id: from_user)
      merge_data.add_more_data(attachments)
      Attachment.delay.migrate_attachments(from_user, target_user)

      updates = {}
      %w[access_tokens
         asset_user_accesses
         calendar_events
         collaborations
         context_module_progressions
         group_memberships
         ignores
         page_comments
         Polling::Poll
         rubric_assessments
         user_services
         web_conference_participants
         web_conferences
         wiki_pages].each do |key|
        updates[key] = "user_id"
      end
      updates["submission_comments"] = "author_id"
      updates["conversation_messages"] = "author_id"
      updates = updates.to_a
      version_updates = ["rubric_assessments", "wiki_pages"]
      touching_updates = ["access_tokens", "group_memberships"]
      updates.each do |table, column|
        klass = table.classify.constantize
        if klass.new.respond_to?(:"#{column}=")
          scope = klass.where(column => from_user)
          klass.transaction do
            if version_updates.include?(table)
              update_versions(scope, table, column)
            end

            update = { column => target_user.id }
            if touching_updates.include?(table) && klass.column_names.include?("updated_at")
              update[:updated_at] = Time.now.utc
            end
            scope.in_batches(of: 1000).update_all(update)
          end
        end
      rescue => e
        Rails.logger.error "migrating #{table} column #{column} failed: #{e}"
      end

      context_updates = ["calendar_events"]
      context_updates.each do |table|
        klass = table.classify.constantize
        scope = klass.where(context_id: from_user, context_type: "User")
        scope.update_all(context_id: target_user.id, context_code: target_user.asset_string)
      end

      merge_data.bulk_insert_merge_data(data) unless data.empty?
      @data = []
      Enrollment.delay.recompute_due_dates_and_scores(target_user.id)
      target_user.update_account_associations
    end

    from_user.reload
    target_user.clear_caches
    from_user.update!(merged_into_user: target_user)
    from_user.destroy
    @merge_data.workflow_state = "active"
    @merge_data.save!
  rescue => e
    @merge_data&.update_attribute(:workflow_state, "failed")
    @merge_data&.items&.create!(user: target_user, item_type: "merge_error", item: e.backtrace.unshift(e.message))
    Canvas::Errors.capture(e, type: :user_merge, merge_data_id: @merge_data&.id, from_user_id: from_user&.id, target_user_id: target_user&.id)
    raise
  end

  def copy_favorites
    from_user.favorites.preload(:context).find_each do |f|
      # don't attempt to create a favorite if the context is missing
      next unless f.context.present?

      target_user.favorites.find_or_create_by(context: f.context)
    end
  end

  def translate_course_id_or_asset_string(key)
    id = key.is_a?(String) ? key.split("_").last : key
    new_id = Shard.relative_id_for(id, from_user.shard, target_user.shard)
    key.is_a?(String) ? [key.split("_").first, new_id].join("_") : new_id
  end

  def copy_migrated_preferences
    from_values = from_user.user_preference_values.to_a
    target_values = target_user.user_preference_values.to_a.index_by { |r| [r.key, r.sub_key] }

    new_record_hashes = []
    existing_record_updates = {}

    from_values.each do |from_record|
      key = from_record.key
      sub_key = from_record.sub_key
      value = from_record.value
      if from_user.shard != target_user.shard
        case key
        when "custom_colors"
          value = value.transform_keys { |id| translate_course_id_or_asset_string(id) }
        when "course_nicknames"
          sub_key = translate_course_id_or_asset_string(sub_key)
        end
      end

      if (existing_record = target_values[[key, sub_key]])
        existing_record_updates[existing_record] = value
      else
        new_record_hashes << { user_id: target_user.id, key:, sub_key: sub_key&.to_json, value: value.to_yaml }
      end
    end
    target_user.shard.activate do
      UserPreferenceValue.bulk_insert(new_record_hashes)
      existing_record_updates.each do |record, new_value|
        UserPreferenceValue.where(id: record).update_all(value: new_value)
      end
    end
  end

  def can_move_lti_ids?
    # the target has already done an LTI 1.1 launch
    return false if target_user.lti_context_id.present?

    # we can't tell explicitly if the user has done an LTI 1.3 launch but we can infer
    # they are unlikely to have done so if they have no enrollments or account users
    return false if target_user.has_enrollment? || target_user.account_membership?

    # the source user already has past LTI IDs that would be orphaned if we did this
    return false if from_user.past_lti_ids.shard(from_user.associated_shards).exists?

    true
  end

  def move_lti_ids
    # retrieve the ids from the old user and nil them out
    from_lti_context_id = from_user.lti_context_id
    from_lti_id = from_user.lti_id
    from_uuid = from_user.uuid

    from_user.override_lti_id_lock = true
    from_user.lti_context_id = nil
    from_user.lti_id = nil
    from_user.uuid = nil

    # get the old ids from the target user and replace them with the source user's
    target_lti_id = target_user.lti_id
    target_uuid = target_user.uuid

    target_user.override_lti_id_lock = true
    target_user.lti_context_id = from_lti_context_id
    target_user.lti_id = from_lti_id
    target_user.uuid = from_uuid

    # perform the move in the DB, updating shadow records synchronously so the target user
    # doesn't trip over the unique constraint. retry once in case of odd timing issues
    User.unique_constraint_retry do
      from_user.lti_context_id_will_change!
      from_user.update_shadow_records_synchronously!
      from_user.save!

      target_user.save!
    end

    if merge_data
      # finally, store target user's existing lti_id and uuid in MergeData so we can restore them in a split
      # (the target lti_context_is is nil or we wouldn't be here, but the lti_id is populated on create, not on demand)
      merge_data.items.create!(user: target_user, item_type: "lti_id", item: target_lti_id)
      merge_data.items.create!(user: target_user, item_type: "uuid", item: target_uuid)
    end
  rescue ActiveRecord::RecordNotUnique
    # if we fail to move lti ids after a retry, put the source user's ids back and fall back on the old behavior
    from_user.update! lti_context_id: from_lti_context_id, lti_id: from_lti_id, uuid: from_uuid
    InstStatsd::Statsd.increment("user_merge.move_lti_ids.unique_constraint_failure")
    populate_past_lti_ids
  end

  # used by SplitUsers to undo this operation from merge
  def move_lti_ids_to(target_user)
    @target_user = target_user
    move_lti_ids
  end

  def populate_past_lti_ids
    move_existing_past_lti_ids
    Shard.with_each_shard(from_user.associated_shards + from_user.associated_shards(:weak) + from_user.associated_shards(:shadow)) do
      lti_ids = []
      { enrollments: :course, group_memberships: :group, account_users: :account }.each do |klass, type|
        klass.to_s.classify.constantize.where(user_id: from_user).distinct_on(type.to_s + "_id").each do |context|
          next if UserPastLtiId.where(user: [target_user, from_user], context_id: context.send(type.to_s + "_id"), context_type: type.to_s.classify).exists?

          lti_ids << UserPastLtiId.new(user: target_user,
                                       context_id: context.send(type.to_s + "_id"),
                                       context_type: type.to_s.classify,
                                       user_uuid: from_user.uuid,
                                       user_lti_id: from_user.lti_id,
                                       user_lti_context_id: from_user.lti_context_id)
        end
      end
      UserPastLtiId.bulk_insert_objects(lti_ids)
    end
  end

  def move_existing_past_lti_ids
    existing_past_ids = target_user.past_lti_ids.select(:context_id, :context_type).shard(target_user).group_by(&:context_type)
    if existing_past_ids.present?
      %w[Group Account Course].each do |klass|
        next unless existing_past_ids[klass]

        Shard.partition_by_shard(existing_past_ids[klass]) do |shard_past_ids|
          UserPastLtiId.where(user_id: from_user, context_type: klass).where.not(context_id: shard_past_ids.map(&:context_id)).update_all(user_id: target_user.id)
        end
      end
    else
      # there are no possible conflicts just move them over
      Shard.partition_by_shard(from_user.past_lti_ids.shard(from_user).pluck(:id)) do |shard_past_ids|
        UserPastLtiId.where(id: shard_past_ids).update_all(user_id: target_user.id)
      end
    end
  end

  def handle_communication_channels
    max_position = target_user.communication_channels.last&.position&.+(1) || 0
    to_retire_ids = []
    known_ccs = target_user.communication_channels.pluck(:id)
    from_user.communication_channels.each do |cc|
      # have to find conflicting CCs, and make sure we don't have conflicts
      target_cc = detect_conflicting_cc(cc)

      if !target_cc && from_user.shard != target_user.shard
        User.clone_communication_channel(cc, target_user, max_position)
        new_cc = target_user.communication_channels.where.not(id: known_ccs).take
        known_ccs << new_cc.id
        merge_data.build_more_data([new_cc], user: target_user, workflow_state: "non_existent", data:)
      end

      next unless target_cc

      to_retire = identify_to_retire(cc, target_cc, max_position)
      next unless to_retire

      keeper = ([target_cc, cc] - [to_retire]).first
      copy_notificaion_policies(to_retire, keeper)
      to_retire_ids << to_retire.id
    end

    finish_ccs(max_position, to_retire_ids)
  end

  def detect_conflicting_cc(source_cc)
    target_user.communication_channels.detect do |c|
      c.path.casecmp?(source_cc.path) && c.path_type == source_cc.path_type
    end
  end

  def finish_ccs(max_position, to_retire_ids)
    if from_user.shard == target_user.shard
      from_user.shard.activate do
        ccs = CommunicationChannel.where(id: to_retire_ids).where.not(workflow_state: "retired")
        merge_data.build_more_data(ccs, data:) unless to_retire_ids.empty?
        ccs.update_all(workflow_state: "retired") unless to_retire_ids.empty?
      end
      scope = from_user.communication_channels.where.not(workflow_state: "retired")
      scope = scope.where.not(id: to_retire_ids) unless to_retire_ids.empty?
      unless scope.empty?
        merge_data.build_more_data(scope, data:)
        scope.touch_all
        scope.update_all(["user_id=?, position=position+?, root_account_ids='{?}'", target_user, max_position, target_user.root_account_ids])
      end
    else
      handle_cross_shard_cc
    end
    merge_data.bulk_insert_merge_data(data) unless data.empty?
    @data = []
  end

  def handle_cross_shard_cc
    ccs = from_user.communication_channels.where.not(workflow_state: "retired")
    merge_data.build_more_data(ccs, data:) unless ccs.empty?
    ccs.update_all(workflow_state: "retired") unless ccs.empty?

    from_user.user_services.each do |us|
      new_us = us.clone
      new_us.shard = target_user.shard
      new_us.user = target_user
      new_us.save!
      merge_data.build_more_data([new_us], user: target_user, workflow_state: "non_existent", data:)
    end
    merge_data.build_more_data(from_user.user_services, data:)
    from_user.user_services.delete_all
  end

  def identify_to_retire(source_cc, target_cc, max_position)
    # we prefer keeping the "most" active one, preferring the target user if they're equal
    # the comments inline show all the different cases, with the source cc on the left,
    # target cc on the right.  The * indicates the CC that will be retired in order
    # to resolve the conflict
    if target_cc.active?
      # retired, active
      # unconfirmed*, active
      # active*, active
      to_retire = source_cc
    elsif source_cc.active?
      # active, unconfirmed*
      # active, retired
      # target_cc will not be able to be restored on split, but it is either unconfirmed or retired so nbd
      target_cc.destroy_permanently!
      if from_user.shard != target_user.shard
        User.clone_communication_channel(source_cc, target_user, max_position)
      end
    elsif target_cc.unconfirmed? # rubocop:disable Lint/DuplicateBranch
      # unconfirmed*, unconfirmed
      # retired, unconfirmed
      to_retire = source_cc
    elsif source_cc.unconfirmed? # rubocop:disable Lint/DuplicateBranch
      # unconfirmed, retired
      # target_cc will not be able to be restored on split, but it is either unconfirmed or retired so nbd
      target_cc.destroy_permanently!
      if from_user.shard != target_user.shard
        User.clone_communication_channel(source_cc, target_user, max_position)
      # elsif (to_retire = source_cc) # rubocop:disable Layout/CommentIndentation
        # retired, retired
      end
    end
    to_retire
  end

  def copy_notificaion_policies(to_retire, keeper)
    # if the communication_channel is already retired, don't bother.
    return if to_retire.workflow_state == "retired"

    time = Time.zone.now
    new_nps = []
    keeper.shard.activate do
      to_retire.notification_policies.where.not(notification_id: keeper.notification_policies.pluck(:notification_id)).each do |np|
        new_nps << NotificationPolicy.new(notification_id: np.notification_id,
                                          communication_channel_id: keeper.id,
                                          frequency: np.frequency,
                                          created_at: time,
                                          updated_at: time)
      end
      NotificationPolicy.bulk_insert_objects(new_nps)
    end
  end

  def move_observees
    merge_data.bulk_insert_merge_data(data) unless data.empty?
    @data = []
    observer_links = from_user.as_observer_observation_links.shard(from_user)
    # record all the records before destroying them
    # pass the from_user since user_id on observation_link is the student we are targeting the observer here
    merge_data.build_more_data(observer_links, user: from_user, data:)

    Shard.partition_by_shard(observer_links) do |shard_observer_links|
      # restore user observation links that are deleted on the target user but active on the from_user
      UserObservationLink.where(
        observer_id: target_user,
        workflow_state: "deleted",
        user_id: shard_observer_links.map(&:user_id)
      ).update_all(workflow_state: "active", updated_at: Time.now.utc)
      # delete links that are now duplicates between the from_user and target_user
      UserObservationLink.where(id: shard_observer_links).where(user_id: target_user.as_observer_observation_links.select(:user_id)).destroy_all
      # delete what would be observing themselves.
      UserObservationLink.where(id: shard_observer_links).where(user_id: target_user).destroy_all
      to_delete = target_user.as_student_observation_links.where(observer_id: from_user)
      merge_data.build_more_data(to_delete, data:)
      to_delete.destroy_all
      # update links to target_user
      UserObservationLink.active.where(id: shard_observer_links).update_all(observer_id: target_user.id, updated_at: Time.now.utc)
    end

    student_links = from_user.as_student_observation_links.shard(from_user)
    merge_data.build_more_data(student_links, data:)
    Shard.partition_by_shard(student_links) do |shard_student_links|
      # restore user observee links that are deleted on the target user but active on the from_user
      UserObservationLink.where(
        observer_id: shard_student_links.map(&:observer_id),
        workflow_state: "deleted",
        user_id: target_user
      ).update_all(workflow_state: "active", updated_at: Time.now.utc)
      # delete links that are now duplicates between the from_user and target_user
      UserObservationLink.where(id: shard_student_links).where(observer_id: target_user.as_student_observation_links.select(:observer_id)).destroy_all
      # delete what would be observing themselves.
      UserObservationLink.where(id: shard_student_links).where(observer_id: target_user).destroy_all
      to_delete = target_user.as_observer_observation_links.where(user_id: from_user)
      merge_data.build_more_data(to_delete, data:)
      to_delete.destroy_all
      # update links to target_user
      UserObservationLink.active.where(id: shard_student_links).update_all(user_id: target_user.id, updated_at: Time.now.utc)
      target_user.as_student_observation_links.where(observer_id: shard_student_links).each(&:create_linked_enrollments)
    end

    # for any observers not already watching both users, make sure they have
    # any missing observer enrollments added
    if from_user.shard != target_user.shard
      from_user.shard.activate do
        UserObservationLink.where("user_id=?", target_user.id).where(id: data.map(&:context_id)).preload(:observer, :root_account).find_each do |link|
          # if the target_user is the same as the observer we already have a record
          next if Shard.shard_for(link.observer_id) == target_user.shard
          next if target_user.as_student_observation_links.active.where(observer_id: link.observer).for_root_accounts(link.root_account).exists?

          # create the record on the target users shard.
          new_link = UserObservationLink.create_or_restore(student: target_user, observer: link.observer, root_account: link.root_account)
          merge_data.build_more_data([new_link], user: target_user, workflow_state: "non_existent", data:)
        end
      end
    end

    merge_data.bulk_insert_merge_data(data) unless data.empty?
    @data = []
  end

  def destroy_conflicting_module_progressions
    # there is a unique index on the context_module_progressions table
    # we need to delete all the conflicting context_module_progressions
    # without impacting the users module progress and without having to
    # recalculate the progressions.
    # find all the modules progressions and delete the most restrictive
    # context_module_progressions
    ContextModuleProgression
      .where(context_module_progressions: { user_id: from_user.id })
      .where("EXISTS (SELECT *
                     FROM #{ContextModuleProgression.quoted_table_name} cmp2
                     WHERE context_module_progressions.context_module_id=cmp2.context_module_id
                       AND cmp2.user_id = ?)",
             target_user.id).find_each do |cmp|
      ContextModuleProgression
        .where(context_module_id: cmp.context_module_id, user_id: [from_user, target_user])
        .order(Arel.sql("CASE WHEN workflow_state = 'completed' THEN 0
                       WHEN workflow_state = 'started' THEN 1
                       WHEN workflow_state = 'unlocked' THEN 2
                       WHEN workflow_state = 'locked' THEN 3
                       END DESC")).first.destroy
    end
  end

  def conflict_scope(column)
    other_column = (column == :user_id) ? :associated_user_id : :user_id
    Enrollment
      .select("type, role_id, course_section_id, #{other_column}")
      .group("type, role_id, course_section_id, #{other_column}")
      .having("COUNT(*) > 1")
  end

  def enrollment_conflicts(enrollment, column, users)
    scope = Enrollment
            .where(type: enrollment.type,
                   role_id: enrollment.role_id,
                   course_section_id: enrollment.course_section_id)

    if column == :user_id
      scope.where(user_id: users, associated_user_id: enrollment.associated_user_id)
    else
      scope.where(user_id: enrollment.user_id, associated_user_id: users)
    end
  end

  def enrollment_keeper(scope)
    # prefer active enrollments to have no impact to the end user.
    # then just keep the newest one.
    scope.order(Arel.sql("CASE WHEN workflow_state='active' THEN 1
                          WHEN workflow_state='invited' THEN 2
                          WHEN workflow_state='creation_pending' THEN 3
                          WHEN workflow_state='completed' THEN 4
                          WHEN workflow_state='rejected' THEN 5
                          WHEN workflow_state='inactive' THEN 6
                          WHEN workflow_state='deleted' THEN 7
                          ELSE 8
                          END, updated_at DESC")).first
  end

  def update_enrollment_state(scope, keeper)
    # update the record on the target user to the better state of the from users enrollment
    enrollment_ids = Enrollment.where(id: scope).where.not(id: keeper).pluck(:id)
    Enrollment.where(id: enrollment_ids).update_all(workflow_state: keeper.workflow_state)
    EnrollmentState.force_recalculation(enrollment_ids)

    # mark the would be keeper from the from_user as deleted so it will not be moved later
    keeper.destroy
  end

  def handle_conflicts(column)
    users = [from_user, target_user]

    # get each pair of conflicts and "handle them"
    conflict_scope(column).where(column => users).find_each do |e|
      # identify the other record that is conflicting with this one.
      scope = enrollment_conflicts(e, column, users)
      # get the highest state between the 2 users enrollments
      keeper = enrollment_keeper(scope)

      # identify if the target_users record needs promoted to better state
      to_update = scope.where.not(id: keeper).where(column => target_user)
      # if the target_users enrollment state will be updated pass the scope so
      # both target and from users records will be recorded in case of a split.
      if to_update.exists?
        # record both records state since both will change
        merge_data.build_more_data(scope, data:)
        update_enrollment_state(scope, keeper)
      end

      # identify if the from users records are worse states than target user
      to_delete = scope.active.where.not(id: keeper).where(column => from_user)
      # record the current state in case of split
      merge_data.build_more_data(to_delete, data:)
      # mark all conflicts on from_user as deleted so they will not be moved later
      to_delete.destroy_all
    end
  end

  def remove_self_observers
    # prevent observing self by marking them as deleted
    to_delete = Enrollment.active.where("type = 'ObserverEnrollment' AND
                                                   (associated_user_id = :target_user AND user_id = :from_user OR
                                                   associated_user_id = :from_user AND user_id = :target_user)",
                                        { target_user:, from_user: })
    merge_data.build_more_data(to_delete, data:)
    to_delete.destroy_all
  end

  def move_enrollments
    [:associated_user_id, :user_id].each do |column|
      Shard.with_each_shard(from_user.associated_shards) do
        Enrollment.transaction do
          handle_conflicts(column)
          remove_self_observers
          # move all the enrollments that have not been marked as deleted to the target user
          to_move = Enrollment.active.where(column => from_user)
          # upgrade to strong association if there are any enrollments
          target_user.associate_with_shard(from_user.shard) if to_move.exists?
          merge_data.build_more_data(to_move, data:)
          to_move.update_all(column => target_user.id, :updated_at => Time.now.utc)
        end
      end
    end
    merge_data.bulk_insert_merge_data(data) unless data.empty?
    @data = []
  end

  def handle_submissions
    [
      [:assignment_id, :submissions],
      [:quiz_id, :"quizzes/quiz_submissions"]
    ].each do |unique_id, table|
      # Submissions are a special case since there's a unique index
      # on the table, and if both the old user and the new user
      # have a submission for the same assignment there will be
      # a conflict.
      model = table.to_s.classify.constantize
      already_scope = model.where(user_id: target_user)
      scope = model.where(user_id: from_user)
      case model.name
      when "Submission"
        # we prefer submissions that have grades than submissions that have
        # a submission... that sort of makes sense.
        # we swap empty objects in cases of collision so that we don't
        # end up causing a unique index violation for a given assignment for
        # the either user, but also so we don't destroy submissions in case
        # of a user split.
        to_move_ids = scope.graded.select(unique_id).where.not(unique_id => already_scope.graded.select(unique_id)).pluck(:id)
        to_move_ids += scope.having_submission
                            .select(unique_id)
                            .where.not(unique_id => already_scope.having_submission.select(unique_id))
                            .where.not(id: to_move_ids)
                            .pluck(:id)
        # only include placeholder submissions for a conflicting assignment
        # if there isn't already an existing submission for the target user
        to_move_ids += scope.without_submission
                            .select(unique_id)
                            .where.not(unique_id => already_scope.having_submission.select(unique_id))
                            .where.not(id: to_move_ids)
                            .pluck(:id)
        to_move = scope.where(id: to_move_ids).to_a
        move_back = already_scope.where(unique_id => to_move.map(&unique_id)).to_a
        merge_data.build_more_data(to_move, data:) unless to_move.empty?
        merge_data.build_more_data(move_back, data:) unless move_back.empty?
        swap_submission(model, move_back, table, to_move, to_move_ids, "fk_rails_8d85741475")
        swap_assignment_override_student(model, move_back, to_move)
      when "Quizzes::QuizSubmission"
        subscope = already_scope.to_a
        to_move = model.where(user_id: from_user).joins(:submission).where(submissions: { user_id: target_user }).to_a
        move_back = model.where(user_id: target_user).joins(:submission).where(submissions: { user_id: from_user }).to_a

        to_move += scope.where("#{unique_id} NOT IN (?)", [subscope.map(&unique_id), move_back.map(&unique_id)].flatten).to_a
        move_back += already_scope.where(unique_id => to_move.map(&unique_id)).to_a
        merge_data.build_more_data(to_move, data:)
        merge_data.build_more_data(move_back, data:)
        swap_submission(model, move_back, table, to_move, to_move, "fk_rails_04850db4b4")
        swap_assignment_override_student(model, move_back, to_move)
      end
    rescue => e
      Rails.logger.error "migrating #{table} column user_id failed: #{e}"
    end
    merge_data.bulk_insert_merge_data(data) unless data.empty?
    @data = []
  end

  def swap_submission(model, move_back, table, to_move, to_move_ids, fkey)
    return if to_move_ids.empty?

    model.transaction do
      # there is a unique index on assignment_id and user_id. Unique
      # indexes are checked after every row during an update statement
      # to get around this and to allow us to swap we are setting the
      # user_id to the negative user_id and then the user_id, after the
      # conflicting rows have been updated.
      model.connection.execute("SET CONSTRAINTS #{model.connection.quote_table_name(fkey)} DEFERRED")
      move_back.each_slice(1000) { |batch| model.where(id: batch).update_all(user_id: -from_user.id) }
      to_move_ids.each_slice(1000) { |batch| model.where(id: batch).update_all(user_id: target_user.id) }
      move_back.each_slice(1000) { |batch| model.where(id: batch).update_all(user_id: from_user.id) }
      to_move.each_slice(1000) { |batch| update_versions(model.where(id: batch), table, :user_id) }
      move_back.each_slice(1000) { |batch| update_versions(model.where(id: batch), table, :user_id) }
    end
  end

  def swap_assignment_override_student(model, move_back, to_move)
    return if to_move.empty?

    to_move_ids = model.where(id: to_move).select(:assignment_id)
    move_back_ids = model.where(id: move_back).select(:assignment_id)
    to_move = AssignmentOverrideStudent.where(user_id: from_user, assignment_id: to_move_ids)
    move_back = AssignmentOverrideStudent.where(user_id: from_user, assignment_id: move_back_ids)
    # bail early if we don't have any student overrides to move
    return unless to_move.exists?

    merge_data.build_more_data(to_move, data:)
    merge_data.build_more_data(move_back, data:)

    AssignmentOverrideStudent.transaction do
      connection = AssignmentOverrideStudent.connection
      fkey = connection.find_foreign_key(:assignment_override_students, :users)
      # DEFERRED constraints are not checked until transaction commit (at the end of the statement)
      # We defer due to the unique constraint on (assignment_id, user_id) so we can
      # swap user id's without facing a violation
      connection.execute("SET CONSTRAINTS #{connection.quote_table_name(fkey)} DEFERRED")
      move_back.update_all(user_id: -from_user.id)
      to_move.update_all(user_id: target_user.id)
      move_back.update_all(user_id: from_user.id)
    end
  end

  def update_versions(scope, table, column)
    scope.find_ids_in_batches do |ids|
      versionable_type = table.to_s.classify
      # TODO: This is a hack to support namespacing
      versionable_type = ["QuizSubmission", "Quizzes::QuizSubmission"] if table.to_s == "quizzes/quiz_submissions"
      version_ids = []
      Version.where(versionable_type:, versionable_id: ids).find_in_batches(strategy: :cursor) do |versions|
        versions.each do |version|
          version_attrs = YAML.load(version.yaml)
          if version_attrs[column.to_s] == from_user.id
            version_attrs[column.to_s] = target_user.id
          end
          # i'm pretty sure simply_versioned just stores fields as strings, but
          # i haven't had time to verify that 100% yet, so better safe than sorry
          if version_attrs[column.to_sym] == from_user.id
            version_attrs[column.to_sym] = target_user.id
          end
          version.yaml = version_attrs.to_yaml
          version.save!
          if versionable_type == "Submission"
            version_ids << version.id
          end
        rescue => e
          Rails.logger.error "migrating versions for #{table} column #{column} failed: #{e}"
          raise e unless Rails.env.production?
        end
      end
      if version_ids.present?
        SubmissionVersion.where(version_id: version_ids, user_id: from_user).update_all(user_id: target_user.id)
      end
    end
  end
end
