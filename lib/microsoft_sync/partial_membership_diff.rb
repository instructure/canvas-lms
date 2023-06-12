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

# Encapsulates the logic of comparing the local course enrollments and
# PartialSyncChanges, and based on these calculating the requests necessary to
# update the group on the Microsoft side. Similar to MembershipDiff, but that
# is for a full sync (where we actually get the list of group users from
# Microsoft), whereas this only calculates changes for the users in
# user_id_to_msft_role_types which we get from PartialSyncChanges: that is, we
# only update group membership for users whose enrollments have recently
# changed.
#
# Note that, in certain situations (such as adding and removing a user in the
# same time period), because we don't know the state on the Microsoft side,
# this may indicate unnecessary changes (such as removing a user from a group
# it is not in); by executing the actions recommended by this class with
# graph_service.groups's remove_users_ignore_missing(), such actions turn into
# no-ops.
# For instance, here is an example where what seems like the "optimal" method
# could lead to us never adding an owner. You can check that the actions we
# actually implement below (MEMBER_MSFT_ROLE_TYPE_ACTIONS[%w[member owner]] and
# OWNER_MSFT_ROLE_TYPE_ACTIONS[%w[member]] are redundant but do not have the
# issue.
#
# 1. STUDENT enrollment added
# 2. Partial sync job starts. Gets the list of changes and starts looking up user
#    mappings and enrollments.
# 3. TEACHER enrollment added while Partial Sync job is running
# 4. In job: we have just 1 PartialSyncChange, of type "member", but current
#    enrollments are of member AND owner (Student and Teacher)
#    "Optimal" but wrong: we assume Teacher enrollment was there already so user
#    was already a member and not do anything.
# 5. After job finishes, but before next job starts, TeacherEnrollment is
#   removed.
# 6. Job starts with 1 PartialSyncChange of "owner", but current enrollments are
#    of type member (Student)
# 7. "Optimal" but wrong: We assume just owner was removed. We remove the users
#    as an owner but we assume member has not changed (it was there already) so
#    don't change it. We will never add the user as a member.

module MicrosoftSync
  class PartialMembershipDiff
    OWNER_MSFT_ROLE_TYPE = "owner"
    MEMBER_MSFT_ROLE_TYPE = "member"

    def initialize(user_id_to_msft_role_types)
      @user_infos = user_id_to_msft_role_types.to_h.transform_values { |ctypes| UserInfo.new(ctypes) }
    end

    def set_local_member(user_id, enrollment_type)
      @user_infos[user_id].set_local_member(enrollment_type)
    end

    def set_member_mapping(user_id, aad_id)
      @user_infos[user_id].aad_id = aad_id
    end

    def additions_in_slices_of(slice_size, &)
      MembershipDiff.in_slices_of(
        aads_with_action(:add_owner),
        aads_with_action(:add_member),
        slice_size,
        &
      )
    end

    def removals_in_slices_of(slice_size, &)
      MembershipDiff.in_slices_of(
        aads_with_action(:remove_owner),
        aads_with_action(:remove_member),
        slice_size,
        &
      )
    end

    def log_all_actions
      @user_infos.each do |user_id, user_info|
        Rails.logger.info "#{self.class.name}: User #{user_id} #{user_info.log_line}"
      end
    end

    private

    def aads_with_action(action)
      @user_infos.values.select { |info| info.actions.include?(action) }.filter_map(&:aad_id).uniq
    end

    class UserInfo
      # Changes based on current enrollments.

      # Some of these may suggest extra unnecessary actions to be safe, because
      # we can't be sure of the original state of the enrollments before
      # changes (and thus the current members of the group on the Microsoft
      # side). These have been careful determined to safely (always eventually
      # get the Microsoft group users matching enrollments) in case of various
      # enrollment changes (such as users being both members and owners) and
      # race conditions in the job:
      #
      # Actions for when there is a "member" PartialSyncChange:
      MEMBER_MSFT_ROLE_TYPE_ACTIONS = {
        [] => %i[remove_member],
        %w[member] => %i[add_member],
        %w[owner] => [],
        %w[member owner] => %i[add_member],
      }.transform_keys(&:freeze).transform_values(&:freeze).freeze

      # Used if there is an "owner" change or both a "member" and "owner" PartialSyncChange:
      OWNER_MSFT_ROLE_TYPE_ACTIONS = {
        [] => %i[remove_member remove_owner],
        %w[member] => %i[add_member remove_owner],
        %w[owner] => %i[add_member add_owner],
        %w[member owner] => %i[add_member add_owner],
      }.transform_keys(&:freeze).transform_values(&:freeze).freeze

      attr_accessor :aad_id

      def initialize(msft_role_types)
        @msft_role_types = msft_role_types
        @mapping =
          if msft_role_types.include?(OWNER_MSFT_ROLE_TYPE)
            OWNER_MSFT_ROLE_TYPE_ACTIONS
          else
            MEMBER_MSFT_ROLE_TYPE_ACTIONS
          end
        @enrollment_types = []
      end

      def set_local_member(enrollment_type)
        @actions = nil
        @enrollment_types << enrollment_type
      end

      def enrollment_msft_role_types
        @enrollment_types.map do |e_type|
          if MicrosoftSync::MembershipDiff::OWNER_ENROLLMENT_TYPES.include?(e_type)
            "owner"
          else
            "member"
          end
        end.uniq.sort
      end

      def actions
        @actions ||= @mapping[enrollment_msft_role_types]
      end

      def log_line
        "(#{aad_id}): change #{@msft_role_types.sort}, " \
          "enrolls #{@enrollment_types.sort} -> #{actions}"
      end
    end
  end
end
