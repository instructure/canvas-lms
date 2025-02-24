# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

#
# Code which syncs course enrollments to Microsoft groups/teams. This is a good
# starting place to understand the syncing process.
# See also MicrosoftSync::Group model.
#
# This ideally shouldn't contain much job plumbing (retry logic, strands, state
# storage, etc.), but focus on the business logic about what to do in each step
# of a sync. For job plumbing, see StateMachineJob. This should normally be
# used by creating a StateMachineJob with this as the steps_object; see
# MicrosoftSync::Group#syncer_job
#   group.syncer_job.run_later
#   group.syncer_job.run_synchronously # e.g. manually in a console
#
module MicrosoftSync
  class SyncerSteps
    # Database batch size for users without AAD ids. Should be an even multiple of
    # GraphServiceHelpers::USERS_ULUVS_TO_AADS_BATCH_SIZE:
    ENROLLMENTS_ULUV_FETCHING_BATCH_SIZE = 750

    # Delays for intermittent errors and to allow Microsoft's
    # eventually-consistent API time to settle:
    STANDARD_RETRY_DELAY = [15, 60, 300].freeze
    DELAY_BEFORE_UPDATE_GROUP = 8.seconds
    DELAY_BEFORE_CREATE_TEAM = 24.seconds

    # The more changes, the more likely it is that some of the changes will
    # be duplicative and cause retries when adding/removing, which makes
    # partial sync less efficient, and it makes sense to just do a full sync.
    # This number is fairly arbitrary but it should be small enough that
    # we can get all the enrollments from the DB in one fetch.  Also, given a
    # max course size of 25k, this means that in the worst case, triggering a
    # full sync would be (25k/20) extra requests to get the current user list,
    # or about 3 extra requests per user added... not too bad.
    MAX_PARTIAL_SYNC_CHANGES = 500

    STATSD_NAME = "microsoft_sync.syncer_steps"
    STATSD_NAME_SKIPPED_BATCHES = "#{STATSD_NAME}.skipped_batches".freeze
    STATSD_NAME_SKIPPED_TOTAL = "#{STATSD_NAME}.skipped_total".freeze
    STATSD_NAME_DELETED_MAPPINGS_FOR_MISSING_USERS =
      "#{STATSD_NAME}.deleted_mappings_for_missing_users".freeze

    # Can happen when User disables sync on account-level when jobs are running:
    class TenantMissingOrSyncDisabled < Errors::GracefulCancelError
      def self.public_message
        I18n.t "Tenant missing or sync disabled. " \
               "Check the Microsoft sync integration settings for the course and account."
      end
    end

    class MultipleEducationClasses < Errors::GracefulCancelError
      def self.public_message
        I18n.t "Multiple Microsoft education classes already exist for the course."
      end
    end

    class MaxMemberEnrollmentsReached < Errors::GracefulCancelError
      def self.public_message
        I18n.t "Microsoft 365 allows a maximum of %{max} members in a team."
      end

      def public_interpolated_values
        { max: MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS }
      end
    end

    class MaxOwnerEnrollmentsReached < Errors::GracefulCancelError
      def self.public_message
        I18n.t "Microsoft 365 allows a maximum of %{max} owners in a team."
      end

      def public_interpolated_values
        { max: MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS }
      end
    end

    attr_reader :group

    delegate :course, to: :group

    def initialize(group)
      @group = group
    end

    def max_retries
      3
    end

    def max_delay
      6.hours
    end

    def after_failure
      # We can clean up here e.g. (MicrosoftSync::GroupMember.delete_all)
      # when we have retry in getting owners & executing diff
    end

    def after_complete
      group.update!(last_synced_at: Time.zone.now)
    end

    def retry_object_for_error(e, **extra_args)
      delay_amount = e.retry_after_seconds if e.is_a?(Errors::Throttled)
      delay_amount ||= STANDARD_RETRY_DELAY
      StateMachineJob::Retry.new(error: e, delay_amount:, **extra_args)
    end

    def step_initial(job_type, _job_state_data)
      StateMachineJob::NextStep.new(
        (job_type.to_s == "partial") ? :step_partial_sync : :step_full_sync_prerequisites
      )
    end

    # Checks if there are too many enrollments to sync, and if, so aborts.
    # Also deletes PartialSyncChanges that are unnecessary now that we will
    # be processing all enrollments. (Deletes only records that have been
    # replicated to the secondary. We read Enrollments from the secondary so we
    # don't want to delete PartialSyncChanges corresponding to enrollments not
    # yet replicated.)
    def step_full_sync_prerequisites(_mem_data, _job_state_data)
      if CanvasModelsHelpers.max_enrollment_members_reached?(course)
        raise_and_disable_group(MaxMemberEnrollmentsReached)
      elsif CanvasModelsHelpers.max_enrollment_owners_reached?(course)
        raise_and_disable_group(MaxOwnerEnrollmentsReached)
      end

      PartialSyncChange.delete_all_replicated_to_secondary_for_course(course.id)

      StateMachineJob::NextStep.new(:step_ensure_class_group_exists)
    end

    # Second step of a full sync. Create group on the Microsoft side.
    def step_ensure_class_group_exists(_mem_data, _job_state_data)
      remote_ids = graph_service_helpers.list_education_classes_for_course(course).pluck("id")

      # If we've created the group previously, we're good to go
      if group.ms_group_id && remote_ids == [group.ms_group_id]
        debug_info_tracker.restart!(group.ms_group_id, new_group: false)

        return StateMachineJob::NextStep.new(:step_ensure_enrollments_user_mappings_filled)
      end

      raise MultipleEducationClasses if remote_ids.length > 1

      # Create a group if needed. If there is already a group but we do not
      # have it in the Group record, use it but first update it with course
      # data in case it was never done.
      new_group_id = remote_ids.first

      new_group_id ||= graph_service_helpers.create_education_class(course)["id"]

      debug_info_tracker.restart!(group.ms_group_id, new_group: true)

      StateMachineJob::DelayedNextStep.new(
        :step_update_group_with_course_data, DELAY_BEFORE_UPDATE_GROUP, new_group_id
      )
    rescue *Errors::INTERMITTENT => e
      retry_object_for_error(e)
    end

    def step_update_group_with_course_data(_mem_state, group_id)
      graph_service_helpers.update_group_with_course_data(group_id, course)
      group.update! ms_group_id: group_id
      StateMachineJob::NextStep.new(:step_ensure_enrollments_user_mappings_filled)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      retry_object_for_error(e, job_state_data: group_id)
    end

    # Gets users enrolled in course, get ULUVs (user lookup values, e.g.
    # addresses, username) for them, looks up the AADs (Azure Active Directory
    # object IDs -- Microsoft's internal ID for the user) from Microsoft, and
    # writes the User->AAD mapping into the UserMapping table.  If a user
    # doesn't have whatever we use to bulid the ULUV (e.g. email or SIS id, as
    # specified by the microsoft_sync_login_attribute Account setting), or
    # Microsoft doesn't have a user for the calculated ULUV, skips that user.
    def step_ensure_enrollments_user_mappings_filled(_mem_data, _job_state_data)
      MicrosoftSync::UserMapping.find_enrolled_user_ids_without_mappings(
        course:, batch_size: ENROLLMENTS_ULUV_FETCHING_BATCH_SIZE
      ) do |user_ids|
        ensure_user_mappings(user_ids)
      end

      StateMachineJob::NextStep.new(:step_generate_diff)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      retry_object_for_error(e)
    end

    def ensure_user_mappings(user_ids)
      users_uluvs_finder = MicrosoftSync::UsersUluvsFinder.new(user_ids, group.root_account)
      users_and_uluvs = users_uluvs_finder.call
      remote_attr = account_settings[:microsoft_sync_remote_attribute]

      user_ids_with_aads = []

      # If some users in different slices have the same ULUVs, this could end up
      # looking up the same ULUV multiple times; but this should be very rare
      users_and_uluvs.each_slice(GraphServiceHelpers::USERS_ULUVS_TO_AADS_BATCH_SIZE) do |slice|
        uluv_to_aad = graph_service_helpers.users_uluvs_to_aads(remote_attr, slice.map(&:last))
        user_id_to_aad = slice.to_h.transform_values { |uluv| uluv_to_aad[uluv] }.compact
        # NOTE: root_account here must be the same (values loaded into memory at the same time)
        # as passed into UsersUluvsFinder AND as used in #tenant, for the "have settings changed?"
        # check to work. For example, using course.root_account here would NOT be correct.
        UserMapping.bulk_insert_for_root_account(group.root_account, user_id_to_aad)
        user_ids_with_aads.concat(user_id_to_aad.keys)
      end

      # Make sure users who deleted whose email address no longer maps to a Microsoft user
      # get their mappings cleared out:
      UserMapping.delete_if_needs_updating(group.root_account_id, user_ids - user_ids_with_aads)

      debug_info_tracker.record_filtered_users(
        irrelevant_enrollments_scope: course.enrollments.microsoft_sync_irrelevant_but_not_fake,
        users_without_uluvs: user_ids - users_and_uluvs.map(&:first),
        users_without_aads: users_and_uluvs.map(&:first) - user_ids_with_aads
      )
    end

    # Get group members/owners from the API and local enrollments and calculate
    # what needs to be done.
    def step_generate_diff(_mem_data, _job_state_data)
      members = graph_service_helpers.get_group_users_aad_ids(group.ms_group_id)
      owners = graph_service_helpers.get_group_users_aad_ids(group.ms_group_id, owners: true)

      diff = MembershipDiff.new(members, owners)

      UserMapping.enrollments_and_aads(course).find_each do |enrollment|
        diff.set_local_member(enrollment.aad_id, enrollment.type)
      end

      StateMachineJob::NextStep.new(:step_execute_diff, diff)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      retry_object_for_error(e)
    end

    def log_batch_skipped(type, change_result)
      return if change_result.blank?

      n_total = change_result.total_unsuccessful
      Rails.logger.warn("#{self.class.name} (#{group.global_id}): " \
                        "Skipping #{type} for #{n_total}: #{change_result.to_json}")
      InstStatsd::Statsd.increment("#{STATSD_NAME_SKIPPED_BATCHES}.#{type}",
                                   tags: { sync_type: })
      InstStatsd::Statsd.count("#{STATSD_NAME_SKIPPED_TOTAL}.#{type}",
                               n_total,
                               tags: { sync_type: })
    end

    # Run the API calls to add/remove users.
    def step_execute_diff(diff, _job_state_data)
      # TODO: If there are no instructor enrollments, we actually want to
      # remove the group on the Microsoft side (INTEROP-6672)
      raise Errors::MissingOwners if diff.local_owners.empty?

      raise_and_disable_group(MaxMemberEnrollmentsReached) if diff.max_enrollment_members_reached?
      raise_and_disable_group(MaxOwnerEnrollmentsReached) if diff.max_enrollment_owners_reached?

      execute_diff(diff)
      debug_info_tracker.record_diff_stats(diff)

      StateMachineJob::NextStep.new(:step_check_team_exists)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      retry_object_for_error(e, step: :step_generate_diff)
    end

    def raise_and_disable_group(error_class)
      err = error_class.new
      # Need to manually update last_error; StateMachineJob won't do it since the group
      # will be in a 'deleted' state
      group.update last_error: MicrosoftSync::Errors.serialize(err)
      group.destroy
      raise err
    end

    # Execute a MembershipDiff or PartialMembershipDiff -- add and remove
    # users in batches
    def execute_diff(diff)
      execute_diff_remove_users(diff)
      execute_diff_add_users(diff)
    rescue Errors::MissingOwners
      # If the group is close to the max number of users, we might need to
      # remove users first to make room for new users.
      # e.g.: group has 25000 users, course has 100 removed but 1 added. Need
      # to remove at least 1 user before we can add 1.
      #
      # However, Microsoft will not let you remove the last owner in a group.
      # So if a course has 1 owner and it is swapped out for a different owner,
      # we should add the new one first. This is a rare scenario and because
      # the Microsoft API is eventually consistent, we'd have to wait a bit to
      # remove the old owner. So just add the new owners, raise the error and
      # have them manually re-sync.
      execute_diff_add_users(diff)
      raise
    end

    def delete_mappings_if_users_missing(change_result)
      bad_aads = change_result&.nonexistent_user_ids
      if bad_aads.present?
        Rails.logger.warn "Deleting mappings for AADs: #{bad_aads}"
        InstStatsd::Statsd.count(STATSD_NAME_DELETED_MAPPINGS_FOR_MISSING_USERS, bad_aads.count)
        UserMapping.where(root_account_id: course.root_account_id, aad_id: bad_aads).delete_all
      end
    end

    def execute_diff_add_users(diff)
      diff.additions_in_slices_of(GraphService::GroupsEndpoints::USERS_BATCH_SIZE) do |members_and_owners|
        change_result = graph_service.groups.add_users_ignore_duplicates(
          group.ms_group_id, **members_and_owners
        )
        log_batch_skipped(:add, change_result)
        delete_mappings_if_users_missing(change_result)
      end
    rescue Errors::MembersQuotaExceeded
      raise_and_disable_group(MaxMemberEnrollmentsReached)
    rescue Errors::OwnersQuotaExceeded
      raise_and_disable_group(MaxOwnerEnrollmentsReached)
    end

    def execute_diff_remove_users(diff)
      diff.removals_in_slices_of(GraphService::GroupsEndpoints::USERS_BATCH_SIZE) do |members_and_owners|
        change_result = graph_service.groups.remove_users_ignore_missing(
          group.ms_group_id, **members_and_owners
        )
        log_batch_skipped(:remove, change_result)
      end
    end

    def step_check_team_exists(_mem_data, _job_state_data)
      if course.enrollments.where(type: MembershipDiff::OWNER_ENROLLMENT_TYPES).any? &&
         !graph_service.teams.team_exists?(group.ms_group_id)
        StateMachineJob::DelayedNextStep.new(:step_create_team, DELAY_BEFORE_CREATE_TEAM)
      else
        StateMachineJob::COMPLETE
      end
    rescue *Errors::INTERMITTENT => e
      retry_object_for_error(e)
    end

    def step_create_team(_mem_data, _job_state_data)
      graph_service.teams.create_for_education_class(group.ms_group_id)
      StateMachineJob::COMPLETE
    rescue MicrosoftSync::Errors::TeamAlreadyExists
      StateMachineJob::COMPLETE
    rescue MicrosoftSync::Errors::GroupHasNoOwners, *MicrosoftSync::Errors::NOT_FOUND => e
      # API is eventually consistent: We often have to wait a couple minutes
      # after creating the group and adding owners for the Teams API to see the
      # group and owners.
      # It's also possible for the course to have added owners (so the
      # enrollments are in the DB) since we last calculated the diff and added them
      # in the generate_diff step. This is rare, but we can also sleep in that
      # case. We'll eventually fail but the team will be created next time we sync.
      StateMachineJob::Retry.new(error: e, delay_amount: [30, 90, 270])
    rescue *Errors::INTERMITTENT => e
      retry_object_for_error(e)
    end

    # Returns array of arrays of [user_id, change_enrollment_type, updated_at]
    # [[234, 'member', timestamp1], [456, 'member', timestamp2], [456, 'owner', timestamp3]]
    def load_partial_sync_changes
      PartialSyncChange.where(course:).limit(MAX_PARTIAL_SYNC_CHANGES + 1)
                       .pluck(:user_id, :enrollment_type, :updated_at)
    end

    def step_partial_sync(_mem_state, _job_state)
      # Step 1. Check prerequisites
      # - Step 1a. If there is an error from a full sync, don't attempt a partial
      #   sync (it would overwrite the error message)
      last_error_metadata = MicrosoftSync::Errors.extra_metadata_from_serialized(group.last_error)
      if last_error_metadata[:step] && last_error_metadata[:step].to_s != "step_partial_sync"
        return StateMachineJob::IGNORE
      end

      # - Step 1b. Kick off a full sync if we haven't created a group yet, or if
      #   there are too many changes to effectively handle here.
      if group.ms_group_id.nil? ||
         (changes = load_partial_sync_changes).length > MAX_PARTIAL_SYNC_CHANGES
        InstStatsd::Statsd.increment("#{STATSD_NAME}.partial_into_full")
        return StateMachineJob::NextStep.new(:step_full_sync_prerequisites)
      end

      return StateMachineJob::COMPLETE if changes.empty?

      # Set sync_type before graph_service used (created) but after we may switch to full sync:
      self.sync_type = "partial"

      # Step 2. ensure users have aad object ids:
      # changes_by_user_id is a hash from user_id ->
      #   array of arrays of [user_id, change_enrollment_type, updated_at]:
      changes_by_user_id = changes.group_by(&:first)
      user_ids = changes_by_user_id.keys
      ensure_user_mappings(UserMapping.user_ids_without_mappings(user_ids, course.root_account_id))

      # Step 3. Generate PartialMembership diff by combining three mappings:
      #   user_id -> change type       from PartialSyncChanges
      #   user_id <-> aad id           from UserMappings (UserMapping.enrollments_aad_aads)
      #   user_id -> enrollment types  from Enrollments (UserMapping.enrollments_aad_aads)
      # We need to look at all Enrollments for each user, not just those of the change type
      # because the user could be removed as an owner but not as a member, etc.

      # e.g., { 123 => ['member', 'owner'], 1230000000000099 => ['owner']}
      users_to_msft_role_types = changes_by_user_id.transform_values { |chgs| chgs.map(&:second) }
      diff = PartialMembershipDiff.new(users_to_msft_role_types)

      mappings = UserMapping.where(root_account_id: course.root_account_id, user_id: user_ids)
                            .pluck(:user_id, :aad_id)
      mappings.each { |user_id, aad_id| diff.set_member_mapping(user_id, aad_id) }

      users_with_mappings = mappings.map(&:first)
      enrollments = Enrollment.microsoft_sync_relevant
                              .where(course:, user_id: users_with_mappings)
                              .pluck(:user_id, :type)
      enrollments.each { |user_id, enrollment_type| diff.set_local_member(user_id, enrollment_type) }

      # Step 4. Execute diff and delete changes. Match additionally on
      # updated_at to avoid deleting any changes that have updated since we
      # started (and will get executed on the next run)
      diff.log_all_actions
      execute_diff(diff)
      PartialSyncChange
        .where(course:)
        .with_values_in(%w[user_id enrollment_type updated_at], changes)
        .delete_all

      StateMachineJob::COMPLETE
    rescue Errors::Throttled => e
      # If throttled, it's likely due to adds/removes. the fact we didn't
      # delete changes will mean retrying will cause us to fail more and probably
      # get throttled more. It will save quota to do a full sync, even if it means
      # incurring more read quota from getting the list of users in a group
      # (generally, cheaper).
      full_sync_after = e.retry_after_seconds || STANDARD_RETRY_DELAY
      Rails.logger.info "MicrosoftSync::SyncerSteps: partial sync throttled, " \
                        "full sync in #{full_sync_after}"
      InstStatsd::Statsd.increment("#{STATSD_NAME}.partial_into_full_throttled")
      StateMachineJob::DelayedNextStep.new(:step_full_sync_prerequisites, full_sync_after)
    rescue Errors::GroupNotFound
      # If the MS group doesn't exist, it's possible (though unlikely) the API
      # just hasn't settled. But more likely it's because someone else has
      # deleted the MS group, which is an expected (graceful cancel) error. So
      # retry but treat as an expected the error the last time.
      retry_object_for_error(Errors::GroupNotFoundGracefulCancelError.new)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      retry_object_for_error(e)
    end

    # Only serialize Group (AR model, so really just Group id) when enqueueing
    # a job. The rest of the instance variables should be reloaded when the job
    # starts again.
    def encode_with(coder)
      coder["group"] = @group
    end

    private

    attr_writer :sync_type

    def sync_type
      @sync_type || "full"
    end

    def tenant
      @tenant ||=
        begin
          enabled = account_settings[:microsoft_sync_enabled]
          tenant = account_settings[:microsoft_sync_tenant]
          raise TenantMissingOrSyncDisabled unless enabled && tenant

          tenant
        end
    end

    def account_settings
      @account_settings ||= group.root_account.settings
    end

    def graph_service_helpers
      @graph_service_helpers ||= tenant && GraphServiceHelpers.new(tenant, sync_type:)
    end

    def graph_service
      @graph_service ||= graph_service_helpers.graph_service
    end

    def debug_info_tracker
      @debug_info_tracker ||= DebugInfoTracker.new(group)
    end
  end
end
