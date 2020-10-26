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

module DataFixup
  module ClearFeatureFlags
    def self.run_async(feature_flag)
      DataFixup::ClearFeatureFlags.send_later_if_production_enqueue_args(
        :run,
        {
          priority: Delayed::LOWER_PRIORITY,
          max_attempts: 1,
          n_strand: "DataFixup::ClearFeatureFlags:#{feature_flag}:#{Shard.current.database_server.id}"
        },
        feature_flag
      )
    end

    def self.run(feature_flag)
      FeatureFlag.where(feature: feature_flag).destroy_all
    end
  end
end
