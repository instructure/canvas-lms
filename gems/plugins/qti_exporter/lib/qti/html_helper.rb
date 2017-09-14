#
# Copyright (C) 2016 - present Instructure, Inc.
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

require 'nokogiri'
require 'sanitize'

module Qti
  module HtmlHelper
    WEBCT_REL_REGEX = "/webct/RelativeResourceManager/Template/"

    def sanitize_html_string(string, remove_extraneous_nodes=false)
      string = escape_unmatched_brackets(string)
      sanitize_html!(Nokogiri::HTML::DocumentFragment.parse(string), remove_extraneous_nodes)
    end

    def sanitize_html!(node, remove_extraneous_nodes=false)
      # root may not be an html element, so we just sanitize its children so we
      # don't blow away the whole thing
      node.children.each do |child|
        Sanitize.clean_node!(child, CanvasSanitize::SANITIZE)
      end

      # replace any file references with the migration id of the file
      if @path_map
        attrs = ['rel', 'href', 'src', 'data', 'value']
        node.search("*").each do |subnode|
          attrs.each do |attr|
            if subnode[attr]
              val = URI.unescape(subnode[attr])
              if val.start_with?(WEBCT_REL_REGEX)
                # It's from a webct package so the references may not be correct
                # Take a path like: /webct/RelativeResourceManager/Template/Imported_Resources/qti web/f11g3_r.jpg
                # Reduce to: Imported_Resources/qti web/f11g3_r.jpg
                val.gsub!(WEBCT_REL_REGEX, '')
                val.gsub!("RelativeResourceManager/Template/", "")

                # Sometimes that path exists, sometimes the desired file is just in the top-level with the .xml files
                # So check for the file starting with the full relative path, going down to just the file name
                paths = val.split("/")
                paths.length.times do |i|
                  if mig_id = find_best_path_match(paths[i..-1].join('/'))
                    subnode[attr] = "#{CC::CCHelper::OBJECT_TOKEN}/attachments/#{mig_id}"
                    break
                  end
                end
              else
                val.gsub!(/\$[A-Z_]*\$/, '') # remove any path tokens like $TOKEN_EH$
                # try to find the file by exact path match. If not found, try to find best match
                if mig_id = find_best_path_match(val)
                  subnode[attr] = "#{CC::CCHelper::OBJECT_TOKEN}/attachments/#{mig_id}"
                end
              end
            end
          end
        end
      end

      if remove_extraneous_nodes
        while true
          node.children.each do |child|
            break unless child.text? && child.text =~ /\A\s+\z/ || child.element? && child.name.downcase == 'br'
            child.remove
          end

          node.children.reverse_each do |child|
            break unless child.text? && child.text =~ /\A\s+\z/ || child.element? && child.name.downcase == 'br'
            child.remove
          end
          break unless node.children.size == 1 && ['p', 'div', 'span'].include?(node.child.name)
          break if !node.child.attributes.empty? && !has_known_meta_class(node.child)

          node = node.child
        end
      end
      yield node if block_given?

      text = node.inner_html.strip
      # Clear WebCT-specific relative paths
      text.gsub!(WEBCT_REL_REGEX, '')
      text.gsub(%r{/?webct/urw/[^/]+/RelativeResourceManager\?contentID=(\d*)}, "$CANVAS_OBJECT_REFERENCE$/attachments/\\1")
    end

    def clear_html(text)
      text.gsub(/<\/?[^>\n]*>/, "").gsub(/&#\d+;/) {|m| m[2..-1].to_i.chr(text.encoding) rescue '' }.gsub(/&\w+;/, "").gsub(/(?:\\r\\n)+/, "\n")
    end

    def find_best_path_match(path)
      @path_map[path] || @path_map[@sorted_paths.find{|k| k.end_with?(path)}]
    end

    # try to escape unmatched '<' and '>' characters because some people don't format their QTI correctly...
    def escape_unmatched_brackets(string)
      unmatched = false
      lcount = 0
      string.scan(/[\<\>]/) do |s|
        if s == ">"
          if lcount == 0
            unmatched = true
          else
            lcount -= 1
          end
        else
          lcount += 1
        end
      end
      return string unless unmatched || lcount > 0
      string.split(/(\<[^\<\>]*\>)/m).map do |sub|
        if sub.strip.start_with?("<") && sub.strip.end_with?(">")
          sub
        else
          sub.gsub("<", "&lt;").gsub(">", "&gt;")
        end
      end.join
    end

    # returns a tuple of [text, html]
    # html is null if it's not an html blob
    def detect_html(node)
      if text_node = node.at_css('div.text')
        return [text_node.text.strip, nil]
      end

      text = clear_html(node.text.gsub(/\s+/, " ")).strip
      html_node = node.at_css('div.html') || (node.name.downcase == 'div' && node['class'] =~ /\bhtml\b/) || @flavor == Qti::Flavors::ANGEL
      is_html = (html_node && @flavor == Qti::Flavors::CANVAS) ? true : false
      # heuristic for detecting html: the sanitized html node is more than just a container for a single text node
      sanitized = sanitize_html!(html_node ? Nokogiri::HTML::DocumentFragment.parse(node.text) : node, true) { |s| is_html ||= !(s.children.size == 1 && s.children.first.is_a?(Nokogiri::XML::Text)) }
      if sanitized.present?
        if is_html
          html = sanitized
        else
          text = sanitized.gsub(/\s+/, " ").strip
        end
      end
      [text, html]
    end
  end
end
