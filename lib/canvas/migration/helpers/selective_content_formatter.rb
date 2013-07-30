module Canvas::Migration::Helpers
  class SelectiveContentFormatter
    SELECTIVE_CONTENT_TYPES = [
            ['course_settings', -> { I18n.t('lib.canvas.migration.course_settings', 'Course Settings') }],
            ['syllabus_body', -> { I18n.t('lib.canvas.migration.syllabus_body', 'Syllabus Body') }],
            ['context_modules', -> { I18n.t('lib.canvas.migration.context_modules', 'Modules') }],
            ['assignments', -> { I18n.t('lib.canvas.migration.assignments', 'Assignments') }],
            ['quizzes', -> { I18n.t('lib.canvas.migration.quizzes', 'Quizzes') }],
            ['assessment_question_banks', -> { I18n.t('lib.canvas.migration.assessment_question_banks', 'Question Banks') }],
            ['discussion_topics', -> { I18n.t('lib.canvas.migration.discussion_topics', 'Discussion Topics') }],
            ['wiki_pages', -> { I18n.t('lib.canvas.migration.wikis', 'Wiki Pages') }],
            ['context_external_tools', -> { I18n.t('lib.canvas.migration.external_tools', 'External Tools') }],
            ['announcements', -> { I18n.t('lib.canvas.migration.announcements', 'Announcements') }],
            ['calendar_events', -> { I18n.t('lib.canvas.migration.calendar_events', 'Calendar Events') }],
            ['rubrics', -> { I18n.t('lib.canvas.migration.rubrics', 'Rubrics') }],
            ['groups', -> { I18n.t('lib.canvas.migration.groups', 'Student Groups') }],
            ['learning_outcomes', -> { I18n.t('lib.canvas.migration.learning_outcomes', 'Learning Outcomes') }],
            ['attachments', -> { I18n.t('lib.canvas.migration.attachments', 'Files') }],
    ]

    def initialize(migration, base_url=nil)
      @migration = migration
      @base_url = base_url
    end

    def get_content_list(type=nil)
      raise "unsupported migration type" if type && !SELECTIVE_CONTENT_TYPES.any?{|t|t[0] == type}

      if @migration.migration_type == 'course_copy_importer'
        get_content_from_course(type)
      elsif @migration.overview_attachment
        get_content_from_overview(type)
      else
        raise "course hasn't been converted"
      end
    end

    private

    # pulls the available items from the overview attachment on the content migration
    def get_content_from_overview(type=nil)
      course_data = Rails.cache.fetch(['migration_selective_cache', @migration.shard, @migration].cache_key, :expires_in => 5.minutes) do
        att = @migration.overview_attachment.open
        data = JSON.parse(att.read)
        data['attachments'] ||= data['file_map'] ? data['file_map'].values : nil
        data['quizzes'] ||= data['assessments']
        data['context_modules'] ||= data['modules']
        data['wiki_pages'] ||= data['wikis']
        data["context_external_tools"] ||= data["external_tools"]
        data["learning_outcomes"] ||= data["outcomes"]
        att.close
        data
      end

      content_list = []
      if type
        if course_data[type]
          case type
            when 'assignments'
              assignment_data(content_list, course_data)
            when 'attachments'
              attachment_data(content_list, course_data)
            else
              course_data[type].each do |item|
                content_list << item_hash(type, item)
              end
          end
        end
      else
        SELECTIVE_CONTENT_TYPES.each do |type, title|
          if course_data[type] && course_data[type].count > 0
            hash = {type: type, property: "copy[all_#{type}]", title: title.call, count: course_data[type].count}
            add_url!(hash, type)
            content_list << hash
          end
        end
      end

      content_list
    end

    # Returns all the assignments in their assignment groups
    def assignment_data(content_list, course_data)
      added_asmnts = []
      if course_data['assignment_groups']
        course_data['assignment_groups'].each do |group|
          item = item_hash('assignment_groups', group)
          sub_items = []
          course_data['assignments'].select { |a| a['assignment_group_migration_id'] == group['migration_id'] }.each do |asmnt|
            sub_items << item_hash('assignments', asmnt)
            added_asmnts << asmnt['migration_id']
          end
          if sub_items.any?
            item['sub_items'] = sub_items
          end
          content_list << item
        end
      end
      course_data['assignments'].each do |asmnt|
        next if added_asmnts.member? asmnt['migration_id']
        content_list << item_hash('assignments', asmnt)
      end
    end

    def attachment_data(content_list, course_data)
      return [] unless course_data['attachments'] && course_data['attachments'].length > 0
      remove_name_regex = %r{/[^/]*\z}
      course_data['attachments'].each{|a| next unless a['path_name']; a['path_name'].gsub!(remove_name_regex, '') }
      folder_groups = course_data['attachments'].group_by{|a|a['path_name']}
      sorted = folder_groups.sort_by{|i|i.first}
      sorted.each do |folder_name, atts|
        if atts.length == 1 && atts[0]['file_name'] == folder_name
          content_list << item_hash('attachments', atts[0])
        else
          mig_id = Digest::MD5.hexdigest(folder_name)
          folder = {type: 'folders', property: "copy[folders][#{mig_id}]", title: folder_name, migration_id: mig_id, sub_items: []}
          content_list << folder
          atts.each {|att| folder[:sub_items] << item_hash('attachments', att)}
        end
      end
    end

    def item_hash(type, item)
      hash = {
              type: type,
              property: "copy[#{type}][#{item['migration_id']}]",
              title: item['title'],
              migration_id: item['migration_id']
      }
      if type == 'attachments'
        hash[:path] = item['path_name']
        hash[:title] = item['file_name']
      end

      hash
    end


    # returns lists of available content from a source course
    def get_content_from_course(type=nil)
      content_list = []
      if source = @migration.source_course || Course.find(@migration.migration_settings[:source_course_id])
        if type
          case type
            when 'assignments'
              course_assignment_data(content_list, source)
            when 'attachments'
              course_attachments_data(content_list, source)
            when 'wiki_pages'
              source.wiki.wiki_pages.not_deleted.select("id, title").each do |item|
                content_list << course_item_hash(type, item)
              end
            when 'discussion_topics'
              source.discussion_topics.active.only_discussion_topics.select("id, title, user_id").except(:user).each do |item|
                content_list << course_item_hash(type, item)
              end
            else
              if source.respond_to?(type)
                scope = source.send(type).select(:id)
                # We only need the id and name, so don't fetch everything from DB
                if type == 'learning_outcomes'
                  scope = scope.select(:short_description)
                elsif type == 'context_modules' || type == 'context_external_tools' || type == 'groups'
                  scope = scope.select(:name)
                else
                  scope = scope.select(:title)
                end

                if scope.respond_to?(:not_deleted)
                  scope = scope.not_deleted
                elsif scope.respond_to?(:active)
                  scope = scope.active
                end

                scope.each do |item|
                  content_list << course_item_hash(type, item)
                end
              end
          end
        else
          SELECTIVE_CONTENT_TYPES.each do |type, title|
            next if type == 'groups'

            count = 0
            if type == 'course_settings' || type == 'syllabus_body'
              content_list << {type: type, property: "copy[all_#{type}]", title: title.call}
              next
            elsif type == 'wiki_pages'
              count = source.wiki.wiki_pages.not_deleted.count
            elsif type == 'discussion_topics'
              count = source.discussion_topics.active.only_discussion_topics.count
            elsif source.respond_to?(type) && source.send(type).respond_to?(:count)
              scope = source.send(type)
              if scope.respond_to?(:not_deleted)
                scope = scope.not_deleted
              elsif scope.respond_to?(:active)
                scope = scope.active
              end
              count = scope.count
            end

            next if count == 0
            hash = {type: type, property: "copy[all_#{type}]", title: title.call, count: count}
            add_url!(hash, type)
            content_list << hash
          end
        end
      end

      content_list
    end

    def add_url!(hash, type)
      if @base_url
        hash[:sub_items_url] = @base_url + "?type=#{type}"
      end
    end

    def course_item_hash(type, item)
      mig_id = CC::CCHelper.create_key(item)
      title = nil
      title ||= item.title if item.respond_to?(:title)
      title ||= item.full_name if item.respond_to?(:full_name)
      title ||= item.display_name if item.respond_to?(:display_name)
      title ||= item.name if item.respond_to?(:name)
      title ||= item.short_description if item.respond_to?(:short_description)
      title ||= ''

      {type: type, property: "copy[#{type}][#{mig_id}]", title: title, migration_id: mig_id}
    end

    def course_assignment_data(content_list, source_course)
      source_course.assignment_groups.active.includes(:assignments).select("id, name").each do |group|
        item = course_item_hash('assignment_groups', group)
        content_list << item
        group.assignments.active.select(:id).select(:title).each do |asmnt|
          item[:sub_items] ||= []
          item[:sub_items] << course_item_hash('assignments', asmnt)
        end
      end
    end

    def course_attachments_data(content_list, source_course)
      source_course.folders.active.select('id, full_name, name').includes(:active_file_attachments).sort_by{|f| f.full_name}.each do |folder|
        next if folder.active_file_attachments.length == 0

        item = course_item_hash('folders', folder)
        item[:sub_items] = []
        content_list << item
        folder.active_file_attachments.each do |att|
          item[:sub_items] << course_item_hash('attachments', att)
        end
      end
    end


  end
end
