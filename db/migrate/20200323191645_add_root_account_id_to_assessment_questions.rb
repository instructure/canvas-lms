# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify
# the terms of the GNU Affero General Public License as publishe
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but
# WARRANTY; without even the implied warranty of MERCHANTABILITY
# A PARTICULAR PURPOSE. See the GNU Affero General Public Licens
# details.
#
# You should have received a copy of the GNU Affero General Publ
# with this program. If not, see <http://www.gnu.org/licenses/>.

class AddRootAccountIdToAssessmentQuestions < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!
  include MigrationHelpers::AddColumnAndFk

  def up
    add_column_and_fk :assessment_questions, :root_account_id, :accounts, if_not_exists: true
  end

  def down
    remove_column :assessment_questions, :root_account_id
  end
end
