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

module Accessibility
  module Rules
    class TableCaptionRuleHelper
      def self.build_system_prompt
        <<~TEXT.strip
          You are an expert in Web Accessibility (A11y) and Educational Content Design.

          Your task is to write a concise, professional title (caption) for an HTML table based on the provided context and data. This caption is for screen-reader users to understand the table's purpose at a glance.
        TEXT
      end

      def self.build_user_message(resource_context, table_html)
        <<~TEXT.strip
          ### Step-by-Step Logic:
          1. **Identify the "Noun":** Look deep into the context for the specific subject, entity, or geographic location being discussed.
            - *Example:* Use **"Galápagos Finch Observations"** instead of "bird data."
            - *Example:* Use **"Industrial Revolution Textile Exports"** instead of "history stats."
            - *Example:* Use **"Corporate Headquarters Renovations"** instead of "construction."

          2. **Identify the "Document Type":** Use standard academic, scientific, or business terminology to describe the data structure.
            - *Example:* If it shows dates and measurements, it is an **"Observation Log"**.
            - *Example:* If it shows loan payments over time, it is an **"Amortization Schedule"**.
            - *Example:* If it shows tasks and deadlines, it is a **"Project Timeline"**.

          3. **Synthesize the Title:** Combine these into the formal naming convention: **[Document Type] for [Specific Subject]**.

          ### Strict Constraints:
          - **No Filler:** Do NOT start with "Table showing...", "A table of...", or "This data includes...".
          - **Specifics Only:** Do NOT use generic words like "Information," "Data," or "Details" if a more specific noun exists in the context.
          - **Length:** Provide ONLY the text of the caption. Keep it to one brief, punchy sentence.

          ### Input Data:
          <resource_context>
          #{resource_context}
          </resource_context>

          <table_html>
          #{table_html}
          </table_html>
        TEXT
      end

      def self.extract_resource_context(path, html_content, resource_title)
        context_parts = []

        context_parts << "Resource Title: #{resource_title}" if resource_title.present?

        latest_section = extract_latest_section_before(path, html_content)
        if latest_section
          context_parts << "Section Title: #{latest_section[:title]}" if latest_section[:title].present?
          context_parts << "Section Content: #{latest_section[:content]}" if latest_section[:content].present?
        end

        context_parts.join("\n\n")
      end

      def self.extract_latest_section_before(path, html_content)
        return nil unless html_content.present?

        doc = Nokogiri::HTML.fragment(html_content)

        target_table = doc.at_xpath(path)
        return nil unless target_table

        preceding_headings = target_table.xpath("preceding::h1 | preceding::h2 | preceding::h3 | preceding::h4 | preceding::h5 | preceding::h6")

        return nil if preceding_headings.empty?

        section_heading_node = preceding_headings.last
        section_title = section_heading_node.text.strip

        following_text_elements = section_heading_node.xpath("following::*[self::p or self::div or self::li or self::blockquote or self::dd or self::td]")

        section_content = nil
        following_text_elements.each do |elem|
          if target_table.xpath("preceding::*").include?(elem) && elem.text.strip.present?
            section_content = elem.text.strip.truncate(500)
            break
          end
        end

        {
          title: section_title,
          content: section_content
        }
      end

      def self.prepend(parent, child)
        if parent.first_element_child
          parent.first_element_child.add_previous_sibling(child)
        else
          parent.add_child(child)
        end
      end

      def self.extract_table_preview(elem, rows_count = 5)
        return nil unless elem.name.downcase == "table"

        # Clone the table to avoid modifying the original
        table = elem.dup

        # Find all body rows (not in thead)
        data_rows = []
        table.css("tr").each do |row|
          # Skip header rows (in thead or containing th elements when there's no thead)
          next if row.parent && row.parent.name == "thead"

          data_rows << row
        end

        # Keep only the first rows_count rows
        rows_to_remove = data_rows[rows_count..]
        rows_to_remove&.each(&:remove) if rows_to_remove&.any?

        # Return the preview table
        table
      end
    end
  end
end
