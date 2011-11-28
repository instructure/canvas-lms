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

module Instructure #:nodoc:
  module SanitizeField #:nodoc:
    
    def self.included(klass)
      klass.extend(ClassMethods)
    end
    
    SANITIZE = {
      :elements => [
        'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col',
        'hr', 'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8',
        'del', 'ins', 'iframe',
        'colgroup', 'dd', 'div', 'dl', 'dt', 'em', 'i', 'img', 'li', 'ol', 'p', 'pre',
        'q', 'small', 'span', 'strike', 'strong', 'sub', 'sup', 'table', 'tbody', 'td',
        'tfoot', 'th', 'thead', 'tr', 'u', 'ul', 'object', 'embed', 'param'],

      :attributes => {
        :all        => ['style', 'class', 'id'],
        'a'          => ['href', 'title', 'target', 'name'],
        'blockquote' => ['cite'],
        'col'        => ['span', 'width'],
        'colgroup'   => ['span', 'width'],
        'img'        => ['align', 'alt', 'height', 'src', 'title', 'width'],
        'iframe'     => ['src', 'width', 'height', 'name', 'align', 'frameborder', 'scrolling'],
        'ol'         => ['start', 'type'],
        'q'          => ['cite'],
        'table'      => ['summary', 'width', 'border', 'cellpadding', 'cellspacing', 'center', 'frame', 'rules', 'dir', 'lang'],
        'tr'         => ['align', 'valign', 'dir'],
        'td'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width', 'align', 'valign', 'dir'],
        'th'         => ['abbr', 'axis', 'colspan', 'rowspan', 'width', 'align', 'valign', 'dir', 'scope'],
        'ul'         => ['type'],
        'param'      => ['name', 'value'],
        'object'     => ['width', 'height', 'style', 'data', 'type', 'classid', 'codebase'],
        'embed'      => ['name', 'src', 'type', 'allowfullscreen', 'pluginspage', 'wmode', 'allowscriptaccess', 'width', 'height']
      },

      :protocols => {
        'a'          => {'href' => ['ftp', 'http', 'https', 'mailto',
                                    :relative]},
        'blockquote' => {'cite' => ['http', 'https', :relative]},
        'img'        => {'src'  => ['http', 'https', :relative]},
        'q'          => {'cite' => ['http', 'https', :relative]},
        'object'     => {'data' => ['http', 'https', :relative]},
        'embed'      => {'src'  => ['http', 'https', :relative]},
        'iframe'     => {'src'  => ['http', 'https', :relative]},
        'style'      => {'any'  => ['http', 'https', :relative]}
      },
      :style_methods => ['url'],
      :style_properties => [
        'background', 'border', 'clear', 'color',
        'cursor', 'direction', 'display', 'float',
        'font', 'height', 'left', 'line-height',
        'list-style', 'margin', 'max-height',
        'max-width', 'min-height', 'min-width',
        'overflow', 'overflow-x', 'overflow-y',
        'padding', 'position', 'right',
        'text-align', 'table-layout',
        'text-decoration', 'text-indent',
        'top', 'vertical-align',
        'visibility', 'white-space', 'width',
        'z-index', 'zoom'
      ],
      :style_expressions => [
        /\Abackground-(?:attachment|color|image|position|repeat)\z/,
        /\Abackground-position-(?:x|y)\z/,
        /\Aborder-(?:bottom|collapse|color|left|right|spacing|style|top|width)\z/,
        /\Aborder-(?:bottom|left|right|top)-(?:color|style|width)\z/,
        /\Afont-(?:family|size|stretch|style|variant|weight)\z/,
        /\Alist-style-(?:image|position|type)\z/,
        /\Amargin-(?:bottom|left|right|top|offset)\z/,
        /\Apadding-(?:bottom|left|right|top)\z/
      ]
    }
    
    module ClassMethods
      
      def sanitize_field(*args)
        
        # Calls this as many times as a field is configured.  Will this play
        # nicely? 
        include Instructure::SanitizeField::InstanceMethods
        extend Instructure::SanitizeField::SingletonMethods

        @config = OpenStruct.new
        @config.sanitizer = []
        @config.fields = []
        @config.allow_comments = true
        args.each { |arg| infer_sanitize_arg(arg) }
        @config.fields.each { |field| write_inheritable_hash(:fully_sanitize_fields, {field => @config.sanitizer.first} ) }

        before_save :fully_sanitize_fields
      end
      
      protected
      
        def infer_sanitize_arg(arg)
          case arg
          when Symbol
            @config.fields << arg
          when Hash
            @config.sanitizer << arg
          when Sanitize::Config::RELAXED
            @config.sanitizer << arg
          when Sanitize::Config::BASIC
            @config.sanitizer << arg
          when Sanitize::Config::RESTRICTED
            @config.sanitizer << arg
          end
        end
        
    end # ClassMethods
      
    module SingletonMethods
      # None right now
    end # SingletonMethods
    
    module InstanceMethods
      protected

        # This should be a protected method on the class.  It should run a
        # different sanitizer on every field being sanitized, using any
        # configuration set for that specific field or 
        # Sanitize::Config::RESTRICTED as the default. 
        def fully_sanitize_fields
          fields_hash = self.class.read_inheritable_attribute(:fully_sanitize_fields) || {}
          fields_hash.each do |field, config|
            config ||= Sanitize::Config::RESTRICTED
            config = Sanitize::Config::RESTRICTED if config.empty?
            # Doesn't try to sanitize nil
            f = self.send(field)
            next unless f
            next unless f.is_a?(String) or f.is_a?(IO)
            val = Sanitize.clean(f, config) 
            self.send((field.to_s + "="), val)
          end
        end

    end # InstanceMethods
  end # SanitizeField
end # Instructure
