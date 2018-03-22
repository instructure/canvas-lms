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

require_dependency 'importers'

module Importers
  class DiscussionTopicImporter < Importer

    self.item_class = DiscussionTopic

    attr_accessor :options, :context, :item, :migration

    def self.process_migration(data, migration)
      process_announcements_migration(Array(data['announcements']), migration)
      process_discussion_topics_migration(Array(data['discussion_topics']), migration)
    end

    def self.process_announcements_migration(announcements, migration)
      announcements.each do |event|
        next unless migration.import_object?('announcements', event['migration_id'])
        event[:type] = 'announcement'

        begin
          self.import_from_migration(event, migration.context, migration)
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
          import_from_migration(topic.merge(topic_entries_to_import: topic_entries_to_import), context, migration)
        rescue
          migration.add_import_warning(t('#migration.discussion_topic_type', "Discussion Topic"), topic[:title], $!)
        end
      end
    end

    def self.can_import_topic?(topic, migration)
      migration.import_object?('discussion_topics', topic['migration_id']) ||
          migration.import_object?("topics", topic['migration_id'])
    end

    def self.import_from_migration(hash, context, migration, item=nil)
      importer = self.new(hash, context, migration, item)
      importer.run
    end

    def initialize(hash, context, migration, item)
      self.options = DiscussionTopicOptions.new(hash)
      self.context = context
      self.migration = migration
      self.item    = find_or_create_topic(item)
      self.item.mark_as_importing!(migration)
    end

    def find_or_create_topic(topic = nil)
      return topic if topic.is_a?(DiscussionTopic)
      topic = DiscussionTopic.where(context_type: context.class.to_s, context_id: context.id).
        where(['id = ? OR (migration_id IS NOT NULL AND migration_id = ?)', options[:id], options[:migration_id]]).first
      topic ||= if options[:type] =~ /announcement/i
                  context.announcements.temp_record
                else
                  context.discussion_topics.temp_record
                end
      topic.saved_by = :migration
      topic
    end

    def run
      return unless options.importable?
      [:migration_id, :title, :discussion_type, :position, :pinned,
       :require_initial_post, :allow_rating, :only_graders_can_rate,
       :sort_by_rating, :locked].each do |attr|
        next if options[attr].nil? && item.class.columns_hash[attr.to_s].type == :boolean
        item.send("#{attr}=", options[attr])
      end

      type = item.is_a?(Announcement) ? :announcement : :discussion_topic
      if options.message
        item.message = migration.convert_html(options.message, type, options[:migration_id], :message)
      else
        item.message = I18n.t('#discussion_topic.empty_message', 'No message')
      end

      item.delayed_post_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(options.delayed_post_at)
      if options[:assignment]
        options[:assignment][:lock_at] ||= options[:lock_at]
      else
        item.lock_at         = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(options[:lock_at])
      end
      item.todo_date       = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(options[:todo_date])
      item.last_reply_at   = nil if item.new_record?

      if options[:workflow_state].present?
        if (options[:workflow_state] != 'unpublished') || item.new_record? || item.deleted? || migration.for_master_course_import?
          item.workflow_state = options[:workflow_state]
        end
      elsif item.should_not_post_yet
        item.workflow_state = 'post_delayed'
      else
        item.workflow_state = 'active'
      end

      if options[:attachment_migration_id].present?
        item.attachment = context.attachments.where(migration_id: options[:attachment_migration_id]).first
      end
      if options[:external_feed_migration_id].present?
        item.external_feed = context.external_feeds.where(migration_id: options[:external_feed_migration_id]).first
      end
      item.assignment = fetch_assignment

      if options[:attachment_ids].present?
        item.message += Attachment.attachment_list_from_migration(context, options[:attachment_ids])
      end

      if options[:has_group_category]
        item.group_category ||= context.group_categories.active.where(:name => options[:group_category]).first
        item.group_category ||= context.group_categories.active.where(:name => I18n.t("Project Groups")).first_or_create
      end

      item.save_without_broadcasting!
      import_migration_item
      item.saved_by = nil
      item
    end

    private

    def fetch_assignment
      return nil unless context.respond_to?(:assignments)
      if options[:assignment]
        Importers::AssignmentImporter.import_from_migration(options[:assignment], context, migration)
      elsif options[:grading]
        Importers::AssignmentImporter.import_from_migration({
          grading: options[:grading], migration_id: options[:migration_id],
          submission_format: 'discussion_topic', due_date: options.due_date,
          title: options[:grading][:title]
        }, context, migration)
      end
    end

    def import_migration_item
      migration.add_imported_item(item)
    end

    class DiscussionTopicOptions
      attr_reader :options

      BOOLEAN_KEYS = [:pinned, :require_initial_post, :locked]

      def initialize(options = {})
        @options = options.with_indifferent_access
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
