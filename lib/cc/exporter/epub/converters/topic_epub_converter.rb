#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CC::Exporter::Epub::Converters
  module TopicEpubConverter
    include CC::Exporter

    def convert_topics
      topics = []
      announcements = []

      @manifest.css('resource[type=imsdt_xmlv1p1]').each do |res|
        cc_path = @package_root.item_path res.at_css('file')['href']

        canvas_id = get_node_att(res, 'dependency', 'identifierref')
        if canvas_id && (meta_res = @manifest.at_css(%{resource[identifier="#{canvas_id}"]}))
          canvas_path = @package_root.item_path meta_res.at_css('file')['href']
          meta_node = open_file_xml(canvas_path)
        else
          meta_node = nil
        end
        cc_doc = open_file_xml(cc_path)

        next unless include_item?(meta_node, "active")

        if get_node_val(meta_node, 'type') != "announcement"
          topics << convert_topic(cc_doc, meta_node)
        else
          announcements << convert_announcement(cc_doc, meta_node)
        end
      end

      [topics, announcements]
    end

    def convert_topic(cc_doc, meta_doc)
      topic = {}
      topic[:description] = get_node_val(cc_doc, 'text')
      topic[:title] = get_node_val(cc_doc, 'title')
      if meta_doc
        topic[:title] = get_node_val(meta_doc, 'title')
        topic[:discussion_type] = get_node_val(meta_doc, 'discussion_type')
        topic[:pinned] = get_bool_val(meta_doc, 'pinned')
        topic[:posted_at] = get_time_val(meta_doc, 'posted_at')
        topic[:lock_at] = get_time_val(meta_doc, 'lock_at')
        topic[:position] = get_int_val(meta_doc, 'position')
        topic[:identifier] = get_node_val(meta_doc, 'topic_id')
        topic[:href] = "topics.xhtml##{topic[:identifier]}"

        if asmnt_node = meta_doc.at_css('assignment')
          topic[:assignment] = assignment_data(asmnt_node)
        end
      end

      topic
    end

    def convert_announcement(cc_doc, meta_doc)
      announcement = {}
      announcement[:description] = get_node_val(cc_doc, 'text')
      announcement[:title] = get_node_val(cc_doc, 'title')
      if meta_doc
        announcement[:posted_at] = get_time_val(meta_doc, 'posted_at')
        announcement[:identifier] = get_node_val(meta_doc, 'topic_id')
        announcement[:href] = "announcements.xhtml##{announcement[:identifier]}"
      end

      announcement
    end
  end
end
