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

module Canvas::MigratorHelper
  include Canvas::Migration

  FULL_COURSE_JSON_FILENAME = "course_export.json"
  ERROR_FILENAME = "errors.json"
  OVERVIEW_JSON = "overview.json"
  
  attr_reader :overview

  # The base directory where all the course data will be download to
  # The final path for a course will be:
  # BASE_DOWNLOAD_PATH + blackboard user name + course name
  if ENV['RAILS_ENV'] and ENV['RAILS_ENV'] == "production"
    #production path
    BASE_DOWNLOAD_PATH = "/var/web/migration_tool/data/"
  else
    BASE_DOWNLOAD_PATH = "exports/"
  end

  def self.unzip_command(zip_file, dest_dir)
    "unzip -qo #{zip_file.gsub(/ /, "\\ ")} -d #{dest_dir.gsub(/ /, "\\ ")} 2>&1"
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

  def make_export_dir
    FileUtils::mkdir_p @base_export_dir
  end

  # Does a JSON export of the courses
  def save_to_file(file_name = nil)
    make_export_dir
    file_name ||= File.join(@base_export_dir, FULL_COURSE_JSON_FILENAME)
    file_name = File.expand_path(file_name)
    @course[:full_export_file_path] = file_name
    save_errors_to_file
    save_overview_to_file
    logger.debug "Writing the full course json file to: #{file_name}"
    File.open(file_name, 'w') { |file| file << @course.to_json}
    file_name
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

  def overview
    return @overview if @overview
    logger.debug "Creating the overview hash."
    @overview = {}
    @overview[:start_timestamp] = nil
    @overview[:end_timestamp] = nil
    dates = []
    if @overview[:course] = @course[:course]
      @overview[:start_timestamp] = @course[:course][:start_timestamp]
      @overview[:end_timestamp] = @course[:course][:end_timestamp]
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
        end
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
        assign[:description] = a[:description]
        assign[:error_message] = a[:error_message] if a[:error_message]
      end
    end
    if @course[:discussion_topics]
      @overview[:discussion_topics] = []
      @course[:discussion_topics].each do |t|
        topic = {}
        @overview[:discussion_topics] << topic
        topic[:title] = t[:title]
        topic[:topic_type] = t[:topic_type]
        topic[:description] = t[:description]
        topic[:migration_id] = t[:migration_id]
        topic[:error_message] = t[:error_message] if t[:error_message]
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