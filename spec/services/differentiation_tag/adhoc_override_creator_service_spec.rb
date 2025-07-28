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

describe DifferentiationTag::AdhocOverrideCreatorService do
  describe "create_adhoc_override" do
    before(:once) do
      @course = course_model

      @teacher = teacher_in_course(course: @course, active_all: true).user
      @student1 = student_in_course(course: @course, active_all: true).user
      @student2 = student_in_course(course: @course, active_all: true).user
      @student3 = student_in_course(course: @course, active_all: true).user
    end

    let(:service) { DifferentiationTag::AdhocOverrideCreatorService }

    context "validate parameters" do
      before do
        @module = @course.context_modules.create!
      end

      it "raises an error if learning object is not provided" do
        errors = service.create_adhoc_override(@course, nil, { student_ids: [@student1.id] })
        expect(errors[0]).to eq("Invalid learning object provided")
      end

      it "raises an error if student_ids are not provided" do
        errors = service.create_adhoc_override(@course, @module, {})
        expect(errors[0]).to eq("Invalid override data provided")
      end

      it "raises an error if course is not provided" do
        errors = service.create_adhoc_override(nil, @module, { student_ids: [@student1.id] })
        expect(errors[0]).to eq("Invalid course provided")
      end

      it "raises an error if course is not a course" do
        errors = service.create_adhoc_override(@course.account, @module, { student_ids: [@student1.id] })
        expect(errors[0]).to eq("Invalid course provided")
      end

      it "can raise multiple errors at once" do
        errors = service.create_adhoc_override(nil, nil, {})
        expect(errors).to match_array([
                                        "Invalid course provided",
                                        "Invalid learning object provided",
                                        "Invalid override data provided"
                                      ])
      end
    end

    context "module overrides" do
      before do
        @module = @course.context_modules.create!
      end

      it "creates adhoc overrides for context modules" do
        override_data = {
          student_ids: [@student1.id, @student2.id, @student3.id]
        }

        service.create_adhoc_override(@course, @module, override_data)

        expect(@module.assignment_overrides.count).to eq(1)
        expect(@module.assignment_overrides.first.set_type).to eq("ADHOC")
        expect(@module.assignment_overrides.first.assignment_override_students.pluck(:user_id)).to match_array([@student1.id, @student2.id, @student3.id])
      end
    end

    context "general assignment overrides" do
      def successfully_create_adhoc_override(learning_object, override_data)
        service.create_adhoc_override(@course, learning_object, override_data)

        expect(learning_object.assignment_overrides.count).to eq(2)

        override = learning_object.assignment_overrides.where(set_type: "ADHOC").first
        expect(override.assignment_override_students.pluck(:user_id)).to match_array(override_data[:student_ids])
        expect(override.due_at).to eq(override_data[:override].due_at)
        expect(override.unlock_at).to eq(override_data[:override].unlock_at)
        expect(override.lock_at).to eq(override_data[:override].lock_at)

        learning_object
      end

      it "creates adhoc overrides for assignments" do
        assignment = @course.assignments.create!(name: "Test Assignment", points_possible: 100, submission_types: ["online_text_entry"])
        override = assignment.assignment_overrides.create!(
          set_type: "Course",
          set_id: @course.id,
          due_at: 1.day.from_now,
          unlock_at: Time.zone.now,
          lock_at: 2.days.from_now
        )

        override_data = {
          override:,
          student_ids: [@student1.id, @student2.id, @student3.id]
        }

        successfully_create_adhoc_override(assignment, override_data)

        expect(assignment.assignment_overrides.where(set_type: "ADHOC").first.assignment_id).to eq(assignment.id)
      end

      it "creates adhoc overrides for quizzes" do
        quiz = @course.quizzes.create!(title: "Test Quiz")
        override = quiz.assignment_overrides.create!(
          set_type: "Course",
          set_id: @course.id,
          due_at: 1.day.from_now,
          unlock_at: Time.zone.now,
          lock_at: 2.days.from_now
        )

        override_data = {
          override:,
          student_ids: [@student1.id, @student3.id]
        }

        successfully_create_adhoc_override(quiz, override_data)

        expect(quiz.assignment_overrides.where(set_type: "ADHOC").first.quiz_id).to eq(quiz.id)
      end

      it "creates adhoc overrides for basic discussion topics" do
        discussion_topic = @course.discussion_topics.create!(title: "Test Discussion Topic")
        override = discussion_topic.assignment_overrides.create!(
          set_type: "Course",
          set_id: @course.id,
          unlock_at: Time.zone.now,
          lock_at: 2.days.from_now
        )

        override_data = {
          override:,
          student_ids: [@student1.id, @student2.id]
        }

        successfully_create_adhoc_override(discussion_topic, override_data)

        expect(discussion_topic.assignment_overrides.where(set_type: "ADHOC").first.discussion_topic_id).to eq(discussion_topic.id)
      end

      it "creates adhoc overrides for wiki pages" do
        wiki_page = @course.wiki_pages.create!(title: "Test Wiki Page")
        override = wiki_page.assignment_overrides.create!(
          set_type: "Course",
          set_id: @course.id,
          unlock_at: Time.zone.now,
          lock_at: 2.days.from_now
        )

        override_data = {
          override:,
          student_ids: [@student1.id, @student2.id]
        }

        successfully_create_adhoc_override(wiki_page, override_data)

        expect(wiki_page.assignment_overrides.where(set_type: "ADHOC").first.wiki_page_id).to eq(wiki_page.id)
      end
    end
  end
end
