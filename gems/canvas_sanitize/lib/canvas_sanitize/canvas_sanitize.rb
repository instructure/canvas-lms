# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

class Sanitize; module Transformers; class CleanElement
  # modified from sanitize.rb to allow data-* attributes EXCEPT the ones
  # we have code of our own that treats it like it is trusted html, namely:
  # kyle-menu|turn-into-dialog|flash-message|popup-within|html-tooltip-title
  #
  # Matches a valid HTML5 data attribute name. The unicode ranges included here
  # are a conservative subset of the full range of characters that are
  # technically allowed, with the intent of matching the most common characters
  # used in data attribute names while excluding uncommon or potentially
  # misleading characters, or characters with the potential to be normalized
  # into unsafe or confusing forms.
  #
  # http://www.whatwg.org/specs/web-apps/current-work/multipage/elements.html#embedding-custom-non-visible-data-with-the-data-*-attributes
  remove_const(:REGEX_DATA_ATTR)
  REGEX_DATA_ATTR = /\Adata-(?!xml|kyle-menu|turn-into-dialog|flash-message|popup-within|html-tooltip-title)[a-z_][\w.\u00E0-\u00F6\u00F8-\u017F\u01DD-\u02AF-]*\z/u

end; end; end

module CanvasSanitize #:nodoc:
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  DEFAULT_PROTOCOLS = ['http', 'https', :relative].freeze
  SANITIZE = {
      :elements => [
          'a', 'b', 'blockquote', 'br', 'caption', 'cite', 'code', 'col',
          'hr', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
          'del', 'ins', 'iframe', 'font',
          'colgroup', 'dd', 'div', 'dl', 'dt', 'em', 'figure', 'figcaption', 'i', 'img', 'li', 'ol', 'p', 'pre',
          'q', 'small', 'source', 'span', 'strike', 'strong', 'style', 'sub', 'sup', 'abbr', 'table', 'tbody', 'td',
          'tfoot', 'th', 'thead', 'tr', 'u', 'ul', 'object', 'embed', 'param', 'video', 'track', 'audio',
          # added to unify tinymce and canvas_sanitize whitelists
          'address', 'acronym', 'map', 'area','bdo', 'dfn', 'kbd', 'legend', 'samp', 'tt', 'var', 'big',
          'article', 'aside', 'details', 'footer', 'header', 'nav', 'section', 'summary', 'time', 'picture',
          'ruby', 'rt', 'rp',
          # MathML
          'annotation', 'annotation-xml', 'maction', 'maligngroup', 'malignmark', 'math',
          'menclose', 'merror', 'mfenced', 'mfrac', 'mglyph', 'mi', 'mlabeledtr', 'mlongdiv',
          'mmultiscripts', 'mn', 'mo', 'mover', 'mpadded', 'mphantom', 'mprescripts', 'mroot',
          'mrow', 'ms', 'mscarries', 'mscarry', 'msgroup', 'msline', 'mspace', 'msqrt', 'msrow',
          'mstack', 'mstyle', 'msub', 'msubsup', 'msup', 'mtable', 'mtd', 'mtext', 'mtr', 'munder',
          'munderover', 'none', 'semantics', 'mark'].freeze,

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
          'area' => ['alt', 'coords', 'href', 'shape', 'target'].freeze,
          'blockquote' => ['cite'].freeze,
          'col' => ['span', 'width'].freeze,
          'colgroup' => ['span', 'width'].freeze,
          'img' => ['align', 'alt', 'height', 'src', 'usemap', 'width', 'longdesc'].freeze,
          'iframe' => ['src', 'width', 'height', 'name', 'align', 'frameborder', 'scrolling',
                       'allow', # TODO: remove explicit allow with domain whitelist account setting
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
          'source' => ['media', 'sizes', 'src', 'srcset', 'type'].freeze,
          'embed' => ['name', 'src', 'type', 'allowfullscreen', 'pluginspage', 'wmode',
                      'allowscriptaccess', 'width', 'height'].freeze,
          'video' => ['name', 'src', 'allowfullscreen', 'muted', 'poster', 'width', 'height', 'controls', 'playsinline'].freeze,
          'track' => ['default', 'kind', 'label', 'src', 'srclang'].freeze,
          'audio' => ['name', 'src', 'muted', 'controls'].freeze,
          'font' => ['face', 'color', 'size'].freeze,
          # MathML
          'annotation' => ['href', 'xref', 'definitionURL', 'encoding', 'cd', 'name', 'src'].freeze,
          'annotation-xml' => ['href', 'xref', 'definitionURL', 'encoding', 'cd', 'name', 'src'].freeze,
          'maction' => ['href', 'xref', 'mathcolor', 'mathbackground', 'actiontype', 'selection'].freeze,
          'maligngroup' => ['href', 'xref', 'mathcolor', 'mathbackground', 'groupalign'].freeze,
          'malignmark' => ['href', 'xref', 'mathcolor', 'mathbackground', 'edge'].freeze,
          'map' => ['name'].freeze,
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
          'a' => {
            'href' => ['ftp', 'http', 'https', 'mailto', 'tel', 'skype', :relative].freeze,
            'data-url' => DEFAULT_PROTOCOLS,
            'data-item-href' => DEFAULT_PROTOCOLS
          }.freeze,
          'blockquote' => {'cite' => DEFAULT_PROTOCOLS }.freeze,
          'img' => {'src' => DEFAULT_PROTOCOLS }.freeze,
          'q' => {'cite' => DEFAULT_PROTOCOLS }.freeze,
          'object' => {'data' => DEFAULT_PROTOCOLS }.freeze,
          'embed' => {'src' => DEFAULT_PROTOCOLS }.freeze,
          'iframe' => {'src' => DEFAULT_PROTOCOLS }.freeze,
          'style' => {'any' => DEFAULT_PROTOCOLS }.freeze,
          'annotation' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'annotation-xml' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'maction' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'maligngroup' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'malignmark' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'math' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'menclose' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'merror' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mfenced' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mfrac' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mglyph' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mi' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mlabeledtr' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mlongdiv' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mmultiscripts' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mn' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mo' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mover' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mpadded' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mphantom' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mprescripts' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mroot' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mrow' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'ms' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mscarries' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mscarry' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'msgroup' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'msline' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mspace' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'msqrt' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'msrow' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mstack' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mstyle' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'msub' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'msubsup' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'msup' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mtable' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mtd' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mtext' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'mtr' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'munder' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'munderover' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'none' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
          'semantics' => { 'href' => DEFAULT_PROTOCOLS }.freeze,
      }.freeze,
      css: {
        properties: ([
          'background', 'border', 'border-radius', 'clear', 'clip', 'color',
          'cursor', 'direction', 'display', 'flex', 'float',
          'font', 'grid', 'height', 'left', 'line-height',
          'list-style', 'margin', 'max-height',
          'max-width', 'min-height', 'min-width',
          'overflow', 'overflow-x', 'overflow-y',
          'padding', 'position', 'right',
          'text-align', 'table-layout',
          'text-decoration', 'text-indent',
          'top', 'vertical-align',
          'visibility', 'white-space', 'width',
          'z-index', 'zoom'
        ] +
        %w{attachment color image position repeat}.map { |i| "background-#{i}"} +
        %w{x y}.map { |i| "background-position-#{i}" } +
        %w{bottom collapse color left right spacing style top width}.map { |i| "border-#{i}" } +
        %w{bottom left right top}.map { |i| %w{color style width}.map { |j| "border-#{i}-#{j}" } }.flatten +
        %w{family size stretch style variant width}.map { |i| "font-#{i}" } +
        %w{image position type}.map { |i| "list-style-#{i}" } +
        %w{bottom left right top offset}.map { |i| "margin-#{i}" } +
        %w{bottom left right top}.map { |i| "padding-#{i}" }
        ).to_set.freeze,
        protocols: DEFAULT_PROTOCOLS
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
        next unless self.attribute_changed?(field)
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

