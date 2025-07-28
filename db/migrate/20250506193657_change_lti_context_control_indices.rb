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

class ChangeLtiContextControlIndices < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    remove_index(
      :lti_context_controls,
      [:course_id, :registration_id],
      name: "index_lti_context_controls_on_course_and_registration",
      if_exists: true
    )
    remove_index(:lti_context_controls,
                 [:account_id, :registration_id],
                 name: "index_lti_context_controls_on_account_and_registration",
                 if_exists: true)
    add_index(:lti_context_controls,
              [:account_id, :deployment_id],
              unique: true,
              name: "index_lti_context_controls_on_account_and_deployment",
              algorithm: :concurrently,
              where: "account_id IS NOT NULL",
              if_not_exists: true)
    add_index(:lti_context_controls,
              [:course_id, :deployment_id],
              unique: true,
              name: "index_lti_context_controls_on_course_and_deployment",
              algorithm: :concurrently,
              where: "course_id IS NOT NULL",
              if_not_exists: true)
  end
end
