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

##
# Loader for loading module progression data for observers.
# Returns progression data from the observed student (observers view one student at a time).
#
class Loaders::ObserverModuleProgressionLoader < GraphQL::Batch::Loader
  include ObserverEnrollmentsHelper

  def initialize(current_user:, session:, request: nil)
    super()
    @current_user = current_user
    @session = session
    @request = request
  end

  def perform(context_modules)
    if context_modules.empty? || @current_user.nil?
      # Fulfill all promises with nil when no user
      context_modules.each do |context_module|
        fulfill(context_module, nil)
      end
      return
    end

    course = context_modules.first.context
    observed_students = ObserverEnrollment.observed_students(course, @current_user, include_restricted_access: false).keys

    if observed_students.empty?
      # Fallback: return empty progression for all modules
      context_modules.each do |context_module|
        fulfill(context_module, nil)
      end
      return
    end

    # Get the currently selected observed student based on observer cookie preference
    selected_student = selected_observed_student_from_cookie(@current_user, observed_students, @request)

    # Load progressions for the selected observed student
    progressions = ContextModuleProgression.where(
      context_module_id: context_modules.map(&:id),
      user_id: selected_student.id
    ).index_by(&:context_module_id)

    context_modules.each do |context_module|
      progression = progressions[context_module.id]
      fulfill(context_module, progression)
    end
  end
end
