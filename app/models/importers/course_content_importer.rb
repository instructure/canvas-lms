module Importers
  class CourseContentImporter < Importer

    self.item_class = Course
    Importers.register_content_importer(self)

    def self.process_migration_files(course, data, migration)
      data['all_files_export'] ||= {}
      data['all_files_export']['file_path'] ||= data['all_files_zip']
      return unless data['all_files_export']['file_path'] && File.exist?(data['all_files_export']['file_path'])

      course.attachment_path_id_lookup ||= {}
      course.attachment_path_id_lookup_lower ||= {}
      params = migration.migration_settings[:migration_ids_to_import]
      valid_paths = []
      (data['file_map'] || {}).each do |id, file|
        path = file['path_name'].starts_with?('/') ? file['path_name'][1..-1] : file['path_name']
        course.attachment_path_id_lookup[path] = file['migration_id']
        course.attachment_path_id_lookup_lower[path.downcase] = file['migration_id']
        if migration.import_object?("attachments", file['migration_id']) || migration.import_object?("files", file['migration_id'])
          if file['errored']
            migration.add_warning(t(:file_import_warning, "File %{file} could not be found", :file => File.basename(file['path_name'])))
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
        callback = Proc.new do
          current += 1
          if (current - last) > 10
            last = current
            migration.update_import_progress((current.to_f/total) * 18.0)
          end
        end
        unzip_opts = {
            :course => migration.context,
            :filename => data['all_files_export']['file_path'],
            :valid_paths => valid_paths,
            :callback => callback,
            :logger => logger,
            :rename_files => migration.migration_settings[:files_import_allow_rename],
            :migration_id_map => course.attachment_path_id_lookup,
        }
        if root_path = migration.migration_settings[:files_import_root_path]
          unzip_opts[:root_directory] = Folder.assert_path(
              root_path, migration.context)
        end
        unzipper = UnzipAttachment.new(unzip_opts)
        migration.update_import_progress(1.0)
        unzipper.process
      end
    end

    def self.import_media_objects(mo_attachments, migration)
      wait_for_completion = migration && migration.canvas_import?
      unless mo_attachments.blank?
        MediaObject.add_media_files(mo_attachments, wait_for_completion)
      end
    end

    def self.import_content(course, data, params, migration)
      params ||= {:copy=>{}}
      logger.debug "starting import"
      course.full_migration_hash = data
      course.external_url_hash = {}
      course.migration_results = []

      (data['web_link_categories'] || []).map{|c| c['links'] }.flatten.each do |link|
        course.external_url_hash[link['link_id']] = link
      end
      ActiveRecord::Base.skip_touch_context

      if !migration.for_course_copy?
        # These only need to be processed once
        Attachment.skip_media_object_creation do
          self.process_migration_files(course, data, migration); migration.update_import_progress(18)
          Importers::AttachmentImporter.process_migration(data, migration); migration.update_import_progress(20)
          mo_attachments = migration.imported_migration_items_by_class(Attachment).find_all { |i| i.media_entry_id.present? }
          begin
            self.import_media_objects(mo_attachments, migration)
          rescue => e
            er = ErrorReport.log_exception(:import_media_objects, e)
            migration.add_error(t(:failed_import_media_objects, %{Failed to import media objects}), error_report_id: er.id)
          end
        end
        if migration.canvas_import?
          migration.update_import_progress(30)
          Importers::MediaTrackImporter.process_migration(data[:media_tracks], migration)
        end
      end

      migration.update_import_progress(31)
      question_data = Importers::AssessmentQuestionImporter.process_migration(data, migration); migration.update_import_progress(35)
      Importers::GroupImporter.process_migration(data, migration); migration.update_import_progress(36)
      Importers::LearningOutcomeImporter.process_migration(data, migration); migration.update_import_progress(37)
      Importers::RubricImporter.process_migration(data, migration); migration.update_import_progress(38)
      course.assignment_group_no_drop_assignments = {}
      Importers::AssignmentGroupImporter.process_migration(data, migration); migration.update_import_progress(39)
      Importers::ExternalFeedImporter.process_migration(data, migration); migration.update_import_progress(39.5)
      Importers::GradingStandardImporter.process_migration(data, migration); migration.update_import_progress(40)
      Importers::ContextExternalToolImporter.process_migration(data, migration); migration.update_import_progress(45)

      #These need to be ran twice because they can reference each other
      Importers::QuizImporter.process_migration(data, migration, question_data); migration.update_import_progress(50)
      Importers::DiscussionTopicImporter.process_migration(data, migration);migration.update_import_progress(55)
      Importers::WikiPageImporter.process_migration(data, migration);migration.update_import_progress(60)
      Importers::AssignmentImporter.process_migration(data, migration);migration.update_import_progress(65)

      # and second time...
      Importers::QuizImporter.process_migration(data, migration, question_data); migration.update_import_progress(70)
      Importers::ContextModuleImporter.process_migration(data, migration);migration.update_import_progress(72)
      Importers::DiscussionTopicImporter.process_migration(data, migration);migration.update_import_progress(75)
      Importers::WikiPageImporter.process_migration(data, migration);migration.update_import_progress(80)
      Importers::AssignmentImporter.process_migration(data, migration);migration.update_import_progress(85)

      #These aren't referenced by anything, but reference other things
      Importers::CalendarEventImporter.process_migration(data, migration);migration.update_import_progress(90)
      Importers::WikiPageImporter.process_migration_course_outline(data, migration);migration.update_import_progress(95)

      everything_selected = !migration.copy_options || migration.is_set?(migration.copy_options[:everything])
      if everything_selected || migration.is_set?(migration.copy_options[:all_course_settings])
        self.import_settings_from_migration(course, data, migration); migration.update_import_progress(96)
      end

      # be very explicit about draft state courses, but be liberal toward legacy courses
      course.wiki.check_has_front_page
      if course.feature_enabled?(:draft_state) && course.wiki.has_no_front_page
        if migration.for_course_copy? && (source = migration.source_course || Course.find_by_id(migration.migration_settings[:source_course_id]))
          mig_id = CC::CCHelper.create_key(source.wiki.front_page)
          if new_front_page = course.wiki.wiki_pages.find_by_migration_id(mig_id)
            course.wiki.set_front_page_url!(new_front_page.url)
          end
        end
      end
      front_page = course.wiki.front_page
      course.wiki.unset_front_page! if front_page.nil? || (course.feature_enabled?(:draft_state) && front_page.new_record?)

      syllabus_should_be_added = everything_selected || migration.copy_options[:syllabus_body] || migration.copy_options[:all_syllabus_body]
      if syllabus_should_be_added
        syllabus_body = data[:course][:syllabus_body] if data[:course]
        self.import_syllabus_from_migration(course, syllabus_body, migration) if syllabus_body
      end

      migration.add_warnings_for_missing_content_links

      begin
        #Adjust dates
        if shift_options = migration.date_shift_options
          shift_options = self.shift_date_options(course, shift_options)

          migration.imported_migration_items_by_class(Assignment).each do |event|
            event.due_at = shift_date(event.due_at, shift_options)
            event.lock_at = shift_date(event.lock_at, shift_options)
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.peer_reviews_due_at = shift_date(event.peer_reviews_due_at, shift_options)
            event.save_without_broadcasting!
          end

          migration.imported_migration_items_by_class(Announcement).each do |event|
            event.delayed_post_at = shift_date(event.delayed_post_at, shift_options)
            event.save_without_broadcasting!
          end

          migration.imported_migration_items_by_class(DiscussionTopic).each do |event|
            event.delayed_post_at = shift_date(event.delayed_post_at, shift_options)
            event.save_without_broadcasting!
          end

          migration.imported_migration_items_by_class(CalendarEvent).each do |event|
            event.start_at = shift_date(event.start_at, shift_options)
            event.end_at = shift_date(event.end_at, shift_options)
            event.save_without_broadcasting!
          end

          migration.imported_migration_items_by_class(Quizzes::Quiz).each do |event|
            event.due_at = shift_date(event.due_at, shift_options)
            event.lock_at = shift_date(event.lock_at, shift_options)
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.show_correct_answers_at = shift_date(event.show_correct_answers_at, shift_options)
            event.hide_correct_answers_at = shift_date(event.hide_correct_answers_at, shift_options)
            event.save!
          end

          migration.imported_migration_items_by_class(ContextModule).each do |event|
            event.unlock_at = shift_date(event.unlock_at, shift_options)
            event.start_at = shift_date(event.start_at, shift_options)
            event.end_at = shift_date(event.end_at, shift_options)
            event.save!
          end

          course.set_course_dates_if_blank(shift_options)
        end
      rescue
        migration.add_warning(t(:due_dates_warning, "Couldn't adjust the due dates."), $!)
      end
      migration.progress=100
      migration.migration_settings ||= {}
      migration.migration_settings[:imported_assets] = migration.imported_migration_items.map(&:asset_string)
      migration.workflow_state = :imported
      migration.save
      ActiveRecord::Base.skip_touch_context(false)
      if course.changed?
        course.save
      else
        course.touch
      end

      Auditors::Course.record_copied(migration.source_course, course, migration.user, source: migration.initiated_source)
      migration.imported_migration_items
    end

    def self.import_syllabus_from_migration(course, syllabus_body, migration)
      missing_links = []
      course.syllabus_body = ImportedHtmlConverter.convert(syllabus_body, course, migration) do |warn, link|
        missing_links << link if warn == :missing_link
      end
      migration.add_missing_content_links(:class => course.class.to_s,
        :id => course.id, :field => "syllabus", :missing_links => missing_links,
        :url => "/#{course.class.to_s.underscore.pluralize}/#{course.id}/assignments/syllabus")
    end

    def self.import_settings_from_migration(course, data, migration)
      return unless data[:course]
      settings = data[:course]
      if settings[:tab_configuration] && settings[:tab_configuration].is_a?(Array)
        tab_config = []
        all_tools = nil
        settings[:tab_configuration].each do |tab|
          if tab['id'].is_a?(String) && tab['id'].start_with?('context_external_tool_')
            tool_mig_id = tab['id'].sub('context_external_tool_', '')
            all_tools ||= ContextExternalTool.find_all_for(course, :course_navigation)
            if tool = (all_tools.detect{|t| t.migration_id == tool_mig_id} ||
                all_tools.detect{|t| CC::CCHelper.create_key(t) == tool_mig_id})
              # translate the migration_id to a real id
              tab['id'] = "context_external_tool_#{tool.id}"
              tab_config << tab
            end
          else
            tab_config << tab
          end
        end
        course.tab_configuration = tab_config
      end
      if settings[:storage_quota] && ( migration.for_course_copy? || course.account.grants_right?(migration.user, :manage_courses))
        course.storage_quota = settings[:storage_quota]
      end
      atts = Course.clonable_attributes
      atts -= Canvas::Migration::MigratorHelper::COURSE_NO_COPY_ATTS
      settings.slice(*atts.map(&:to_s)).each do |key, val|
        course.send("#{key}=", val)
      end
      if settings[:grading_standard_enabled]
        course.grading_standard_enabled = true
        if settings[:grading_standard_identifier_ref]
          if gs = course.grading_standards.find_by_migration_id(settings[:grading_standard_identifier_ref])
            course.grading_standard = gs
          else
            migration.add_warning(t(:copied_grading_standard_warning, "Couldn't find copied grading standard for the course."))
          end
        elsif settings[:grading_standard_id].present?
          if gs = GradingStandard.standards_for(course).find_by_id(settings[:grading_standard_id])
            course.grading_standard = gs
          else
            migration.add_warning(t(:account_grading_standard_warning,"Couldn't find account grading standard for the course." ))
          end
        end
      end
    end

    def self.shift_date_options(course, options={})
      result = {}
      result[:old_start_date] = Date.parse(options[:old_start_date]) rescue course.real_start_date
      result[:old_end_date] = Date.parse(options[:old_end_date]) rescue course.real_end_date
      result[:new_start_date] = Date.parse(options[:new_start_date]) rescue course.real_start_date
      result[:new_end_date] = Date.parse(options[:new_end_date]) rescue course.real_end_date
      result[:day_substitutions] = options[:day_substitutions]
      result[:time_zone] = options[:time_zone]
      result[:time_zone] ||= course.root_account.default_time_zone unless course.root_account.nil?

      result[:default_start_at] = DateTime.parse(options[:new_start_date]) rescue course.real_start_date
      result[:default_conclude_at] = DateTime.parse(options[:new_end_date]) rescue course.real_end_date
      Time.use_zone(result[:time_zone] || Time.zone) do
        # convert times
        [:default_start_at, :default_conclude_at].each do |k|
          old_time = result[k]
          new_time = Time.utc(old_time.year, old_time.month, old_time.day, (old_time.hour rescue 0), (old_time.min rescue 0)).in_time_zone
          new_time -= new_time.utc_offset
          result[k] = new_time
        end
      end
      result
    end

    def self.shift_date(time, options={})
      return nil unless time
      time_zone = options[:time_zone] || Time.zone
      Time.use_zone time_zone do
        time = ActiveSupport::TimeWithZone.new(time.utc, Time.zone)
        old_date = time.to_date
        new_date = old_date.clone
        old_start_date = options[:old_start_date]
        old_end_date = options[:old_end_date]
        new_start_date = options[:new_start_date]
        new_end_date = options[:new_end_date]
        return time unless old_start_date && old_end_date && new_start_date && new_end_date
        old_full_diff = old_end_date - old_start_date
        old_event_diff = old_date - old_start_date
        old_event_percent = old_full_diff > 0 ? old_event_diff.to_f / old_full_diff.to_f : 0
        new_full_diff = new_end_date - new_start_date
        new_event_diff = (new_full_diff.to_f * old_event_percent).round
        new_date = new_start_date + new_event_diff
        options[:day_substitutions] ||= {}
        options[:day_substitutions][old_date.wday.to_s] ||= old_date.wday.to_s
        if options[:day_substitutions] && options[:day_substitutions][old_date.wday.to_s]
          if new_date.wday != options[:day_substitutions][old_date.wday.to_s].to_i
            new_date += (options[:day_substitutions][old_date.wday.to_s].to_i - new_date.wday) % 7
            new_date -= 7 unless new_date - 7 < new_start_date
          end
        end

        new_time = Time.utc(new_date.year, new_date.month, new_date.day, (time.hour rescue 0), (time.min rescue 0)).in_time_zone
        new_time -= new_time.utc_offset
        new_time
      end
    end
  end
end
