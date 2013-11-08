class GradeSummaryAssignmentPresenter
  attr_reader :assignment, :submission

  def initialize(summary, current_user, assignment, submission)
    @summary = summary
    @current_user = current_user
    @assignment = assignment
    @submission = submission
  end

  def hide_distribution_graphs?
    submission_count = @summary.submission_counts[assignment.id] || 0
    submission_count < 5 || assignment.context.hide_distribution_graphs?
  end

  def is_unread?
    (submission.present? ? @summary.unread_submission_ids.include?(submission.id) : false)
  end

  def graded?
    submission && submission.grade && !assignment.muted?
  end

  def is_letter_graded?
    assignment.grading_type == 'letter_grade'
  end

  def is_assignment?
    assignment.class.to_s == "Assignment"
  end

  def has_no_group_weight?
    !(assignment.group_weight rescue false)
  end

  def has_no_score_display?
    assignment.muted? || submission.nil?
  end

  def unchangeable?
    (!@summary.editable? || assignment.special_class)
  end

  def has_comments?
    submission && submission.visible_submission_comments && !submission.visible_submission_comments.empty?
  end

  def has_scoring_details?
    submission && submission.score && assignment.points_possible && assignment.points_possible > 0 && !assignment.muted?
  end

  def has_grade_distribution?
    assignment && assignment.points_possible && assignment.points_possible > 0 && !assignment.muted?
  end

  def has_rubric_assessments?
    !rubric_assessments.empty?
  end

  def is_text_entry?
    submission.submission_type == 'online_text_entry'
  end

  def is_online_upload?
    submission.submission_type == 'online_upload'
  end

  def should_display_details?
    !assignment.special_class && (has_comments? || has_scoring_details?)
  end

  def hide_max_scores?
    assignment && assignment.hide_max_scores_for_assignments
  end

  def hide_min_scores?
    assignment && assignment.hide_min_scores_for_assignments
  end

  def show_all_scores?
    assignment && !hide_max_scores? && !hide_min_scores?
  end

  def special_class
    assignment.special_class ? ("hard_coded " + assignment.special_class) : "editable"
  end

  def published_grade
    is_letter_graded? ? "(#{submission.published_grade})" : ''
  end

  def display_score
    if has_no_score_display?
      ''
    else
      "#{submission.published_score} #{published_grade}"
    end
  end

  def turnitin
    t = if is_text_entry?
      submission.turnitin_data && submission.turnitin_data[submission.asset_string]
    elsif is_online_upload? && file
      submission.turnitin_data[file.asset_string]
    else
      nil
    end
    t.try(:[], :state) ? t : nil
  end

  def grade_distribution
    @grade_distribution ||= begin
      stats = @summary.assignment_stats[assignment.id]
      [stats.max.to_f.round(1),
       stats.min.to_f.round(1),
       stats.avg.to_f.round(1)]
    end
  end

  def graph
    @graph ||= begin
      high, low, mean = grade_distribution
      score = submission && submission.score
      GradeSummaryGraph.new(high, low, mean, assignment.points_possible, score)
    end
  end

  def file
    @file ||= submission.attachments.detect{|a| submission.turnitin_data && submission.turnitin_data[a.asset_string] }
  end

  def comments
    submission.visible_submission_comments
  end

  def rubric_assessments
    @visible_rubric_assessments ||= begin
      if submission && !assignment.muted?
        assessments = submission.rubric_assessments.select { |a| a.grants_rights?(@current_user, :read)[:read] }
        assessments.sort_by { |a| [a.assessment_type == 'grading' ? SortFirst : SortLast, a.assessor_name] }
      else
        []
      end
    end
  end

  def group
    @group ||= assignment && assignment.assignment_group
  end
end


class GradeSummaryGraph
  FULLWIDTH = 150.0

  def initialize(high, low, mean, points_possible, score)
    @high = high.to_f
    @mean = mean.to_f
    @low = low.to_f
    @points_possible = points_possible.to_f
    @score = score
  end

  def low_width
    pixels_for(@low)
  end

  def high_left
    pixels_for(@high)
  end

  def high_width
    pixels_for(@points_possible - @high)
  end

  def mean_left
    pixels_for(@mean)
  end

  def mean_low_width
    pixels_for(@mean - @low)
  end

  def mean_high_width
    pixels_for(@high - @mean)
  end

  def max_left
    [FULLWIDTH.round, (pixels_for(@high) + 3)].max
  end

  def score_left
    pixels_for(@score) - 5
  end

  private
  def pixels_for(value)
    (value.to_f / @points_possible * FULLWIDTH).round
  end
end
