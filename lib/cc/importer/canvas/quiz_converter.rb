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
  module QuizConverter
    include CC::Importer
    
    def convert_quizzes
      assessments = []
      qti_folder = File.join(@unzipped_file_path, ASSESSMENT_NON_CC_FOLDER)

      return unless File.exists?(qti_folder) && File.directory?(qti_folder)

      run_qti_converter(qti_folder)
      @course[:assessment_questions] = convert_questions
      @course[:assessments] = convert_assessments
      post_process_assessments
      
      assessments
    end
    
    def post_process_assessments
      return unless @course[:assessments] && @course[:assessments][:assessments] 
      quiz_map = {}
      @course[:assessments][:assessments].each {|a| quiz_map[a[:migration_id]] = a }
      
      @manifest.css('resource[type$=assessment]').each do |res|
        migration_id = res['identifier']
        
        path = File.join @unzipped_file_path, migration_id, ASSESSMENT_META
        doc = open_file_xml(path)
        
        if quiz = quiz_map[migration_id]
          get_quiz_meta(doc, quiz)
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
       'require_lockdown_browser_monitor'
      ].each do |bool_val|
        val = get_bool_val(doc, bool_val)
        quiz[bool_val] = val unless val.nil?
      end
      
      if asmnt_node = doc.at_css('assignment')
        quiz['assignment'] = convert_assignment(asmnt_node)
      end

      quiz
    end
    
    def run_qti_converter(qti_folder)
      # convert to 2.1
      @dest_dir_2_1 = File.join(qti_folder, "qti_2_1")
      return unless File.exists?(qti_folder)

      command = Qti.get_conversion_command(@dest_dir_2_1, qti_folder)
      logger.debug "Running migration command: #{command}"
      python_std_out = `#{command}`

      if $?.exitstatus == 0
        @converted = true
      else
        make_export_dir
        qti_error_file = File.join(@base_export_dir, "qti_conversion_error.log")
        File.open(qti_error_file, 'w') {|f|f << python_std_out}
        raise "Couldn't convert QTI 1.2 to 2.1, see error log: #{qti_error_file}"
      end
    end

    def convert_questions
      raise "The QTI must be converted to 2.1 before converting to JSON" unless @converted
      questions = {}
      begin
        manifest_file = File.join(@dest_dir_2_1, Qti::Converter::MANIFEST_FILE)
        questions[:assessment_questions] = Qti.convert_questions(manifest_file, :flavor => Qti::Flavors::CANVAS)
      rescue
        questions[:qti_error] = "#{$!}: #{$!.backtrace.join("\n")}"
      end
      questions
    end

    def convert_assessments
      raise "The QTI must be converted to 2.1 before converting to JSON" unless @converted
      quizzes = {}
      begin
        manifest_file = File.join(@dest_dir_2_1, Qti::Converter::MANIFEST_FILE)
        quizzes[:assessments] = Qti.convert_assessments(manifest_file, :flavor => Qti::Flavors::CANVAS)
      rescue
        quizzes[:qti_error] = "#{$!}: #{$!.backtrace.join("\n")}"
      end
      quizzes
    end
    
  end
end
