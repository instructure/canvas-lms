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
# Job which syncs course enrollments to Microsoft groups/teams
# See also MicrosoftSync::Group model
#
module MicrosoftSync
  class Syncer
    attr_reader :group
    delegate :course, to: :group

    def initialize(group)
      @group = group
    end

    def sync!
      return unless tenant
      return unless group&.update_workflow_state_unless_deleted(:running) # quits now if deleted

      ensure_class_group_exists
      ensure_enrollments_user_mappings_filled

      group.update_workflow_state_unless_deleted(:completed, last_error: nil)
    rescue => e
      error_msg = MicrosoftSync::Errors.user_facing_message(e)
      group&.update_workflow_state_unless_deleted(:errored, last_error: error_msg)
      raise
    end

    def ensure_class_group_exists
      # TODO: as we continue building the job we could possibly just use the
      # group.ms_group_id and if we get an error know we have to create it.
      # That will save us a API call. But we won't be able to detect if there
      # are multiple
      remote_ids = canvas_graph_service.list_education_classes_for_course(course).map{|c| c['id']}

      # If we've created the group previously, we're good to go
      return if group.ms_group_id && remote_ids == [group.ms_group_id]

      if remote_ids.length > 1
        raise MicrosoftSync::Errors::InvalidRemoteState, \
              "Multiple Microsoft education classes exist for the course."
      end

      # Create a group if needed. If there is already a group but we do not
      # have it in the Group record, use it but first update it with course
      # data in case it was never done.
      new_group_id = remote_ids.first

      unless new_group_id
        new_group_id = canvas_graph_service.create_education_class(course)['id']
        # TODO: this sleep is temporary until we can 1) talk with Microsoft
        # about how their API is supposed to work and 2) decide amongst
        # ourselves if we should start a new delayed job instead of sleeping
        # (even a small amount) in the job
        sleep 2
      end

      canvas_graph_service.update_group_with_course_data(new_group_id, course)
      group.update! ms_group_id: new_group_id
    end

    ENROLLMENTS_UPN_FETCHING_BATCH_SIZE = 750

    # Gets users enrolled in course, get UPNs (e.g. email addresses) for them,
    # looks up the AADs from Microsoft, and writes the User->AAD mapping into
    # the UserMapping table.  If a user doesn't have a UPN or Microsoft doesn't
    # have an AAD for them, skips that user.
    def ensure_enrollments_user_mappings_filled
      MicrosoftSync::UserMapping.find_enrolled_user_ids_without_mappings(
        course: course, batch_size: ENROLLMENTS_UPN_FETCHING_BATCH_SIZE
      ) do |user_ids|
        users_and_upns = CommunicationChannel.
          where(user_id: user_ids, path_type: 'email').pluck(:user_id, :path)

        users_and_upns.each_slice(CanvasGraphService::USERS_UPNS_TO_AADS_BATCH_SIZE) do |slice|
          upn_to_aad = canvas_graph_service.users_upns_to_aads(slice.map(&:last))
          user_id_to_aad = slice.map{|user_id, upn| [user_id, upn_to_aad[upn]]}.to_h.compact
          UserMapping.bulk_insert_for_root_account_id(course.root_account_id, user_id_to_aad)
        end
      end
    end

    def tenant
      @tenant ||= group.root_account.settings[:microsoft_sync_tenant]
    end

    def canvas_graph_service
      @canvas_graph_service ||= tenant && CanvasGraphService.new(tenant)
    end
  end
end
