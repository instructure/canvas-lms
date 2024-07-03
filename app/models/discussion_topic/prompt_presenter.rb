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
      anonymized_user_ids = {}
      instructor_count = 0
      student_count = 0

      @topic.course.enrollments.active.find_each do |enrollment|
        user_id = enrollment.user_id
        if @topic.course.user_is_instructor?(enrollment.user)
          instructor_count += 1
          anonymized_user_ids[user_id] = "instructor_#{instructor_count}"
        else
          student_count += 1
          anonymized_user_ids[user_id] = "student_#{student_count}"
        end
      end

      entries_for_parent_id = @topic.discussion_entries.active.to_a.group_by(&:parent_id)

      xml = Builder::XmlMarkup.new(indent: 2)

      xml.discussion do
        xml.topic(user: anonymized_user_ids[@topic.user_id]) do
          xml.title { xml.text! @topic.title || "" }
          xml.message { xml.text! @topic.message || "" }
        end

        xml.entries do
          xml << parts_for_summary(nil, entries_for_parent_id, anonymized_user_ids, "", 1)
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

    def parts_for_summary(parent_id, entries_for_parent_id, anonymized_user_ids, prefix, level)
      xml = Builder::XmlMarkup.new(indent: 2)

      entries_for_parent_id[parent_id]&.each do |entry|
        user_identifier = anonymized_user_ids[entry.user_id]
        current_level = prefix.empty? ? level.to_s : "#{prefix}.#{level}"

        xml.entry(user: user_identifier, index: current_level) do
          xml.text! entry.message || ""
        end

        xml << parts_for_summary(entry.id, entries_for_parent_id, anonymized_user_ids, current_level, 1)

        level += 1
      end

      xml.target!
    end
  end
end
