# frozen_string_literal: true

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

require_relative "../../import_helper"

describe "Assessment Question import from hash" do
  SYSTEMS.each do |system|
    QUESTIONS.each do |q|
      next unless import_data_exists? [system, "quiz"], q[0]

      it "imports #{q[0]} questions for #{system}" do
        test_question_import(q[0], system)
      end
    end
  end

  it "only imports assessment question once" do
    context = get_import_context
    data = get_import_data "", "single_question"
    data = { "assessment_questions" => { "assessment_questions" => data } }

    migration = ContentMigration.create!(context:)
    expect(context.assessment_questions.count).to eq 0

    Importers::AssessmentQuestionImporter.process_migration(data, migration)
    Importers::AssessmentQuestionImporter.process_migration(data, migration)

    expect(context.assessment_question_banks.count).to eq 1
    expect(context.assessment_questions.count).to eq 1
  end

  it "updates assessment question on re-import" do
    context = get_import_context
    data = get_import_data "", "single_question"
    data = { "assessment_questions" => { "assessment_questions" => data } }

    migration = ContentMigration.create!(context:)
    expect(context.assessment_questions.count).to eq 0

    Importers::AssessmentQuestionImporter.process_migration(data, migration)
    data["assessment_questions"]["assessment_questions"].first["question_name"] = "Bee2"
    Importers::AssessmentQuestionImporter.process_migration(data, migration)

    expect(context.assessment_question_banks.count).to eq 1
    expect(context.assessment_questions.count).to eq 1
    expect(context.assessment_questions.first.name).to eq "Bee2"
  end

  it "uses the question bank settings" do
    q = get_import_data "cengage", "question"
    context = get_import_context("cengage")
    data = { "assessment_questions" => { "assessment_questions" => [q] } }
    migration = ContentMigration.create!(context:)
    Importers::AssessmentQuestionImporter.process_migration(data, migration)

    bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: q[:question_bank_name]).first
    expect(bank.assessment_questions.count).to eq 1
    expect(bank.assessment_questions.first.migration_id).to eq q[:migration_id]
  end

  it "uses the specified question group" do
    context = course_model
    data = get_import_data [], "question_group"
    q_hash = data["assessment_questions"]["assessment_questions"].first
    migration = ContentMigration.create!(context:)
    Importers::AssessmentQuestionImporter.process_migration(data, migration)

    q = AssessmentQuestion.where(migration_id: q_hash[:migration_id]).first

    bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: q_hash[:question_bank_name]).first
    bank_aq = bank.assessment_questions.first
    expect(bank_aq.id).to eq q.id
  end

  it "uses the default question group if none specified" do
    context = course_model
    data = get_import_data [], "question_group"
    q_hash = data["assessment_questions"]["assessment_questions"].last
    migration = ContentMigration.create!(context:)
    Importers::AssessmentQuestionImporter.process_migration(data, migration)

    q = AssessmentQuestion.where(migration_id: q_hash[:migration_id]).first

    bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: AssessmentQuestionBank.default_imported_title).first
    bank_aq = bank.assessment_questions.first
    expect(bank_aq.id).to eq q.id
  end

  it "uses the correct question bank" do
    context = course_model
    migration = ContentMigration.create!(context:)
    migration.question_bank_name = "test question bank"
    data = get_import_data [], "question_group"

    Importers::AssessmentQuestionImporter.process_migration(data, migration)
    Importers::AssessmentQuestionImporter.process_migration(data, migration)

    expect(context.assessment_question_banks.count).to be(3)
    expect(context.assessment_questions.count).to be(4)

    bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: "Group1").first
    expect(bank.assessment_questions.count).to be(1)
    expect(bank.assessment_questions.first.migration_id).to eql("1")

    bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: "Assmnt1").first
    expect(bank.assessment_questions.count).to be(2)
    expect(["2", "3"].member?(bank.assessment_questions.first.migration_id)).not_to be_nil
    expect(["2", "3"].member?(bank.assessment_questions.last.migration_id)).not_to be_nil

    bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: "test question bank").first
    expect(bank.assessment_questions.count).to be(1)
    expect(bank.assessment_questions.first.migration_id).to eql("4")
  end

  it "allows question groups to point to question banks" do
    question = get_import_data "cengage", "question"
    context = get_import_context("cengage")
    data = { "assessment_questions" => { "assessment_questions" => [question] } }
    migration = ContentMigration.create!(context:)
    Importers::AssessmentQuestionImporter.process_migration(data, migration)
    bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: question[:question_bank_name]).first
    question_data = { aq_data: {}, qq_ids: {} }
    question_data[:aq_data][question[:migration_id]] = context.assessment_questions.where(migration_id: question[:migration_id]).first

    quiz = get_import_data "cengage", "quiz"
    Importers::QuizImporter.import_from_migration(quiz, context, migration, question_data)
    quiz = context.quizzes.where(migration_id: quiz[:migration_id]).first

    group = quiz.quiz_groups.first
    expect(group.assessment_question_bank_id).to eq bank.id
  end

  it "sets root_account_id correctly" do
    context = course_model
    data = get_import_data [], "question_group"
    migration = ContentMigration.create!(context:)
    Importers::AssessmentQuestionImporter.process_migration(data, migration)

    bank = AssessmentQuestionBank.where(
      context_type: context.class.to_s, context_id: context, title: AssessmentQuestionBank.default_imported_title
    ).first
    bank_aq = bank.assessment_questions.first

    expect(bank_aq.root_account_id).not_to be_nil
    expect(bank_aq.root_account_id).to eq bank.root_account_id
    expect(bank_aq.root_account_id).to eq @course.root_account_id
  end
end

def test_question_import(hash_name, system)
  q = get_import_data [system, "quiz"], hash_name
  context = get_import_context(system)
  data = { "assessment_questions" => { "assessment_questions" => [q] } }
  migration = ContentMigration.create!(context:)
  Importers::AssessmentQuestionImporter.process_migration(data, migration)
  expect(context.assessment_questions.count).to eq 1

  db_aq = AssessmentQuestion.where(migration_id: q[:migration_id]).first
  expect(db_aq.migration_id).to eq q[:migration_id]
  expect(db_aq.name).to eq q[:question_name]

  bank = AssessmentQuestionBank.where(context_type: context.class.to_s, context_id: context, title: AssessmentQuestionBank.default_imported_title).first
  bank_aq = bank.assessment_questions.first
  expect(bank_aq.id).to eq db_aq.id
end
