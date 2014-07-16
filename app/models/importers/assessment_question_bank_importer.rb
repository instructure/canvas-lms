module Importers
  class AssessmentQuestionBankImporter < Importer

    self.item_class = AssessmentQuestionBank

    # extract and compile the assessment question bank data from inside the individual questions
    def self.preprocess_migration_data(data)
      return if data[:assessment_question_banks]

      questions = (data[:assessment_questions] && data[:assessment_questions][:assessment_questions]) || []

      banks = []
      questions.each do |q|
        q.delete(:question_bank_name) if q[:question_bank_name].blank?

        if id = q.delete(:question_bank_id)
          q[:question_bank_migration_id] ||= id
        end

        if q[:question_bank_migration_id] && bank = banks.detect{|b| b[:migration_id] == q[:question_bank_migration_id]}
          bank[:count] += 1
          bank[:title] ||= q[:question_bank_name]
          q[:question_bank_name] ||= bank[:title]
          bank[:migration_id] ||= CC::CCHelper.create_key(bank[:title], 'assessment_question_bank') if bank[:title]
        elsif q[:question_bank_name] && bank = banks.detect{|b| b[:title] == q[:question_bank_name]}
          bank[:count] += 1
          q[:question_bank_migration_id] = bank[:migration_id]
        else
          bank = {:count => 1}
          bank[:title] = q[:question_bank_name] if q[:question_bank_name]
          bank[:migration_id] = q[:question_bank_migration_id] if q[:question_bank_migration_id]
          bank[:migration_id] ||= CC::CCHelper.create_key(bank[:title], 'assessment_question_bank') if bank[:title]
          q[:question_bank_migration_id] ||= bank[:migration_id]
          banks << bank
        end
      end

      data[:assessment_question_banks] = banks
    end
  end
end