module Importers
  class AssignmentImporter < Importer

    self.item_class = Assignment

    def self.process_migration(data, migration)
      assignments = data['assignments'] ? data['assignments']: []
      to_import = migration.to_import 'assignments'
      assignments.each do |assign|
        if migration.import_object?("assignments", assign['migration_id'])
          begin
            import_from_migration(assign, migration.context, migration)
          rescue
            migration.add_import_warning(t('#migration.assignment_type', "Assignment"), assign[:title], $!)
          end
        end
      end
      migration_ids = assignments.map{|m| m['assignment_id'] }.compact
      conn = Assignment.connection
      cases = []
      max = migration.context.assignments.map(&:position).compact.max || 0
      migration.context.assignments
      assignments.each_with_index{|m, idx| cases << " WHEN migration_id=#{conn.quote(m['assignment_id'])} THEN #{max + idx + 1} " if m['assignment_id'] }
      unless cases.empty?
        conn.execute("UPDATE assignments SET position=CASE #{cases.join(' ')} ELSE NULL END WHERE context_id=#{migration.context.id} AND context_type=#{conn.quote(migration.context.class.to_s)} AND migration_id IN (#{migration_ids.map{|id| conn.quote(id)}.join(',')})")
      end
    end

    def self.import_from_migration(hash, context, migration=nil, item=nil, quiz=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:assignments_to_import] && !hash[:assignments_to_import][hash[:migration_id]]
      item ||= Assignment.find_by_context_type_and_context_id_and_id(context.class.to_s, context.id, hash[:id])
      item ||= Assignment.find_by_context_type_and_context_id_and_migration_id(context.class.to_s, context.id, hash[:migration_id]) if hash[:migration_id]
      item ||= context.assignments.new #new(:context => context)
      item.title = hash[:title]
      item.migration_id = hash[:migration_id]
      item.workflow_state = (hash[:workflow_state] || 'published') if item.new_record? || item.deleted?
      if hash[:instructions_in_html] == false
        self.extend TextHelper
      end

      missing_links = {:description => [], :instructions => []}
      description = ""
      if hash[:instructions_in_html] == false
        description += ImportedHtmlConverter.convert_text(hash[:description] || "", context)
        description += ImportedHtmlConverter.convert_text(hash[:instructions] || "", context)
      else
        description += ImportedHtmlConverter.convert(hash[:description] || "", context, migration) do |warn, link|
          missing_links[:description] << link if warn == :missing_link
        end
        description += ImportedHtmlConverter.convert(hash[:instructions] || "", context, migration) do |warn, link|
          missing_links[:instructions] << link if warn == :missing_link
        end
      end

      description += Attachment.attachment_list_from_migration(context, hash[:attachment_ids])
      item.description = description

      if hash[:freeze_on_copy]
        item.freeze_on_copy = true
        item.copied = true
        item.copying = true
      end
      if !hash[:submission_types].blank?
        item.submission_types = hash[:submission_types]
      elsif ['discussion_topic'].include?(hash[:submission_format])
        item.submission_types = "discussion_topic"
      elsif ['online_upload','textwithattachments'].include?(hash[:submission_format])
        item.submission_types = "online_upload,online_text_entry"
      elsif ['online_text_entry'].include?(hash[:submission_format])
        item.submission_types = "online_text_entry"
      elsif ['webpage'].include?(hash[:submission_format])
        item.submission_types = "online_upload"
      elsif ['online_quiz'].include?(hash[:submission_format])
        item.submission_types = "online_quiz"
      elsif ['external_tool'].include?(hash[:submission_format])
        item.submission_types = "external_tool"
      end
      if item.submission_types == "online_quiz"
        item.saved_by = :quiz
      end
      if item.submission_types == "discussion_topic"
        item.saved_by = :discussion_topic
      end

      if hash[:grading_type]
        item.grading_type = hash[:grading_type]
        item.points_possible = hash[:points_possible]
      elsif grading = hash[:grading]
        hash[:due_at] ||= grading[:due_at] || grading[:due_date]
        hash[:assignment_group_migration_id] ||= grading[:assignment_group_migration_id]
        if grading[:grade_type] =~ /numeric|points/i
          item.points_possible = grading[:points_possible] ? grading[:points_possible].to_f : 10
        elsif grading[:grade_type] =~ /alphanumeric|letter_grade/i
          item.grading_type = "letter_grade"
          item.points_possible = grading[:points_possible] ? grading[:points_possible].to_f : 100
        elsif grading[:grade_type] == 'rubric'
          hash[:rubric_migration_id] ||= grading[:rubric_id]
        elsif grading[:grade_type] == 'not_graded'
          item.submission_types = 'not_graded'
        end
      end

      # Associating with a rubric or a quiz might cause item to get saved, no longer indicating
      # that it is a new record.  We need to know that below, where we add to the list of
      # imported items
      new_record = item.new_record?

      rubric = nil
      rubric = context.rubrics.find_by_migration_id(hash[:rubric_migration_id]) if hash[:rubric_migration_id]
      rubric ||= context.available_rubric(hash[:rubric_id]) if hash[:rubric_id]
      if rubric
        assoc = rubric.associate_with(item, context, :purpose => 'grading')
        assoc.use_for_grading = !!hash[:rubric_use_for_grading] if hash.has_key?(:rubric_use_for_grading)
        assoc.hide_score_total = !!hash[:rubric_hide_score_total] if hash.has_key?(:rubric_hide_score_total)
        if hash[:saved_rubric_comments]
          assoc.summary_data ||= {}
          assoc.summary_data[:saved_comments] ||= {}
          assoc.summary_data[:saved_comments] = hash[:saved_rubric_comments]
        end
        assoc.save

        item.points_possible ||= rubric.points_possible if item.infer_grading_type == "points"
      end
      if hash[:grading_standard_migration_id]
        gs = context.grading_standards.find_by_migration_id(hash[:grading_standard_migration_id])
        item.grading_standard = gs if gs
      end
      if quiz
        item.quiz = quiz
      elsif hash[:quiz_migration_id]
        if q = context.quizzes.find_by_migration_id(hash[:quiz_migration_id])
          if !item.quiz || item.quiz.id == q.id
            # the quiz is published because it has an assignment
            q.assignment = item
            q.generate_quiz_data
            q.published_at = Time.now
            q.workflow_state = 'available'
            q.save
          end
        end
        item.submission_types = 'online_quiz'
        item.saved_by = :quiz
      end
      if hash[:assignment_group_migration_id]
        item.assignment_group = context.assignment_groups.find_by_migration_id(hash[:assignment_group_migration_id])
      end
      item.assignment_group ||= context.assignment_groups.find_or_create_by_name(t :imported_assignments_group, "Imported Assignments")

      hash[:due_at] ||= hash[:due_date]
      [:due_at, :lock_at, :unlock_at, :peer_reviews_due_at].each do |key|
        item.send"#{key}=", Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[key]) unless hash[key].nil?
      end

      [:turnitin_enabled, :peer_reviews_assigned, :peer_reviews,
       :automatic_peer_reviews, :anonymous_peer_reviews,
       :grade_group_students_individually, :allowed_extensions,
       :position, :peer_review_count, :muted
      ].each do |prop|
        item.send("#{prop}=", hash[prop]) unless hash[prop].nil?
      end

      migration.add_imported_item(item) if migration
      item.save_without_broadcasting!

      if migration
        missing_links.each do |field, missing_links|
          migration.add_missing_content_links(:class => item.class.to_s,
            :id => item.id, :field => field, :missing_links => missing_links,
            :url => "/#{context.class.to_s.underscore.pluralize}/#{context.id}/#{item.class.to_s.demodulize.underscore.pluralize}/#{item.id}")
        end
      end

      if item.submission_types == 'external_tool'
        tag = item.create_external_tool_tag(:url => hash[:external_tool_url], :new_tab => hash[:external_tool_new_tab])
        tag.content_type = 'ContextExternalTool'
        if !tag.save
          migration.add_warning(t('errors.import.external_tool_url', "The url for the external tool assignment \"%{assignment_name}\" wasn't valid.", :assignment_name => item.title)) if migration && tag.errors["url"]
          item.association(:external_tool_tag).target = nil # otherwise it will trigger destroy on the tag
        end
      end

      if context.respond_to?(:assignment_group_no_drop_assignments) && context.assignment_group_no_drop_assignments
        if group = context.assignment_group_no_drop_assignments[item.migration_id]
          AssignmentGroup.add_never_drop_assignment(group, item)
        end
      end

      item
    end
  end
end
