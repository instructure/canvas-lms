#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

class GradeCalculator
  attr_accessor :submissions, :assignments, :groups

  def initialize(user_ids, course, opts = {})
    opts = opts.reverse_merge(
      ignore_muted: true,
      update_all_grading_period_scores: true,
      update_course_score: true
    )

    Rails.logger.info("GRADES: calc args: user_ids=#{user_ids.inspect}")
    Rails.logger.info("GRADES: calc args: course=#{course.inspect}")
    Rails.logger.info("GRADES: calc args: opts=#{opts.inspect}")

    @course = course.is_a?(Course) ? course : Course.find(course)
    @groups = @course.assignment_groups.active
    @grading_period = opts[:grading_period]
    # if we're updating an overall course score (no grading period specified), we
    # want to first update all grading period scores for the users
    @update_all_grading_period_scores = @grading_period.nil? && opts[:update_all_grading_period_scores]
    # if we're updating a grading period score, we also need to update the
    # overall course score
    @update_course_score = @grading_period.present? && opts[:update_course_score]
    @assignments = @course.assignments.published.gradeable.to_a
    @user_ids = Array(user_ids).map { |id| Shard.relative_id_for(id, Shard.current, @course.shard) }
    @current_updates = {}
    @final_updates = {}
    @ignore_muted = opts[:ignore_muted]
  end

  # recomputes the scores and saves them to each user's Enrollment
  def self.recompute_final_score(user_ids, course_id, compute_score_opts = {})
    user_ids = Array(user_ids).uniq.map(&:to_i)
    return if user_ids.empty?
    course = Course.active.find(course_id)
    grading_period = GradingPeriod.for(course).find_by(
      id: compute_score_opts.delete(:grading_period_id)
    )
    user_ids.in_groups_of(1000, false) do |user_ids_group|
      GradeCalculator.new(
        user_ids_group,
        course_id,
        compute_score_opts.merge(grading_period: grading_period)
      ).compute_and_save_scores
    end
  end

  def compute_scores
    @submissions = @course.submissions.
        except(:order, :select).
        for_user(@user_ids).
        where(assignment_id: @assignments).
        select("submissions.id, user_id, assignment_id, score, excused, submissions.workflow_state")
    submissions_by_user = @submissions.group_by(&:user_id)

    result = []
    @user_ids.each_slice(100) do |batched_ids|
      load_assignment_visibilities_for_users(batched_ids)
      batched_ids.each do |user_id|
        user_submissions = submissions_by_user[user_id] || []
        user_submissions.select!{|s| assignment_ids_visible_to_user(user_id).include?(s.assignment_id)}
        current, current_groups = calculate_current_score(user_id, user_submissions)
        final, final_groups = calculate_final_score(user_id, user_submissions)

        scores = {
          current: current,
          current_groups: current_groups,
          final: final,
          final_groups: final_groups
        }

        result << scores
      end
      clear_assignment_visibilities_cache
    end
    result
  end

  def compute_and_save_scores
    calculate_grading_period_scores if @update_all_grading_period_scores
    compute_scores
    save_scores
    calculate_course_score if @update_course_score
  end

  private

  def calculate_grading_period_scores
    GradingPeriod.for(@course).each do |grading_period|
      # update this grading period score, and do not
      # update any other scores (grading period or course)
      # after this one
      GradeCalculator.new(
        @user_ids,
        @course,
        update_all_grading_period_scores: false,
        update_course_score: false,
        grading_period: grading_period
      ).compute_and_save_scores
    end
  end

  def calculate_course_score
    # update the overall course score now that we've finished
    # updating the grading period score
    GradeCalculator.new(
      @user_ids,
      @course,
      update_all_grading_period_scores: false,
      update_course_score: false
    ).compute_and_save_scores
  end

  def enrollments
    @enrollments ||= Enrollment.shard(@course).active.
      where(user_id: @user_ids, course_id: @course.id).
      select(:id, :user_id)
  end

  def joined_enrollment_ids
    @joined_enrollment_ids ||= enrollments.map(&:id).join(',')
  end

  def enrollments_by_user
    @enrollments_by_user ||= begin
      hsh = enrollments.group_by {|e| Shard.relative_id_for(e.user_id, Shard.current, @course.shard) }
      hsh.default = []
      hsh
    end
  end

  def save_scores
    raise "Can't save scores when ignore_muted is false" unless @ignore_muted

    return if @current_updates.empty? && @final_updates.empty?
    return if joined_enrollment_ids.blank?

    @course.touch
    updated_at = Score.sanitize(Time.now.utc)

    Score.transaction do
      # Construct upsert statement to update existing Scores or create them if needed.
      Score.connection.execute("
        UPDATE #{Score.quoted_table_name}
            SET
              current_score = CASE enrollment_id
                #{@current_updates.map do |user_id, score|
                  enrollments_by_user[user_id].map do |enrollment|
                    "WHEN #{enrollment.id} THEN #{score || 'NULL'}"
                  end.join(' ')
                end.join(' ')}
                ELSE current_score
              END,
              final_score = CASE enrollment_id
                #{@final_updates.map do |user_id, score|
                  enrollments_by_user[user_id].map do |enrollment|
                    "WHEN #{enrollment.id} THEN #{score || 'NULL'}"
                  end.join(' ')
                end.join(' ')}
                ELSE final_score
              END,
              updated_at = #{updated_at}
            WHERE
              enrollment_id IN (#{joined_enrollment_ids}) AND
              workflow_state <> 'deleted' AND
              grading_period_id #{@grading_period ? "= #{@grading_period.id}" : 'IS NULL'};
        INSERT INTO #{Score.quoted_table_name}
            (enrollment_id, grading_period_id, current_score, final_score, created_at, updated_at)
            SELECT
              enrollments.id as enrollment_id,
              #{@grading_period.try(:id) || 'NULL'} as grading_period_id,
              CASE enrollments.id
                #{@current_updates.map do |user_id, score|
                  enrollments_by_user[user_id].map do |enrollment|
                    "WHEN #{enrollment.id} THEN #{score || 'NULL'}"
                  end.join(' ')
                end.join(' ')}
                ELSE NULL
              END :: float AS current_score,
              CASE enrollments.id
                #{@final_updates.map do |user_id, score|
                  enrollments_by_user[user_id].map do |enrollment|
                    "WHEN #{enrollment.id} THEN #{score || 'NULL'}"
                  end.join(' ')
                end.join(' ')}
                ELSE NULL
              END :: float AS final_score,
              #{updated_at} as created_at,
              #{updated_at} as updated_at
            FROM #{Enrollment.quoted_table_name} enrollments
            LEFT OUTER JOIN #{Score.quoted_table_name} scores on
              scores.enrollment_id = enrollments.id AND
              scores.workflow_state <> 'deleted' AND
              scores.grading_period_id #{@grading_period ? "= #{@grading_period.id}" : 'IS NULL'}
            WHERE
              enrollments.id IN (#{joined_enrollment_ids}) AND
              scores.id IS NULL;
      ")
    end
  end

  # The score ignoring unsubmitted assignments
  def calculate_current_score(user_id, submissions)
    calculate_score(submissions, user_id, true)
  end

  # The final score for the class, so unsubmitted assignments count as zeros
  def calculate_final_score(user_id, submissions)
    calculate_score(submissions, user_id, false)
  end

  def calculate_score(submissions, user_id, ignore_ungraded)
    group_sums = create_group_sums(submissions, user_id, ignore_ungraded)
    info = calculate_total_from_group_scores(group_sums)
    Rails.logger.info "GRADES: calculated: #{info.inspect}"

    updates_hash = ignore_ungraded ? @current_updates : @final_updates
    updates_hash[user_id] = info[:grade]

    [info, group_sums.index_by { |s| s[:id] }]
  end

  # returns information about assignments groups in the form:
  # [
  #   {
  #    :id       => 1
  #    :score    => 5,
  #    :possible => 7,
  #    :grade    => 71.42,
  #    :weight   => 50},
  #   ...]
  # each group
  def create_group_sums(submissions, user_id, ignore_ungraded=true)
    visible_assignments = @assignments
    visible_assignments = visible_assignments.select{|a| assignment_ids_visible_to_user(user_id).include?(a.id)}

    if @grading_period
      user = @course.users.find(user_id)
      visible_assignments = @grading_period.assignments_for_student(visible_assignments, user)
    end
    assignments_by_group_id = visible_assignments.group_by(&:assignment_group_id)
    submissions_by_assignment_id = Hash[
      submissions.map { |s| [s.assignment_id, s] }
    ]

    @groups.map do |group|
      assignments = assignments_by_group_id[group.id] || []

      group_submissions = assignments.map do |a|
        s = submissions_by_assignment_id[a.id]

        # ignore submissions for muted assignments
        s = nil if @ignore_muted && a.muted?

        # ignore pending_review quiz submissions
        s = nil if ignore_ungraded && s.try(:pending_review?)

        {
          assignment: a,
          submission: s,
          score: s && s.score,
          total: a.points_possible || 0,
          excused: s && s.excused?,
        }
      end

      group_submissions.reject! { |s| s[:score].nil? } if ignore_ungraded
      group_submissions.reject! { |s| s[:excused] }
      group_submissions.reject! { |s| s[:assignment].omit_from_final_grade? }
      group_submissions.each { |s| s[:score] ||= 0 }

      logged_submissions = group_submissions.map { |s| loggable_submission(s) }
      Rails.logger.info "GRADES: calculating for assignment_group=#{group.global_id} user=#{user_id}"
      Rails.logger.info "GRADES: calculating... ignore_ungraded=#{ignore_ungraded}"
      Rails.logger.info "GRADES: calculating... submissions=#{logged_submissions.inspect}"

      kept = drop_assignments(group_submissions, group.rules_hash)

      score, possible = kept.reduce([0, 0]) { |(s_sum,p_sum),s|
        [s_sum + s[:score], p_sum + s[:total]]
      }

      {
        :id       => group.id,
        :score    => score,
        :possible => possible,
        :weight   => group.group_weight,
        :grade    => ((score.to_f / possible * 100).round(2) if possible > 0),
      }.tap { |group_grade_info|
        Rails.logger.info "GRADES: calculated #{group_grade_info.inspect}"
      }
    end
  end

  def load_assignment_visibilities_for_users(user_ids)
    @assignment_ids_visible_to_user ||= begin
      AssignmentStudentVisibility.shard(@course)
        .visible_assignment_ids_in_course_by_user(
          course_id: @course.id,
          user_id: user_ids.map { |u| Shard.global_id_for(u) }, # hack to always find cross-shard enrollments
          use_global_id: true
        )
    end
  end

  def clear_assignment_visibilities_cache
    @assignment_ids_visible_to_user = nil
  end

  def assignment_ids_visible_to_user(user_id)
    @assignment_ids_visible_to_user[Shard.global_id_for(user_id)]
  end

  # see comments for dropAssignments in grade_calculator.coffee
  def drop_assignments(submissions, rules)
    drop_lowest    = rules[:drop_lowest] || 0
    drop_highest   = rules[:drop_highest] || 0
    never_drop_ids = rules[:never_drop] || []
    return submissions if drop_lowest.zero? && drop_highest.zero?

    Rails.logger.info "GRADES: dropping assignments! #{rules.inspect}"

    cant_drop = []
    if never_drop_ids.present?
      cant_drop, submissions = submissions.partition { |s|
        never_drop_ids.include? s[:assignment].id
      }
    end

    # fudge the drop rules if there aren't enough submissions
    return cant_drop if submissions.empty?
    drop_lowest = submissions.size - 1 if drop_lowest >= submissions.size
    drop_highest = 0 if drop_lowest + drop_highest >= submissions.size

    keep_highest = submissions.size - drop_lowest
    keep_lowest  = keep_highest - drop_highest

    submissions.sort! { |a,b| a[:assignment].id - b[:assignment].id }

    # assignment groups that have no points possible have to be dropped
    # differently (it's a simpler case, but not one that fits in with our
    # usual bisection approach)
    kept = (cant_drop + submissions).any? { |s| s[:total] > 0 } ?
      drop_pointed(submissions, cant_drop, keep_highest, keep_lowest) :
      drop_unpointed(submissions, keep_highest, keep_lowest)

    (kept + cant_drop).tap do |all_kept|
      loggable_kept = all_kept.map { |s| loggable_submission(s) }
      Rails.logger.info "GRADES.calculating... kept=#{loggable_kept.inspect}"
    end
  end

  def drop_unpointed(submissions, keep_highest, keep_lowest)
    sorted_submissions = submissions.sort_by { |s| s[:score] }
    sorted_submissions.last(keep_highest).first(keep_lowest)
  end

  def drop_pointed(submissions, cant_drop, n_highest, n_lowest)
    max_total = (submissions + cant_drop).map { |s| s[:total] }.max

    kept = keep_highest(submissions, cant_drop, n_highest, max_total)
    kept = keep_lowest(kept, cant_drop, n_lowest, max_total)
  end

  def keep_highest(submissions, cant_drop, keep, max_total)
    keep_helper(submissions, cant_drop, keep, max_total) { |*args| big_f_best(*args) }
  end

  def keep_lowest(submissions, cant_drop, keep, max_total)
    keep_helper(submissions, cant_drop, keep, max_total) { |*args| big_f_worst(*args) }
  end

  # @submissions: set of droppable submissions
  # @cant_drop: submissions that are not eligible for dropping
  # @keep: number of submissions to keep from +submissions+
  # @max_total: the highest number of points possible
  # @big_f_blk: sorting block for the big_f function
  # returns +keep+ +submissions+
  def keep_helper(submissions, cant_drop, keep, max_total, &big_f_blk)
    return submissions if submissions.size <= keep

    unpointed, pointed = (submissions + cant_drop).partition { |s|
      s[:total].zero?
    }
    grades = pointed.map { |s| s[:score].to_f / s[:total] }.sort

    q_high = estimate_q_high(pointed, unpointed, grades)
    q_low  = grades.first
    q_mid  = (q_low + q_high) / 2

    x, kept = big_f_blk.call(q_mid, submissions, cant_drop, keep)
    threshold = 1 / (2 * keep * max_total**2)
    until q_high - q_low < threshold
      x < 0 ?
        q_high = q_mid :
        q_low  = q_mid
      q_mid = (q_low + q_high) / 2

      # bail if we can't can't ever satisfy the threshold (floats!)
      break if q_mid == q_high || q_mid == q_low

      x, kept = big_f_blk.call(q_mid, submissions, cant_drop, keep)
    end

    kept
  end

  def big_f(q, submissions, cant_drop, keep, &sort_blk)
    kept = submissions.map { |s|
      rated_score = s[:score] - q * s[:total]
      [rated_score, s]
    }.sort(&sort_blk).first(keep)

    q_kept = kept.reduce(0) { |sum,(rated_score,_)| sum + rated_score }
    q_cant_drop = cant_drop.reduce(0) { |sum,s| sum + (s[:score] - q * s[:total]) }

    [q_kept + q_cant_drop, kept.map(&:last)]
  end

  # we can't use the student's highest grade as an upper-bound for bisection
  # when 0-points-possible assignments are present, so guess the best possible
  # grade the student could have earned in that case
  def estimate_q_high(pointed, unpointed, grades)
    if unpointed.present?
      points_possible = pointed.reduce(0) { |sum,s| sum + s[:total] }
      best_pointed_score = [
        points_possible,                              # 100%
        pointed.reduce(0) { |sum,s| sum + s[:score] } # ... or extra credit
      ].max
      unpointed_score = unpointed.reduce(0) { |sum,s| sum + s[:score] }
      max_score = best_pointed_score + unpointed_score
      max_score.to_f / points_possible
    else
      grades.last
    end
  end

  # determines the best +keep+ assignments from submissions for the given q
  # (suitable for use with drop_lowest)
  def big_f_best(q, submissions, cant_drop, keep)
    big_f(q, submissions, cant_drop, keep) { |(a,_),(b,_)| b <=> a }
  end

  # determines the worst +keep+ assignments from submissions for the given q
  # (suitable for use with drop_highest)
  def big_f_worst(q, submissions, cant_drop, keep)
    big_f(q, submissions, cant_drop, keep) { |(a,_),(b,_)| a <=> b }
  end

  # returns grade information from all the assignment groups
  def calculate_total_from_group_scores(group_sums)
    if @course.group_weighting_scheme == 'percent'
      relevant_group_sums = group_sums.reject { |gs|
        gs[:possible].zero? || gs[:possible].nil?
      }
      final_grade = relevant_group_sums.reduce(0) { |grade,gs|
        grade + (gs[:score].to_f / gs[:possible]) * gs[:weight]
      }

      # scale the grade up if total weights don't add up to 100%
      full_weight = relevant_group_sums.reduce(0) { |w,gs| w + gs[:weight] }
      if full_weight.zero?
        final_grade = nil
      elsif full_weight < 100
        final_grade *= 100.0 / full_weight
      end

      {:grade => final_grade.try(:round, 2)}
    else
      total, possible = group_sums.reduce([0,0]) { |(m,n),gs|
        [m + gs[:score], n + gs[:possible]]
      }
      if possible > 0
        final_grade = (total.to_f / possible) * 100
        {
          :grade => final_grade.round(2),
          :total => total.to_f,
          :possible => possible,
        }
      else
        {:grade => nil, :total => total.to_f}
      end
    end
  end

  # this takes a wrapped submission (like from create_group_sums)
  def loggable_submission(wrapped_submission)
    {
      assignment_id: wrapped_submission[:assignment].id,
      score: wrapped_submission[:score],
      total: wrapped_submission[:total],
    }
  end
end
