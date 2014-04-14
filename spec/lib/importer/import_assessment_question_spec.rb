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

require File.expand_path(File.dirname(__FILE__) + '../../../import_helper')

describe "Assessment Question import from hash" do
  
  SYSTEMS.each do |system|
    QUESTIONS.each do |q|
      if import_data_exists? [system, 'quiz'], q[0]
        it "should import #{q[0]} questions for #{system}" do
          test_question_import(q[0], system, q[1])
        end
      end
    end
  end

  it "should only import assessment question once" do
    context = get_import_context
    context.imported_migration_items ||= []
    data = get_import_data '', 'single_question'
    data = {'assessment_questions'=>{'assessment_questions'=>data}}

    migration = ContentMigration.create!(:context => context)
    migration.migration_ids_to_import = {:copy => {:assessment_questions => true}}.with_indifferent_access

    context.assessment_questions.count.should == 0

    AssessmentQuestion.process_migration(data, migration)
    AssessmentQuestion.process_migration(data, migration)

    context.assessment_questions.count.should == 1
  end

  it "should update assessment question on re-import" do
    context = get_import_context
    context.imported_migration_items ||= []
    data = get_import_data '', 'single_question'
    data = {'assessment_questions'=>{'assessment_questions'=>data}}

    migration = ContentMigration.create!(:context => context)
    migration.migration_ids_to_import = {:copy => {:assessment_questions => true}}.with_indifferent_access

    context.assessment_questions.count.should == 0

    AssessmentQuestion.process_migration(data, migration)
    data['assessment_questions']['assessment_questions'].first['question_name'] = "Bee2"
    AssessmentQuestion.process_migration(data, migration)

    context.assessment_questions.count.should == 1
    context.assessment_questions.first.name.should == "Bee2"
  end

  it "should use the question bank settings" do
    q = get_import_data 'cengage', 'question'
    context = get_import_context('cengage')
    AssessmentQuestion.import_from_migration(q, context)
    
    bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title_and_migration_id(context.class.to_s, context.id, q[:question_bank_name], q[:question_bank_id]) 
    bank.assessment_questions.count.should == 1
    bank.assessment_questions.first.migration_id.should == q[:migration_id]
  end

end

def test_question_import(hash_name, system, question_type=nil)
  question_type ||= "#{hash_name}_question"
  q = get_import_data [system, 'quiz'], hash_name 
#  q[:question_type].should == question_type
  context = get_import_context(system)
  AssessmentQuestion.import_from_migration(q, context)
  AssessmentQuestion.count.should == 1

  db_aq = AssessmentQuestion.find_by_migration_id(q[:migration_id])
  db_aq.migration_id.should == q[:migration_id]
  db_aq.name == q[:question_name]

  bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title_and_migration_id(context.class.to_s, context.id, AssessmentQuestionBank.default_imported_title, nil)
  bank_aq = bank.assessment_questions.first
  bank_aq.id.should == db_aq.id
end
