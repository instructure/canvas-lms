# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module DataFixup::BackfillAttachmentIdsOnMediaTracks
  def self.run(start_id, end_id)
    MediaTrack.connection.exec_update(update_sql(start_id, end_id))
  end

  def self.update_sql(start_id, end_id)
    <<~SQL.squish
      WITH ranked_tracks AS (
        SELECT
          id,
          media_object_id,
          ROW_NUMBER() OVER (PARTITION BY locale, media_object_id ORDER BY created_at DESC) AS rank
        FROM #{MediaTrack.quoted_table_name}
      )

      UPDATE #{MediaTrack.quoted_table_name} AS mt
      SET attachment_id = mo.attachment_id
      FROM #{MediaObject.quoted_table_name} mo
      INNER JOIN ranked_tracks rt
      ON mo.id = rt.media_object_id
      WHERE mt.attachment_id IS NULL
          AND mt.id BETWEEN #{start_id} AND #{end_id}
          AND mo.attachment_id IS NOT NULL
          AND mo.id = mt.media_object_id
          AND mt.id = rt.id
          AND rt.rank = 1
    SQL
  end
end
