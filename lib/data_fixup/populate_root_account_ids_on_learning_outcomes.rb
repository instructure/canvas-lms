# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdsOnLearningOutcomes
  # this method is called from PopulateRootAccountIdOnModels as an override
  # for :populate_root_account_ids
  def self.populate(min, max)
    LearningOutcome.find_ids_in_ranges(start_at: min, end_at: max) do |batch_min, batch_max|
      # special case:
      # Global LearningOutcomes do not have a context id.
      # They are linked into a customer's shard on request,
      # and linked to normal outcomes and group via ContentTags
      global_outcomes = LearningOutcome.where(id: batch_min..batch_max, context_id: nil)
      if Account.root_accounts.count == 1
        # this shard only has one root_account, which is the correct root account to use
        global_outcomes.update_all(root_account_ids: [Account.root_accounts.first.id])
      else
        # this shard has multiple root_accounts. to associate a global outcome with
        # its correct root account, use the ContentTag links.

        # get unique array of root_account_ids from associated ContentTags
        subquery = ContentTag.learning_outcome_links.
          where("content_id=learning_outcomes.id").
          select("array_agg(DISTINCT root_account_id)").
          to_sql

        # end up with a unique, sorted array of root_account_ids that already existed on the LearningOutcome
        # and that came from its associated ContentTags
        uniquify = "SELECT ARRAY(SELECT DISTINCT e FROM unnest(array_cat(root_account_ids, (#{subquery}))) AS a(e) ORDER BY e)"
        global_outcomes.update_all("root_account_ids=(#{uniquify})")
      end

      # normal case:
      # LearningOutcomes take root_account_ids from their context
      # account for nil or empty array root_account_ids
      normal_outcomes = LearningOutcome.where(id: batch_min..batch_max).where("root_account_ids IS NULL OR root_account_ids = ?", "{}")
      normal_outcomes.joins(:course).update_all("root_account_ids=ARRAY[courses.root_account_id]")
      normal_outcomes.joins(:account).update_all("root_account_ids=ARRAY[#{Account.resolved_root_account_id_sql}]")
    end
  end
end