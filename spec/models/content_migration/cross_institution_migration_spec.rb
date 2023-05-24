# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "course_copy_helper"

describe ContentMigration do
  context "cross-institution migration" do
    include_context "course copy"

    before do
      @account = @copy_from.account
      account_admin_user user: @cm.user, account: @account

      # account external tool in module item, course navigation, and assignment submission
      @tool = @account.context_external_tools.build name: "blah",
                                                    url: "https://blah.example.com",
                                                    shared_secret: "123",
                                                    consumer_key: "456"
      @tool.course_navigation = { enabled: "true" }
      @tool.homework_submission = { url: "https://blah.example.com/sub" }
      @tool.save!
      mod = @copy_from.context_modules.create!
      @item = mod.add_item(type: "external_tool", url: "https://blah.example.com/what", id: @tool.id, title: "what")
      @copy_from.tab_configuration = [{ "id" => 0 }, { "id" => "context_external_tool_#{@tool.id}" }]
      @copy_from.save!

      # account outcome in course group
      @outcome = create_outcome(@account)
      og = @copy_from.learning_outcome_groups.create! title: "whut"
      og.add_outcome(@outcome)

      # account rubric in assignment
      create_rubric_asmnt(@account)

      # account grading standard in assignment
      @assignment.grading_standard = grading_standard_for(@account)
      @assignment.save!

      # account external tool submission
      @assignment2 = @copy_from.assignments.create! name: "tool assignment", submission_types: "external_tool", grading_type: "points"
      tag = @assignment2.build_external_tool_tag(url: "https://blah.example.com/sub", new_tab: true)
      tag.content_type = "ContextExternalTool"
      tag.content_id = @tool.id
      tag.save!

      # account question bank in course quiz
      @bank = @account.assessment_question_banks.create!(title: "account bank")
      @bank.assessment_questions.create!(question_data:         { "question_name" => "test question 1", "question_type" => "essay_question", "question_text" => "blah" })
      @quiz = @copy_from.quizzes.create!
      @quiz.quiz_groups.create! pick_count: 1, assessment_question_bank_id: @bank.id

      @export = run_export
    end

    it "retains external references when importing into the same root account" do
      skip unless Qti.qti_enabled?

      run_import(@export.attachment_id)

      expect(@copy_to.context_module_tags.first.content).to eq @tool
      expect(@copy_to.tab_configuration).to eq [{ "id" => 0 }, { "id" => "context_external_tool_#{@tool.id}" }]
      expect(@copy_to.learning_outcome_links.first.content).to eq @outcome
      to_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(to_assignment.rubric).to eq @rubric
      expect(to_assignment.grading_standard).to eq @standard
      to_assignment2 = @copy_to.assignments.where(migration_id: mig_id(@assignment2)).first
      expect(to_assignment2.external_tool_tag.content).to eq @tool
      expect(@copy_to.quizzes.first.quiz_groups.first.assessment_question_bank).to eq @bank
    end

    it "discards external references when importing into a different root account" do
      skip unless Qti.qti_enabled?

      @copy_to.root_account.update_attribute(:uuid, "more_different_uuid")
      run_import(@export.attachment_id)

      expect(@copy_to.context_module_tags.first.url).to eq "https://blah.example.com/what"
      expect(@copy_to.context_module_tags.first.content).to be_nil
      expect(@copy_to.tab_configuration).to eq [{ "id" => 0 }]
      expect(@copy_to.learning_outcome_links.first.content.context).to eq @copy_to
      to_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(to_assignment.rubric.context).to eq @copy_to
      expect(to_assignment.grading_standard).to be_nil
      to_assignment2 = @copy_to.assignments.where(migration_id: mig_id(@assignment2)).first
      expect(to_assignment2.external_tool_tag.content).to be_nil
      expect(@copy_to.quizzes.first.quiz_groups.first.assessment_question_bank).to be_nil

      expect(@cm.warnings.detect { |w| w =~ /account External Tool.+must be configured/ }).not_to be_nil
      expect(@cm.warnings.detect { |w| w =~ /external Learning Outcome couldn't be found.+creating a copy/ }).not_to be_nil
      expect(@cm.warnings.detect { |w| w.include?("Couldn't find the question bank") }).not_to be_nil
      expect(@cm.warnings.detect { |w| w.include?("referenced a grading scheme that was not found") }).not_to be_nil
    end
  end
end
