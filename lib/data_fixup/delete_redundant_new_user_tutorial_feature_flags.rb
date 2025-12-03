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

module DataFixup
  class DeleteRedundantNewUserTutorialFeatureFlags < CanvasOperations::DataFixup
    self.mode = :batch
    self.progress_tracking = false

    scope do
      FeatureFlag.where(context_type: "User", feature: "new_user_tutorial_on_off", state: "on")
    end

    def process_batch(batch)
      batch.delete_all
    end
  end
end
