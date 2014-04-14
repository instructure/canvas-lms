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

require File.expand_path(File.dirname(__FILE__) + '/spec_helper.rb')

IMPORT_JSON_DIR = File.dirname(__FILE__) + '/fixtures/importer/'

QUESTIONS = [
        ['calculated_complex', 'calculated_question'],
        ['calculated_simple', 'calculated_question'],
        ['essay'],
        ['file_upload', 'unsupported'],
        ['fill_in_multiple_blanks'],
        ['hot_spot', 'unsupported'],
        ['matching'],
        ['multiple_answers'],
        ['multiple_choice'],
        ['multiple_dropdowns'],
        ['numerical'],
        ['ordering', 'matching_question'],
        ['short_answer'],
        ['true_false'],
]
SYSTEMS = ['vista', 'bb8', 'bb9', 'angel']

def import_data_exists?(sub_folder, hash_name)
  File.exists? File.join(IMPORT_JSON_DIR, sub_folder, "#{hash_name}.json")
end

def get_import_data(sub_folder, hash_name)
  json = File.open(File.join(IMPORT_JSON_DIR, sub_folder, "#{hash_name}.json")).read
  data = JSON.parse(json)
  data = data.with_indifferent_access if data.is_a? Hash
  data
end

def import_example_questions(context)
  question_data = {:aq_data=>{}, :qq_data=>{}}
  QUESTIONS.each do |question|
    if import_data_exists?(['vista', 'quiz'], question[0])
      q = get_import_data ['vista', 'quiz'], question[0]
      q = AssessmentQuestion.import_from_migration(q, context)
      question_data[:aq_data][q['migration_id']] = q
    end
  end
  question_data
end

def get_import_context(system=nil)
  context = course_model
  context.imported_migration_items = []
  context.import_source == :webct if system == 'vista'
  
  context
end
