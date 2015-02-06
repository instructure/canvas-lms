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

module Features
  module DifferentiatedAssignments
    class ModuleEvaluator < Struct.new(:course_id)
      def perform
        ContextModuleProgression.joins(:context_module).readonly(false).
          where(:context_modules => { :context_type => 'Course', :context_id => course_id}).
          find_each do |prog|
            prog.mark_as_outdated!
          end
      end
    end
  end
end

Feature.register('differentiated_assignments' =>
  {
    display_name: -> { I18n.t('features.differentiated_assignments', 'Differentiated Assignments') },
    description:  -> { I18n.t('differentiated_assignments_description', <<-END) },
Differentiated Assignments is a *beta* feature that enables choosing which section(s) an assignment applies to.
Sections that are not given an assignment will not see it in their course content and their final grade will be
calculated without those points.
END
    applies_to: 'Course',
    state: 'allowed',
    root_opt_in: true,
    beta: true,
    development: false,
    custom_transition_proc: ->(user, context, from_state, transitions) do
      if context.is_a?(Course) && from_state == 'on'
        transitions['off']['message'] = I18n.t('features.differentiated_assignments_course_disable_warning', <<END)
Disabling differentiated assignments will make all published assignments visible to all students.
END
      elsif context.is_a?(Account) && from_state != 'off'
        site_admin = Account.site_admin.grants_right?(user, :read)
        warning = I18n.t('features.differentiated_assignments_account_disable_warning', <<END)
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
      if context.is_a?(Course)
        Delayed::Job.enqueue(Features::DifferentiatedAssignments::ModuleEvaluator.new(context.id), max_attempts: 1)
      end
    end
  }
)
