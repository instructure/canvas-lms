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
module CC::Importer
  module TopicConverter
    include CC::Importer
    
    def convert_topics
      topics = []
      
      @manifest.css('resource[type=imsdt_xmlv1p1]').each do |res|
        cc_path = File.join @unzipped_file_path, res.at_css('file')['href']
        canvas_id = res.at_css('dependency')['identifierref']
        canvas_path = File.join @unzipped_file_path, "#{canvas_id}.xml"
        cc_doc = open_file_xml(cc_path)
        meta_node = open_file_xml(canvas_path)
        
        topics << convert_topic(cc_doc, meta_node)
      end
      
      topics
    end
    
    def convert_topic(cc_doc, meta_doc)
      topic = {}
      topic['migration_id'] = get_node_val(meta_doc, 'topic_id')
      topic['title'] = get_node_val(meta_doc, 'title')
      topic['description'] = get_node_val(cc_doc, 'text')
      topic['type'] = get_node_val(meta_doc, 'type')
      topic['external_feed_migration_id'] = get_node_val(meta_doc, 'external_feed_identifierref')
      topic['attachment_migration_id'] = get_node_val(meta_doc, 'attachment_identifierref')
      topic['posted_at'] = get_time_val(meta_doc, 'posted_at')
      topic['delayed_post_at'] = get_time_val(meta_doc, 'delayed_post_at')
      topic['position'] = get_int_val(meta_doc, 'position')
      
      if asmnt_node = meta_doc.at_css('assignment')
        topic['assignment'] = convert_assignment(asmnt_node)
      end

      topic
    end
    
  end
end
