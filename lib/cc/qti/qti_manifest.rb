# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
  module Qti
    class QtiManifest
      include CC::CCHelper

      attr_accessor :exporter

      delegate :add_error, :set_progress, :export_object?, :add_exported_asset, :for_course_copy, :qti_export?, :course, :user, :create_key, to: :exporter
      delegate :referenced_files, to: :@html_exporter

      def initialize(exporter)
        @exporter = exporter
        @file = nil
        @document = nil
        @html_exporter = CCHelper::HtmlContentExporter.new(@exporter.course,
                                                           @exporter.user,
                                                           key_generator: @exporter,
                                                           track_referenced_files: true,
                                                           media_object_flavor: Setting.get("exporter_media_object_flavor", nil).presence,
                                                           disable_content_rewriting: @exporter.disable_content_rewriting)
      end

      def export_dir
        @exporter.export_dir
      end

      def zip_file
        @exporter.zip_file
      end

      def close
        @file&.close
        @document = nil
        @file
      end

      def create_document
        @file = File.new(File.join(export_dir, MANIFEST), "w")
        @document = Builder::XmlMarkup.new(target: @file, indent: 2)
        @document.instruct!
        # noinspection RubyArgCount
        @document.manifest("identifier" => create_key(course, "qti_export_"),
                           "xmlns" => "http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1",
                           "xmlns:lom" => "http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource",
                           "xmlns:imsmd" => "http://www.imsglobal.org/xsd/imsmd_v1p2",
                           "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                           "xsi:schemaLocation" => "http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1 http://www.imsglobal.org/xsd/imscp_v1p1.xsd http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lomresource_v1p0.xsd http://www.imsglobal.org/xsd/imsmd_v1p2 http://www.imsglobal.org/xsd/imsmd_v1p2p2.xsd") do |manifest_node|
          manifest_node.metadata do |md|
            create_metadata(md)
          end
          set_progress(5)

          manifest_node.organizations

          manifest_node.resources do |resources|
            begin
              g = Qti::QtiGenerator.new(self, resources, @html_exporter)
              g.generate_qti_only
            rescue
              add_error(I18n.t("course_exports.errors.quizzes", "Some quizzes failed to export"), $!)
            end
            set_progress(60)

            zipper = ContentZipper.new(check_user: false)
            (@html_exporter.referenced_files.values + @html_exporter.referenced_assessment_question_files.values).each do |att|
              path = if att.context_type == "AssessmentQuestion"
                       "assessment_questions#{att.full_display_path}"
                     else
                       att.full_display_path.sub("course files/", "")
                     end
              zipper.add_attachment_to_zip(att, @exporter.zip_file, path)

              resources.resource(
                identifier: att.export_id,
                type: WEBCONTENT,
                href: path
              ) do |res|
                res.file(href: path)
              end
            end

            begin
              Resource.new(self, manifest_node, resources).add_media_objects(@html_exporter)
            rescue
              add_error(I18n.t("course_exports.errors.resources", "Failed to link some resources."), $!)
            end
          end
        end # manifest

        # write any errors to the manifest file
        unless @exporter.errors.empty?
          @document.comment! I18n.t("course_exports.errors_list_message", "Export errors for export %{export_id}:", export_id: @exporter.export_id)
          @exporter.errors.each do |error|
            @document.comment! error.first
          end
        end
      end

      def create_metadata(md)
        md.schema "IMS Content"
        md.schemaversion "1.1.3"
        md.imsmd :lom do |lom|
          lom.imsmd :general do |general|
            general.imsmd :title do |title|
              title.imsmd :string, %(QTI Quiz Export for course "#{course.name}")
            end
          end
          lom.imsmd :lifeCycle do |general|
            general.imsmd :contribute do |title|
              title.imsmd :date do |date|
                date.imsmd :dateTime, ims_date
              end
            end
          end
          lom.imsmd :rights do |rights|
            rights.imsmd :copyrightAndOtherRestrictions do |node|
              node.imsmd :value, "yes"
            end
            rights.imsmd :description do |desc|
              desc.imsmd :string, "#{course.readable_license} - #{course.license_data[:license_url]}"
            end
          end
        end
      end
    end
  end
end
