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
    include CoursesHelper

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
      submission_json_fields = %i(id submitted_at workflow_state grade
                                  grade_matches_current_submission graded_at turnitin_data
                                  submission_type score points_deducted assignment_id submission_comments
                                  grading_period_id excused updated_at)

      submission_json_fields << (anonymous_students? ? :anonymous_id : :user_id)

      attachment_json_fields = %i(id comment_id content_type context_id context_type display_name
                                  filename mime_class size submitter_id workflow_state)

      if !@assignment.anonymize_students? || @course.account_membership_allows(@user)
        attachment_json_fields << :viewed_at
      end

      enrollment_json_fields = %i(course_section_id workflow_state user_id)

      res = @assignment.as_json(
        :include => {
          :context => { :only => :id },
          :rubric_association => { :except => {} }
        },
        :include_root => false
      )
      res['anonymize_students'] = @assignment.anonymize_students?

      # include :provisional here someday if we need to distinguish
      # between provisional and real comments (also in
      # SubmissionComment#serialization_methods)
      submission_comment_methods = []
      submission_comment_methods << :avatar_path if @avatars

      res[:context][:rep_for_student] = {}

      # If we're working with anonymous IDs, skip students who don't have a
      # valid submission object, which means no inactive or concluded students
      # even if the user has elected to show them in gradebook
      student_includes = @assignment.anonymize_students? ? [] : gradebook_includes
      @students = @assignment.representatives(@user, includes: student_includes) do |rep, others|
        others.each { |s| res[:context][:rep_for_student][s.id] = rep.id }
      end

      # Ensure that any test students are sorted last
      @students = @students.partition { |r| r.preferences[:fake_student] != true }.flatten

      enrollments = @course.apply_enrollment_visibility(gradebook_enrollment_scope, @user, nil,
                                                        include: student_includes)

      current_user_rubric_assessments = @assignment.visible_rubric_assessments_for(@user, provisional_grader: provisional_grader_or_moderator?) || []

      # include all the rubric assessments if a moderator
      all_provisional_rubric_assessments =
        @grading_role == :moderator ? @assignment.visible_rubric_assessments_for(@user, :provisional_moderator => true) : []

      ActiveRecord::Associations::Preloader.new.preload(@assignment, :moderated_grading_selections) if provisional_grader_or_moderator?

      includes = [{ versions: :versionable }, :quiz_submission, :user, :attachment_associations, :assignment, :originality_reports]
      key = @grading_role == :grader ? :submission_comments : :all_submission_comments

      includes << {key => {submission: {assignment: { context: :root_account }}}}
      @submissions = @assignment.submissions.where(:user_id => @students).preload(*includes)

      student_json_fields = anonymous_students? ? [] : %i(name id sortable_name)

      res[:context][:students] = @students.map do |student|
        json = student.as_json(include_root: false, methods: submission_comment_methods, only: student_json_fields)
        json[:anonymous_id] = student_ids_to_anonymous_ids[student.id.to_s] if anonymous_students?
        json[:needs_provisional_grade] = @assignment.can_be_moderated_grader?(@user) if provisional_grader_or_moderator?
        json[:rubric_assessments] = rubric_assessements_to_json(current_user_rubric_assessments.select {|assessment| assessment.user_id == student.id})
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
        enrollment_json = enrollment.as_json(include_root: false, only: enrollment_json_fields)
        if anonymous_students?
          enrollment_json[:anonymous_id] = student_ids_to_anonymous_ids[enrollment.user_id.to_s]
          enrollment_json.delete(:user_id)
        end
        enrollment_json
      end
      res[:context][:quiz] = @assignment.quiz.as_json(:include_root => false, :only => [:anonymous_submissions])

      attachment_includes = %i(crocodoc_document canvadoc root_attachment)
      # Preload attachments for later looping
      attachments_for_submission =
        Submission.bulk_load_attachments_for_submissions(@submissions, preloads: attachment_includes)

      # Preloading submission history versioned attachments and originality reports
      submission_histories = @submissions.map(&:submission_history).flatten
      Submission.bulk_load_versioned_attachments(submission_histories,
                                                 preloads: attachment_includes)
      Submission.bulk_load_versioned_originality_reports(submission_histories)
      Submission.bulk_load_text_entry_originality_reports(submission_histories)

      provisional_grades = @assignment.provisional_grades
      provisional_grades = provisional_grades.preload(:scorer) unless anonymous_graders?

      if @grading_role == :provisional_grader
        provisional_grades = if grader_comments_hidden?
          provisional_grades.not_final.where(scorer: @user)
        else
          select_fields = ::ModeratedGrading::GRADE_ATTRIBUTES_ONLY.dup.append(:submission_id)
          provisional_grades.select(select_fields)
        end
      elsif @grading_role == :grader
        provisional_grades = ::ModeratedGrading::ProvisionalGrade.none
      end
      preloaded_prov_grades = provisional_grades.order(:id).to_a.group_by(&:submission_id)

      preloaded_prov_selections =
        @grading_role == :moderator ? @assignment.moderated_grading_selections.index_by(&:student_id) : {}

      res[:too_many_quiz_submissions] = too_many = @assignment.too_many_qs_versions?(@submissions)
      qs_versions = @assignment.quiz_submission_versions(@submissions, too_many)

      enrollment_types_by_id = enrollments.inject({}){ |h, e| h[e.user_id] ||= e.type; h }

      if @assignment.quiz
        if @assignment.quiz.assignment_overrides.to_a.select(&:active?).count == 0
          @assignment.quiz.has_no_overrides = true
        else
          @assignment.quiz.context.preload_user_roles!
        end
      end

      res[:submissions] = @submissions.map do |sub|
        json = sub.as_json(
          include_root: false,
          methods: %i(submission_history late external_tool_url entered_score entered_grade),
          only: submission_json_fields
        ).merge("from_enrollment_type" => enrollment_types_by_id[sub.user_id])

        if provisional_grader_or_moderator?
          provisional_grade = sub.provisional_grade(@user, preloaded_grades: preloaded_prov_grades)
          json.merge! provisional_grade_to_json(provisional_grade)
        end

        comments = if grader_comments_hidden?
          (provisional_grade || sub).submission_comments
        else
          sub.all_submission_comments
        end

        if @assignment.grade_as_group?
          comments = comments.reject { |comment| comment.group_comment_id.nil? }
        end
        json[:submission_comments] = submission_comments_to_json(comments)

        # We get the attachments this way to avoid loading the
        # attachments again via the submission method that creates a
        # new query.
        json['attachments'] = attachments_for_submission[sub].map do |att|
          att.as_json(:only => [:mime_class, :comment_id, :id, :submitter_id ])
        end
        has_crocodoc = attachments_for_submission[sub].any?(&:crocodoc_available?)

        sub_attachments = []
        moderated_grading_whitelist = if provisional_grader_or_moderator?
                                        [ sub.user, @user ].map do |u|
                                          u.moderated_grading_ids(has_crocodoc)
                                        end
                                      else
                                        sub.moderated_grading_whitelist
                                      end

        url_opts = {
          anonymous_instructor_annotations: @assignment.anonymous_instructor_annotations,
          enable_annotations: true,
          moderated_grading_whitelist: moderated_grading_whitelist
        }

        if url_opts[:enable_annotations]
          url_opts[:enrollment_type] = user_type(@course, @user)
        end

        if json['submission_history'] && (@assignment.quiz.nil? || too_many)
          json['submission_history'] = json['submission_history'].map do |version|
            # to avoid a call to the DB in Submission#missing?
            version.assignment = sub.assignment
            version.as_json(only: submission_json_fields,
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
                  a.as_json(only: attachment_json_fields,
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

        if provisional_grader_or_moderator?
          pgs = preloaded_prov_grades[sub.id] || []
          selection = preloaded_prov_selections[sub.user.id]
          unless pgs.count == 0 || (pgs.count == 1 && pgs.first.scorer_id == @user.id)
            json['provisional_grades'] = []
            pgs.each do |pg|
              current_pg_json = provisional_grade_to_json(pg).tap do |pg_json|
                assessments = all_provisional_rubric_assessments.select {|assessment| assessment.artifact_id == pg.id}
                pg_json[:rubric_assessments] = rubric_assessements_to_json(assessments)

                pg_json[:selected] = !!(selection && selection.selected_provisional_grade_id == pg.id)
                # this should really be provisional_doc_view_urls :: https://instructure.atlassian.net/browse/CNVS-38202
                pg_json[:crocodoc_urls] = sub_attachments.map { |a| pg.attachment_info(@user, a) }
                pg_json[:readonly] = !pg.final && (pg.scorer_id != @user.id)
              end

              if pg.final
                json['final_provisional_grade'] = current_pg_json
              else
                json['provisional_grades'] << current_pg_json
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

    def rubric_assessements_to_json(rubric_assessments)
      rubric_assessments.map do |assessment|
        json = assessment.as_json(methods: [:assessor_name], include_root: false)
        assessor_id = json[:assessor_id]

        if anonymous_graders?
          json.delete(:assessor_id)
          json[:anonymous_assessor_id] = grader_ids_to_anonymous_ids[assessor_id.to_s]
          json.delete(:assessor_name) unless assessor_id == @user.id
        end

        if anonymous_students?
          json[:anonymous_user_id] = student_ids_to_anonymous_ids[json.delete(:user_id)]
        end

        if grader_comments_hidden? && other_grader?(assessor_id)
          json['data'].each do |datum|
            datum.delete(:comments)
            datum.delete(:comments_html)
          end
        end

        json
      end
    end

    def provisional_grade_to_json(provisional_grade)
      provisional_grade.grade_attributes.tap do |json|
        if anonymous_graders?
          json[:anonymous_grader_id] = grader_ids_to_anonymous_ids[json.delete(:scorer_id).to_s]
        else
          json[:scorer_name] = provisional_grade.scorer&.name
        end
      end
    end

    def submission_comments_to_json(submission_comments)
      @submission_comment_methods ||= @avatars ? [:avatar_path] : []
      @submission_comment_fields ||= %i(attachments author_id author_name cached_attachments comment
                                        created_at draft group_comment_id id media_comment_id
                                        media_comment_type)

      visible_submission_comments(submission_comments).map do |submission_comment|
        json = submission_comment.as_json(include_root: false,
                                          methods: @submission_comment_methods,
                                          only: @submission_comment_fields)
        author_id = submission_comment.author_id.to_s

        json[:publishable] = submission_comment.publishable_for?(@user)
        if anonymous_students? && student_ids_to_anonymous_ids.key?(author_id)
          json.delete(:author_id)
          json.delete(:author_name)
          json[:anonymous_id] = student_ids_to_anonymous_ids.fetch(author_id)
          json[:avatar_path] = User.default_avatar_fallback if @avatars
        elsif anonymous_graders? && (grader_ids_to_anonymous_ids.key?(author_id) || final_grader?(author_id))
          json.delete(:author_id)
          json[:anonymous_id] = grader_ids_to_anonymous_ids.fetch(author_id, nil)
          unless author_id == @user.id.to_s
            json[:avatar_path] = User.default_avatar_fallback if @avatars
            if final_grader?(author_id)
              json[:author_name] = I18n.t 'Moderator'
            else
              json.delete(:author_name)
            end
          end
        end

        json
      end
    end

    def anonymous_students?
      return @anonymous_students if defined? @anonymous_students
      @anonymous_students = !@assignment.can_view_student_names?(@user)
    end

    def anonymous_graders?
      return @anonymous_graders if defined? @anonymous_graders
      @anonymous_graders = !@assignment.can_view_other_grader_identities?(@user)
    end

    def grader_comments_hidden?
      return @grader_comments_hidden if defined? @grader_comments_hidden
      @grader_comments_hidden = !@assignment.can_view_other_grader_comments?(@user)
    end

    def visible_submission_comments(submission_comments)
      return submission_comments unless grader_comments_hidden?
      submission_comments.reject {|submission_comment| other_grader?(submission_comment.author_id)}
    end

    def student_ids_to_anonymous_ids
      return @student_ids_to_anonymous_ids if @student_ids_to_anonymous_ids
      # ensure each student has membership, even without a submission
      @student_ids_to_anonymous_ids = @students.each_with_object({}) {|student, map| map[student.id.to_s] = nil}
      @submissions.each do |submission|
        @student_ids_to_anonymous_ids[submission.user_id.to_s] = submission.anonymous_id
      end
      @student_ids_to_anonymous_ids
    end

    def grader_ids_to_anonymous_ids
      @assignment.grader_ids_to_anonymous_ids
    end

    def final_grader?(user_id)
      @assignment.final_grader_id.to_s == user_id.to_s
    end

    def other_grader?(user_id)
      !student?(user_id) && user_id != @user.id
    end

    def student?(user_id)
      student_ids_to_anonymous_ids.key?(user_id.to_s)
    end

    def provisional_grader_or_moderator?
      @grading_role == :provisional_grader || @grading_role == :moderator
    end
  end
end
