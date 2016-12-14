require_dependency 'importers'

module Importers
  class AssessmentQuestionImporter < Importer

    self.item_class = AssessmentQuestion

    def self.preprocess_migration_data(data)
      return if data['assessment_questions'] && data['assessment_questions']['preprocessed']

      Importers::QuizImporter.preprocess_migration_data(data)
      Importers::AssessmentQuestionBankImporter.preprocess_migration_data(data)

      data['assessment_questions'] ||= {}
      data['assessment_questions']['preprocessed'] = true
    end

    def self.process_migration(data, migration)
      data = data.with_indifferent_access
      Importers::AssessmentQuestionImporter.preprocess_migration_data(data) # just in case
      question_data = {:aq_data => {}, :qq_ids => {}}
      questions = data['assessment_questions'] ? data['assessment_questions']['assessment_questions'] : []
      questions ||= []

      existing_questions = migration.context.assessment_questions.
          except(:select).
          select("assessment_questions.id, assessment_questions.migration_id").
          where("assessment_questions.migration_id IS NOT NULL").reorder(nil).
          index_by(&:migration_id)
      questions.each do |q|
        existing_question = existing_questions[q['migration_id']]
        q['assessment_question_id'] = existing_question.id if existing_question
      end

      default_bank = migration.context.assessment_question_banks.where(id: migration.question_bank_id).first if migration.question_bank_id
      migration.question_bank_name = default_bank.title if default_bank
      default_title = migration.question_bank_name || AssessmentQuestionBank.default_imported_title

      bank_map = migration.context.assessment_question_banks.reload.index_by(&:migration_id)
      bank_map[CC::CCHelper.create_key(default_title, 'assessment_question_bank')] = default_bank if default_bank

      questions.each do |question|
        question_data[:aq_data][question['migration_id']] = question

        bank_mig_id = question[:question_bank_migration_id] || CC::CCHelper.create_key(default_title, 'assessment_question_bank')
        next unless migration.import_object?("assessment_question_banks", bank_mig_id)

        # for canvas imports/copies, don't auto generate banks for quizzes
        next if question['is_quiz_question_bank'] && (migration.for_course_copy? || (migration.migration_type == 'canvas_cartridge_importer'))

        question_bank = bank_map[bank_mig_id]

        if !question_bank
          question_bank = migration.context.assessment_question_banks.temp_record
          if bank_hash = data['assessment_question_banks'].detect{|qb_hash| qb_hash['migration_id'] == bank_mig_id}
            question_bank.title = bank_hash['title']
            if question_bank.title && question_bank.title.length > ActiveRecord::Base.maximum_string_length
              migration.add_warning(t("The title of the following question bank was truncated: \"%{title}\"", :title => question_bank.title))
              question_bank.title = CanvasTextHelper.truncate_text(question_bank.title, :max_length => ActiveRecord::Base.maximum_string_length)
            end
          end
          question_bank.title ||= default_title
          question_bank.migration_id = bank_mig_id
        elsif data['assessment_question_banks']
          if bank_hash = data['assessment_question_banks'].detect{|qb_hash| qb_hash['migration_id'] == question_bank.migration_id}
            question_bank.title = bank_hash['title'] # we should update the title i guess?
          end
        end

        if question_bank.workflow_state == 'deleted'
          question_bank.workflow_state = 'active'
        end

        question_bank.mark_as_importing!(migration)
        if question_bank.new_record?
          question_bank.save!
          migration.add_imported_item(question_bank)
          bank_map[question_bank.migration_id] = question_bank
        elsif question_bank.changed?
          question_bank.save!
        end

        begin
          if migration.for_master_course_import?
            # don't overwrite any existing assessment question content if the bank or any questions have been updated downstream
            next if question['assessment_question_id'] && question_bank.edit_types_locked_for_overwrite_on_import.include?(:content)
          end

          question = self.import_from_migration(question, migration.context, migration, question_bank)
          question_data[:aq_data][question['migration_id']] = question
        rescue
          migration.add_import_warning(t('#migration.quiz_question_type', "Quiz Question"), question[:question_name], $!)
        end
      end

      question_data
    end

    def self.import_from_migration(hash, context, migration, bank, options={})
      hash = hash.with_indifferent_access
      hash.delete(:question_bank_migration_id) if hash.has_key?(:question_bank_migration_id)

      self.prep_for_import(hash, migration, :assessment_question)

      import_warnings = hash.delete(:import_warnings) || []
      if error = hash.delete(:import_error)
        import_warnings << error
      end
      if error = hash.delete(:qti_error)
        import_warnings << error
      end

      if id = hash['assessment_question_id']
        AssessmentQuestion.where(id: id).update_all(name: hash[:question_name], question_data: hash,
            workflow_state: 'active', created_at: Time.now.utc, updated_at: Time.now.utc,
            assessment_question_bank_id: bank.id)
      else
        query = AssessmentQuestion.send(:sanitize_sql, [<<-SQL, hash[:question_name], hash.to_yaml, Time.now.utc, Time.now.utc, bank.id, hash[:migration_id]])
          INSERT INTO #{AssessmentQuestion.quoted_table_name} (name, question_data, workflow_state, created_at, updated_at, assessment_question_bank_id, migration_id)
          VALUES (?,?,'active',?,?,?,?)
        SQL
        Shackles.activate(:master) do
          id = AssessmentQuestion.connection.insert(query, "#{name} Create",
            AssessmentQuestion.primary_key, nil, AssessmentQuestion.sequence_name)
          hash['assessment_question_id'] = id
        end
      end

      if import_warnings
        import_warnings.each do |warning|
          migration.add_warning(warning, {
            :fix_issue_html_url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/question_banks/#{bank.id}#question_#{hash['assessment_question_id']}_question_text"
          })
        end
      end
      hash
    end

    def self.prep_for_import(hash, migration, item_type)
      return hash if hash[:prepped_for_import]

      if hash[:is_cc_pattern_match]
        migration.add_unique_warning(:cc_pattern_match,
          t("This package includes the question type, Pattern Match, which is not compatible with Canvas. We have converted the question type to Fill in the Blank"))
      end

      if hash[:question_text] && hash[:question_text].length > 16.kilobytes
        hash[:question_text] = t("The imported question text for this question was too long.")
        migration.add_warning(t("The question text for the question \"%{question_name}\" was too long.",
          :question_name => hash[:question_name]))
      end

      [:question_text, :correct_comments_html, :incorrect_comments_html, :neutral_comments_html, :more_comments_html].each do |field|
        if hash[field].present?
          hash[field] = migration.convert_html(
            hash[field], item_type, hash[:migration_id], field, {:remove_outer_nodes_if_one_child => true}
          )
        end
      end

      [:correct_comments, :incorrect_comments, :neutral_comments, :more_comments].each do |field|
        html_field = "#{field}_html".to_sym
        if hash[field].present? && hash[field] == hash[html_field]
          hash.delete(html_field)
        end
      end

      hash[:answers].each_with_index do |answer, i|
        [:html, :comments_html, :left_html].each do |field|
          key = "answer #{i} #{field}"

          if answer[field].present?
            answer[field] = migration.convert_html(
              answer[field], item_type, hash[:migration_id], key, {:remove_outer_nodes_if_one_child => true}
            )
          end
        end
        if answer[:comments].present? && answer[:comments] == answer[:comments_html]
          answer.delete(:comments_html)
        end
      end if hash[:answers]

      hash[:prepped_for_import] = true
      hash
    end
  end
end
