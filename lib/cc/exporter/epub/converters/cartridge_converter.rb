#
# Copyright (C) 2015 - present Instructure, Inc.
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

module CC::Exporter::Epub::Converters
  class CartridgeConverter < Canvas::Migration::Migrator
    include CC::CCHelper
    include Canvas::Migration::XMLHelper
    include WikiEpubConverter
    include AssignmentEpubConverter
    include TopicEpubConverter
    include QuizEpubConverter
    include ModuleEpubConverter
    include FilesConverter
    include MediaConverter

    MANIFEST_FILE = "imsmanifest.xml"

    ALLOWED_GRADING_TYPES = {
      "pass_fail" => I18n.t("Pass/Fail"),
      "percent" => I18n.t("Percentage"),
      "letter_grade" => I18n.t("Letter Grade"),
      "gpa_scale" => I18n.t("GPA Scale"),
      "points" => I18n.t("Points"),
      "not_graded" => I18n.t("Not Graded")
    }.freeze

    SUBMISSION_TYPES = {
      "online_quiz" => I18n.t("Quiz"),
      "online_upload" => I18n.t("Online Upload"),
      "online_text_entry" => I18n.t("Online Text Entry"),
      "online_url" => I18n.t("Online URL"),
      "discussion_topic" => I18n.t("Discussion Topic"),
      "media_recording" => I18n.t("Media Recording"),
      "on_paper" => I18n.t("On Paper"),
      "external_tool" => I18n.t("External Tool")
    }.freeze

    # settings will use these keys: :course_name, :base_download_dir
    def initialize(settings)
      super(settings, "cc")
      @course = @course.with_indifferent_access
      @resources = {}
      @course[:syllabus] = []
      @resource_nodes_for_flat_manifest = {}
      @unsupported_files = []
    end
    attr_reader :unsupported_files

    def update_syllabus(content)
      return unless content[:identifier]
      @course[:syllabus] << {
        title: content[:title],
        identifier: content[:identifier],
        due_at: content[:due_at],
        href: content[:href]
      }
    end

    def organize_syllabus
      due_anytime, has_due_date = @course[:syllabus].partition { |item| item[:due_at].nil? }
      @course[:syllabus] = has_due_date.sort_by{|item| item[:due_at]} + due_anytime
    end

    def include_item?(meta_node, workflow_state='published')
      get_node_val(meta_node, 'workflow_state') == workflow_state &&
      !get_bool_val(meta_node, 'module_locked')
    end

    # exports the package into the intermediary json
    def export(export_type)
      unzip_archive

      @manifest = open_file(@package_root.item_path(MANIFEST_FILE))
      get_all_resources(@manifest)

      @course[:title] = get_node_val(@manifest, "string")
      @course[:files], @unsupported_files = convert_files(export_type)

      @course[:pages] = convert_wikis
      @course[:assignments] = convert_assignments
      @course[:topics], @course[:announcements] = convert_topics
      @course[:quizzes] = convert_quizzes
      @course[:modules] = convert_modules

      save_to_file
      organize_syllabus
      @course
    end
  end
end
