require_dependency 'importers'

module Importers
  class QuizQuestionImporter < Importer

    self.item_class = Quizzes::QuizQuestion

    def self.import_from_migration(aq_hash, qq_hash, position, qq_ids, context, migration, quiz=nil, quiz_group=nil)
      unless aq_hash[:prepped_for_import]
        Importers::AssessmentQuestionImporter.prep_for_import(aq_hash, migration, :quiz_question)
      end

      hash = aq_hash.dup
      hash[:position] = position
      hash[:points_possible] = qq_hash[:points_possible] if qq_hash[:points_possible]
      hash[:points_possible] = 0 if hash[:points_possible].to_f < 0

      mig_id = qq_hash['quiz_question_migration_id'] || qq_hash['migration_id']

      if id = qq_ids[mig_id]
        Quizzes::QuizQuestion.where(id: id).update_all(quiz_group_id: quiz_group,
          assessment_question_id: hash['assessment_question_id'], question_data: hash,
          created_at: Time.now.utc, updated_at: Time.now.utc, migration_id: mig_id,
          position: position)
      else
        args = [quiz && quiz.id, quiz_group && quiz_group.id, hash['assessment_question_id'],
            hash.to_yaml, Time.now.utc, Time.now.utc, mig_id, position]
        query = self.item_class.send(:sanitize_sql, [<<-SQL, *args])
          INSERT INTO #{Quizzes::QuizQuestion.quoted_table_name} (quiz_id, quiz_group_id, assessment_question_id, question_data, created_at, updated_at, migration_id, position)
          VALUES (?,?,?,?,?,?,?,?)
        SQL
        Shackles.activate(:master) do
          qq_ids[mig_id] = self.item_class.connection.insert(query, "#{self.item_class.name} Create",
            self.item_class.primary_key, nil, self.item_class.sequence_name)
        end
      end
      hash
    end
  end
end