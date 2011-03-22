module ActionView
  class Base
    def self.xss_safe?
      true
    end

    module WithSafeOutputBuffer
      # Rails version of with_output_buffer uses '' as the default buf
      def with_output_buffer(buf = ActiveSupport::SafeBuffer.new) #:nodoc:
        super buf
      end
    end

    include WithSafeOutputBuffer
  end

  module Helpers
    module CaptureHelper
      def content_for(name, content = nil, &block)
        ivar = "@content_for_#{name}"
        content = capture(&block) if block_given?
        instance_variable_set(ivar, "#{instance_variable_get(ivar)}#{ERB::Util.h(content)}".html_safe)
        nil
      end
    end    

    module TextHelper
      def concat(string, unused_binding = nil)
        if unused_binding
          ActiveSupport::Deprecation.warn("The binding argument of #concat is no longer needed.  Please remove it from your views and helpers.", caller)
        end

        output_buffer.concat(string)
      end

      def simple_format_with_escaping(text, html_options = {})
        simple_format_without_escaping(ERB::Util.h(text), html_options)
      end
      alias_method_chain :simple_format, :escaping
    end

    module TagHelper
      private
        def content_tag_string_with_escaping(name, content, options, escape = true)
          content_tag_string_without_escaping(name, escape ? ERB::Util.h(content) : content, options, escape)
        end
        alias_method_chain :content_tag_string, :escaping
    end

    module UrlHelper
      def link_to(*args, &block)
        if block_given?
          options      = args.first || {}
          html_options = args.second
          concat(link_to(capture(&block), options, html_options))
        else
          name         = args.first
          options      = args.second || {}
          html_options = args.third

          url = url_for(options)

          if html_options
            html_options = html_options.stringify_keys
            href = html_options['href']
            convert_options_to_javascript!(html_options, url)
            tag_options = tag_options(html_options)
          else
            tag_options = nil
          end

          href_attr = "href=\"#{url}\"" unless href
          "<a #{href_attr}#{tag_options}>#{ERB::Util.h(name || url)}</a>".html_safe
        end
      end
    end
  end
end

module RailsXss
  module SafeHelpers
    def safe_helper(*names)
      names.each do |helper_method_name|
        aliased_target, punctuation = helper_method_name.to_s.sub(/([?!=])$/, ''), $1
        module_eval <<-END
          def #{aliased_target}_with_xss_safety#{punctuation}(*args, &block)
            raw(#{aliased_target}_without_xss_safety#{punctuation}(*args, &block))
          end
        END
        alias_method_chain helper_method_name, :xss_safety
      end
    end
  end
end

Module.class_eval { include RailsXss::SafeHelpers }
