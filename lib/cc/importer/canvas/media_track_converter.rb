#
# Copyright (C) 2014 Instructure, Inc.
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
module CC::Importer::Canvas
  module MediaTrackConverter
    include CC::Importer

    def convert_media_tracks(doc)
      track_map = {}
      return track_map unless doc
      if media_tracks = doc.at_css('media_tracks')
        media_tracks.css('media').each do |media|
          file_migration_id = media['identifierref']
          tracks = []
          media.css('track').each do |track|
            track = { 'migration_id' => track['identifierref'],
                      'kind' => track['kind'],
                      'locale' => track['locale'] }
            tracks << track
          end
          track_map[file_migration_id] = tracks
        end
      end
      track_map
    end

  end
end
