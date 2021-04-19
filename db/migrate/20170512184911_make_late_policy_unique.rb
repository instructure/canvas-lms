# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class MakeLatePolicyUnique < ActiveRecord::Migration[4.2]
  # running fixup as a predeploy and add_index without concern of lockup
  # because we're certain the tables are small. Only one endpoint has been
  # exposed, in beta, and that endpoint is behind a feature flag. The only way a
  # duplicate LatePolicy can be created at this point is through a rails console
  tag :predeploy

  def change
    reversible do |dir|
      dir.up do
        DataFixup::MakeLatePolicyUnique.run
      end
    end

    remove_index :late_policies, column: :course_id
    add_index :late_policies, :course_id, unique: true
  end
end
