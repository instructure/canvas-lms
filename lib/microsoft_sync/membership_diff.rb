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
# members/owners of a Microsoft group and determining what needs to be
# added/removed.

module MicrosoftSync
  class MembershipDiff
    attr_reader :local_owners

    def initialize(remote_members, remote_owners)
      @remote_members = Set.new(remote_members)
      @remote_owners = Set.new(remote_owners)
      @local_members = Set.new
      @local_owners = Set.new
    end

    OWNER_ENROLLMENT_TYPES = %w[TeacherEnrollment TaEnrollment DesignerEnrollment].freeze

    def set_local_member(member, enrollment_type)
      if OWNER_ENROLLMENT_TYPES.include?(enrollment_type)
        @local_owners << member
      else
        @local_members << member
      end
    end

    def additions_in_slices_of(slice_size)
      # Admins/teachers need to be both owners and members in the remote group
      owners_to_add = (@local_owners - @remote_owners).to_a
      members_to_add = ((@local_members | @local_owners) - @remote_members).to_a

      owners_to_add.each_slice(slice_size) do |owners_slice|
        # If we have extra room, add some of the members, to possibly reduce
        # the number of API calls
        yield owners: owners_slice, members: members_to_add.shift(slice_size - owners_slice.length)
      end

      members_to_add.each_slice(slice_size) do |members_slice|
        yield(members: members_slice)
      end
    end

    def members_to_remove
      @remote_members - @local_members - @local_owners
    end

    def owners_to_remove
      @remote_owners - @local_owners
    end
  end
end

