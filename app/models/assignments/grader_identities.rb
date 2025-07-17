# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Assignments
  module GraderIdentities
    # This module provides grader identity functionality for assignments

    def self.anonymize_grader_identity(grader)
      {
        name: I18n.t("Grader %{position}", { position: grader[:position] }),
        anonymous_id: grader[:anonymous_id],
        position: grader[:position],
      }
    end

    def grader_identities
      return [] unless moderated_grading?

      self.class.build_grader_identities(ordered_moderation_graders_with_slot_taken)
    end

    def anonymous_grader_identities_by_user_id
      # Response looks like: { user_id => { id: anonymous_id, name: anonymous_name } }
      @anonymous_grader_identities_by_user_id ||= anonymous_grader_identities_by(index_by: :user_id)
    end

    def anonymous_grader_identities_by_anonymous_id
      # Response looks like: { anonymous_id => { id: anonymous_id, name: anonymous_name } }
      @anonymous_grader_identities_by_anonymous_id ||= anonymous_grader_identities_by(index_by: :anonymous_id)
    end

    def anonymous_grader_identities_by(index_by:)
      raise ArgumentError, "index_by must be either :user_id or :anonymous_id" unless [:user_id, :anonymous_id].include?(index_by)

      grader_identities.each_with_object({}) do |grader, identities|
        identity = Assignments::GraderIdentities.anonymize_grader_identity(grader)

        # limiting exposed attributes to match previous API behavior
        identity.delete(:position)
        identity[:id] = identity.delete(:anonymous_id)

        # Use the original grader hash to get the index value
        identities[grader[index_by]] = identity
      end
    end

    module ClassMethods
      def build_grader_identities(graders, anonymize: false)
        graders.map.with_index(1) do |moderation_grader, position|
          identity = {
            name: moderation_grader.user.name,
            user_id: moderation_grader.user_id,
            anonymous_id: moderation_grader.anonymous_id,
            position:
          }

          anonymize ? Assignments::GraderIdentities.anonymize_grader_identity(identity) : identity
        end
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
