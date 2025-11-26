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

describe VisibilitySqlHelper do
  describe ".assignment_override_non_collaborative_group_join_sql" do
    it "includes workflow_state = 'accepted' condition for group memberships" do
      sql = VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("AND gm.workflow_state = 'accepted'")
    end

    it "joins GroupMembership table" do
      sql = VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("INNER JOIN #{GroupMembership.quoted_table_name} gm")
    end

    it "joins with group_id and user_id" do
      sql = VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("ON gm.group_id = g.id")
      expect(sql).to include("AND gm.user_id = e.user_id")
    end

    it "only includes non-collaborative groups" do
      sql = VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("AND g.non_collaborative = TRUE")
    end
  end

  describe ".assignment_override_unassign_non_collaborative_group_join_sql" do
    it "includes workflow_state = 'accepted' condition for group memberships" do
      sql = VisibilitySqlHelper.assignment_override_unassign_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("AND gm.workflow_state = 'accepted'")
    end

    it "joins GroupMembership table" do
      sql = VisibilitySqlHelper.assignment_override_unassign_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("INNER JOIN #{GroupMembership.quoted_table_name} gm")
    end

    it "joins with group_id and user_id" do
      sql = VisibilitySqlHelper.assignment_override_unassign_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("ON gm.group_id = g.id")
      expect(sql).to include("AND gm.user_id = e.user_id")
    end

    it "only includes non-collaborative groups" do
      sql = VisibilitySqlHelper.assignment_override_unassign_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("AND g.non_collaborative = TRUE")
    end
  end

  context "SQL correctness validation" do
    it "generates valid SQL that filters by accepted workflow_state" do
      sql = VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "assignment_id")

      expect(sql).to include("INNER JOIN")
      expect(sql).to include(GroupMembership.quoted_table_name)
      expect(sql).to include(Group.quoted_table_name)
      expect(sql).to include(AssignmentOverride.quoted_table_name)
      expect(sql).to include("gm.workflow_state = 'accepted'")
      expect(sql).to include("g.non_collaborative = TRUE")
      expect(sql).to include("ao.set_type = 'Group'")

      expect(sql).not_to include("  ")
    end
  end
end
