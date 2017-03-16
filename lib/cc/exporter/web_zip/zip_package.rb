module CC::Exporter::WebZip
  class ZipPackage < CC::Exporter::Epub::FilesDirectory

    def initialize(exporter, course, user, progress_key)
      @files = exporter.unsupported_files + exporter.cartridge_json[:files]
      @filename_prefix = exporter.filename_prefix
      @viewer_path_prefix = @filename_prefix + '/viewer'
      @files_path_prefix = @viewer_path_prefix + '/files'
      @path_to_files = nil
      @course_data_filename = 'course-data.js'
      @course = course
      @user = user
      @current_progress = Rails.cache.fetch(progress_key)
      @current_progress ||= MustViewModuleProgressor.new(user, course).current_progress
      @html_converter = CC::CCHelper::HtmlContentExporter.new(course, user)
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
      files.each do |file_data|
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

    def create
      begin
        add_files
        add_course_data
        pull_dist_package
      ensure
        zip_file&.close
      end

      zip_file.to_s
    end

    def add_course_data
      f = File.new(@course_data_filename, 'w+')
      last_web_export_time = course.web_zip_exports.where(user: user).last&.created_at

      data = {
        language: course.locale || 'en',
        lastDownload: force_timezone(last_web_export_time),
        title: course.name,
        files: create_tree_data,
        modules: parse_module_data
      }

      f.write("window.COURSE_DATA = #{data.to_json}")

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
      course.context_modules.active.map do |mod|
        unlock_date = force_timezone(mod.unlock_at) if mod.unlock_at &.> Time.now
        {
          id: mod.id,
          name: mod.name,
          status: user_module_status(mod),
          unlockDate: unlock_date,
          prereqs: mod.prerequisites.map{|pre| pre[:id]},
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

    def parse_module_item_data(modul)
      items = modul.content_tags.active.select{ |item| item.visible_to_user?(user) }
      items.map do |item|
        item_hash = {
          id: item.id,
          title: item.title,
          type: item.content_type,
          indent: item.indent,
          locked: !item.available_for?(user, deep_check_if_needed: true)
        }
        parse_module_item_details(item, item_hash) if item.content_type != 'ContextModuleSubHeader'
        item_hash
      end
    end

    def parse_module_item_details(item, item_hash)
      add_assignment_details(item, item_hash) if ASSIGNMENT_TYPES.include?(item.content_type)
      requirement, score = parse_requirement(item)
      item_hash[:requirement] = requirement
      item_hash[:requiredPoints] = score if score
      item_hash[:completed] = item_completed?(item)
      item_hash[:content] = parse_content(item) unless item_hash[:locked]
      item_hash[:exportId] = find_export_id(item) if CONTENT_TYPES.include?(item.content_type)
    end

    def find_export_id(item)
      case item.content_type
      when 'Assignment', 'DiscussionTopic', 'Quizzes::Quiz'
        CC::CCHelper.create_key(item.content&.asset_string)
      when 'WikiPage'
        item.content&.url
      end
    end

    def add_assignment_details(item, item_hash)
      case item.content_type
      when 'Assignment'
        assignment = item.content
        item_hash[:submissionTypes] = assignment.readable_submission_types
        item_hash[:graded] = assignment.grading_type != 'not_graded'
      when 'Quizzes::Quiz'
        assignment = item.content
        item_hash[:questionCount] = assignment.question_count
        item_hash[:timeLimit] = assignment.time_limit
        item_hash[:attempts] = assignment.allowed_attempts
        item_hash[:graded] = assignment.quiz_type != 'survey'
      when 'DiscussionTopic'
        assignment = item.content&.assignment
        item_hash[:graded] = assignment.present?
      end
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

    def parse_content(item)
      case item.content_type
      when 'Assignment', 'Quizzes::Quiz'
        convert_html_to_local(item.content&.description)
      when 'DiscussionTopic'
        convert_html_to_local(item.content&.message)
      when 'WikiPage'
        convert_html_to_local(item.content&.body)
      when 'ExternalUrl'
        item.url
      when 'Attachment'
        path = file_path(item)
        "viewer/files#{path}#{item.content&.filename}"
      end
    end

    def file_path(item)
      folder = item.content&.folder&.full_name || ''
      local_folder = folder.sub(/\/?course files\/?/, '')
      local_folder.length > 0 ? "/#{local_folder}/" : '/'
    end

    def dist_package_path
      'node_modules/canvas_offline_course_viewer/dist'
    end

    def pull_dist_package
      path = dist_package_path
      config = ConfigFile.load('offline_web', Rails.env)
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
          path_in_zip = path.sub(base_path, '')
          zip_file.add("#{@filename_prefix}/#{path_in_zip}", path)
        end
      end
    end

    def cleanup_files
      File.delete(@course_data_filename) if File.exist?(@course_data_filename)
    end
  end
end
