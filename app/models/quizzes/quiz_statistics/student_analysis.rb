#
# Copyright (C) 2013 Instructure, Inc.
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

require 'csv'

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
    t('#quizzes.quiz_statistics.types.student_analysis', 'Student Analysis')
  end

  class TemporaryUser < Struct.new(:id, :short_name)
  end

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
  def generate(legacy=true)
    submissions = submissions_for_statistics
    # questions: questions from quiz#quiz_data
    #{1022=>
    # {"id"=>1022,
    #  "points_possible"=>1,
    #  "question_type"=>"numerical_question",
    #  "question_name"=>"Really Hard Question",
    #  "name"=>"Really Hard Question",
    #  "answers"=> [{"id"=>6782},...],
    #  "assessment_question_id"=>1022,
    # }, ...}
    questions = Hash[
      (quiz.quiz_data || []).map { |q| q[:questions] || q }.
      flatten.
      select { |q| q[:answers] }.
      map { |q| [q[:id], q] }
    ]
    stats = {}
    found_ids = {}
    score_counter = Stats::Counter.new
    questions_hash = {}
    quiz_points = [quiz.current_points_possible.to_f, 1.0].max
    stats[:questions] = []
    stats[:multiple_attempts_exist] = submissions.any? { |s|
      s.attempt && s.attempt > 1
    }
    stats[:submission_user_ids] = Set.new
    stats[:submission_logged_out_users] = []
    stats[:submission_scores] = Hash.new(0)
    stats[:unique_submission_count] = 0
    correct_cnt = incorrect_cnt = total_duration = 0
    submissions.each_with_index do |sub, index|
      #check for temporary user submissions
      if sub.user_id
        stats[:submission_user_ids] << sub.user_id if sub.user_id > 0
      else
        temp_user = TemporaryUser.new(sub.temporary_user_code, I18n.t(:logged_out_user, "Logged Out User %{user_counter}", :user_counter => index + 1))
        stats[:submission_logged_out_users] << temp_user
      end
      if !found_ids[sub.id]
        percentile = (sub.score.to_f / quiz_points * 100).round
        stats[:unique_submission_count] += 1
        stats[:submission_scores][percentile] += 1
        found_ids[sub.id] = true
      end
      answers = sub.submission_data || []
      next unless answers.is_a?(Array)
      points = answers.map { |a| a[:points] }.sum
      score_counter << points
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
    if submissions.size > 0
      stats[:submission_correct_count_average] = correct_cnt.to_f / submissions.size
      stats[:submission_incorrect_count_average] = incorrect_cnt.to_f / submissions.size
      stats[:submission_duration_average] = total_duration.to_f / submissions.size
    else
      stats[:submission_correct_count_average] =
        stats[:submission_incorrect_count_average] =
        stats[:submission_duration_average] = 0
    end

    assessment_questions = if questions_hash.any? { |_, q| q[:assessment_question_id] }
                             Hash[
                               AssessmentQuestion.where(:id => questions_hash.keys).
                               map { |aq| [aq.id, aq] }
                             ]
                           else
                             {}
                           end
    responses_for_question = {}
    submissions.each do |s|
      s.submission_data.each do |a|
        q_id = a[:question_id]
        a[:user_id] = s.user_id || s.temporary_user_code
        responses_for_question[q_id] ||= []
        responses_for_question[q_id] << a
      end
    end

    questions_hash.keys.each do |id|
      obj = questions[id]
      unless obj
        obj = questions_hash[id]
        if obj[:assessment_question_id]
          aq_name = assessment_questions[obj[:assessment_question_id]].try(:name)
          obj[:name] = aq_name if aq_name
        end
      end
      if obj[:answers] && obj[:question_type] != 'text_only_question'
        stat = stats_for_question(obj, responses_for_question[obj[:id]], legacy)
        stats[:questions] << ['question', stat]
      end
    end

    stats
  end

  def preload_attachments(submissions)
    ids = submissions.map(&:submission_data).flatten.compact.select do |hash|
      hash[:attachment_ids].present?
    end.map do |hash|
      hash[:attachment_ids]
    end.flatten
    @attachments = Hash[Attachment.where(:id => ids).map do |a|
      [a.id, a]
    end
    ]
  end

  def attachment_csv(answer)
    return "" unless answer && answer[:attachment_ids]
    @attachments[answer[:attachment_ids].first.to_i].display_name
  end

  def to_csv
    start_progress
    include_root_accounts = quiz.context.root_account.trust_exists?
    csv = CSV.generate do |csv|
      context = quiz.context

      # write columns to csv
      columns = []
      columns << I18n.t('statistics.csv_columns.name', 'name') unless anonymous?
      columns << I18n.t('statistics.csv_columns.id', 'id') unless anonymous?
      columns << I18n.t('statistics.csv_columns.sis_id', 'sis_id') unless anonymous?
      columns << I18n.t('statistics.csv_columns.root_account', 'root_account') if !anonymous? && include_root_accounts
      columns << I18n.t('statistics.csv_columns.section', 'section')
      columns << I18n.t('statistics.csv_columns.section_id', 'section_id')
      columns << I18n.t('statistics.csv_columns.section_sis_id', 'section_sis_id')
      columns << I18n.t('statistics.csv_columns.submitted', 'submitted')
      columns << I18n.t('statistics.csv_columns.attempt', 'attempt') if includes_all_versions?
      first_question_index = columns.length
      submissions = submissions_for_statistics
      preload_attachments(submissions)
      found_question_ids = {}
      quiz_datas = [quiz.quiz_data] + submissions.map(&:quiz_data)
      quiz_datas.compact.each do |quiz_data|
        quiz_data.each do |question|
          next if question['entry_type'] == 'quiz_group'
          if !found_question_ids[question[:id]]
            columns << "#{question[:id]}: #{strip_tags(question[:question_text])}"
            columns << question[:points_possible]
            found_question_ids[question[:id]] = true
          end
        end
      end
      last_question_index = columns.length - 1
      columns << I18n.t('statistics.csv_columns.n_correct', 'n correct')
      columns << I18n.t('statistics.csv_columns.n_incorrect', 'n incorrect')
      columns << I18n.t('statistics.csv_columns.score', 'score')
      csv << columns

      # write rows to csv
      submissions.each_with_index do |submission, i|
        update_progress(i, submissions.size)
        row = []
        unless anonymous?
          if submission.user
            row << submission.user.name
            row << submission.user_id
            pseudonym = submission.user.sis_pseudonym_for(quiz.context.account, include_root_accounts)
            row << pseudonym.try(:sis_user_id)
            row << (pseudonym && HostUrl.context_host(pseudonym.account)) if include_root_accounts
          else
            3.times do
              row << ''
            end
            row << '' if include_root_accounts
          end
        end
        section_name = []
        section_id = []
        section_sis_id = []
        context.student_enrollments.active.where(:user_id => submission.user_id).each do |enrollment|
          section_name << enrollment.course_section.name
          section_id << enrollment.course_section.id
          section_sis_id << enrollment.course_section.try(:sis_source_id)
        end
        row << section_name.join(", ")
        row << section_id.join(", ")
        row << section_sis_id.join(", ")
        row << submission.finished_at
        row << submission.attempt if includes_all_versions?
        columns[first_question_index..last_question_index].each do |id|
          next unless id.is_a?(String)
          id = id.to_i
          answer = submission.submission_data.detect { |a| a[:question_id] == id }
          question = submission.quiz_data.detect { |q| q[:id] == id }
          unless question
            # if this submission didn't answer this question, fill in with blanks
            row << ''
            row << ''
            next
          end
          strip_html_answers(question)
          answer_item = question && question[:answers].detect { |a| a[:id] == answer[:answer_id] }
          answer_item ||= answer
          if question[:question_type] == 'fill_in_multiple_blanks_question'
            blank_ids = question[:answers].map { |a| a[:blank_id] }.uniq
            row << blank_ids.map { |blank_id| answer["answer_for_#{blank_id}".to_sym].try(:gsub, /,/, '\,') }.compact.join(',')
          elsif question[:question_type] == 'multiple_answers_question'
            row << question[:answers].map { |a| answer["answer_#{a[:id]}".to_sym] == '1' ? a[:text].gsub(/,/, '\,') : nil }.compact.join(',')
          elsif question[:question_type] == 'multiple_dropdowns_question'
            blank_ids = question[:answers].map { |a| a[:blank_id] }.uniq
            answer_ids = blank_ids.map { |blank_id| answer["answer_for_#{blank_id}".to_sym] }
            row << answer_ids.map { |id| (question[:answers].detect { |a| a[:id] == id } || {})[:text].try(:gsub, /,/, '\,') }.compact.join(',')
          elsif question[:question_type] == 'calculated_question'
            list = question[:answers][0][:variables].map { |a| [a[:name], a[:value].to_s].map { |str| str.gsub(/\=>/, '\=>') }.join('=>') }
            list << answer[:text]
            row << list.map { |str| (str || '').gsub(/,/, '\,') }.join(',')
          elsif question[:question_type] == 'matching_question'
            answer_ids = question[:answers].map { |a| a[:id] }
            answer_and_matches = answer_ids.map { |id| [id, answer["answer_#{id}".to_sym].to_i] }
            row << answer_and_matches.map { |id, match_id|
              res = []
              res << (question[:answers].detect { |a| a[:id] == id } || {})[:text]
              match = question[:matches].detect { |m| m[:match_id] == match_id } || question[:answers].detect { |m| m[:match_id] == match_id } || {}
              res << (match[:right] || match[:text])
              res.map { |s| (s || '').gsub(/\=>/, '\=>') }.join('=>').gsub(/,/, '\,')
            }.join(',')
          elsif question[:question_type] == 'numerical_question'
            row << (answer && answer[:text])
          elsif question[:question_type] == 'file_upload_question'

            row << attachment_csv(answer)
          else
            row << ((answer_item && answer_item[:text]) || '')
          end
          row << (answer ? answer[:points] : "")
        end
        row << submission.submission_data.select { |a| a[:correct] }.length
        row << submission.submission_data.reject { |a| a[:correct] }.length
        row << submission.score
        csv << row
      end
    end
    csv
  end

  private

  def submissions_for_statistics
    Shackles.activate(:slave) do
      #submissions from users
      for_users = quiz.context.student_ids
      scope = quiz.quiz_submissions.where(:user_id => for_users)
      logged_out = quiz.quiz_submissions.logged_out.where('NOT was_preview')

      all_submissions = []
      all_submissions = prep_submissions scope
      all_submissions += prep_submissions logged_out
    end
  end

  def prep_submissions(submissions)
    subs = submissions.includes(:versions).map do |qs|
      includes_all_versions? ? qs.attempts.version_models : qs.attempts.kept
    end
    subs = subs.flatten.compact.select do |s|
      s.completed? && s.submission_data.is_a?(Array)
    end
    subs.sort_by(&:updated_at).reverse
  end

  def strip_html_answers(question)
    return if !question || !question[:answers] || !(%w(multiple_choice_question multiple_answers_question).include? question[:question_type])
    for answer in question[:answers] do
      answer[:text] = strip_tags(answer[:html]) if !answer[:html].blank? && answer[:text].blank?
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
  def stats_for_question(question, responses, legacy=true)
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
    question[:answers].each { |a|
      a[:responses] = 0
      a[:user_ids] = []
    }
    strip_html_answers(question)

    question[:user_ids] = responses.map { |r| r[:user_id] }
    question[:response_values] = responses.map { |r| r[:text] }
    question[:responses] = responses.size

    question = Quizzes::QuizQuestion::Base.from_question_data(question).stats(responses)
    none = {
      :responses => question[:responses] - question[:answers].map { |a| a[:responses] || 0 }.sum,
      :id => "none",
      :weight => 0,
      :text => I18n.t('statistics.no_answer', "No Answer"),
      :user_ids => question[:user_ids] - question[:answers].map { |a| a[:user_ids] }.flatten
    } rescue nil
    question[:answers] << none if none && none[:responses] > 0
    question.to_hash.with_indifferent_access
  end

end
