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
module CC::Importer::Standard
  module QuizConverter
    include CC::Importer

    def convert_quizzes
      quizzes = []
      questions = []
      
      conversion_dir = @package_root.item_path("temp_qti_conversions")

      resources_by_type("imsqti").each do |res|
        path = res[:href] || (res[:files] && res[:files].first && res[:files].first[:href])
        full_path = path ? get_full_path(path) : nil
        id = res[:migration_id]

        if path.nil? # inline qti
          next unless res_node = @resource_nodes_for_flat_manifest[id]
          qti_node = res_node.elements.first
          path = "#{id}_qti.xml"
          full_path = get_full_path(path)
          File.open(full_path, 'w') {|f| f << qti_node.to_xml} # write to file so we can convert with qti exporter
        end

        if File.exist?(full_path)
          qti_converted_dir = File.join(conversion_dir, id)
          if run_qti_converter(full_path, qti_converted_dir, id)
            # get quizzes/questions
            if q_list = convert_questions(qti_converted_dir, id)
              questions += q_list
            end
            if quiz = convert_assessment(qti_converted_dir, id)
              quizzes << quiz
            end
          end
        end
      end

      [{:assessment_questions => questions}, {:assessments => quizzes}]
    end
    
    def run_qti_converter(qti_file, out_folder, resource_id)
      # convert to 2.1
      command = Qti.get_conversion_command(out_folder, qti_file)
      logger.debug "Running migration command: #{command}"
      python_std_out = `#{command}`

      if $?.exitstatus == 0
        true
      else
        add_warning(I18n.t('lib.cc.standard.failed_to_convert_qti', 'Failed to import Assessment %{file_identifier}', :file_identifier => resource_id), "Output of QTI conversion tool: #{python_std_out.last(300)}")
        false
      end
    end

    def convert_questions(out_folder, resource_id)
      questions = nil
      begin
        manifest_file = File.join(out_folder, Qti::Converter::MANIFEST_FILE)
        questions = Qti.convert_questions(manifest_file, :flavor => Qti::Flavors::COMMON_CARTRIDGE)
        ::Canvas::Migration::MigratorHelper.prepend_id_to_questions(questions, resource_id)

        #try to replace relative urls
        questions.each do |question|
          question[:question_text] = replace_urls(question[:question_text], resource_id) if question[:question_text]
          question[:answers].each do |ans|
            ans.each_pair do |key, val|
              if key.to_s.end_with? "html"
                ans[key] = replace_urls(val, resource_id) if ans[key]
              end
            end
          end
        end
      rescue
        add_warning(I18n.t('lib.cc.standard.failed_to_convert_qti', 'Failed to import Assessment %{file_identifier}', :file_identifier => resource_id), $!)
      end
      questions
    end

    def convert_assessment(out_folder, resource_id)
      quiz = nil
      begin
        manifest_file = File.join(out_folder, Qti::Converter::MANIFEST_FILE)
        quizzes = Qti.convert_assessments(manifest_file, :flavor => Qti::Flavors::COMMON_CARTRIDGE)
        ::Canvas::Migration::MigratorHelper.prepend_id_to_assessments(quizzes, resource_id)
        if quiz = quizzes.first
          quiz[:migration_id] = resource_id
        end
      rescue
        add_warning(I18n.t('lib.cc.standard.failed_to_convert_qti', 'Failed to import Assessment %{file_identifier}', :file_identifier => resource_id), $!)
      end
      quiz
    end
    
  end
end