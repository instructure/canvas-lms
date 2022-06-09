# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
module Auditors::ActiveRecord
  class FeatureFlagRecord < ActiveRecord::Base
    include Auditors::ActiveRecord::Attributes
    include CanvasPartman::Concerns::Partitioned
    self.partitioning_strategy = :by_date
    self.partitioning_interval = :months
    self.partitioning_field = "created_at"
    self.table_name = "auditor_feature_flag_records"

    belongs_to :user
    belongs_to :root_account,
               class_name: "Account",
               inverse_of: :auditor_feature_flag_records

    class << self
      include Auditors::ActiveRecord::Model

      def ar_attributes_from_event_stream(record)
        record.attributes.except("id").tap do |attrs_hash|
          attrs_hash["request_id"] ||= "MISSING"
          attrs_hash["uuid"] = record.id
          # could be nil in the rare case of an unprovisioned console user.
          # NULL is therefore the signal that there was no inferrable user at
          # the time of the feature flag flip.
          attrs_hash["user_id"] = Shard.relative_id_for(record.user_id, Shard.current, Shard.current)
          attrs_hash["feature_flag_id"] = Shard.relative_id_for(record.feature_flag_id, Shard.current, Shard.current)
          attrs_hash["context_id"] = Shard.relative_id_for(record.context_id, Shard.current, Shard.current)
          attrs_hash["root_account_id"] = Shard.relative_id_for(record.root_account_id, Shard.current, Shard.current)
        end
      end
    end
  end
end
