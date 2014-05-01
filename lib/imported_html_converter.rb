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
  include HtmlTextHelper

  CONTAINER_TYPES = ['div', 'p', 'body']

  def self.convert(html, context, opts={})
    doc = Nokogiri::HTML(html || "")
    attrs = ['rel', 'href', 'src', 'data', 'value']
    course_path = "/#{context.class.to_s.underscore.pluralize}/#{context.id}"

    for_course_copy = false
    domain_substitution_map = {}
    if context.respond_to?(:content_migration) && context.content_migration
      for_course_copy = true if context.content_migration.for_course_copy?

      if ds_map = context.content_migration.migration_settings[:domain_substitution_map]
        ds_map.each{|k, v| domain_substitution_map[k.to_s] = v.to_s } # ensure strings
      end
    end

    doc.search("*").each do |node|
      attrs.each do |attr|
        if node[attr]
          if attr == 'value'
            next unless node['name'] && node['name'] == 'src'
          end

          new_url = nil
          missing_relative_url = nil
          val = URI.unescape(node[attr])

          if val =~ /wiki_page_migration_id=(.*)/
            # This would be from a BB9 migration. 
            #todo: refactor migration systems to use new $CANVAS...$ flags
            #todo: FLAG UNFOUND REFERENCES TO re-attempt in second loop?
            if wiki_migration_id = $1
              if linked_wiki = context.wiki.wiki_pages.find_by_migration_id(wiki_migration_id)
                new_url = "#{course_path}/wiki/#{linked_wiki.url}"
              end
            end
          elsif val =~ /discussion_topic_migration_id=(.*)/
            if topic_migration_id = $1
              if linked_topic = context.discussion_topics.find_by_migration_id(topic_migration_id)
                new_url = URI::escape("#{course_path}/discussion_topics/#{linked_topic.id}")
              end
            end
          elsif val =~ %r{\$CANVAS_COURSE_REFERENCE\$/modules/items/(.*)}
            if tag = context.context_module_tags.where(:migration_id => $1).select('id').first
              new_url = URI::escape "#{course_path}/modules/items/#{tag.id}"
            end
          elsif val =~ %r{(?:\$CANVAS_OBJECT_REFERENCE\$|\$WIKI_REFERENCE\$)/([^/]*)/(.*)}
            type = $1
            migration_id = $2
            type_for_url = type
            type = 'context_modules' if type == 'modules'
            type = 'pages' if type == 'wiki'
            if type == 'pages'
              new_url = "#{course_path}/#{context.feature_enabled?(:draft_state) ? 'pages' : 'wiki'}/#{migration_id}"
            elsif type == 'attachments'
              if att = context.attachments.find_by_migration_id(migration_id)
                new_url = URI::escape("#{course_path}/files/#{att.id}/preview")
              end
            elsif context.respond_to?(type) && context.send(type).respond_to?(:find_by_migration_id)
              if object = context.send(type).find_by_migration_id(migration_id)
                new_url = URI::escape("#{course_path}/#{type_for_url}/#{object.id}")
              end
            end
          elsif val =~ %r{\$CANVAS_COURSE_REFERENCE\$/(.*)}
            section = $1
            new_url = URI::escape("#{course_path}/#{section}")
          elsif val =~ %r{\$IMS_CC_FILEBASE\$/(.*)}
            rel_path = $1
            if attr == 'href' && node['class'] && node['class'] =~ /instructure_inline_media_comment/
              unless new_url = replace_media_comment_data(node, rel_path, context, opts)
                unless new_url = replace_relative_file_url(rel_path, context)
                  missing_relative_url = rel_path
                end
              end
            else
              unless new_url = replace_relative_file_url(rel_path, context)
                missing_relative_url = rel_path
              end
            end
          elsif attr == 'href' && node['class'] && node['class'] =~ /instructure_inline_media_comment/
            # Course copy media reference, leave it alone
            new_url = node[attr]
          elsif attr == 'src' && node['class'] && node['class'] =~ /equation_image/
            # Equation image, leave it alone
            new_url = node[attr]
          elsif val =~ %r{\A/assessment_questions/\d+/files/\d+}
            # The file is in the context of an AQ, leave the link alone
            new_url = node[attr]
          elsif val =~ %r{\A/courses/\d+/files/\d+}
            # This points to a specific file already, leave it alone
            new_url = node[attr]
          elsif for_course_copy
            # For course copies don't try to fix relative urls. Any url we can
            # correctly alter was changed during the 'export' step
            new_url = node[attr]
          elsif val.start_with?('#')
            # It's just a link to an anchor, leave it alone
            new_url = node[attr]
          else
            begin
              if relative_url?(node[attr])
                unless new_url = replace_relative_file_url(val, context)
                  missing_relative_url = val
                end
              else
                new_url = node[attr]
              end
            rescue URI::InvalidURIError
              Rails.logger.warn "attempting to translate invalid url: #{node[attr]}"
              # leave the url as it was
            end
          end

          if missing_relative_url
            node[attr] = replace_missing_relative_url(missing_relative_url, context, course_path)
          end

          if new_converted_url = check_domain_substitutions(new_url || val, domain_substitution_map)
            new_url = new_converted_url
          end

          if new_url
            node[attr] = new_url
          elsif opts[:missing_links]
            opts[:missing_links] << node[attr]
          end
        end
      end
    end

    node = doc.at_css('body')
    if opts[:remove_outer_nodes_if_one_child]
      while node.children.size == 1 && node.child.child
        break unless CONTAINER_TYPES.member? node.child.name
        node = node.child
      end
    end

    node.inner_html
  rescue
    ""
  end

  def self.check_domain_substitutions(url, sub_map)
    return nil if sub_map.empty?
    new_url = nil
    sub_map.each do |from_domain, to_domain|
      if url.start_with?(from_domain)
        new_url = url.sub(from_domain, to_domain)
      end
    end
    return new_url
  end

  def self.find_file_in_context(rel_path, context)
    mig_id = nil
    # This is for backward-compatibility: canvas attachment filenames are escaped
    # with '+' for spaces and older exports have files with that instead of %20
    alt_rel_path = rel_path.gsub('+', ' ')
    if context.respond_to?(:attachment_path_id_lookup) && context.attachment_path_id_lookup
      mig_id ||= context.attachment_path_id_lookup[rel_path]
      mig_id ||= context.attachment_path_id_lookup[alt_rel_path]
    end
    if !mig_id && context.respond_to?(:attachment_path_id_lookup_lower) && context.attachment_path_id_lookup_lower
      mig_id ||= context.attachment_path_id_lookup_lower[rel_path.downcase]
      mig_id ||= context.attachment_path_id_lookup_lower[alt_rel_path.downcase]
    end
    
    mig_id && context.attachments.find_by_migration_id(mig_id)
  end

  def self.replace_relative_file_url(rel_path, context)
    new_url = nil
    rel_path, qs = rel_path.split('?', 2)
    if file = find_file_in_context(rel_path, context)
      new_url = "/courses/#{context.id}/files/#{file.id}"
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
    new_url
  end

  def self.replace_missing_relative_url(rel_path, context, course_path)
    # the rel_path should already be escaped
    File.join(URI::escape("#{course_path}/file_contents/#{Folder.root_folders(context).first.name}"), rel_path)
  end

  def self.replace_media_comment_data(node, rel_path, context, opts={})
    if context.respond_to?(:attachment_path_id_lookup) &&
      context.attachment_path_id_lookup &&
        context.attachment_path_id_lookup[rel_path]
      file = context.attachments.find_by_migration_id(context.attachment_path_id_lookup[rel_path])
      if file && file.media_object
        media_id = file.media_object.media_id
        node['id'] = "media_comment_#{media_id}"
        return "/media_objects/#{media_id}"
      end
    end

    if node['id'] && node['id'] =~ /\Amedia_comment_(.+)\z/
      link = "/media_objects/#{$1}"
      opts[:missing_links] << link if opts[:missing_links]
      return link
    else
      node.delete('class')
      node.delete('id')
      node.delete('style')
      opts[:missing_links] << rel_path if opts[:missing_links]
      return nil
    end
  end
  
  def self.relative_url?(url)
    URI.parse(url).relative?
  end
  
  def self.convert_text(text, context, import_source=:webct)
    instance.format_message(text || "")[0]
  end
  
  def self.instance
    @@instance ||= self.new
  end
end
