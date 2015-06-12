module CC::Importer::Canvas
  module QuizMetadataConverter
    include AssignmentConverter

    def post_process_assessments
      return unless @course[:assessments] && @course[:assessments][:assessments]
      quiz_map = {}
      @course[:assessments][:assessments].each {|a| quiz_map[File.join(a[:migration_id], ASSESSMENT_META)] = a }

      @manifest.css('resource[type$="learning-application-resource"]').each do |res|

        res.css('file').select{|f| f['href'].to_s.end_with?(ASSESSMENT_META)}.each do |file|
          meta_path = file['href']
          if quiz = quiz_map[meta_path]
            doc = open_file_xml(File.join(@unzipped_file_path, meta_path))
            get_quiz_meta(doc, quiz)
          end
        end
      end
    end

    def get_quiz_meta(doc, quiz)
      ['title', 'description', 'access_code', 'ip_filter',
       'quiz_type', 'scoring_policy', 'hide_results',
       'lockdown_browser_monitor_data'].each do |string_type|
        val = get_node_val(doc, string_type)
        quiz[string_type] = val unless val.nil?
      end
      quiz['assignment_group_migration_id'] = get_node_val(doc, 'assignment_group_identifierref')
      quiz['points_possible'] = get_float_val(doc, 'points_possible')
      quiz['lock_at'] = get_time_val(doc, 'lock_at')
      quiz['unlock_at'] = get_time_val(doc, 'unlock_at')
      quiz['due_at'] = get_time_val(doc, 'due_at')
      quiz['show_correct_answers_at'] = get_time_val(doc, 'show_correct_answers_at')
      quiz['hide_correct_answers_at'] = get_time_val(doc, 'hide_correct_answers_at')
      quiz['time_limit'] = get_int_val(doc, 'time_limit')
      quiz['allowed_attempts'] = get_int_val(doc, 'allowed_attempts')
      ['could_be_locked','anonymous_submissions','show_correct_answers',
       'require_lockdown_browser','require_lockdown_browser_for_results',
       'shuffle_answers','available', 'cant_go_back', 'one_question_at_a_time',
       'require_lockdown_browser_monitor',
       'one_time_results', 'show_correct_answers_last_attempt'
      ].each do |bool_val|
        val = get_bool_val(doc, bool_val)
        quiz[bool_val] = val unless val.nil?
      end

      if asmnt_node = doc.at_css('assignment')
        quiz['assignment'] = parse_canvas_assignment_data(asmnt_node)
      end

      quiz
    end
  end
end