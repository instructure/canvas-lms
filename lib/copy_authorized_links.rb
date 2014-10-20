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

module CopyAuthorizedLinks
  module CopyAuthorizedLinksClassMethods
    attr_reader :copy_authorized_links_block
    attr_reader :copy_authorized_links_columns
 
    def copy_authorized_links(column_names, &block)
      @copy_authorized_links_block = block
      @copy_authorized_links_columns = Array(column_names)
      before_save :copy_authorized_links_to_context
    end
  end
 
  module CopyAuthorizedLinksInstanceMethods
    def repair_malformed_links(user)
      block = self.class.copy_authorized_links_block rescue nil
      columns = (self.class.copy_authorized_links_columns || []).compact
      @copy_authorized_links_override_user = user
      columns.each do |column|
        if column == :custom
        else
          html = self.read_attribute(column) rescue nil
          if html && !html.empty?
            context, inferred_user = self.instance_eval(&block) if block
            user = @copy_authorized_links_override_user || inferred_user
            re = Regexp.new("/#{context.class.to_s.pluralize.underscore}/#{context.id}/files/(\\d+)")
            ids = []
            html.scan(re) do |match|
              ids << match[0]
            end
            Attachment.where(id: ids.uniq).each do |file|
              html = html.gsub(Regexp.new("/#{context.class.to_s.pluralize.underscore}/#{context.id}/files/#{file.id}"), "/#{file.context_type.pluralize.underscore}/#{file.context_id}/files/#{file.id}")
            end
            self.write_attribute(column, html) if html && !html.empty?
          end
        end
      end
      self.save
    end
    
    def copy_authorized_links_to_context
      block = self.class.copy_authorized_links_block rescue nil
      columns = (self.class.copy_authorized_links_columns || []).compact
      columns.each do |column|
        if column == :custom
          if self.respond_to?(:copy_authorized_content_custom_column)
            self.copy_authorized_content_custom_column(context, user)
          end
        else
          html = self.read_attribute(column) rescue nil
          if html && !html.empty?
            context, inferred_user = self.instance_eval(&block) if block
            user = @copy_authorized_links_override_user || inferred_user
            html = Course.copy_authorized_content(html, context, user) if context && user
            self.write_attribute(column, html) if html && !html.empty?
          end
        end
      end
      true
    end
    
    def content_being_saved_by(user)
      @copy_authorized_links_override_user = user
    end
  end
 
  def self.included(klass)
    klass.send :include, CopyAuthorizedLinksInstanceMethods
    klass.extend CopyAuthorizedLinksClassMethods
  end
end
 