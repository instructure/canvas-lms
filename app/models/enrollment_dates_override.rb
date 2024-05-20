# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class EnrollmentDatesOverride < ActiveRecord::Base
  belongs_to :root_account, class_name: "Account"
  belongs_to :context, polymorphic: [:account]
  belongs_to :enrollment_term

  before_save :infer_root_account

  after_save :update_courses_and_states_if_necessary

  include StickySisFields
  are_sis_sticky :start_at, :end_at

  def infer_root_account
    return if root_account_id.present?

    self.root_account = context.root_account if context&.root_account?
    self.root_account_id ||= context&.resolved_root_account_id || context&.root_account_id
  end

  def update_courses_and_states_if_necessary
    if saved_changes?
      enrollment_term.update_courses_and_states_later(enrollment_type)
    end
  end
end
