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
module CC::Importer::Canvas
  module TopicConverter
    include CC::Importer

    def convert_topics_and_announcements
      topics = []
      announcements = []

      @manifest.css('resource[type=imsdt_xmlv1p1]').each do |res|
        cc_path = File.join @unzipped_file_path, res.at_css('file')['href']
        cc_id = res['identifier']
        canvas_id = get_node_att(res, 'dependency', 'identifierref')
        if canvas_id && meta_res = @manifest.at_css(%{resource[identifier="#{canvas_id}"]})
          canvas_path = File.join @unzipped_file_path, meta_res.at_css('file')['href']
          meta_node = open_file_xml(canvas_path)
        else
          meta_node = nil
        end
        cc_doc = open_file_xml(cc_path)

        topic = convert_topic(cc_doc, meta_node, canvas_id || cc_id)
        if topic['type'] == 'announcement'
          announcements << topic
        else
          topics << topic
        end
      end

      [topics, announcements]
    end

    def convert_topic(cc_doc, meta_doc, mig_id=nil)
      topic = {}
      topic['description'] = get_node_val(cc_doc, 'text')
      topic['title'] = get_node_val(cc_doc, 'title')
      topic['migration_id'] = mig_id
      if meta_doc
        topic['migration_id'] = get_node_val(meta_doc, 'topic_id')
        topic['title'] = get_node_val(meta_doc, 'title')
        topic['type'] = get_node_val(meta_doc, 'type')
        topic['discussion_type'] = get_node_val(meta_doc, 'discussion_type')
        topic['pinned'] = get_bool_val(meta_doc, 'pinned')
        topic['require_initial_post'] = get_bool_val(meta_doc, 'require_initial_post')
        topic['external_feed_migration_id'] = get_node_val(meta_doc, 'external_feed_identifierref')
        topic['attachment_migration_id'] = get_node_val(meta_doc, 'attachment_identifierref')
        topic['posted_at'] = get_time_val(meta_doc, 'posted_at')
        topic['delayed_post_at'] = get_time_val(meta_doc, 'delayed_post_at')
        topic['lock_at'] = get_time_val(meta_doc, 'lock_at')
        topic['position'] = get_int_val(meta_doc, 'position')
        wf_state = get_node_val(meta_doc, 'workflow_state')
        topic['workflow_state'] = wf_state if wf_state.present?
        topic['group_category'] = get_node_val(meta_doc, 'group_category')
        %w(has_group_category allow_rating only_graders_can_rate sort_by_rating).each do |setting|
          get_bool_val(meta_doc, setting).tap { |val| topic[setting] = val unless val.nil? }
        end
        if asmnt_node = meta_doc.at_css('assignment')
          topic['assignment'] = parse_canvas_assignment_data(asmnt_node)
        end
      end

      topic
    end

  end
end
