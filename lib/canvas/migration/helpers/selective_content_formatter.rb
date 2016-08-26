module Canvas::Migration::Helpers
  class SelectiveContentFormatter
    COURSE_SETTING_TYPE = -> { I18n.t('lib.canvas.migration.course_settings', 'Course Settings') }
    COURSE_SYLLABUS_TYPE = -> { I18n.t('lib.canvas.migration.syllabus_body', 'Syllabus Body') }
    SELECTIVE_CONTENT_TYPES = [
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

    def initialize(migration=nil, base_url=nil)
      @migration = migration
      @base_url = base_url
    end

    def valid_type?(type=nil)
      type.nil? || SELECTIVE_CONTENT_TYPES.any?{|t|t[0] == type} || type.start_with?("submodules_")
    end

    def get_content_list(type=nil, source=nil)
      raise "unsupported migration type" unless valid_type?(type)

      if !@migration || @migration.migration_type == 'course_copy_importer'
        get_content_from_course(type, source)
      elsif @migration.overview_attachment
        get_content_from_overview(type)
      else
        raise "course hasn't been converted"
      end
    end

    private

    def property_prefix
      @migration ? "copy" : "select"
    end

    # pulls the available items from the overview attachment on the content migration
    def get_content_from_overview(type=nil)
      course_data = Rails.cache.fetch(['migration_selective_cache', @migration.shard, @migration].cache_key, :expires_in => 5.minutes) do
        att = @migration.overview_attachment.open
        data = JSON.parse(att.read)
        data = separate_announcements(data)
        data['attachments'] ||= data['file_map'] ? data['file_map'].values : nil
        data['quizzes'] ||= data['assessments']
        data['context_modules'] ||= data['modules']
        data['wiki_pages'] ||= data['wikis']
        data["context_external_tools"] ||= data["external_tools"]
        data["learning_outcomes"] ||= data["outcomes"]

        # skip auto generated quiz question banks for canvas imports
        if data['assessment_question_banks']
          data['assessment_question_banks'].select! do |item|
            !(item['for_quiz'] && @migration && (@migration.for_course_copy? || (@migration.migration_type == 'canvas_cartridge_importer')))
          end
        end

        att.close
        data
      end

      content_list = []
      if type
        if match_data = type.match(/submodules_(.*)/)
          (submodule_data(course_data['context_modules'], match_data[1]) || []).each do |item|
            content_list << item_hash('context_modules', item)
          end
        elsif course_data[type]
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
        if course_data['course']
          content_list << {type: 'course_settings', property: "#{property_prefix}[all_course_settings]", title: COURSE_SETTING_TYPE.call}
          if course_data['course']['syllabus_body']
            content_list << {type: 'syllabus_body', property: "#{property_prefix}[all_syllabus_body]", title: COURSE_SYLLABUS_TYPE.call}
          end
        end
        SELECTIVE_CONTENT_TYPES.each do |type, title|
          if course_data[type] && course_data[type].count > 0
            hash = {type: type, property: "#{property_prefix}[all_#{type}]", title: title.call, count: course_data[type].count}
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
          folder = {type: 'folders', property: "#{property_prefix}[folders][id_#{mig_id}]", title: folder_name, migration_id: mig_id, sub_items: []}
          content_list << folder
          atts.each {|att| folder[:sub_items] << item_hash('attachments', att)}
        end
      end
    end

    def item_hash(type, item)
      hash = {
              type: type,
              property: "#{property_prefix}[#{type}][id_#{item['migration_id']}]",
              title: item['title'],
              migration_id: item['migration_id']
      }
      case type
      when 'attachments'
        hash[:path] = item['path_name']
        hash[:title] = item['file_name']
      when 'assessment_question_banks'
        if hash[:title].blank? && @migration && @migration.context.respond_to?(:assessment_question_banks)
          if hash[:migration_id] && bank = @migration.context.assessment_question_banks.where(migration_id: hash[:migration_id]).first
            hash[:title] = bank.title
          elsif @migration.question_bank_id && default_bank = @migration.context.assessment_question_banks.where(id: @migration.question_bank_id).first
            hash[:title] = default_bank.title
          end
          hash[:title] ||= @migration.question_bank_name || AssessmentQuestionBank.default_imported_title
          hash[:migration_id] ||= CC::CCHelper.create_key(hash[:title], 'assessment_question_bank')
        end
      when 'context_modules'
        hash[:item_count] = item['item_count']
        if item['submodules']
          hash[:submodule_count] = item['submodules'].count
          add_url!(hash, "submodules_#{CGI.escape(item['migration_id'])}")
        end
      end
      hash = add_linked_resource(type, item, hash)
      hash
    end

    def add_linked_resource(type, item, hash)
      if type == 'assignments'
        if mig_id = item['quiz_migration_id']
          hash[:linked_resource] = {:type => 'quizzes', :migration_id => mig_id}
        elsif mig_id = item['topic_migration_id']
          hash[:linked_resource] = {:type => 'discussion_topics', :migration_id => mig_id}
        elsif mig_id = item['page_migration_id']
          hash[:linked_resource] = {:type => 'wiki_pages', :migration_id => mig_id}
        end
      elsif ['discussion_topics', 'quizzes', 'wiki_pages'].include?(type) && mig_id = item['assignment_migration_id']
        hash[:linked_resource] = {:type => 'assignments', :migration_id => mig_id}
      end
      hash
    end

    # returns lists of available content from a source course
    def get_content_from_course(type=nil, source=nil)
      content_list = []
      source ||= @migration.source_course || Course.find(@migration.migration_settings[:source_course_id]) if @migration
      if source
        if type
          case type
            when 'assignments'
              course_assignment_data(content_list, source)
            when 'attachments'
              course_attachments_data(content_list, source)
            when 'wiki_pages'
              source.wiki.wiki_pages.not_deleted.select("id, title, assignment_id").each do |item|
                content_list << course_item_hash(type, item)
              end
            when 'discussion_topics'
              source.discussion_topics.active.only_discussion_topics.select("id, title, user_id, assignment_id").except(:preload).each do |item|
                content_list << course_item_hash(type, item)
              end
            else
              if source.respond_to?(type)
                scope = source.send(type).select(:id).except(:preload)
                # We only need the id and name, so don't fetch everything from DB

                scope = scope.select(:assignment_id) if type == 'quizzes'

                if type == 'learning_outcomes'
                  scope = scope.select(:short_description)
                elsif type == 'context_modules' || type == 'context_external_tools' || type == 'groups'
                  scope = scope.select(:name)
                else
                  scope = scope.select(:title)
                end

                if scope.klass.respond_to?(:not_deleted)
                  scope = scope.not_deleted
                elsif scope.klass.respond_to?(:active)
                  scope = scope.active
                end

                scope.each do |item|
                  content_list << course_item_hash(type, item)
                end
              end
          end
        else
          content_list << {type: 'course_settings', property: "#{property_prefix}[all_course_settings]", title: COURSE_SETTING_TYPE.call}
          content_list << {type: 'syllabus_body', property: "#{property_prefix}[all_syllabus_body]", title: COURSE_SYLLABUS_TYPE.call}

          SELECTIVE_CONTENT_TYPES.each do |type, title|
            next if type == 'groups'

            count = 0
            if type == 'wiki_pages'
              count = source.wiki.wiki_pages.not_deleted.count
            elsif type == 'discussion_topics'
              count = source.discussion_topics.active.only_discussion_topics.count
            elsif source.respond_to?(type) && source.send(type).respond_to?(:count)
              scope = source.send(type).except(:preload)
              if scope.klass.respond_to?(:not_deleted)
                scope = scope.not_deleted
              elsif scope.klass.respond_to?(:active)
                scope = scope.active
              end
              count = scope.count
            end

            next if count == 0
            hash = {type: type, property: "#{property_prefix}[all_#{type}]", title: title.call, count: count}
            add_url!(hash, type)
            content_list << hash
          end
        end
      end

      content_list
    end

    def add_url!(hash, type)
      return if type == 'learning_outcomes' # TODO: remove this when learning outcomes selection ui is finished
      if @base_url
        hash[:sub_items_url] = @base_url + "?type=#{type}"
      end
    end

    def course_item_hash(type, item, include_linked_resource=true)
      title = nil
      title ||= item.title if item.respond_to?(:title)
      title ||= item.full_name if item.respond_to?(:full_name)
      title ||= item.display_name if item.respond_to?(:display_name)
      title ||= item.name if item.respond_to?(:name)
      title ||= item.short_description if item.respond_to?(:short_description)
      title ||= ''

      hash = {type: type, title: title}
      if @migration
        mig_id = CC::CCHelper.create_key(item)
        hash[:migration_id] = mig_id
        hash[:property] = "#{property_prefix}[#{type}][id_#{mig_id}]"
      else
        hash[:id] = item.asset_string
      end
      hash = course_linked_resource(item, hash) if include_linked_resource

      hash
    end

    def course_linked_resource(item, hash)
      lr = nil
      if item.is_a?(Assignment)
        if item.quiz
          lr = course_item_hash('quizzes', item.quiz, false)
          lr[:message] = I18n.t('linked_quiz_message', "linked with Quiz '%{title}'",
                                :title => item.quiz.title)
        elsif item.discussion_topic
          lr = course_item_hash('discussion_topics', item.discussion_topic, false)
          lr[:message] = I18n.t('linked_discussion_topic_message', "linked with Discussion Topic '%{title}'",
                                :title => item.discussion_topic.title)
        elsif item.wiki_page
          lr = course_item_hash('wiki_pages', item.wiki_page, false)
          lr[:message] = I18n.t("linked with Wiki Page '%{title}'",
                                :title => item.wiki_page.title)
        end
      elsif [DiscussionTopic, WikiPage, Quizzes::Quiz].any? { |t| item.is_a?(t) } && item.assignment
        lr = course_item_hash('assignments', item.assignment, false)
        lr[:message] = I18n.t('linked_assignment_message', "linked with Assignment '%{title}'",
                              :title => item.assignment.title)
      end
      if lr
        lr.delete(:title)
        hash[:linked_resource] = lr
      end
      hash
    end

    def course_assignment_data(content_list, source_course)
      source_course.assignment_groups.active.preload(:assignments).select("id, name").each do |group|
        item = course_item_hash('assignment_groups', group)
        content_list << item
        group.assignments.active.select(:id).select(:title).each do |asmnt|
          item[:sub_items] ||= []
          item[:sub_items] << course_item_hash('assignments', asmnt)
        end
      end
    end

    def course_attachments_data(content_list, source_course)
      Canvas::ICU.collate_by(source_course.folders.active.select('id, full_name, name').preload(:active_file_attachments), &:full_name).each do |folder|
        next if folder.active_file_attachments.length == 0

        item = course_item_hash('folders', folder)
        item[:sub_items] = []
        content_list << item
        folder.active_file_attachments.each do |att|
          item[:sub_items] << course_item_hash('attachments', att)
        end
      end
    end

    def submodule_data(modules, parent_mig_id)
      if mod = modules.detect{|m| m['migration_id'] == parent_mig_id}
        mod['submodules']
      else
        modules.each do |mod|
          if mod['submodules'] && (sm_data = submodule_data(mod['submodules'], parent_mig_id))
            return sm_data
          end
        end
        nil
      end
    end

    def separate_announcements(course_data)
      return course_data unless course_data['discussion_topics']

      announcements, topics = course_data['discussion_topics'].partition{|topic_hash| topic_hash['type'] == 'announcement'}

      if announcements.any?
        course_data['announcements'] ||= []
        course_data['announcements'] += announcements
        course_data['discussion_topics'] = topics
      end
      course_data
    end
  end
end
