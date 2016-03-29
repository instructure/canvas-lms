require_dependency 'importers'

module Importers
  class QuizGroupImporter < Importer

    self.item_class = Quizzes::QuizGroup

    def self.import_from_migration(hash, context, quiz, question_data, position = nil, migration = nil)
      hash = hash.with_indifferent_access
      item ||= Quizzes::QuizGroup.where(quiz_id: quiz, migration_id: hash[:migration_id].try(:to_s)).first
      item ||= quiz.quiz_groups.new
      item.migration_id = hash[:migration_id]
      item.question_points = hash[:question_points]
      item.pick_count = hash[:pick_count]
      item.position = position
      item.name = hash[:title] || t('#quizzes.quiz_group.question_group', "Question Group")
      if hash[:question_bank_migration_id]
        if hash[:question_bank_is_external] && migration && migration.user && hash[:question_bank_context].present? && hash[:question_bank_migration_id].present?
          bank = nil
          bank_context = nil

          unless migration.cross_institution?
            if hash[:question_bank_context] =~ /account_(\d*)/
              bank_context = Account.where(id: $1).first
            elsif hash[:question_bank_context] =~ /course_(\d*)/
              bank_context = Course.where(id: $1).first
            end

            if bank_context
              bank = bank_context.assessment_question_banks.where(id: hash[:question_bank_migration_id]).first
            end
          end

          if bank
            if bank.grants_right?(migration.user, :read)
              item.assessment_question_bank_id = bank.id
            else
              migration.add_warning(t('#quizzes.quiz_group.errors.no_permissions', "User didn't have permission to reference question bank in quiz group %{group_name}", :group_name => item.name))
            end
          else
            migration.add_warning(t('#quizzes.quiz_group.errors.no_bank', "Couldn't find the question bank for quiz group %{group_name}", :group_name => item.name))
          end
        else
          if bank = context.assessment_question_banks.where(migration_id: hash[:question_bank_migration_id]).first
            item.assessment_question_bank_id = bank.id
          end
        end
      end
      item.save!
      hash[:questions].each_with_index do |question, i|
        if aq = (question_data[:aq_data][question[:migration_id]] || question_data[:aq_data][question[:assessment_question_migration_id]])
          Importers::QuizQuestionImporter.import_from_migration(aq, question, i + 1,
            question_data[:qq_ids][quiz.migration_id], context, migration, quiz, item)
        end
      end

      item
    end
  end
end