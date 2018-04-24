#
# Copyright (C) 2016 - present Instructure, Inc.
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

module CC::Exporter::WebZip
  class ZipPackage < CC::Exporter::Epub::FilesDirectory

    def initialize(exporter, course, user, progress_key)
      @files = exporter.unsupported_files + exporter.cartridge_json[:files]
      @pages = exporter.cartridge_json[:pages]
      @assignments = exporter.cartridge_json[:assignments]
      @topics = exporter.cartridge_json[:topics]
      @quizzes = exporter.cartridge_json[:quizzes]
      @filename_prefix = exporter.filename_prefix
      @viewer_path_prefix = @filename_prefix + '/viewer'
      @files_path_prefix = @viewer_path_prefix + '/files'
      @path_to_files = nil
      @course_data_filename = 'course-data.js'
      @course = course
      @user = user
      @current_progress = Rails.cache.fetch(progress_key)
      @current_progress ||= MustViewModuleProgressor.new(user, course).current_progress
      @html_converter = CC::CCHelper::HtmlContentExporter.new(course, user, for_epub_export: true)
      @canvas_object_export_hash = map_canvas_objects_to_export_ids
    end
    attr_reader :files, :course, :user, :current_progress
    attr_accessor :file_data

    ASSIGNMENT_TYPES = ['Assignment', 'Quizzes::Quiz', 'DiscussionTopic'].freeze
    CONTENT_TYPES = [*ASSIGNMENT_TYPES, 'WikiPage'].freeze
    CONTENT_TOKENS = [CC::CCHelper::OBJECT_TOKEN, CC::CCHelper::COURSE_TOKEN, CC::CCHelper::WIKI_TOKEN].freeze

    def force_timezone(time)
      time&.in_time_zone(user.time_zone)&.iso8601
    end

    def convert_html_to_local(html)
      exported_html = @html_converter.html_content(html)
      exported_html&.gsub!(CGI.escape(CC::CCHelper::WEB_CONTENT_TOKEN), 'viewer/files')
      CONTENT_TOKENS.each do |token|
        exported_html&.gsub!("#{CGI.escape(token)}/", '')
      end
      exported_html
    end

    def add_files
      export_files = tab_hidden?(:files) ? filter_and_clean_files(files) : files
      export_files.each do |file_data|
        next unless file_data[:exists]
        unless @path_to_files
          match = file_data[:path_to_file].match(%r{.*/web_resources/})
          @path_to_files = match.to_s
        end
        File.open(file_data[:path_to_file]) do |file|
          file_path = file_data[:local_path].sub(%r{^media/}, @files_path_prefix + '/')
          zip_file.add(file_path, file) { add_clone(file_path, file) }
        end
      end
    end

    def filter_and_clean_files(files)
      export_files = filter_for_export_safe_items(files, :attachments)
      cleanup_files = files - export_files
      cleanup_files.each {|file_data| File.delete(file_data[:path_to_file])}
      export_files
    end

    def filter_for_export_safe_items(item_list, type)
      item_list.select do |export_item|
        ident = type == :attachments ? export_item[:local_path].sub('media', '') : export_item[:identifier]
        next true if @linked_items.include?(ident)
        next unless [:quizzes, :discussion_topics].include?(type)
        !tab_hidden?(:assignments) && @canvas_object_export_hash[type][ident]&.assignment
      end
    end

    def create
      begin
        add_course_data(parse_course_data)
        pull_dist_package
      ensure
        zip_file&.close
      end

      zip_file.to_s
    end

    def real_export_id(item)
      export_id = item[:exportId]
      real_export_id = @discussion_quiz_export_id_map[export_id] if export_id
      if real_export_id
        assignment_export_id = export_id
        export_id = real_export_id
      end
      export_id ||= item[:content]&.sub('viewer/files', '')
      [export_id, assignment_export_id]
    end

    def string_to_symbol_type(type)
      case type
      when 'pages'
        :wiki_pages
      else
        type.underscore.pluralize.split('/').first.to_sym
      end
    end

    def check_for_links_and_mark_exportable(export_item, linked_items, items_to_check)
      # quizzes and discussions could be linked by assignment or quiz/discussion, so we need
      #  to find the quiz/discussion export id to match it with the cc data
      # we're matching files by filename, which is under content instead of exportId
      export_id, assignment_export_id = real_export_id(export_item)
      return if linked_items.include?(export_id) || export_item[:locked]
      linked_items.add(export_id)
      linked_items.add(assignment_export_id) if assignment_export_id
      return if export_item[:type] == 'Attachment'
      type = string_to_symbol_type(export_item[:type])
      match_item = @export_item_map.dig(type, export_id)
      return unless match_item
      content = match_item[:content] || match_item[:text] || match_item[:description]
      linked_objects = format_linked_objects(CC::CCHelper.map_linked_objects(content))
      items_to_check.concat(linked_objects)
    end

    def format_linked_objects(canvas_objects)
      canvas_objects.map do |lo|
        key, canvas_key = lo[:type] == 'Attachment' ? [:content, :local_path] : [:exportId, :identifier]
        lo[key] = lo.delete(canvas_key)
        lo
      end
    end

    def find_linked_items(module_data)
      linked_items = Set.new
      items_to_check = []
      module_data.each do |mod|
        mod[:items].each do |item|
          next unless CONTENT_TYPES.include?(item[:type]) || item[:type] == 'Attachment'
          check_for_links_and_mark_exportable(item, linked_items, items_to_check)
        end
      end
      until items_to_check.empty?
        item_to_check = items_to_check.shift
        check_for_links_and_mark_exportable(item_to_check, linked_items, items_to_check)
      end
      linked_items
    end

    def any_hidden_tabs?
      list = {
        wiki_pages: @pages,
        assignments: @assignments,
        discussion_topics: @topics,
        quizzes: @quizzes,
        attachments: files
      }
      return unless list.keys.any? {|type| tab_hidden?(type)}
      list.each {|type, item_list| map_export_item_ids(type, item_list)}
    end

    def parse_course_data
      module_data = parse_module_data
      @linked_items = find_linked_items(module_data) if any_hidden_tabs?
      course_data = {
        language: course.locale || user.locale || course.account.default_locale(true) || 'en',
        lastDownload: force_timezone(course.web_zip_exports.where(user: user).last&.created_at),
        title: course.name,
        modules: module_data,
        pages: parse_non_module_items(:wiki_pages),
        assignments: parse_non_module_items(:assignments),
        discussion_topics: parse_non_module_items(:discussion_topics),
        quizzes: parse_non_module_items(:quizzes)
      }
      add_files
      course_data[:files] = create_tree_data
      course_data
    end

    def add_course_data(course_data)
      f = File.new(@course_data_filename, 'w+')
      f.write("window.COURSE_DATA = #{course_data.to_json}")
      zip_file.add("#{@viewer_path_prefix}/#{@course_data_filename}", f)
      f.close
    end

    def create_tree_data
      return nil unless @path_to_files

      data = []
      walk(@path_to_files, data)
      data
    end

    def walk(dir, accumulator)
      Dir.foreach(dir) do |file|
        path = File.join(dir, file)
        next if ['.', '..'].include? file
        is_dir = File.directory?(path)
        if is_dir
          next_files = []
          walk(path, next_files)
        end
        accumulator << {
          type: is_dir ? 'folder' : 'file',
          name: file,
          size: is_dir ? nil : File.size(path),
          files: is_dir ? next_files : nil
        }
      end
    end

    def parse_module_data
      active_module_ids = Set.new(course.context_modules.active.map(&:id))
      course.context_modules.active.map do |mod|
        unlock_date = force_timezone(mod.unlock_at) if mod.unlock_at &.> Time.now
        {
          id: mod.id,
          name: mod.name,
          status: user_module_status(mod),
          unlockDate: unlock_date,
          prereqs: mod.prerequisites.map{|pre| pre[:id]}.select{|id| active_module_ids.include?(id)},
          requirement: requirement_type(mod),
          sequential: mod.require_sequential_progress || false,
          exportId: CC::CCHelper.create_key(mod),
          items: parse_module_item_data(mod)
        }
      end
    end

    def user_module_status(modul)
      return 'locked' if modul.locked_for?(user, deep_check_if_needed: true)
      status = current_progress&.dig(modul.id, :status) || 'unlocked'
      status == 'locked' ? 'unlocked' : status
    end

    def item_completed?(item)
      modul = item.context_module
      current_progress&.dig(modul.id, :items, item.id) || false
    end

    def requirement_type(modul)
      return :one if modul.requirement_count == 1
      return :all if modul.completion_requirements.count > 0
    end

    def mod_item_or_content_locked?(item)
      return true if item.locked_for?(user, deep_check_if_needed: true)
      locked = !!item.content.locked_for?(user) if item.content.respond_to?(:locked_for?)
      locked || false
    end

    def parse_module_item_data(modul)
      items = modul.content_tags.active.select{ |item| item.visible_to_user?(user) }
      items.map do |item|
        item_hash = {
          id: item.id,
          title: item.title,
          type: item.content_type,
          indent: item.indent,
          locked: mod_item_or_content_locked?(item)
        }
        parse_module_item_details(item, item_hash) if item.content_type != 'ContextModuleSubHeader'
        item_hash
      end
    end

    def parse_module_item_details(item, item_hash)
      add_assignment_details(item.content, item_hash) if ASSIGNMENT_TYPES.include?(item.content_type)
      requirement, score = parse_requirement(item)
      item_hash[:requirement] = requirement
      item_hash[:requiredPoints] = score if score
      item_hash[:completed] = item_completed?(item)
      item_hash[:content] = parse_content(item.content) unless item_hash[:locked] || item.content_type == 'ExternalUrl'
      item_hash[:content] = item.url if !item_hash[:locked] && item.content_type == 'ExternalUrl'
      item_hash[:exportId] = find_export_id(item) if CONTENT_TYPES.include?(item.content_type)
    end

    def find_export_id(item)
      case item.content_type
      when 'Assignment', 'DiscussionTopic', 'Quizzes::Quiz'
        CC::CCHelper.create_key(item.content)
      when 'WikiPage'
        item.content&.url
      end
    end

    def add_assignment_details(item_content, item_hash)
      case item_content
      when Assignment
        item_hash[:submissionTypes] = item_content.readable_submission_types
        item_hash[:graded] = item_content.grading_type != 'not_graded'
      when Quizzes::Quiz
        item_hash[:assignmentExportId] = CC::CCHelper.create_key(item_content.assignment)
        item_hash[:questionCount] = item_content.question_count
        item_hash[:timeLimit] = item_content.time_limit
        item_hash[:attempts] = item_content.allowed_attempts
        item_hash[:graded] = item_content.quiz_type != 'survey'
      when DiscussionTopic
        item_hash[:lockAt] = force_timezone(item_content.lock_at)
        item_hash[:unlockAt] = force_timezone(item_content.unlock_at)
        item_content = item_content.assignment
        item_hash[:assignmentExportId] = CC::CCHelper.create_key(item_content) if item_content.present?
        item_hash[:graded] = item_content.present?
      end
      return unless item_content
      assignment = AssignmentOverrideApplicator.assignment_overridden_for(item_content, user, skip_clone: true)
      item_hash[:pointsPossible] = assignment&.points_possible if item_hash[:graded]
      item_hash[:dueAt] = force_timezone(assignment&.due_at)
      item_hash[:lockAt] = force_timezone(assignment&.lock_at)
      item_hash[:unlockAt] = force_timezone(assignment&.unlock_at)
      item_hash
    end

    def parse_requirement(item)
      completion_reqs = item.context_module.completion_requirements
      reqs_for_item = completion_reqs.find{|req| req[:id] == item.id}
      return unless reqs_for_item
      [reqs_for_item[:type], reqs_for_item[:min_score]]
    end

    def parse_content(item_content)
      case item_content
      when Assignment, Quizzes::Quiz
        convert_html_to_local(item_content&.description)
      when DiscussionTopic
        convert_html_to_local(item_content&.message)
      when WikiPage
        convert_html_to_local(item_content&.body)
      when Attachment
        path = file_path(item_content)
        "viewer/files#{path}#{item_content&.display_name}"
      end
    end

    def tab_hidden?(type)
      tab_id = case type
               when :wiki_pages
                 Course::TAB_PAGES
               when :discussion_topics
                 Course::TAB_DISCUSSIONS
               when :attachments
                 Course::TAB_FILES
               else
                 "Course::TAB_#{type.upcase}".constantize
               end
      course.tab_hidden?(tab_id)
    end

    def map_canvas_objects_to_export_ids
      canvas_object_export_hash = {}
      @discussion_quiz_export_id_map = {}
      [:wiki_pages, :assignments, :discussion_topics, :quizzes].each do |type|
        type_export_hash, assignment_export_hash = map_object_type_to_export_ids(type)
        canvas_object_export_hash[type] = type_export_hash
        canvas_object_export_hash[:assignments] ||= {}
        canvas_object_export_hash[:assignments].merge!(assignment_export_hash)
      end
      canvas_object_export_hash
    end

    def map_object_type_to_export_ids(type)
      type_export_hash = {}
      assignment_export_hash = {}
      course.send(type).each do |item|
        tag = (type == :wiki_pages ? item.url : CC::CCHelper.create_key(item))
        type_export_hash[tag] = item
        next unless (type == :discussion_topics || type == :quizzes) && item.assignment
        assignment_id = CC::CCHelper.create_key(item.assignment)
        assignment_export_hash[assignment_id] = item
        @discussion_quiz_export_id_map[assignment_id] = tag
      end
      [type_export_hash, assignment_export_hash]
    end

    def map_export_item_ids(type, item_list)
      @export_item_map ||= {}
      @export_item_map[type] ||= {}
      item_list.each {|item| @export_item_map[type][item[:identifier]] = item}
      @export_item_map
    end

    def parse_non_module_item(export_item, item)
      {
        exportId: export_item[:identifier],
        title: export_item[:title],
        type: item.class.name,
        content: parse_content(item) || export_item[:text]
      }
    end

    def parse_non_module_items(type)
      list = {wiki_pages: @pages, assignments: @assignments, discussion_topics: @topics, quizzes: @quizzes}[type]
      list = filter_for_export_safe_items(list, type) if tab_hidden?(type)
      list.map do |export_item|
        item = @canvas_object_export_hash[type][export_item[:identifier]]
        item_hash = parse_non_module_item(export_item, item)
        item_hash[:frontPage] = export_item[:front_page] if type == :wiki_pages
        add_assignment_details(item, item_hash) unless type == :wiki_pages
        item_hash
      end
    end

    def file_path(item_content)
      folder = item_content&.folder&.full_name || ''
      local_folder = folder.sub(/\/?course files\/?/, '')
      local_folder.length > 0 ? "/#{local_folder}/" : '/'
    end

    def dist_package_path
      'node_modules/canvas_offline_course_viewer/dist'
    end

    def pull_dist_package
      path = dist_package_path
      config = ConfigFile.load('offline_web')
      if config&.fetch('local')
        path = config['path_to_dist']
      end
      add_dir_to_zip(path, path)
    end

    def add_dir_to_zip(dir, base_path)
      Dir.foreach(dir) do |file|
        path = File.join(dir, file)
        next if ['.', '..'].include? file
        if File.directory?(path)
          add_dir_to_zip(path, base_path)
        else
          path_in_zip = Pathname(path).relative_path_from(Pathname(base_path))
          zip_file.add(File.join(@filename_prefix, path_in_zip), path)
        end
      end
    end

    def cleanup_files
      File.delete(@course_data_filename) if File.exist?(@course_data_filename)
    end
  end
end
