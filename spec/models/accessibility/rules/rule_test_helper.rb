# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "spec_helper"

module RuleTestHelper
  include ::Accessibility::NokogiriMethods

  RULE_MAP = {
    adjacent_links: Accessibility::Rules::AdjacentLinksRule,
    headings_sequence: Accessibility::Rules::HeadingsSequenceRule,
    headings_start_at_h2: Accessibility::Rules::HeadingsStartAtH2Rule,
    img_alt: Accessibility::Rules::ImgAltRule,
    img_alt_filename: Accessibility::Rules::ImgAltFilenameRule,
    img_alt_length: Accessibility::Rules::ImgAltLengthRule,
    list_structure: Accessibility::Rules::ListStructureRule,
    paragraphs_for_headings: Accessibility::Rules::ParagraphsForHeadingsRule,
    small_text_contrast: Accessibility::Rules::SmallTextContrastRule,
    large_text_contrast: Accessibility::Rules::LargeTextContrastRule,
    table_caption: Accessibility::Rules::TableCaptionRule,
    table_header: Accessibility::Rules::TableHeaderRule,
    table_header_scope: Accessibility::Rules::TableHeaderScopeRule
  }.freeze

  RULE_TRANSFORMATIONS = {
    adjacent_links: {
      '<div><a href="https://example.com">Link 1</a> <a href="https://example.com">Link 2</a></div>' =>
        '<div><a href="https://example.com">Link 1 Link 2</a></div>',
      '<div><a href="https://example.com">Link 1</a> <a href="https://different.com">Link 2</a></div>' =>
        '<div><a href="https://example.com">Link 1</a> <a href="https://different.com">Link 2</a></div>'
    },

    headings_sequence: {
      "<div><h2>First heading</h2><h4>Skipped heading level</h4></div>" =>
        "<div><h2>First heading</h2><h3>Skipped heading level</h3></div>",
      "<div><h2>First heading</h2><h3>Proper sequence</h3></div>" =>
        "<div><h2>First heading</h2><h3>Proper sequence</h3></div>"
    },

    headings_start_at_h2: {
      "<div><h1>Document Title</h1><h2>Section Title</h2></div>" =>
        "<div><h2>Document Title</h2><h3>Section Title</h3></div>",
      "<div><h1>Document Title</h1><h2>Section Title</h2><h3>Subsection</h3></div>" =>
        "<div><h2>Document Title</h2><h3>Section Title</h3><h4>Subsection</h4></div>",
      "<div><h2>Already starts at h2</h2></div>" =>
        "<div><h2>Already starts at h2</h2></div>"
    },

    img_alt: {
      '<div><img src="image.jpg"></div>' =>
        '<div><img src="image.jpg" alt="Image description"></div>',
      '<div><img src="image.jpg" alt="Already has alt"></div>' =>
        '<div><img src="image.jpg" alt="Already has alt"></div>'
    },

    img_alt_filename: {
      '<div><img src="image.jpg" alt="image.jpg"></div>' =>
        '<div><img src="image.jpg" alt="Descriptive alt text"></div>',
      '<div><img src="image.jpg" alt="A beautiful landscape"></div>' =>
        '<div><img src="image.jpg" alt="A beautiful landscape"></div>'
    },

    img_alt_length: {
      '<div><img src="image.jpg" alt="This is an extremely long description that contains far too many words and details about the image. The alt text should be concise and to the point, not unnecessarily verbose. Screen readers will read all of this text to users, making for a poor experience."></div>' =>
        '<div><img src="image.jpg" alt="This is an extremely long description that contains far too many words and details about the image. The alt text should be con..."></div>',
      '<div><img src="image.jpg" alt="A mountain landscape"></div>' =>
        '<div><img src="image.jpg" alt="A mountain landscape"></div>'
    },

    list_structure: {
      "<ul><li>First item</li><div>Not a list item</div><li>Third item</li></ul>" =>
        "<ul><li>First item</li><li>Not a list item</li><li>Third item</li></ul>",
      "<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>" =>
        "<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>"
    },

    paragraphs_for_headings: {
      "<div><h2>Heading without paragraph</h2><h3>Another heading</h3><p>This paragraph belongs to the second heading.</p></div>" =>
        "<div><h2>Heading without paragraph</h2><p>Added paragraph for accessibility.</p><h3>Another heading</h3><p>This paragraph belongs to the second heading.</p></div>",
      "<div><h2>Heading with paragraph</h2><p>This paragraph belongs to the heading.</p></div>" =>
        "<div><h2>Heading with paragraph</h2><p>This paragraph belongs to the heading.</p></div>"
    },

    small_text_contrast: {
      '<p style="color: #CCCCCC; background-color: #FFFFFF;">Low contrast text</p>' =>
        '<p style="color: #767676; background-color: #FFFFFF;">Low contrast text</p>',
      '<p style="color: #000000; background-color: #FFFFFF;">Good contrast text</p>' =>
        '<p style="color: #000000; background-color: #FFFFFF;">Good contrast text</p>'
    },

    large_text_contrast: {
      '<h1 style="color: #BBBBBB; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>' =>
        '<h1 style="color: #767676; background-color: #FFFFFF; font-size: 24px;">Low contrast heading</h1>',
      '<h1 style="color: #777777; background-color: #FFFFFF; font-size: 24px;">Sufficient contrast</h1>' =>
        '<h1 style="color: #777777; background-color: #FFFFFF; font-size: 24px;">Sufficient contrast</h1>'
    },

    table_caption: {
      "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>" =>
        "<table><caption>Table caption</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>",
      "<table><caption>Table Caption</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>" =>
        "<table><caption>Table Caption</caption><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
    },

    table_header: {
      "<table><tr><td>Cell 1</td><td>Cell 2</td></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>" =>
        "<table><tr><th>Cell 1</th><th>Cell 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>",
      "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>" =>
        "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>"
    },

    table_header_scope: {
      "<table><tr><th>Header 1</th><th>Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>" =>
        '<table><tr><th scope="col">Header 1</th><th scope="col">Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>',
      '<table><tr><th scope="col">Header 1</th><th scope="col">Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>' =>
        '<table><tr><th scope="col">Header 1</th><th scope="col">Header 2</th></tr><tr><td>Data 1</td><td>Data 2</td></tr></table>'
    }
  }.freeze

  def apply_rule(rule_name, html)
    transformations = RULE_TRANSFORMATIONS[rule_name.to_sym]
    raise ArgumentError, "Unknown rule: #{rule_name}" unless transformations

    if transformations.key?(html)
      transformations[html]
    else
      html
    end
  end

  def find_issues(rule_name, html, resource_prefix)
    rule_class = RULE_MAP[rule_name.to_sym]
    raise ArgumentError, "Unknown rule: #{rule_name}" unless rule_class

    document = Nokogiri::HTML::DocumentFragment.parse(html)
    extend_nokogiri_with_dom_adapter(document)

    issues = []
    # For most rules, we want to check all elements. For performance, you could scope this if needed.
    document.traverse do |elem|
      next unless elem.respond_to?(:tag_name) && elem.tag_name # skip text nodes, comments, etc.

      result = rule_class.test(elem)
      if result
        # Compose a similar issue hash as before
        issues << {
          element_type: elem.tag_name,
          rule_id: rule_class.name.demodulize.underscore,
          data: { id: "#{resource_prefix}-#{rule_class.id}-1" },
          resource_prefix:,
          message: result.is_a?(String) ? result : rule_class.message
        }
      end
    end
    issues
  end

  def fix_issue(rule_name, html, selector, value)
    rule_class = RULE_MAP[rule_name.to_sym]
    raise ArgumentError, "Unknown rule: #{rule_name}" unless rule_class

    document = Nokogiri::HTML::DocumentFragment.parse(html)
    extend_nokogiri_with_dom_adapter(document)
    element = document.at_xpath(selector)

    if element
      rule_class.fix!(element, value)
    else
      raise ArgumentError, "Element not found for selector: '" + selector + "', please fix test case. HTML was '" + html + "'"
    end

    document.to_html
  end
end
