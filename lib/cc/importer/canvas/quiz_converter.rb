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
    include QuizMetadataConverter
    
    def convert_quizzes
      assessments = []
      qti_folder = File.join(@unzipped_file_path, ASSESSMENT_NON_CC_FOLDER)

      return unless File.exist?(qti_folder) && File.directory?(qti_folder)

      run_qti_converter(qti_folder)
      @course[:assessment_questions] = convert_questions
      @course[:assessments] = convert_assessments
      post_process_assessments
      
      assessments
    end
    
    def run_qti_converter(qti_folder)
      # convert to 2.1
      @dest_dir_2_1 = File.join(qti_folder, "qti_2_1")
      return unless File.exist?(qti_folder)

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
