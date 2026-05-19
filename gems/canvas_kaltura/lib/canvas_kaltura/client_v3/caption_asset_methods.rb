# frozen_string_literal: true

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

module CanvasKaltura
  class ClientV3
    module CaptionAssetMethods
      # Returns all caption assets for a media entry.
      #
      # @param media_entry_id [String] The Kaltura media entry ID
      # @return [Array<Hash>] Array of hashes representing caption assets
      # @return [nil] If the request fails
      def caption_assets(media_entry_id)
        result = getRequest(:captionAsset,
                            :list,
                            ks: @ks,
                            "filter[entryIdEqual]": media_entry_id)
        return nil unless result

        result.css("item").map { node_to_hash(it) }
      end

      # Creates a new caption asset for a media entry.
      #
      # @param media_entry_id [String] The Kaltura media entry ID
      # @param language_code [String, nil] The language code (e.g., "en", "es").
      # @return [Hash] Hash representing the created caption asset
      # @return [nil] If the request fails
      def create_caption_asset(media_entry_id, language_code = nil)
        result = getRequest(:captionAsset,
                            :add,
                            ks: @ks,
                            entryId: media_entry_id,
                            **{ "captionAsset[languageCode]": language_code }.compact)
        return nil unless result

        node_to_hash(result)
      end

      # Gets a caption asset by ID.
      #
      # @param caption_id [String] The caption asset ID
      # @return [Hash] Hash representing the caption asset
      # @return [nil] If the request fails
      def caption_asset(caption_id)
        result = getRequest(:captionAsset,
                            :get,
                            ks: @ks,
                            captionAssetId: caption_id)
        return nil unless result

        node_to_hash(result)
      end

      # Gets the download URL for a caption asset.
      #
      # @param caption_id [String] The caption asset ID
      # @return [String] The URL to the caption file
      # @return [nil] If the request fails
      def caption_asset_url(caption_id)
        result = getRequest(:captionAsset,
                            :getUrl,
                            ks: @ks,
                            captionAssetId: caption_id)
        result&.content&.strip
      end

      # Gets the raw contents of a caption asset as an SRT subtitle file.
      #
      # @param caption_id [String] The caption asset ID
      # @return [String] The unescaped SRT content
      # @return [nil] If the request fails
      def caption_asset_contents(caption_id)
        result = getRequest(:captionAsset,
                            :serve,
                            ks: @ks,
                            captionAssetId: caption_id)

        result&.content&.strip&.then { CGI.unescapeHTML(it) }
      end
    end
  end
end
