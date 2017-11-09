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
  module QuizEpubConverter
    include AssignmentEpubConverter

    def convert_quizzes
      quizzes = []
      @manifest.css('resource[type$=assessment]').each do |quiz|
        xml_path = @package_root.item_path quiz.at_css('file[href$="xml"]')['href']

        meta_node = open_file_xml(xml_path)
        ident = get_node_att(meta_node, "assessment", "ident")

        quiz_meta_path = "#{ident}/assessment_meta.xml"
        quiz_meta_link = @package_root.item_path quiz_meta_path
        quiz_meta_data = open_file_xml(quiz_meta_link)

        quiz = convert_quiz(quiz_meta_data)
        next unless get_bool_val(quiz_meta_data, 'available') &&
          !get_bool_val(quiz_meta_data, 'module_locked')
        quizzes << quiz
      end
      quizzes
    end

    def convert_quiz(quiz_meta_data)
      quiz = {}

      quiz[:title] = get_node_val(quiz_meta_data, "title")
      quiz[:description] = get_node_val(quiz_meta_data, "description")
      quiz[:due_at] = get_node_val(quiz_meta_data, "due_at")
      quiz[:lock_at] = get_node_val(quiz_meta_data, "lock_at")
      quiz[:unlock_at] = get_node_val(quiz_meta_data, "unlock_at")
      quiz[:allowed_attempts] = get_node_val(quiz_meta_data, "allowed_attempts")
      quiz[:points_possible] = get_node_val(quiz_meta_data, "points_possible")
      quiz[:position] = get_node_val(quiz_meta_data, 'position')
      quiz[:identifier] = get_node_att(quiz_meta_data, 'quiz', 'identifier')
      quiz[:href] = "quizzes.xhtml##{quiz[:identifier]}"
      update_syllabus(quiz) if get_node_val(quiz_meta_data, 'assignment').present?
      quiz
    end
  end
end
