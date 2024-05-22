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
module CC
  module Qti
    class NewQuizzesGenerator
      def initialize(manifest, resources_node)
        @manifest = manifest
        @resources_node = resources_node
      end

      def write_new_quizzes_content
        return unless new_quizzes_export_file_url

        tmp_file = Tempfile.new
        tmp_file.binmode
        tmp_file.write(new_quizzes_export_file.read)
        tmp_file.flush

        Dir.mktmpdir do |tmpdir|
          CanvasUnzip.extract_archive(tmp_file.path, tmpdir)

          migration_ids_map_path = File.join(tmpdir, "migration_ids_map.json")
          migration_ids_map = File.exist?(migration_ids_map_path) ? JSON.parse(File.read(migration_ids_map_path)) : {}
          migration_ids_replacer = CC::Qti::MigrationIdsReplacer.new(@manifest, migration_ids_map)
          Dir.glob(File.join(tmpdir, "{non_cc_assessments/*,**/assessment_meta.xml,**/assessment_qti.xml,Uploaded Media/*}")).map do |f|
            file_path = migration_ids_replacer.replace_in_string(f.sub("#{tmpdir}/", ""))
            file_dir = file_path.split("/").first
            file_name = file_path.split("/").last
            dest_dir = File.join(export_dir, file_dir)

            file_content = File.read(f)

            if file_name.end_with?(".xml", ".qti")
              file_content = links_replacer.replace_links(file_content)
              file_content = migration_ids_replacer.replace_in_xml(file_content)
            end

            FileUtils.mkdir_p(dest_dir)
            File.binwrite(File.join(dest_dir, file_name), file_content)
            file_path
          end
        end
      end

      def new_quizzes_export_file
        @_new_quizzes_export_file ||= URI.open(new_quizzes_export_file_url) # rubocop:disable Security/Open
      end

      def export_dir
        @manifest.export_dir
      end

      def new_quizzes_export_file_url
        @manifest.exporter.new_quizzes_export_url
      end

      def generate_qti
        file_paths = write_new_quizzes_content
        return unless file_paths

        classified_files_hash = classified_files(file_paths)
        classified_files_hash.each_key do |k|
          file_paths = classified_files_hash[k]

          next uploaded_media_resources(file_paths) if k == "uploaded_media"

          file_paths.include?("#{k}/assessment_meta.xml") ? quiz_resources(k) : bank_resources(k)
        end
      end

      def classified_files(file_paths)
        classified_files_hash = {}
        file_paths.each do |file_path|
          ident = nil
          if file_path.start_with?("non_cc_assessments/")
            ident = file_path.sub("non_cc_assessments/", "").split(".").first
          elsif file_path.end_with?("assessment_meta.xml")
            ident = file_path.split("/").first
          elsif file_path.start_with?("Uploaded Media")
            ident = "uploaded_media"
          end

          next unless ident

          classified_files_hash[ident] = [] if classified_files_hash[ident].nil?
          classified_files_hash[ident] << file_path
        end

        classified_files_hash
      end

      private

      def links_replacer
        @links_replacer ||= CC::NewQuizzesLinksReplacer.new(@manifest)
      end

      def uploaded_media_resources(file_paths)
        file_paths.each do |file_path|
          file_uuid = file_path.split("/").last
          identifier = CC::CCHelper.create_key(file_uuid)
          @resources_node.resource({ identifier:, type: "webcontent", href: file_path }) do |resource|
            resource.file({ href: file_path })
          end
        end
      end

      def quiz_resources(mig_id)
        identifier = CC::CCHelper.create_key(mig_id)
        @resources_node.resource(
          identifier: mig_id,
          type: "imsqti_xmlv1p2/imscc_xmlv1p1/assessment"
        ) do |resource|
          resource.file(href: "#{mig_id}/assessment_qti.xml")
          resource.dependency(identifierref: identifier)
        end
        @resources_node.resource(
          identifier:,
          type: "associatedcontent/imscc_xmlv1p1/learning-application-resource",
          href: "#{mig_id}/assessment_meta.xml"
        ) do |resource|
          resource.file(href: "#{mig_id}/assessment_meta.xml")
          resource.file(href: "non_cc_assessments/#{mig_id}.xml.qti")
        end
      end

      def bank_resources(mig_id)
        @resources_node.resource(
          identifier: mig_id,
          type: "associatedcontent/imscc_xmlv1p1/learning-application-resource",
          href: "non_cc_assessments/#{mig_id}.xml.qti"
        ) do |resource|
          resource.file(href: "non_cc_assessments/#{mig_id}.xml.qti")
        end
      end
    end
  end
end
