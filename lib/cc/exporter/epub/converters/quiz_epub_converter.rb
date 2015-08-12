module CC::Exporter::Epub::Converters
  module QuizEpubConverter
    include AssignmentEpubConverter

    def convert_quizzes
      quizzes = []
      @manifest.css('resource[type$=assessment]').each do |quiz|
        xml_path = File.join @unzipped_file_path, quiz.at_css('file[href$="xml"]')['href']

        meta_node = open_file_xml(xml_path)
        ident = get_node_att(meta_node, "assessment", "ident")

        quiz_meta_path = "#{ident}/assessment_meta.xml"

        quizzes << convert_quiz(quiz_meta_path)
      end
      quizzes
    end

    def convert_quiz(quiz_meta_path)
      quiz = {}
      quiz_meta_link = File.join @unzipped_file_path, quiz_meta_path
      quiz_meta_data = open_file_xml(quiz_meta_link)

      quiz[:title] = get_node_val(quiz_meta_data, "title")
      quiz[:description] = get_node_val(quiz_meta_data, "description")
      quiz[:due_at] = get_node_val(quiz_meta_data, "due_at")
      quiz[:lock_at] = get_node_val(quiz_meta_data, "lock_at")
      quiz[:unlock_at] = get_node_val(quiz_meta_data, "unlock_at")
      quiz[:allowed_attempts] = get_node_val(quiz_meta_data, "allowed_attempts")
      quiz[:points_possible] = get_node_val(quiz_meta_data, "points_possible")
      quiz
    end
  end
end
