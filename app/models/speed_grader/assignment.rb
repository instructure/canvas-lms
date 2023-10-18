# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module SpeedGrader
  class Assignment
    include GradebookSettingsHelpers
    include CoursesHelper
    include Api::V1::SubmissionComment
    include CanvadocsHelper
    include Rails.application.routes.url_helpers

    def initialize(assignment, current_user, avatars: false, grading_role: :grader)
      @assignment = assignment
      @avatars = avatars
      @current_user = current_user
      @grading_role = grading_role
    end

    def json
      Attachment.skip_thumbnails = true
      submission_json_fields = %i[
        id
        submitted_at
        workflow_state
        grade
        grade_matches_current_submission
        graded_at
        turnitin_data
        submission_type
        score
        points_deducted
        assignment_id
        submission_comments
        grading_period_id
        excused
        updated_at
        attempt
        posted_at
        resource_link_lookup_uuid
        redo_request
        cached_due_date
      ]

      submission_json_fields <<
        (
          if anonymous_students?(current_user:, assignment:)
            :anonymous_id
          else
            :user_id
          end
        )

      submission_json_fields <<
        (
          if Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
            :custom_grade_status_id
          end
        )

      attachment_json_fields = %i[
        id
        comment_id
        content_type
        context_id
        context_type
        display_name
        filename
        mime_class
        size
        submitter_id
        workflow_state
      ]

      if !assignment.anonymize_students? || course.account_membership_allows(current_user)
        attachment_json_fields << :viewed_at
      end

      enrollment_json_fields = %i[course_section_id workflow_state user_id]

      res =
        assignment.as_json(
          include: [{ context: { only: :id } }, :rubric_association],
          include_root: false
        )

      res["context"]["concluded"] = assignment.context.concluded?
      res["anonymize_students"] = assignment.anonymize_students?
      res["anonymize_graders"] = !assignment.can_view_other_grader_identities?(current_user)
      res["post_manually"] = assignment.post_manually?

      # include :provisional here someday if we need to distinguish
      # between provisional and real comments (also in
      # SubmissionComment#serialization_methods)
      submission_comment_methods = []
      submission_comment_methods << :avatar_path if display_avatars?

      res[:context][:rep_for_student] = {}

      includes = gradebook_includes(user: current_user, course:)
      students =
        assignment.representatives(
          user: current_user,
          includes:,
          group_id: group_id_filter,
          section_id: section_id_filter,
          ignore_student_visibility: true
        ) { |rep, others| others.each { |s| res[:context][:rep_for_student][s.id] = rep.id } }

      unless assignment.anonymize_students?
        # Ensure that any test students are sorted last
        students = students.sort_by { |r| (r.preferences[:fake_student] == true) ? 1 : 0 }
      end

      enrollments =
        course.apply_enrollment_visibility(
          gradebook_enrollment_scope(user: current_user, course:),
          current_user,
          nil,
          include: includes
        )

      current_user_rubric_assessments =
        assignment.visible_rubric_assessments_for(
          current_user,
          provisional_grader: provisional_grader_or_moderator?
        ) || []

      # include all the rubric assessments if a moderator
      all_provisional_rubric_assessments =
        if grading_role == :moderator
          assignment.visible_rubric_assessments_for(current_user, provisional_moderator: true)
        else
          []
        end

      if provisional_grader_or_moderator?
        ActiveRecord::Associations.preload(assignment, :moderated_grading_selections)
      end

      includes = [
        { versions: :versionable },
        :quiz_submission,
        :user,
        :attachment_associations,
        :assignment,
        :originality_reports
      ]
      includes << {
        all_submission_comments: {
          submission: {
            assignment: {
              context: :root_account
            }
          }
        }
      }
      submissions = assignment.submissions.where(user_id: students).preload(*includes)

      student_json_fields =
        if anonymous_students?(current_user:, assignment:)
          []
        else
          %i[name id sortable_name]
        end

      res[:context][:students] =
        students.map do |student|
          json =
            student.as_json(
              include_root: false,
              methods: submission_comment_methods,
              only: student_json_fields
            )
          if anonymous_students?(current_user:, assignment:)
            anonymous_ids =
              student_ids_to_anonymous_ids(
                current_user:,
                assignment:,
                course:,
                submissions:
              )
            json[:anonymous_id] = anonymous_ids[student.id.to_s]
            identity = assignment.anonymous_student_identities.fetch(student.id, {})
            json[:anonymous_name] = identity[:name]
            json[:anonymous_name_position] = identity[:position]
          end
          if provisional_grader_or_moderator?
            json[:needs_provisional_grade] =
              assignment.can_be_moderated_grader?(current_user)
          end
          json[:rubric_assessments] =
            rubric_assessments_to_json(
              rubric_assessments:
                current_user_rubric_assessments.select do |assessment|
                  assessment.user_id == student.id
                end,
              submissions:
            )
          json[:fake_student] = !!student.preferences[:fake_student]
          json
        end

      res[:context][:active_course_sections] =
        assignment
        .context
        .sections_visible_to(current_user, assignment.sections_with_visibility(current_user))
        .map { |section| section.as_json(include_root: false, only: %i[id name]) }

      res[:context][:enrollments] =
        enrollments.map do |enrollment|
          enrollment_json = enrollment.as_json(include_root: false, only: enrollment_json_fields)
          if anonymous_students?(current_user:, assignment:)
            enrollment_json[:anonymous_id] =
              student_ids_to_anonymous_ids(
                current_user:,
                assignment:,
                course:,
                submissions:
              ).fetch(enrollment.user_id.to_s, nil)
            enrollment_json.delete(:user_id)
          end
          enrollment_json
        end
      res[:context][:quiz] =
        assignment.quiz.as_json(include_root: false, only: [:anonymous_submissions])

      attachment_includes = %i[crocodoc_document canvadoc root_attachment]

      # Preload attachments for later looping
      attachments_for_submission =
        ::Submission.bulk_load_attachments_for_submissions(
          submissions,
          preloads: attachment_includes
        )

      # Preloading submission history versioned attachments and originality reports
      submission_histories = submissions.map(&:submission_history).flatten
      ::Submission.bulk_load_versioned_attachments(
        submission_histories,
        preloads: attachment_includes
      )
      ::Submission.bulk_load_versioned_originality_reports(submission_histories)

      preloaded_provisional_selections =
        if grading_role == :moderator
          assignment.moderated_grading_selections.index_by(&:student_id)
        else
          {}
        end

      res[:too_many_quiz_submissions] = too_many = assignment.too_many_qs_versions?(submissions)
      qs_versions = assignment.quiz_submission_versions(submissions, too_many)

      enrollment_types_by_id = enrollments.each_with_object({}) { |e, h| h[e.user_id] ||= e.type }

      if assignment.quiz
        if assignment.quiz.assignment_overrides.to_a.count(&:active?) == 0
          assignment.quiz.has_no_overrides = true
        else
          assignment.quiz.context.preload_user_roles!
        end
      end

      res[:submissions] =
        submissions.map do |sub|
          submission_methods = %i[
            submission_history
            late
            external_tool_url
            entered_score
            entered_grade
            seconds_late
            missing
            late_policy_status
            word_count
          ]
          json =
            sub
            .as_json(
              include_root: false,
              methods: submission_methods,
              only: submission_json_fields
            )
            .merge("from_enrollment_type" => enrollment_types_by_id[sub.user_id])

          if provisional_grader_or_moderator?
            provisional_grade =
              sub.provisional_grade(current_user, preloaded_grades: preloaded_provisional_grades)
            json.merge! provisional_grade_to_json(provisional_grade)
          end

          json[:has_postable_comments] =
            sub.all_submission_comments.any?(&:allows_posting_submission?)

          json[:submission_comments] =
            anonymous_moderated_submission_comments_json(
              assignment:,
              course:,
              current_user:,
              avatars: display_avatars?,
              submission_comments: sub.visible_submission_comments_for(current_user),
              submissions:
            )

          json[:proxy_submitter] = sub.proxy_submitter&.short_name
          json[:proxy_submitter_id] = sub.proxy_submitter_id

          # We get the attachments this way to avoid loading the
          # attachments again via the submission method that creates a
          # new query.
          json["attachments"] =
            attachments_for_submission[sub].map do |att|
              att.as_json(only: %i[mime_class comment_id id submitter_id])
            end

          sub_attachments = []
          url_opts = {
            anonymous_instructor_annotations: assignment.anonymous_instructor_annotations,
            enable_annotations:
              !provisional_grader_or_moderator? ||
              assignment.can_be_moderated_grader?(current_user),
            moderated_grading_allow_list:
              sub.moderated_grading_allow_list(
                current_user,
                loaded_attachments: attachments_for_submission[sub]
              ),
            submission_id: sub.id
          }

          if url_opts[:enable_annotations]
            url_opts[:disable_annotation_notifications] = assignment.post_manually? && !sub.posted?
            url_opts[:enrollment_type] = canvadocs_user_role(course, current_user)
          end

          if quizzes_next_submission?
            quiz_lti_submission = BasicLTI::QuizzesNextVersionedSubmission.new(assignment, sub.user)
            json["submission_history"] =
              quiz_lti_submission.grade_history.map { |submission| { submission: } }
          elsif json["submission_history"] && (assignment.quiz.nil? || too_many)
            json["submission_history"] =
              json["submission_history"].map do |version|
                # to avoid a call to the DB in Submission#missing?
                version.assignment = sub.assignment
                version_methods = %i[
                  versioned_attachments
                  late
                  missing
                  external_tool_url
                  late_policy_status
                  word_count
                ]
                version
                  .as_json(only: submission_json_fields, methods: version_methods)
                  .tap do |version_json|
                    version_json["submission"]["has_originality_report"] =
                      version.has_originality_report?
                    version_json["submission"]["has_plagiarism_tool"] =
                      version.assignment.assignment_configuration_tool_lookup_ids.present?
                    version_json["submission"]["has_originality_score"] =
                      version.originality_reports_for_display.any? do |o|
                        o.originality_score.present?
                      end
                    version_json["submission"]["turnitin_data"].merge!(version.originality_data)
                    version_json["submission"]["proxy_submitter"] =
                      version.proxy_submitter&.short_name
                    version_json["submission"]["proxy_submitter_id"] = version.proxy_submitter_id

                    # Fill in the parent's anonymous ID if this version was serialized
                    # without it
                    if assignment.anonymize_students? &&
                       version_json["submission"]["anonymous_id"].blank?
                      version_json["submission"]["anonymous_id"] = sub.anonymous_id
                    end

                    if version_json["submission"][:submission_type] == "discussion_topic"
                      url_opts[:enable_annotations] = false
                    end
                    if version_json["submission"] &&
                       version_json["submission"]["versioned_attachments"]
                      version_json["submission"]["versioned_attachments"].map! do |a|
                        if version_json["submission"][:submission_type] == "discussion_topic"
                          url_opts[:enable_annotations] = false
                        end
                        if grading_role == :moderator
                          # we'll use to create custom crocodoc urls for each prov grade
                          sub_attachments << a
                        end
                        a
                          .as_json(only: attachment_json_fields)
                          .tap do |attachment_json|
                            attachment_json[:attachment].merge!(
                              {
                                view_inline_ping_url:
                                  assignment_file_inline_view_path(assignment.id, a.id),
                                canvadoc_url: a.canvadoc_url(current_user, url_opts),
                                crocodoc_url: a.crocodoc_url(current_user, url_opts),
                                submitted_to_crocodoc: a.crocodoc_document.present?,
                                hijack_crocodoc_session:
                                  a.crocodoc_document.present? && migrate_to_canvadocs?,
                                upload_status: AttachmentUploadStatus.upload_status(a)
                              }
                            )
                            a.set_word_count if a.word_count.nil? && a.word_count_supported?
                            attachment_json[:attachment][:word_count] = a.word_count
                          end
                      end
                    end
                  end
              end
          elsif assignment.quiz && sub.quiz_submission
            json["submission_history"] =
              qs_versions[sub.quiz_submission.id].map do |v|
                # don't use v.model, because these are huge objects, and can be significantly expensive
                # to instantiate an actual AR object deserializing and reserializing the inner YAML
                qs = YAML.safe_load(v.yaml)

                # Returns the id of the Submission, but this may be too ambiguous.
                # In the future, we may want to return both a quiz_id and a
                # submission_id and let clients handle it themselves.
                {
                  submission: {
                    grade: qs["score"],
                    id: sub.id,
                    show_grade_in_dropdown: true,
                    submitted_at: qs["finished_at"],
                    late: Quizzes::QuizSubmission.late_from_attributes?(qs, assignment.quiz, sub),
                    version: v.number
                  }
                }
              end
          end

          if provisional_grader_or_moderator?
            pgs = preloaded_provisional_grades[sub.id] || []
            selection = preloaded_provisional_selections[sub.user.id]
            unless pgs.count == 0 || (pgs.count == 1 && pgs.first.scorer_id == current_user.id)
              json["provisional_grades"] = []
              pgs.each do |pg|
                current_pg_json =
                  provisional_grade_to_json(pg).tap do |pg_json|
                    rubric_assessments =
                      all_provisional_rubric_assessments.select do |assessment|
                        assessment.artifact_id == pg.id
                      end
                    pg_json[:rubric_assessments] =
                      rubric_assessments_to_json(
                        rubric_assessments:,
                        submissions:
                      )
                    pg_json[:selected] =
                      !!(selection && selection.selected_provisional_grade_id == pg.id)

                    # this should really be provisional_doc_view_urls :: https://instructure.atlassian.net/browse/CNVS-38202
                    pg_json[:crocodoc_urls] =
                      sub_attachments.map { |a| pg.attachment_info(current_user, a) }
                    pg_json[:readonly] = !pg.final && (pg.scorer_id != current_user.id)
                  end

                if pg.final
                  json["final_provisional_grade"] = current_pg_json
                else
                  json["provisional_grades"] << current_pg_json
                end
              end
            end
          end

          json
        end

      res[:GROUP_GRADING_MODE] = assignment.grade_as_group?
      res[:quiz_lti] = assignment.quiz_lti?
      StringifyIds.recursively_stringify_ids(res)
    ensure
      Attachment.skip_thumbnails = nil
    end

    def quizzes_next_submission?
      assignment.quiz_lti? &&
        assignment.root_account.feature_enabled?(:quizzes_next_submission_history)
    end

    def preloaded_provisional_grades
      @preloaded_provisional_grades ||=
        begin
          provisional_grades = assignment.provisional_grades
          unless anonymous_graders?(current_user:, assignment:)
            provisional_grades = provisional_grades.preload(:scorer)
          end

          case grading_role
          when :provisional_grader
            provisional_grades =
              if grader_comments_hidden?(current_user:, assignment:)
                provisional_grades.not_final.where(scorer: current_user)
              else
                select_fields =
                  ModeratedGrading::GRADE_ATTRIBUTES_ONLY.dup.push(:id, :submission_id)
                provisional_grades.select(select_fields)
              end
          when :grader
            provisional_grades = ModeratedGrading::ProvisionalGrade.none
          end
          provisional_grades.order(:id).to_a.group_by(&:submission_id)
        end
    end

    private

    attr_reader :assignment, :avatars, :current_user, :grading_role

    def course
      assignment.context
    end

    def migrate_to_canvadocs?
      account_context = course.try(:account) || course.try(:root_account)
      account_context.present? && account_context.migrate_to_canvadocs?
    end

    def rubric_assessments_to_json(rubric_assessments:, submissions:)
      rubric_assessments.map do |assessment|
        json = assessment.as_json(methods: [:assessor_name], include_root: false)
        assessor_id = json[:assessor_id]

        if anonymous_graders?(current_user:, assignment:)
          json.delete(:assessor_id)
          json[:anonymous_assessor_id] = assignment.grader_ids_to_anonymous_ids[assessor_id.to_s]
          json.delete(:assessor_name) unless assessor_id == current_user.id
        end

        if anonymous_students?(current_user:, assignment:)
          json[:anonymous_user_id] =
            student_ids_to_anonymous_ids(
              current_user:,
              assignment:,
              course:,
              submissions:
            ).fetch(json.delete(:user_id).to_s)
        end

        if grader_comments_hidden_or_other_grader?(
          assessor_id:,
          submissions:
        )
          json["data"].each do |datum|
            datum.delete(:comments)
            datum.delete(:comments_html)
          end
        end

        json
      end
    end

    def provisional_grade_to_json(provisional_grade)
      provisional_grade.grade_attributes.tap do |json|
        if anonymous_graders?(current_user:, assignment:)
          json[:anonymous_grader_id] =
            assignment.grader_ids_to_anonymous_ids[json.delete(:scorer_id).to_s]
        else
          json[:scorer_name] = provisional_grade.scorer&.name
        end
      end
    end

    def provisional_grader_or_moderator?
      grading_role == :provisional_grader || grading_role == :moderator
    end

    def display_avatars?
      avatars && !assignment.grade_as_group?
    end

    def grader_comments_hidden_or_other_grader?(assessor_id:, submissions:)
      grader_comments_hidden?(current_user:, assignment:) &&
        other_grader?(
          user_id: assessor_id,
          current_user:,
          course:,
          assignment:,
          submissions:
        )
    end

    def group_id_filter
      return nil unless course.filter_speed_grader_by_student_group?

      group_id =
        current_user
        .get_preference(:gradebook_settings, course.global_id)
        &.dig("filter_rows_by", "student_group_id")

      # If we selected a group that is now deleted, don't use it
      Group.active.where(id: group_id).exists? ? group_id : nil
    end

    def section_id_filter
      current_user
        .get_preference(:gradebook_settings, course.global_id)
        &.dig("filter_rows_by", "section_id")
    end
  end
end
