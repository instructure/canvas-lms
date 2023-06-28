# frozen_string_literal: true

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

require "active_support/core_ext/object"

module CanvasLinkMigrator
  class LinkResolver
    def initialize(migration_id_converter)
      @migration_id_converter = migration_id_converter
    end

    def resolve_links!(link_map)
      link_map.each_value do |field_links|
        field_links.each_value do |links|
          links.each do |link|
            resolve_link!(link)
          end
        end
      end
    end

    def context_path
      @migration_id_converter.context_path
    end

    # finds the :new_value to use to replace the placeholder
    def resolve_link!(link)
      case link[:link_type]
      when :wiki_page
        if (linked_wiki_url = @migration_id_converter.convert_wiki_page_migration_id_to_slug(link[:migration_id]))
          link[:new_value] = "#{context_path}/pages/#{linked_wiki_url}#{link[:query]}"
        end
      when :discussion_topic
        if (linked_topic_id = @migration_id_converter.convert_discussion_topic_migration_id(link[:migration_id]))
          link[:new_value] = "#{context_path}/discussion_topics/#{linked_topic_id}#{link[:query]}"
        end
      when :module_item
        if (tag_id = @migration_id_converter.convert_context_module_tag_migration_id(link[:migration_id]))
          link[:new_value] = "#{context_path}/modules/items/#{tag_id}#{link[:query]}"
        end
      when :object
        type = link[:type]
        migration_id = link[:migration_id]

        type_for_url = type
        type = "context_modules" if type == "modules"
        type = "pages" if type == "wiki"
        if type == "pages"
          query = resolve_module_item_query(nil, link[:query])
          link[:new_value] = "#{context_path}/pages/#{migration_id}#{query}"
        elsif type == "attachments"
          att_id = @migration_id_converter.convert_attachment_migration_id(migration_id)
          if att_id
            link[:new_value] = "#{context_path}/files/#{att_id}/preview"
          end
        elsif type == "media_attachments_iframe"
          att_id = @migration_id_converter.convert_attachment_migration_id(migration_id)
          link[:new_value] = att_id ? "/media_attachments_iframe/#{att_id}#{link[:query]}" : link[:old_value]
        else
          object_id = @migration_id_converter.convert_migration_id(type, migration_id)
          if object_id
            query = resolve_module_item_query(nil, link[:query])
            link[:new_value] = "#{context_path}/#{type_for_url}/#{object_id}#{query}"
          end
        end
      when :media_object
        # because we actually might change the node itself
        # this part is a little trickier
        # tl;dr we've replaced the entire node with the placeholder
        # see LinkParser for details
        rel_path = link[:rel_path]
        node = Nokogiri::HTML5.fragment(link[:old_value]).children.first
        new_url = resolve_media_comment_data(node, rel_path)
        new_url ||= resolve_relative_file_url(rel_path)

        unless new_url
          new_url ||= missing_relative_file_url(rel_path)
          link[:missing_url] = new_url
        end
        if ["iframe", "source"].include?(node.name)
          node["src"] = new_url
        else
          node["href"] = new_url
        end
        link[:new_value] = node.to_s
      when :file
        rel_path = link[:rel_path]
        new_url = resolve_relative_file_url(rel_path)
        unless new_url
          new_url = missing_relative_file_url(rel_path)
          link[:missing_url] = new_url
        end
        link[:new_value] = new_url
      when :file_ref
        file_id = @migration_id_converter.convert_attachment_migration_id(link[:migration_id])
        if file_id
          rest = link[:rest].presence || "/preview"

          # Icon Maker files should not have the course
          # context prepended to the URL. This prevents
          # redirects to non cross-origin friendly urls
          # during a file fetch
          if rest.include?("icon_maker_icon=1")
            link[:new_value] = "/files/#{file_id}#{rest}"
          else
            link[:new_value] = "#{context_path}/files/#{file_id}#{rest}"
            link[:new_value] = "/media_objects_iframe?mediahref=#{link[:new_value]}" if link[:in_media_iframe]
          end
        end
      else
        raise "unrecognized link_type (#{link[:link_type]}) in unresolved link"
      end
    end

    def resolve_module_item_query(_context, query)
      return query unless query&.include?("module_item_id=")

      original_param = query.sub("?", "").split("&").detect { |p| p.include?("module_item_id=") }
      mig_id = original_param.split("=").last
      tag_id = @migration_id_converter.convert_context_module_tag_migration_id(mig_id)
      return query unless tag_id

      new_param = "module_item_id=#{tag_id}"
      query.sub(original_param, new_param)
    end

    def missing_relative_file_url(rel_path)
      # the rel_path should already be escaped
      File.join(URI::DEFAULT_PARSER.escape("#{context_path}/file_contents/#{@migration_id_converter.root_folder_name}"), rel_path.gsub(" ", "%20"))
    end

    def find_file_in_context(rel_path)
      mig_id = nil
      # This is for backward-compatibility: canvas attachment filenames are escaped
      # with '+' for spaces and older exports have files with that instead of %20
      alt_rel_path = rel_path.tr("+", " ")
      if @migration_id_converter.attachment_path_id_lookup
        mig_id ||= @migration_id_converter.attachment_path_id_lookup[rel_path]
        mig_id ||= @migration_id_converter.attachment_path_id_lookup[alt_rel_path]
      end
      if !mig_id && @migration_id_converter.attachment_path_id_lookup_lower
        mig_id ||= @migration_id_converter.attachment_path_id_lookup_lower[rel_path.downcase]
        mig_id ||= @migration_id_converter.attachment_path_id_lookup_lower[alt_rel_path.downcase]
      end

      # This md5 comparison is here to handle faulty cartridges with the migration_id equivalent of an empty string
      mig_id && mig_id != "gd41d8cd98f00b204e9800998ecf8427e" && @migration_id_converter.lookup_attachment_by_migration_id(mig_id)
    end

    def resolve_relative_file_url(rel_path)
      split = rel_path.split("?")
      qs = split.pop if split.length > 1
      path = split.join("?")

      # since we can't be sure whether a ? is part of a filename or query string, try it both ways
      new_url = resolve_relative_file_url_with_qs(path, qs)
      new_url ||= resolve_relative_file_url_with_qs(rel_path, "") if qs.present?
      new_url
    end

    def resolve_relative_file_url_with_qs(rel_path, qs)
      new_url = nil
      rel_path_parts = Pathname.new(rel_path).each_filename.to_a

      # e.g. start with "a/b/c.txt" then try "b/c.txt" then try "c.txt"
      while new_url.nil? && !rel_path_parts.empty?
        sub_path = File.join(rel_path_parts)
        if (file = find_file_in_context(sub_path))
          new_url = "#{context_path}/files/#{file.id}"
          # support other params in the query string, that were exported from the
          # original path components and query string. see
          # CCHelper::file_query_string
          params = Rack::Utils.parse_nested_query(qs.presence || "")
          qs = []
          new_action = ""
          params.each do |k, v|
            case k
            when /canvas_qs_(.*)/
              qs << "#{Rack::Utils.escape($1)}=#{Rack::Utils.escape(v)}"
            when /canvas_(.*)/
              new_action += "/#{$1}"
            end
          end
          new_url += new_action.presence || "/preview"
          new_url += "?#{qs.join("&")}" if qs.present?
        end
        rel_path_parts.shift
      end
      new_url
    end

    def media_iframe_url(media_id, media_type = nil)
      url = "/media_objects_iframe/#{media_id}"
      url += "?type=#{media_type}" if media_type.present?
      url
    end

    def media_attachment_iframe_url(file_id, media_type = nil)
      url = "/media_attachments_iframe/#{file_id}"
      url += "?type=#{media_type}" if media_type.present?
      url
    end

    def resolve_media_comment_data(node, rel_path)
      if (file = find_file_in_context(rel_path[/^[^?]+/])) # strip query string for this search
        media_id = (file.media_object&.media_id || file.media_entry_id)
        if media_id && media_id != "maybe"
          if ["iframe", "source"].include?(node.name)
            node["data-media-id"] = media_id
            if node["data-is-media-attachment"]
              node.delete("data-is-media-attachment")
              return media_attachment_iframe_url(file.id, node["data-media-type"])
            else
              return media_iframe_url(media_id, node["data-media-type"])
            end
          else
            node["id"] = "media_comment_#{media_id}"
            return "/media_objects/#{media_id}"
          end
        end
      end

      if node["id"] && node["id"] =~ /\Amedia_comment_(.+)\z/
        "/media_objects/#{$1}"
      elsif node["data-media-id"].present?
        media_iframe_url(node["data-media-id"], node["data-media-type"])
      else
        node.delete("class")
        node.delete("id")
        node.delete("style")
        nil
      end
    end
  end
end
