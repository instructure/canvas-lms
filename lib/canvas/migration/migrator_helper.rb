#
# Copyright (C) 2011 Instructure, Inc.
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
#
require 'tmpdir'
require 'shellwords'
module Canvas::Migration
module MigratorHelper
  include Canvas::Migration

  FULL_COURSE_JSON_FILENAME = "course_export.json"
  ERROR_FILENAME = "errors.json"
  OVERVIEW_JSON = "overview.json"
  ALL_FILES_ZIP = "all_files.zip"
  
  COURSE_NO_COPY_ATTS = [:name, :course_code, :start_at, :conclude_at, :grading_standard_id, :tab_configuration, :syllabus_body, :storage_quota]
  
  QUIZ_FILE_DIRECTORY = "Quiz Files"
  
  attr_reader :overview

  def self.get_utc_time_from_timestamp(timestamp)
    return nil if timestamp.nil?

    # timestamp can be either a time string in the format "2011-04-30T00:00:00-06:00",
    # or an integer epoch * 1000
    if timestamp.to_s.match(/^-?[0-9.]+$/)
      timestamp = timestamp.to_i/ 1000 rescue 0
      t = nil
      if timestamp > 0
        t = Time.at(timestamp).utc
        t = Time.utc(t.year, t.month, t.day, t.hour, t.min, t.sec)
      end
      t
    else
      Time.use_zone("UTC"){Time.zone.parse(timestamp.to_s)}
    end
  end

  def self.unzip_command(zip_file, dest_dir)
    "unzip -qo #{Shellwords.escape(zip_file)} -d #{Shellwords.escape(dest_dir)} 2>&1"
  end

  def add_error(type, message, object=nil, e=nil)
    logger.error message
    @error_count += 1
    stack_trace = e ? "#{e}: #{e.backtrace.join("\n")}" : nil
    error = {:object_type=>type, :error_message=>message}
    error[:stack_trace] = stack_trace if stack_trace
    error[:object] = object if object
    @errors << error
    object[:error_message] = message if object
    if @scraper and @scraper.page
      error[:error_url] = @scraper.page.uri.to_s
      error[:page_body] = @scraper.page.body
    end

    error
  end
  
  def unique_quiz_dir
    if content_migration
      if a = content_migration.attachment
        key = "#{a.filename.gsub(/\..*/,'')}_#{content_migration.id}"
      else
        key = content_migration.id.to_s
      end
    else
      key = "data_#{rand(10000)}" #should only happen in testing
    end
    "#{QUIZ_FILE_DIRECTORY}/#{key}"
  end
  
  def content_migration
    @settings[:content_migration]
  end
  
  def add_warning(user_message, exception_or_info='')
    if content_migration.respond_to?(:add_warning)
      content_migration.add_warning(user_message, exception_or_info)
    end
  end

  def set_progress(progress)
    if content_migration && content_migration.respond_to?(:update_conversion_progress)
      content_migration.update_conversion_progress(progress)
    end
  end
  
  def logger
    Rails.logger
  end
  
  def find_export_dir
    if @settings[:content_migration_id] && @settings[:user_id]
      slug = "cm_#{@settings[:content_migration_id]}_user_id_#{@settings[:user_id]}_#{@settings[:migration_type]}"
    else
      slug = "export_#{rand(10000)}"
    end

    path = create_export_dir(slug)
    i = 1
    while File.exists?(path) && File.directory?(path)
      i += 1
      path = create_export_dir("#{slug}_attempt_#{i}")
    end

    path
  end

  def create_export_dir(slug)
    config = ConfigFile.load('external_migration')
    if config && config[:data_folder]
      folder = config[:data_folder]
    else
      folder = Dir.tmpdir
    end
    File.join(folder, slug)
  end

  def make_export_dir
    FileUtils::mkdir_p @base_export_dir
  end

  # Does a JSON export of the courses
  def save_to_file(file_name = nil)
    make_export_dir
    add_assessment_id_prepend

    @course = @course.with_indifferent_access
    Importers::AssessmentQuestionImporter.preprocess_migration_data(@course)

    file_name ||= File.join(@base_export_dir, FULL_COURSE_JSON_FILENAME)
    file_name = File.expand_path(file_name)
    @course[:full_export_file_path] = file_name
    save_errors_to_file
    save_overview_to_file
    logger.debug "Writing the full course json file to: #{file_name}"
    File.open(file_name, 'w') { |file| file << @course.to_json}
    file_name
  end
  
  def self.download_archive(settings)
    config = ConfigFile.load('external_migration') || {}
    if settings[:export_archive_path]
      settings[:archive_file] = File.open(settings[:export_archive_path], 'rb')
    elsif settings[:course_archive_download_url].present?
      # open-uri downloads the http response to a tempfile
      settings[:archive_file] = open(settings[:course_archive_download_url])
    elsif settings[:attachment_id]
      att = Attachment.find(settings[:attachment_id])
      settings[:archive_file] = att.open(:temp_folder => config[:data_folder], :need_local_file => true)
    else
      raise "No migration file found"
    end

    settings[:archive_file]
  end

  def id_prepender
    @settings[:id_prepender]
  end
  
  def prepend_id(id, prepend_value=nil)
    prepend_value ||= id_prepender
    prepend_value ? "#{prepend_value}_#{id}" : id
  end
  
  def add_assessment_id_prepend
    if id_prepender && !@settings[:overwrite_quizzes]
      if @course[:assessment_questions] && @course[:assessment_questions][:assessment_questions]
        prepend_id_to_questions(@course[:assessment_questions][:assessment_questions])
      end
      if @course[:assessments] && @course[:assessments][:assessments]
        prepend_id_to_assessments(@course[:assessments][:assessments])
        prepend_id_to_linked_assessment_module_items(@course[:modules]) if @course[:modules]
      end
    end
  end
  
  def prepend_id_to_questions(questions, prepend_value=nil)
    questions.each do |q|
      q[:migration_id] = prepend_id(q[:migration_id], prepend_value)
      q[:question_bank_id] = prepend_id(q[:question_bank_id], prepend_value) if q[:question_bank_id].present?
    end
  end
  
  def prepend_id_to_assessments(assessments, prepend_value=nil)
    assessments.each do |a|
      a[:migration_id] = prepend_id(a[:migration_id], prepend_value)
      if h = a[:assignment]
        h[:migration_id] = prepend_id(h[:migration_id], prepend_value)
      end

      a[:questions].each do |q|
        if q[:question_type] == "question_reference"
          q[:migration_id] = prepend_id(q[:migration_id], prepend_value)
        elsif q[:question_type] == "question_group"
          q[:question_bank_migration_id] = prepend_id(q[:question_bank_migration_id], prepend_value) if q[:question_bank_migration_id].present?
          q[:questions].each do |gq|
            gq[:migration_id] = prepend_id(gq[:migration_id], prepend_value)
          end
        end
      end
    end
  end

  def prepend_id_to_linked_assessment_module_items(modules, prepend_value=nil)
    modules.each do |m|
      next unless m[:items]
      m[:items].each do |i|
        if i[:linked_resource_type] =~ /assessment|quiz/i
          i[:item_migration_id] = prepend_id(i[:item_migration_id], prepend_value)
          i[:linked_resource_id] = prepend_id(i[:linked_resource_id], prepend_value)
        end
      end
    end
  end

  # Does a JSON overview export of the courses
  def save_overview_to_file(file_name = nil)
    file_name ||= File.join(@base_export_dir, OVERVIEW_JSON)
    file_name = File.expand_path(file_name)
    @course[:overview_file_path] = file_name
    logger.debug "Writing the overview course json file to: #{file_name}"
    File.open(file_name, 'w') { |file| file << overview().to_json}
    file_name
  end

  def save_errors_to_file(file_name=nil)
    unless @errors.empty?
      file_name ||= File.join(@base_export_dir, ERROR_FILENAME)
      file_name = File.expand_path(file_name)
      @course[:error_file_path] = file_name
      logger.debug "Writing the error json file to: #{file_name}"
      File.open(file_name, 'w') { |file| file << @errors.to_json}
      file_name
    end
  end

  def add_learning_outcome_to_overview(overview, outcome)
    unless outcome[:type] == "learning_outcome_group"
      overview[:learning_outcomes] << {:migration_id => outcome[:migration_id], :title => outcome[:title]}
    end
    if outcome[:outcomes]
      outcome[:outcomes].each do |sub_outcome|
        overview = add_learning_outcome_to_overview(overview, sub_outcome)
      end
    end
    overview
  end

  def overview
    return @overview if @overview
    logger.debug "Creating the overview hash."
    @overview = {}
    @overview[:start_timestamp] = nil
    @overview[:end_timestamp] = nil
    dates = []
    if @overview[:course] = @course[:course]
      @overview[:start_timestamp] = @course[:course][:start_timestamp] || @course[:course][:start_at]
      @overview[:end_timestamp] = @course[:course][:end_timestamp] || @course[:course][:conclude_at]
    end
    @overview[:role] = @course[:role]
    @overview[:base_url] = @course[:base_url]
    @overview[:role] = @course[:role]
    @overview[:name] = @course[:name]
    @overview[:title] = @course[:title]
    @overview[:run_times] = @course[:run_times]
    @overview[:full_export_file_path] = @course[:full_export_file_path]
    @overview[:overview_file_path] = @course[:overview_file_path]
    @overview[:error_file_path] = @course[:error_file_path]
    @overview[:all_files_export] = @course[:all_files_export] if @course[:all_files_export]
    @overview[:file_map] = @course[:file_map] if @course[:file_map]
    @overview[:all_questions_qti_export] = @course[:all_questions_qti_export] if @course[:all_questions_qti_export]
    @overview[:course_outline] = @course[:course_outline] if @course[:course_outline]
    @overview[:error_count] = @error_count

    if @course[:assessments]
      @overview[:assessments] = []
      if @course[:assessments][:assessments]
        @course[:assessments][:assessments].each do |a|
          assmnt = {}
          dates << a[:due_date] if a[:due_date]
          @overview[:assessments] << assmnt
          assmnt[:quiz_name] = a[:quiz_name]
          assmnt[:quiz_name] ||= a[:title]
          assmnt[:title] = a[:title]
          assmnt[:title] ||= a[:quiz_name]
          assmnt[:migration_id] = a[:migration_id]
          assmnt[:type] = a[:type]
          assmnt[:max_points] = a[:max_points]
          assmnt[:duration] = a[:duration]
          assmnt[:error_message] = a[:error_message] if a[:error_message]
          if a[:assignment] && a[:assignment][:migration_id]
            assmnt[:assignment_migration_id] = a[:assignment][:migration_id]
          end
        end
      end
    end

    if @course[:assessment_question_banks]
      @overview[:assessment_question_banks] ||= []
      @course[:assessment_question_banks].each do |aqb|
        @overview[:assessment_question_banks] << aqb.dup
      end
    end

    if @course[:calendar_events]
      @overview[:calendar_events] = []
      @course[:calendar_events].each do |e|
        event = {}
        dates << e[:start_timestamp] if e[:start_timestamp]
        dates << e[:end_timestamp] if e[:end_timestamp]
        @overview[:calendar_events] << event
        event[:title] = e[:title]
        event[:migration_id] = e[:migration_id]
        event[:start_timestamp] = e[:start_timestamp]
        event[:error_message] = e[:error_message] if e[:error_message]
      end
    end
    if @course[:announcements]
      @overview[:announcements] = []
      @course[:announcements].each do |e|
        announcement = {}
        dates << e[:start_date] if e[:start_date]
        @overview[:announcements] << announcement
        announcement[:title] = e[:title]
        announcement[:migration_id] = e[:migration_id]
        announcement[:start_date] = e[:start_date]
        announcement[:error_message] = e[:error_message] if e[:error_message]
      end
    end
    if @course[:rubrics]
      @overview[:rubrics] = []
      @course[:rubrics].each do |r|
        rubric = {}
        @overview[:rubrics] << rubric
        rubric[:title] = r[:title]
        rubric[:migration_id] = r[:migration_id]
        rubric[:description] = r[:description]
        rubric[:error_message] = r[:error_message] if r[:error_message]
      end
    end
    if @course[:modules]
      @overview[:modules] = []
      @course[:modules].each do |m|
        mod = {}
        @overview[:modules] << mod
        mod[:title] = m[:title]
        mod[:order] = m[:order]
        mod[:migration_id] = m[:migration_id]
        mod[:description] = m[:description]
        mod[:error_message] = m[:error_message] if m[:error_message]
      end
    end
    if @course[:assignments]
      @overview[:assignments] = []
      @course[:assignments].each do |a|
        assign = {}
        dates << a[:due_date] if a[:due_date]
        @overview[:assignments] << assign
        assign[:title] = a[:title]
        assign[:due_date] = a[:due_date]
        assign[:migration_id] = a[:migration_id]
        assign[:quiz_migration_id] = a[:quiz_migration_id] if a[:quiz_migration_id]
        assign[:assignment_group_migration_id] = a[:assignment_group_migration_id] if a[:assignment_group_migration_id]
        assign[:error_message] = a[:error_message] if a[:error_message]
      end
    end
    if @course[:discussion_topics]
      @overview[:discussion_topics] = []
      @overview[:announcements] = []
      @course[:discussion_topics].each do |t|
        topic = {}
        if t[:type] == 'announcement'
          @overview[:announcements] << topic
        else
          @overview[:discussion_topics] << topic
        end
        topic[:title] = t[:title]
        topic[:topic_type] = t[:type]
        topic[:migration_id] = t[:migration_id]
        topic[:error_message] = t[:error_message] if t[:error_message]
        if t[:assignment] && a_mig_id = t[:assignment][:migration_id]
          if assign = @overview[:assignments].find{|a| a[:migration_id] == a_mig_id}
            assign[:topic_migration_id] = t[:migration_id]
            topic[:assignment_migration_id] = a_mig_id
          end
        end
      end
    end
    if @course[:assignment_groups]
      @overview[:assignment_groups] = []
      @course[:assignment_groups].each do |g|
        group = {}
        @overview[:assignment_groups] << group
        group[:migration_id] = g[:migration_id]
        group[:title] = g[:title]
      end
    end
    if @course[:groups]
      @overview[:groups] = []
      @course[:groups].each do |g|
        group = {}
        @overview[:groups] << group
        group[:migration_id] = g[:migration_id]
        group[:title] = g[:title]
      end
    end
    if @course[:wikis]
      @overview[:wikis] = []
      @course[:wikis].each do |w|
        next unless w
        wiki = {}
        @overview[:wikis] << wiki
        wiki[:migration_id] = w[:migration_id]
        wiki[:title] = w[:title]
      end
    end
    if @course[:external_tools]
      @overview[:external_tools] = []
      @course[:external_tools].each do |ct|
        next unless ct
        tool = {}
        @overview[:external_tools] << tool
        tool[:migration_id] = ct[:migration_id]
        tool[:title] = ct[:title]
      end
    end

    if @course[:learning_outcomes]
      @overview[:learning_outcomes] = []
      @course[:learning_outcomes].each do |outcome|
        next unless outcome
        add_learning_outcome_to_overview(@overview, outcome)
      end
    end

    if dates.length > 0
      @overview[:start_timestamp] ||= dates.min
      @overview[:end_timestamp] ||= dates.max
    end

    @overview[:scrape_errors] = []
#    @errors.each do |e|
#      @overview[:scrape_errors] << {:error_message=>e[:error_message], :object_type=>e[:object_type]}
#    end
    @overview
  end
end
end
