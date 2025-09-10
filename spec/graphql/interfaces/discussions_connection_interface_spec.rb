# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../spec_helper"

describe Interfaces::DiscussionsConnectionInterface do
  # Create a test class that includes the interface to test the methods
  let(:test_class) do
    Class.new do
      include Interfaces::DiscussionsConnectionInterface

      attr_accessor :current_user

      def initialize(current_user)
        @current_user = current_user
      end
    end
  end
  let(:test_instance) { test_class.new(@teacher) }

  before :once do
    course_with_teacher(active_all: true)
    course_with_student(course: @course, active_all: true)

    # Create announcements with different visibility scenarios
    @public_announcement = @course.announcements.create!(
      title: "Public Announcement",
      message: "Public message",
      user: @teacher
    )

    @delayed_announcement = @course.announcements.create!(
      title: "Future Announcement",
      message: "Future message",
      user: @teacher,
      delayed_post_at: 1.day.from_now
    )

    @locked_announcement = @course.announcements.create!(
      title: "Locked Announcement",
      message: "Locked message",
      user: @teacher,
      lock_at: 1.day.ago
    )
  end

  describe "#discussions_scope" do
    context "when filtering announcements" do
      it "returns all active announcements for admin users" do
        scope = test_instance.discussions_scope(@course, nil, nil, true)

        expect(scope).to include(@public_announcement)
        expect(scope).to include(@delayed_announcement)
        expect(scope).to include(@locked_announcement)
      end

      it "filters out time-restricted announcements for non-admin users" do
        test_instance.current_user = @student
        scope = test_instance.discussions_scope(@course, nil, nil, true)

        expect(scope).to include(@public_announcement)
        expect(scope).not_to include(@delayed_announcement)
        expect(scope).not_to include(@locked_announcement)
      end

      it "filters by search term when provided" do
        scope = test_instance.discussions_scope(@course, nil, "Public", true)

        expect(scope).to include(@public_announcement)
        expect(scope).not_to include(@delayed_announcement)
        expect(scope).not_to include(@locked_announcement)
      end

      context "with section-specific announcements" do
        before :once do
          @section_a = @course.course_sections.create!(name: "Section A")
          @section_b = @course.course_sections.create!(name: "Section B")

          @student_a = user_with_pseudonym(active_all: true, name: "Student A")
          @course.enroll_student(@student_a, section: @section_a, enrollment_state: "active")

          @student_b = user_with_pseudonym(active_all: true, name: "Student B")
          @course.enroll_student(@student_b, section: @section_b, enrollment_state: "active")

          @section_a_announcement = @course.announcements.create!(
            title: "Section A Announcement",
            message: "Message for Section A",
            user: @teacher,
            is_section_specific: true,
            course_sections: [@section_a]
          )

          @section_b_announcement = @course.announcements.create!(
            title: "Section B Announcement",
            message: "Message for Section B",
            user: @teacher,
            is_section_specific: true,
            course_sections: [@section_b]
          )

          @all_sections_announcement = @course.announcements.create!(
            title: "All Sections Announcement",
            message: "Message for all sections",
            user: @teacher
          )
        end

        it "shows section-specific announcements to students in that section" do
          test_instance.current_user = @student_a
          scope = test_instance.discussions_scope(@course, nil, nil, true)

          expect(scope).to include(@section_a_announcement)
          expect(scope).to include(@all_sections_announcement)
          expect(scope).not_to include(@section_b_announcement)
        end

        it "shows section-specific announcements to students in different section" do
          test_instance.current_user = @student_b
          scope = test_instance.discussions_scope(@course, nil, nil, true)

          expect(scope).to include(@section_b_announcement)
          expect(scope).to include(@all_sections_announcement)
          expect(scope).not_to include(@section_a_announcement)
        end

        it "shows all announcements to teachers regardless of section" do
          scope = test_instance.discussions_scope(@course, nil, nil, true)

          expect(scope).to include(@section_a_announcement)
          expect(scope).to include(@section_b_announcement)
          expect(scope).to include(@all_sections_announcement)
        end

        it "respects user_id parameter for section scoping" do
          # Teacher queries for announcements as seen by Student A
          scope = test_instance.discussions_scope(@course, @student_a.id, nil, true)

          expect(scope).to include(@section_a_announcement)
          expect(scope).to include(@all_sections_announcement)
          expect(scope).not_to include(@section_b_announcement)
        end

        it "respects user_id parameter for different student" do
          # Teacher queries for announcements as seen by Student B
          scope = test_instance.discussions_scope(@course, @student_b.id, nil, true)

          expect(scope).to include(@section_b_announcement)
          expect(scope).to include(@all_sections_announcement)
          expect(scope).not_to include(@section_a_announcement)
        end
      end
    end

    context "when filtering regular discussions" do
      before :once do
        @regular_discussion = @course.discussion_topics.create!(
          title: "Regular Discussion",
          message: "Regular message",
          user: @teacher
        )
      end

      it "excludes announcements when is_announcement is false" do
        scope = test_instance.discussions_scope(@course, nil, nil, false)

        expect(scope).to include(@regular_discussion)
        expect(scope).not_to include(@public_announcement)
        expect(scope).not_to include(@delayed_announcement)
      end
    end

    context "when user_id is provided" do
      it "handles nonexistent user_id gracefully" do
        scope = test_instance.discussions_scope(@course, "nonexistent", nil, true)
        expect(scope.to_a).to eq([])
      end

      it "handles invalid permissions gracefully" do
        other_teacher = User.create!(name: "Other Teacher")
        expect do
          test_instance.discussions_scope(@course, other_teacher.id, nil, true)
        end.to raise_error(GraphQL::ExecutionError, "You do not have permission to view this course.")
      end
    end
  end

  describe "#apply_discussion_order" do
    it "orders announcements by created_at desc when is_announcement is true" do
      ordered_scope = test_instance.apply_discussion_order(
        @course.announcements.all, true
      )

      expect(ordered_scope.order_values.first.to_sql).to include("created_at")
      expect(ordered_scope.order_values.first.to_sql).to include("DESC")
    end

    it "orders discussions by id asc when is_announcement is false" do
      ordered_scope = test_instance.apply_discussion_order(
        @course.discussion_topics.all, false
      )

      expect(ordered_scope.order_values.first.to_sql).to include("id")
      expect(ordered_scope.order_values.first.to_sql).to include("ASC")
    end
  end
end
