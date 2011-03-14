
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
module Canvas::CC
  module TopicResources

    def add_topics
      @course.discussion_topics.active.each do |topic|
        migration_id = CCHelper.create_key(topic)
        
        # the CC Discussion Topic
        topic_file_name = "#{migration_id}.xml"
        topic_path = File.join(@export_dir, topic_file_name)
        topic_file = File.new(topic_path, 'w')
        topic_doc = Builder::XmlMarkup.new(:target=>topic_file, :indent=>2)
        topic_doc.instruct!
  
        topic_doc.topic("xmlns" => "http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1",
                        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                        "xsi:schemaLocation"=> "http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1  http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imsdt_v1p1.xsd"
        ) do |t|
          t.title topic.title
          html = CCHelper.html_content(topic.message || '', @course, @manifest.exporter.user)
          t.text(html, :texttype=>'text/html')
          if topic.attachment
            t.attachments do |atts|
              folder = topic.attachment.folder.full_name.gsub("course files", CCHelper::WEB_CONTENT_TOKEN)
                path = "#{folder}/#{topic.attachment.display_name}"
              atts.attachment(:href=>path)
            end
          end
        end
        topic_file.close
        
        # Save all the meta-data into a canvas-specific xml schema
        meta_migration_id = CCHelper.create_key(topic, "meta")
        meta_file_name = "#{meta_migration_id}.xml"
        meta_path = File.join(@export_dir, meta_file_name)
        meta_file = File.new(meta_path, 'w')
        meta_doc = Builder::XmlMarkup.new(:target=>meta_file, :indent=>2)
        meta_doc.instruct!
        meta_doc.topicMeta("identifier" => meta_migration_id,
                        "xmlns" => CCHelper::CANVAS_NAMESPACE,
                        "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
                        "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
        ) do |t|
          t.topic_id migration_id
          t.title topic.title
          t.posted_at ims_datetime(topic.posted_at) if topic.posted_at
          t.delayed_post_at ims_datetime(topic.delayed_post_at) if topic.delayed_post_at
          t.position topic.position
          t.external_feed_id CCHelper.create_key(topic.external_feed) if topic.external_feed
          if topic.is_announcement
            t.tag!('type', 'announcement')
          else
            t.tag!('type', 'topic')
          end
          if topic.assignment
            assignment_migration_id = CCHelper.create_key(topic.assignment)
            t.assignment(:identifier=>assignment_migration_id) do |a|
              AssignmentResources.create_assignment(a, topic.assignment)
            end
          end
        end
        meta_file.close
        
        @resources.resource(
                :identifier => migration_id,
                "type" => CCHelper::DISCUSSION_TOPIC
        ) do |res|
          res.file(:href=>topic_file_name)
          res.dependency(:identifierref=>meta_migration_id)
        end
        @resources.resource(
                :identifier => meta_migration_id,
                :type => CCHelper::LOR,
                :href => meta_file_name
        ) do |res|
          res.file(:href=>meta_file_name)
        end
      end
    end

  end
end
