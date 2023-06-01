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

require_relative "spec_components_assignable_module"

module SpecComponents
  class Discussion
    include Assignable
    include Factories

    def initialize(opts)
      course = opts[:course]
      discussion_title = opts.fetch(:title, "Test Discussion")
      due_at = opts.fetch(:due_at, Time.zone.now.advance(days: 7))

      @component_discussion = assignment_model(
        context: course,
        title: discussion_title,
        submission_types: "discussion_topic",
        due_at:
      )
      @id = @component_discussion.discussion_topic.id
      @title = @component_discussion.discussion_topic.title
    end

    def assign_to(opts)
      add_assignment_override(@component_discussion, opts)
    end

    def submit_as(user)
      @component_discussion.discussion_topic.discussion_entries.create!(
        message: "This is #{user.name}'s discussion entry",
        user:
      )
    end

    private

    def add_assignment_override_for_student(opts)
      super(opts) { |assignment_override| assignment_override.assignment = @component_discussion }
    end

    def add_assignment_override_for_section(opts)
      super(opts) { |assignment_override| assignment_override.assignment = @component_discussion }
    end
  end
end
