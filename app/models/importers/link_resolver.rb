module Importers
  class LinkResolver
    include LinkParser::Helpers

    def initialize(migration)
      @migration = migration
    end

    def resolve_links!(link_map)
      link_map.each do |item_key, field_links|
        field_links.each do |_field, links|
          links.each do |link|
            resolve_link!(link)
          end
        end
      end
    end

    # finds the :new_value to use to replace the placeholder
    def resolve_link!(link)
      case link[:link_type]
      when :wiki_page
        if linked_wiki_url = context.wiki.wiki_pages.where(migration_id: link[:migration_id]).limit(1).pluck(:url).first
          link[:new_value] = "#{context_path}/pages/#{linked_wiki_url}"
        end
      when :discussion_topic
        if linked_topic_id = context.discussion_topics.where(migration_id: link[:migration_id]).limit(1).pluck(:id).first
          link[:new_value] = "#{context_path}/discussion_topics/#{linked_topic_id}"
        end
      when :module_item
        if tag_id = context.context_module_tags.where(:migration_id => link[:migration_id]).limit(1).pluck(:id).first
          link[:new_value] = "#{context_path}/modules/items/#{tag_id}"
        end
      when :object
        type = link[:type]
        migration_id = link[:migration_id]

        type_for_url = type
        type = 'context_modules' if type == 'modules'
        type = 'pages' if type == 'wiki'
        if type == 'pages'
          link[:new_value] = "#{context_path}/pages/#{migration_id}"
        elsif type == 'attachments'
          if att_id = context.attachments.where(migration_id: migration_id).limit(1).pluck(:id).first
            link[:new_value] = "#{context_path}/files/#{att_id}/preview"
          end
        elsif context.respond_to?(type) && context.send(type).respond_to?(:scoped)
          scope = context.send(type).scoped
          if scope.table.engine.columns_hash['migration_id']
            if object_id = scope.where(migration_id: migration_id).limit(1).pluck(:id).first
              link[:new_value] = "#{context_path}/#{type_for_url}/#{object_id}"
            end
          end
        end
      when :media_object
        # because we actually might change the node itself
        # this part is a little trickier
        # tl;dr we've replaced the entire node with the placeholder
        # see LinkParser for details

        rel_path = link[:rel_path]
        node = Nokogiri::HTML::DocumentFragment.parse(link[:old_value]).children.first
        new_url = resolve_media_comment_data(node, rel_path)
        new_url ||= resolve_relative_file_url(rel_path)

        unless new_url
          new_url ||= missing_relative_file_url(rel_path)
          link[:missing_url] = new_url
        end
        node['href'] = new_url
        link[:new_value] = node.to_xml
      when :file
        rel_path = link[:rel_path]
        new_url = resolve_relative_file_url(rel_path)
        unless new_url
          new_url = missing_relative_file_url(rel_path)
          link[:missing_url] = new_url
        end
        link[:new_value] = new_url
      else
        raise "unrecognized link_type in unresolved link"
      end
    end

    def missing_relative_file_url(rel_path)
      # the rel_path should already be escaped
      File.join(URI::escape("#{context_path}/file_contents/#{Folder.root_folders(context).first.name}"), rel_path.gsub(" ", "%20"))
    end

    def find_file_in_context(rel_path)
      mig_id = nil
      # This is for backward-compatibility: canvas attachment filenames are escaped
      # with '+' for spaces and older exports have files with that instead of %20
      alt_rel_path = rel_path.gsub('+', ' ')
      if @migration.attachment_path_id_lookup
        mig_id ||= @migration.attachment_path_id_lookup[rel_path]
        mig_id ||= @migration.attachment_path_id_lookup[alt_rel_path]
      end
      if !mig_id && @migration.attachment_path_id_lookup_lower
        mig_id ||= @migration.attachment_path_id_lookup_lower[rel_path.downcase]
        mig_id ||= @migration.attachment_path_id_lookup_lower[alt_rel_path.downcase]
      end

      mig_id && context.attachments.where(migration_id: mig_id).first
    end

    def resolve_relative_file_url(rel_path)
      new_url = nil
      split = rel_path.split('?')
      qs = split.pop if split.length > 1
      rel_path = split.join('?')

      rel_path_parts = Pathname.new(rel_path).each_filename.to_a

      # e.g. start with "a/b/c.txt" then try "b/c.txt" then try "c.txt"
      while new_url.nil? && rel_path_parts.length > 0
        sub_path = File.join(rel_path_parts)
        if file = find_file_in_context(sub_path)
          new_url = "#{context_path}/files/#{file.id}"
          # support other params in the query string, that were exported from the
          # original path components and query string. see
          # CCHelper::file_query_string
          params = Rack::Utils.parse_nested_query(qs.presence || "")
          qs = []
          new_action = ""
          params.each do |k,v|
            case k
            when /canvas_qs_(.*)/
              qs << "#{Rack::Utils.escape($1)}=#{Rack::Utils.escape(v)}"
            when /canvas_(.*)/
              new_action += "/#{$1}"
            end
          end
          if new_action.present?
            new_url += new_action
          else
            new_url += "/preview"
          end
          new_url += "?#{qs.join("&")}" if qs.present?
        end
        rel_path_parts.shift
      end
      new_url
    end

    def resolve_media_comment_data(node, rel_path)
      if file = find_file_in_context(rel_path)
        if media_id = ((file.media_object && file.media_object.media_id) || file.media_entry_id)
          node['id'] = "media_comment_#{media_id}"
          return "/media_objects/#{media_id}"
        end
      end

      if node['id'] && node['id'] =~ /\Amedia_comment_(.+)\z/
        return "/media_objects/#{$1}"
      else
        node.delete('class')
        node.delete('id')
        node.delete('style')
        return nil
      end
    end
  end
end