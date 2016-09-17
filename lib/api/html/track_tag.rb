#
# Copyright (C) 2016 Instructure, Inc.
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

require 'nokogiri'

module Api
  module Html
    class TrackTag
      include LocaleSelection

      def initialize(media_track, doc, node_builder=Nokogiri::XML::Node)
        @media_track = media_track
        @doc = doc
        @node_builder = node_builder
      end
      attr_reader :media_track, :doc, :node_builder

      def to_node(url_helper)
        node_builder.new('track', doc).tap do |n|
          n['kind'] = media_track.kind
          n['srclang'] = media_track.locale
          n['src'] = url_helper.proxy.show_media_tracks_url(
            media_track.media_object_id, media_track.id, format: :json
          )
          n['label'] = language_name
        end
      end

      private
      def language_name
        available_locales[media_track.locale] || media_track.locale
      end
    end
  end
end
