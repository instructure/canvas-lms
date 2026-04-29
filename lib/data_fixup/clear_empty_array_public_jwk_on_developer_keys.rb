# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class DataFixup::ClearEmptyArrayPublicJwkOnDeveloperKeys < CanvasOperations::DataFixup
  self.mode = :batch
  self.progress_tracking = false
  self.record_changes = true

  scope do
    DeveloperKey.where("public_jwk = '[]'::jsonb")
  end

  def process_batch(batch)
    ids = batch.pluck(:id)
    batch.update_all(public_jwk: nil)
    ids.map { |id| Shard.global_id_for(id) }.join(",")
  rescue => e
    Canvas::Errors.capture(e,
                           {
                             tags: {
                               operation: self.class.operation_name,
                               shard_id: Shard.current.id
                             }
                           },
                           :error)
    log_message(
      "Error empty array public_jwks on shard #{Shard.current.id}, " \
      "batch IDs: #{batch.pluck(:id).join(",")}: #{e.message}",
      level: :error
    )
  end
end
