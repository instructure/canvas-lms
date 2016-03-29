#
# Copyright (C) 2014 Instructure, Inc.
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

require_dependency 'importers'

module Importers
  class CalendarEventImporter < Importer

    self.item_class = CalendarEvent

    def self.process_migration(data, migration)
      events = data['calendar_events'] ? data['calendar_events']: []
      events.each do |event|
        if migration.import_object?("calendar_events", event['migration_id']) || migration.import_object?("events", event['migration_id'])
          begin
            import_from_migration(event, migration.context, migration)
          rescue
            migration.add_import_warning(t('#migration.calendar_event_type', "Calendar Event"), event[:title], $!)
          end
        end
      end
    end

    def self.import_from_migration(hash, context, migration, item=nil)
      hash = hash.with_indifferent_access
      return nil if hash[:migration_id] && hash[:events_to_import] && !hash[:events_to_import][hash[:migration_id]]
      item ||= CalendarEvent.where(context_type: context.class.to_s, context_id: context, id: hash[:id]).first
      item ||= CalendarEvent.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:migration_id]).first if hash[:migration_id]
      item ||= context.calendar_events.new

      item.migration_id = hash[:migration_id]
      item.workflow_state = 'active' if item.deleted?
      item.title = hash[:title] || hash[:name]

      item.description = migration.convert_html(hash[:description] || "", :calendar_event, hash[:migration_id], :description)
      item.description += import_migration_attachment_suffix(hash, context)
      item.start_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:start_at] || hash[:start_date])
      item.end_at = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:end_at] || hash[:end_date])
      item.all_day_date = Canvas::Migration::MigratorHelper.get_utc_time_from_timestamp(hash[:all_day_date]).try(:to_date)
      item.imported = true

      item.save_without_broadcasting!
      migration.add_imported_item(item)
      if hash[:all_day]
        item.all_day = hash[:all_day]
        item.save
      end
      item
    end

    # Returns a String that should be appended to the description (may be empty).
    # understood attachment types should define a *_attachment_description method.
    # no idea what 'area' or 'media_collection' attachment types are, so we're ignoring them
    def self.import_migration_attachment_suffix(hash, context)
      suffix_method_name = "#{hash[:attachment_type]}_attachment_description"
      suffix = self.send(suffix_method_name, hash, context) if self.respond_to?(suffix_method_name)
      suffix || ""
    end


    def self.external_url_attachment_description(hash, context)
      return unless url = hash[:attachment_value]
      import_migration_attachment_link(url, ERB::Util.h(t('#calendar_event.see_related_link', "See Related Link")))
    end

    def self.assignment_attachment_description(hash, context)
      return unless assignment = context.assignments.where(migration_id: hash[:attachment_value]).first
      import_migration_attachment_link(
        attachment_url(context, assignment),
        ERB::Util.h(t('#calendar_event.see_assignment', "See %{assignment_name}", :assignment_name => assignment.title)))
    end

    def self.assessment_attachment_description(hash, context)
      return unless quiz = context.quizzes.where(migration_id: hash[:attachment_value]).first
      import_migration_attachment_link(
        attachment_url(context, quiz),
        ERB::Util.h(t('#calendar_event.see_quiz', "See %{quiz_name}", :quiz_name => quiz.title)))
    end

    def self.file_attachment_description(hash, context)
      return unless file = context.attachments.where(migration_id: hash[:attachment_value]).first
      import_migration_attachment_link(
        attachment_url(context, file),
        ERB::Util.h(t('#calendar_event.see_file', "See %{file_name}", :file_name => file.display_name)))
    end

    def self.web_link_attachment_description(hash, context)
      link = context.external_url_hash[hash[:attachment_value]]
      link ||= context.full_migration_hash['web_link_categories'].map{|c| c['links'] }.flatten.select{|l| l['link_id'] == hash[:attachment_value] } rescue nil
      return unless link
      import_migration_attachment_link(
        link['url'],
        link['name'] || ERB::Util.h(t('#calendar_event.see_related_link', "See Related Link")))
    end

    def self.topic_attachment_description(hash, context)
      return unless topic = context.discussion_topics.where(migration_id: hash[:attachment_value]).first
      import_migration_attachment_link(
        attachment_url(context, topic),
        ERB::Util.h(t('#calendar_event.see_discussion_topic', "See %{discussion_topic_name}", :discussion_topic_name => topic.title)))
    end

    def self.import_migration_attachment_link(href, body)
      if href && body
        "<p><a href='#{href}'>#{body}</a></p>"
      end
    end

    def self.attachment_url(context, subject)
      "#{object_url_part(context)}/#{object_url_part(subject)}"
    end

    def self.object_url_part(object)
      case object
      when ::Attachment then "files/#{object.id}/download"
      else "#{object.class.to_s.demodulize.underscore.pluralize}/#{object.id}"
      end
    end

  end
end
