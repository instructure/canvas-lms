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
module CC
  class Manifest
    include CCHelper

    attr_accessor :exporter, :weblinks, :basic_ltis
    attr_reader :options
    delegate :add_error, :set_progress, :export_object?, :export_symbol?, :for_course_copy, :add_item_to_export, :add_exported_asset, :user, :create_key, :to => :exporter

    def initialize(exporter, opts = {})
      @exporter = exporter
      @file = nil
      @document = nil
      @resource = nil
      @weblinks = []
      @options = opts
    end

    def course
      @exporter.course
    end

    def export_dir
      @exporter.export_dir
    end

    def zip_file
      @exporter.zip_file
    end

    def close
      @file.close if @file
      @document = nil
      @file
    end

    def create_document
      @file = File.new(File.join(export_dir, MANIFEST), 'w')
      @document = Builder::XmlMarkup.new(:target=>@file, :indent=>2)
      @document.instruct!
      @document.manifest({"identifier" => create_key(course, "common_cartridge_")}.merge(namespace_hash)) do |manifest_node|

        manifest_node.metadata do |md|
          create_metadata(md)
        end
        set_progress(5)

        begin
          Organization.create_organizations(self, manifest_node)
        rescue
          add_error(I18n.t('course_exports.errors.organization', "Failed to generate organization structure."), $!)
        end
        set_progress(10)

        begin
          @resource = Resource.create_resources(self, manifest_node)
        rescue
          add_error(I18n.t('course_exports.errors.resources', "Failed to link some resources."), $!)
        end
      end #manifest

      # write any errors to the manifest file
      if @exporter.errors.length > 0
        @document.comment! I18n.t('course_exports.errors_list_message', "Export errors for export %{export_id}:", :export_id => @exporter.export_id)
        @exporter.errors.each do |error|
          @document.comment! error.first
        end
      end
    end

    def referenced_files
      @resource ? @resource.referenced_files : {}
    end

    def create_metadata(md)
      md.schema "IMS Common Cartridge"
      md.schemaversion cc_version
      md.lomimscc :lom do |lom|
        lom.lomimscc :general do |general|
          general.lomimscc :title do |title|
            title.lomimscc :string, course.name
          end
        end
        lom.lomimscc :lifeCycle do |general|
          general.lomimscc :contribute do |title|
            title.lomimscc :date do |date|
              date.lomimscc :dateTime, ims_date
            end
          end
        end
        lom.lomimscc :rights do |rights|
          rights.lomimscc :copyrightAndOtherRestrictions do |node|
            node.lomimscc :value, "yes"
          end
          rights.lomimscc :description do |desc|
            desc.lomimscc :string, "#{course.license_data[:readable_license]} - #{course.license_data[:license_url]}"
          end
        end
      end
    end

    def cc_version
      @cc_version ||= case @options[:version]
                        when "1.3"
                          "1.3.0"
                        else
                          "1.1.0"
                      end
    end

    def namespace_hash
      @namespace_hash ||= if cc_version == "1.3.0"
        {
          "xmlns" => "http://www.imsglobal.org/xsd/imsccv1p3/imscp_v1p1",
          "xmlns:lom" => "http://ltsc.ieee.org/xsd/imsccv1p3/LOM/resource",
          "xmlns:lomimscc" => "http://ltsc.ieee.org/xsd/imsccv1p3/LOM/manifest",
          "xmlns:cpx" => "http://www.imsglobal.org/xsd/imsccv1p3/imscp_extensionv1p2",
          "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation" => "http://ltsc.ieee.org/xsd/imsccv1p3/LOM/resource http://www.imsglobal.org/profile/cc/ccv1p3/LOM/ccv1p3_lomresource_v1p0.xsd http://www.imsglobal.org/xsd/imsccv1p3/imscp_v1p1 http://www.imsglobal.org/profile/cc/ccv1p3/ccv1p3_imscp_v1p2_v1p0.xsd http://ltsc.ieee.org/xsd/imsccv1p3/LOM/manifest http://www.imsglobal.org/profile/cc/ccv1p3/LOM/ccv1p3_lommanifest_v1p0.xsd http://www.imsglobal.org/xsd/imsccv1p3/imscp_extensionv1p2 http://www.imsglobal.org/profile/cc/ccv1p3/ccv1p3_cpextensionv1p2_v1p0.xsd"
        }.freeze
      else
        {
          "xmlns" => "http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1",
          "xmlns:lom"=>"http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource",
          "xmlns:lomimscc"=>"http://ltsc.ieee.org/xsd/imsccv1p1/LOM/manifest",
          "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
          "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1 http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imscp_v1p2_v1p0.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lomresource_v1p0.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/manifest http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lommanifest_v1p0.xsd"
        }.freeze
      end
    end

  end
end
