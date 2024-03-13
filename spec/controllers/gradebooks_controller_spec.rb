# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe GradebooksController do
  include TextHelper

  before :once do
    Account.site_admin.disable_feature!(:archived_grading_schemes)
    course_with_teacher active_all: true
    @teacher_enrollment = @enrollment
    student_in_course active_all: true
    @student_enrollment = @enrollment

    user_factory(active_all: true)
    @observer = @user
    @oe = @course.enroll_user(@user, "ObserverEnrollment")
    @oe.accept
    @oe.update_attribute(:associated_user_id, @student.id)
  end

  it "uses GradebooksController" do
    expect(controller).to be_an_instance_of(GradebooksController)
  end

  describe "GET 'grade_summary'" do
    context "when logged in as a student" do
      before do
        user_session(@student)
        @assignment = @course.assignments.create!(title: "Example Assignment")
        @media_object = factory_with_protected_attributes(MediaObject, media_id: "m-someid", media_type: "video", title: "Example Media Object", context: @course)
        @mock_kaltura = double("CanvasKaltura::ClientV3")
        allow(CanvasKaltura::ClientV3).to receive(:new).and_return(@mock_kaltura)
        @media_sources = [{
          height: "240",
          width: "336",
          content_type: "video/mp4",
          url: "https://kaltura.example.com/some/url",
        }]
        allow(@mock_kaltura).to receive_messages(startSession: nil, media_sources: @media_sources)
        @media_track = @media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "English").as_json["media_track"]
      end

      it "includes muted assignments" do
        @assignment.ensure_post_policy(post_manually: true)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        expect(assigns[:js_env][:assignment_groups].first[:assignments].size).to eq 1
        expect(assigns[:js_env][:assignment_groups].first[:assignments].first[:muted]).to be true
      end

      it "does not include score, excused, or workflow_state of unposted submissions" do
        @assignment.ensure_post_policy(post_manually: true)
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == @assignment.id }
        aggregate_failures do
          expect(submission).not_to have_key(:score)
          expect(submission).not_to have_key(:excused)
          expect(submission).not_to have_key(:workflow_state)
        end
      end

      it "includes score, excused, and workflow_state of posted submissions" do
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == @assignment.id }
        aggregate_failures do
          expect(submission[:score]).to be 10.0
          expect(submission[:excused]).to be false
          expect(submission[:workflow_state]).to eq "graded"
        end
      end

      it "includes submission_comments of posted submissions" do
        @assignment.anonymous_peer_reviews = true
        @assignment.save!
        attachment = attachment_model(context: @assignment)
        attachment2 = attachment_model(context: @assignment)
        other_student = @course.enroll_user(User.create!(name: "some other user")).user
        deleted_media_object = factory_with_protected_attributes(MediaObject, media_id: "m-someid2", media_type: "video", title: "Example Media Object 2", context: @course)
        submission_to_comment = @assignment.grade_student(@student, grade: 10, grader: @teacher).first
        comment_1 = submission_to_comment.add_comment(comment: "a student comment", author: @teacher, attachments: [attachment])
        comment_2 = submission_to_comment.add_comment(comment: "another student comment", author: @teacher, attachments: [attachment, attachment2])
        comment_3 = submission_to_comment.add_comment(comment: "an anonymous comment", author: other_student)
        comment_4 = submission_to_comment.add_comment(media_comment_id: "m-someid", media_comment_type: "video", author: @student)
        submission_to_comment.add_comment(media_comment_id: "m-someid2", media_comment_type: "video", author: @student)
        deleted_media_object.destroy_permanently!
        comment_1.mark_read!(@student)

        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == @assignment.id }
        aggregate_failures do
          expect(submission[:score]).to be 10.0
          expect(submission[:submission_comments].length).to be 5

          submission_comment_1 = submission[:submission_comments].first
          expect(submission_comment_1).to include({
                                                    "comment" => comment_1["comment"],
                                                    "attempt" => comment_1["attempt"],
                                                    "author_name" => comment_1["author_name"],
                                                    "display_updated_at" => datetime_string(comment_1["updated_at"]),
                                                    "is_read" => true,
                                                    "attachments" => [
                                                      {
                                                        "id" => attachment.id,
                                                        "display_name" => attachment.display_name,
                                                        "mime_class" => attachment.mime_class,
                                                        "url" => file_download_url(attachment)
                                                      }
                                                    ]
                                                  })

          submission_comment_2 = submission[:submission_comments].second
          expect(submission_comment_2).to include({
                                                    "comment" => comment_2["comment"],
                                                    "attempt" => comment_2["attempt"],
                                                    "author_name" => comment_2["author_name"],
                                                    "display_updated_at" => datetime_string(comment_2["updated_at"]),
                                                    "is_read" => false,
                                                    "attachments" => [
                                                      {
                                                        "id" => attachment.id,
                                                        "display_name" => attachment.display_name,
                                                        "mime_class" => attachment.mime_class,
                                                        "url" => file_download_url(attachment)
                                                      },
                                                      {
                                                        "id" => attachment2.id,
                                                        "display_name" => attachment2.display_name,
                                                        "mime_class" => attachment2.mime_class,
                                                        "url" => file_download_url(attachment2)
                                                      }
                                                    ]
                                                  })
          submission_comment_3 = submission[:submission_comments].third
          expect(submission_comment_3).to include({
                                                    "comment" => comment_3["comment"],
                                                    "attempt" => comment_3["attempt"],
                                                    "author_name" => "Anonymous User",
                                                    "display_updated_at" => datetime_string(comment_3["updated_at"]),
                                                    "is_read" => false,
                                                    "attachments" => []
                                                  })
          submission_comment_4 = submission[:submission_comments].fourth
          expect(submission_comment_4).to include({
                                                    "comment" => comment_4["comment"],
                                                    "attempt" => comment_4["attempt"],
                                                    "author_name" => comment_4["author_name"],
                                                    "display_updated_at" => datetime_string(comment_4["updated_at"]),
                                                    "is_read" => false,
                                                    "attachments" => [],
                                                    "media_object" => {
                                                      "id" => @media_object.media_id,
                                                      "title" => @media_object.title,
                                                      "media_sources" => [
                                                        {
                                                          "height" => @media_sources.first[:height],
                                                          "width" => @media_sources.first[:width],
                                                          "content_type" => @media_sources.first[:content_type],
                                                          "url" => @media_sources.first[:url]
                                                        }
                                                      ],
                                                      "media_tracks" => [
                                                        {
                                                          "id" => @media_track["id"],
                                                          "locale" => @media_track["locale"],
                                                          "content" => @media_track["content"],
                                                          "kind" => @media_track["kind"],
                                                        }
                                                      ]

                                                    }
                                                  })
        end
      end
    end

    context "when logged in as a teacher" do
      before do
        user_session(@teacher)
        @assignment = @course.assignments.create!(points_possible: 10)
      end

      it "includes muted assignments" do
        @assignment.ensure_post_policy(post_manually: true)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        expect(assigns[:js_env][:assignment_groups].first[:assignments].size).to eq 1
        expect(assigns[:js_env][:assignment_groups].first[:assignments].first[:muted]).to be true
      end

      it "does not include score, excused, or workflow_state of unposted submissions" do
        @assignment.ensure_post_policy(post_manually: true)
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == @assignment.id }
        aggregate_failures do
          expect(submission).not_to have_key(:score)
          expect(submission).not_to have_key(:excused)
          expect(submission).not_to have_key(:workflow_state)
        end
      end

      it "includes score, excused, and workflow_state of posted submissions" do
        @assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == @assignment.id }
        aggregate_failures do
          expect(submission[:score]).to be 10.0
          expect(submission[:excused]).to be false
          expect(submission[:workflow_state]).to eq "graded"
        end
      end

      it "returns submissions for inactive students" do
        @assignment.grade_student(@student, grade: 6.6, grader: @teacher)
        enrollment = @course.enrollments.find_by(user: @student)
        enrollment.deactivate
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
        expect(assigns.fetch(:js_env).fetch(:submissions).first.fetch(:score)).to be 6.6
      end

      it "returns assignments for inactive students" do
        @assignment.grade_student(@student, grade: 6.6, grader: @teacher)
        enrollment = @course.enrollments.find_by(user: @student)
        enrollment.deactivate
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
        assignment_id = assigns.dig(:js_env, :assignment_groups, 0, :assignments, 0, :id)
        expect(assignment_id).to eq @assignment.id
      end
    end

    it "redirects to the login page if the user is logged out" do
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(response).to redirect_to(login_url)
      expect(flash[:warning]).to be_present
    end

    it "redirects teacher to gradebook" do
      user_session(@teacher)
      get "grade_summary", params: { course_id: @course.id, id: nil }
      expect(response).to redirect_to(action: "show")
    end

    it "renders for current user" do
      user_session(@student)
      get "grade_summary", params: { course_id: @course.id, id: nil }
      expect(response).to render_template("grade_summary")
    end

    it "does not allow access for inactive enrollment" do
      user_session(@student)
      @student_enrollment.deactivate
      get "grade_summary", params: { course_id: @course.id, id: nil }
      assert_unauthorized
    end

    it "renders with specified user_id" do
      user_session(@student)
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(response).to render_template("grade_summary")
      expect(assigns[:presenter].courses_with_grades).not_to be_nil
    end

    it "does not allow access for wrong user" do
      user_factory(active_all: true)
      user_session(@user)
      get "grade_summary", params: { course_id: @course.id, id: nil }
      assert_unauthorized
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      assert_unauthorized
    end

    it "allows access for a linked observer" do
      user_session(@observer)
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(response).to render_template("grade_summary")
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "does not allow access for a linked student" do
      user_factory(active_all: true)
      user_session(@user)
      @se = @course.enroll_student(@user)
      @se.accept
      @se.update_attribute(:associated_user_id, @student.id)
      @user.reload
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      assert_unauthorized
    end

    it "does not allow access for an observer linked in a different course" do
      @course1 = @course
      course_factory(active_all: true)
      @course2 = @course

      user_session(@observer)

      get "grade_summary", params: { course_id: @course2.id, id: @student.id }
      assert_unauthorized
    end

    it "allows concluded teachers to see a student grades pages" do
      user_session(@teacher)
      @teacher_enrollment.conclude
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(response).to be_successful
      expect(response).to render_template("grade_summary")
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "allows concluded students to see their grades pages" do
      user_session(@student)
      @student_enrollment.conclude
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(response).to render_template("grade_summary")
    end

    it "gives a student the option to switch between courses" do
      pseudonym(@teacher, username: "teacher@example.com")
      pseudonym(@student, username: "student@example.com")
      course_with_teacher(user: @teacher, active_all: 1)
      student_in_course user: @student, active_all: 1
      user_session(@student)
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(response).to be_successful
      expect(assigns[:presenter].courses_with_grades).not_to be_nil
      expect(assigns[:presenter].courses_with_grades.length).to eq 2
    end

    it "does not give a teacher the option to switch between courses when viewing a student's grades" do
      pseudonym(@teacher, username: "teacher@example.com")
      pseudonym(@student, username: "student@example.com")
      course_with_teacher(user: @teacher, active_all: 1)
      student_in_course user: @student, active_all: 1
      user_session(@teacher)
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(response).to be_successful
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "does not give a linked observer the option to switch between courses when viewing a student's grades" do
      pseudonym(@teacher, username: "teacher@example.com")
      pseudonym(@student, username: "student@example.com")
      user_with_pseudonym(username: "parent@example.com", active_all: 1)

      course1 = @course
      course2 = course_with_teacher(user: @teacher, active_all: 1).course
      student_in_course user: @student, active_all: 1
      oe = course2.enroll_user(@observer, "ObserverEnrollment")
      oe.associated_user = @student
      oe.save!
      oe.accept

      user_session(@observer)
      get "grade_summary", params: { course_id: course1.id, id: @student.id }
      expect(response).to be_successful
      expect(assigns[:courses_with_grades]).to be_nil
    end

    it "assigns assignment group values for grade calculator to ENV" do
      user_session(@teacher)
      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:submissions]).not_to be_nil
      expect(assigns[:js_env][:assignment_groups]).not_to be_nil
    end

    it "does not include assignment discussion information in grade calculator ENV data" do
      user_session(@teacher)
      assignment1 = @course.assignments.create(title: "Assignment 1")
      assignment1.submission_types = "discussion_topic"
      assignment1.save!

      get "grade_summary", params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:assignment_groups].first[:assignments].first["discussion_topic"]).to be_nil
    end

    it "includes assignment sort options in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:assignment_sort_options]).to match_array [["Due Date", "due_at"], ["Name", "title"]]
    end

    it "includes the current assignment sort order in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      order = assigns[:js_env][:current_assignment_sort_order]
      expect(order).to eq :due_at
    end

    it "includes the current grading period id in the ENV" do
      group = @course.root_account.grading_period_groups.create!
      period = group.grading_periods.create!(title: "GP", start_date: 3.months.ago, end_date: 3.months.from_now)
      group.enrollment_terms << @course.enrollment_term
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:current_grading_period_id]).to eq period.id
    end

    it "includes courses_with_grades, with each course having an id, nickname, and URL" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      courses = assigns[:js_env][:courses_with_grades]
      expect(courses).to all include("id", "nickname", "url")
    end

    it "includes the URL to save the assignment order in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env]).to have_key :save_assignment_order_url
    end

    it "includes the students for the grade summary page in the ENV" do
      user_session(@teacher)
      get :grade_summary, params: { course_id: @course.id, id: @student.id }
      expect(assigns[:js_env][:students]).to match_array [@student].as_json(include_root: false)
    end

    context "final grade override" do
      before(:once) do
        @course.update!(grading_standard_enabled: true)
        @course.assignments.create!(title: "an assignment")
        @student_enrollment.scores.find_by(course_score: true).update!(override_score: 99)
      end

      context "when the feature is enabled" do
        before(:once) do
          @course.enable_feature!(:final_grades_override)
          @course.update!(allow_final_grade_override: true)
        end

        it "includes the effective final score in the ENV if course setting is enabled" do
          user_session(@teacher)
          get :grade_summary, params: { course_id: @course.id, id: @student.id }
          expect(assigns[:js_env][:effective_final_score]).to eq 99
        end

        it "does not include the effective final score in the ENV if the course setting is not enabled" do
          @course.update!(allow_final_grade_override: false)
          @student_enrollment.scores.find_by(course_score: true).update!(override_score: nil)
          user_session(@teacher)
          get :grade_summary, params: { course_id: @course.id, id: @student.id }
          expect(assigns[:js_env]).not_to have_key(:effective_final_score)
        end

        it "does not include the effective final score in the ENV if there is no score" do
          invited_student = @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "invited").user
          user_session(@teacher)
          get :grade_summary, params: { course_id: @course.id, id: invited_student.id }
          expect(assigns[:js_env]).not_to have_key(:effective_final_score)
        end

        describe "final grade override score custom status" do
          let(:status) { CustomGradeStatus.create!(name: "custom", color: "#000000", root_account_id: @course.root_account, created_by: @teacher) }

          it "does not include the final grade override score custom status id if the ff is off" do
            Account.site_admin.disable_feature!(:custom_gradebook_statuses)
            invited_student_enrollment = @course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "invited")
            score = invited_student_enrollment.update_override_score(
              override_score: 95,
              updating_user: @teacher
            )
            score.update!(custom_grade_status_id: status.id)
            user_session(@teacher)
            get :grade_summary, params: { course_id: @course.id, id: @student.id }
            expect(assigns[:js_env]).not_to have_key(:final_override_custom_grade_status_id)
          end

          it "does not include the final grade override score custom status id if there is no status" do
            Score.find_by(course_score: true).update!(custom_grade_status_id: nil, override_score: 95)
            user_session(@teacher)
            get :grade_summary, params: { course_id: @course.id, id: @student.id }
            expect(assigns[:js_env]).not_to have_key(:final_override_custom_grade_status_id)
          end

          it "includes the final grade override score custom status id if the ff is on and there is a status" do
            Score.find_by(course_score: true).update!(custom_grade_status_id: status.id)
            user_session(@teacher)
            get :grade_summary, params: { course_id: @course.id, id: @student.id }
            expect(assigns[:js_env]).to have_key(:final_override_custom_grade_status_id)
          end

          it "includes the final grade override score custom status id if the ff is on and there is a status and there is no score" do
            Score.find_by(course_score: true).update!(custom_grade_status_id: status.id, override_score: nil)
            user_session(@teacher)
            get :grade_summary, params: { course_id: @course.id, id: @student.id }
            expect(assigns[:js_env]).to have_key(:final_override_custom_grade_status_id)
          end
        end

        it "takes the effective final score for the grading period, if present" do
          grading_period_group = @course.grading_period_groups.create!
          grading_period = grading_period_group.grading_periods.create!(
            title: "a grading period",
            start_date: 1.day.ago,
            end_date: 1.day.from_now
          )
          @student_enrollment.scores.find_by(grading_period:).update!(override_score: 84)
          user_session(@teacher)
          get :grade_summary, params: { course_id: @course.id, id: @student.id }
          expect(assigns[:js_env][:effective_final_score]).to eq 84
        end

        it "takes the effective final score for the course score, if viewing all grading periods" do
          user_session(@teacher)
          get :grade_summary, params: { course_id: @course.id, id: @student.id, grading_period_id: 0 }
          expect(assigns[:js_env][:effective_final_score]).to eq 99
        end
      end

      it "does not include the effective final score in the ENV if the feature is disabled" do
        @course.disable_feature!(:final_grades_override)
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
        expect(assigns[:js_env]).not_to have_key(:effective_final_score)
      end
    end

    context "assignment sorting" do
      let!(:teacher_session) { user_session(@teacher) }
      let!(:assignment1) { @course.assignments.create(title: "Banana", position: 2) }
      let!(:assignment2) { @course.assignments.create(title: "Apple", due_at: 3.days.from_now, position: 3) }
      let!(:assignment3) do
        assignment_group = @course.assignment_groups.create!(position: 2)
        @course.assignments.create!(
          assignment_group:, title: "Carrot", due_at: 2.days.from_now, position: 1
        )
      end
      let(:assignment_ids) { assigns[:presenter].assignments.select { |a| a.instance_of?(Assignment) }.map(&:id) }

      it "sorts assignments by due date (null last), then title if there is no saved order preference" do
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
      end

      it "sort order of 'due_at' sorts by due date (null last), then title" do
        @teacher.set_preference(:course_grades_assignment_order, @course.id, :due_at)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
      end

      context "sort by: title" do
        let!(:teacher_setup) do
          @teacher.set_preference(:course_grades_assignment_order, @course.id, :title)
        end

        it "sorts assignments by title" do
          get "grade_summary", params: { course_id: @course.id, id: @student.id }
          expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end

        it "ingores case" do
          assignment1.title = "banana"
          assignment1.save!
          get "grade_summary", params: { course_id: @course.id, id: @student.id }
          expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end
      end

      it "sort order of 'assignment_group' sorts by assignment group position, then assignment position" do
        @teacher.preferences[:course_grades_assignment_order] = { @course.id => :assignment_group }
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        expect(assignment_ids).to eq [assignment1, assignment2, assignment3].map(&:id)
      end

      context "sort by: module" do
        let!(:first_context_module) { @course.context_modules.create! }
        let!(:second_context_module) { @course.context_modules.create! }
        let!(:assignment1_tag) do
          a1_tag = assignment1.context_module_tags.new(context: @course, position: 1, tag_type: "context_module")
          a1_tag.context_module = second_context_module
          a1_tag.save!
        end

        let!(:assignment2_tag) do
          a2_tag = assignment2.context_module_tags.new(context: @course, position: 3, tag_type: "context_module")
          a2_tag.context_module = first_context_module
          a2_tag.save!
        end

        let!(:assignment3_tag) do
          a3_tag = assignment3.context_module_tags.new(context: @course, position: 2, tag_type: "context_module")
          a3_tag.context_module = first_context_module
          a3_tag.save!
        end

        let!(:teacher_setup) do
          @teacher.set_preference(:course_grades_assignment_order, @course.id, :module)
        end

        it "sorts by module position, then context module tag position" do
          get "grade_summary", params: { course_id: @course.id, id: @student.id }
          expect(assignment_ids).to eq [assignment3, assignment2, assignment1].map(&:id)
        end

        it "sorts by module position, then context module tag position, " \
           "with those not belonging to a module sorted last" do
          assignment3.context_module_tags.first.destroy!
          get "grade_summary", params: { course_id: @course.id, id: @student.id }
          expect(assignment_ids).to eq [assignment2, assignment1, assignment3].map(&:id)
        end
      end
    end

    describe "course_active_grading_scheme" do
      it "uses the course's grading scheme when a grading scheme is set" do
        user_session(@student)
        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]

        grading_standard = @course.grading_standards.build({ title: "My Grading Scheme",
                                                             data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                             points_based: true,
                                                             scaling_factor: 4.0,
                                                             workflow_state: "active" })
        @course.update!(grading_standard:)
        all_grading_periods_id = 0
        get "grade_summary", params: { course_id: @course.id, id: @student.id, grading_period_id: all_grading_periods_id }
        expect(controller.js_env[:course_active_grading_scheme]).to eq({ "id" => grading_standard.id.to_s,
                                                                         "title" => grading_standard.title,
                                                                         "context_type" => "Course",
                                                                         "context_id" => @course.id,
                                                                         "context_name" => @course.name,
                                                                         "data" => data,
                                                                         "permissions" => { "manage" => false },
                                                                         "points_based" => grading_standard.points_based,
                                                                         "scaling_factor" => grading_standard.scaling_factor,
                                                                         "workflow_state" => "active" })
        expect(controller.js_env[:grading_scheme]).to be_nil
      end

      it "uses the Canvas default grading scheme if the course is set to use default grading scheme" do
        user_session(@student)
        @course.update!(grading_standard_id: 0)
        all_grading_periods_id = 0
        get "grade_summary", params: { course_id: @course.id, id: @student.id, grading_period_id: all_grading_periods_id }
        expect(controller.js_env[:course_active_grading_scheme]).to eq({ "id" => "",
                                                                         "title" => "Default Canvas Grading Scheme",
                                                                         "context_type" => "Course",
                                                                         "context_id" => @course.id,
                                                                         "context_name" => @course.name,
                                                                         "data" => [{ "name" => "A", "value" => 0.94 }, { "name" => "A-", "value" => 0.9 }, { "name" => "B+", "value" => 0.87 }, { "name" => "B", "value" => 0.84 }, { "name" => "B-", "value" => 0.8 }, { "name" => "C+", "value" => 0.77 }, { "name" => "C", "value" => 0.74 }, { "name" => "C-", "value" => 0.7 }, { "name" => "D+", "value" => 0.67 }, { "name" => "D", "value" => 0.64 }, { "name" => "D-", "value" => 0.61 }, { "name" => "F", "value" => 0.0 }],
                                                                         "permissions" => { "manage" => false },
                                                                         "points_based" => false,
                                                                         "scaling_factor" => 1.0,
                                                                         "workflow_state" => nil })

        expect(controller.js_env[:grading_scheme]).to be_nil
      end

      it "uses the default canvas grading scheme when a course's grading scheme was (soft) deleted" do
        user_session(@student)
        data = [{ "name" => "A", "value" => 0.90 },
                { "name" => "B", "value" => 0.80 },
                { "name" => "C", "value" => 0.70 },
                { "name" => "D", "value" => 0.60 },
                { "name" => "F", "value" => 0.0 }]

        grading_standard = @course.grading_standards.build({ title: "My Grading Scheme",
                                                             data: GradingSchemesJsonController.to_grading_standard_data(data),
                                                             points_based: true,
                                                             scaling_factor: 4.0 })
        @course.update!(grading_standard:)
        @course.reload
        grading_standard.destroy
        @course.reload

        all_grading_periods_id = 0
        get "grade_summary", params: { course_id: @course.id, id: @student.id, grading_period_id: all_grading_periods_id }
        expect(controller.js_env[:course_active_grading_scheme]).to eq({ "id" => "",
                                                                         "title" => "Default Canvas Grading Scheme",
                                                                         "context_type" => "Course",
                                                                         "context_id" => @course.id,
                                                                         "context_name" => @course.name,
                                                                         "data" => [{ "name" => "A", "value" => 0.94 }, { "name" => "A-", "value" => 0.9 }, { "name" => "B+", "value" => 0.87 }, { "name" => "B", "value" => 0.84 }, { "name" => "B-", "value" => 0.8 }, { "name" => "C+", "value" => 0.77 }, { "name" => "C", "value" => 0.74 }, { "name" => "C-", "value" => 0.7 }, { "name" => "D+", "value" => 0.67 }, { "name" => "D", "value" => 0.64 }, { "name" => "D-", "value" => 0.61 }, { "name" => "F", "value" => 0.0 }],
                                                                         "permissions" => { "manage" => false },
                                                                         "points_based" => false,
                                                                         "scaling_factor" => 1.0,
                                                                         "workflow_state" => nil })
        expect(controller.js_env[:grading_scheme]).to be_nil
      end

      it "uses no course grading scheme if the course is not set to use grading schemes" do
        user_session(@student)
        all_grading_periods_id = 0
        get "grade_summary", params: { course_id: @course.id, id: @student.id, grading_period_id: all_grading_periods_id }
        # expect(controller.js_env[:course_active_grading_scheme]).to be_nil
        expect(controller.js_env[:grading_scheme]).to be_nil
      end
    end

    context "custom gradebook statuses in grade summary" do
      it "does not include custom gradebook status ids on submissions when feature flag is disabled" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        user_session(@student)
        assignment = @course.assignments.create!
        assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        controller.load_grade_summary_data
        grade_summary_submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
        expect(grade_summary_submission).not_to have_key(:custom_grade_status_id)
      end

      it "does include custom gradebook status ids on submissions when feature flag is enabled" do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        user_session(@student)
        assignment = @course.assignments.create!
        assignment.grade_student(@student, grade: 10, grader: @teacher)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        controller.load_grade_summary_data
        grade_summary_submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
        expect(grade_summary_submission).to have_key(:custom_grade_status_id)
        expect(grade_summary_submission[:custom_grade_status_id]).to be_nil
      end

      it "returns the correct status id on submissions when they have a custom status and the feature flag is enabled" do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        user_session(@student)
        assignment = @course.assignments.create!
        submission = assignment.grade_student(@student, grade: 10, grader: @teacher).first
        status = CustomGradeStatus.create!(name: "custom status", color: "#00ffff", root_account_id: @course.root_account_id, created_by: @teacher)
        submission.update!(custom_grade_status: status)
        get "grade_summary", params: { course_id: @course.id, id: @student.id }
        controller.load_grade_summary_data
        grade_summary_submission = assigns[:js_env][:submissions].find { |s| s[:assignment_id] == assignment.id }
        expect(grade_summary_submission).to have_key(:custom_grade_status_id)
        expect(grade_summary_submission[:custom_grade_status_id]).to eq(status.id)
      end
    end

    context "with grading periods" do
      let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
      let(:period_helper) { Factories::GradingPeriodHelper.new }

      before :once do
        @grading_period_group = group_helper.create_for_account(@course.root_account, weighted: true)
        term = @course.enrollment_term
        term.grading_period_group = @grading_period_group
        term.save!
        @grading_periods = period_helper.create_presets_for_group(@grading_period_group, :past, :current, :future)
      end

      it "does not display totals if 'All Grading Periods' is selected" do
        user_session(@student)
        all_grading_periods_id = 0
        get "grade_summary", params: { course_id: @course.id, id: @student.id, grading_period_id: all_grading_periods_id }
        expect(assigns[:exclude_total]).to be true
      end

      it "assigns grading period values for grade calculator to ENV" do
        user_session(@teacher)
        all_grading_periods_id = 0
        get "grade_summary", params: { course_id: @course.id, id: @student.id, grading_period_id: all_grading_periods_id }
        expect(assigns[:js_env][:submissions]).not_to be_nil
        expect(assigns[:js_env][:grading_periods]).not_to be_nil
      end

      it "displays totals if any grading period other than 'All Grading Periods' is selected" do
        user_session(@student)
        get "grade_summary", params: { course_id: @course.id, id: @student.id, grading_period_id: @grading_periods.first.id }
        expect(assigns[:exclude_total]).to be false
      end

      it "includes the grading period group (as 'set') in the ENV" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
        grading_period_set = assigns[:js_env][:grading_period_set]
        expect(grading_period_set[:id]).to eq @grading_period_group.id
      end

      it "includes grading periods within the group" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
        grading_period_set = assigns[:js_env][:grading_period_set]
        expect(grading_period_set[:grading_periods].count).to eq 3
        period = grading_period_set[:grading_periods][0]
        expect(period).to have_key(:is_closed)
        expect(period).to have_key(:is_last)
      end

      it "includes necessary keys with each grading period" do
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
        periods = assigns[:js_env][:grading_period_set][:grading_periods]
        expect(periods).to all include(:id, :start_date, :end_date, :close_date, :is_closed, :is_last)
      end

      it "is ordered by start_date" do
        @grading_periods.sort_by!(&:id)
        grading_period_ids = @grading_periods.map(&:id)
        @grading_periods.last.update!(
          start_date: @grading_periods.first.start_date - 1.week,
          end_date: @grading_periods.first.start_date - 1.second
        )
        user_session(@teacher)
        get :grade_summary, params: { course_id: @course.id, id: @student.id }
        periods = assigns[:js_env][:grading_period_set][:grading_periods]
        expected_ids = [grading_period_ids.last].concat(grading_period_ids[0..-2])
        expect(periods.map { |period| period.fetch("id") }).to eql expected_ids
      end
    end

    context "with assignment due date overrides" do
      before :once do
        @assignment = @course.assignments.create(title: "Assignment 1")
        @due_at = 4.days.from_now
      end

      def check_grades_page(due_at)
        [@student, @teacher, @observer].each do |u|
          controller.js_env.clear
          user_session(u)
          get "grade_summary", params: { course_id: @course.id, id: @student.id }
          assignment_due_at = assigns[:presenter].assignments.find { |a| a.instance_of?(Assignment) }.due_at
          expect(assignment_due_at.to_i).to eq due_at.to_i
        end
      end

      it "reflects section overrides" do
        section = @course.default_section
        override = assignment_override_model(assignment: @assignment)
        override.set = section
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(@due_at)
      end

      it "shows the latest section override in student view" do
        section = @course.default_section
        override = assignment_override_model(assignment: @assignment)
        override.set = section
        override.override_due_at(@due_at)
        override.save!

        section2 = @course.course_sections.create!
        override2 = assignment_override_model(assignment: @assignment)
        override2.set = section2
        override2.override_due_at(@due_at - 1.day)
        override2.save!

        user_session(@teacher)
        @fake_student = @course.student_view_student
        session[:become_user_id] = @fake_student.id

        get "grade_summary", params: { course_id: @course.id, id: @fake_student.id }
        assignment_due_at = assigns[:presenter].assignments.find { |a| a.instance_of?(Assignment) }.due_at
        expect(assignment_due_at.to_i).to eq @due_at.to_i
      end

      it "reflects group overrides when student is a member" do
        @assignment.group_category = group_category
        @assignment.save!
        group = @assignment.group_category.groups.create!(context: @course)
        group.add_user(@student)

        override = assignment_override_model(assignment: @assignment)
        override.set = group
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(@due_at)
      end

      it "does not reflect group overrides when student is not a member" do
        @assignment.group_category = group_category
        @assignment.save!
        group = @assignment.group_category.groups.create!(context: @course)

        override = assignment_override_model(assignment: @assignment)
        override.set = group
        override.override_due_at(@due_at)
        override.save!
        check_grades_page(nil)
      end

      it "reflects ad-hoc overrides" do
        override = assignment_override_model(assignment: @assignment)
        override.override_due_at(@due_at)
        override.save!
        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!
        check_grades_page(@due_at)
      end

      it "uses the latest override" do
        section = @course.default_section
        override = assignment_override_model(assignment: @assignment)
        override.set = section
        override.override_due_at(@due_at)
        override.save!

        override = assignment_override_model(assignment: @assignment)
        override.override_due_at(@due_at + 1.day)
        override.save!
        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!

        check_grades_page(@due_at + 1.day)
      end
    end

    it "raises an exception on a non-integer :id" do
      user_session(@teacher)
      assert_page_not_found do
        get "grade_summary", params: { course_id: @course.id, id: "lqw" }
      end
    end

    context "js_env" do
      before do
        user_session(@student)
      end

      describe "outcome_service_results_to_canvas" do
        it "is set to true if outcome_service_results_to_canvas feature flag is enabled" do
          @course.enable_feature!(:outcome_service_results_to_canvas)
          get "grade_summary", params: { course_id: @course.id, id: @student.id }
          js_env = assigns[:js_env]
          expect(js_env[:outcome_service_results_to_canvas]).to be true
        end

        it "is set to false if outcome_service_results_to_canvas feature flag is disabled" do
          @course.disable_feature!(:outcome_service_results_to_canvas)
          get "grade_summary", params: { course_id: @course.id, id: @student.id }
          js_env = assigns[:js_env]
          expect(js_env[:outcome_service_results_to_canvas]).to be false
        end
      end
    end
  end

  describe "GET 'show'" do
    let(:gradebook_options) { controller.js_env.fetch(:GRADEBOOK_OPTIONS) }

    context "as an admin" do
      before do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
      end

      describe "js_env enhanced_gradebook_filters" do
        it "sets enhanced_gradebook_filters in js_env as true if enabled" do
          @course.enable_feature!(:enhanced_gradebook_filters)
          user_session(@teacher)
          get :show, params: { course_id: @course.id }
          expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:enhanced_gradebook_filters]).to be(true)
        end

        it "sets enhanced_gradebook_filters in js_env as false if disabled" do
          @course.disable_feature!(:enhanced_gradebook_filters)
          user_session(@teacher)
          get :show, params: { course_id: @course.id }
          expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:enhanced_gradebook_filters]).to be(false)
        end
      end

      it "renders default gradebook when preferred with 'default'" do
        @admin.set_preference(:gradebook_version, "default")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradebook")
      end

      it "renders default gradebook when preferred with '2'" do
        # most users will have this set from before New Gradebook existed
        @admin.set_preference(:gradebook_version, "2")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradebook")
      end

      it "renders screenreader gradebook when preferred with 'individual'" do
        @admin.set_preference(:gradebook_version, "individual")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/individual")
      end

      it "renders screenreader gradebook when preferred with 'srgb'" do
        # most a11y users will have this set from before New Gradebook existed
        @admin.set_preference(:gradebook_version, "srgb")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/individual")
      end

      it "renders default gradebook when user has no preference" do
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradebook")
      end

      it "ignores the parameter version when not in development" do
        allow(Rails.env).to receive(:development?).and_return(false)
        @admin.set_preference(:gradebook_version, "default")
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("gradebooks/gradebook")
      end

      it "renders enhanced individual gradebook when individual_enhanced & individual_gradebook_enhancements is enabled" do
        @course.root_account.enable_feature!(:individual_gradebook_enhancements)
        @admin.set_preference(:gradebook_version, "individual_enhanced")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("layouts/application")
      end

      it "renders traditional gradebook when individual_gradebook_enhancements is disabled" do
        @course.root_account.disable_feature!(:individual_gradebook_enhancements)
        @admin.set_preference(:gradebook_version, "individual_enhanced")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/gradebook")
      end

      describe "score to ungraded" do
        before do
          options = Gradebook::ApplyScoreToUngradedSubmissions::Options.new(
            percent: 50,
            excused: false,
            mark_as_missing: false,
            only_apply_to_past_due: false
          )
          @progress = Gradebook::ApplyScoreToUngradedSubmissions.queue_apply_score(course: @course, grader: @teacher, options:)
        end

        describe "FF disabled" do
          before do
            @course.account.disable_feature!(:apply_score_to_ungraded)
          end

          it "sets gradebook_score_to_ungraded_progress in js_env as null" do
            user_session(@teacher)
            get :show, params: { course_id: @course.id }
            expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:gradebook_score_to_ungraded_progress]).to be_nil
          end
        end

        describe "FF enabled" do
          before do
            @course.account.enable_feature!(:apply_score_to_ungraded)
          end

          it "sets gradebook_score_to_ungraded_progress in js_env as null if the last progress has workflow state failed" do
            @progress.fail!

            user_session(@teacher)
            get :show, params: { course_id: @course.id }
            expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:gradebook_score_to_ungraded_progress]).to be_nil
          end

          it "sets gradebook_score_to_ungraded_progress object in js_env if the last progress has workflow state queued" do
            @progress.update_attribute(:workflow_state, "queued")

            user_session(@teacher)
            get :show, params: { course_id: @course.id }
            expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:gradebook_score_to_ungraded_progress]).to eq(@progress)
          end

          it "sets gradebook_score_to_ungraded_progress object in js_env if the last progress has workflow state running" do
            @progress.start!

            user_session(@teacher)
            get :show, params: { course_id: @course.id }
            expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:gradebook_score_to_ungraded_progress]).to eq(@progress)
          end

          it "sets gradebook_score_to_ungraded_progress object in js_env if the last progress has workflow state completed" do
            @progress.update_attribute(:workflow_state, "completed")

            user_session(@teacher)
            get :show, params: { course_id: @course.id }
            expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:gradebook_score_to_ungraded_progress]).to eq(@progress)
          end
        end
      end
    end

    context "in development and requested version is 'default'" do
      before do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.set_preference(:gradebook_version, "individual")
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders default gradebook" do
        get "show", params: { course_id: @course.id, version: "default" }
        expect(response).to render_template("gradebooks/gradebook")
      end
    end

    context "in development and requested version is 'individual'" do
      before do
        account_admin_user(account: @course.root_account)
        user_session(@admin)
        @admin.set_preference(:gradebook_version, "default")
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "renders screenreader gradebook" do
        get "show", params: { course_id: @course.id, version: "individual" }
        expect(response).to render_template("gradebooks/individual")
      end
    end

    describe "prefetching" do
      render_views

      before do
        user_session(@teacher)
      end

      it "prefetches user ids" do
        get :show, params: { course_id: @course.id }

        scripts = Nokogiri::HTML5(response.body).css("script").map(&:text)
        expect(scripts).to include a_string_matching(/\bprefetched_xhrs\b.*\buser_ids\b/)
      end

      it "prefetches grading period assignments when the course uses grading periods" do
        group_helper = Factories::GradingPeriodGroupHelper.new
        period_helper = Factories::GradingPeriodHelper.new

        grading_period_group = group_helper.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = grading_period_group
        term.save!
        period_helper.create_presets_for_group(grading_period_group, :past, :current, :future)

        get :show, params: { course_id: @course.id }

        scripts = Nokogiri::HTML5(response.body).css("script").map(&:text)
        expect(scripts).to include a_string_matching(/\bprefetched_xhrs\b.*\bgrading_period_assignments\b/)
      end

      it "does not prefetch grading period assignments when the course has no grading periods" do
        get :show, params: { course_id: @course.id }

        scripts = Nokogiri::HTML5(response.body).css("script").map(&:text)
        expect(scripts).not_to include a_string_matching(/\bprefetched_xhrs\b.*\bgrading_period_assignments\b/)
      end
    end

    describe "js_env" do
      before do
        user_session(@teacher)
      end

      describe "course_settings" do
        let(:course_settings) { gradebook_options.fetch(:course_settings) }

        describe "filter_speed_grader_by_student_group" do
          before :once do
            @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
          end

          it "sets filter_speed_grader_by_student_group to true when filter_speed_grader_by_student_group? is true" do
            @course.update!(filter_speed_grader_by_student_group: true)
            get :show, params: { course_id: @course.id }
            expect(course_settings.fetch(:filter_speed_grader_by_student_group)).to be true
          end

          it "sets filter_speed_grader_by_student_group to false when filter_speed_grader_by_student_group? is false" do
            @course.update!(filter_speed_grader_by_student_group: false)
            get :show, params: { course_id: @course.id }
            expect(course_settings.fetch(:filter_speed_grader_by_student_group)).to be false
          end
        end

        describe "allow_final_grade_override" do
          before :once do
            @course.enable_feature!(:final_grades_override)
            @course.update!(allow_final_grade_override: true)
          end

          let(:allow_final_grade_override) { course_settings.fetch(:allow_final_grade_override) }

          it "sets allow_final_grade_override to true when final grade override is allowed" do
            get :show, params: { course_id: @course.id }
            expect(allow_final_grade_override).to be true
          end

          it "sets allow_final_grade_override to false when final grade override is not allowed" do
            @course.update!(allow_final_grade_override: false)
            get :show, params: { course_id: @course.id }
            expect(allow_final_grade_override).to be false
          end

          it "sets allow_final_grade_override to false when 'Final Grade Override' is not enabled" do
            @course.disable_feature!(:final_grades_override)
            get :show, params: { course_id: @course.id }
            expect(allow_final_grade_override).to be false
          end
        end
      end

      describe "view ungraded as zero" do
        context "when individual gradebook is enabled" do
          before { @teacher.set_preference(:gradebook_version, "srgb") }

          it "save_view_ungraded_as_zero_to_server is true when the feature is enabled" do
            @course.account.enable_feature!(:view_ungraded_as_zero)
            get :show, params: { course_id: @course.id }
            expect(gradebook_options[:save_view_ungraded_as_zero_to_server]).to be true
          end

          it "save_view_ungraded_as_zero_to_server is false when the feature is not enabled" do
            get :show, params: { course_id: @course.id }
            expect(gradebook_options[:save_view_ungraded_as_zero_to_server]).to be false
          end
        end

        context "when default gradebook is enabled" do
          it "sets allow_view_ungraded_as_zero in the ENV to true if the feature is enabled" do
            @course.account.enable_feature!(:view_ungraded_as_zero)
            get :show, params: { course_id: @course.id }
            expect(gradebook_options.fetch(:allow_view_ungraded_as_zero)).to be true
          end

          it "sets allow_view_ungraded_as_zero in the ENV to false if the feature is not enabled" do
            get :show, params: { course_id: @course.id }
            expect(gradebook_options.fetch(:allow_view_ungraded_as_zero)).to be false
          end
        end
      end

      describe "split student names" do
        it "sets allow_separate_first_last_names in the ENV to true if the feature is enabled at the site admin FF is also enabled" do
          Account.site_admin.enable_feature!(:gradebook_show_first_last_names)
          @course.account.settings[:allow_gradebook_show_first_last_names] = true
          @course.account.save!
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:allow_separate_first_last_names)).to be true
        end

        it "sets allow_separate_first_last_names in the ENV to false if the feature is not enabled" do
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:allow_separate_first_last_names)).to be false
        end
      end

      describe "show_message_students_with_observers_dialog" do
        shared_examples_for "environment variable" do
          it "is true when the feature is enabled" do
            Account.site_admin.enable_feature!(:message_observers_of_students_who)
            get :show, params: { course_id: @course.id }
            expect(gradebook_options[:show_message_students_with_observers_dialog]).to be true
          end

          it "is false when the feature is not enabled" do
            get :show, params: { course_id: @course.id }
            expect(gradebook_options[:show_message_students_with_observers_dialog]).to be false
          end
        end

        context "when individual gradebook is enabled" do
          before { @teacher.set_preference(:gradebook_version, "srgb") }

          include_examples "environment variable"
        end

        context "when default gradebook is enabled" do
          include_examples "environment variable"
        end
      end

      describe "grading_standard" do
        it "uses the Canvas default grading standard if the course does not have one" do
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:default_grading_standard)).to eq GradingStandard.default_grading_standard
        end

        it "uses the course's grading standard" do
          grading_standard = grading_standard_for(@course)
          @course.update!(grading_standard:)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:grading_standard)).to eq grading_standard.data
          expect(gradebook_options.fetch(:grading_standard_points_based)).to be false
          expect(gradebook_options.fetch(:grading_standard_scaling_factor)).to eq 1.0
        end

        it "uses the course's grading standard points_based value when feature flag is on" do
          grading_standard = grading_standard_for(@course)
          grading_standard.points_based = true
          grading_standard.scaling_factor = 4.0
          grading_standard.save
          @course.update!(grading_standard:)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:grading_standard)).to eq grading_standard.data
          expect(gradebook_options.fetch(:grading_standard_points_based)).to be true
          expect(gradebook_options.fetch(:grading_standard_scaling_factor)).to eq 4.0
        end

        it "grading_standard is false if the course does not have one" do
          get :show, params: { course_id: @course.id }
          expect(gradebook_options.fetch(:grading_standard)).to be false
        end
      end

      it "includes colors" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :colors
      end

      it "user set colors overwrites standard grading status colors when the feature is enabled" do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        @teacher.set_preference(:gradebook_settings, "colors", { "late" => "#EEEEEE" })
        StandardGradeStatus.new(root_account: @course.root_account, status_name: "late", color: "#000000").save!
        StandardGradeStatus.new(root_account: @course.root_account, status_name: "missing", color: "#FFFFFF").save!
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:colors]).to eql({ "late" => "#EEEEEE", "missing" => "#FFFFFF" })
      end

      it "includes standard grading status colors when the feature is enabled" do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        StandardGradeStatus.new(root_account: @course.root_account, status_name: "late", color: "#000000").save!
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:colors]).to eql({ "late" => "#000000" })
      end

      it "does not include standard grading status colors when the feature is disabled" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        @teacher.set_preference(:gradebook_settings, "colors", { "late" => "#EEEEEE" })
        StandardGradeStatus.new(root_account: @course.root_account, status_name: "missing", color: "#000000").save!
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:colors]).to eql({ "late" => "#EEEEEE" })
      end

      it "includes custom_grade_statuses_enabled as true when feature is enabled" do
        Account.site_admin.enable_feature!(:custom_gradebook_statuses)
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:custom_grade_statuses_enabled]).to be true
      end

      it "includes custom_grade_statuses_enabled as false when feature is disabled" do
        Account.site_admin.disable_feature!(:custom_gradebook_statuses)
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:custom_grade_statuses_enabled]).to be false
      end

      it "includes final_grade_override_enabled" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :final_grade_override_enabled
      end

      it "includes late_policy" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :late_policy
      end

      it "includes message_attachment_upload_folder_id" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :message_attachment_upload_folder_id
      end

      it "includes grading_schemes" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options).to have_key :grading_schemes
      end

      it "sets show_similarity_score to true when the New Gradebook Plagiarism Indicator feature flag is enabled" do
        @course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator)
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:show_similarity_score]).to be(true)
      end

      it "sets show_similarity_score to false when the New Gradebook Plagiarism Indicator feature flag is not enabled" do
        get :show, params: { course_id: @course.id }
        expect(gradebook_options[:show_similarity_score]).to be(false)
      end

      describe "performance_controls" do
        let(:performance_controls) { assigns[:js_env][:GRADEBOOK_OPTIONS][:performance_controls] }

        it "defaults active_request_limit to 12" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:active_request_limit]).to eq(12)
        end

        it "includes api_max_per_page" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:api_max_per_page]).to eq(100)
        end

        it "defaults assignment_groups_per_page to the api_max_per_page setting" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:assignment_groups_per_page]).to eq(100)
        end

        it "defaults context_modules_per_page to the api_max_per_page setting" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:context_modules_per_page]).to eq(100)
        end

        it "defaults custom_column_data_per_page to the api_max_per_page setting" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:custom_column_data_per_page]).to eq(100)
        end

        it "defaults custom_columns_per_page to the api_max_per_page setting" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:custom_columns_per_page]).to eq(100)
        end

        it "defaults students_chunk_size to the api_max_per_page setting" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:students_chunk_size]).to eq(100)
        end

        it "defaults submissions_chunk_size to 10" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:submissions_chunk_size]).to eq(10)
        end

        it "defaults submissions_per_page to the api_max_per_page setting" do
          get :show, params: { course_id: @course.id }
          expect(performance_controls[:submissions_per_page]).to eq(100)
        end
      end

      describe "post_manually" do
        it "is set to true when the course is manually-posted" do
          @course.default_post_policy.update!(post_manually: true)
          get :show, params: { course_id: @course.id }
          expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:post_manually]).to be true
        end

        it "is set to false when the course is not manually-posted" do
          get :show, params: { course_id: @course.id }
          expect(assigns[:js_env][:GRADEBOOK_OPTIONS][:post_manually]).to be false
        end
      end

      describe "student_groups" do
        let(:category) { @course.group_categories.create!(name: "category") }
        let(:category2) { @course.group_categories.create!(name: "another category") }

        let(:group_categories_json) { assigns[:js_env][:GRADEBOOK_OPTIONS][:student_groups] }

        before do
          category.create_groups(2)
          category2.create_groups(2)
          @groupless_category = @course.group_categories.create!(name: "no groups!")
        end

        it "includes the student group categories for the course" do
          get :show, params: { course_id: @course.id }
          expect(group_categories_json.pluck("id")).to contain_exactly(category.id, category2.id, @groupless_category.id)
        end

        it "does not include deleted group categories" do
          category2.destroy!

          get :show, params: { course_id: @course.id }
          expect(group_categories_json.pluck("id")).to contain_exactly(category.id, @groupless_category.id)
        end

        it "includes the groups within each category" do
          get :show, params: { course_id: @course.id }

          category2_json = group_categories_json.find { |category_json| category_json["id"] == category2.id }
          expect(category2_json["groups"].pluck("id")).to match_array(category2.groups.pluck(:id))
        end

        it "includes an empty groups array for categories without groups" do
          get :show, params: { course_id: @course.id }

          groupless_json = group_categories_json.find { |cat| cat["id"] == @groupless_category.id }
          expect(groupless_json["groups"]).to be_empty
        end
      end

      context "publish_to_sis_enabled" do
        before(:once) do
          @course.sis_source_id = "xyz"
          @course.save
        end

        it "is true when the user is able to sync grades to the course SIS" do
          expect_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(true)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be true
        end

        it "is false when the user is not allowed to publish grades" do
          expect_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(false)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be false
        end

        it "is false when the user is not allowed to manage grades" do
          allow_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(true)
          @course.root_account.role_overrides.create!(
            permission: :manage_grades,
            role: Role.find_by(name: "TeacherEnrollment"),
            enabled: false
          )
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be false
        end

        it "is false when the course is not using a SIS" do
          allow_any_instantiation_of(@course).to receive(:allows_grade_publishing_by).with(@teacher).and_return(true)
          @course.sis_source_id = nil
          @course.save
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:publish_to_sis_enabled]).to be false
        end
      end

      it "includes sis_section_id on the sections even if the teacher doesn't have 'Read SIS Data' permissions" do
        @course.root_account.role_overrides.create!(permission: :read_sis, enabled: false, role: teacher_role)
        get :show, params: { course_id: @course.id }
        section = gradebook_options.fetch(:sections).first
        expect(section).to have_key :sis_section_id
      end

      describe "graded_late_submissions_exist" do
        let(:assignment) do
          @course.assignments.create!(
            due_at: 3.days.ago,
            points_possible: 10,
            submission_types: "online_text_entry"
          )
        end

        let(:graded_late_submissions_exist) do
          gradebook_options.fetch(:graded_late_submissions_exist)
        end

        it "is true if graded late submissions exist" do
          assignment.submit_homework(@student, body: "a body")
          assignment.grade_student(@student, grader: @teacher, grade: 8)
          get :show, params: { course_id: @course.id }
          expect(graded_late_submissions_exist).to be true
        end

        it "is false if late submissions exist, but they are not graded" do
          assignment.submit_homework(@student, body: "a body")
          get :show, params: { course_id: @course.id }
          expect(graded_late_submissions_exist).to be false
        end

        it "is false if there are no late submissions" do
          get :show, params: { course_id: @course.id }
          expect(graded_late_submissions_exist).to be false
        end
      end

      describe "sections" do
        before do
          @course.course_sections.create!
          Enrollment.limit_privileges_to_course_section!(@course, @teacher, true)
        end

        let(:returned_section_ids) { gradebook_options.fetch(:sections).pluck(:id) }

        it "only includes course sections visible to the user" do
          get :show, params: { course_id: @course.id }
          expect(returned_section_ids).to contain_exactly(@course.default_section.id)
        end
      end

      describe "allow_apply_score_to_ungraded" do
        it "is set to true if the feature is enabled on the account" do
          @course.account.enable_feature!(:apply_score_to_ungraded)
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:allow_apply_score_to_ungraded]).to be true
        end

        it "is set to false if the feature is not enabled on the account" do
          get :show, params: { course_id: @course.id }
          expect(gradebook_options[:allow_apply_score_to_ungraded]).to be false
        end
      end

      describe "restrict_quantitative_data" do
        context "when RQD is not enabled" do
          it "returns false when teacher views gradebook" do
            user_session(@teacher)
            get :show, params: { course_id: @course.id }
            expect(gradebook_options.fetch(:restrict_quantitative_data)).to be(false)
          end
        end

        context "when RQD is enabled" do
          before :once do
            # truthy feature flag
            Account.default.enable_feature! :restrict_quantitative_data

            # truthy settings
            Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
            Account.default.save!
            @course.restrict_quantitative_data = true
            @course.save!
          end

          it "returns true when teacher views gradebook" do
            user_session(@teacher)
            get :show, params: { course_id: @course.id }
            expect(gradebook_options.fetch(:restrict_quantitative_data)).to be(true)
          end
        end
      end
    end

    describe "csv" do
      before :once do
        @course.assignments.create(title: "Assignment 1")
        @course.assignments.create(title: "Assignment 2")
      end

      before do
        user_session(@teacher)
      end

      shared_examples_for "working download" do
        it "does not recompute enrollment grades" do
          expect(Enrollment).not_to receive(:recompute_final_score)
          get "show", params: { course_id: @course.id, init: 1, assignments: 1 }, format: "csv"
        end

        it "gets all the expected datas even with multibytes characters" do
          @course.assignments.create(title: "Déjà vu")
          exporter = GradebookExporter.new(
            @course,
            @teacher,
            { include_sis_id: true }
          )
          raw_csv = exporter.to_csv
          expect(raw_csv).to include("Déjà vu")
        end
      end

      context "with teacher that prefers Grid View" do
        before do
          @user.set_preference(:gradebook_version, "2")
        end

        include_examples "working download"
      end

      context "with teacher that prefers Individual View" do
        before do
          @user.set_preference(:gradebook_version, "srgb")
        end

        include_examples "working download"
      end
    end

    context "Individual View" do
      before do
        user_session(@teacher)
      end

      it "redirects to Grid View with a friendly URL" do
        @teacher.set_preference(:gradebook_version, "2")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebook")
      end

      it "redirects to Individual View with a friendly URL" do
        @teacher.set_preference(:gradebook_version, "srgb")
        get "show", params: { course_id: @course.id }
        expect(response).to render_template("gradebooks/individual")
      end
    end

    it "renders the unauthorized page without gradebook authorization" do
      get "show", params: { course_id: @course.id }
      assert_unauthorized
    end

    context "includes data needed by the Gradebook Action menu in ENV" do
      before do
        user_session(@teacher)
        get "show", params: { course_id: @course.id }
        @gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
      end

      it "includes the context_allows_gradebook_uploads key in ENV" do
        actual_value = @gradebook_env[:context_allows_gradebook_uploads]
        expected_value = @course.allows_gradebook_uploads?

        expect(actual_value).to eq(expected_value)
      end

      it "includes the gradebook_import_url key in ENV" do
        actual_value = @gradebook_env[:gradebook_import_url]
        expected_value = new_course_gradebook_upload_path(@course)

        expect(actual_value).to eq(expected_value)
      end
    end

    context "includes student context card info in ENV" do
      before { user_session(@teacher) }

      it "includes context_id" do
        get :show, params: { course_id: @course.id }
        context_id = assigns[:js_env][:GRADEBOOK_OPTIONS][:context_id]
        expect(context_id).to eq @course.id.to_param
      end

      it "is enabled for teachers" do
        get :show, params: { course_id: @course.id }
        expect(assigns[:js_env][:STUDENT_CONTEXT_CARDS_ENABLED]).to be true
      end
    end

    context "includes relevant account settings in ENV" do
      before { user_session(@teacher) }

      let(:custom_login_id) { "FOOBAR" }

      it "includes login_handle_name" do
        @course.account.update!(login_handle_name: custom_login_id)
        get :show, params: { course_id: @course.id }

        login_handle_name = assigns[:js_env][:GRADEBOOK_OPTIONS][:login_handle_name]

        expect(login_handle_name).to eq(custom_login_id)
      end
    end

    context "with grading periods" do
      let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
      let(:period_helper) { Factories::GradingPeriodHelper.new }

      before :once do
        @grading_period_group = group_helper.create_for_account(@course.root_account)
        term = @course.enrollment_term
        term.grading_period_group = @grading_period_group
        term.save!
        @grading_periods = period_helper.create_presets_for_group(@grading_period_group, :past, :current, :future)
      end

      before { user_session(@teacher) }

      it "includes the grading period group (as 'set') in the ENV" do
        get :show, params: { course_id: @course.id }
        grading_period_set = assigns[:js_env][:GRADEBOOK_OPTIONS][:grading_period_set]
        expect(grading_period_set[:id]).to eq @grading_period_group.id
      end

      it "includes grading periods within the group" do
        get :show, params: { course_id: @course.id }
        grading_period_set = assigns[:js_env][:GRADEBOOK_OPTIONS][:grading_period_set]
        expect(grading_period_set[:grading_periods].count).to eq 3
        period = grading_period_set[:grading_periods][0]
        expect(period).to have_key(:is_closed)
        expect(period).to have_key(:is_last)
      end

      it "includes necessary keys with each grading period" do
        get :show, params: { course_id: @course.id }
        periods = assigns[:js_env][:GRADEBOOK_OPTIONS][:grading_period_set][:grading_periods]
        expect(periods).to all include(:id, :start_date, :end_date, :close_date, :is_closed, :is_last)
      end
    end

    context "when outcome gradebook is enabled" do
      before :once do
        @course.enable_feature!(:outcome_gradebook)
      end

      before do
        user_session(@teacher)
      end

      def preferred_gradebook_view
        gradebook_preferences = @teacher.get_preference(:gradebook_settings, @course.global_id) || {}
        gradebook_preferences["gradebook_view"]
      end

      def update_preferred_gradebook_view!(gradebook_view)
        @teacher.set_preference(:gradebook_settings, @course.global_id, {
                                  "gradebook_view" => gradebook_view,
                                })
      end

      def update_preferred_gradebook_version!(version)
        @teacher.set_preference(:gradebook_version, version)
        user_session(@teacher)
      end

      context "when the user has no preferred view" do
        it "renders 'gradebook' when no view is requested" do
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/gradebook")
        end

        it "renders 'gradebook' when the user uses default view" do
          update_preferred_gradebook_version!("2")
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/gradebook")
        end

        it "renders 'individual' when the user uses individual view" do
          update_preferred_gradebook_version!("individual")
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/individual")
        end

        it "updates the user's preference when the requested view is 'gradebook'" do
          get "show", params: { course_id: @course.id, view: "gradebook" }
          @teacher.reload
          expect(preferred_gradebook_view).to eql("gradebook")
        end

        it "redirects to the gradebook when the requested view is 'gradebook'" do
          get "show", params: { course_id: @course.id, view: "gradebook" }
          expect(response).to redirect_to(action: "show")
        end

        it "updates the user's preference when the requested view is 'learning_mastery'" do
          get "show", params: { course_id: @course.id, view: "learning_mastery" }
          @teacher.reload
          expect(preferred_gradebook_view).to eql("learning_mastery")
        end

        it "redirects to the gradebook when the requested view is 'learning_mastery'" do
          get "show", params: { course_id: @course.id, view: "learning_mastery" }
          expect(response).to redirect_to(action: "show")
        end

        it "increments inst_statsd when learning mastery gradebook is visited" do
          # The initial show view will redirect to show without the view query param the first time,
          #  and because RSpec doesn't follow redirects well, we stub out a few things to simulate
          #  the redirects
          allow(InstStatsd::Statsd).to receive(:increment)
          allow_any_instance_of(GradebooksController).to receive(:preferred_gradebook_view).and_return("learning_mastery")
          get "show", params: { course_id: @course.id, view: "" }
          expect(InstStatsd::Statsd).to have_received(:increment).with(
            "outcomes_page_views",
            tags: { type: "teacher_lmgb" }
          )
        end
      end

      context "when the user prefers gradebook" do
        before :once do
          update_preferred_gradebook_view!("gradebook")
        end

        it "renders 'gradebook' when no view is requested" do
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/gradebook")
        end

        it "renders 'gradebook' when the user uses default view" do
          update_preferred_gradebook_version!("2")
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/gradebook")
        end

        it "renders 'individual' when the user uses individual view" do
          update_preferred_gradebook_version!("individual")
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/individual")
        end

        it "redirects to the gradebook when requesting the preferred view" do
          get "show", params: { course_id: @course.id, view: "gradebook" }
          expect(response).to redirect_to(action: "show")
        end

        it "updates the user's preference when the requested view is 'learning_mastery'" do
          get "show", params: { course_id: @course.id, view: "learning_mastery" }
          @teacher.reload
          expect(preferred_gradebook_view).to eql("learning_mastery")
        end

        it "redirects to the gradebook when changing the requested view" do
          get "show", params: { course_id: @course.id, view: "learning_mastery" }
          expect(response).to redirect_to(action: "show")
        end
      end

      context "when the user prefers learning mastery" do
        before do
          update_preferred_gradebook_view!("learning_mastery")
        end

        it "renders 'learning_mastery' when no view is requested" do
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/learning_mastery")
        end

        it "renders 'learning_mastery' when the user uses default view" do
          update_preferred_gradebook_version!("2")
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/learning_mastery")
        end

        it "renders 'individual' when the user uses individual view" do
          update_preferred_gradebook_version!("individual")
          get "show", params: { course_id: @course.id }
          expect(response).to render_template("gradebooks/individual")
        end

        it "redirects to the gradebook when requesting the preferred view" do
          get "show", params: { course_id: @course.id, view: "learning_mastery" }
          expect(response).to redirect_to(action: "show")
        end

        it "updates the user's preference when the requested view is 'gradebook'" do
          get "show", params: { course_id: @course.id, view: "gradebook" }
          @teacher.reload
          expect(preferred_gradebook_view).to eql("gradebook")
        end

        it "redirects to the gradebook when changing the requested view" do
          get "show", params: { course_id: @course.id, view: "gradebook" }
          expect(response).to redirect_to(action: "show")
        end
      end

      describe "ENV" do
        before do
          update_preferred_gradebook_view!("learning_mastery")
        end

        describe ".outcome_proficiency" do
          before do
            @proficiency = outcome_proficiency_model(@course.account)
            @course.root_account.enable_feature! :non_scoring_rubrics

            get "show", params: { course_id: @course.id }

            @gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
          end

          it "is set to the outcome proficiency on the account" do
            expect(@gradebook_env[:outcome_proficiency]).to eq(@proficiency.as_json)
          end

          describe "with account_level_mastery_scales enabled" do
            before do
              @course_proficiency = outcome_proficiency_model(@course)
              @course.root_account.enable_feature! :account_level_mastery_scales

              get "show", params: { course_id: @course.id }

              @gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
            end

            it "is set to the resolved_outcome_proficiency on the course" do
              expect(@gradebook_env[:outcome_proficiency]).to eq(@course_proficiency.as_json)
            end
          end
        end

        describe ".sections" do
          before do
            @section_2 = @course.course_sections.create!
            teacher_in_section(@section_2, user: @teacher, limit_privileges_to_course_section: true)
          end

          let(:returned_section_ids) { gradebook_options.fetch(:sections).pluck(:id) }

          describe "with the :limit_section_visibility_in_lmgb FF enabled" do
            before do
              @course.root_account.enable_feature!(:limit_section_visibility_in_lmgb)
            end

            it "only includes course sections visible to the user" do
              get :show, params: { course_id: @course.id }
              expect(returned_section_ids).to contain_exactly(@section_2.id)
            end
          end

          describe "with the :limit_section_visibility_in_lmgb FF disabled" do
            it "includes all course sections" do
              get :show, params: { course_id: @course.id }
              expect(returned_section_ids).to match_array([@section_2.id, @course.default_section.id])
            end
          end
        end

        describe "IMPROVED_LMGB" do
          it "is false if the feature flag is off" do
            @course.root_account.disable_feature! :improved_lmgb
            get :show, params: { course_id: @course.id }
            gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
            expect(gradebook_env[:IMPROVED_LMGB]).to be false
          end

          it "is true if the feature flag is on" do
            @course.root_account.enable_feature! :improved_lmgb
            get :show, params: { course_id: @course.id }
            gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
            expect(gradebook_env[:IMPROVED_LMGB]).to be true
          end
        end

        describe "Outcomes Friendly Description" do
          it "is false if the feature flag is off" do
            Account.site_admin.disable_feature! :outcomes_friendly_description
            get :show, params: { course_id: @course.id }
            gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
            expect(gradebook_env[:OUTCOMES_FRIENDLY_DESCRIPTION]).to be false
          end

          it "is true if the feature flag is on" do
            Account.site_admin.enable_feature! :outcomes_friendly_description
            get :show, params: { course_id: @course.id }
            gradebook_env = assigns[:js_env][:GRADEBOOK_OPTIONS]
            expect(gradebook_env[:OUTCOMES_FRIENDLY_DESCRIPTION]).to be true
          end
        end

        describe "outcome_service_results_to_canvas" do
          it "is set to true if outcome_service_results_to_canvas feature flag is enabled" do
            @course.enable_feature!(:outcome_service_results_to_canvas)
            get :show, params: { course_id: @course.id }
            js_env = assigns[:js_env]
            expect(js_env[:outcome_service_results_to_canvas]).to be true
          end

          it "is set to false if outcome_service_results_to_canvas feature flag is disabled" do
            @course.disable_feature!(:outcome_service_results_to_canvas)
            get :show, params: { course_id: @course.id }
            js_env = assigns[:js_env]
            expect(js_env[:outcome_service_results_to_canvas]).to be false
          end
        end

        describe "outcome_average_calculation feature flag" do
          it "is set to true if outcome_average_calculation ff is enabled" do
            @course.root_account.enable_feature!(:outcome_average_calculation)
            get :show, params: { course_id: @course.id }
            js_env = assigns[:js_env]
            expect(js_env[:OUTCOME_AVERAGE_CALCULATION]).to be true
          end

          it "is set to false if outcome_average_calculation ff is disabled" do
            @course.root_account.disable_feature!(:outcome_average_calculation)
            get :show, params: { course_id: @course.id }
            js_env = assigns[:js_env]
            expect(js_env[:OUTCOME_AVERAGE_CALCULATION]).to be false
          end
        end
      end
    end
  end

  describe "GET 'final_grade_overrides'" do
    it "returns unauthorized when there is no current user" do
      get :final_grade_overrides, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "returns unauthorized when the user is not authorized to manage grades" do
      user_session(@student)
      get :final_grade_overrides, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "grants authorization to teachers in active courses" do
      user_session(@teacher)
      get :final_grade_overrides, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)
      get :final_grade_overrides, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "returns the map of final grade overrides" do
      assignment = assignment_model(course: @course, points_possible: 10)
      assignment.grade_student(@student, grade: "85%", grader: @teacher)
      enrollment = @student.enrollments.find_by!(course: @course)
      enrollment.scores.find_by!(course_score: true).update!(override_score: 89.2)

      user_session(@teacher)
      get :final_grade_overrides, params: { course_id: @course.id }, format: :json
      final_grade_overrides = json_parse(response.body)["final_grade_overrides"]
      expect(final_grade_overrides).to have_key(@student.id.to_s)
    end
  end

  describe "GET 'user_ids'" do
    it "returns unauthorized if there is no current user" do
      get :user_ids, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "returns unauthorized if the user is not authorized to manage grades" do
      user_session(@student)
      get :user_ids, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "grants authorization to teachers in active courses" do
      user_session(@teacher)
      get :user_ids, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)
      get :user_ids, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "returns an array of user ids sorted according to the user's preferences" do
      student1 = @student
      student1.update!(name: "Jon")
      student2 = student_in_course(active_all: true, name: "Ron").user
      student3 = student_in_course(active_all: true, name: "Don").user
      @teacher.set_preference(:gradebook_settings, @course.global_id, {
                                sort_rows_by_column_id: "student",
                                sort_rows_by_setting_key: "name",
                                sort_rows_by_direction: "descending"
                              })

      user_session(@teacher)
      get :user_ids, params: { course_id: @course.id }, format: :json
      user_ids = json_parse(response.body)["user_ids"]
      expect(user_ids).to eq([student2.id, student1.id, student3.id])
    end
  end

  describe "GET 'grading_period_assignments'" do
    before(:once) do
      @group = Factories::GradingPeriodGroupHelper.new.create_for_account(@course.account)
      @group.enrollment_terms << @course.enrollment_term
      @period1, @period2 = Factories::GradingPeriodHelper.new.create_presets_for_group(@group, :past, :current)
      @assignment1_in_gp1 = @course.assignments.create!(due_at: 3.months.ago)
      @assignment2_in_gp2 = @course.assignments.create!(due_at: 1.day.from_now)
      @assignment_not_in_gp = @course.assignments.create!(due_at: 9.months.from_now)
    end

    it "returns unauthorized if there is no current user" do
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "returns unauthorized if the user is not authorized to manage grades" do
      user_session(@student)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      assert_status(401)
    end

    it "grants authorization to teachers in active courses" do
      user_session(@teacher)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      expect(response).to be_ok
    end

    it "returns an array of user ids sorted according to the user's preferences" do
      user_session(@teacher)
      get :grading_period_assignments, params: { course_id: @course.id }, format: :json
      json = json_parse(response.body)["grading_period_assignments"]
      expect(json).to eq({
                           @period1.id.to_s => [@assignment1_in_gp1.id.to_s],
                           @period2.id.to_s => [@assignment2_in_gp2.id.to_s],
                           "none" => [@assignment_not_in_gp.id.to_s]
                         })
    end
  end

  describe "GET 'change_gradebook_version'" do
    it "switches to gradebook if clicked" do
      user_session(@teacher)
      get "grade_summary", params: { course_id: @course.id, id: nil }

      expect(response).to redirect_to(action: "show")

      # tell it to use gradebook 2
      get "change_gradebook_version", params: { course_id: @course.id, version: 2 }
      expect(response).to redirect_to(action: "show")
    end
  end

  describe "GET 'history'" do
    it "grants authorization to teachers in active courses" do
      user_session(@teacher)

      get "history", params: { course_id: @course.id }
      expect(response).to be_ok
    end

    it "grants authorization to teachers in concluded courses" do
      @course.complete!
      user_session(@teacher)

      get "history", params: { course_id: @course.id }
      expect(response).to be_ok
    end

    it "returns unauthorized for students" do
      user_session(@student)

      get "history", params: { course_id: @course.id }
      assert_unauthorized
    end

    describe "js_env" do
      before { user_session(@teacher) }

      describe "OVERRIDE_GRADES_ENABLED" do
        let(:override_grades_enabled) { assigns[:js_env][:OVERRIDE_GRADES_ENABLED] }

        it "is set to true if the final_grade_override flag is enabled and the course setting is on" do
          @course.enable_feature!(:final_grades_override)
          @course.allow_final_grade_override = true
          @course.save!

          get "history", params: { course_id: @course.id }
          expect(override_grades_enabled).to be true
        end

        it "is set to false if the final_grade_override flag is disabled" do
          @course.allow_final_grade_override = true
          @course.save!

          get "history", params: { course_id: @course.id }
          expect(override_grades_enabled).to be false
        end

        it "is set to false if the course setting is off" do
          @course.enable_feature!(:final_grades_override)

          get "history", params: { course_id: @course.id }
          expect(override_grades_enabled).to be false
        end
      end

      describe "COURSE_URL" do
        it "is set to the context url for the current course" do
          get "history", params: { course_id: @course.id }
          expect(assigns[:js_env][:COURSE_URL]).to eq "/courses/#{@course.id}"
        end
      end

      describe "OUTCOME_GRADEBOOK_ENABLED" do
        it "is set to true if outcome_gradebook is enabled for the course" do
          @course.enable_feature!(:outcome_gradebook)
          get "history", params: { course_id: @course.id }
          expect(assigns[:js_env][:OUTCOME_GRADEBOOK_ENABLED]).to be true
        end

        it "is set to false if outcome_gradebook is not enabled for the course" do
          get "history", params: { course_id: @course.id }
          expect(assigns[:js_env][:OUTCOME_GRADEBOOK_ENABLED]).to be false
        end
      end
    end
  end

  describe "POST 'submissions_zip_upload'" do
    before(:once) do
      @course = course_factory(active_all: true)
      @assignment = assignment_model(course: @course)
    end

    let(:zip_params) do
      {
        assignment_id: @assignment.id,
        course_id: @course.id,
        submissions_zip: fixture_file_upload("docs/txt.txt", "text/plain", true)
      }
    end

    it "requires authentication" do
      post "submissions_zip_upload", params: zip_params
      assert_unauthorized
    end

    context "with an authenticated user" do
      before do
        user_session(@teacher)
      end

      it "redirects to the assignment page if the course does not allow score uploads" do
        @course.update!(large_roster: true)
        post "submissions_zip_upload", params: zip_params
        expect(response).to redirect_to(course_assignment_url(@course, @assignment))
        expect(flash[:error]).to eq "This course does not allow score uploads."
      end

      it "redirects to the assignment page if the submissions_zip param is invalid (and no attachment_id param)" do
        post "submissions_zip_upload", params: zip_params.merge(submissions_zip: "an invalid zip")
        expect(response).to redirect_to(course_assignment_url(@course, @assignment))
        expect(flash[:error]).to eq "Could not find file to upload."
      end

      it "redirects to the submission upload page" do
        post "submissions_zip_upload", params: zip_params
        expect(response).to redirect_to(show_submissions_upload_course_gradebook_url(@course, @assignment))
      end

      it "accepts an attachment_id param in place of a submissions_zip param" do
        attachment = @teacher.attachments.create!(uploaded_data: zip_params[:submissions_zip])
        post "submissions_zip_upload", params: zip_params.merge(attachment_id: attachment.id).except(:submissions_zip)
        expect(response).to redirect_to(show_submissions_upload_course_gradebook_url(@course, @assignment))
      end
    end
  end

  describe "GET 'show_submissions_upload'" do
    before :once do
      course_factory
      assignment_model
    end

    before do
      user_session(@teacher)
    end

    it "assigns the @assignment variable for the template" do
      get :show_submissions_upload, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(assigns[:assignment]).to eql(@assignment)
    end

    it "redirects to the assignment page when the course does not allow gradebook uploads" do
      allow_any_instance_of(Course).to receive(:allows_gradebook_uploads?).and_return(false)
      get :show_submissions_upload, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to redirect_to course_assignment_url(@course, @assignment)
    end

    it "requires authentication" do
      remove_user_session
      get :show_submissions_upload, params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_unauthorized
    end

    it "grants authorization to teachers" do
      get :show_submissions_upload, params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_ok
    end

    it "returns unauthorized for students" do
      user_session(@student)
      get :show_submissions_upload, params: { course_id: @course.id, assignment_id: @assignment.id }
      assert_unauthorized
    end
  end

  describe "POST 'update_submission'" do
    let(:json) { response.parsed_body }

    describe "returned JSON" do
      before(:once) do
        @assignment = @course.assignments.create!(title: "Math 1.1")
        @submission = @assignment.submissions.find_by!(user: @student)
      end

      describe "non-anonymous assignment" do
        before do
          user_session(@teacher)
          post(
            "update_submission",
            params: {
              course_id: @course.id,
              submission: {
                assignment_id: @assignment.id,
                user_id: @student.id,
                grade: 10
              }
            },
            format: :json
          )
        end

        it "includes assignment_visibility" do
          submissions = json.pluck("submission")
          expect(submissions).to all include("assignment_visible" => true)
        end

        it "includes missing in base submission object" do
          submission = json.first["submission"]
          expect(submission).to include("missing" => false)
        end

        it "includes missing in submission history" do
          submission_history = json.first["submission"]["submission_history"]
          submissions = submission_history.pluck("submission")
          expect(submissions).to all include("missing" => false)
        end

        it "includes late in base submission object" do
          submission = json.first["submission"]
          expect(submission).to include("late" => false)
        end

        it "includes late in submission history" do
          submission_history = json.first["submission"]["submission_history"]
          submissions = submission_history.pluck("submission")
          expect(submissions).to all include("late" => false)
        end

        it "includes user_ids" do
          submissions = json.pluck("submission")
          expect(submissions).to all include("user_id")
        end
      end

      describe "set default grade" do
        before do
          user_session(@teacher)
        end

        context "setting grades" do
          let(:post_params) do
            {
              course_id: @course.id,
              submission: {
                assignment_id: @assignment.id,
                user_id: @student.id,
                grade: 10,
                set_by_default_grade: true
              }
            }
          end

          it "does not set the grader_id on missing submissions if set_by_default_grade is true" do
            @assignment.update!(due_at: 10.days.ago, submission_types: "online_text_entry")

            expect { post(:update_submission, params: post_params, format: :json) }.not_to change {
              @submission.reload.grader_id
            }.from(nil)
          end

          it "sets the grader_id on missing submissions if set_by_default_grade is false" do
            post_params[:submission][:set_by_default_grade] = false
            @assignment.update!(due_at: 10.days.ago, submission_types: "online_text_entry")

            expect { post(:update_submission, params: post_params, format: :json) }.to change {
              @submission.reload.grader_id
            }.from(nil).to(@teacher.id)
          end

          it "sets the grader_id on missing submissions when set_by_default_grade is true and the late policy status is missing" do
            @assignment.update!(due_at: 10.days.ago, submission_types: "online_text_entry")
            @submission.update!(late_policy_status: "missing")

            expect { post(:update_submission, params: post_params, format: :json) }.to change {
              @submission.reload.grader_id
            }.from(nil).to(@teacher.id)
          end

          it "sets the grader_id on non missing submissions when set_by_default_grade is true" do
            @assignment.update!(due_at: 10.days.from_now, submission_types: "online_text_entry")

            expect { post(:update_submission, params: post_params, format: :json) }.to change {
              @submission.reload.grader_id
            }.from(nil).to(@teacher.id)
          end
        end

        context "marking students as missing" do
          let(:post_params) do
            {
              course_id: @course.id,
              submission: {
                assignment_id: @assignment.id,
                user_id: @student.id,
                late_policy_status: "missing",
                set_by_default_grade: true
              }
            }
          end

          it "marks not-yet-graded students as missing" do
            expect { post(:update_submission, params: post_params, format: :json) }.to change {
              @submission.reload.missing?
            }.from(false).to(true)
          end

          it "marks already-graded students as missing" do
            @assignment.grade_student(@student, grade: 2, grader: @teacher)
            expect { post(:update_submission, params: post_params, format: :json) }.to change {
              @submission.reload.missing?
            }.from(false).to(true)
          end

          it "marks not-yet-graded students as missing when passed dont_overwrite_grades param" do
            params = post_params.merge(dont_overwrite_grades: true)
            expect { post(:update_submission, params:, format: :json) }.to change {
              @submission.reload.missing?
            }.from(false).to(true)
          end

          it "does not modify already-graded students when passed dont_overwrite_grades param" do
            @assignment.grade_student(@student, grade: 2, grader: @teacher)
            params = post_params.merge(dont_overwrite_grades: true)
            expect { post(:update_submission, params:, format: :json) }.not_to change {
              @submission.reload.missing?
            }.from(false)
          end
        end
      end

      describe "anonymous assignment" do
        before(:once) do
          @assignment.update!(anonymous_grading: true)
        end

        let(:post_params) do
          {
            course_id: @course.id,
            submission: {
              assignment_id: @assignment.id,
              anonymous_id: @submission.anonymous_id,
              grade: 10
            }
          }
        end

        before { user_session(@teacher) }

        it "works with the absence of user_id and the presence of anonymous_id" do
          post(:update_submission, params: post_params, format: :json)
          submissions = json.map { |submission| submission.fetch("submission").fetch("anonymous_id") }
          expect(submissions).to contain_exactly(@submission.anonymous_id)
        end

        it "does not include user_ids for muted anonymous assignments" do
          post(:update_submission, params: post_params, format: :json)
          submissions = json.map { |submission| submission["submission"].key?("user_id") }
          expect(submissions).to contain_exactly(false)
        end

        it "includes user_ids for unmuted anonymous assignments" do
          @assignment.unmute!
          post(:update_submission, params: post_params, format: :json)
          submission = json.first.fetch("submission")
          expect(submission).to have_key("user_id")
        end

        context "given a student comment" do
          before(:once) { @submission.add_comment(comment: "a student comment", author: @student) }

          it "includes anonymous_ids on submission_comments" do
            params_with_comment = post_params.deep_merge(submission: { score: 10 })
            post(:update_submission, params: params_with_comment, format: :json)
            comments = json.first.fetch("submission").fetch("submission_comments").pluck("submission_comment")
            expect(comments).to all have_key("anonymous_id")
          end

          it "excludes author_name on submission_comments" do
            params_with_comment = post_params.deep_merge(submission: { score: 10 })
            post(:update_submission, params: params_with_comment, format: :json)
            comments = json.first.fetch("submission").fetch("submission_comments").pluck("submission_comment")
            comments.each do |comment|
              expect(comment).not_to have_key("author_name")
            end
          end
        end
      end
    end

    describe "adding comments" do
      before do
        user_session(@teacher)
        @assignment = @course.assignments.create!(title: "some assignment")
        @student = @course.enroll_user(User.create!(name: "some user"))
      end

      it "allows adding comments for submission" do
        post "update_submission", params: { course_id: @course.id, submission: { comment: "some comment", assignment_id: @assignment.id, user_id: @student.user_id } }
        expect(response).to be_redirect
        expect(assigns[:assignment]).to eql(@assignment)
        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions].length).to be(1)
        expect(assigns[:submissions][0].submission_comments).not_to be_nil
        expect(assigns[:submissions][0].submission_comments[0].comment).to eql("some comment")
      end

      it "allows attaching files to comments for submission" do
        data = fixture_file_upload("docs/doc.doc", "application/msword", true)
        post "update_submission",
             params: { course_id: @course.id,
                       attachments: { "0" => { uploaded_data: data } },
                       submission: { comment: "some comment",
                                     assignment_id: @assignment.id,
                                     user_id: @student.user_id } }
        expect(response).to be_redirect
        expect(assigns[:assignment]).to eql(@assignment)
        expect(assigns[:submissions]).not_to be_nil
        expect(assigns[:submissions].length).to be(1)
        expect(assigns[:submissions][0].submission_comments).not_to be_nil
        expect(assigns[:submissions][0].submission_comments[0].comment).to eql("some comment")
        expect(assigns[:submissions][0].submission_comments[0].attachments.length).to be(1)
        expect(assigns[:submissions][0].submission_comments[0].attachments[0].display_name).to eql("doc.doc")
      end

      it "sets comment to hidden when assignment posts manually and is unposted" do
        @assignment.ensure_post_policy(post_manually: true)
        @assignment.hide_submissions
        post "update_submission", params: {
          course_id: @course.id,
          submission: {
            comment: "some comment",
            assignment_id: @assignment.id,
            user_id: @student.user_id
          }
        }
        expect(assigns[:submissions][0].submission_comments[0]).to be_hidden
      end

      it "does not set comment to hidden when assignment posts manually and submission is posted" do
        @assignment.ensure_post_policy(post_manually: true)
        @assignment.post_submissions
        post "update_submission", params: {
          course_id: @course.id,
          submission: {
            comment: "some comment",
            assignment_id: @assignment.id,
            user_id: @student.user_id
          }
        }
        expect(assigns[:submissions][0].submission_comments[0]).not_to be_hidden
      end

      it "does not set comment to hidden when assignment posts automatically" do
        @assignment.ensure_post_policy(post_manually: false)
        post "update_submission", params: {
          course_id: @course.id,
          submission: {
            comment: "some comment",
            assignment_id: @assignment.id,
            user_id: @student.user_id
          }
        }
        expect(assigns[:submissions][0].submission_comments[0]).not_to be_hidden
      end

      context "media comments" do
        before do
          post "update_submission",
               params: {
                 course_id: @course.id,
                 submission: {
                   assignment_id: @assignment.id,
                   user_id: @student.user_id,
                   media_comment_id: "asdfqwerty",
                   media_comment_type: "audio"
                 }
               }
          @media_comment = assigns[:submissions][0].submission_comments[0]
        end

        it "allows media comments for submissions" do
          expect(@media_comment).not_to be_nil
          expect(@media_comment.media_comment_id).to eql "asdfqwerty"
        end

        it "includes the type in the media comment" do
          expect(@media_comment.media_comment_type).to eql "audio"
        end
      end
    end

    it "stores attached files in instfs if instfs is enabled" do
      uuid = "1234-abcd"
      allow(InstFS).to receive_messages(enabled?: true, direct_upload: uuid)
      user_session(@teacher)
      @assignment = @course.assignments.create!(title: "some assignment")
      @student = @course.enroll_user(User.create!(name: "some user"))
      data = fixture_file_upload("docs/doc.doc", "application/msword", true)
      post "update_submission",
           params: { course_id: @course.id,
                     attachments: { "0" => { uploaded_data: data } },
                     submission: { comment: "some comment",
                                   assignment_id: @assignment.id,
                                   user_id: @student.user_id } }
      expect(assigns[:submissions][0].submission_comments[0].attachments[0].instfs_uuid).to eql(uuid)
    end

    it "does not allow updating submissions for concluded courses" do
      user_session(@teacher)
      @teacher_enrollment.complete
      @assignment = @course.assignments.create!(title: "some assignment")
      @student = @course.enroll_user(User.create!(name: "some user"))
      post "update_submission",
           params: { course_id: @course.id,
                     submission: { comment: "some comment",
                                   assignment_id: @assignment.id,
                                   user_id: @student.user_id } }
      assert_unauthorized
    end

    it "does not allow updating submissions in other sections when limited" do
      user_session(@teacher)
      @teacher_enrollment.update_attribute(:limit_privileges_to_course_section, true)
      s1 = submission_model(course: @course)
      s2 = submission_model(course: @course,
                            username: "otherstudent@example.com",
                            section: @course.course_sections.create(name: "another section"),
                            assignment: @assignment)

      post "update_submission",
           params: { course_id: @course.id,
                     submission: { comment: "some comment",
                                   assignment_id: @assignment.id,
                                   user_id: s1.user_id } }
      expect(response).to be_redirect

      # attempt to grade another section throws not found
      post "update_submission",
           params: { course_id: @course.id,
                     submission: { comment: "some comment",
                                   assignment_id: @assignment.id,
                                   user_id: s2.user_id } }
      expect(flash[:error]).to eql "Submission was unsuccessful: Submission Failed"
    end

    context "moderated grading" do
      before :once do
        @assignment = @course.assignments.create!(title: "some assignment", moderated_grading: true, grader_count: 1)
        @student = @course.enroll_student(User.create!(name: "some user"), enrollment_state: :active).user
      end

      before do
        user_session(@teacher)
      end

      it "creates a provisional grade" do
        submission = @assignment.submit_homework(@student, body: "hello")
        post "update_submission",
             params: { course_id: @course.id,
                       submission: { score: 100,
                                     comment: "provisional!",
                                     assignment_id: @assignment.id,
                                     user_id: @student.id,
                                     provisional: true } },
             format: :json

        # confirm "real" grades/comments were not written
        submission.reload
        expect(submission.workflow_state).to eq "submitted"
        expect(submission.score).to be_nil
        expect(submission.grade).to be_nil
        expect(submission.submission_comments.first).to be_nil

        # confirm "provisional" grades/comments were written
        pg = submission.provisional_grade(@teacher)
        expect(pg.score).to eq 100
        expect(pg.submission_comments.first.comment).to eq "provisional!"

        # confirm the response JSON shows provisional information
        json = response.parsed_body
        expect(json.first.fetch("submission").fetch("score")).to eq 100
        expect(json.first.fetch("submission").fetch("grade_matches_current_submission")).to be true
        expect(json.first.fetch("submission").fetch("submission_comments").first.fetch("submission_comment").fetch("comment")).to eq "provisional!"
      end

      context "when submitting a final provisional grade" do
        before(:once) do
          @assignment.update!(final_grader: @teacher)
        end

        let(:provisional_grade_params) do
          {
            course_id: @course.id,
            submission: {
              score: 66,
              comment: "not the end",
              assignment_id: @assignment.id,
              user_id: @student.id,
              provisional: true
            }
          }
        end

        let(:final_provisional_grade_params) do
          {
            course_id: @course.id,
            submission: {
              score: 77,
              comment: "THE END",
              assignment_id: @assignment.id,
              user_id: @student.id,
              final: true,
              provisional: true
            }
          }
        end

        let(:submission_json) do
          response_json = response.parsed_body
          response_json[0]["submission"].with_indifferent_access
        end

        before do
          post "update_submission", params: provisional_grade_params, format: :json
          post "update_submission", params: final_provisional_grade_params, format: :json
        end

        it "returns the submitted score in the submission JSON" do
          expect(submission_json.fetch("score")).to eq 77
        end

        it "returns the submitted comments in the submission JSON" do
          all_comments = submission_json.fetch("submission_comments")
                                        .map { |c| c.fetch("submission_comment") }
                                        .map { |c| c.fetch("comment") }
          expect(all_comments).to contain_exactly("not the end", "THE END")
        end

        it "returns the value for grade_matches_current_submission of the submitted grade in the JSON" do
          expect(submission_json["grade_matches_current_submission"]).to be true
        end
      end

      it "includes the graded anonymously flag in the provisional grade object" do
        submission = @assignment.submit_homework(@student, body: "hello")
        post "update_submission",
             params: { course_id: @course.id,
                       submission: { score: 100,
                                     comment: "provisional!",
                                     assignment_id: @assignment.id,
                                     user_id: @student.id,
                                     provisional: true,
                                     graded_anonymously: true } },
             format: :json

        submission.reload
        pg = submission.provisional_grade(@teacher)
        expect(pg.graded_anonymously).to be true

        submission = @assignment.submit_homework(@student, body: "hello")
        post "update_submission",
             params: { course_id: @course.id,
                       submission: { score: 100,
                                     comment: "provisional!",
                                     assignment_id: @assignment.id,
                                     user_id: @student.id,
                                     provisional: true,
                                     graded_anonymously: false } },
             format: :json

        submission.reload
        pg = submission.provisional_grade(@teacher)
        expect(pg.graded_anonymously).to be false
      end

      it "doesn't create a provisional grade when the student has one already" do
        @assignment.submit_homework(@student, body: "hello")
        other_teacher = teacher_in_course(course: @course, active_all: true).user
        @assignment.grade_student(@student, grade: 2, grader: other_teacher, provisional: true)

        post "update_submission",
             params: { course_id: @course.id,
                       submission: { score: 100,
                                     comment: "provisional!",
                                     assignment_id: @assignment.id,
                                     user_id: @student.id,
                                     provisional: true } },
             format: :json
        expect(response).to_not be_successful
        expect(response.body).to include("The maximum number of graders has been reached for this assignment")
      end

      it "creates a provisional grade even if the student has one but is in the moderation set" do
        submission = @assignment.submit_homework(@student, body: "hello")
        other_teacher = teacher_in_course(course: @course, active_all: true).user
        submission.find_or_create_provisional_grade!(other_teacher)

        post "update_submission",
             params: { course_id: @course.id,
                       submission: { score: 100,
                                     comment: "provisional!",
                                     assignment_id: @assignment.id,
                                     user_id: @student.id,
                                     provisional: true } },
             format: :json
        expect(response).to be_successful
      end

      it "creates a final provisional grade" do
        @assignment.update!(final_grader: @teacher)
        submission = @assignment.submit_homework(@student, body: "hello")
        other_teacher = teacher_in_course(course: @course, active_all: true).user
        submission.find_or_create_provisional_grade!(other_teacher) # create one so we can make a final

        post "update_submission",
             params: { course_id: @course.id,
                       submission: { score: 100,
                                     comment: "provisional!",
                                     assignment_id: @assignment.id,
                                     user_id: @student.id,
                                     provisional: true,
                                     final: true } },
             format: :json
        expect(response).to be_successful

        # confirm "real" grades/comments were not written
        submission.reload
        expect(submission.workflow_state).to eq "submitted"
        expect(submission.score).to be_nil
        expect(submission.grade).to be_nil
        expect(submission.submission_comments.first).to be_nil

        # confirm "provisional" grades/comments were written
        pg = submission.provisional_grade(@teacher, final: true)
        expect(pg.score).to eq 100
        expect(pg.final).to be true
        expect(pg.submission_comments.first.comment).to eq "provisional!"

        # confirm the response JSON shows provisional information
        json = response.parsed_body
        expect(json[0]["submission"]["score"]).to eq 100
        expect(json[0]["submission"]["provisional_grade_id"]).to eq pg.id
        expect(json[0]["submission"]["grade_matches_current_submission"]).to be true
        expect(json[0]["submission"]["submission_comments"].first["submission_comment"]["comment"]).to eq "provisional!"
      end

      it "does not mark the provisional grade as final when the user does not have permission to moderate" do
        submission = @assignment.submit_homework(@student, body: "hello")
        other_teacher = teacher_in_course(course: @course, active_all: true).user
        submission.find_or_create_provisional_grade!(other_teacher)
        post_params = {
          course_id: @course.id,
          submission: {
            score: 100.to_s,
            comment: "provisional comment",
            assignment_id: @assignment.id.to_s,
            user_id: @student.id.to_s,
            provisional: true,
            final: true
          }
        }

        post(:update_submission, params: post_params, format: :json)
        submission_json = response.parsed_body.first.fetch("submission")
        provisional_grade = ModeratedGrading::ProvisionalGrade.find(submission_json.fetch("provisional_grade_id"))
        expect(provisional_grade).not_to be_final
      end
    end

    describe "provisional grade error handling" do
      before(:once) do
        course_with_student(active_all: true)
        teacher_in_course(active_all: true)

        @assignment = @course.assignments.create!(
          title: "yet another assignment",
          moderated_grading: true,
          grader_count: 1
        )
      end

      let(:submission_params) do
        { provisional: true, assignment_id: @assignment.id, user_id: @student.id, score: 1 }
      end
      let(:request_params) { { course_id: @course.id, submission: submission_params } }

      let(:response_json) { response.parsed_body }

      it "returns an error code of MAX_GRADERS_REACHED if a MaxGradersReachedError is raised" do
        @assignment.grade_student(@student, provisional: true, grade: 5, grader: @teacher)
        @previous_teacher = @teacher

        teacher_in_course(active_all: true)
        user_session(@teacher)

        post "update_submission", params: request_params, format: :json
        expect(response_json.dig("errors", "error_code")).to eq "MAX_GRADERS_REACHED"
      end

      it "returns a generic error if a GradeError is raised" do
        invalid_submission_params = submission_params.merge(excused: true)
        invalid_request_params = request_params.merge(submission: invalid_submission_params)
        user_session(@teacher)

        post "update_submission", params: invalid_request_params, format: :json
        expect(response_json.dig("errors", "base")).to be_present
      end

      it "returns a PROVISIONAL_GRADE_INVALID_SCORE error code if an invalid grade is given" do
        invalid_submission_params = submission_params.merge(grade: "NaN")
        invalid_request_params = request_params.merge(submission: invalid_submission_params)
        user_session(@teacher)

        post "update_submission", params: invalid_request_params, format: :json
        expect(response_json.dig("errors", "error_code")).to eq "PROVISIONAL_GRADE_INVALID_SCORE"
      end
    end

    describe "checkpointed discussions" do
      before do
        @course.root_account.enable_feature!(:discussion_checkpoints)
        assignment = @course.assignments.create!(has_sub_assignments: true)
        assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC, due_at: 2.days.from_now)
        assignment.sub_assignments.create!(context: @course, sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY, due_at: 3.days.from_now)
        @topic = @course.discussion_topics.create!(assignment:, reply_to_entry_required_count: 1)
      end

      let(:post_params) do
        {
          course_id: @course.id,
          submission: {
            assignment_id: @topic.assignment_id,
            user_id: @student.id,
            grade: 10
          }
        }
      end

      let(:reply_to_topic_submission) do
        @topic.reply_to_topic_checkpoint.submissions.find_by(user: @student)
      end

      it "supports grading checkpoints" do
        user_session(@teacher)
        post(
          "update_submission",
          params: post_params.merge(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC),
          format: :json
        )
        expect(response).to be_successful
        expect(reply_to_topic_submission.score).to eq 10
      end

      it "raises an error if no sub assignment tag is provided" do
        user_session(@teacher)
        post(
          "update_submission",
          params: post_params,
          format: :json
        )
        expect(response).to have_http_status :bad_request
        expect(json_parse.dig("errors", "base")).to eq "Must provide a valid sub assignment tag when grading checkpointed discussions"
      end

      it "ignores checkpoints when the feature flag is disabled" do
        @course.root_account.disable_feature!(:discussion_checkpoints)
        user_session(@teacher)
        post(
          "update_submission",
          params: post_params.merge(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC),
          format: :json
        )
        expect(response).to be_successful
        expect(reply_to_topic_submission.score).to be_nil
        expect(@topic.assignment.submissions.find_by(user: @student).score).to eq 10
      end
    end
  end

  describe "GET 'speed_grader'" do
    before :once do
      @assignment = @course.assignments.create!(
        title: "A Title", submission_types: "online_url", grading_type: "percent"
      )
    end

    before do
      user_session(@teacher)
    end

    it "renders speed_grader template with locals" do
      @assignment.publish
      get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
      expect(response).to render_template(:speed_grader, locals: { anonymous_grading: false })
    end

    it "redirects the user if course's large_roster? setting is true" do
      allow_any_instance_of(Course).to receive(:large_roster?).and_return(true)

      get "speed_grader", params: { course_id: @course.id, assignment_id: @assignment.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to eq "SpeedGrader is disabled for this course"
    end

    it "redirects if the assignment is unpublished" do
      @assignment.unpublish
      get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to eq I18n.t(
        :speedgrader_enabled_only_for_published_content, "SpeedGrader is enabled only for published content."
      )
    end

    it "does not redirect if the assignment is published" do
      @assignment.publish
      get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
      expect(response).not_to be_redirect
    end

    it "loads the platform speedgreader when the feature flag is on and the platform_sg flag is passed" do
      @assignment.publish
      Account.site_admin.enable_feature!(:platform_service_speedgrader)
      get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id, platform_sg: true }
      expect(response).to render_template(:bare, locals: { anonymous_grading: false })
    end

    describe "js_env" do
      let(:js_env) { assigns[:js_env] }

      it "includes lti_retrieve_url" do
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
        expect(js_env[:lti_retrieve_url]).not_to be_nil
      end

      it "includes the grading_type" do
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
        expect(js_env[:grading_type]).to eq("percent")
      end

      it "includes instructor selectable states keyed by provisional_grade_id" do
        @assignment.update!(moderated_grading: true, grader_count: 2)
        @assignment.create_moderation_grader(@teacher, occupy_slot: true)
        submission = @assignment.submissions.first
        provisional_grade = submission.find_or_create_provisional_grade!(@teacher, score: 1)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:instructor_selectable_states]).to have_key provisional_grade.id
      end

      it "includes anonymous identities keyed by anonymous_id" do
        @assignment.update!(moderated_grading: true, grader_count: 2)
        anonymous_id = @assignment.create_moderation_grader(@teacher, occupy_slot: true).anonymous_id
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:anonymous_identities]).to have_key anonymous_id
      end

      it "sets can_view_audit_trail to true when the current user can view the assignment audit trail" do
        @course.root_account.role_overrides.create!(permission: :view_audit_trail, enabled: true, role: teacher_role)
        @assignment.update!(moderated_grading: true, grader_count: 2, grades_published_at: 2.days.ago)
        @assignment.update!(muted: false) # must be updated separately for some reason
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:can_view_audit_trail]).to be true
      end

      it "sets can_view_audit_trail to false when the current user cannot view the assignment audit trail" do
        @assignment.update!(moderated_grading: true, grader_count: 2, muted: true)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:can_view_audit_trail]).to be false
      end

      it "includes MANAGE_GRADES" do
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:MANAGE_GRADES)).to be true
      end

      it "includes READ_AS_ADMIN" do
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:READ_AS_ADMIN)).to be true
      end

      it "includes final_grader_id" do
        @assignment.update!(final_grader: @teacher, grader_count: 2, moderated_grading: true)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env[:final_grader_id]).to eql @teacher.id
      end

      it "sets filter_speed_grader_by_student_group_feature_enabled to true when enabled" do
        @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:filter_speed_grader_by_student_group_feature_enabled)).to be true
      end

      it "sets filter_speed_grader_by_student_group_feature_enabled to false when disabled" do
        @course.root_account.disable_feature!(:filter_speed_grader_by_student_group)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:filter_speed_grader_by_student_group_feature_enabled)).to be false
      end

      it "sets show_comment_library to true when enabled" do
        @course.root_account.enable_feature!(:assignment_comment_library)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:assignment_comment_library_feature_enabled)).to be true
      end

      it "sets show_comment_library to false when disabled" do
        @course.root_account.disable_feature!(:assignment_comment_library)
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:assignment_comment_library_feature_enabled)).to be false
      end

      it "sets outcomes keys" do
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
        expect(js_env).to have_key :outcome_proficiency
        expect(js_env).to have_key :outcome_extra_credit_enabled
      end

      it "sets media_comment_asset_string" do
        get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
        expect(js_env.fetch(:media_comment_asset_string)).to eq @teacher.asset_string
      end

      describe "student group filtering" do
        before do
          @course.root_account.enable_feature!(:filter_speed_grader_by_student_group)

          group_category.create_groups(2)
          group1.add_user(@student)
        end

        let(:group_category) { @course.group_categories.create!(name: "a group category") }
        let(:group1) { group_category.groups.first }

        context "when the SpeedGrader student group filter is enabled for the course" do
          before do
            @course.update!(filter_speed_grader_by_student_group: true)
          end

          it "sets filter_speed_grader_by_student_group to true" do
            get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
            expect(js_env[:filter_speed_grader_by_student_group]).to be true
          end

          context "when loading a student causes a new group to be selected" do
            it "updates the viewing user's preferences for the course with the new group" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: @student }
              @teacher.reload

              saved_group_id = @teacher.get_preference(:gradebook_settings, @course.global_id).dig("filter_rows_by", "student_group_id")
              expect(saved_group_id).to eq group1.id.to_s
            end

            it "sets selected_student_group to the group's JSON representation" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: @student }
              expect(js_env.dig(:selected_student_group, "id")).to eq group1.id
            end

            it "sets student_group_reason_for_change to the supplied change reason" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: @student }
              expect(js_env[:student_group_reason_for_change]).to eq :no_group_selected
            end
          end

          context "when the selected group stays the same" do
            before do
              @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_id" => group1.id } })
            end

            it "sets selected_student_group to the selected group's JSON representation" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: @student }
              expect(js_env.dig(:selected_student_group, "id")).to eq group1.id
            end

            it "does not set a value for student_group_reason_for_change" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: @student }
              expect(js_env).not_to include(:student_group_reason_for_change)
            end
          end

          context "when the selected group is cleared due to loading a student not in any group" do
            let(:groupless_student) { @course.enroll_student(User.create!, enrollment_state: :active).user }

            before do
              @teacher.set_preference(:gradebook_settings, @course.global_id, { "filter_rows_by" => { "student_group_id" => group1.id } })
            end

            it "clears the selected group from the viewing user's preferences for the course" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: groupless_student }
              @teacher.reload

              saved_group_id = @teacher.get_preference(:gradebook_settings, @course.global_id).dig("filter_rows_by", "student_group_id")
              expect(saved_group_id).to be_nil
            end

            it "does not set selected_student_group" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: groupless_student }
              expect(js_env).not_to include(:selected_student_group)
            end

            it "sets student_group_reason_for_change to the supplied change reason" do
              get :speed_grader, params: { course_id: @course, assignment_id: @assignment, student_id: groupless_student }
              expect(js_env[:student_group_reason_for_change]).to eq :student_in_no_groups
            end
          end
        end

        context "when the SpeedGrader student group filter is not enabled for the course" do
          it "does not set filter_speed_grader_by_student_group" do
            get :speed_grader, params: { course_id: @course, assignment_id: @assignment }
            expect(js_env).not_to include(:filter_speed_grader_by_student_group)
          end
        end
      end
    end

    describe "current_anonymous_id" do
      before do
        user_session(@teacher)
      end

      context "for a moderated assignment" do
        let(:moderated_assignment) do
          @course.assignments.create!(
            moderated_grading: true,
            grader_count: 1,
            final_grader: @teacher
          )
        end

        it "is set to the anonymous ID for the viewing grader if grader identities are concealed" do
          moderated_assignment.update!(grader_names_visible_to_final_grader: false)
          moderated_assignment.moderation_graders.create!(user: @teacher, anonymous_id: "zxcvb")

          get "speed_grader", params: { course_id: @course, assignment_id: moderated_assignment }
          expect(assigns[:js_env][:current_anonymous_id]).to eq "zxcvb"
        end

        it "is not set if grader identities are visible" do
          get "speed_grader", params: { course_id: @course, assignment_id: moderated_assignment }
          expect(assigns[:js_env]).not_to include(:current_anonymous_id)
        end

        it "is not set if grader identities are concealed but grades are published" do
          moderated_assignment.update!(
            grader_names_visible_to_final_grader: false,
            grades_published_at: Time.zone.now
          )
          get "speed_grader", params: { course_id: @course, assignment_id: moderated_assignment }
          expect(assigns[:js_env]).not_to include(:current_anonymous_id)
        end
      end

      it "is not set if the assignment is not moderated" do
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment }
        expect(assigns[:js_env]).not_to include(:current_anonymous_id)
      end
    end

    describe "new_gradebook_plagiarism_icons_enabled" do
      it "is set to true if New Gradebook Plagiarism Icons are on" do
        @course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator)
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment }
        expect(assigns[:js_env][:new_gradebook_plagiarism_icons_enabled]).to be true
      end

      it "is not set if the New Gradebook Plagiarism Icons are off" do
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment }
        expect(assigns[:js_env]).not_to include(:new_gradebook_plagiarism_icons_enabled)
      end
    end

    describe "reassignment" do
      it "allows teacher reassignment" do
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
        expect(controller.instance_variable_get(:@can_reassign_submissions)).to be true
      end

      it "does not allow student reassignment" do
        user_session(@student)
        get "speed_grader", params: { course_id: @course, assignment_id: @assignment.id }
        expect(controller.instance_variable_get(:@can_reassign_submissions)).to be_nil
      end

      context "with moderated grading" do
        before(:once) do
          @mod_assignment = @course.assignments.create!(
            title: "some assignment", moderated_grading: true, grader_count: 1
          )
          course_with_ta(course: @course)
          @mod_assignment.update!(final_grader: @teacher)
        end

        it "does not allow non-final grader to reassign" do
          user_session(@ta)
          get "speed_grader", params: { course_id: @course, assignment_id: @mod_assignment.id }
          expect(controller.instance_variable_get(:@can_reassign_submissions)).to be false
        end

        it "allows final grader to reassign" do
          user_session(@teacher)
          get "speed_grader", params: { course_id: @course, assignment_id: @mod_assignment.id }
          expect(controller.instance_variable_get(:@can_reassign_submissions)).to be true
        end
      end
    end
  end

  describe "POST 'speed_grader_settings'" do
    it "lets you set your :enable_speedgrader_grade_by_question preference" do
      user_session(@teacher)
      expect(@teacher.preferences[:enable_speedgrader_grade_by_question]).not_to be_truthy

      post "speed_grader_settings", params: { course_id: @course.id,
                                              enable_speedgrader_grade_by_question: "1" }
      expect(@teacher.reload.preferences[:enable_speedgrader_grade_by_question]).to be_truthy

      post "speed_grader_settings", params: { course_id: @course.id,
                                              enable_speedgrader_grade_by_question: "0" }
      expect(@teacher.reload.preferences[:enable_speedgrader_grade_by_question]).not_to be_truthy
    end

    describe "selected_section_id preference" do
      let(:course_settings) { @teacher.reload.get_preference(:gradebook_settings, @course.global_id) }

      before do
        user_session(@teacher)
      end

      it "sets the selected section for the course to the passed-in value" do
        section_id = @course.course_sections.first.id
        post "speed_grader_settings", params: { course_id: @course.id, selected_section_id: section_id }

        expect(course_settings.dig("filter_rows_by", "section_id")).to eq section_id.to_s
      end

      it "ensures that selected_view_options_filters includes 'sections' if a section is selected" do
        section_id = @course.course_sections.first.id
        post "speed_grader_settings", params: { course_id: @course.id, selected_section_id: section_id }

        expect(course_settings["selected_view_options_filters"]).to include("sections")
      end

      context "when a section has previously been selected" do
        before do
          @teacher.set_preference(:gradebook_settings,
                                  @course.global_id,
                                  { filter_rows_by: { section_id: @course.course_sections.first.id } })
        end

        it 'clears the selected section for the course if passed the value "all"' do
          post "speed_grader_settings", params: { course_id: @course.id, selected_section_id: "all" }

          expect(course_settings.dig("filter_rows_by", "section_id")).to be_nil
        end

        it "clears the selected section if passed an invalid value" do
          post "speed_grader_settings", params: { course_id: @course.id, selected_section_id: "hahahaha" }

          expect(course_settings.dig("filter_rows_by", "section_id")).to be_nil
        end

        it "clears the selected section if passed a non-active section in the course" do
          deleted_section = @course.course_sections.create!
          deleted_section.destroy!

          post "speed_grader_settings", params: { course_id: @course.id, selected_section_id: deleted_section.id }

          expect(course_settings.dig("filter_rows_by", "section_id")).to be_nil
        end

        it "clears the selected section if passed a section ID not in the course" do
          section_in_other_course = Course.create!.course_sections.create!
          post "speed_grader_settings", params: { course_id: @course.id, selected_section_id: section_in_other_course.id }

          expect(course_settings.dig("filter_rows_by", "section_id")).to be_nil
        end
      end
    end
  end

  describe "POST 'save_assignment_order'" do
    it "saves the sort order in the user's preferences" do
      user_session(@teacher)
      post "save_assignment_order", params: { course_id: @course.id, assignment_order: "due_at" }
      saved_order = @teacher.get_preference(:course_grades_assignment_order, @course.id)
      expect(saved_order).to eq(:due_at)
    end
  end

  describe "#light_weight_ags_json" do
    it "returns the necessary JSON for GradeCalculator" do
      ag = @course.assignment_groups.create! group_weight: 100
      a  = ag.assignments.create! submission_types: "online_upload",
                                  points_possible: 10,
                                  context: @course,
                                  omit_from_final_grade: true
      AssignmentGroup.add_never_drop_assignment(ag, a)
      @controller.instance_variable_set(:@context, @course)
      @controller.instance_variable_set(:@current_user, @user)
      @controller.instance_variable_set(:@presenter, @controller.send(:grade_summary_presenter))
      expect(@controller.light_weight_ags_json([ag])).to eq [
        {
          id: ag.id,
          rules: {
            "never_drop" => [
              a.id.to_s
            ]
          },
          group_weight: 100,
          assignments: [
            {
              due_at: nil,
              id: a.id,
              points_possible: 10,
              submission_types: ["online_upload"],
              omit_from_final_grade: true,
              muted: true
            }
          ],
        },
      ]
    end

    it "does not return unpublished assignments" do
      course_with_student
      ag = @course.assignment_groups.create! group_weight: 100
      a1 = ag.assignments.create! submission_types: "online_upload",
                                  points_possible: 10,
                                  context: @course
      a2 = ag.assignments.build submission_types: "online_upload",
                                points_possible: 10,
                                context: @course
      a2.workflow_state = "unpublished"
      a2.save!

      @controller.instance_variable_set(:@context, @course)
      @controller.instance_variable_set(:@current_user, @user)
      @controller.instance_variable_set(:@presenter, @controller.send(:grade_summary_presenter))
      expect(@controller.light_weight_ags_json([ag])).to eq [
        {
          id: ag.id,
          rules: {},
          group_weight: 100,
          assignments: [
            {
              id: a1.id,
              due_at: nil,
              points_possible: 10,
              submission_types: ["online_upload"],
              omit_from_final_grade: false,
              muted: true
            }
          ],
        },
      ]
    end
  end

  describe "#external_tool_detail" do
    let(:tool) do
      {
        definition_id: 123,
        name: "test lti",
        placements: {
          post_grades: {
            canvas_launch_url: "http://example.com/lti/post_grades",
            launch_width: 100,
            launch_height: 100
          }
        }
      }
    end

    it "maps a tool to launch details" do
      expect(@controller.external_tool_detail(tool)).to eql(
        id: 123,
        data_url: "http://example.com/lti/post_grades",
        name: "test lti",
        type: :lti,
        data_width: 100,
        data_height: 100
      )
    end
  end

  describe "#post_grades_ltis" do
    it "maps #external_tools with #external_tool_detail" do
      expect(@controller).to receive(:external_tools).and_return([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
      expect(@controller).to receive(:external_tool_detail).exactly(10).times

      @controller.post_grades_ltis
    end

    it "memoizes" do
      expect(@controller).to receive(:external_tools).and_return([]).once

      expect(@controller.post_grades_ltis).to eq(@controller.post_grades_ltis)
    end
  end

  describe "#post_grades_feature?" do
    it "returns false when :post_grades feature disabled for context" do
      context = object_double(@course, feature_enabled?: false)
      @controller.instance_variable_set(:@context, context)

      expect(@controller.post_grades_feature?).to be(false)
    end

    it "returns false when context does not allow grade publishing by user" do
      context = object_double(@course, feature_enabled?: true, allows_grade_publishing_by: false)
      @controller.instance_variable_set(:@context, context)

      expect(@controller.post_grades_feature?).to be(false)
    end

    it "returns false when #can_do is false" do
      context = object_double(@course, feature_enabled?: true, allows_grade_publishing_by: true)
      @controller.instance_variable_set(:@context, context)
      allow(@controller).to receive(:can_do).and_return(false)

      expect(@controller.post_grades_feature?).to be(false)
    end

    it "returns true when all conditions are met" do
      context = object_double(@course, feature_enabled?: true, allows_grade_publishing_by: true)
      @controller.instance_variable_set(:@context, context)
      allow(@controller).to receive(:can_do).and_return(true)

      expect(@controller.post_grades_feature?).to be(true)
    end
  end

  describe "#grading_rubrics" do
    context "sharding" do
      specs_require_sharding

      it "fetches rubrics from a cross-shard course" do
        user_session(@teacher)
        @shard1.activate do
          a = Account.create!
          @cs_course = Course.create!(name: "cs_course", account: a)
          @rubric = Rubric.create!(context: @cs_course, title: "testing")
          RubricAssociation.create!(context: @cs_course, rubric: @rubric, purpose: :bookmark, association_object: @cs_course)
          @cs_course.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")
        end

        get "grading_rubrics", params: { course_id: @course, context_code: @cs_course.asset_string }
        json = json_parse(response.body)
        expect(json.first["rubric_association"]["rubric_id"]).to eq @rubric.global_id.to_s
        expect(json.first["rubric_association"]["context_code"]).to eq @cs_course.global_asset_string
      end
    end

    context "access control" do
      it "allows users with the appropriate permissions to view rubrics" do
        user_session(@teacher)

        get "grading_rubrics", params: { course_id: @course }
        expect(response).to be_successful
      end

      it "allows admins to view rubrics" do
        user_session(account_admin_user)

        get "grading_rubrics", params: { course_id: @course }
        expect(response).to be_successful
      end

      it "forbids viewing if the user lacks appropriate permissions" do
        user_session(@student)

        get "grading_rubrics", params: { course_id: @course }
        expect(response).to be_unauthorized
      end

      it "requires a logged-in user" do
        get "grading_rubrics", params: { course_id: @course }

        expect(response).to redirect_to(login_url)
      end
    end
  end

  describe "PUT 'update_final_grade_overrides'" do
    let(:override_score_updates) do
      [
        { student_id: @student.id, override_score: 10.0 }
      ]
    end

    let(:update_params) { { course_id: @course.id, override_scores: override_score_updates } }

    before do
      user_session(@teacher)

      @course.enable_feature!(:final_grades_override)
      @course.allow_final_grade_override = true
      @course.save!
    end

    it "returns unauthorized when there is no current user" do
      remove_user_session
      put :update_final_grade_overrides, params: update_params, format: :json
      assert_unauthorized
    end

    it "returns unauthorized when the user is not authorized to manage grades" do
      user_session(@student)
      put :update_final_grade_overrides, params: update_params, format: :json
      assert_unauthorized
    end

    it "returns unauthorized when the course does not allow final grade override" do
      @course.allow_final_grade_override = false
      @course.save!

      put :update_final_grade_overrides, params: update_params, format: :json
      assert_unauthorized
    end

    it "grants authorization to teachers in active courses" do
      put :update_final_grade_overrides, params: update_params, format: :json
      expect(response).to be_ok
    end

    it "returns unauthorized when the course is concluded" do
      @course.complete!
      put :update_final_grade_overrides, params: update_params, format: :json
      assert_unauthorized
    end

    it "returns an error when the override_scores param is not supplied" do
      put :update_final_grade_overrides, params: update_params.slice(:course_id), format: :json
      assert_status(400)
    end

    describe "grading periods" do
      let(:group_helper)  { Factories::GradingPeriodGroupHelper.new }
      let(:period_helper) { Factories::GradingPeriodHelper.new }

      it "accepts grading periods that are used by the course" do
        grading_period = period_helper.create_with_group_for_account(@course.account)
        @course.enrollment_term.update!(grading_period_group: grading_period.grading_period_group)

        put :update_final_grade_overrides, params: update_params.merge({ grading_period_id: grading_period.id })
        expect(response).to be_ok
      end

      it "returns a 400 for grading periods that are not used by the course" do
        other_period = period_helper.create_with_group_for_account(@course.account)

        put :update_final_grade_overrides, params: update_params.merge({ grading_period_id: other_period.id })

        aggregate_failures do
          assert_status(400)
          expect(json_parse["error"]).to eq "invalid_grading_period"
        end
      end
    end

    it "returns a progress object" do
      put :update_final_grade_overrides, params: update_params, format: :json

      returned_id = json_parse["id"]
      progress = Progress.find(returned_id)

      aggregate_failures do
        expect(progress).not_to be_nil
        expect(progress.tag).to eq "override_grade_update"
      end
    end
  end

  describe "PUT 'apply_score_to_ungraded_submissions'" do
    before do
      @course.account.enable_feature!(:apply_score_to_ungraded)
      user_session(@teacher)
    end

    let(:other_course) do
      other_course = Course.create!(account: @course.account)
      other_course.enroll_teacher(@teacher, enrollment_state: "active")
      other_course
    end

    def make_request(**additional_params)
      params = additional_params.reverse_merge({ course_id: @course.id, assignment_ids: ["1", "2"], student_ids: ["11", "22"] })
      put :apply_score_to_ungraded_submissions, params:, format: :json
      response.parsed_body
    end

    describe "authorization" do
      it "rejects requests if the caller does not have the manage_grades permission" do
        user_session(@student)
        make_request(percent: 50.0)
        assert_unauthorized
      end

      it "rejects requests if the account does not have the apply_score_to_ungraded feature enabled" do
        @course.account.disable_feature!(:apply_score_to_ungraded)
        make_request(percent: 50.0)
        assert_unauthorized
      end
    end

    describe "grade values" do
      it "accepts a percent value" do
        make_request(percent: 50.0)
        expect(response).to be_successful
      end

      it "accepts a true value for excused" do
        make_request(excused: true)
        expect(response).to be_successful
      end

      it "does not accept both a percent and a true value for excused" do
        json = make_request(excused: true, percent: 50.0)
        expect(json["error"]).to eq "cannot_both_score_and_excuse"
      end

      it "requires either a percent value or a true value for excused" do
        json = make_request
        expect(json["error"]).to eq "no_score_or_excused_provided"
      end

      it "does not accept empty assignment ids" do
        put :apply_score_to_ungraded_submissions, params: { course_id: @course.id, percent: 95.0, assignment_ids: [], student_ids: ["11", "22"] }, format: :json
        expect(response.parsed_body["error"]).to eq "no_assignment_ids_provided"
      end

      it "does not accept empty student ids" do
        put :apply_score_to_ungraded_submissions, params: { course_id: @course.id, percent: 95.0, assignment_ids: ["1", "2"], student_ids: [] }, format: :json
        expect(response.parsed_body["error"]).to eq "no_student_ids_provided"
      end
    end
  end
end
