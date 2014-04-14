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

describe "Quiz Import" do
  it "should use the specified question group" do
    context = course_model
    data = get_import_data [], 'question_group'
    data = data['assessment_questions']['assessment_questions'].first
    AssessmentQuestion.import_from_migration(data, context)

    q = AssessmentQuestion.find_by_migration_id(data[:migration_id])

    bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title(context.class.to_s, context.id, data[:question_bank_name])
    bank_aq = bank.assessment_questions.first
    bank_aq.id.should == q.id
  end

  it "should use the default question group if none specified" do
    context = course_model
    data = get_import_data [], 'question_group'
    data = data['assessment_questions']['assessment_questions'].last
    AssessmentQuestion.import_from_migration(data, context)

    q = AssessmentQuestion.find_by_migration_id(data[:migration_id])

    bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title(context.class.to_s, context.id, AssessmentQuestionBank.default_imported_title)
    bank_aq = bank.assessment_questions.first
    bank_aq.id.should == q.id
  end

  it "should use the correct question bank" do
    context = course_model
    migration = ContentMigration.create!(:context => context)
    migration.migration_ids_to_import = {:copy=>{'assessment_questions'=>true, 'all_quizzes'=>true}}
    migration.question_bank_name = "test question bank"
    data = get_import_data [], 'question_group'

    AssessmentQuestion.process_migration(data, migration)
    AssessmentQuestion.process_migration(data, migration)

    context.assessment_question_banks.count.should eql(3)
    context.assessment_questions.count.should eql(4)

    bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title(context.class.to_s, context.id, 'Group1')
    bank.assessment_questions.count.should eql(1)
    bank.assessment_questions.first.migration_id.should eql('1')

    bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title(context.class.to_s, context.id, 'Assmnt1')
    bank.assessment_questions.count.should eql(2)
    ['2','3'].member?(bank.assessment_questions.first.migration_id).should_not be_nil
    ['2','3'].member?(bank.assessment_questions.last.migration_id).should_not be_nil

    bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title(context.class.to_s, context.id, "test question bank")
    bank.assessment_questions.count.should eql(1)
    bank.assessment_questions.first.migration_id.should eql('4')
  end
  
  it "should allow question groups to point to question banks" do
    question = get_import_data 'cengage', 'question'
    context = get_import_context('cengage')
    AssessmentQuestion.import_from_migration(question, context)
    bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title_and_migration_id(context.class.to_s, context.id, question[:question_bank_name], question[:question_bank_id])
    question_data = {}
    question_data[question[:migration_id]] = context.assessment_questions.find_by_migration_id(question[:migration_id])
    
    quiz = get_import_data 'cengage', 'quiz'
    Quizzes::QuizImporter.import_from_migration(quiz, context, question_data)
    quiz = context.quizzes.find_by_migration_id(quiz[:migration_id])
    
    group = quiz.quiz_groups.first
    group.assessment_question_bank_id.should == bank.id
  end

end
