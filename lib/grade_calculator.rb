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

class GradeCalculator
  attr_reader :gradable_assignments
  attr_accessor :assignments, :groups

  def initialize(user_ids, course, **opts)
    opts = opts.reverse_merge(
      emit_live_event: true,
      ignore_muted: true,
      update_all_grading_period_scores: true,
      update_course_score: true,
      only_update_course_gp_metadata: false,
      only_update_points: false
    )

    @course = course.is_a?(Course) ? course : Course.find(course)

    @groups = opts[:groups] || @course.assignment_groups.active.to_a
    @grading_period = opts[:grading_period]
    # if we're updating an overall course score (no grading period specified), we
    # want to first update all grading period scores for the users
    @update_all_grading_period_scores = @grading_period.nil? && opts[:update_all_grading_period_scores]
    # if we're updating a grading period score, we also need to update the
    # overall course score
    @update_course_score = @grading_period.present? && opts[:update_course_score]
    @ignore_unposted_anonymous = opts.fetch(
      :ignore_unposted_anonymous,
      @course.root_account.feature_enabled?(:grade_calc_ignore_unposted_anonymous)
    )
    @gradable_assignments = (opts[:assignments] || @course.assignments.published.gradeable).to_a

    @assignments = if @ignore_unposted_anonymous
                     Assignment.preload_unposted_anonymous_submissions(@gradable_assignments)

                     # Ignore anonymous assignments with unposted submissions in the grade calculation
                     # so that we don't break anonymity prior to the assignment being posted
                     # (which is when identities are revealed)
                     @gradable_assignments.reject(&:unposted_anonymous_submissions?)
                   else
                     @gradable_assignments
                   end

    @user_ids = Array(user_ids).map { |id| Shard.relative_id_for(id, Shard.current, @course.shard) }
    @current_updates = {}
    @final_updates = {}
    @dropped_updates = {}
    @current_groups = {}
    @final_groups = {}
    # The developers of the future, I leave you this gift:
    #   If you add a new options here, make sure you also update the
    #   opts in the compute_branch method
    @emit_live_event = opts[:emit_live_event]
    @ignore_muted = opts[:ignore_muted]
    @effective_due_dates = opts[:effective_due_dates]
    @enrollments = opts[:enrollments]
    @periods = opts[:periods]
    @submissions = opts[:submissions]
    @only_update_course_gp_metadata = opts[:only_update_course_gp_metadata]
    @only_update_points = opts[:only_update_points]
  end

  # recomputes the scores and saves them to each user's Enrollment
  def self.recompute_final_score(user_ids, course_id, **compute_score_opts)
    user_ids = Array(user_ids).uniq.map(&:to_i)
    return if user_ids.empty?

    course = course_id.is_a?(Course) ? course_id : Course.active.where(id: course_id).take
    return unless course

    assignments = compute_score_opts[:assignments] || course.assignments.published.gradeable.to_a
    groups = compute_score_opts[:groups] || course.assignment_groups.active.to_a
    periods = compute_score_opts[:periods] || GradingPeriod.for(course)
    grading_period_id = compute_score_opts.delete(:grading_period_id)
    grading_period = periods.find_by(id: grading_period_id) if grading_period_id
    opts = compute_score_opts.reverse_merge(
      grading_period:,
      assignments:,
      groups:,
      periods:
    )
    user_ids.sort.in_groups_of(100, false) do |user_ids_group|
      GradeCalculator.new(user_ids_group, course, **opts).compute_and_save_scores
    end
  end

  def submissions
    @submissions ||= begin
      submissions = @course.submissions
                           .except(:order, :select)
                           .for_user(@user_ids)
                           .where(assignment_id: @assignments)
                           .select("submissions.id, user_id, assignment_id, score, excused, submissions.workflow_state, submissions.posted_at")
                           .preload(:assignment)

      submissions
    end
  end

  def compute_scores
    scores_and_group_sums = []
    @user_ids.each_slice(100) do |batched_ids|
      scores_and_group_sums_batch = compute_scores_and_group_sums_for_batch(batched_ids)
      scores_and_group_sums.concat(scores_and_group_sums_batch)
    end
    scores_and_group_sums
  end

  def compute_and_save_scores
    calculate_grading_period_scores if @update_all_grading_period_scores
    compute_scores
    scores_prior_to_compute = Score.where(enrollment: @enrollments.map(&:id), assignment_group_id: nil, course_score: true).to_a
    save_scores
    update_score_statistics
    # The next line looks weird, but it is intended behaviour.  Its
    # saying "if we're on the branch not calculating hidden scores, run
    # the branch that does."
    calculate_hidden_scores if @ignore_muted

    # Since we @emit_live_event only in the outer call when @ignore_muted is true, this has to be
    # done after calculate_hidden_scores -- so changes in that inner call are also captured. But
    # it must be done before calculate_course_score so if @update_course_score is true (we are
    # scoring a grading period, not a course) we don't trigger an additional alert/live event here.
    create_course_grade_alerts_and_live_events(scores_prior_to_compute)

    calculate_course_score if @update_course_score
  end

  private

  def effective_due_dates
    @effective_due_dates ||= EffectiveDueDates.for_course(@course, @assignments).filter_students_to(@user_ids)
  end

  def observer_ids
    @observer_ids ||= ObserverEnrollment.where.not(workflow_state: [:rejected, :deleted])
                                        .where(course: @course)
                                        .pluck(:user_id)
                                        .uniq
  end

  def create_course_grade_alerts_and_live_events(scores)
    @course.shard.activate do
      ActiveRecord::Associations.preload(scores, :enrollment)
      # Make only one alert per user even if they have multiple enrollments (sections in same course)
      scores = scores.uniq { |s| s.enrollment.user_id }

      scores.each_slice(100) do |scores_batch|
        scores_info = scores_batch.each_with_object({ student_ids: [], ids: [] }) do |score, memo|
          memo[:student_ids] << score.enrollment.user_id
          memo[:ids] << score.id
        end

        preloaded_thresholds = ObserverAlertThreshold.active
                                                     .where(user_id: scores_info[:student_ids], alert_type: ["course_grade_high", "course_grade_low"])
                                                     .group_by(&:user_id)

        reloaded_scores = Score.where(id: scores_info[:ids]).index_by(&:id)
        scores_batch.each do |score|
          reloaded_score = reloaded_scores[score.id]
          # NOTE: only the old score has enrollment pre-loaded
          create_course_grade_live_event(score, reloaded_score) if @emit_live_event

          thresholds = preloaded_thresholds.fetch(score.enrollment.user_id, [])
          create_course_grade_alert(score, reloaded_score, thresholds)
        end
      end
    end
  end

  LIVE_EVENT_FIELDS = %i[current_score final_score unposted_current_score unposted_final_score].freeze

  def create_course_grade_live_event(old_score, score)
    return if LIVE_EVENT_FIELDS.all? { |f| old_score.send(f) == score.send(f) }

    old_score_values = LIVE_EVENT_FIELDS.index_with { |f| old_score.send(f) }
    Canvas::LiveEvents.course_grade_change(score, old_score_values, old_score.enrollment)
  end

  def create_course_grade_alert(old_score, score, thresholds)
    thresholds.each do |threshold|
      next unless threshold.did_pass_threshold(old_score.current_score, score.current_score)
      next unless observer_ids.include?(threshold.observer_id)

      ObserverAlert.create(observer_id: threshold.observer_id,
                           user_id: threshold.user_id,
                           observer_alert_threshold: threshold,
                           context: @course,
                           action_date: score.updated_at,
                           alert_type: threshold.alert_type,
                           title: I18n.t("Course grade: %{grade}% in %{course_code}", {
                                           grade: score.current_score,
                                           course_code: @course.course_code
                                         }))
    end
  end

  def compute_scores_and_group_sums_for_batch(user_ids)
    user_ids.filter_map do |user_id|
      next unless enrollments_by_user[user_id].first

      group_sums = compute_group_sums_for_user(user_id)
      scores = compute_scores_for_user(user_id, group_sums)
      update_changes_hash_for_user(user_id, scores, group_sums)
      {
        current: scores[:current],
        current_groups: group_sums[:current].index_by { |group| group[:id] },
        final: scores[:final],
        final_groups: group_sums[:final].index_by { |group| group[:id] }
      }
    end
  end

  def assignment_visible_to_student?(assignment_id, user_id)
    effective_due_dates.find_effective_due_date(user_id, assignment_id).key?(:due_at)
  end

  def compute_group_sums_for_user(user_id)
    user_submissions = submissions_by_user.fetch(user_id, []).select do |submission|
      assignment_visible_to_student?(submission.assignment_id, user_id)
    end

    {
      current: create_group_sums(user_submissions, user_id, ignore_ungraded: true),
      final: create_group_sums(user_submissions, user_id, ignore_ungraded: false)
    }
  end

  def compute_scores_for_user(user_id, group_sums)
    if compute_course_scores_from_weighted_grading_periods?
      calculate_total_from_weighted_grading_periods(user_id)
    else
      {
        current: calculate_total_from_group_scores(group_sums[:current]),
        final: calculate_total_from_group_scores(group_sums[:final])
      }
    end
  end

  def update_changes_hash_for_user(user_id, scores, group_sums)
    @current_updates[user_id] = scores[:current]
    @final_updates[user_id] = scores[:final]
    @current_groups[user_id] = group_sums[:current]
    @final_groups[user_id] = group_sums[:final]
    @dropped_updates[user_id] = {
      current: { dropped: scores[:current][:dropped] },
      final: { dropped: scores[:final][:dropped] }
    }
  end

  def grading_period_scores(enrollment_id)
    @grading_period_scores ||= Score.active.where(
      enrollment: enrollments.map(&:id),
      grading_period: grading_periods_for_course.map(&:id)
    ).group_by(&:enrollment_id)
    @grading_period_scores[enrollment_id] || []
  end

  def calculate_total_from_weighted_grading_periods(user_id)
    enrollment = enrollments_by_user[user_id].first
    grading_period_scores = grading_period_scores(enrollment.id)
    scores = apply_grading_period_weights_to_scores(grading_period_scores)
    scale_and_round_scores(scores, grading_period_scores)
  end

  def apply_grading_period_weights_to_scores(grading_period_scores)
    grading_period_scores.each_with_object(
      { current: { full_weight: 0.0, grade: 0.0 }, final: { full_weight: 0.0, grade: 0.0 } }
    ) do |score, scores|
      weight = grading_period_weights[score.grading_period_id] || 0.0
      scores[:final][:full_weight] += weight
      scores[:current][:full_weight] += weight if score.current_score
      scores[:current][:grade] += (score.current_score || 0.0) * (weight / 100.0)
      scores[:final][:grade] += (score.final_score || 0.0) * (weight / 100.0)
    end
  end

  def scale_and_round_scores(scores, grading_period_scores)
    [:current, :final].each_with_object({ current: {}, final: {} }) do |score_type, adjusted_scores|
      score = scores[score_type][:grade]
      full_weight = scores[score_type][:full_weight]
      score = scale_score_up(score, full_weight) if full_weight < 100
      if score.abs < Float::EPSILON && score_type == :current && grading_period_scores.none?(&:current_score)
        score = nil
      end
      adjusted_scores[score_type][:grade] = score ? score.round(2) : score
      adjusted_scores[score_type][:total] = adjusted_scores[score_type][:grade]
    end
  end

  def scale_score_up(score, weight)
    return 0.0 if weight.zero?

    (score * 100.0) / weight
  end

  def compute_course_scores_from_weighted_grading_periods?
    return @compute_from_weighted_periods if @compute_from_weighted_periods.present?

    @compute_from_weighted_periods = if @grading_period || grading_periods_for_course.empty?
                                       false
                                     else
                                       grading_periods_for_course.first.grading_period_group.weighted?
                                     end
  end

  def grading_periods_for_course
    @periods ||= GradingPeriod.for(@course)
  end

  def grading_period_weights
    @grading_period_weights ||= grading_periods_for_course.each_with_object({}) do |period, weights|
      weights[period.id] = period.weight
    end
  end

  def submissions_by_user
    @submissions_by_user ||= submissions.group_by { |s| Shard.relative_id_for(s.user_id, Shard.current, @course.shard) }
  end

  def compute_branch(**opts)
    opts = opts.reverse_merge(
      groups: @groups,
      grading_period: @grading_period,
      update_all_grading_period_scores: false,
      update_course_score: false,
      assignments: @assignments,
      emit_live_event: @emit_live_event,
      ignore_muted: @ignore_muted,
      ignore_unposted_anonymous: @ignore_unposted_anonymous,
      periods: grading_periods_for_course,
      effective_due_dates:,
      enrollments:,
      submissions:,
      only_update_course_gp_metadata: @only_update_course_gp_metadata,
      only_update_points: @only_update_points
    )
    GradeCalculator.new(@user_ids, @course, **opts).compute_and_save_scores
  end

  def calculate_hidden_scores
    # re-run this calculator, except include muted assignments/unposted submissions
    compute_branch(ignore_muted: false, emit_live_event: false)
  end

  def calculate_grading_period_scores
    grading_periods_for_course.each do |grading_period|
      # update this grading period score
      compute_branch(grading_period:)
    end

    # delete any grading period scores that are no longer relevant
    grading_period_ids = grading_periods_for_course.empty? ? nil : grading_periods_for_course.map(&:id)
    @course.shard.activate do
      Score.active.joins(:enrollment)
           .where(enrollments: { user_id: @user_ids, course_id: @course.id })
           .where.not(grading_period_id: grading_period_ids)
           .update_all(workflow_state: :deleted)
    end
  end

  def calculate_course_score
    # update the overall course score now that we've finished
    # updating the grading period score
    compute_branch(grading_period: nil)
  end

  def enrollments
    @enrollments ||= Enrollment.shard(@course.shard).active
                               .where(user_id: @user_ids, course_id: @course.id)
                               .select(:id, :user_id, :workflow_state)
  end

  def joined_enrollment_ids
    # use local_id because we'll exec the query on the enrollment's shard
    @joined_enrollment_ids ||= enrollments.map(&:local_id).join(",")
  end

  def enrollments_by_user
    @enrollments_by_user ||= begin
      hsh = enrollments.group_by { |e| Shard.relative_id_for(e.user_id, Shard.current, @course.shard) }
      hsh.default = []
      hsh
    end
  end

  def number_or_null(score)
    # GradeCalculator sometimes divides by 0 somewhere,
    # resulting in NaN. Treat that as null here
    score = nil if score.try(:nan?)
    score || "NULL::float"
  end

  def group_score_rows
    enrollments_by_user.keys.map do |user_id|
      current_group_scores = @current_groups[user_id].index_by { |group| group[:global_id] }
      final_group_scores = @final_groups[user_id].index_by { |group| group[:global_id] }
      @groups.map do |group|
        agid = group.global_id
        current = current_group_scores[agid]
        final = final_group_scores[agid]
        enrollments_by_user[user_id].map do |enrollment|
          fields = [enrollment.id, group.id]

          unless @only_update_points
            fields << number_or_null(current[:grade])
            fields << number_or_null(final[:grade])
          end

          fields << number_or_null(current[:score])
          fields << number_or_null(final[:score])

          "(#{fields.join(", ")})"
        end
      end
    end.flatten
  end

  def group_dropped_rows
    enrollments_by_user.keys.map do |user_id|
      current = @current_groups[user_id].pluck(:global_id, :dropped).to_h
      final = @final_groups[user_id].pluck(:global_id, :dropped).to_h
      @groups.map do |group|
        agid = group.global_id
        hsh = {
          current: { dropped: current[agid] },
          final: { dropped: final[agid] }
        }
        enrollments_by_user[user_id].map do |enrollment|
          "(#{enrollment.id}, #{group.id}, '#{hsh.to_json}')"
        end
      end
    end.flatten
  end

  def updated_at
    @updated_at ||= Score.connection.quote(Time.now.utc)
  end

  def column_prefix
    @ignore_muted ? "" : "unposted_"
  end

  def current_score_column
    "#{column_prefix}current_score"
  end

  def final_score_column
    "#{column_prefix}final_score"
  end

  def points_column(type)
    "#{column_prefix}#{type}_points"
  end

  def update_score_statistics
    return if @grading_period   # only update score statistics when calculating course scores
    return unless @ignore_muted # only update when calculating final scores

    ScoreStatisticsGenerator.update_score_statistics_in_singleton(@course)
  end

  def save_scores
    return if @current_updates.empty? && @final_updates.empty?
    return if joined_enrollment_ids.blank?
    return if @grading_period&.deleted?

    save_scores_in_transaction
  end

  def save_scores_in_transaction
    Score.transaction do
      @course.shard.activate do
        save_course_and_grading_period_scores
        save_course_and_grading_period_metadata
        score_rows = group_score_rows
        if @grading_period.nil? && score_rows.any?
          dropped_rows = group_dropped_rows
          save_assignment_group_scores(score_rows, dropped_rows)
        end
      end
    end
  end

  def user_specific_updates(updates:, default_value:, key:)
    specific_values = updates.flat_map do |user_id, score_details|
      enrollments_by_user[user_id].map do |enrollment|
        "WHEN #{enrollment.id} THEN #{number_or_null(score_details[key])}"
      end
    end

    "#{specific_values.join(" ")} ELSE #{default_value}"
  end

  def update_values_for(column, updates: {}, key: :grade)
    return unless column

    actual_updates = user_specific_updates(updates:, default_value: "excluded.#{column}", key:)

    "#{column} = CASE excluded.enrollment_id #{actual_updates} END"
  end

  def insert_values_for(column, updates: {}, key: :grade)
    return unless column

    actual_updates = user_specific_updates(updates:, default_value: "NULL", key:)

    "CASE enrollments.id #{actual_updates} END :: float AS #{column}"
  end

  def columns_to_insert_or_update
    return @columns_to_insert_or_update if defined? @columns_to_insert_or_update

    # Use a hash with Array values to ensure ordering of data
    column_list = { columns: [], insert_values: [], update_values: [] }

    unless @only_update_points
      column_list[:columns] << current_score_column
      column_list[:insert_values] << insert_values_for(current_score_column, updates: @current_updates)
      column_list[:update_values] << update_values_for(current_score_column, updates: @current_updates)

      column_list[:columns] << final_score_column
      column_list[:insert_values] << insert_values_for(final_score_column, updates: @final_updates)
      column_list[:update_values] << update_values_for(final_score_column, updates: @final_updates)
    end

    column_list[:columns] << points_column(:current)
    column_list[:insert_values] << insert_values_for(points_column(:current), updates: @current_updates, key: :total)
    column_list[:update_values] << update_values_for(points_column(:current), updates: @current_updates, key: :total)

    column_list[:columns] << points_column(:final)
    column_list[:insert_values] << insert_values_for(points_column(:final), updates: @final_updates, key: :total)
    column_list[:update_values] << update_values_for(points_column(:final), updates: @final_updates, key: :total)

    @columns_to_insert_or_update = column_list
  end

  def save_course_and_grading_period_scores
    return if @only_update_course_gp_metadata

    # Depending on whether we're updating course scores or grading period
    # scores, we need to check our inserted values against different uniqueness
    # constraints
    conflict_target = if @grading_period.present?
                        "(enrollment_id, grading_period_id) WHERE grading_period_id IS NOT NULL"
                      else
                        "(enrollment_id) WHERE course_score"
                      end

    # Update existing course and grading period Scores or create them if needed.
    Score.connection.with_max_update_limit(enrollments.length) do
      Score.connection.execute(<<~SQL.squish)
        INSERT INTO #{Score.quoted_table_name}
            (
              enrollment_id, grading_period_id,
              #{columns_to_insert_or_update[:columns].join(", ")},
              course_score, root_account_id, created_at, updated_at
            )
            SELECT
              enrollments.id as enrollment_id,
              #{@grading_period.try(:id) || "NULL"} as grading_period_id,
              #{columns_to_insert_or_update[:insert_values].join(", ")},
              #{@grading_period ? "FALSE" : "TRUE"} AS course_score,
              #{@course.root_account_id} AS root_account_id,
              #{updated_at} as created_at,
              #{updated_at} as updated_at
            FROM #{Enrollment.quoted_table_name} enrollments
            WHERE
              enrollments.id IN (#{joined_enrollment_ids})
            ORDER BY enrollment_id
        ON CONFLICT #{conflict_target}
        DO UPDATE SET
            #{columns_to_insert_or_update[:update_values].join(", ")},
            updated_at = excluded.updated_at,
            root_account_id = #{@course.root_account_id},
            /* if workflow_state was previously deleted for some reason, update it to active */
            workflow_state = COALESCE(NULLIF(excluded.workflow_state, 'deleted'), 'active')
      SQL
    end
  rescue ActiveRecord::Deadlocked => e
    Canvas::Errors.capture_exception(:grade_calcuator, e, :warn)
    raise Delayed::RetriableError, "Deadlock in upserting course or grading period scores"
  end

  def save_course_and_grading_period_metadata
    # We only save score metadata for posted grades. This means, if we're
    # calculating unposted grades (which means @ignore_muted is false),
    # we don't want to update the score metadata. TODO: start storing the
    # score metadata for unposted grades.
    return unless @ignore_muted

    ScoreMetadata.connection.execute("
      INSERT INTO #{ScoreMetadata.quoted_table_name}
        (score_id, calculation_details, created_at, updated_at)
        SELECT
          scores.id AS score_id,
          CASE enrollments.user_id
            #{@dropped_updates.map do |user_id, dropped|
              "WHEN #{user_id} THEN cast('#{dropped.to_json}' as json)"
            end.join(" ")}
            ELSE NULL
          END AS calculation_details,
          #{updated_at} AS created_at,
          #{updated_at} AS updated_at
        FROM #{Score.quoted_table_name} scores
        INNER JOIN #{Enrollment.quoted_table_name} enrollments ON
          enrollments.id = scores.enrollment_id
        LEFT OUTER JOIN #{ScoreMetadata.quoted_table_name} metadata ON
          metadata.score_id = scores.id
        WHERE
          scores.enrollment_id IN (#{joined_enrollment_ids}) AND
          scores.assignment_group_id IS NULL AND
          #{@grading_period ? "scores.grading_period_id = #{@grading_period.id}" : "scores.course_score IS TRUE"}
        ORDER BY enrollment_id
      ON CONFLICT (score_id)
      DO UPDATE SET
        calculation_details = excluded.calculation_details,
        updated_at = excluded.updated_at
      ;
    ")
  end

  def assignment_group_columns_to_insert_or_update
    return @assignment_group_columns_to_insert_or_update if defined? @assignment_group_columns_to_insert_or_update

    column_list = {
      insert_columns: [],
      insert_values: [],
      update_columns: [],
      update_values: [],
      value_names: []
    }

    unless @only_update_points
      column_list[:value_names] << "current_score"
      column_list[:update_columns] << "#{current_score_column} = excluded.current_score"
      column_list[:insert_columns] << "val.current_score AS #{current_score_column}"

      column_list[:value_names] << "final_score"
      column_list[:update_columns] << "#{final_score_column} = excluded.final_score"
      column_list[:insert_columns] << "val.final_score AS #{final_score_column}"
    end

    column_list[:value_names] << "current_points"
    column_list[:update_columns] << "#{points_column(:current)} = excluded.current_points"
    column_list[:insert_columns] << "val.current_points AS #{points_column(:current)}"

    column_list[:value_names] << "final_points"
    column_list[:update_columns] << "#{points_column(:final)} = excluded.final_points"
    column_list[:insert_columns] << "val.final_points AS #{points_column(:final)}"

    @assignment_group_columns_to_insert_or_update = column_list
  end

  def save_assignment_group_scores(score_values, dropped_values)
    Score.connection.with_max_update_limit(score_values.length) do
      # Update existing assignment group Scores or create them if needed.
      Score.connection.execute("
        INSERT INTO #{Score.quoted_table_name} (
          enrollment_id, assignment_group_id,
          #{assignment_group_columns_to_insert_or_update[:value_names].join(", ")},
          course_score, root_account_id, created_at, updated_at
        )
          SELECT
            val.enrollment_id AS enrollment_id,
            val.assignment_group_id as assignment_group_id,
            #{assignment_group_columns_to_insert_or_update[:insert_columns].join(", ")},
            FALSE AS course_score,
            #{@course.root_account_id} AS root_account_id,
            #{updated_at} AS created_at,
            #{updated_at} AS updated_at
          FROM (VALUES #{score_values.join(",")}) val
            (
              enrollment_id,
              assignment_group_id,
              #{assignment_group_columns_to_insert_or_update[:value_names].join(", ")}
            )
          ORDER BY assignment_group_id, enrollment_id
        ON CONFLICT (enrollment_id, assignment_group_id) WHERE assignment_group_id IS NOT NULL
        DO UPDATE SET
          #{assignment_group_columns_to_insert_or_update[:update_columns].join(", ")},
          updated_at = excluded.updated_at,
          root_account_id = #{@course.root_account_id},
          workflow_state = COALESCE(NULLIF(excluded.workflow_state, 'deleted'), 'active')
      ")
    end

    # We only save score metadata for posted grades. This means, if we're
    # calculating unposted grades (which means @ignore_muted is false),
    # we don't want to update the score metadata. TODO: start storing the
    # score metadata for unposted grades.
    if @ignore_muted
      Score.connection.with_max_update_limit(dropped_values.length) do
        ScoreMetadata.connection.execute("
          INSERT INTO #{ScoreMetadata.quoted_table_name}
            (score_id, calculation_details, created_at, updated_at)
            SELECT
              scores.id AS score_id,
              CAST(val.calculation_details as json) AS calculation_details,
              #{updated_at} AS created_at,
              #{updated_at} AS updated_at
            FROM (VALUES #{dropped_values.join(",")}) val
              (enrollment_id, assignment_group_id, calculation_details)
            LEFT OUTER JOIN #{Score.quoted_table_name} scores ON
              scores.enrollment_id = val.enrollment_id AND
              scores.assignment_group_id = val.assignment_group_id
            ORDER BY score_id
          ON CONFLICT (score_id)
          DO UPDATE SET
            calculation_details = excluded.calculation_details,
            updated_at = excluded.updated_at
          ;
        ")
      end
    end
  rescue ActiveRecord::Deadlocked => e
    Canvas::Errors.capture_exception(:grade_calculator, e, :warn)
    raise Delayed::RetriableError, "Deadlock in upserting assignment group scores"
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
  def create_group_sums(submissions, user_id, ignore_ungraded: true)
    visible_assignments = @assignments.select { |assignment| assignment_visible_to_student?(assignment.id, user_id) }

    if @grading_period
      visible_assignments.select! do |assignment|
        effective_due_dates.grading_period_id_for(
          student_id: user_id,
          assignment_id: assignment.id
        ) == Shard.relative_id_for(@grading_period.id, Shard.current, @course.shard)
      end
    end

    assignments_by_group_id = visible_assignments.group_by(&:assignment_group_id)
    submissions_by_assignment_id =
      submissions.index_by(&:assignment_id)

    @groups.map do |group|
      assignments = assignments_by_group_id[group.id] || []

      group_submissions = assignments.map do |a|
        s = submissions_by_assignment_id[a.id]

        # ignore unposted submissions and all submissions for muted assignments
        s = nil if ignore_submission?(submission: s, assignment: a)

        # ignore pending_review quiz submissions
        s = nil if ignore_ungraded && s.try(:pending_review?)

        {
          assignment: a,
          submission: s,
          score: s&.score,
          total: BigDecimal(a.points_possible || 0, 15),
          excused: s&.excused?,
        }
      end

      if enrollments_by_user[user_id].all? { |e| e.workflow_state == "completed" }
        group_submissions.reject! { |s| s[:submission].nil? }
      end

      group_submissions.reject! { |s| s[:score].nil? } if ignore_ungraded
      group_submissions.reject! { |s| s[:excused] }
      group_submissions.reject! { |s| s[:assignment].omit_from_final_grade? }
      group_submissions.each { |s| s[:score] ||= 0 }

      kept = drop_assignments(group_submissions, group.rules_hash)
      dropped_submissions = (group_submissions - kept).filter_map { |s| s[:submission]&.id }

      score, possible = kept.reduce([0.0, 0.0]) do |(s_sum, p_sum), s|
        [s_sum.to_d + s[:score].to_d, p_sum.to_d + s[:total].to_d]
      end

      {
        id: group.id,
        global_id: group.global_id,
        score:,
        possible:,
        weight: group.group_weight,
        grade: ((score.to_f / possible * 100).round(2).to_f if possible > 0),
        dropped: dropped_submissions
      }
    end
  end

  # see comments for dropAssignments in grade_calculator.js
  def drop_assignments(submissions, rules)
    drop_lowest    = rules[:drop_lowest] || 0
    drop_highest   = rules[:drop_highest] || 0
    never_drop_ids = rules[:never_drop] || []
    return submissions if drop_lowest.zero? && drop_highest.zero?

    cant_drop = []
    if never_drop_ids.present?
      cant_drop, submissions = submissions.partition { |submission| never_drop_ids.include?(submission[:assignment].id) }
    end

    # fudge the drop rules if there aren't enough submissions
    return cant_drop if submissions.empty?

    drop_lowest = submissions.size - 1 if drop_lowest >= submissions.size
    drop_highest = 0 if drop_lowest + drop_highest >= submissions.size

    keep_highest = submissions.size - drop_lowest
    keep_lowest  = keep_highest - drop_highest

    submissions.sort! { |a, b| a[:assignment].id - b[:assignment].id }

    # assignment groups that have no points possible have to be dropped
    # differently (it's a simpler case, but not one that fits in with our
    # usual bisection approach)
    kept = if (cant_drop + submissions).any? { |s| s[:total] > 0 }
             drop_pointed(submissions, cant_drop, keep_highest, keep_lowest)
           else
             drop_unpointed(submissions, keep_highest, keep_lowest)
           end

    kept + cant_drop
  end

  def drop_unpointed(submissions, keep_highest, keep_lowest)
    sorted_submissions = submissions.sort_by { |s| s[:score] }
    sorted_submissions.last(keep_highest).first(keep_lowest)
  end

  def drop_pointed(submissions, cant_drop, n_highest, n_lowest)
    max_total = (submissions + cant_drop).pluck(:total).max

    kept = keep_highest(submissions, cant_drop, n_highest, max_total)
    keep_lowest(kept, cant_drop, n_lowest, max_total)
  end

  def keep_highest(submissions, cant_drop, keep, max_total)
    keep_helper(submissions, cant_drop, keep, max_total, keep_mode: :highest) { |*args| big_f_best(*args) }
  end

  def keep_lowest(submissions, cant_drop, keep, max_total)
    keep_helper(submissions, cant_drop, keep, max_total, keep_mode: :lowest) { |*args| big_f_worst(*args) }
  end

  # @param submissions [Array<Submission>] set of droppable submissions
  # @param cant_drop [Array<Submission>] submissions that are not eligible for dropping
  # @param keep [Integer] number of submissions to keep from +submissions+
  # @param max_total [Float] the highest number of points possible
  # @yield sorting block for the big_f function
  # returns +keep+ +submissions+
  def keep_helper(submissions, cant_drop, keep, max_total, keep_mode: nil)
    return submissions if submissions.size <= keep

    unpointed, pointed = (submissions + cant_drop).partition do |s|
      s[:total].zero?
    end

    kept = nil
    if pointed.empty? && keep_mode == :lowest
      # this is a really dumb situation that we saw in the wild.  17
      # assignments, 2 of them have points possible, the rest have 0
      # points possible with drop rules of drop 8 lowest and drop 7
      # highest.
      #
      # In drop_pointed above, the call to keep_highest that
      # goes here ends up eliminating the pointed assignments, so when
      # keep_lowest is called, we end up here with unpointed
      # assignments which completely breaks math. estimate_q_high
      # comes back as NaN and q_low is nil.  "(nil + NaN)/2" means
      # you're gonna have a bad time.
      #
      # What we'll do instead is just sort by score like
      # drop_unpointed above, and drop the unpointed
      # ones up to keep.
      kept = unpointed.sort_by { |s| s[:score].to_f }[-keep, keep]
    else
      grades = pointed.map { |s| s[:score].to_f / s[:total] }.sort

      q_high = estimate_q_high(pointed, unpointed, grades)
      q_low  = grades.first
      q_mid  = (q_low + q_high) / 2

      x, kept = yield(q_mid, submissions, cant_drop, keep)
      threshold = 1 / (2 * keep * (max_total**2))
      until q_high - q_low < threshold
        if x < 0
          q_high = q_mid
        else
          q_low = q_mid
        end
        q_mid = (q_low + q_high) / 2

        # bail if we can't can't ever satisfy the threshold (floats!)
        break if q_mid == q_high || q_mid == q_low

        x, kept = yield(q_mid, submissions, cant_drop, keep)
      end
    end

    kept
  end

  def big_f(q, submissions, cant_drop, keep, &)
    kept = submissions.map do |s|
      rated_score = s[:score] - (q * s[:total])
      [rated_score, s]
    end.sort(&).first(keep)

    q_kept = kept.reduce(0) { |sum, (rated_score, _)| sum + rated_score }
    q_cant_drop = cant_drop.reduce(0) { |sum, s| sum + (s[:score] - (q * s[:total])) }

    [q_kept + q_cant_drop, kept.map(&:last)]
  end

  # we can't use the student's highest grade as an upper-bound for bisection
  # when 0-points-possible assignments are present, so guess the best possible
  # grade the student could have earned in that case
  def estimate_q_high(pointed, unpointed, grades)
    if unpointed.present?
      points_possible = pointed.reduce(0) { |sum, s| sum + s[:total] }
      best_pointed_score = [
        points_possible, # 100%
        pointed.reduce(0) { |sum, s| sum + s[:score] } # ... or extra credit
      ].max
      unpointed_score = unpointed.reduce(0) { |sum, s| sum + s[:score] }
      max_score = best_pointed_score + unpointed_score
      max_score.to_f / points_possible
    else
      grades.last
    end
  end

  # determines the best +keep+ assignments from submissions for the given q
  # (suitable for use with drop_lowest)
  def big_f_best(q, submissions, cant_drop, keep)
    big_f(q, submissions, cant_drop, keep) { |(a, _), (b, _)| b <=> a }
  end

  # determines the worst +keep+ assignments from submissions for the given q
  # (suitable for use with drop_highest)
  def big_f_worst(q, submissions, cant_drop, keep)
    big_f(q, submissions, cant_drop, keep) { |(a, _), (b, _)| a <=> b }
  end

  def gather_dropped_from_group_scores(group_sums)
    dropped = group_sums.pluck(:dropped)
    dropped.flatten!
    dropped.uniq!
    dropped
  end

  # returns grade information from all the assignment groups
  def calculate_total_from_group_scores(group_sums)
    dropped = gather_dropped_from_group_scores(group_sums)

    if @course.group_weighting_scheme == "percent"
      relevant_group_sums = group_sums.reject do |gs|
        gs[:possible].zero? || gs[:possible].nil?
      end
      final_grade = relevant_group_sums.reduce(0) do |grade, gs|
        grade + ((gs[:score].to_d / gs[:possible]) * gs[:weight].to_d)
      end

      # scale the grade up if total weights don't add up to 100%
      full_weight = relevant_group_sums.reduce(0) { |w, gs| w + gs[:weight] }
      if full_weight.zero?
        final_grade = nil
      elsif full_weight < 100
        final_grade *= 100.0 / full_weight
      end

      rounded_grade = final_grade&.to_f.try(:round, 2)
      {
        grade: rounded_grade,
        total: rounded_grade,
        dropped:
      }
    else
      total, possible = group_sums.reduce([0, 0]) { |(m, n), gs| [m + gs[:score], n + gs[:possible]] }
      if possible > 0
        final_grade = (total.to_f / possible) * 100
        {
          grade: final_grade.round(2).to_f,
          total: total.to_f,
          possible: possible.to_f,
          dropped:
        }
      else
        {
          grade: nil,
          total: total.to_f,
          dropped:
        }
      end
    end
  end

  def ignore_submission?(submission:, assignment:)
    return false unless @ignore_muted

    # If we decided to ignore this submission earlier in this run (see
    # create_group_sums), it will be nil, in which case keep ignoring it
    submission.blank? || !submission.posted?
  end
end
