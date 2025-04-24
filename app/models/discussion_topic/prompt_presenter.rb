# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class DiscussionTopic
  class PromptPresenter
    def initialize(topic)
      @topic = topic
      @cached_entries = nil
      @cached_entries_by_id = nil
      @cached_entries_by_parent_id = nil
      @cached_anonymized_user_ids = nil
    end

    # Example output:
    #
    # <discussion>
    #   <topic user="instructor_1">
    #     <title>
    # Discussion Topic Title    </title>
    #     <message>
    # Discussion Topic Message    </message>
    #   </topic>
    #   <entries>
    # <entry user="student_1" index="1">
    # I liked the course.</entry>
    # <entry user="student_2" index="2">
    # I felt the course was too hard.</entry>
    # <entry user="instructor_1" index="2.1">
    # I'm sorry to hear that. Could you please provide more details?</entry>
    #   </entries>
    # </discussion>
    def content_for_summary
      xml = Builder::XmlMarkup.new(indent: 2)

      xml.discussion do
        xml.topic(user: anonymized_user_ids[@topic.user_id]) do
          xml.title { xml.text! @topic.title || "" }
          xml.message { xml.text! @topic.message || "" }
        end

        xml.entries do
          xml << parts_for_summary(nil, entries_by_parent_id, "", 1)
        end
      end

      xml.target!
    end

    def content_for_insight(entries:, expanded_context: false)
      xml = Builder::XmlMarkup.new(indent: 2)

      xml.discussion do
        xml.topic do
          xml.title { xml.text! @topic.title || "" }
          xml.message { xml.text! @topic.message || "" }
        end

        xml.entries do
          entries.each_with_index do |entry, index|
            parent_chain = []
            parent_id = entry.parent_id
            siblings = []

            if parent_id
              current_id = parent_id
              while current_id
                parent = entries_by_id[current_id]
                break unless parent

                parent_chain << parent
                current_id = parent.parent_id
              end

              siblings = (entries_by_parent_id[parent_id] || []).select { |e| e.created_at < entry.created_at && e.id != entry.id }
                                                                .sort_by(&:created_at)
                                                                .last(2).reverse
            else
              siblings = (entries_by_parent_id[nil] || []).select { |e| e.created_at < entry.created_at && e.id != entry.id }
                                                          .sort_by(&:created_at)
                                                          .last(2).reverse
            end

            format_insight_entry(
              xml:,
              entry:,
              parent_chain:,
              siblings:,
              extra_attributes: { id: index.to_s },
              should_add_context_availability: !expanded_context
            )

            next unless expanded_context

            xml.context do
              if parent_chain.any?
                xml.thread do
                  parent_chain.each_with_index do |ancestor, depth|
                    format_insight_entry(
                      xml:,
                      entry: ancestor,
                      parent_chain: [],
                      siblings: [],
                      extra_attributes: {
                        tag_name: :parent,
                        depth: depth.to_s,
                      },
                      should_add_context_availability: false
                    )
                  end
                end
              end

              if siblings.any?
                xml.siblings do
                  siblings.sort_by(&:created_at).each do |sibling|
                    format_insight_entry(
                      xml:,
                      entry: sibling,
                      parent_chain: [],
                      siblings: [],
                      extra_attributes: {
                        tag_name: :entry,
                        created_at: sibling.created_at.to_s,
                      },
                      should_add_context_availability: false
                    )
                  end
                end
              end
            end
          end
        end
      end

      xml.target!
    end

    def self.focus_for_summary(user_input:)
      focus_xml = Builder::XmlMarkup.new(indent: 2)
      focus_xml.focus((user_input.present? && user_input.strip) || "general summary")
      focus_xml.target!
    end

    def self.raw_summary_for_refinement(raw_summary:)
      raw_summary_xml = Builder::XmlMarkup.new(indent: 2)
      raw_summary_xml.raw_summary(raw_summary)
      raw_summary_xml.target!
    end

    private

    def all_entries
      @cached_entries ||= @topic.discussion_entries.active.preload(:user, :attachment).to_a
    end

    def entries_by_id
      @cached_entries_by_id ||= all_entries.index_by(&:id)
    end

    def entries_by_parent_id
      @cached_entries_by_parent_id ||= all_entries.group_by(&:parent_id)
    end

    def format_insight_entry(xml:, entry:, parent_chain: [], siblings: [], extra_attributes: {}, should_add_context_availability: true)
      tag_name = extra_attributes.delete(:tag_name) || :item
      attributes = { id: entry.id.to_s }.merge(extra_attributes)

      xml.tag!(tag_name, attributes) do
        xml.metadata do
          xml.anonymized_user_id anonymized_user_ids[entry.user_id]
          xml.word_count entry.message_word_count.to_s if entry.respond_to?(:message_word_count)

          if should_add_context_availability
            xml.context_available (parent_chain.any? || siblings.any?).to_s
          end

          if entry.attachment.present?
            xml.attachments do
              xml.attachment do
                xml.filename entry.attachment.name
                xml.content_type entry.attachment.mimetype
                if entry.attachment.word_count.present?
                  xml.word_count entry.attachment.word_count
                end
              end
            end
          end
        end
        xml.content do
          xml.text! anonymize_mentions(entry.message || "")
        end
      end
    end

    def anonymized_user_ids
      return @cached_anonymized_user_ids if @cached_anonymized_user_ids

      user_ids = {}
      instructor_count = 0
      student_count = 0
      instructor_types = ["TeacherEnrollment", "TaEnrollment"]

      enrollments_by_user = {}
      @topic.course.enrollments.active.select(:user_id, :type).each do |enrollment|
        enrollments_by_user[enrollment.user_id] ||= []
        enrollments_by_user[enrollment.user_id] << enrollment.type
      end

      enrollments_by_user.sort_by { |user_id, _| user_id }.each do |user_id, types|
        is_instructor = types.any? { |type| instructor_types.include?(type) }

        if is_instructor
          instructor_count += 1
          user_ids[user_id] = "instructor_#{instructor_count}"
        else
          student_count += 1
          user_ids[user_id] = "student_#{student_count}"
        end
      end

      @cached_anonymized_user_ids = user_ids
    end

    def parts_for_summary(parent_id, entries_for_parent_id, prefix, level)
      xml = Builder::XmlMarkup.new(indent: 2)

      entries_for_parent_id[parent_id]&.each do |entry|
        user_identifier = anonymized_user_ids[entry.user_id]
        current_level = prefix.empty? ? level.to_s : "#{prefix}.#{level}"

        xml.entry(user: user_identifier, index: current_level) do
          xml.text! anonymize_mentions(entry.message || "")
        end

        xml << parts_for_summary(entry.id, entries_for_parent_id, current_level, 1)

        level += 1
      end

      xml.target!
    end

    def anonymize_mentions(content)
      content.gsub(%r{<span class="mceNonEditable mention" data-mention="(\d+)".*?>.*?</span>}) do
        user_id = $1.to_i
        "@#{anonymized_user_ids[user_id] || "unknown"}"
      end
    end
  end
end
