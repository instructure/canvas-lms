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

require "sanitize"

class Sanitize
  module Transformers
    class CleanElement
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
      REGEX_DATA_ATTR = /\Adata-(?!xml|kyle-menu|turn-into-dialog|flash-message|popup-within|html-tooltip-title|method)[a-z_][\w.\u00E0-\u00F6\u00F8-\u017F\u01DD-\u02AF-]*\z/u
    end
  end
end

module CanvasSanitize # :nodoc:
  def self.included(klass)
    klass.extend(ClassMethods)
  end

  DEFAULT_PROTOCOLS = ["http", "https", :relative].freeze

  remove_spaces_from_ids = lambda do |env|
    return unless env[:node]&.element? && env[:node][:id] && env[:node][:id].match?(/\s/)

    env[:node][:id] = env[:node][:id].gsub(/\s+/, "")
  end

  SANITIZE = {
    elements: [
      "a",
      "b",
      "blockquote",
      "br",
      "caption",
      "cite",
      "code",
      "col",
      "hr",
      "h1",
      "h2",
      "h3",
      "h4",
      "h5",
      "h6",
      "del",
      "ins",
      "iframe",
      "font",
      "colgroup",
      "dd",
      "div",
      "dl",
      "dt",
      "em",
      "figure",
      "figcaption",
      "i",
      "img",
      "li",
      "ol",
      "p",
      "pre",
      "q",
      "small",
      "source",
      "span",
      "strike",
      "strong",
      "style",
      "sub",
      "sup",
      "abbr",
      "table",
      "tbody",
      "td",
      "tfoot",
      "th",
      "thead",
      "tr",
      "u",
      "ul",
      "object",
      "embed",
      "param",
      "video",
      "track",
      "audio",
      # added to unify tinymce and canvas_sanitize whitelists
      "address",
      "acronym",
      "map",
      "area",
      "bdo",
      "dfn",
      "kbd",
      "legend",
      "samp",
      "tt",
      "var",
      "big",
      "article",
      "aside",
      "details",
      "footer",
      "header",
      "nav",
      "section",
      "summary",
      "time",
      "picture",
      "ruby",
      "rt",
      "rp",
      # MathML
      "annotation",
      "annotation-xml",
      "maction",
      "maligngroup",
      "malignmark",
      "math",
      "menclose",
      "merror",
      "mfenced",
      "mfrac",
      "mglyph",
      "mi",
      "mlabeledtr",
      "mlongdiv",
      "mmultiscripts",
      "mn",
      "mo",
      "mover",
      "mpadded",
      "mphantom",
      "mprescripts",
      "mroot",
      "mrow",
      "ms",
      "mscarries",
      "mscarry",
      "msgroup",
      "msline",
      "mspace",
      "msqrt",
      "msrow",
      "mstack",
      "mstyle",
      "msub",
      "msubsup",
      "msup",
      "mtable",
      "mtd",
      "mtext",
      "mtr",
      "munder",
      "munderover",
      "none",
      "semantics",
      "mark"
    ].freeze,

    # The default is Nokogiri::Gumbo::DEFAULT_MAX_TREE_DEPTH = 400
    # Quiz Submissions often contain many layers of nested tables
    # User content (in pages or syllabus, for example) can also contain deeply-nested content
    parser_options: {
      max_tree_depth: 10_000,
    }.freeze,

    attributes: {
      :all => ["style",
               "class",
               "id",
               "title",
               "role",
               "lang",
               "dir",
               :data, # NOTE: the symbol :data allows for arbitrary HTML5 data-* attributes
               "aria-labelledby",
               "aria-atomic",
               "aria-busy",
               "aria-controls",
               "aria-describedby",
               "aria-disabled",
               "aria-dropeffect",
               "aria-flowto",
               "aria-grabbed",
               "aria-haspopup",
               "aria-hidden",
               "aria-invalid",
               "aria-label",
               "aria-labelledby",
               "aria-live",
               "aria-owns",
               "aria-relevant",
               "aria-autocomplete",
               "aria-checked",
               "aria-disabled",
               "aria-expanded",
               "aria-haspopup",
               "aria-hidden",
               "aria-invalid",
               "aria-label",
               "aria-level",
               "aria-multiline",
               "aria-multiselectable",
               "aria-orientation",
               "aria-pressed",
               "aria-readonly",
               "aria-required",
               "aria-selected",
               "aria-sort",
               "aria-valuemax",
               "aria-valuemin",
               "aria-valuenow",
               "aria-valuetext"].freeze,
      "a" => %w[href target name].freeze,
      "area" => %w[alt coords href shape target].freeze,
      "blockquote" => ["cite"].freeze,
      "col" => ["span", "width"].freeze,
      "colgroup" => ["span", "width"].freeze,
      "img" => %w[align alt height src usemap width longdesc].freeze,
      "iframe" => ["src",
                   "width",
                   "height",
                   "name",
                   "align",
                   "frameborder",
                   "scrolling",
                   "allow", # TODO: remove explicit allow with domain whitelist account setting
                   "sandbox",
                   "allowfullscreen",
                   "webkitallowfullscreen",
                   "mozallowfullscreen"].freeze,
      "ol" => ["start", "type"].freeze,
      "q" => ["cite"].freeze,
      "table" => %w[summary width border cellpadding cellspacing center frame rules].freeze,
      "tr" => %w[align valign dir].freeze,
      "td" => %w[abbr axis colspan rowspan width align valign dir].freeze,
      "th" => %w[abbr axis colspan rowspan width align valign dir scope].freeze,
      "ul" => ["type"].freeze,
      "param" => ["name", "value"].freeze,
      "object" => %w[width height style data type classid codebase].freeze,
      "source" => %w[media width height sizes src srcset type].freeze,
      "embed" => %w[name
                    src
                    type
                    allowfullscreen
                    pluginspage
                    wmode
                    allowscriptaccess
                    width
                    height].freeze,
      "video" => %w[name src allowfullscreen allow muted poster width height controls playsinline].freeze,
      "track" => %w[default kind label src srclang].freeze,
      "audio" => %w[name src allowfullscreen allow muted poster width height controls playsinline].freeze,
      "font" => %w[face color size].freeze,
      # MathML
      "annotation" => %w[href xref definitionURL encoding cd name src].freeze,
      "annotation-xml" => %w[href xref definitionURL encoding cd name src].freeze,
      "maction" => %w[href xref mathcolor mathbackground actiontype selection].freeze,
      "maligngroup" => %w[href xref mathcolor mathbackground groupalign].freeze,
      "malignmark" => %w[href xref mathcolor mathbackground edge].freeze,
      "map" => ["name"].freeze,
      "math" => %w[href
                   xref
                   display
                   maxwidth
                   overflow
                   altimg
                   altimg-width
                   altimg-height
                   altimg-valign
                   alttext
                   cdgroup
                   mathcolor
                   mathbackground
                   scriptlevel
                   displaystyle
                   scriptsizemultiplier
                   scriptminsize
                   infixlinebreakstyle
                   decimalpoint
                   mathvariant
                   mathsize
                   width
                   height
                   valign
                   form
                   fence
                   separator
                   lspace
                   rspace
                   stretchy
                   symmetric
                   maxsize
                   minsize
                   largeop
                   movablelimits
                   accent
                   linebreak
                   lineleading
                   linebreakstyle
                   linebreakmultchar
                   indentalign
                   indentshift
                   indenttarget
                   indentalignfirst
                   indentshiftfirst
                   indentalignlast
                   indentshiftlast
                   depth
                   lquote
                   rquote
                   linethickness
                   munalign
                   denomalign
                   bevelled
                   voffset
                   open
                   close
                   separators
                   notation
                   subscriptshift
                   superscriptshift
                   accentunder
                   align
                   rowalign
                   columnalign
                   groupalign
                   alignmentscope
                   columnwidth
                   rowspacing
                   columnspacing
                   rowlines
                   columnlines
                   frame
                   framespacing
                   equalrows
                   equalcolumns
                   side
                   minlabelspacing
                   rowspan
                   columnspan
                   edge
                   stackalign
                   charalign
                   charspacing
                   longdivstyle
                   position
                   shift
                   location
                   crossout
                   length
                   leftoverhang
                   rightoverhang
                   mslinethickness
                   selection
                   xmlns].freeze,
      "menclose" => %w[href xref mathcolor mathbackground notation].freeze,
      "merror" => %w[href xref mathcolor mathbackground].freeze,
      "mfenced" => %w[href xref mathcolor mathbackground open close separators].freeze,
      "mfrac" => %w[href
                    xref
                    mathcolor
                    mathbackground
                    linethickness
                    munalign
                    denomalign
                    bevelled].freeze,
      "mglyph" => %w[href xref mathcolor mathbackground src alt width height valign].freeze,
      "mi" => %w[href xref mathcolor mathbackground mathvariant mathsize].freeze,
      "mlabeledtr" => %w[href xref mathcolor mathbackground].freeze,
      "mlongdiv" => %w[href
                       xref
                       mathcolor
                       mathbackground
                       longdivstyle
                       align
                       stackalign
                       charalign
                       charspacing].freeze,
      "mmultiscripts" => %w[href
                            xref
                            mathcolor
                            mathbackground
                            subscriptshift
                            superscriptshift].freeze,
      "mn" => %w[href xref mathcolor mathbackground mathvariant mathsize].freeze,
      "mo" => %w[href
                 xref
                 mathcolor
                 mathbackground
                 mathvariant
                 mathsize
                 form
                 fence
                 separator
                 lspace
                 rspace
                 stretchy
                 symmetric
                 maxsize
                 minsize
                 largeop
                 movablelimits
                 accent
                 linebreak
                 lineleading
                 linebreakstyle
                 linebreakmultchar
                 indentalign
                 indentshift
                 indenttarget
                 indentalignfirst
                 indentshiftfirst
                 indentalignlast
                 indentshiftlast].freeze,
      "mover" => %w[href xref mathcolor mathbackground accent align].freeze,
      "mpadded" => %w[href
                      xref
                      mathcolor
                      mathbackground
                      height
                      depth
                      width
                      lspace
                      voffset].freeze,
      "mphantom" => %w[href xref mathcolor mathbackground].freeze,
      "mprescripts" => %w[href xref mathcolor mathbackground].freeze,
      "mroot" => %w[href xref mathcolor mathbackground].freeze,
      "mrow" => %w[href xref mathcolor mathbackground].freeze,
      "ms" => %w[href xref mathcolor mathbackground mathvariant mathsize lquote rquote].freeze,
      "mscarries" => %w[href
                        xref
                        mathcolor
                        mathbackground
                        position
                        location
                        crossout
                        scriptsizemultiplier].freeze,
      "mscarry" => %w[href xref mathcolor mathbackground location crossout].freeze,
      "msgroup" => %w[href xref mathcolor mathbackground position shift].freeze,
      "msline" => %w[href
                     xref
                     mathcolor
                     mathbackground
                     position
                     length
                     leftoverhang
                     rightoverhang
                     mslinethickness].freeze,
      "mspace" => %w[href xref mathcolor mathbackground mathvariant mathsize].freeze,
      "msqrt" => %w[href xref mathcolor mathbackground].freeze,
      "msrow" => %w[href xref mathcolor mathbackground position].freeze,
      "mstack" => %w[href
                     xref
                     mathcolor
                     mathbackground
                     align
                     stackalign
                     charalign
                     charspacing].freeze,
      "mstyle" => %w[href
                     xref
                     mathcolor
                     mathbackground
                     scriptlevel
                     displaystyle
                     scriptsizemultiplier
                     scriptminsize
                     infixlinebreakstyle
                     decimalpoint
                     mathvariant
                     mathsize
                     width
                     height
                     valign
                     form
                     fence
                     separator
                     lspace
                     rspace
                     stretchy
                     symmetric
                     maxsize
                     minsize
                     largeop
                     movablelimits
                     accent
                     linebreak
                     lineleading
                     linebreakstyle
                     linebreakmultchar
                     indentalign
                     indentshift
                     indenttarget
                     indentalignfirst
                     indentshiftfirst
                     indentalignlast
                     indentshiftlast
                     depth
                     lquote
                     rquote
                     linethickness
                     munalign
                     denomalign
                     bevelled
                     voffset
                     open
                     close
                     separators
                     notation
                     subscriptshift
                     superscriptshift
                     accentunder
                     align
                     rowalign
                     columnalign
                     groupalign
                     alignmentscope
                     columnwidth
                     rowspacing
                     columnspacing
                     rowlines
                     columnlines
                     frame
                     framespacing
                     equalrows
                     equalcolumns
                     side
                     minlabelspacing
                     rowspan
                     columnspan
                     edge
                     stackalign
                     charalign
                     charspacing
                     longdivstyle
                     position
                     shift
                     location
                     crossout
                     length
                     leftoverhang
                     rightoverhang
                     mslinethickness
                     selection].freeze,
      "msub" => %w[href xref mathcolor mathbackground subscriptshift].freeze,
      "msubsup" => %w[href xref mathcolor mathbackground subscriptshift superscriptshift].freeze,
      "msup" => %w[href xref mathcolor mathbackground superscriptshift].freeze,
      "mtable" => %w[href
                     xref
                     mathcolor
                     mathbackground
                     align
                     rowalign
                     columnalign
                     groupalign
                     alignmentscope
                     columnwidth
                     width
                     rowspacing
                     columnspacing
                     rowlines
                     columnlines
                     frame
                     framespacing
                     equalrows
                     equalcolumns
                     displaystyle
                     side
                     minlabelspacing].freeze,
      "mtd" => %w[href
                  xref
                  mathcolor
                  mathbackground
                  rowspan
                  columnspan
                  rowalign
                  columnalign
                  groupalign].freeze,
      "mtext" => %w[href
                    xref
                    mathcolor
                    mathbackground
                    mathvariant
                    mathsize
                    width
                    height
                    depth
                    linebreak].freeze,
      "mtr" => %w[href xref mathcolor mathbackground rowalign columnalign groupalign].freeze,
      "munder" => %w[href xref mathcolor mathbackground accentunder align].freeze,
      "munderover" => %w[href xref mathcolor mathbackground accent accentunder align].freeze,
      "none" => %w[href xref mathcolor mathbackground].freeze,
      "semantics" => %w[href xref definitionURL encoding].freeze,
    }.freeze,

    protocols: {
      "a" => {
        "href" => ["ftp", "http", "https", "mailto", "tel", "skype", :relative].freeze,
        "data-url" => DEFAULT_PROTOCOLS,
        "data-item-href" => DEFAULT_PROTOCOLS
      }.freeze,
      "blockquote" => { "cite" => DEFAULT_PROTOCOLS }.freeze,
      "img" => { "src" => DEFAULT_PROTOCOLS }.freeze,
      "q" => { "cite" => DEFAULT_PROTOCOLS }.freeze,
      "object" => { "data" => DEFAULT_PROTOCOLS }.freeze,
      "embed" => { "src" => DEFAULT_PROTOCOLS }.freeze,
      "iframe" => { "src" => DEFAULT_PROTOCOLS }.freeze,
      "style" => { "any" => DEFAULT_PROTOCOLS }.freeze,
      "audio" => { "src" => ["data", "http", "https", :relative] }.freeze,
      "video" => { "src" => ["data", "http", "https", :relative] }.freeze,
      "source" => { "src" => ["data", "http", "https", :relative] }.freeze,
      "track" => { "src" => ["data", "http", "https", :relative] }.freeze,
    },

    css: {
      properties: (%w[
        align-content
        align-items
        align-self
        background
        border
        border-radius
        clear
        clip
        color
        column-gap
        cursor
        direction
        display
        flex
        flex-basis
        flex-direction
        flex-flow
        flex-grow
        flex-shrink
        flex-wrap
        float
        font
        gap
        grid
        height
        justify-content
        justify-items
        justify-self
        left
        line-height
        list-style
        margin
        max-height
        max-width
        min-height
        min-width
        order
        overflow
        overflow-x
        overflow-y
        padding
        position
        place-content
        place-items
        place-self
        right
        row-gap
        text-align
        table-layout
        text-decoration
        text-indent
        top
        vertical-align
        visibility
        white-space
        width
        z-index
        zoom
      ] +
      %w[area auto-columns auto-flow auto-rows column gap row template].map { |i| "grid-#{i}" } +
      %w[areas columns rows].map { |i| "grid-template-#{i}" } +
      %w[end gap start].map { |i| "grid-column-#{i}" } +
      %w[end gap start].map { |i| "grid-row-#{i}" } +
      %w[attachment color image position repeat].map { |i| "background-#{i}" } +
      %w[x y].map { |i| "background-position-#{i}" } +
      %w[bottom collapse color left right spacing style top width].map { |i| "border-#{i}" } +
      %w[bottom left right top].map { |i| %w[color style width].map { |j| "border-#{i}-#{j}" } }.flatten +
      %w[family size stretch style variant width].map { |i| "font-#{i}" } +
      %w[image position type].map { |i| "list-style-#{i}" } +
      %w[bottom left right top offset].map { |i| "margin-#{i}" } +
      %w[bottom left right top].map { |i| "padding-#{i}" }
                  ).to_set.freeze,
      protocols: DEFAULT_PROTOCOLS
    },

    transformers: remove_spaces_from_ids
  }.freeze

  # Any allowed elements for which we don't explicitly declare a
  # protocol above will be populated with a sane default for
  # href/src/cite/etc. so as to not allow arbitrary javascript or
  # other protocols on any tag + attribute combos we may have missed
  missing_protocol_elements = SANITIZE[:elements].to_set - SANITIZE[:protocols].keys.to_set
  missing_protocol_elements.each do |element|
    elements_allowed_attributes = SANITIZE[:attributes][element]
    element_protocols = %w[href src cite].each_with_object({}) do |attribute, hash|
      hash[attribute] = DEFAULT_PROTOCOLS if elements_allowed_attributes&.include?(attribute)
    end
    SANITIZE[:protocols][element] = element_protocols.freeze unless element_protocols.empty?
  end

  SANITIZE[:protocols].freeze
  SANITIZE.freeze

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
      when Hash,
           Sanitize::Config::RELAXED,
           Sanitize::Config::BASIC,
           Sanitize::Config::RESTRICTED
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
        next unless attribute_changed?(field)

        config ||= Sanitize::Config::RESTRICTED
        config = Sanitize::Config::RESTRICTED if config.empty?
        # Doesn't try to sanitize nil
        f = send(field)
        next unless f
        next unless f.is_a?(String) || f.is_a?(IO)

        val = Sanitize.clean(f, config)
        send((field.to_s + "="), val)
      end
    end
  end # InstanceMethods
end
