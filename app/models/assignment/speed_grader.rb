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

class Assignment
  class SpeedGrader
    include GradebookSettingsHelpers

    def initialize(assignment, user, avatars: false, grading_role: :grader)
      @assignment = assignment
      @course = @assignment.context
      @user = user
      @avatars = avatars && !@assignment.grade_as_group?
      @grading_role = grading_role
      account_context = @course.try(:account) || @course.try(:root_account)
      @should_migrate_to_canvadocs = account_context.present? && account_context.migrate_to_canvadocs?
    end

    def json
      Attachment.skip_thumbnails = true
      submission_fields = %i(anonymous_id id submitted_at workflow_state grade
                             grade_matches_current_submission graded_at turnitin_data
                             submission_type score points_deducted assignment_id submission_comments
                             grading_period_id excused updated_at)

      submission_fields << (anonymous_moderated_marking? ? :anonymous_id : :user_id)

      comment_fields = %i(comment id author_name created_at author_id media_comment_type
                          media_comment_id cached_attachments attachments draft
                          group_comment_id).freeze

      attachment_fields = %i(id comment_id content_type context_id context_type display_name
                             filename mime_class size submitter_id workflow_state viewed_at).freeze

      enrollment_fields = %i(course_section_id workflow_state user_id).freeze

      res = @assignment.as_json(
        :include => {
          :context => { :only => :id },
          :rubric_association => { :except => {} }
        },
        :include_root => false
      )

      # include :provisional here someday if we need to distinguish
      # between provisional and real comments (also in
      # SubmissionComment#serialization_methods)
      submission_comment_methods = []
      submission_comment_methods << :avatar_path if @avatars

      res[:context][:rep_for_student] = {}

      students = @assignment.representatives(@user, includes: gradebook_includes) do |rep, others|
        others.each { |s| res[:context][:rep_for_student][s.id] = rep.id }
      end
      # Ensure that any test students are sorted last
      students = students.partition { |r| r.preferences[:fake_student] != true }.flatten

      enrollments = @course.apply_enrollment_visibility(gradebook_enrollment_scope, @user, nil,
                                                        include: gradebook_includes)

      is_provisional = @grading_role == :provisional_grader || @grading_role == :moderator
      rubric_assmnts = @assignment.visible_rubric_assessments_for(@user, :provisional_grader => is_provisional) || []

      # include all the rubric assessments if a moderator
      all_provisional_rubric_assmnts = @grading_role == :moderator &&
        (@assignment.visible_rubric_assessments_for(@user, :provisional_moderator => true) || [])

      # if we're a provisional grader, calculate whether the student needs a grade
      preloaded_pg_counts = is_provisional && @assignment.provisional_grades.not_final.group("submissions.user_id").count
      ActiveRecord::Associations::Preloader.new.preload(@assignment, :moderated_grading_selections) if is_provisional

      includes = [{ versions: :versionable }, :quiz_submission, :user, :attachment_associations, :assignment, :originality_reports]
      key = @grading_role == :grader ? :submission_comments : :all_submission_comments

      includes << {key => {submission: {assignment: { context: :root_account }}}}
      submissions = @assignment.submissions.where(:user_id => students).preload(*includes)

      student_ids_to_anonymous_ids = students.each_with_object({}) { |student, map| map[student.id.to_s] = nil }

      student_fields = %i(name id sortable_name)
      rubric_assessment_excludes = []

      if anonymous_moderated_marking?
        submissions.each do |submission|
          student_ids_to_anonymous_ids[submission.user_id.to_s] = submission.anonymous_id
        end

        student_fields = []
        rubric_assessment_excludes << :user_id
      end

      res[:context][:students] = students.map do |u|
        json = u.as_json(include_root: false, methods: submission_comment_methods, only: student_fields)
        json[:anonymous_id] = student_ids_to_anonymous_ids[u.id.to_s]

        if preloaded_pg_counts
          json[:needs_provisional_grade] = @assignment.student_needs_provisional_grade?(u, preloaded_pg_counts)
        end

        json[:rubric_assessments] = rubric_assmnts.select{|ra| ra.user_id == u.id}.
          as_json(except: rubric_assessment_excludes, methods: [:assessor_name], include_root: false)

        json
      end

      res[:context][:active_course_sections] = @assignment
        .context
        .sections_visible_to(
          @user,
          @assignment.sections_with_visibility(@user)
        )
        .map do |section|
          section.as_json(
            include_root: false,
            only: [:id, :name]
          )
        end

      res[:context][:enrollments] = enrollments.map do |enrollment|
        enrollment_json = enrollment.as_json(include_root: false, only: enrollment_fields)
        if anonymous_moderated_marking?
          enrollment_json[:anonymous_id] = student_ids_to_anonymous_ids[enrollment.user_id.to_s]
          enrollment_json.delete(:user_id)
        end
        enrollment_json
      end
      res[:context][:quiz] = @assignment.quiz.as_json(:include_root => false, :only => [:anonymous_submissions])

      attachment_includes = %i(crocodoc_document canvadoc root_attachment)
      # Preload attachments for later looping
      attachments_for_submission =
        Submission.bulk_load_attachments_for_submissions(submissions, preloads: attachment_includes)

      # Preloading submission history versioned attachments and originality reports
      submission_histories = submissions.map(&:submission_history).flatten
      Submission.bulk_load_versioned_attachments(submission_histories,
                                                 preloads: attachment_includes)
      Submission.bulk_load_versioned_originality_reports(submission_histories)
      Submission.bulk_load_text_entry_originality_reports(submission_histories)

      preloaded_prov_grades =
        case @grading_role
        when :moderator
          @assignment.provisional_grades.order(:id).to_a.group_by(&:submission_id)
        when :provisional_grader
          @assignment.provisional_grades.not_final.where(:scorer_id => @user).order(:id).to_a.
            group_by(&:submission_id)
        else
          {}
        end

      preloaded_prov_selections = @grading_role == :moderator ? @assignment.moderated_grading_selections.index_by(&:student_id) : []

      res[:too_many_quiz_submissions] = too_many = @assignment.too_many_qs_versions?(submissions)
      qs_versions = @assignment.quiz_submission_versions(submissions, too_many)

      enrollment_types_by_id = enrollments.inject({}){ |h, e| h[e.user_id] ||= e.type; h }

      if @assignment.quiz
        if @assignment.quiz.assignment_overrides.to_a.select(&:active?).count == 0
          @assignment.quiz.has_no_overrides = true
        else
          @assignment.quiz.context.preload_user_roles!
        end
      end

      res[:submissions] = submissions.map do |sub|
        json = sub.as_json(:include_root => false,
          :methods => [:submission_history, :late, :external_tool_url, :entered_score, :entered_grade],
          :only => submission_fields
        ).merge("from_enrollment_type" => enrollment_types_by_id[sub.user_id])

        if @grading_role == :provisional_grader || @grading_role == :moderator
          provisional_grade = sub.provisional_grade(@user, preloaded_grades: preloaded_prov_grades)
          json.merge! provisional_grade.grade_attributes
        end

        comments = (provisional_grade || sub).submission_comments
        if @assignment.grade_as_group?
          comments = comments.reject { |comment| comment.group_comment_id.nil? }
        end
        json[:submission_comments] = comments.map do |comment|
          comment_json = comment.as_json(
            include_root: false,
            methods: submission_comment_methods,
            only: comment_fields
          )
          if anonymous_moderated_marking? && student_ids_to_anonymous_ids.key?(comment_json[:author_id].to_s)
            author_id = comment_json.delete(:author_id).to_s
            comment_json.delete(:author_name)
            comment_json[:anonymous_id] = student_ids_to_anonymous_ids[author_id]
            comment_json[:avatar_path] = User.default_avatar_fallback if @avatars
          end
          comment_json
        end

        # We get the attachments this way to avoid loading the
        # attachments again via the submission method that creates a
        # new query.
        json['attachments'] = attachments_for_submission[sub].map do |att|
          att.as_json(:only => [:mime_class, :comment_id, :id, :submitter_id ])
        end
        has_crocodoc = attachments_for_submission[sub].any?(&:crocodoc_available?)

        sub_attachments = []
        moderated_grading_whitelist = if is_provisional
                                        [ sub.user, @user ].map do |u|
                                          u.moderated_grading_ids(has_crocodoc)
                                        end
                                      else
                                        sub.moderated_grading_whitelist
                                      end

        url_opts = {
          enable_annotations: true,
          moderated_grading_whitelist: moderated_grading_whitelist
        }

        if json['submission_history'] && (@assignment.quiz.nil? || too_many)
          json['submission_history'] = json['submission_history'].map do |version|
            # to avoid a call to the DB in Submission#missing?
            version.assignment = sub.assignment
            version.as_json(only: submission_fields,
                            methods: %i[versioned_attachments late missing external_tool_url]).tap do |version_json|
              version_json['submission']['has_originality_report'] = version.has_originality_report?
              version_json['submission']['has_plagiarism_tool'] = version.assignment.assignment_configuration_tool_lookup_ids.present?
              version_json['submission']['has_originality_score'] = version.originality_reports_for_display.any? { |o| o.originality_score.present? }
              version_json['submission']['turnitin_data'].merge!(version.originality_data)

              if version_json['submission'][:submission_type] == 'discussion_topic'
                url_opts[:enable_annotations] = false
              end
              if version_json['submission'] && version_json['submission']['versioned_attachments']
                version_json['submission']['versioned_attachments'].map! do |a|
                  if version_json['submission'][:submission_type] == 'discussion_topic'
                    url_opts[:enable_annotations] = false
                  end
                  if @grading_role == :moderator
                    # we'll use to create custom crocodoc urls for each prov grade
                    sub_attachments << a
                  end
                  a.as_json(only: attachment_fields,
                            methods: [:view_inline_ping_url]).tap do |json|
                    json[:attachment][:canvadoc_url] = a.canvadoc_url(@user, url_opts)
                    json[:attachment][:crocodoc_url] = a.crocodoc_url(@user, url_opts)
                    json[:attachment][:submitted_to_crocodoc] = a.crocodoc_document.present?
                    json[:attachment][:hijack_crocodoc_session] = a.crocodoc_document.present? && @should_migrate_to_canvadocs
                  end
                end
              end
            end
          end
        elsif @assignment.quiz && sub.quiz_submission
          json['submission_history'] = qs_versions[sub.quiz_submission.id].map do |v|
            # don't use v.model, because these are huge objects, and can be significantly expensive
            # to instantiate an actual AR object deserializing and reserializing the inner YAML
            qs = YAML.load(v.yaml)

            {submission: {
                grade: qs['score'],
                show_grade_in_dropdown: true,
                submitted_at: qs['finished_at'],
                late: Quizzes::QuizSubmission.late_from_attributes?(qs, @assignment.quiz, sub),
                version: v.number,
              }}
          end
        end

        if @grading_role == :moderator
          pgs = preloaded_prov_grades[sub.id] || []
          selection = preloaded_prov_selections[sub.user.id]
          unless pgs.count == 0 || (pgs.count == 1 && pgs.first.scorer_id == @user.id)
            json['provisional_grades'] = []
            pgs.each do |pg|
              pg_json = pg.grade_attributes.tap do |json|
                json[:rubric_assessments] =
                  all_provisional_rubric_assmnts.select { |ra| ra.artifact_id == pg.id }.
                    as_json(:methods => [:assessor_name], :include_root => false)

                json[:selected] = !!(selection && selection.selected_provisional_grade_id == pg.id)
                # this should really be provisional_doc_view_urls :: https://instructure.atlassian.net/browse/CNVS-38202
                json[:crocodoc_urls] =
                  sub_attachments.map { |a| pg.attachment_info(@user, a) }
                json[:readonly] = !pg.final && (pg.scorer_id != @user.id)
                json[:submission_comments] =
                  pg.submission_comments.as_json(include_root: false,
                                                 methods: submission_comment_methods,
                                                 only: comment_fields)
              end

              if pg.final
                json['final_provisional_grade'] = pg_json
              else
                json['provisional_grades'] << pg_json
              end
            end
          end
        end

        json
      end
      res[:GROUP_GRADING_MODE] = @assignment.grade_as_group?
      StringifyIds.recursively_stringify_ids(res)
    ensure
      Attachment.skip_thumbnails = nil
    end

    private

    def anonymous_moderated_marking?
      @course.root_account.feature_enabled?(:anonymous_moderated_marking) && @assignment.anonymous_grading?
    end
  end
end
