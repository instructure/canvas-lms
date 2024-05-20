# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class Quizzes::QuizStatistics::StudentAnalysis < Quizzes::QuizStatistics::Report
  CQS = CanvasQuizStatistics

  # The question_data attributes that we'll expose with the question statistics
  CQS_QuestionDataFields = %w[
    id
    question_type
    question_text
    position
  ].map(&:to_sym).freeze
  include HtmlTextHelper

  def readable_type
    t("#quizzes.quiz_statistics.types.student_analysis", "Student Analysis")
  end

  TemporaryUser = Struct.new(:id, :short_name)

  # returns a blob of stats junk like this:
  # {
  #   :multiple_attempts_exist=>false,
  #   :submission_user_ids=>#<Set: {2, ...}>,
  #   :submission_logged_out_users=>#<Array: [<#Hash: {"id"=>"tmp_93920...", "short_name"=>"Anonymous User"}>]>,
  #   :unique_submission_count=>50,
  #   :submission_score_average=>5,
  #   :submission_score_high=>10,
  #   :submission_score_low=>0,
  #   :submission_duration_average=>124,
  #   :submission_score_stdev=>0,
  #   :submission_incorrect_count_average=>3,
  #   :submission_correct_count_average=>1,
  #   :questions=>
  #     [output of stats_for_question for every question in submission_data]
  def generate(legacy = true, options = {})
    submissions = submissions_for_statistics(options)
    # questions: questions from quiz#quiz_data
    # {1022=>
    # {"id"=>1022,
    #  "points_possible"=>1,
    #  "question_type"=>"numerical_question",
    #  "question_name"=>"Really Hard Question",
    #  "name"=>"Really Hard Question",
    #  "answers"=> [{"id"=>6782},...],
    #  "assessment_question_id"=>1022,
    # }, ...}
    questions =
      (quiz.quiz_data || []).map { |q| q[:questions] || q }
                            .flatten
                            .select { |q| q[:answers] }
                            .index_by { |q| q[:id] }

    stats = {}
    found_ids = {}
    score_counter = Stats::Counter.new
    questions_hash = {}
    quiz_points = [quiz.current_points_possible.to_f, 1.0].max
    stats[:questions] = []
    stats[:multiple_attempts_exist] = submissions.any? do |s|
      s.attempt && s.attempt > 1
    end
    stats[:submission_user_ids] = Set.new
    stats[:submission_logged_out_users] = []
    stats[:submission_scores] = Hash.new(0)
    stats[:unique_submission_count] = 0
    temp_users = {}
    correct_cnt = incorrect_cnt = total_duration = 0
    submissions.each_with_index do |sub, index|
      # check for temporary user submissions
      if sub.user_id
        stats[:submission_user_ids] << sub.user_id if sub.user_id > 0
      else
        temp_user = TemporaryUser.new(sub.temporary_user_code, I18n.t(:logged_out_user, "Logged Out User %{user_counter}", user_counter: index + 1))
        stats[:submission_logged_out_users] << temp_user
        temp_users[sub.temporary_user_code] = temp_user
      end
      unless found_ids[sub.id]
        percentile = (sub.score.to_f / quiz_points * 100).round
        stats[:unique_submission_count] += 1
        stats[:submission_scores][percentile] += 1
        found_ids[sub.id] = true
      end
      answers = sub.submission_data || []
      next unless answers.is_a?(Array)

      score_counter << sub.score.to_f
      correct_cnt += answers.count { |a| a[:correct] == true }
      incorrect_cnt += answers.count { |a| a[:correct] == false }
      total_duration += ((sub.finished_at - sub.started_at).to_i rescue 30)
      sub.quiz_data.each do |question|
        questions_hash[question[:id]] ||= question
      end
    end
    stats[:submission_score_average] = score_counter.mean
    stats[:submission_score_high] = score_counter.max
    stats[:submission_score_low] = score_counter.min
    stats[:submission_score_stdev] = score_counter.standard_deviation
    if submissions.empty?
      stats[:submission_correct_count_average] =
        stats[:submission_incorrect_count_average] =
          stats[:submission_duration_average] = 0
    else
      stats[:submission_correct_count_average] = correct_cnt.to_f / submissions.size
      stats[:submission_incorrect_count_average] = incorrect_cnt.to_f / submissions.size
      stats[:submission_duration_average] = total_duration.to_f / submissions.size
    end

    assessment_questions = if questions_hash.any? { |_, q| q[:assessment_question_id] }

                             AssessmentQuestion.where(id: questions_hash.keys)
                                               .index_by(&:id)

                           else
                             {}
                           end
    responses_for_question = {}
    submissions.each do |s|
      s.submission_data.each do |a|
        q_id = a[:question_id]
        unless quiz.anonymous_survey?
          a[:user_id] = s.user_id || s.temporary_user_code
          a[:user_name] = s.user&.name || temp_users[s.temporary_user_code]&.short_name
        end
        responses_for_question[q_id] ||= []
        responses_for_question[q_id] << a
      end
    end

    questions_hash.each_key do |id|
      obj = questions[id]
      unless obj
        obj = questions_hash[id]
        if obj[:assessment_question_id]
          aq_name = assessment_questions[obj[:assessment_question_id]].try(:name)
          obj[:name] = aq_name if aq_name
        end
      end
      next unless obj[:answers] && obj[:question_type] != "text_only_question"

      stat = stats_for_question(obj, responses_for_question[obj[:id]], legacy)
      stat[:answers].each { |a| a.delete(:user_names) } if stat[:answers] && anonymous?
      stats[:questions] << ["question", stat]
    end

    stats
  end

  def preload_attachments(submissions)
    ids = submissions.map(&:submission_data).flatten.compact.select do |hash|
      hash[:attachment_ids].present?
    end.pluck(:attachment_ids).flatten
    @attachments = Attachment.where(id: ids).index_by(&:id)
  end

  def attachment_csv(answer)
    return "" unless answer && answer[:attachment_ids].present?

    attachment = @attachments[answer[:attachment_ids].first.to_i]

    if attachment.present?
      attachment.display_name
    else
      ""
    end
  end

  def to_csv
    include_root_accounts = quiz.context.root_account.trust_exists?
    CSV.generate do |csv|
      context = quiz.context

      # write columns to csv
      columns = []
      columns << I18n.t("statistics.csv_columns.name", "name") unless anonymous?
      columns << I18n.t("statistics.csv_columns.id", "id") unless anonymous?
      columns << I18n.t("statistics.csv_columns.sis_id", "sis_id") if !anonymous? && includes_sis_ids?
      columns << I18n.t("statistics.csv_columns.root_account", "root_account") if !anonymous? && include_root_accounts
      columns << I18n.t("statistics.csv_columns.section", "section")
      columns << I18n.t("statistics.csv_columns.section_id", "section_id")
      columns << I18n.t("statistics.csv_columns.section_sis_id", "section_sis_id") if includes_sis_ids?
      columns << I18n.t("statistics.csv_columns.submitted", "submitted")
      columns << I18n.t("statistics.csv_columns.attempt", "attempt") if includes_all_versions?
      first_question_index = columns.length
      submissions = submissions_for_statistics
      preload_attachments(submissions)
      found_question_ids = {}
      quiz_datas = [quiz.quiz_data] + submissions.map(&:quiz_data)
      quiz_datas.compact.each do |quiz_data|
        quiz_data.each do |question|
          next if question["entry_type"] == "quiz_group"

          next if found_question_ids[question[:id]]

          columns << "#{question[:id]}: #{strip_tags(question[:question_text])}"
          columns << question[:points_possible]
          found_question_ids[question[:id]] = true
        end
      end
      last_question_index = columns.length - 1
      columns << I18n.t("statistics.csv_columns.n_correct", "n correct")
      columns << I18n.t("statistics.csv_columns.n_incorrect", "n incorrect")
      columns << I18n.t("statistics.csv_columns.score", "score")
      csv << columns

      # write rows to csv
      submissions.each_with_index do |submission, i|
        update_progress(i, submissions.size)
        row = []
        unless anonymous?
          if submission.user
            row << submission.user.name
            row << submission.user_id
            if includes_sis_ids?
              pseudonym = SisPseudonym.for(submission.user, quiz.context, type: :trusted)
              row << pseudonym.try(:sis_user_id)
            end
            row << (pseudonym && HostUrl.context_host(pseudonym.account)) if include_root_accounts
          else
            2.times do
              row << ""
            end
            row << "" if includes_sis_ids?
            row << "" if include_root_accounts
          end
        end
        section_name = []
        section_id = []
        section_sis_id = []
        context.student_enrollments.active.where(user_id: submission.user_id).each do |enrollment|
          section_name << enrollment.course_section.name
          section_id << enrollment.course_section.id
          section_sis_id << enrollment.course_section.try(:sis_source_id)
        end
        row << section_name.join(", ")
        row << section_id.join(", ")
        row << section_sis_id.join(", ") if includes_sis_ids?
        row << submission.finished_at
        row << submission.attempt if includes_all_versions?
        columns[first_question_index..last_question_index].each do |id|
          next unless id.is_a?(String)

          id = id.to_i
          answer = submission.submission_data.detect { |a| a[:question_id] == id }
          question = submission.quiz_data.detect { |q| q[:id] == id }
          unless question
            # if this submission didn't answer this question, fill in with blanks
            row << ""
            row << ""
            next
          end
          strip_html_answers(question)
          answer_item = question && question[:answers]&.detect { |a| a[:id] == answer[:answer_id] }
          answer_item ||= answer
          case question[:question_type]
          when "fill_in_multiple_blanks_question"
            blank_ids = question[:answers].pluck(:blank_id).uniq
            row << blank_ids.filter_map { |blank_id| answer[:"answer_for_#{blank_id}"].try(:gsub, /,/, "\\,") }.join(",")
          when "multiple_answers_question"
            row << question[:answers].filter_map { |a| (answer[:"answer_#{a[:id]}"] == "1") ? a[:text].gsub(",", "\\,") : nil }.join(",")
          when "multiple_dropdowns_question"
            blank_ids = question[:answers].pluck(:blank_id).uniq
            answer_ids = blank_ids.map { |blank_id| answer[:"answer_for_#{blank_id}"] }
            row << answer_ids.filter_map { |answer_id| (question[:answers].detect { |a| a[:id] == answer_id } || {})[:text].try(:gsub, /,/, "\\,") }.join(",")
          when "calculated_question"
            list = question[:answers].take(1).flat_map do |ans|
              ans[:variables]&.map do |variable|
                [variable[:name], variable[:value].to_s].map { |str| str.gsub("=>", "\\=>") }.join("=>")
              end
            end
            list << answer[:text]
            row << list.map { |str| (str || "").gsub(",", "\\,") }.join(",")
          when "matching_question"
            answer_ids = question[:answers].pluck(:id)
            answer_and_matches = answer_ids.map { |aid| [aid, answer[:"answer_#{aid}"].to_i] }
            row << answer_and_matches.map do |answer_id, match_id|
              res = []
              res << (question[:answers].detect { |a| a[:id] == answer_id } || {})[:text]
              match = question[:matches].detect { |m| m[:match_id] == match_id } || question[:answers].detect { |m| m[:match_id] == match_id } || {}
              res << (match[:right] || match[:text])
              res.map { |s| (s || "").gsub("=>", "\\=>") }.join("=>").gsub(",", "\\,")
            end.join(",")
          when "numerical_question"
            row << (answer && answer[:text])
          when "file_upload_question"

            row << attachment_csv(answer)
          else
            row << ((answer_item && answer_item[:text]) || "")
          end
          row.push(html_to_text(row.pop.to_s))
          row << (answer ? answer[:points] : "")
        end
        row << submission.submission_data.count { |a| a[:correct] }
        row << submission.submission_data.count { |a| !a[:correct] }
        row << submission.score
        csv << row
      end
    end
  end

  private

  def submissions_for_statistics(param_options = {})
    GuardRail.activate(:secondary) do
      scope = quiz.quiz_submissions.for_students(quiz)
      logged_out = quiz.quiz_submissions.logged_out

      if param_options[:section_ids].present?
        user_ids = Enrollment.active.where(course_section_id: param_options[:section_ids]).pluck(:user_id)
        scope = scope.where(user_id: user_ids)
        logged_out = logged_out.where(user_id: user_ids)
      end

      all_submissions = prep_submissions(scope)
      all_submissions + prep_submissions(logged_out)
    end
  end

  def prep_submissions(submissions)
    subs = submissions.preload(:versions, :user).map do |qs|
      includes_all_versions? ? qs.attempts.version_models : qs.attempts.kept
    end
    subs = subs.flatten.compact.select do |s|
      s.completed? && s.submission_data.is_a?(Array)
    end
    subs.sort_by(&:updated_at).reverse
  end

  def strip_html_answers(question)
    return if !question || !question[:answers] || !(%w[multiple_choice_question multiple_answers_question].include? question[:question_type])

    question[:answers].each do |answer|
      answer[:text] = strip_tags(answer[:html]) if answer[:html].present? && answer[:text].blank?
    end
  end

  # takes a question hash from Quiz/Submission#quiz_data, and a set of
  # responses (from Submission#submission_data)
  #
  # returns:
  # ["question",
  #  {"points_possible"=>1,
  #   "question_type"=>"multiple_choice_question",
  #   "question_name"=>"Some Question",
  #   "name"=>"Some Question",
  #   "question_text"=>"<p>Blah blah blah?</p>",
  #   "answers"=>
  #    [{"text"=>"blah",
  #      "comments"=>"",
  #      "weight"=>100,
  #      "id"=>8379,
  #      "responses"=>2,
  #      "user_ids"=>[2, 3]},
  #     {"text"=>"blarb",
  #      "weight"=>0,
  #      "id"=>8153,
  #      "responses"=>1,
  #      "user_ids"=>[1]}],
  #   "assessment_question_id"=>1017,
  #   "id"=>1017,
  #   "responses"=>3,
  #   "response_values"=>[...],
  #   "unexpected_response_values"=>[],
  #   "user_ids"=>[1,2,3],
  #   "multiple_responses"=>false}],
  def stats_for_question(question, responses, legacy = true)
    if !legacy && CQS.can_analyze?(question)
      output = {}

      # the gem expects all hash keys to be symbols:
      question = CQS::Util.deep_symbolize_keys(question.to_hash)
      responses = responses.map(&CQS::Util.method(:deep_symbolize_keys))

      output.merge! question.slice(*CQS_QuestionDataFields)
      output.merge! CQS.analyze(question, responses)

      return output
    end

    question[:responses] = 0
    question[:response_values] = []
    question[:unexpected_response_values] = []
    question[:user_ids] = []
    question[:answers].each do |a|
      a[:responses] = 0
      a[:user_ids] = []
    end
    strip_html_answers(question)

    question[:user_ids] = responses.pluck(:user_id)
    question[:response_values] = responses.map { |r| strip_tags(r[:text].to_s) }
    question[:responses] = responses.size

    question = Quizzes::QuizQuestion::Base.from_question_data(question).stats(responses)
    none = {
      responses: question[:responses] - question[:answers].sum { |a| a[:responses] || 0 },
      id: "none",
      weight: 0,
      text: I18n.t("statistics.no_answer", "No Answer"),
      user_ids: question[:user_ids] - question[:answers].pluck(:user_ids).flatten
    } rescue nil
    question[:answers] << none if none && none[:responses] > 0
    question.to_hash.with_indifferent_access
  end
end
