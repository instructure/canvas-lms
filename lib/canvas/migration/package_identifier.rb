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

module Canvas::Migration
  class UnsupportedPackage < Error; end

  class PackageIdentifier
    include Canvas::Migration::XMLHelper
    attr_reader :type, :converter

    COMMON_CARTRIDGE_REGEX = /IMS(?: Thin)? Common Cartridge/i

    def initialize(archive)
      @archive = archive
    end

    def get_converter
      @type = identify_package
      @converter = find_converter
    end

    def identify_package
      if @archive.path.ends_with?("xml")
        return check_flat_xml_file
      end

      if @archive.find_entry("AngelManifest.xml")
        :angel_7_4
      elsif @archive.find_entry("angelData.xml")
        :angel_7_3
      elsif @archive.find_entry("moodle.xml")
        :moodle_1_9
      elsif @archive.find_entry("moodle_backup.xml")
        :moodle_2
      elsif @archive.find_entry("imsmanifest.xml")
        data = @archive.read("imsmanifest.xml")
        doc = create_xml_doc(data)

        if COMMON_CARTRIDGE_REGEX.match?(get_node_val(doc, "metadata schema"))
          if doc.at_css(%(resources resource[href="#{CC::CCHelper::COURSE_SETTINGS_DIR}/#{CC::CCHelper::SYLLABUS}"] file[href="#{CC::CCHelper::COURSE_SETTINGS_DIR}/#{CC::CCHelper::COURSE_SETTINGS}"])) ||
             doc.at_css(%(resources resource[href="#{CC::CCHelper::COURSE_SETTINGS_DIR}/#{CC::CCHelper::CANVAS_EXPORT_FLAG}"]))
            :canvas_cartridge
          elsif get_node_val(doc, "metadata schemaversion") == "1.0.0"
            :common_cartridge_1_0
          elsif get_node_val(doc, "metadata schemaversion") == "1.1.0"
            :common_cartridge_1_1
          elsif get_node_val(doc, "metadata schemaversion") == "1.2.0"
            :common_cartridge_1_2
          elsif get_node_val(doc, "metadata schemaversion") == "1.3.0"
            :common_cartridge_1_3
          end
        elsif has_namespace(doc, "http://www.blackboard.com/content-packaging")
          :bb_learn
        elsif has_namespace(doc, "http://desire2learn.com/xsd/d2lcp")
          :d2l
        elsif has_namespace(doc, "http://www.webct.com/xsd/cisv3")
          :webct # only quizzes are supported
        elsif has_namespace(doc, "http://www.webct.com/IMS")
          :webct_4_1
        elsif has_namespace(doc, "http://www.adlnet.org/xsd/adl_cp_rootv1p1")
          :scorm_1_1
        elsif has_namespace(doc, "http://www.adlnet.org/xsd/adlcp_rootv1p2")
          :scorm_1_2
        elsif has_namespace(doc, "http://www.adlnet.org/xsd/adlcp_v1p3")
          :scorm_1_3 # scorm 2004
        elsif doc.at_css("resources resource[type^=ims_qti]") ||
              doc.at_css("resources resource[type^=imsqti]")
          :qti
        else
          # generic IMS Content Package?
          :unknown_ims_cp_package
        end
      else
        :unknown
      end
    rescue
      # Not a valid archive file
      raise Canvas::Migration::Error,
            I18n.t(:package_error,
                   "Error identifying package type: %{error}",
                   error: $!.message),
            $!.backtrace
    end

    private

    # Common Cartridge 1.3 supports having just a single xml file
    # if it's not CC 1.3 then we don't know how to handle it
    def check_flat_xml_file
      doc = create_xml_doc(File.read(@archive.file))
      if get_node_val(doc, "metadata schema") =~ COMMON_CARTRIDGE_REGEX &&
         get_node_val(doc, "metadata schemaversion") == "1.3.0"
        :common_cartridge_1_3
      else
        :unknown
      end
    end

    def has_namespace(node, namespace)
      node.namespaces.values.any? { |ns| ns =~ /#{namespace}/i }
    end

    def find_converter
      if (plugin = Canvas::Plugin.all_for_tag(:export_system).find { |p| p.settings[:provides] && p.settings[:provides][@type] })
        return plugin.settings[:provides][@type]
      end

      raise Canvas::Migration::UnsupportedPackage, I18n.t(:unsupported_package, "Unsupported content package")
    end
  end
end
