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

class ImportedHtmlConverter
  include TextHelper
  def self.convert(html, context, remove_outer_nodes_if_one_child = false)
    doc = Nokogiri::HTML(html || "")
    attrs = ['rel', 'href', 'src', 'data', 'value']
    course_path = "/#{context.class.to_s.underscore.pluralize}/#{context.id}"
    doc.search("*").each do |node|
      attrs.each do |attr|
        if node[attr]
          if node[attr] =~ /wiki_page_migration_id=([^'"]*)/
            # This would be from a BB9 migration. 
            #todo: refactor migration systems to use new $CANVAS...$ flags
            #todo: FLAG UNFOUND REFERENCES TO re-attempt in second loop?
            if wiki_migration_id = $1
              if linked_wiki = context.wiki.wiki_pages.find_by_migration_id(wiki_migration_id)
                node[attr] = URI::escape("#{course_path}/wiki/#{linked_wiki.url}")
              end
            end
          elsif node[attr] =~ /discussion_topic_migration_id=([^'"]*)/
            if topic_migration_id = $1
              if linked_topic = context.discussion_topics.find_by_migration_id(topic_migration_id)
                node[attr] = URI::escape("#{course_path}/discussion_topics/#{linked_topic.id}")
              end
            end
          elsif node[attr] =~ %r{(?:\$CANVAS_OBJECT_REFERENCE\$|\$WIKI_REFERENCE\$)/([^/]*)/([^'"]*)}
            type = $1
            migration_id = $2
            if type == 'wiki'
              if page = context.wiki.wiki_pages.find_by_url(migration_id)
                node[attr] = URI::escape("#{course_path}/wiki/#{page.url}")
              end
            elsif context.respond_to?(type) && context.send(type).respond_to?(:find_by_migration_id)
              if object = context.send(type).find_by_migration_id(migration_id)
                node[attr] = URI::escape("#{course_path}/#{type}/#{object.id}")
              end
            end
          elsif node[attr] =~ %r{\$CANVAS_COURSE_REFERENCE\$/([^'"]*)}
            section = $1
            node[attr] = URI::escape("#{course_path}/#{section}")
          elsif node[attr] =~ %r{\$IMS_CC_FILEBASE\$/([^'"]*)}
            node[attr] = replace_relative_file_url($1, context, course_path)
          elsif relative_url?(node[attr])
            node[attr] = replace_relative_file_url(node[attr], context, course_path)
          end
        end
      end
    end
    node = doc.at_css('body')
    if remove_outer_nodes_if_one_child
      node = node.child while node.children.size == 1 && node.child.child
    end
    node.inner_html
  rescue
    ""
  end

  def self.replace_relative_file_url(rel_path, context, course_path)
    new_url = nil
    if context.respond_to?(:attachment_path_id_lookup) &&
        context.attachment_path_id_lookup &&
        context.attachment_path_id_lookup[rel_path]
      if file = context.attachments.find_by_migration_id(context.attachment_path_id_lookup[rel_path])
        new_url = "/courses/#{context.id}/files/#{file.id}/preview"
      end
    end
    unless new_url
      # the rel_path should already be escaped
      new_url = URI::escape("#{course_path}/file_contents/#{Folder.root_folders(context).first.name}/") + rel_path
    end
    new_url
  end
  
  def self.relative_url?(url)
    (url.match(/[\/#\?]/) || (url.match(/\./) && !url.match(/@/))) && !url.match(/\A\w+:/) && !url.match(/\A\//)
  end
  
  def self.convert_text(text, context, import_source=:webct)
    instance.format_message(text || "")[0]
  end
  
  def self.instance
    @@instance ||= self.new
  end
end
