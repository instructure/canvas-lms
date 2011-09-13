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
module CC::Importer::Canvas
  class Converter < Canvas::Migration::Migrator
    include CC::Importer
    include CourseSettings
    include WikiConverter
    include AssignmentConverter
    include TopicConverter
    include WebcontentConverter
    include QuizConverter

    MANIFEST_FILE = "imsmanifest.xml"

    # settings will use these keys: :course_name, :base_download_dir
    def initialize(settings)
      super(settings, "cc")
      @course = @course.with_indifferent_access
    end

    # exports the package into the intermediary json
    def export(to_export = SCRAPE_ALL_HASH)
      to_export = SCRAPE_ALL_HASH.merge to_export if to_export
      unzip_archive
      
      @manifest = open_file(File.join(@unzipped_file_path, MANIFEST_FILE))
      convert_all_course_settings
      @course[:wikis] = convert_wikis
      @course[:assignments] = convert_assignments
      @course[:discussion_topics] = convert_topics
      @course[:file_map] = create_file_map
      package_course_files
      convert_quizzes
      
      #close up shop
      save_to_file
      delete_unzipped_archive
      @course
    end

  end
end
