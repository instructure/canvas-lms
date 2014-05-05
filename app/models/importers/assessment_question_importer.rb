module Importers
  class AssessmentQuestionImporter < Importer

    self.item_class = AssessmentQuestion

    def self.process_migration(data, migration)
      question_data = {:aq_data=>{}, :qq_data=>{}}
      questions = data['assessment_questions'] ? data['assessment_questions']['assessment_questions'] : []
      questions ||= []
      to_import = migration.to_import 'quizzes'
      total = questions.length

      # If a question doesn't have a specified question bank
      # we want to put it in a bank named after the assessment it's in
      bank_map = {}
      assessments = data['assessments'] ? data['assessments']['assessments'] : []
      assessments ||= []
      assessments.each do |assmnt|
        next unless assmnt['questions']
        assmnt['questions'].each do |q|
          if q["question_type"] == "question_reference"
            bank_map[q['migration_id']] = [assmnt['title'], assmnt['migration_id']] if q['migration_id']
          elsif q["question_type"] == "question_group"
            q['questions'].each do |ref|
              bank_map[ref['migration_id']] = [assmnt['title'], assmnt['migration_id']] if ref['migration_id']
            end
          end
        end
      end
      if migration.to_import('assessment_questions') != false || (to_import && !to_import.empty?)

        existing_questions = migration.context.assessment_questions.
            except(:select).
            select("assessment_questions.id, assessment_questions.migration_id").
            where("assessment_questions.migration_id IS NOT NULL").
            index_by(&:migration_id)
        questions.each do |q|
          existing_question = existing_questions[q['migration_id']]
          q['assessment_question_id'] = existing_question.id if existing_question
        end

        logger.debug "adding #{total} assessment questions"

        default_bank = migration.question_bank_id ? migration.context.assessment_question_banks.find_by_id(migration.question_bank_id) : nil
        banks = {}
        questions.each do |question|
          question_bank = nil
          question[:question_bank_name] = nil if question[:question_bank_name] == ''
          question[:question_bank_name], question[:question_bank_migration_id] = bank_map[question[:migration_id]] if question[:question_bank_name].blank?
          if default_bank
            question_bank = default_bank
          else
            question[:question_bank_name] ||= migration.question_bank_name
            question[:question_bank_name] ||= AssessmentQuestionBank.default_imported_title
          end
          if question[:assessment_question_migration_id] && !migration.migration_settings[:import_quiz_questions_without_quiz]
            question_data[:qq_data][question['migration_id']] = question
            next
          end
          next if question[:question_bank_migration_id] &&
              !migration.import_object?("quizzes", question[:question_bank_migration_id]) &&
              !migration.import_object?("assessment_question_banks", question[:question_bank_migration_id])

          if !question_bank
            hash_id = "#{question[:question_bank_id]}_#{question[:question_bank_name]}"
            if !banks[hash_id]
              bank_mig_id = question[:question_bank_id] || question[:question_bank_migration_id]
              unless bank = migration.context.assessment_question_banks.find_by_title_and_migration_id(question[:question_bank_name], bank_mig_id)
                bank = migration.context.assessment_question_banks.new
                bank.title = question[:question_bank_name]
                bank.migration_id = bank_mig_id
                bank.save!
              end
              if bank.workflow_state == 'deleted'
                bank.workflow_state = 'active'
                bank.save!
              end
              banks[hash_id] = bank
            end
            question_bank = banks[hash_id]
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
      end

      question_data
    end

    def self.import_from_migration(hash, context, migration=nil, bank=nil, options={})
      hash = hash.with_indifferent_access
      if !bank
        hash[:question_bank_name] = nil if hash[:question_bank_name] == ''
        hash[:question_bank_name] ||= AssessmentQuestionBank::default_imported_title
        migration_id = hash[:question_bank_id] || hash[:question_bank_migration_id]
        unless bank = AssessmentQuestionBank.find_by_context_type_and_context_id_and_title_and_migration_id(context.class.to_s, context.id, hash[:question_bank_name], migration_id)
          bank ||= context.assessment_question_banks.new
          bank.title = hash[:question_bank_name]
          bank.migration_id = migration_id
          bank.save!
        end
        if bank.workflow_state == 'deleted'
          bank.workflow_state = 'active'
          bank.save!
        end
      end
      hash.delete(:question_bank_migration_id) if hash.has_key?(:question_bank_migration_id)

      migration.add_imported_item(bank) if migration
      self.prep_for_import(hash, context, migration)

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
        hash[:missing_links].each do |field, missing_links|
          migration.add_missing_content_links(:class => self.to_s,
            :id => hash['assessment_question_id'], :field => field, :missing_links => missing_links,
            :url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/question_banks/#{bank.id}#question_#{hash['assessment_question_id']}_question_text")
        end
        if hash[:import_warnings]
          hash[:import_warnings].each do |warning|
            migration.add_warning(warning, {
              :fix_issue_html_url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/question_banks/#{bank.id}#question_#{hash['assessment_question_id']}_question_text"
            })
          end
        end
      end
      hash.delete(:missing_links)
      hash
    end

    def self.prep_for_import(hash, context, migration=nil)
      hash[:missing_links] = {}
      [:question_text, :correct_comments_html, :incorrect_comments_html, :neutral_comments_html, :more_comments_html].each do |field|
        hash[:missing_links][field] = []
        hash[field] = ImportedHtmlConverter.convert(hash[field], context, migration, {:missing_links => hash[:missing_links][field], :remove_outer_nodes_if_one_child => true}) if hash[field].present?
      end
      [:correct_comments, :incorrect_comments, :neutral_comments, :more_comments].each do |field|
        html_field = "#{field}_html".to_sym
        if hash[field].present? && hash[field] == hash[html_field]
          hash.delete(html_field)
        end
      end
      hash[:answers].each_with_index do |answer, i|
        [:html, :comments_html, :left_html].each do |field|
          hash[:missing_links]["answer #{i} #{field}"] = []
          answer[field] = ImportedHtmlConverter.convert(answer[field], context, migration, {:missing_links => hash[:missing_links]["answer #{i} #{field}"], :remove_outer_nodes_if_one_child => true}) if answer[field].present?
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