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
  class ReNormalizePseudonyms < CanvasOperations::DataFixup
    self.mode = :individual_record
    self.record_changes = true
    self.progress_tracking = Rails.env.production?
    self.run_on_default_shard = false

    scope { Pseudonym.all }

    def valid_shard? = true

    def process_record(pseudonym)
      normalized = NormalizePseudonyms.normalize(pseudonym.unique_id)
      return if pseudonym.unique_id_normalized == normalized

      pseudonym.unique_id_normalized = normalized
      pseudonym.save(validate: false)
      pseudonym.global_id
    end
  end
end
