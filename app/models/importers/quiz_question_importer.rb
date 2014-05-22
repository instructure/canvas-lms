module Importers
  class QuizQuestionImporter < Importer

    self.item_class = Quizzes::QuizQuestion

    def self.import_from_migration(aq_hash, qq_hash, position, qq_ids, context, migration=nil, quiz=nil, quiz_group=nil)
      unless aq_hash[:prepped_for_import]
        Importers::AssessmentQuestionImporter.prep_for_import(aq_hash, context, migration)
      end

      hash = aq_hash.dup
      hash[:position] = position
      hash[:points_possible] = qq_hash[:points_possible] if qq_hash[:points_possible]

      if id = qq_ids[qq_hash['migration_id']]
        Quizzes::QuizQuestion.where(id: id).update_all(quiz_group_id: quiz_group,
          assessment_question_id: hash['assessment_question_id'], question_data: hash.to_yaml,
          created_at: Time.now.utc, updated_at: Time.now.utc, migration_id: hash[:migration_id],
          position: position)
      else
        query = self.item_class.send(:sanitize_sql, [<<-SQL, quiz && quiz.id, quiz_group && quiz_group.id, hash['assessment_question_id'], hash.to_yaml, Time.now.utc, Time.now.utc, hash[:migration_id], position])
        INSERT INTO quiz_questions (quiz_id, quiz_group_id, assessment_question_id, question_data, created_at, updated_at, migration_id, position)
        VALUES (?,?,?,?,?,?,?,?)
        SQL
        qq_ids[qq_hash['migration_id']] = self.item_class.connection.insert(query, "#{self.item_class.name} Create",
          self.item_class.primary_key, nil, self.item_class.sequence_name)
      end
      hash
    end
  end
end