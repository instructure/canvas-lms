# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module Importers
  class CourseContentImporter < Importer
    self.item_class = Course

    def self.process_migration_files(data, migration)
      data["all_files_export"] ||= {}
      data["all_files_export"]["file_path"] ||= data["all_files_zip"]
      return unless data["all_files_export"]["file_path"] && File.exist?(data["all_files_export"]["file_path"])

      params = migration.migration_settings[:migration_ids_to_import]
      valid_paths = []
      (data["file_map"] || {}).each_value do |file|
        path = file["path_name"].starts_with?("/") ? file["path_name"][1..] : file["path_name"]
        migration.add_attachment_path(path, file["migration_id"])
        if migration.import_object?("attachments", file["migration_id"]) || migration.import_object?("files", file["migration_id"])
          if file["errored"]
            migration.add_warning(t(:file_import_warning, "File %{file} could not be found", file: File.basename(file["path_name"])))
          else
            valid_paths << path
          end
        end
      end
      valid_paths = [0] if valid_paths.empty? && params[:copy] && params[:copy][:files]
      logger.debug "adding #{valid_paths.length} files"
      total = valid_paths.length
      if valid_paths != [0]
        current = 0
        last = current
        callback = proc do
          current += 1
          if (current - last) > 10
            last = current
            migration.update_import_progress((current.to_f / total) * 18.0)
          end
        end
        unzip_opts = {
          course: migration.context,
          filename: data["all_files_export"]["file_path"],
          valid_paths:,
          callback:,
          logger:,
          rename_files: migration.migration_settings[:files_import_allow_rename],
          migration_id_map: migration.attachment_path_id_lookup,
        }
        if (root_path = migration.migration_settings[:files_import_root_path])
          unzip_opts[:root_directory] = Folder.assert_path(
            root_path, migration.context
          )
        end
        unzipper = UnzipAttachment.new(unzip_opts)
        migration.update_import_progress(1.0)
        unzipper.process
      end
    end

    def self.import_media_objects(mo_attachments, migration)
      wait_for_completion = migration&.canvas_import?
      unless mo_attachments.blank?
        MediaObject.add_media_files(mo_attachments, wait_for_completion)
      end
    end

    def self.import_content(course, data, _params, migration)
      logger.debug "starting import"

      Importers.disable_live_events! do
        Importers::ContentImporterHelper.add_assessment_id_prepend(course, data, migration)
        course.full_migration_hash = data
        course.external_url_hash = {}
        course.migration_results = []

        migration.check_cross_institution
        logger.debug "migration is cross-institution; external references will not be used" if migration.cross_institution?

        (data["web_link_categories"] || []).pluck("links").flatten.each do |link|
          course.external_url_hash[link["link_id"]] = link
        end
        ActiveRecord::Base.skip_touch_context

        unless migration.for_course_copy?
          migration.find_source_course_for_import if migration.canvas_import?
          Importers::ContextModuleImporter.select_all_linked_module_items(data, migration)
          Importers::GradingStandardImporter.select_course_grading_standard(data, migration)
          # These only need to be processed once
          Attachment.skip_media_object_creation do
            process_migration_files(data, migration)
            migration.update_import_progress(18)
            Importers::AttachmentImporter.process_migration(data, migration)
            migration.update_import_progress(20)
            mo_attachments = migration.imported_migration_items_by_class(Attachment).find_all { |i| i.media_entry_id.present? }
            begin
              import_media_objects(mo_attachments, migration)
            rescue => e
              er = Canvas::Errors.capture_exception(:import_media_objects, e)[:error_report]
              error_message = t("Failed to import media objects")
              migration.add_error(error_message, error_report_id: er)
            end
          end
        end

        if (!migration.for_course_copy? || Account.site_admin.feature_enabled?(:media_links_use_attachment_id)) &&
           (migration.canvas_import? || migration.for_master_course_import?)
          migration.update_import_progress(30)
          Importers::MediaTrackImporter.process_migration(data[:media_tracks], migration)
        end

        migration.update_import_progress(35)
        unless migration.quizzes_next_banks_migration?
          question_data = Importers::AssessmentQuestionImporter.process_migration(data, migration)
          migration.update_import_progress(45)
        end
        Importers::GroupImporter.process_migration(data, migration)
        migration.update_import_progress(48)
        Importers::LearningOutcomeImporter.process_migration(data, migration)
        migration.update_import_progress(50)
        Importers::RubricImporter.process_migration(data, migration)
        migration.update_import_progress(52)
        course.assignment_group_no_drop_assignments = {}
        Importers::AssignmentGroupImporter.process_migration(data, migration)
        migration.update_import_progress(54)
        Importers::ExternalFeedImporter.process_migration(data, migration)
        migration.update_import_progress(56)
        Importers::GradingStandardImporter.process_migration(data, migration)
        migration.update_import_progress(58)
        Importers::ContextExternalToolImporter.process_migration(data, migration)
        migration.update_import_progress(60)
        Importers::ToolProfileImporter.process_migration(data, migration)
        migration.update_import_progress(61)

        Assignment.suspend_due_date_caching do
          Importers::QuizImporter.process_migration(data, migration, question_data)
          migration.update_import_progress(65)
        end

        Assignment.suspend_due_date_caching do
          Importers::DiscussionTopicImporter.process_migration(data, migration)
          migration.update_import_progress(70)
        end
        Importers::WikiPageImporter.process_migration(data, migration)
        migration.update_import_progress(75)

        Assignment.suspend_due_date_caching do
          Importers::AssignmentImporter.process_migration(data, migration)
          migration.update_import_progress(80)
        end

        module_id = migration.migration_settings[:insert_into_module_id].presence
        unless module_id && course.context_modules.where(id: module_id).exists? # we're importing into a module so don't create new ones
          Importers::ContextModuleImporter.process_migration(data, migration)
        end

        migration.update_import_progress(85)
        Importers::WikiPageImporter.process_migration_course_outline(data, migration)
        Importers::CalendarEventImporter.process_migration(data, migration)
        Importers::LtiResourceLinkImporter.process_migration(data, migration)

        # FIXME: Eventually remove feature flag checking
        Importers::CoursePaceImporter.process_migration(data, migration) if course.account.feature_enabled?(:course_paces)

        everything_selected = !migration.copy_options || migration.is_set?(migration.copy_options[:everything])

        if (everything_selected || migration.is_set?(migration.copy_options[:all_course_settings])) && !(migration.should_skip_import? "all_course_settings")
          import_settings_from_migration(course, data, migration)
          Importers::LatePolicyImporter.process_migration(data, migration) unless migration.should_skip_import? "LatePolicy"
        end
        migration.update_import_progress(90)

        if (migration.migration_settings[:import_blueprint_settings] || (migration.copy_options && migration.copy_options[:all_blueprint_settings])) &&
           (course.account.grants_any_right?(migration.user, :manage_courses, :manage_courses_admin) && course.account.grants_right?(migration.user, :manage_master_courses))
          Importers::BlueprintSettingsImporter.process_migration(data, migration)
        end

        # be very explicit about draft state courses, but be liberal toward legacy courses
        if course.wiki.has_no_front_page &&
           migration.for_course_copy? &&
           !migration.for_master_course_import? &&
           (source = migration.source_course || Course.where(id: migration.migration_settings[:source_course_id]).first)
          mig_id = migration.content_export.create_key(source.wiki.front_page)
          if (new_front_page = course.wiki_pages.where(migration_id: mig_id).first)
            course.wiki.set_front_page_url!(new_front_page.url)
          end
        end
        front_page = course.wiki.front_page
        course.wiki.unset_front_page! if front_page.nil? || front_page.new_record?

        syllabus_should_be_added = everything_selected || migration.copy_options[:syllabus_body] || migration.copy_options[:all_syllabus_body]
        if syllabus_should_be_added
          syllabus_body = data[:course][:syllabus_body] if data[:course]
          import_syllabus_from_migration(course, syllabus_body, migration) if syllabus_body
        end

        course.save! if course.changed?

        migration.resolve_content_links!
        migration.update_import_progress(95)

        if data["external_content"]
          Canvas::Migration::ExternalContent::Migrator.send_imported_content(migration, data["external_content"])
        end
        migration.update_import_progress(97)

        insert_into_module(course, migration, data)
        migration.update_import_progress(98)

        move_to_assignment_group(course, migration)
        migration.update_import_progress(99)

        adjust_dates(course, migration)

        migration.progress = 100
        migration.migration_settings ||= {}

        imported_asset_hash = {}
        migration.imported_migration_items_hash.each { |k, assets| imported_asset_hash[k] = assets.values.map(&:id).join(",") if assets.present? }
        migration.migration_settings[:imported_assets] = imported_asset_hash
        migration.migration_settings[:attachment_path_id_lookup] = migration.attachment_path_id_lookup
        migration.workflow_state = :imported unless post_processing?(migration)
        migration.save

        if migration.for_master_course_import? &&
           migration.migration_settings[:publish_after_completion] &&
           course.unpublished?
          # i could just do it directly but this way preserves the audit trail
          course.update_one({ event: "offer" }, migration.user, :blueprint_sync)
        end

        if course.changed?
          course.save!
        else
          course.touch
        end

        clear_assignment_and_quiz_caches(migration)
      end

      migration.trigger_live_events!
      Auditors::Course.record_copied(migration.source_course, course, migration.user, source: migration.initiated_source)
      InstStatsd::Statsd.increment("content_migrations.import_success")
      duration = Time.now - migration.created_at
      InstStatsd::Statsd.timing("content_migrations.import_duration", duration, tags: { migration_type: migration.migration_type })
      migration.imported_migration_items
    rescue Exception # rubocop:disable Lint/RescueException
      InstStatsd::Statsd.increment("content_migrations.import_failure")
      raise
    ensure
      ActiveRecord::Base.skip_touch_context(false)
    end

    def self.insert_into_module(course, migration, data)
      module_id = migration.migration_settings[:insert_into_module_id]
      return unless module_id.present?

      mod = course.context_modules.find_by(id: module_id)
      return unless mod

      items = (data[:modules] || []).pluck(:items).flatten! || []
      items.each do |hash|
        Importers::ContextModuleImporter.add_module_item_from_migration(mod, hash, 0, migration.context, {}, migration)
      end

      imported_items = migration.imported_migration_items_for_insert_type
      return unless imported_items.any?

      # get rid of assignments relating to quizzes lest they create 2 quizzes in the module
      quiz_assignments = imported_items.filter { |item| item.is_a? Quizzes::Quiz }.pluck(:assignment_id)
      imported_items.filter! { |item| !(item.is_a?(Assignment) && quiz_assignments.include?(item.id)) }
      start_pos = migration.migration_settings[:insert_into_module_position]
      start_pos = start_pos.to_i unless start_pos.nil? # 0 = start; nil = end
      mod.insert_items(imported_items, start_pos)
    end

    def self.move_to_assignment_group(course, migration)
      ag_id = migration.migration_settings[:move_to_assignment_group_id]
      return unless ag_id.present?

      ag = course.assignment_groups.find_by(id: ag_id)
      return unless ag

      assignments = migration.imported_migration_items_by_class(Assignment)
      quizzes = migration.imported_migration_items_by_class(Quizzes::Quiz)
      return unless assignments.any? || quizzes.any?

      # various callbacks run on assignment_group_id change, so we'll do these one by one
      # (the expected use case for this feature is a migration containing a single assignment anyhow)
      assignments.each do |assignment|
        next if assignment.assignment_group == ag

        assignment.assignment_group = ag
        assignment.position = nil
        assignment.save!
      end

      quizzes.each do |quiz|
        next if quiz.assignment_group == ag

        quiz.assignment_group = ag
        quiz.save!
      end
    end

    def self.adjust_dates(course, migration)
      # Adjust dates
      if (shift_options = migration.date_shift_options)
        shift_options = shift_date_options(course, shift_options)

        Assignment.suspend_due_date_caching do
          migration.imported_migration_items_by_class(Assignment).each do |event|
            event.reload # just in case
            event.due_at = shift_date(event.due_at, shift_options)
            event.lock_at = shift_date(event.lock_at, shift_options)
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.peer_reviews_due_at = shift_date(event.peer_reviews_due_at, shift_options)
            event.needs_update_cached_due_dates = true if event.update_cached_due_dates?
            event.save_without_broadcasting
            if event.errors.any?
              migration.add_warning(t("Couldn't adjust dates on assignment %{name} (ID %{id})", name: event.name, id: event.id.to_s))
            end
          end
        end

        migration.imported_migration_items_by_class(Attachment).each do |event|
          event.lock_at = shift_date(event.lock_at, shift_options)
          event.unlock_at = shift_date(event.unlock_at, shift_options)
          event.save_without_broadcasting
        end

        migration.imported_migration_items_by_class(Folder).each do |event|
          event.lock_at = shift_date(event.lock_at, shift_options)
          event.unlock_at = shift_date(event.unlock_at, shift_options)
          event.save
        end

        (migration.imported_migration_items_by_class(Announcement) +
          migration.imported_migration_items_by_class(DiscussionTopic)).each do |event|
          event.reload
          event.saved_by = :after_migration
          event.delayed_post_at = shift_date(event.delayed_post_at, shift_options)
          event.lock_at = shift_date(event.lock_at, shift_options)
          event.todo_date = shift_date(event.todo_date, shift_options)
          event.save_without_broadcasting
        end

        migration.imported_migration_items_by_class(CalendarEvent).each do |event|
          event.reload
          event.start_at = shift_date(event.start_at, shift_options)
          event.end_at = shift_date(event.end_at, shift_options)
          if event.all_day_date
            ad_time = event.all_day_date.in_time_zone(shift_options[:time_zone] || Time.zone)
            event.all_day_date = shift_date(ad_time, shift_options).try(:to_date)
          end
          event.save_without_broadcasting
        end

        Assignment.suspend_due_date_caching do
          migration.imported_migration_items_by_class(Quizzes::Quiz).each do |event|
            event.reload # have to reload the quiz_data to keep link resolution - the others are just in case
            event.due_at = shift_date(event.due_at, shift_options)
            event.lock_at = shift_date(event.lock_at, shift_options)
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.show_correct_answers_at = shift_date(event.show_correct_answers_at, shift_options)
            event.hide_correct_answers_at = shift_date(event.hide_correct_answers_at, shift_options)
            event.saved_by = :migration
            event.save
          end

          migration.imported_migration_items_by_class(AssignmentOverride).each do |event|
            AssignmentOverride.overridden_dates.each do |field|
              date = event.send(field)
              next unless date

              event.send(:"#{field}=", shift_date(date, shift_options))
            end
            event.save_without_broadcasting
          end
        end

        migration.imported_migration_items_by_class(ContextModule).each do |event|
          event.unlock_at = shift_date(event.unlock_at, shift_options)
          event.save
        end

        migration.imported_migration_items_by_class(WikiPage).each do |event|
          event.reload
          event.todo_date = shift_date(event.todo_date, shift_options)
          event.publish_at = shift_date(event.publish_at, shift_options)
          event.save_without_broadcasting
        end

        course.set_course_dates_if_blank(shift_options)
      else
        (migration.imported_migration_items_by_class(Announcement) +
          migration.imported_migration_items_by_class(DiscussionTopic)).each do |event|
          event.saved_by = :after_migration
          event.schedule_delayed_transitions
        end
      end
    rescue
      migration.add_warning(t(:due_dates_warning, "Couldn't adjust the due dates."), $!)
    end

    def self.clear_assignment_and_quiz_caches(migration)
      assignments = migration.imported_migration_items_by_class(Assignment).select(&:needs_update_cached_due_dates)
      if assignments.any?
        Assignment.clear_cache_keys(assignments, :availability)
        SubmissionLifecycleManager.recompute_course(migration.context, assignments:, update_grades: true, executing_user: migration.user, skip_late_policy_applicator: !!migration.date_shift_options)
      end
      quizzes = migration.imported_migration_items_by_class(Quizzes::Quiz).select(&:should_clear_availability_cache)
      Quizzes::Quiz.clear_cache_keys(quizzes, :availability) if quizzes.any?
    end

    def self.post_processing?(migration)
      migration.quizzes_next_migration?
    end

    def self.import_syllabus_from_migration(course, syllabus_body, migration)
      if migration.for_master_course_import?
        course.master_migration = migration
      end
      course.syllabus_body = migration.convert_html(syllabus_body, :syllabus, nil, :syllabus)
    end

    def self.import_settings_from_migration(course, data, migration)
      return unless data[:course]

      settings = data[:course]
      if settings[:tab_configuration].is_a?(Array)
        tab_config = []
        all_tools = nil
        settings[:tab_configuration].each do |tab|
          if tab["id"].is_a?(String) && tab["id"].start_with?("context_external_tool_")
            tool_mig_id = tab["id"].sub("context_external_tool_", "")
            all_tools ||= if migration.cross_institution?
                            course.context_external_tools.having_setting("course_navigation")
                          else
                            ContextExternalTool.find_all_for(course, :course_navigation)
                          end
            if (tool = all_tools.detect { |t| t.migration_id == tool_mig_id } ||
                all_tools.detect do |t|
                  CC::CCHelper.create_key(t) == tool_mig_id ||
                  CC::CCHelper.create_key(t, global: true) == tool_mig_id
                end)
              # translate the migration_id to a real id
              tab["id"] = "context_external_tool_#{tool.id}"
              tab_config << tab
            end
          else
            tab_config << tab
          end
        end
        course.tab_configuration = tab_config
      end
      if settings[:storage_quota] && course.account.grants_right?(migration.user, :manage_storage_quotas)
        course.storage_quota = settings[:storage_quota]
      end
      atts = Course.clonable_attributes
      atts -= Canvas::Migration::MigratorHelper::COURSE_NO_COPY_ATTS

      if course.root_account.settings[:prevent_course_availability_editing_by_teachers] && !course.account.grants_right?(migration.user, :read_as_admin)
        atts -= [:restrict_enrollments_to_course_dates]
      end

      atts -= [:is_public_to_auth_users, :is_public] if migration.should_skip_import? "visibility_settings"

      course.settings_will_change! unless atts.empty?

      # superhax to force new wiki front page if home view changed (or is master course sync)
      if settings["default_view"] && data[:wikis] && (migration.for_master_course_import? || (settings["default_view"] != course.default_view))
        course.wiki # ensure that it exists already
        if (page_hash = data[:wikis].detect { |h| h[:front_page] }) &&
           (page = migration.find_imported_migration_item(WikiPage, page_hash[:migration_id]))
          page.set_as_front_page!
        end
      end

      if settings.key?("overridden_course_visibility")
        course.apply_overridden_course_visibility(settings.delete("overridden_course_visibility"))
      end

      if migration.for_master_course_import?
        course.start_at    = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(settings["start_at"]) if settings.key?("start_at")
        course.conclude_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(settings["conclude_at"]) if settings.key?("conclude_at")
      end

      settings.slice(*atts.map(&:to_s)).each do |key, val|
        course.send(:"#{key}=", val)
      end
      if settings.key?(:grading_standard_enabled)
        if settings[:grading_standard_enabled]
          course.grading_standard_enabled = true
          if settings[:grading_standard_identifier_ref]
            if (gs = course.grading_standards.where(migration_id: settings[:grading_standard_identifier_ref]).first)
              course.grading_standard = gs
            else
              migration.add_warning(t(:copied_grading_standard_warning, "Couldn't find copied grading standard for the course."))
            end
          elsif settings[:grading_standard_id].present?
            if (gs = GradingStandard.for(course).where(id: settings[:grading_standard_id]).first)
              course.grading_standard = gs
            else
              migration.add_warning(t(:account_grading_standard_warning, "Couldn't find account grading standard for the course."))
            end
          end
        elsif migration.for_master_course_import?
          course.grading_standard_enabled = false
          course.grading_standard = nil
        end
      end
      if (image_url = settings[:image_url])
        course.image_url = image_url
        course.image_id = nil
      elsif (image_ref = settings[:image_identifier_ref]) &&
            (image_att = course.attachments.where(migration_id: image_ref).active.first)
        course.image_id = image_att.id
        course.image_url = nil
      end
      if (banner_image_url = settings[:banner_image_url])
        course.banner_image_url = banner_image_url
        course.banner_image_id = nil
      elsif (image_ref = settings[:banner_image_identifier_ref]) &&
            (image_att = course.attachments.where(migration_id: image_ref).active.first)
        course.banner_image_id = image_att.id
        course.banner_image_url = nil
      end
      if settings[:lock_all_announcements]
        Announcement.lock_from_course(course)
      end

      if settings.key?(:time_zone)
        course.time_zone = settings[:time_zone]
      end

      if settings.key?(:default_post_policy)
        post_manually = Canvas::Plugin.value_to_boolean(settings.dig(:default_post_policy, :post_manually))
        course.default_post_policy.update!(post_manually:)
      end

      if settings.key?(:allow_final_grade_override) && course.account.feature_enabled?(:final_grades_override)
        course.allow_final_grade_override = settings[:allow_final_grade_override]
      end

      if settings.key?(:enable_course_paces) && course.account.feature_enabled?(:course_paces)
        course.enable_course_paces = settings[:enable_course_paces]
      end
    end

    def self.shift_date_options(course, options = {})
      return({ remove_dates: true }) if Canvas::Plugin.value_to_boolean(options[:remove_dates])

      result = {}
      remove_bad_end_dates!(options)
      result[:old_start_date] = Date.parse(options[:old_start_date]) rescue course.real_start_date
      result[:old_end_date] = Date.parse(options[:old_end_date]) rescue course.real_end_date
      result[:new_start_date] = Date.parse(options[:new_start_date]) rescue course.real_start_date
      result[:new_end_date] = Date.parse(options[:new_end_date]) rescue nil
      # infer a new end date preserving course duration, instead of using the unshifted old end date
      if result[:new_end_date].nil? && result[:new_start_date].present? &&
         result[:old_end_date].present? && result[:old_start_date].present?
        result[:new_end_date] = result[:new_start_date] + (result[:old_end_date] - result[:old_start_date])
      end
      result[:day_substitutions] = options[:day_substitutions]
      result[:time_zone] = Time.find_zone(options[:time_zone])
      result[:time_zone] ||= course.root_account.default_time_zone unless course.root_account.nil?
      time_zone = result[:time_zone] || Time.zone
      result[:default_start_at] = time_zone.parse(options[:new_start_date]) rescue nil
      result[:default_conclude_at] = time_zone.parse(options[:new_end_date]) rescue nil
      result
    end

    def self.remove_bad_end_dates!(options)
      old_start = DateTime.parse(options[:old_start_date]) rescue nil
      old_end   = DateTime.parse(options[:old_end_date]) rescue nil
      options[:old_end_date] = nil if old_start && old_end && old_end < old_start
      new_start = DateTime.parse(options[:new_start_date]) rescue nil
      new_end   = DateTime.parse(options[:new_end_date]) rescue nil
      options[:new_end_date] = nil if new_start && new_end && new_end < new_start
    end

    def self.shift_date(time, options = {})
      return nil unless time
      return nil if options[:remove_dates]

      time_zone = options[:time_zone] || Time.zone
      Time.use_zone time_zone do
        time = ActiveSupport::TimeWithZone.new(time.utc, Time.zone)
        old_date = time.to_date
        old_start_date = options[:old_start_date]
        old_end_date = options[:old_end_date]
        new_start_date = options[:new_start_date]
        new_end_date = options[:new_end_date]
        return time unless old_start_date && old_end_date && new_start_date && new_end_date

        old_full_diff = old_end_date - old_start_date
        old_event_diff = old_date - old_start_date
        old_event_percent = (old_full_diff > 0) ? old_event_diff.to_f / old_full_diff.to_f : 0
        new_full_diff = new_end_date - new_start_date
        new_event_diff = (new_full_diff.to_f * old_event_percent).round
        new_date = new_start_date + new_event_diff
        options[:day_substitutions] ||= {}
        options[:day_substitutions][old_date.wday.to_s] ||= old_date.wday.to_s
        if options[:day_substitutions] &&
           options[:day_substitutions][old_date.wday.to_s] &&
           new_date.wday != options[:day_substitutions][old_date.wday.to_s].to_i
          new_date += (options[:day_substitutions][old_date.wday.to_s].to_i - new_date.wday) % 7
          new_date -= 7 unless new_date - 7 < new_start_date
        end

        new_time = Time.utc(new_date.year, new_date.month, new_date.day, (time.hour rescue 0), (time.min rescue 0)).in_time_zone
        new_time -= new_time.utc_offset
        new_time
      end
    end
  end
end
