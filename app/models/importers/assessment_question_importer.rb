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
          where("assessment_questions.migration_id IS NOT NULL").
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
          question_bank = migration.context.assessment_question_banks.new
          if bank_hash = data['assessment_question_banks'].detect{|qb_hash| qb_hash['migration_id'] == bank_mig_id}
            question_bank.title = bank_hash['title']
          end
          question_bank.title ||= default_title
          question_bank.migration_id = bank_mig_id
          question_bank.save!
          migration.add_imported_item(question_bank)
          bank_map[question_bank.migration_id] = question_bank
        end

        if question_bank.workflow_state == 'deleted'
          question_bank.workflow_state = 'active'
          question_bank.save!
        end

        begin
          question = self.import_from_migration(question, migration.context, migration, question_bank)

          # If the question appears to have links, we need to translate them so that file links point
          # to the AssessmentQuestion. Ideally we would just do this before saving the question, but
          # the link needs to include the id of the AQ, which we don't have until it's saved. This will
          # be a problem as long as we use the question as a context for its attachments. (We're turning this
          # hash into a string so we can quickly check if anywhere in the hash might have a URL.)
          if question.to_s =~ %r{/files/\d+/(download|preview)}
            AssessmentQuestion.find(question[:assessment_question_id]).translate_links
          end

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

      self.prep_for_import(hash, context, migration)

      missing_links = hash.delete(:missing_links) || {}
      import_warnings = hash.delete(:import_warnings) || []
      if error = hash.delete(:import_error)
        import_warnings += [error]
      end

      if id = hash['assessment_question_id']
        AssessmentQuestion.where(id: id).update_all(name: hash[:question_name], question_data: hash.to_yaml,
            workflow_state: 'active', created_at: Time.now.utc, updated_at: Time.now.utc,
            assessment_question_bank_id: bank.id)
      else
        query = AssessmentQuestion.send(:sanitize_sql, [<<-SQL, hash[:question_name], hash.to_yaml, Time.now.utc, Time.now.utc, bank.id, hash[:migration_id]])
          INSERT INTO assessment_questions (name, question_data, workflow_state, created_at, updated_at, assessment_question_bank_id, migration_id)
          VALUES (?,?,'active',?,?,?,?)
        SQL
        id = AssessmentQuestion.connection.insert(query, "#{name} Create",
          AssessmentQuestion.primary_key, nil, AssessmentQuestion.sequence_name)
        hash['assessment_question_id'] = id
      end

      if migration
        missing_links.each do |field, links|
          migration.add_missing_content_links(:class => self.to_s,
            :id => hash['assessment_question_id'], :field => field, :missing_links => links,
            :url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/question_banks/#{bank.id}#question_#{hash['assessment_question_id']}_question_text")
        end
        if import_warnings
          import_warnings.each do |warning|
            migration.add_warning(warning, {
              :fix_issue_html_url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/question_banks/#{bank.id}#question_#{hash['assessment_question_id']}_question_text"
            })
          end
        end
      end
      hash
    end

    def self.prep_for_import(hash, context, migration=nil)
      return hash if hash[:prepped_for_import]
      hash[:missing_links] = {}
      [:question_text, :correct_comments_html, :incorrect_comments_html, :neutral_comments_html, :more_comments_html].each do |field|
        hash[:missing_links][field] = []
        if hash[field].present?
          hash[field] = ImportedHtmlConverter.convert(hash[field], context, migration, {:remove_outer_nodes_if_one_child => true}) do |warn, link|
            hash[:missing_links][field] << link if warn == :missing_link
          end
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
          hash[:missing_links][key] = []
          if answer[field].present?
            answer[field] = ImportedHtmlConverter.convert(answer[field], context, migration, {:remove_outer_nodes_if_one_child => true}) do |warn, link|
              hash[:missing_links][key] << link if warn == :missing_link
            end
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