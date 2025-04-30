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

  def self.check_content_accessibility(html_content, rules)
    return NO_ACCESSIBILITY_ISSUES.dup if html_content.blank? || !html_content.include?("<")

    begin
      doc = Nokogiri::HTML5.fragment(html_content, nil, **CanvasSanitize::SANITIZE[:parser_options])
      extend_nokogiri_with_dom_adapter(doc)

      issues = []

      rules.each do |rule_class|
        rule_issues = []

        doc.children.each do |node|
          next unless node.is_a?(Nokogiri::XML::Element)

          walk_dom_tree(node) do |element|
            next if rule_class.test(element)

            violation_id = SecureRandom.uuid

            rule_issues << {
              id: violation_id,
              rule_id: rule_class.id,
              element: element.name,
              message: rule_class.message,
              why: rule_class.why,
              path: element_path(element),
              severity: "error",
              issue_url: rule_class.link,
            }
          rescue => e
            Rails.logger.error "Accessibility check problem encountered with rule '#{rule_class.id}'. HTML fragment was '#{element}'. Error is #{e.message}"
            Rails.logger.error e.backtrace.join("\n")
          end
        end
        issues.concat(rule_issues)
      end

      unique_issues = []
      seen_paths = Set.new

      issues.each do |issue|
        issue_key = "#{issue[:rule_id]}-#{issue[:element]}-#{issue[:path]}"
        unless seen_paths.include?(issue_key)
          unique_issues << issue
          seen_paths.add(issue_key)
        end
      end

      count = unique_issues.size
      severity = issue_severity(count)

      { count:, severity:, issues: unique_issues }
    rescue => e
      Rails.logger.error "Accessibility check problem encountered. Returning empty report to UI. Error was: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      NO_ACCESSIBILITY_ISSUES.dup
    end
  end

  def self.walk_dom_tree(node, &block)
    return unless node

    if node.is_a?(Nokogiri::XML::Element)
      yield(node)

      node.children.each do |child|
        walk_dom_tree(child, &block)
      end
    end
  end

  def self.element_path(element)
    path = []
    current = element

    while current && current.name != "document"
      identifier = current.name
      identifier += "##{current["id"]}" if current["id"]
      identifier += ".#{current["class"]}" if current["class"]
      path.unshift(identifier)
      current = current.parent
    end

    path.join(" > ")
  end

  def self.issue_severity(count)
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

  def self.extend_nokogiri_with_dom_adapter(doc)
    doc.singleton_class.class_eval do
      define_method(:tag_name) { "html" }
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

    doc.traverse do |node|
      if node.is_a?(Nokogiri::XML::Element)
        node.singleton_class.class_eval do
          define_method(:tag_name) { name.downcase }
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
      elsif node.is_a?(Nokogiri::XML::Text)
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
    end

    doc
  end
end
