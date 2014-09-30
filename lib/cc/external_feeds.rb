#
# Copyright (C) 2011 Instructure, Inc.
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
module CC
  module ExternalFeeds
    def create_external_feeds(document=nil)
      return nil unless @course.external_feeds.count > 0
      if document
        feed_file = nil
        rel_path = nil
      else
        feed_file = File.new(File.join(@canvas_resource_dir, CCHelper::EXTERNAL_FEEDS), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::EXTERNAL_FEEDS)
        document = Builder::XmlMarkup.new(:target=>feed_file, :indent=>2)
      end
      
      document.instruct!
      document.externalFeeds(
              "xmlns" => CCHelper::CANVAS_NAMESPACE,
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |feeds_node|
        @course.external_feeds.each do |feed|
          next unless export_object?(feed)
          migration_id = CCHelper.create_key(feed)
          feeds_node.externalFeed(:identifier=>migration_id) do |feed_node|
            feed_node.title feed.title if feed.title
            feed_node.url feed.url
            feed_node.feed_type feed.feed_type
            feed_node.purpose feed.feed_purpose
            feed_node.verbosity feed.verbosity
            feed_node.header_match feed.header_match unless feed.header_match.blank?
          end
        end
      end
      
      feed_file.close if feed_file
      rel_path
    end
  end
end