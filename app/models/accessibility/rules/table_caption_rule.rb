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
    class TableCaptionRule < Accessibility::Rule
      self.id = "table-caption"
      self.link = "https://www.w3.org/TR/WCAG20-TECHS/H39.html"

      # Accessibility::Rule methods

      def test(elem)
        return nil if elem.tag_name.downcase != "table"

        caption = elem.query_selector("caption")

        I18n.t("Table caption should be present.") if !caption || caption.text.gsub(/\s/, "") == ""
      end

      def form(_elem)
        Accessibility::Forms::TextInputField.new(
          label: I18n.t("Table caption"),
          undo_text: I18n.t("Caption added"),
          value: "",
          action: I18n.t("Add caption"),
          can_generate_fix: true,
          generate_button_label: I18n.t("Generate")
        )
      end

      def generate_fix(elem)
        llm_config = LLMConfigs.config_for("table_caption_generate")
        unless llm_config
          raise "LLM configuration not found for: table_caption_generate"
        end

        unless elem.tag_name.downcase == "table"
          raise "HTML fragment is not a table."
        end

        table_preview = self.class.extract_table_preview(elem)

        # Convert Nokogiri element to HTML string
        table_html = table_preview.to_html

        prompt, = llm_config.generate_prompt_and_options(substitutions: {
                                                           HTML_TABLE: table_html,
                                                         })

        response = InstLLMHelper.client(llm_config.model_id).chat(
          [{ role: "user", content: prompt }]
        )
        response.message[:content]
      rescue => e
        Rails.logger.error("Error generating table caption: #{e.message}")
        Rails.logger.error e.backtrace.join("\n")
        nil
      end

      def fix!(elem, value)
        raise StandardError, "Caption cannot be empty." if value.blank?

        caption = elem.at_css("caption")
        if caption
          return nil if (caption.content = value)

        else
          caption = elem.document.create_element("caption")
          self.class.prepend(elem, caption)
        end
        caption.content = value
        elem
      end

      def display_name
        I18n.t("Missing table caption")
      end

      def message
        I18n.t("Tables should include a caption describing the contents of the table.")
      end

      def why
        I18n.t("Tables should have a table caption, a title for the table to help learners understand what the table is about.")
      end

      # Helper methods

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
