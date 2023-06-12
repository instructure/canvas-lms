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

# require_relative '../../pact_config'
# require_relative '../pact_setup'

PactConfig::Consumers::ALL.each do |consumer|
  Pact.provider_states_for consumer do
    # Student ID: 5 || Student Name: Student1
    # Course ID: 1
    # Assignment ID: 1
    provider_state "a student in a course with an assignment" do
      set_up do
        course = Pact::Canvas.base_state.course
        course.assignments.create({
                                    name: "Assignment 1",
                                    due_at: 1.day.from_now,
                                    submission_types: "online_text_entry"
                                  })
      end
    end

    provider_state "a migrated quiz assignment" do
      set_up do
        course = Pact::Canvas.base_state.course
        assignment = assignment_model(context: course, title: "Assignment1")
        assignment.submission_types = "external_tool"
        assignment.external_tool_tag_attributes = {
          resource_link_id: "9b4ef1eea0eb4c3498983e09a6ef88f1"
        }
        assignment.save!
      end
    end

    provider_state "a cloned quiz assignment" do
      set_up do
        course = Pact::Canvas.base_state.course
        assignment = assignment_model(context: course, title: "Assignment1")
        assignment.submission_types = "external_tool"
        assignment.external_tool_tag_attributes = {
          resource_link_id: "9b4ef1eea0eb4c3498983e09a6ef88f1"
        }
        assignment.save!
      end
    end

    provider_state "an assignment with overrides" do
      set_up do
        course = Pact::Canvas.base_state.course
        student = Pact::Canvas.base_state.students.first
        assignment = course.assignments.create({
                                                 name: "Assignment Override",
                                                 due_at: 1.day.from_now,
                                                 submission_types: "online_text_entry"
                                               })

        override = assignment.assignment_overrides.create!
        override.assignment_override_students.create!(user: student)
      end
    end

    # Student ID 8
    # Course ID 3
    # Assignment IDs 1-3, submission types: online_text_entry, online_upload, online_url
    provider_state "mobile 3 assignments, 3 submissions" do
      set_up do
        mcourse = Pact::Canvas.base_state.mobile_courses[1]
        mstudent = Pact::Canvas.base_state.mobile_student
        mteacher = Pact::Canvas.base_state.mobile_teacher
        test_submission_types = %w[online_text_entry online_upload online_url]
        # Create a category/group...
        cat = mcourse.group_categories.create!(name: "The Cool Kids")
        g = cat.groups.create(context: mcourse)
        g.users << mstudent
        g.save!
        # Create 3 assignments with different submission types
        3.times do |i|
          # Create an assignment
          assignment = mcourse.assignments.create!(
            title: "Assignment #{i}",
            description: "Awesome!",
            due_at: 2.days.ago,
            points_possible: 10,
            allowed_extensions: ["txt"],
            submission_types: [test_submission_types[i]],
            group_category_id: cat.id
          )
          # Create a submission for the assignment
          # Submit an online_upload for course 2, and an online_text_entry for course 3
          submission_type = test_submission_types[i]
          submission =
            case submission_type
            when "online_upload"
              assignment.submit_homework(
                mstudent, {
                  submission_type: "online_upload",
                  attachments: [
                    attachment_model(filename: "attached.txt", context: mstudent, content_type: "text/html")
                  ]
                }
              )
            when "online_url"
              assignment.submit_homework(mstudent, { submission_type: "online_url", url: "someurl" })
            else
              # assume online_text_entry by default
              assignment.submit_homework(mstudent, { submission_type: "online_text_entry", body: "Here it is" })
            end
          submission.save!

          # Add a submission comment to the submission
          submission.submission_comments.create!(
            author: mstudent,
            comment: "a comment"
            # this had no effect at all
            # attachments: [
            #   attachment_model(filename: 'comment_attachment.txt', context: mstudent, content_type: 'text/html')
            # ]
          )
          # Let's set some overrides for the assignment.
          # This should result in a number of lock-reelated fields being populated, as well as an
          # overrides object (only seen by teacher).
          # Also will ensure that assignment is late, which populates points_deducted in the submission.
          override = assignment.assignment_overrides.create!(
            due_at: 2.days.ago,
            due_at_overridden: true,
            all_day: true,
            unlock_at: 1.day.from_now,
            unlock_at_overridden: true,
            lock_at: 3.days.from_now,
            lock_at_overridden: true
          )
          override.assignment_override_students.create!(user: mstudent)
          override.save!
          # Create a rubric for the assignment
          rubric = Rubric.create!(
            title: "rubric title",
            context: mcourse,
            context_id: mcourse.id,
            context_type: "Course",
            points_possible: 10,
            public: true
          )
          rubric.save!
          # Unbelievable -- The only way I could see to apply rubric criteria to the assignment was
          # to update them here.  Couldn't do it in Rubric.create!() above.
          rubric_association = rubric.update_with_association(mteacher,
                                                              {
                                                                criteria: {
                                                                  "0" => {
                                                                    ignore_for_scoring: "0",
                                                                    description: "standard",
                                                                    points: 10,
                                                                    ratings: {
                                                                      "1" => { points: 10, description: "Yay!", long_description: "You're awesome!" },
                                                                      "2" => { points: 5, description: "Meh", long_description: "I've seen better" },
                                                                      "3" => { points: 0, description: "Boo!", long_description: "Whatever" },
                                                                    },
                                                                  },
                                                                },
                                                              },
                                                              mcourse,
                                                              {
                                                                association_object: assignment, purpose: "grading", update_if_existing: true, use_for_grading: "1", skip_updating_points_possible: true
                                                              })
          rubric.save!
          assignment.save!
          # Grade the assignment
          RubricAssessment.create!({
                                     artifact: submission,
                                     assessment_type: "grading",
                                     assessor: mteacher,
                                     rubric:,
                                     user: mstudent,
                                     rubric_association:,
                                     data: [{ points: 10.0, comments: "hey" }]
                                   })
          # Unfortunately, the rubric assessment above will not actually assign a grade
          assignment.grade_student(mstudent, grader: mteacher, score: 10, points_deducted: 0)
        end
      end
    end
  end
end
