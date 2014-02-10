#
# Copyright (C) 2014 Instructure, Inc.
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


module DraftState
  class Publisher < Struct.new(:course_id)
    def perform
      course = Course.find(course_id)
      course.quizzes.where(workflow_state: 'unpublished').update_all(workflow_state: 'edited')
      course.assignments.where(workflow_state: 'unpublished').update_all(workflow_state: 'published')
      course.context_modules.where(workflow_state: 'unpublished').update_all(workflow_state: 'active')
      course.context_module_tags.where(workflow_state: 'unpublished').update_all(workflow_state: 'active')
      course.discussion_topics.where(workflow_state: 'unpublished').update_all(workflow_state: 'active')
    end
  end
end

Feature.register('draft_state' => {
    display_name: lambda { I18n.t('features.draft_state', 'Draft State') },
    description: lambda { I18n.t('draft_state_description', <<END) },
Draft state is a *beta* feature that allows course content to be published and unpublished.
Unpublished content won't be visible to students and won't affect grades.
It also includes a redesign of some course areas to make them more consistent in look and functionality.

Unpublished content may not be available if Draft State is disabled.
END
    applies_to: 'Course',
    state: 'hidden',
    root_opt_in: true,
    development: true,

    custom_transition_proc: ->(user, context, from_state, transitions) do
      if context.is_a?(Course) && from_state == 'on'
        transitions['off']['message'] = I18n.t('features.draft_state_course_disable_warning', <<END)
Turning this feature off will publish ALL existing objects in the course. Please make sure all draft content
is ready to be published and available to all users in the course before continuing.
END
      elsif context.is_a?(Account) && from_state != 'off'
        site_admin = Account.site_admin.grants_right?(user, :read)
        warning = I18n.t('features.draft_state_account_disable_warning', <<END)
Turning this feature off will impact existing courses. For assistance in disabling this feature, please contact
your Canvas Success Manager.
END
        %w(allowed off).each do |target_state|
          if transitions.has_key?(target_state)
            transitions[target_state]['message'] = warning
            transitions[target_state]['locked'] = true unless site_admin
          end
        end
      end
    end,

    after_state_change_proc: ->(context, old_state, new_state) do
      if context.is_a?(Course) && old_state == 'on' && new_state == 'off'
        Delayed::Job.enqueue(DraftState::Publisher.new(context.id), max_attempts: 1)
      end
    end
  }
)
