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
      def initialize(manifest)
        @manifest = manifest
      end

      def write_new_quizzes_content
        return unless new_quizzes_export_file_url

        tmp_file = Tempfile.new
        tmp_file.binmode
        tmp_file.write(new_quizzes_export_file.read)
        tmp_file.flush

        Dir.mktmpdir do |tmpdir|
          CanvasUnzip.extract_archive(tmp_file.path, tmpdir)
          Dir.glob(File.join(tmpdir, "{non_cc_assessments/*,**/assessment_meta.xml,**/assessment_qti.xml,Uploaded Media/*}")).map do |f|
            file_path = f.sub("#{tmpdir}/", "")
            file_dir = file_path.split("/").first
            file_name = file_path.split("/").last

            dest_dir = File.join(export_dir, file_dir)
            FileUtils.mkdir_p(dest_dir)

            File.binwrite(File.join(dest_dir, file_name), File.read(f))
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
    end
  end
end
