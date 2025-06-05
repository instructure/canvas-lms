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

module AccessibilityControllerHelper
  NO_ACCESSIBILITY_ISSUES = { count: 0, severity: "none", issues: [] }.freeze

  class << self
    def check_content_accessibility(html_content, rules)
      return NO_ACCESSIBILITY_ISSUES.dup if html_content.blank? || !html_content.include?("<")

      begin
        doc = Nokogiri::HTML5.fragment(html_content, nil, **CanvasSanitize::SANITIZE[:parser_options])
        extend_nokogiri_with_dom_adapter(doc)

        issues = []

        rules.each_value do |rule_class|
          doc.children.each do |node|
            next unless node.is_a?(Nokogiri::XML::Element)

            walk_dom_tree(node) do |element|
              next if rule_class.test(element)

              issues << build_issue(rule_class, element: element.name, path: element_path(element))
            rescue => e
              log_rule_error(rule_class, element, e)
            end
          end
        end

        process_issues(issues)
      rescue => e
        log_general_error(e)
        NO_ACCESSIBILITY_ISSUES.dup
      end
    end

    def check_pdf_accessibility(pdf, rules)
      issues = []

      begin
        pdf_reader = PDF::Reader.new(pdf.open)

        rules.each do |rule_class|
          next if rule_class.test(pdf_reader)

          issues << build_issue(rule_class, element: "PDF Document")
        rescue => e
          log_rule_error(rule_class, "PDF Document", e)
        end

        process_issues(issues)
      rescue => e
        log_general_error(e)
        NO_ACCESSIBILITY_ISSUES.dup
      end
    end

    def walk_dom_tree(node, &block)
      return unless node

      if node.is_a?(Nokogiri::XML::Element)
        yield(node)

        node.children.each do |child|
          walk_dom_tree(child, &block)
        end
      end
    end

    def element_path(element)
      path = []
      current = element

      while current && current.name != "document"
        break if current.name == "#document-fragment"

        identifier = current.name

        if current["id"]
          identifier += "[@id='#{current["id"]}']"
        elsif current["class"]
          classes = current["class"].split.map { |cls| "contains(concat(' ', normalize-space(@class), ' '), ' #{cls} ')" }.join(" and ")
          identifier += "[#{classes}]" unless classes.empty?
        end

        siblings = current.parent ? current.parent.xpath("./#{current.name}") : []
        index = siblings.index(current) + 1
        identifier += "[#{index}]" if siblings.size > 1

        path.unshift(identifier)
        current = current.parent
      end

      "./" + path.join("/")
    end

    def issue_severity(count)
      if count > 30
        "high"
      elsif count > 2
        "medium"
      elsif count > 0
        "low"
      else
        "none"
      end
    end

    def extend_nokogiri_with_dom_adapter(doc)
      extend_document(doc)
      doc.traverse do |node|
        extend_nokogiri_element(node) if node.is_a?(Nokogiri::XML::Element)
        extend_nokogiri_text(node) if node.is_a?(Nokogiri::XML::Text)
      end

      doc
    end

    def extend_nokogiri_element(node)
      return unless node.is_a?(Nokogiri::XML::Element)

      node.singleton_class.class_eval do
        define_method(:tag_name) { @tag_name || name.downcase }

        alias_method :text_content, :text

        define_method(:get_attribute) { |attr| self[attr] }
        define_method(:attribute?) { |attr| key?(attr) }
        define_method(:set_attribute) { |attr, value| self[attr] = value }

        unless method_defined?(:original_remove_attribute)
          alias_method :original_remove_attribute, :remove_attribute
          define_method(:remove_attribute) { |attr| original_remove_attribute(attr) }
        end

        alias_method :parent_node, :parent
        alias_method :parent_element, :parent
        alias_method :child_nodes, :children
        alias_method :query_selector, :at_css
        alias_method :query_selector_all, :css

        define_method(:first_element_child) { children.find(&:element?) }

        define_method(:next_element_sibling) do
          sibling = next_sibling
          while sibling && !sibling.element?
            sibling = sibling.next_sibling
          end
          sibling
        end

        define_method(:previous_element_sibling) do
          sibling = previous_sibling
          while sibling && !sibling.element?
            sibling = sibling.previous_sibling
          end
          sibling
        end

        define_method(:node_type) { 1 }
      end
    end

    def extend_nokogiri_text(node)
      node.singleton_class.class_eval do
        define_method(:node_type) { 3 }
        define_method(:text_content) { content }
        define_method(:tag_name) { "#text" }
        define_method(:get_attribute) { |_| nil }
        define_method(:attribute?) { |_| false }
        define_method(:set_attribute) { |_, _| nil }
        define_method(:remove_attribute) { |_| nil }
        define_method(:parent_element) { parent }
        define_method(:parent_node) { parent }
        define_method(:child_nodes) { [] }
        define_method(:query_selector) { |_| nil }
        define_method(:query_selector_all) { |_| [] }
        define_method(:first_element_child) { nil }
        define_method(:next_element_sibling) do
          sibling = next_sibling
          while sibling && !sibling.element?
            sibling = sibling.next_sibling
          end
          sibling
        end
        define_method(:previous_element_sibling) do
          sibling = previous_sibling
          while sibling && !sibling.element?
            sibling = sibling.previous_sibling
          end
          sibling
        end
      end
    end

    def extend_document(doc)
      doc.singleton_class.class_eval do
        define_method(:tag_name) { @tag_name || "html" }
        define_method(:text_content) { text }
        define_method(:get_attribute) { |attr| self[attr] }
        define_method(:attribute?) { |attr| key?(attr) }
        define_method(:set_attribute) { |attr, value| self[attr] = value }
        define_method(:parent_element) { nil }
        define_method(:parent_node) { nil }
        define_method(:node_type) { 9 } # Document node type is 9
        define_method(:query_selector) { |selector| at_css(selector) }
        define_method(:query_selector_all) { |selector| css(selector) }
        define_method(:child_nodes) { children }
        define_method(:first_element_child) { children.find(&:element?) }
      end
    end

    private

    def build_issue(rule_class, element:, path: nil)
      {
        id: SecureRandom.uuid,
        rule_id: rule_class.id,
        element:,
        message: rule_class.message,
        why: rule_class.why,
        path:,
        severity: "error",
        issue_url: rule_class.link
      }
    end

    def process_issues(issues)
      unique_issues = issues.uniq { |issue| "#{issue[:rule_id]}-#{issue[:element]}-#{issue[:path]}" }
      count = unique_issues.size
      severity = issue_severity(count) # Calls the public class method issue_severity

      { count:, severity:, issues: unique_issues }
    end

    def log_rule_error(rule_class, element, error)
      Rails.logger.error "Accessibility check problem encountered with rule '#{rule_class.id}'. Element was '#{element}'. Error is #{error.message}"
      Rails.logger.error error.backtrace.join("\n")
    end

    def log_general_error(error)
      Rails.logger.error "Accessibility check problem encountered. Returning empty report to UI. Error was: #{error.message}"
      Rails.logger.error error.backtrace.join("\n")
    end
  end
end
