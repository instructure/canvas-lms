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
  def self.convert(html, context)
    doc = Nokogiri::HTML(html || "")
    root_folder_name = nil
    attrs = ['rel', 'href', 'src', 'data', 'value']
    doc.search("*").each do |node|
      attrs.each do |attr|
        if node[attr]
          if node[attr] =~ /wiki_page_migration_id=([^'"]*)/
            # This would be from a BB9 migration.
            if wiki_migration_id = $1
              if linked_wiki = context.wiki.wiki_pages.find_by_migration_id(wiki_migration_id)
                node[attr] = URI::escape("/#{context.class.to_s.underscore.pluralize}/#{context.id}/wiki/#{linked_wiki.url}")
              end
            end
          elsif node[attr] =~ /discussion_topic_migration_id=([^'"]*)/
            if topic_migration_id = $1
              if linked_topic = context.discussion_topics.find_by_migration_id(topic_migration_id)
                node[attr] = URI::escape("/#{context.class.to_s.underscore.pluralize}/#{context.id}/discussion_topics/#{linked_topic.id}")
              end
            end
          elsif relative_url?(node[attr])
            root_folder_name ||= Folder.root_folders(context).first.name
            node[attr] = URI::escape("/#{context.class.to_s.underscore.pluralize}/#{context.id}/file_contents/#{root_folder_name}/#{node[attr]}")
          end
        end
      end
    end
    doc.at_css('body').inner_html rescue ""
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
