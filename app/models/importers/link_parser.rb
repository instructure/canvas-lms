module Importers
  class LinkParser
    module Helpers
      def context
        @context ||= @migration.context
      end

      def context_path
        @context_path ||= "/#{context.class.to_s.underscore.pluralize}/#{context.id}"
      end

      def relative_url?(url)
        ImportedHtmlConverter.relative_url?(url)
      end
    end

    include Helpers

    REFERENCE_KEYWORDS = %w{CANVAS_COURSE_REFERENCE CANVAS_OBJECT_REFERENCE WIKI_REFERENCE IMS_CC_FILEBASE IMS-CC-FILEBASE}
    LINK_PLACEHOLDER = "LINK.PLACEHOLDER"

    attr_reader :unresolved_link_map

    def initialize(migration)
      @migration = migration
      reset!
    end

    def reset!
      @unresolved_link_map = {}
    end

    def add_unresolved_link(link, item_type, mig_id, field)
      key = {:type => item_type, :migration_id => mig_id}
      @unresolved_link_map[key] ||= {}
      @unresolved_link_map[key][field] ||= []
      @unresolved_link_map[key][field] << link
    end

    def placeholder(old_value)
      "#{LINK_PLACEHOLDER}_#{Digest::MD5.hexdigest(old_value)}"
    end

    def convert_link(node, attr, item_type, mig_id, field)
      return unless node[attr].present?

      if attr == 'value'
        return unless node['name'] && node['name'] == 'src'
      end

      url = node[attr].dup
      REFERENCE_KEYWORDS.each do |ref|
        url.gsub!("%24#{ref}%24", "$#{ref}$")
      end

      result = parse_url(url, node, attr)
      if result[:resolved]
        # resolved, just replace and carry on
        new_url = result[:new_url] || url
        if @migration && !relative_url?(new_url) && processed_url = @migration.process_domain_substitutions(new_url)
          new_url = processed_url
        end
        node[attr] = new_url
      else
        result.delete(:resolved)
        if result[:link_type] == :media_object
          # because we may actually change the media comment node itself
          # (rather than just replacing a value), we're going to
          # replace the entire node with a placeholder
          result[:old_value] = node.to_xml
          result[:placeholder] = placeholder(result[:old_value])
          placeholder_node = Nokogiri::HTML::DocumentFragment.parse(result[:placeholder])

          node.replace(placeholder_node)
        else
          result[:old_value] = node[attr]
          result[:placeholder] = placeholder(result[:old_value])
          node[attr] = result[:placeholder]
        end
        add_unresolved_link(result, item_type, mig_id, field)
      end
    end

    def unresolved(type, data={})
      {:resolved => false, :link_type => type}.merge(data)
    end

    def resolved(new_url=nil)
      {:resolved => true, :new_url => new_url}
    end

    # returns a hash with resolution status and data to hold onto if unresolved
    def parse_url(url, node, attr)
      if url =~ /wiki_page_migration_id=(.*)/
        unresolved(:wiki_page, :migration_id => $1)
      elsif url =~ /discussion_topic_migration_id=(.*)/
        unresolved(:discussion_topic, :migration_id => $1)
      elsif url =~ %r{\$CANVAS_COURSE_REFERENCE\$/modules/items/(.*)}
        unresolved(:module_item, :migration_id => $1)
      elsif url =~ %r{(?:\$CANVAS_OBJECT_REFERENCE\$|\$WIKI_REFERENCE\$)/([^/]*)/(.*)}
        unresolved(:object, :type => $1, :migration_id => $2)

      elsif url =~ %r{\$CANVAS_COURSE_REFERENCE\$/(.*)}
        resolved("#{context_path}/#{$1}")

      elsif url =~ %r{\$IMS(?:-|_)CC(?:-|_)FILEBASE\$/(.*)}
        rel_path = URI.unescape($1)
        if attr == 'href' && node['class'] && node['class'] =~ /instructure_inline_media_comment/
          unresolved(:media_object, :rel_path => rel_path)
        else
          unresolved(:file, :rel_path => rel_path)
        end
      elsif attr == 'href' && node['class'] && node['class'] =~ /instructure_inline_media_comment/
        # Course copy media reference, leave it alone
        resolved
      elsif attr == 'src' && node['class'] && node['class'] =~ /equation_image/
        # Equation image, leave it alone
        resolved
      elsif url =~ %r{\A/assessment_questions/\d+/files/\d+}
        # The file is in the context of an AQ, leave the link alone
        resolved
      elsif url =~ %r{\A/courses/\d+/files/\d+}
        # This points to a specific file already, leave it alone
        resolved
      elsif @migration && @migration.for_course_copy?
        # For course copies don't try to fix relative urls. Any url we can
        # correctly alter was changed during the 'export' step
        resolved
      elsif url.start_with?('#')
        # It's just a link to an anchor, leave it alone
        resolved
      elsif relative_url?(url)
        unresolved(:file, :rel_path => URI.unescape(url))
      else
        resolved
      end
    end
  end
end