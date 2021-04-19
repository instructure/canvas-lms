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
# Code which syncs course enrollments to Microsoft groups/teams
# See also MicrosoftSync::Group model
#
# This ideally shouldn't contain much job plumbing, but focus on the business
# logic about what to do in each step of a sync. For job plumbing, see
# StateMachineJob. This should normally be used by creating a StateMachineJob
# with this as the steps_object; see MicrosoftSync::Group#syncer_job
#   group.syncer_job.run_later
#   group.syncer_job.run_synchronously # e.g. manually in a console
#
module MicrosoftSync
  class SyncerSteps
    # Database batch size for users without AAD ids. Should be an even multiple of
    # GraphServiceHelpers::USERS_UPNS_TO_AADS_BATCH_SIZE:
    ENROLLMENTS_UPN_FETCHING_BATCH_SIZE = 750
    STANDARD_RETRY_DELAY = {delay_amount: [5, 20, 100].freeze}.freeze

    attr_reader :group
    delegate :course, to: :group

    def initialize(group)
      @group = group
    end

    def initial_step
      :step_ensure_class_group_exists
    end

    def max_retries
      3
    end

    def restart_job_after_inactivity
      6.hours
    end

    def after_failure
      # We can clean up here e.g. (MicrosoftSync::GroupMember.delete_all)
      # when we have retry in getting owners & executing diff
    end

    def after_complete
      group.update!(last_synced_at: Time.zone.now)
    end

    # This is semi-expected (user disables sync on account-level when jobs are
    # running), so we raise this which will cleanup_after_failure but not
    # produce a failed job.
    class TenantMissingOrSyncDisabled < StandardError
      include StateMachineJob::GracefulCancelErrorMixin
    end

    # First step of a full sync. Create group on the Microsoft side.
    def step_ensure_class_group_exists(_mem_data, _job_state_data)
      # TODO: as we continue building the job we could possibly just use the
      # group.ms_group_id and if we get an error know we have to create it.
      # That will save us a API call. But we won't be able to detect if there
      # are multiple; and it makes handling the 404s soon after a creation trickier.
      remote_ids = graph_service_helpers.list_education_classes_for_course(course).map{|c| c['id']}

      # If we've created the group previously, we're good to go
      if group.ms_group_id && remote_ids == [group.ms_group_id]
        return StateMachineJob::NextStep.new(:step_ensure_enrollments_user_mappings_filled)
      end

      if remote_ids.length > 1
        raise MicrosoftSync::Errors::InvalidRemoteState, \
              "Multiple Microsoft education classes exist for the course."
      end

      # Create a group if needed. If there is already a group but we do not
      # have it in the Group record, use it but first update it with course
      # data in case it was never done.
      new_group_id = remote_ids.first

      unless new_group_id
        new_group_id = graph_service_helpers.create_education_class(course)['id']
      end

      StateMachineJob::DelayedNextStep.new(
        :step_update_group_with_course_data, 2.seconds, new_group_id
      )
    rescue *Errors::INTERMITTENT => e
      StateMachineJob::Retry.new(error: e, **STANDARD_RETRY_DELAY)
    end

    def step_update_group_with_course_data(_mem_state, group_id)
      graph_service_helpers.update_group_with_course_data(group_id, course)
      group.update! ms_group_id: group_id
      StateMachineJob::NextStep.new(:step_ensure_enrollments_user_mappings_filled)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      StateMachineJob::Retry.new(error: e, **STANDARD_RETRY_DELAY, job_state_data: group_id)
    end

    # Gets users enrolled in course, get UPNs ("userPrincipalName"s, e.g. email
    # addresses, username) for them, looks up the AADs (Azure Active Directory
    # object IDs -- Microsoft's internal ID for the user) from Microsoft, and
    # writes the User->AAD mapping into the UserMapping table.  If a user
    # doesn't have a UPN or Microsoft doesn't have an AAD for them, skips that
    # user.
    def step_ensure_enrollments_user_mappings_filled(_mem_data, _job_state_data)
      MicrosoftSync::UserMapping.find_enrolled_user_ids_without_mappings(
        course: course, batch_size: ENROLLMENTS_UPN_FETCHING_BATCH_SIZE
      ) do |user_ids|
        users_and_upns = CommunicationChannel.
          where(user_id: user_ids, path_type: 'email').pluck(:user_id, :path)

        users_and_upns.each_slice(GraphServiceHelpers::USERS_UPNS_TO_AADS_BATCH_SIZE) do |slice|
          upn_to_aad = graph_service_helpers.users_upns_to_aads(slice.map(&:last))
          user_id_to_aad = slice.map{|user_id, upn| [user_id, upn_to_aad[upn]]}.to_h.compact
          UserMapping.bulk_insert_for_root_account_id(course.root_account_id, user_id_to_aad)
        end
      end

      StateMachineJob::NextStep.new(:step_generate_diff)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      StateMachineJob::Retry.new(error: e, **STANDARD_RETRY_DELAY)
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
      StateMachineJob::Retry.new(error: e, **STANDARD_RETRY_DELAY)
    end

    # Run the API calls to add/remove users.
    def step_execute_diff(diff, _job_state_data)
      batch_size = GraphService::GROUP_USERS_ADD_BATCH_SIZE
      diff.additions_in_slices_of(batch_size) do |members_and_owners|
        graph_service.add_users_to_group(group.ms_group_id, members_and_owners)
      end

      # Microsoft will not let you remove the last owner in a group, so it's
      # slightly safer to remove owners last in case we need to completely
      # change owners. TODO: A class could still have all of its teacher
      # enrollments removed, need to remove the group when this happens
      # (INTEROP-6672)
      diff.members_to_remove.each do |aad|
        graph_service.remove_group_member(group.ms_group_id, aad)
      end

      diff.owners_to_remove.each do |aad|
        graph_service.remove_group_owner(group.ms_group_id, aad)
      end

      StateMachineJob::NextStep.new(:step_check_team_exists)
    rescue *Errors::INTERMITTENT_AND_NOTFOUND => e
      StateMachineJob::Retry.new(error: e, **STANDARD_RETRY_DELAY, step: :step_generate_diff)
    end

    def step_check_team_exists(_mem_data, _job_state_data)
      if course.enrollments.where(type: MembershipDiff::OWNER_ENROLLMENT_TYPES).any? \
        && !graph_service.team_exists?(group.ms_group_id)
        StateMachineJob::DelayedNextStep.new(:step_create_team, 10.seconds)
      else
        StateMachineJob::COMPLETE
      end
    rescue *Errors::INTERMITTENT => e
      StateMachineJob::Retry.new(error: e, **STANDARD_RETRY_DELAY)
    end

    def step_create_team(_mem_data, _job_state_data)
      graph_service.create_education_class_team(group.ms_group_id)
      StateMachineJob::COMPLETE
    rescue MicrosoftSync::Errors::TeamAlreadyExists
      StateMachineJob::COMPLETE
    rescue MicrosoftSync::Errors::GroupHasNoOwners, MicrosoftSync::Errors::HTTPNotFound => e
      # API is eventually consistent: We often have to wait a couple minutes
      # after creating the group and adding owners for the Teams API to see the
      # group and owners.
      # It's also possible for the course to have added owners (so the
      # enrollments are in the DB) since we last calculated the diff and added them
      # in the generate_diff step. This is rare, but we can also sleep in that
      # case. We'll eventually fail but the team will be created next time we sync.
      StateMachineJob::Retry.new(error: e, delay_amount: [30, 90, 270])
    rescue *Errors::INTERMITTENT => e
      StateMachineJob::Retry.new(error: e, **STANDARD_RETRY_DELAY)
    end

    def tenant
      @tenant ||=
        begin
          settings = group.root_account.settings
          enabled = settings[:microsoft_sync_enabled]
          tenant = settings[:microsoft_sync_tenant]
          raise TenantMissingOrSyncDisabled unless enabled && tenant

          tenant
        end
    end

    def graph_service_helpers
      @graph_service_helpers ||= tenant && GraphServiceHelpers.new(tenant)
    end

    def graph_service
      @graph_service ||= graph_service_helpers.graph_service
    end
  end
end
