# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do
    # Student ID: 5 || Name: Student1
    provider_state "a student with a to do item" do
      set_up do
        student = Pact::Canvas.base_state.students.first
        planner_note_model(user: student)
      end
    end

    provider_state "a teacher not in a course" do
      set_up do
        @teacher = user_factory(active_all: true, name: "Teacher2")
        @teacher.pseudonyms.create!(unique_id: "Teacher2@instructure.com", password: "password", password_confirmation: "password")
      end
    end

    provider_state "shareable users existing in canvas" do
      set_up do
        @teacher = user_factory(active_all: true, name: "Pact Teacher")
        course_with_teacher({ user: @teacher })
        @teacher.update(email: "pact-teacher@example.com")
      end
    end

    provider_state "user enrollments existing in canvas" do
      no_op
    end

    # provider state for mobile
    # Student ID: 8 || Name: "Mobile Student"
    # Conversation IDs: 1 (read), 2 (unread)
    provider_state "mobile user with conversations" do
      set_up do
        # High-level set-up
        student = Pact::Canvas.base_state.mobile_student
        student2 = Pact::Canvas.base_state.students.first # Borrow a student from legacy, non-mobile pact logic
        student2.update(pronouns: "He/Him") # Add pronoun
        teacher = Pact::Canvas.base_state.mobile_teacher
        course = Pact::Canvas.base_state.mobile_courses[1]
        course.enroll_student(student2).accept! # enroll student2 in our mobile course
        course.save!

        # Create the attachment and media comment that we will use for each conversation
        mc = MediaObject.create(media_type: "audio", media_id: "1234", context: student, user: student, title: "Display Name")

        attachment = student.conversation_attachments_folder.attachments.create!(context: student,
                                                                                 filename: "test.txt",
                                                                                 display_name: "test.txt",
                                                                                 uploaded_data: StringIO.new("test"))

        # Create two distinct conversations, both authored by student.
        # We need the two conversations to be able to test filtering.
        # We need different participant sets for each, or else they will be combined into one conversation.
        # We're providing an attachment and a media_comment for each.
        conversation1 = conversation(student2,
                                     sender: student,
                                     context_type: "Course",
                                     context_id: course.id,
                                     body: "Conversation 1 Body",
                                     subject: "Subject 1",
                                     workflow_state: "read")
        conversation1.messages.first.update!(media_comment: mc, attachment_ids: [attachment.id])
        conversation1.save!

        conversation2 = conversation(teacher,
                                     sender: student,
                                     context_type: "Course",
                                     context_id: course.id,
                                     body: "Conversation 2 Body",
                                     subject: "Subject 2",
                                     workflow_state: "unread")
        conversation2.messages.first.update!(media_comment: mc, attachment_ids: [attachment.id])
        conversation2.save!
      end
    end
  end
end
