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

module Canvas::XMLHelper
  def convert_to_timestamp(string)
    return nil if string.nil? or string == ""
    Time.parse(string).to_i * 1000 rescue nil
  end

  def get_node_val(node, selector, default=nil)
    node.at_css(selector) ? node.at_css(selector).text : default
  end

  def get_unescaped_html_val(node, selector)
    ::CGI.unescapeHTML(get_node_val(node, selector, ''))
  end

  def get_bool_val(node, selector, default=nil)
    node.at_css(selector) ? (node.at_css(selector).text =~ /true|yes|t|y|1/i ? true : false) : default
  end

  def get_int_val(node, selector, default=nil)
    val = get_node_val(node, selector, default)
    return default if val.nil? || val == ""
    begin
      val = val.to_i
    rescue
      val = nil
    end
    val
  end

  def get_float_val(node, selector, default=nil)
    val = get_node_val(node, selector, default)
    return default if val == ""
    begin
      val = val.to_f
    rescue
      val = nil
    end
    val
  end

  def get_time_val(node, selector, default=nil)
    convert_to_timestamp(get_node_val(node, selector, default))
  end

  #Gets the node value and changed forward slashes to back slashes
  def get_file_path(node, selector)
    path = get_node_val(node, selector)
    path = path.gsub('\\', '/') if path
    path
  end

  def open_file(path)
    ::Nokogiri::HTML(open(path))
  end

  def open_file_xml(path)
    ::Nokogiri::XML(open(path))
  end
end