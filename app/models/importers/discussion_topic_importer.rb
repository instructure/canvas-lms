module Importers
  class DiscussionTopicImporter < Importer

    self.item_class = DiscussionTopic

    attr_accessor :options, :context, :item

    def self.process_migration(data, migration)
      process_announcements_migration(Array(data['announcements']), migration)
      process_discussion_topics_migration(Array(data['discussion_topics']), migration)
    end

    def self.process_announcements_migration(announcements, migration)
      announcements.each do |event|
        next unless migration.import_object?('announcements', event['migration_id'])
        event[:type] = 'announcement'

        begin
          self.import_from_migration(event, migration.context)
        rescue
          migration.add_import_warning(t('#migration.announcement_type', "Announcement"), event[:title], $!)
        end
      end
    end

    def self.process_discussion_topics_migration(discussion_topics, migration)
      topic_entries_to_import = migration.to_import('topic_entries')
      discussion_topics.each do |topic|
        context = Group.where(context_id: migration.context.id,
                              context_type: migration.context.class.to_s,
                              migration_id: topic['group_id']).first if topic['group_id']
        context ||= migration.context
        next unless context && can_import_topic?(topic, migration)
        begin
          import_from_migration(topic.merge(topic_entries_to_import: topic_entries_to_import), context)
        rescue
          migration.add_import_warning(t('#migration.discussion_topic_type', "Discussion Topic"), topic[:title], $!)
        end
      end
    end

    def self.can_import_topic?(topic, migration)
      migration.import_object?('discussion_topics', topic['migration_id']) ||
          migration.import_object?("topics", topic['migration_id']) ||
          (topic['type'] == 'announcement' &&
              migration.import_object?('announcements', topic['migration_id']))
    end

    def self.import_from_migration(hash, context, item=nil)
      importer = self.new(hash, context, item)
      importer.run
    end

    def initialize(hash, context, item)
      self.options = DiscussionTopicOptions.new(hash)
      self.context = context
      self.item    = find_or_create_topic(item)
    end

    def find_or_create_topic(topic = nil)
      return topic if topic.is_a?(DiscussionTopic)
      topic = DiscussionTopic.where(context_type: context.class.to_s, context_id: context.id).
        where(['id = ? OR (migration_id IS NOT NULL AND migration_id = ?)', options[:id], options[:migration_id]]).first
      topic ||= if options[:type] =~ /announcement/i
                  context.announcements.scoped.new
                else
                  context.discussion_topics.scoped.new
                end
      topic
    end

    def run
      return unless options.importable?
      # not seeing where this is used, so I'm commenting it out for now
      # options[:skip_replies] = true unless options.importable_entries?
      [:migration_id, :title, :discussion_type, :position, :pinned,
       :require_initial_post].each do |attr|
        item.send("#{attr}=", options[attr])
      end
      item.message              = options.message ? ImportedHtmlConverter.convert(options.message, context, missing_links: options[:missing_links]) : I18n.t('#discussion_topic.empty_message', 'No message')
      item.posted_at            = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(options[:posted_at])
      item.delayed_post_at      = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(options.delayed_post_at)
      item.last_reply_at        = item.posted_at if item.new_record?
      item.workflow_state       = 'active'       if item.deleted?
      item.workflow_state       = 'post_delayed' if item.should_not_post_yet
      item.attachment           = context.attachments.where(migration_id: options[:attachment_migration_id]).first
      item.external_feed        = context.external_feeds.where(migration_id: options[:external_feed_migration_id]).first
      item.assignment           = fetch_assignment

      if options[:attachment_ids].present?
        item.message += Attachment.attachment_list_from_migration(context, options[:attachment_ids])
      end

      item.save_without_broadcasting!
      import_migration_item
      add_missing_content_links
      item
    end

    private

    def fetch_assignment
      return nil unless context.respond_to?(:assignments)
      if options[:assignment]
        Importers::AssignmentImporter.import_from_migration(options[:assignment], context)
      elsif options[:grading]
        Importers::AssignmentImporter.import_from_migration({
          grading: options[:grading], migration_id: options[:migration_id],
          submission_format: 'discussion_topic', due_date: options.due_date,
          title: options[:grading][:title]
        }, context)
      end
    end

    def import_migration_item
      if context.respond_to?(:imported_migration_items)
        Array(context.imported_migration_items) << item
      end
    end

    def add_missing_content_links
      if context.try_rescue(:content_migration)
        context.content_migration.add_missing_content_links(class: item.class.to_s,
          id: item.id, missing_links: options[:missing_links],
          url: "/#{context.class.to_s.underscore.pluralize}/#{context.id}/#{item.class.to_s.demodulize.underscore.pluralize}/#{item.id}")
      end
    end

    class DiscussionTopicOptions
      attr_reader :options

      BOOLEAN_KEYS = [:pinned, :require_initial_post]

      def initialize(options = {})
        @options = options.with_indifferent_access
        @options[:missing_links] = []
        @options[:messages]    ||= @options[:posts]
      end

      def [](key)
        BOOLEAN_KEYS.include?(key) ? !!@options[key] : @options[key]
      end

      def []=(key, value)
        @options[key] = BOOLEAN_KEYS.include?(key) ? !!value : value
      end

      def importable?
        !(options[:migration_id] && options[:topics_to_import] &&
            !options[:topics_to_import][options[:migration_id]])
      end

      def message
        return options[:description] if options[:description].present?
        return options[:text] if options[:text].present?
      end

      def delayed_post_at
        options[:delayed_post_at] || options[:start_date]
      end

      def due_date
        options[:due_date] || options[:grading][:due_date]
      end
    end
  end
end
