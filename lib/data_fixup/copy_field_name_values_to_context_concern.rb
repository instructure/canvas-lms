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

module DataFixup::CopyFieldNameValuesToContextConcern
  def self.actual_run
    AttachmentAssociation
      .where(field_name: "syllabus_body")
      .in_batches(strategy: :pluck_ids)
      .update_all(context_concern: "syllabus_body")
  end

  def self.run
    delay_if_production(
      priority: Delayed::LOW_PRIORITY,
      n_strand: ["DataFixup::CopyFieldNameValuesToContextConcern", Shard.current.database_server.id]
    ).actual_run
  end
end
