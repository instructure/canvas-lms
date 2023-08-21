# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "nokogiri"

module Canvas::Migration
  module XMLHelper
    def convert_to_timestamp(string)
      return nil if string.nil? || string == ""

      Time.use_zone("UTC") { Time.zone.parse(string).to_i * 1000 } rescue nil
    end

    def get_node_att(node, selector, attribute, default = nil)
      if (node = node.at_css(selector))
        return node[attribute]
      end

      default
    end

    def get_node_val(node, selector, default = nil)
      node.at_css(selector) ? node.at_css(selector).text : default
    end

    # You can't do a css selector that only looks for direct
    # descendants of the current node, so you have to iterate
    # over the children and see if it's there.
    def get_val_if_child(node, name)
      if (child = node.children.find { |c| c.name == name })
        return child.text
      end

      nil
    end

    def get_unescaped_html_val(node, selector)
      ::CGI.unescapeHTML(get_node_val(node, selector, ""))
    end

    def get_bool_val(node, selector, default = nil)
      node.at_css(selector) ? /true|yes|t|y|1/i.match?(node.at_css(selector).text) : default
    end

    def get_int_val(node, selector, default = nil)
      val = get_node_val(node, selector, default)
      return default if val.nil? || val == "" || val.nil?

      begin
        val = val.to_i
      rescue
        val = default
      end
      val
    end

    def get_float_val(node, selector, default = nil)
      val = get_node_val(node, selector, default)
      return default if val == "" || val.nil?

      begin
        val = val.to_f
      rescue
        val = default
      end
      val
    end

    def get_time_val(node, selector, default = nil)
      convert_to_timestamp(get_node_val(node, selector, default))
    end

    # Gets the node value and changed forward slashes to back slashes
    def get_file_path(node, selector)
      path = get_node_val(node, selector)
      path = path.tr("\\", "/") if path
      path
    end

    def open_file(path)
      File.exist?(path) ? ::Nokogiri::HTML(File.open(path)) : nil
    end

    def open_file_html5(path)
      File.exist?(path) ? ::Nokogiri::HTML5(File.open(path)) : nil
    end

    def open_file_xml(path)
      File.exist?(path) ? create_xml_doc(File.open(path)) : nil
    end

    def create_xml_doc(string_or_io)
      doc = ::Nokogiri::XML(string_or_io)
      if doc.encoding != "UTF-8"
        begin
          doc.at_css("*")
        rescue ArgumentError => e
          # ruby 2.2
          raise unless /^invalid byte sequence/.match?(e.message)

          doc.encoding = "UTF-8"
        rescue Encoding::CompatibilityError
          # ruby 2.1
          doc.encoding = "UTF-8"
        end
      end
      doc
    end
  end
end
