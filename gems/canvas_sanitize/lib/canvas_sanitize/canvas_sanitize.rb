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

require 'sanitize'

module CanvasSanitize #:nodoc:
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  # modified from sanitize.rb to support mid-value matching
  REGEX_STYLE_PROTOCOL = /([A-Za-z0-9\+\-\.\&\;\#\s]*?)(?:\:|&#0*58|&#x0*3a)/i
  REGEX_STYLE_METHOD = /([A-Za-z0-9\+\-\.\&\;\#\s]*?)(?:\(|&#0*40|&#x0*28)/i

  # used as a sanitize.rb transformer, below
  def self.sanitize_style(env)
    node = env[:node]
    styles = []
    style = node['style'] || ""
    # taken from https://github.com/flavorjones/loofah/blob/master/lib/loofah/html5/scrub.rb
    # the gauntlet
    style = '' unless style =~ /\A([-:,\;#%.\(\)\/\sa-zA-Z0-9!]|\'[\s\w]+\'|\"[\s\w]+\"|\([\d,\s]+\))*\z/
    style = '' unless style =~ /\A\s*([-\w]+\s*:[^\;]*(\;\s*|$))*\z/

    config = env[:config]

    style.scan(/([-\w]+)\s*:\s*([^;]*)/) do |property, value|
      property = property.downcase
      valid = (config[:style_properties] || []).include?(property)
      valid ||= (config[:style_expressions] || []).any? { |e| property.match(e) }
      if valid
        styles << [property, clean_style_value(config, value)]
      end
    end
    node['style'] = styles.select { |k, v| v }.map { |k, v| "#{k}: #{v}" }.join('; ') + ";"
  end

  def self.clean_style_value(config, value)
    # checks for any colons anywhere in the string
    # to make sure they're preceded by a valid protocol
    protocols = config[:protocols]['style']['any']

    # no idea what these are called in css, but it's
    # a name followed by open-paren
    # (i.e. url(...) or expression(...))
    methods = config[:style_methods]

    if methods
      value.to_s.downcase.scan(REGEX_STYLE_METHOD) do |match|
        return nil if !methods.include?(match[0].downcase)
      end
    end
    if protocols
      value.to_s.downcase.scan(REGEX_STYLE_PROTOCOL) do |match|
        return nil if !protocols.include?(match[0].downcase)
      end
    end
    value
  end

  SANITIZE = {
      :elements => [
          'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col',
          'hr', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8',
          'del', 'ins', 'iframe', 'font',
          'colgroup', 'dd', 'div', 'dl', 'dt', 'em', 'figure', 'figcaption', 'i', 'img', 'li', 'ol', 'p', 'pre',
          'q', 'small', 'source', 'span', 'strike', 'strong', 'sub', 'sup', 'table', 'tbody', 'td',
          'tfoot', 'th', 'thead', 'tr', 'u', 'ul', 'object', 'embed', 'param', 'video', 'track', 'audio',
          # MathML
          'annotation', 'annotation-xml', 'maction', 'maligngroup', 'malignmark', 'math',
          'menclose', 'merror', 'mfenced', 'mfrac', 'mglyph', 'mi', 'mlabeledtr', 'mlongdiv',
          'mmultiscripts', 'mn', 'mo', 'mover', 'mpadded', 'mphantom', 'mprescripts', 'mroot',
          'mrow', 'ms', 'mscarries', 'mscarry', 'msgroup', 'msline', 'mspace', 'msqrt', 'msrow',
          'mstack', 'mstyle', 'msub', 'msubsup', 'msup', 'mtable', 'mtd', 'mtext', 'mtr', 'munder',
          'munderover', 'none', 'semantics'].freeze,

      :attributes => {
          :all => ['style',
                   'class',
                   'id',
                   'title',
                   'role',
                   'lang',
                   'dir',
                   :data,  # Note: the symbol :data allows for arbitrary HTML5 data-* attributes
                   'aria-labelledby',
                   'aria-atomic',
                   'aria-busy',
                   'aria-controls',
                   'aria-describedby',
                   'aria-disabled',
                   'aria-dropeffect',
                   'aria-flowto',
                   'aria-grabbed',
                   'aria-haspopup',
                   'aria-hidden',
                   'aria-invalid',
                   'aria-label',
                   'aria-labelledby',
                   'aria-live',
                   'aria-owns',
                   'aria-relevant',
                   'aria-autocomplete',
                   'aria-checked',
                   'aria-disabled',
                   'aria-expanded',
                   'aria-haspopup',
                   'aria-hidden',
                   'aria-invalid',
                   'aria-label',
                   'aria-level',
                   'aria-multiline',
                   'aria-multiselectable',
                   'aria-orientation',
                   'aria-pressed',
                   'aria-readonly',
                   'aria-required',
                   'aria-selected',
                   'aria-sort',
                   'aria-valuemax',
                   'aria-valuemin',
                   'aria-valuenow',
                   'aria-valuetext'].freeze,
          'a' => ['href', 'target', 'name'].freeze,
          'blockquote' => ['cite'].freeze,
          'col' => ['span', 'width'].freeze,
          'colgroup' => ['span', 'width'].freeze,
          'img' => ['align', 'alt', 'height', 'src', 'width'].freeze,
          'iframe' => ['src', 'width', 'height', 'name', 'align', 'frameborder', 'scrolling',
                       'sandbox', 'allowfullscreen','webkitallowfullscreen','mozallowfullscreen'].freeze,
          'ol' => ['start', 'type'].freeze,
          'q' => ['cite'].freeze,
          'table' => ['summary', 'width', 'border', 'cellpadding', 'cellspacing', 'center', 'frame', 'rules'].freeze,
          'tr' => ['align', 'valign', 'dir'].freeze,
          'td' => ['abbr', 'axis', 'colspan', 'rowspan', 'width', 'align', 'valign', 'dir'].freeze,
          'th' => ['abbr', 'axis', 'colspan', 'rowspan', 'width', 'align', 'valign', 'dir', 'scope'].freeze,
          'ul' => ['type'].freeze,
          'param' => ['name', 'value'].freeze,
          'object' => ['width', 'height', 'style', 'data', 'type', 'classid', 'codebase'].freeze,
          'source' => ['src', 'type'].freeze,
          'embed' => ['name', 'src', 'type', 'allowfullscreen', 'pluginspage', 'wmode',
                      'allowscriptaccess', 'width', 'height'].freeze,
          'video' => ['name', 'src', 'allowfullscreen', 'muted', 'poster', 'width', 'height', 'controls'].freeze,
          'track' => ['default', 'kind', 'label', 'src', 'srclang'].freeze,
          'audio' => ['name', 'src', 'muted'].freeze,
          'font' => ['face', 'color', 'size'].freeze,
          # MathML
          'annotation' => ['href', 'xref', 'definitionURL', 'encoding', 'cd', 'name', 'src'].freeze,
          'annotation-xml' => ['href', 'xref', 'definitionURL', 'encoding', 'cd', 'name', 'src'].freeze,
          'maction' => ['href', 'xref', 'mathcolor', 'mathbackground', 'actiontype', 'selection'].freeze,
          'maligngroup' => ['href', 'xref', 'mathcolor', 'mathbackground', 'groupalign'].freeze,
          'malignmark' => ['href', 'xref', 'mathcolor', 'mathbackground', 'edge'].freeze,
          'math' => ['href', 'xref', 'display', 'maxwidth', 'overflow', 'altimg', 'altimg-width',
                     'altimg-height', 'altimg-valign', 'alttext', 'cdgroup', 'mathcolor',
                     'mathbackground', 'scriptlevel', 'displaystyle', 'scriptsizemultiplier',
                     'scriptminsize', 'infixlinebreakstyle', 'decimalpoint', 'mathvariant',
                     'mathsize', 'width', 'height', 'valign', 'form', 'fence', 'separator',
                     'lspace', 'rspace', 'stretchy', 'symmetric', 'maxsize', 'minsize', 'largeop',
                     'movablelimits', 'accent', 'linebreak', 'lineleading', 'linebreakstyle',
                     'linebreakmultchar', 'indentalign', 'indentshift', 'indenttarget',
                     'indentalignfirst', 'indentshiftfirst', 'indentalignlast', 'indentshiftlast',
                     'depth', 'lquote', 'rquote', 'linethickness', 'munalign', 'denomalign',
                     'bevelled', 'voffset', 'open', 'close', 'separators', 'notation',
                     'subscriptshift', 'superscriptshift', 'accentunder', 'align', 'rowalign',
                     'columnalign', 'groupalign', 'alignmentscope', 'columnwidth', 'rowspacing',
                     'columnspacing', 'rowlines', 'columnlines', 'frame', 'framespacing',
                     'equalrows', 'equalcolumns', 'side', 'minlabelspacing', 'rowspan',
                     'columnspan', 'edge', 'stackalign', 'charalign', 'charspacing', 'longdivstyle',
                     'position', 'shift', 'location', 'crossout', 'length', 'leftoverhang',
                     'rightoverhang', 'mslinethickness', 'selection', 'xmlns'].freeze,
          'menclose' => ['href', 'xref', 'mathcolor', 'mathbackground', 'notation'].freeze,
          'merror' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'mfenced' => ['href', 'xref', 'mathcolor', 'mathbackground', 'open', 'close', 'separators'].freeze,
          'mfrac' => ['href', 'xref', 'mathcolor', 'mathbackground', 'linethickness', 'munalign',
                      'denomalign', 'bevelled'].freeze,
          'mglyph' => ['href', 'xref', 'mathcolor', 'mathbackground', 'src', 'alt', 'width', 'height', 'valign'].freeze,
          'mi' => ['href', 'xref', 'mathcolor', 'mathbackground', 'mathvariant', 'mathsize'].freeze,
          'mlabeledtr' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'mlongdiv' => ['href', 'xref', 'mathcolor', 'mathbackground', 'longdivstyle', 'align',
                         'stackalign', 'charalign', 'charspacing'].freeze,
          'mmultiscripts' => ['href', 'xref', 'mathcolor', 'mathbackground', 'subscriptshift',
                              'superscriptshift'].freeze,
          'mn' => ['href', 'xref', 'mathcolor', 'mathbackground', 'mathvariant', 'mathsize'].freeze,
          'mo' => ['href', 'xref', 'mathcolor', 'mathbackground', 'mathvariant', 'mathsize', 'form',
                   'fence', 'separator', 'lspace', 'rspace', 'stretchy', 'symmetric', 'maxsize',
                   'minsize', 'largeop', 'movablelimits', 'accent', 'linebreak', 'lineleading',
                   'linebreakstyle', 'linebreakmultchar', 'indentalign', 'indentshift',
                   'indenttarget', 'indentalignfirst', 'indentshiftfirst', 'indentalignlast',
                   'indentshiftlast'].freeze,
          'mover' => ['href', 'xref', 'mathcolor', 'mathbackground', 'accent', 'align'].freeze,
          'mpadded' => ['href', 'xref', 'mathcolor', 'mathbackground', 'height', 'depth', 'width',
                        'lspace', 'voffset'].freeze,
          'mphantom' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'mprescripts' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'mroot' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'mrow' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'ms' => ['href', 'xref', 'mathcolor', 'mathbackground', 'mathvariant', 'mathsize', 'lquote', 'rquote'].freeze,
          'mscarries' => ['href', 'xref', 'mathcolor', 'mathbackground', 'position', 'location',
                          'crossout', 'scriptsizemultiplier'].freeze,
          'mscarry' => ['href', 'xref', 'mathcolor', 'mathbackground', 'location', 'crossout'].freeze,
          'msgroup' => ['href', 'xref', 'mathcolor', 'mathbackground', 'position', 'shift'].freeze,
          'msline' => ['href', 'xref', 'mathcolor', 'mathbackground', 'position', 'length',
                       'leftoverhang', 'rightoverhang', 'mslinethickness'].freeze,
          'mspace' => ['href', 'xref', 'mathcolor', 'mathbackground', 'mathvariant', 'mathsize'].freeze,
          'msqrt' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'msrow' => ['href', 'xref', 'mathcolor', 'mathbackground', 'position'].freeze,
          'mstack' => ['href', 'xref', 'mathcolor', 'mathbackground', 'align', 'stackalign',
                       'charalign', 'charspacing'].freeze,
          'mstyle' => ['href', 'xref', 'mathcolor', 'mathbackground', 'scriptlevel', 'displaystyle',
                       'scriptsizemultiplier', 'scriptminsize', 'infixlinebreakstyle',
                       'decimalpoint', 'mathvariant', 'mathsize', 'width', 'height', 'valign',
                       'form', 'fence', 'separator', 'lspace', 'rspace', 'stretchy', 'symmetric',
                       'maxsize', 'minsize', 'largeop', 'movablelimits', 'accent', 'linebreak',
                       'lineleading', 'linebreakstyle', 'linebreakmultchar', 'indentalign',
                       'indentshift', 'indenttarget', 'indentalignfirst', 'indentshiftfirst',
                       'indentalignlast', 'indentshiftlast', 'depth', 'lquote', 'rquote',
                       'linethickness', 'munalign', 'denomalign', 'bevelled', 'voffset', 'open',
                       'close', 'separators', 'notation', 'subscriptshift', 'superscriptshift',
                       'accentunder', 'align', 'rowalign', 'columnalign', 'groupalign',
                       'alignmentscope', 'columnwidth', 'rowspacing', 'columnspacing', 'rowlines',
                       'columnlines', 'frame', 'framespacing', 'equalrows', 'equalcolumns', 'side',
                       'minlabelspacing', 'rowspan', 'columnspan', 'edge', 'stackalign',
                       'charalign', 'charspacing', 'longdivstyle', 'position', 'shift', 'location',
                       'crossout', 'length', 'leftoverhang', 'rightoverhang', 'mslinethickness',
                       'selection'].freeze,
          'msub' => ['href', 'xref', 'mathcolor', 'mathbackground', 'subscriptshift'].freeze,
          'msubsup' => ['href', 'xref', 'mathcolor', 'mathbackground', 'subscriptshift', 'superscriptshift'].freeze,
          'msup' => ['href', 'xref', 'mathcolor', 'mathbackground', 'superscriptshift'].freeze,
          'mtable' => ['href', 'xref', 'mathcolor', 'mathbackground', 'align', 'rowalign',
                       'columnalign', 'groupalign', 'alignmentscope', 'columnwidth', 'width',
                       'rowspacing', 'columnspacing', 'rowlines', 'columnlines', 'frame',
                       'framespacing', 'equalrows', 'equalcolumns', 'displaystyle', 'side',
                       'minlabelspacing'].freeze,
          'mtd' => ['href', 'xref', 'mathcolor', 'mathbackground', 'rowspan', 'columnspan',
                    'rowalign', 'columnalign', 'groupalign'].freeze,
          'mtext' => ['href', 'xref', 'mathcolor', 'mathbackground', 'mathvariant', 'mathsize',
                      'width', 'height', 'depth', 'linebreak'].freeze,
          'mtr' => ['href', 'xref', 'mathcolor', 'mathbackground', 'rowalign', 'columnalign', 'groupalign'].freeze,
          'munder' => ['href', 'xref', 'mathcolor', 'mathbackground', 'accentunder', 'align'].freeze,
          'munderover' => ['href', 'xref', 'mathcolor', 'mathbackground', 'accent', 'accentunder', 'align'].freeze,
          'none' => ['href', 'xref', 'mathcolor', 'mathbackground'].freeze,
          'semantics' => ['href', 'xref', 'definitionURL', 'encoding'].freeze,
      }.freeze,

      :protocols => {
          'a' => {'href' => ['ftp', 'http', 'https', 'mailto',
                             :relative].freeze}.freeze,
          'blockquote' => {'cite' => ['http', 'https', :relative].freeze}.freeze,
          'img' => {'src' => ['http', 'https', :relative].freeze}.freeze,
          'q' => {'cite' => ['http', 'https', :relative].freeze}.freeze,
          'object' => {'data' => ['http', 'https', :relative].freeze}.freeze,
          'embed' => {'src' => ['http', 'https', :relative].freeze}.freeze,
          'iframe' => {'src' => ['http', 'https', :relative].freeze}.freeze,
          'style' => {'any' => ['http', 'https', :relative].freeze}.freeze
      }.freeze,
      :style_methods => ['url'].freeze,
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
      ].freeze,
      :style_expressions => [
          /\Abackground-(?:attachment|color|image|position|repeat)\z/,
          /\Abackground-position-(?:x|y)\z/,
          /\Aborder-(?:bottom|collapse|color|left|right|spacing|style|top|width)\z/,
          /\Aborder-(?:bottom|left|right|top)-(?:color|style|width)\z/,
          /\Afont-(?:family|size|stretch|style|variant|weight)\z/,
          /\Alist-style-(?:image|position|type)\z/,
          /\Amargin-(?:bottom|left|right|top|offset)\z/,
          /\Apadding-(?:bottom|left|right|top)\z/
      ].freeze,
      :transformers => lambda { |env|
        CanvasSanitize.sanitize_style(env) if env[:node]['style']
        Sanitize.clean_node!(env[:node], {:remove_contents => true}) if env[:node_name] == 'style'
      }
  }.freeze

  module ClassMethods

    def sanitize_field(*args)

      # Calls this as many times as a field is configured.  Will this play
      # nicely?
      include CanvasSanitize::InstanceMethods
      extend CanvasSanitize::SingletonMethods

      @config = OpenStruct.new
      @config.sanitizer = []
      @config.fields = []
      @config.allow_comments = true
      args.each { |arg| infer_sanitize_arg(arg) }
      @config.fields.each do |field|
        class_attribute :fully_sanitize_fields_config
        fields = (self.fully_sanitize_fields_config ||= {})
        fields[field] = @config.sanitizer.first
      end

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
      fields_hash = self.class.fully_sanitize_fields_config || {}
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
end
