module MigrationImport
  class DiscussionTopic
    attr_accessor :options, :context, :item

    def initialize(hash, context, item)
      self.options = MigrationImport::DiscussionTopicOptions.new(hash)
      self.context = context
      self.item    = DiscussionTopic(item)
    end

    def DiscussionTopic(topic = nil)
      return topic if topic.is_a?(::DiscussionTopic)
      topic = ::DiscussionTopic.where(context_type: context.class.to_s,
                                      context_id: context.id).
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
        Assignment.import_from_migration(options[:assignment], context)
      elsif options[:grading]
        Assignment.import_from_migration({
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
  end
end
