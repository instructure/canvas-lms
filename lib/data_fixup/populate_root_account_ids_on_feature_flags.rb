# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup::PopulateRootAccountIdsOnFeatureFlags
  def self.run
    FeatureFlag.where(root_account_ids: [], context_type: "Account")
               .non_shadow
               .joins("INNER JOIN #{Account.quoted_table_name} ON feature_flags.context_id=accounts.id")
               .in_batches
               .update_all("root_account_ids=ARRAY[CASE WHEN accounts.root_account_id IS NULL OR accounts.root_account_id=0 THEN accounts.id ELSE accounts.root_account_id END]")

    FeatureFlag.where(root_account_ids: [], context_type: "Course")
               .non_shadow
               .joins("INNER JOIN #{Course.quoted_table_name} ON feature_flags.context_id=courses.id")
               .in_batches
               .update_all("root_account_ids=ARRAY[courses.root_account_id]")

    FeatureFlag.where(root_account_ids: [], context_type: "User")
               .non_shadow
               .joins("INNER JOIN #{User.quoted_table_name} ON feature_flags.context_id=users.id")
               .in_batches
               .update_all("root_account_ids=users.root_account_ids")

    # shadow records exist only for feature flags in root-account context only
    FeatureFlag.where(root_account_ids: [], context_type: "Account")
               .shard(Shard.current)
               .shadow
               .in_batches
               .update_all("root_account_ids=ARRAY[context_id]")
  end
end
