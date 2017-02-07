require_dependency 'importers'

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
      max = migration.context.assignments.pluck(:position).compact.max || 0
      assignments.each_with_index{|m, idx| cases << " WHEN migration_id=#{conn.quote(m['assignment_id'])} THEN #{max + idx + 1} " if m['assignment_id'] }
      unless cases.empty?
        conn.execute("UPDATE #{Assignment.quoted_table_name} SET position=CASE #{cases.join(' ')} ELSE NULL END WHERE context_id=#{migration.context.id} AND context_type=#{conn.quote(migration.context.class.to_s)} AND migration_id IN (#{migration_ids.map{|id| conn.quote(id)}.join(',')})")
      end
    end

    def self.import_from_migration(hash, context, migration, item=nil, quiz=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:assignments_to_import] && !hash[:assignments_to_import][hash[:migration_id]]
      item ||= Assignment.where(context_type: context.class.to_s, context_id: context, id: hash[:id]).first
      item ||= Assignment.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= context.assignments.temp_record #new(:context => context)

      item.mark_as_importing!(migration)

      item.title = hash[:title]
      item.title = I18n.t('untitled assignment') if item.title.blank?
      item.migration_id = hash[:migration_id]
      if item.new_record? || item.deleted?
        if item.can_unpublish?
          item.workflow_state = (hash[:workflow_state] || 'published')
        else
          item.workflow_state = 'published'
        end
      end
      if hash[:instructions_in_html] == false
        self.extend TextHelper
      end

      description = ""
      if hash[:instructions_in_html] == false
        description += migration.convert_text(hash[:description] || "")
        description += migration.convert_text(hash[:instructions] || "")
      else
        description += migration.convert_html(hash[:description] || "", :assignment, hash[:migration_id], :description)
        description += migration.convert_html(hash[:instructions] || "", :assignment, hash[:migration_id], :description)
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
      if hash[:assignment_group_migration_id]
        item.assignment_group = context.assignment_groups.where(migration_id: hash[:assignment_group_migration_id]).first
      end
      item.assignment_group ||= context.assignment_groups.where(name: t(:imported_assignments_group, "Imported Assignments")).first_or_create

      if item.points_possible.to_i < 0
        item.points_possible = 0
      end

      item.save_without_broadcasting!

      rubric = nil
      rubric = context.rubrics.where(migration_id: hash[:rubric_migration_id]).first if hash[:rubric_migration_id]
      rubric ||= context.available_rubric(hash[:rubric_id]) if hash[:rubric_id]
      if rubric
        assoc = rubric.associate_with(item, context, :purpose => 'grading', :skip_updating_points_possible => true)
        assoc.use_for_grading = !!hash[:rubric_use_for_grading] if hash.has_key?(:rubric_use_for_grading)
        assoc.hide_score_total = !!hash[:rubric_hide_score_total] if hash.has_key?(:rubric_hide_score_total)
        if hash[:saved_rubric_comments]
          assoc.summary_data ||= {}
          assoc.summary_data[:saved_comments] ||= {}
          assoc.summary_data[:saved_comments] = hash[:saved_rubric_comments]
        end
        assoc.skip_updating_points_possible = true
        assoc.save

        item.points_possible ||= rubric.points_possible if item.infer_grading_type == "points"
      end

      if hash[:assignment_overrides]
        hash[:assignment_overrides].each do |o|
          override = item.assignment_overrides.where(o.slice(:set_type, :set_id)).first
          override ||= item.assignment_overrides.build
          override.set_type = o[:set_type]
          override.title = o[:title]
          override.set_id = o[:set_id]
          AssignmentOverride.overridden_dates.each do |field|
            next unless o.key?(field)
            override.send "override_#{field}", Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(o[field])
          end
          override.save!
          migration.add_imported_item(override,
            key: [item.migration_id, override.set_type, override.set_id].join('/'))
        end
        if hash.has_key?(:only_visible_to_overrides)
          item.only_visible_to_overrides = hash[:only_visible_to_overrides]          
        end
      end

      if hash[:grading_standard_migration_id]
        gs = context.grading_standards.where(migration_id: hash[:grading_standard_migration_id]).first
        item.grading_standard = gs if gs
      elsif hash[:grading_standard_id] && migration
        gs = GradingStandard.for(context).where(id: hash[:grading_standard_id]).first unless migration.cross_institution?
        if gs
          item.grading_standard = gs if gs
        else
          migration.add_warning(t('errors.import.grading_standard_not_found', %{The assignment "%{title}" referenced a grading scheme that was not found in the target course's account chain.}, :title => hash[:title]))
        end
      end
      if quiz
        item.quiz = quiz
      elsif hash[:quiz_migration_id]
        if q = context.quizzes.where(migration_id: hash[:quiz_migration_id]).first
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

      hash[:due_at] ||= hash[:due_date]
      [:due_at, :lock_at, :unlock_at, :peer_reviews_due_at].each do |key|
        item.send"#{key}=", Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[key]) unless hash[key].nil?
      end

      if hash[:has_group_category]
        item.group_category = context.group_categories.active.where(:name => hash[:group_category]).first
        item.group_category ||= context.group_categories.active.where(:name => t("Project Groups")).first_or_create
      end

      [:turnitin_enabled, :vericite_enabled, :peer_reviews,
       :automatic_peer_reviews, :anonymous_peer_reviews,
       :grade_group_students_individually, :allowed_extensions,
       :position, :peer_review_count, :muted, :moderated_grading,
       :omit_from_final_grade, :intra_group_peer_reviews
      ].each do |prop|
        item.send("#{prop}=", hash[prop]) unless hash[prop].nil?
      end

      if item.turnitin_enabled
        settings = JSON.parse(hash[:turnitin_settings]).with_indifferent_access
        settings[:created] = false if settings[:created]
        item.turnitin_settings = settings
      end

      migration.add_imported_item(item)

      if migration.date_shift_options
        # Unfortunately, we save the assignment here, and then shift dates and
        # save the assignment again later in the course migration. Saving here
        # would normally schedule the auto peer reviews job with the
        # pre-shifted due date, which is probably in the past. After shifting
        # dates, it is saved again, but because the job is stranded, and
        # because the new date is probably later than the old date, the new job
        # is not scheduled, even though that's the date we want.
        item.skip_schedule_peer_reviews = true
      end
      item.save_without_broadcasting!
      item.skip_schedule_peer_reviews = nil

      if item.submission_types == 'external_tool'
        tag = item.create_external_tool_tag(:url => hash[:external_tool_url], :new_tab => hash[:external_tool_new_tab])
        if hash[:external_tool_id] && migration && !migration.cross_institution?
          tool_id = hash[:external_tool_id].to_i
          tag.content_id = tool_id if ContextExternalTool.all_tools_for(context).where(id: tool_id).exists?
        elsif hash[:external_tool_migration_id]
          tool = context.context_external_tools.where(migration_id: hash[:external_tool_migration_id]).first
          tag.content_id = tool.id if tool
        end
        tag.content_type = 'ContextExternalTool'
        if !tag.save
          if tag.errors["url"]
            migration.add_warning(t('errors.import.external_tool_url',
              "The url for the external tool assignment \"%{assignment_name}\" wasn't valid.",
              :assignment_name => item.title))
          end
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
