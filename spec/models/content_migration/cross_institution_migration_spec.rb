require File.expand_path(File.dirname(__FILE__) + '/course_copy_helper.rb')

describe ContentMigration do
  context "cross-institution migration" do
    include_examples "course copy"

    before do
      @account = @copy_from.account
      account_admin_user user: @cm.user, account: @account

      # account external tool in module item and course navigation
      @tool = @account.context_external_tools.build name: 'blah', url: 'https://blah.example.com',
        shared_secret: '123', consumer_key: '456'
      @tool.course_navigation = { enabled: 'true' }
      @tool.save!
      mod = @copy_from.context_modules.create!
      @item = mod.add_item(type: 'external_tool', url: 'https://blah.example.com/what', id: @tool.id, title: 'what')
      @copy_from.tab_configuration = [ {"id" =>0 }, {"id" => "context_external_tool_#{@tool.id}"} ]
      @copy_from.save!

      # account outcome in course group
      @outcome = create_outcome(@account)
      og = @copy_from.learning_outcome_groups.create! title: 'whut'
      og.add_outcome(@outcome)

      # account rubric in assignment
      create_rubric_asmnt(@account)

      # account question bank in course quiz
      @bank = @account.assessment_question_banks.create!(:title => "account bank")
      aq = @bank.assessment_questions.create!(:question_data =>
        {'question_name' => 'test question 1', 'question_type' => 'essay_question', 'question_text' => 'blah'})
      @quiz = @copy_from.quizzes.create!
      @quiz.quiz_groups.create! pick_count: 1, assessment_question_bank_id: @bank.id

      @export = run_export
    end

    it "should retain external references when importing into the same root account" do
      skip unless Qti.qti_enabled?

      run_import(@export.attachment_id)

      expect(@copy_to.context_module_tags.first.content).to eq @tool
      expect(@copy_to.tab_configuration).to eq [ {"id" =>0 }, {"id" => "context_external_tool_#{@tool.id}"} ]
      expect(@copy_to.learning_outcome_links.first.content).to eq @outcome
      to_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(to_assignment.rubric).to eq @rubric
      expect(@copy_to.quizzes.first.quiz_groups.first.assessment_question_bank).to eq @bank
    end

    it "should discard external references when importing into a different root account" do
      skip unless Qti.qti_enabled?

      @copy_to.root_account.update_attribute(:uuid, 'more_different_uuid')
      run_import(@export.attachment_id)

      expect(@copy_to.context_module_tags.first.url).to eq 'https://blah.example.com/what'
      expect(@copy_to.context_module_tags.first.content).to be_nil
      expect(@copy_to.tab_configuration).to eq [{'id'=>0}]
      expect(@copy_to.learning_outcome_links.first.content.context).to eq @copy_to
      to_assignment = @copy_to.assignments.where(migration_id: mig_id(@assignment)).first
      expect(to_assignment.rubric.context).to eq @copy_to
      expect(@copy_to.quizzes.first.quiz_groups.first.assessment_question_bank).to be_nil

      expect(@cm.warnings.detect { |w| w =~ /account External Tool.+must be configured/ }).not_to be_nil
      expect(@cm.warnings.detect { |w| w =~ /external Rubric couldn't be found.+creating a copy/ }).not_to be_nil
      expect(@cm.warnings.detect { |w| w =~ /external Learning Outcome couldn't be found.+creating a copy/ }).not_to be_nil
      expect(@cm.warnings.detect { |w| w =~ /Couldn't find the question bank/ }).not_to be_nil
    end
  end
end