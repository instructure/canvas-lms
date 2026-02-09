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

module Services
  class NewQuizzes
    module Routes
      # Shared logic for launching New Quizzes in different contexts
      # Used by NewQuizzesController and SpeedGrader
      class LaunchHelper
        # Build launch data for New Quizzes
        # @param tool [ContextExternalTool] The external tool
        # @param assignment [Assignment] The assignment
        # @param context [Course] The course context
        # @param user [User] The current user
        # @param controller [ApplicationController] The controller instance
        # @param request [ActionDispatch::Request] The request object
        # @param basename [String] The base path for routing (e.g., "/courses/1/assignments/2")
        # @param content_tag [ContentTag] Optional content tag (module item or assignment tag)
        # @param launch_url [String] Optional launch URL override
        # @param current_pseudonym [Pseudonym] Optional current pseudonym
        # @param domain_root_account [Account] Optional domain root account
        # @return [Hash] Signed launch data
        def self.default_launch_data(
          tool:,
          assignment:,
          context:,
          user:,
          controller:,
          request:,
          basename:,
          content_tag: nil,
          launch_url: nil,
          current_pseudonym: nil,
          domain_root_account: nil
        )
          build_signed_launch_data(
            tool:,
            context:,
            user:,
            controller:,
            request:,
            assignment:,
            tag: assignment.external_tool_tag,
            placement: nil,
            content_tag:,
            launch_url:,
            current_pseudonym:,
            domain_root_account:,
            basename:
          )
        end

        # Build launch data for New Quizzes item banks
        # @param tool [ContextExternalTool] The external tool
        # @param context [Course, Account] The context (course or account)
        # @param user [User] The current user
        # @param controller [ApplicationController] The controller instance
        # @param request [ActionDispatch::Request] The request object
        # @param basename [String] The base path for routing (e.g., "/courses/1/external_tools/2")
        # @param placement [String] The LTI placement (e.g., "course_navigation")
        # @param current_pseudonym [Pseudonym] Optional current pseudonym
        # @param domain_root_account [Account] Optional domain root account
        # @return [Hash] Signed launch data with basename set
        def self.item_bank_launch_data(
          tool:,
          context:,
          user:,
          controller:,
          request:,
          basename:,
          placement:,
          current_pseudonym: nil,
          domain_root_account: nil
        )
          build_signed_launch_data(
            tool:,
            context:,
            user:,
            controller:,
            request:,
            assignment: nil,
            tag: nil,
            placement:,
            current_pseudonym:,
            domain_root_account:,
            basename:
          )
        end

        # Private helper to build signed launch data
        # Shared by both assignment and item bank launches
        def self.build_signed_launch_data(
          tool:,
          context:,
          user:,
          controller:,
          request:,
          assignment:,
          tag:,
          placement:,
          current_pseudonym:,
          domain_root_account:,
          basename:,
          content_tag: nil,
          launch_url: nil
        )
          domain_root_account ||= context.root_account

          variable_expander = Lti::VariableExpander.new(
            domain_root_account,
            context,
            controller,
            {
              current_user: user,
              current_pseudonym:,
              assignment:,
              tool:,
              content_tag:,
              launch_url:
            }.compact
          )

          signed_data = ::NewQuizzes::LaunchDataBuilder.new(
            context:,
            assignment:,
            tool:,
            tag:,
            current_user: user,
            controller:,
            request:,
            variable_expander:,
            placement:
          ).build_with_signature

          signed_data[:basename] = basename
          signed_data
        end
        private_class_method :build_signed_launch_data
      end
    end
  end
end
