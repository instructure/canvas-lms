#
# Copyright (C) 2014 Instructure, Inc.
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

module GradebooksHelper
  UNGRADED_SUBMISSION_ICON_ATTRIBUTES = {
    'online_url' => {
      :icon_class => 'icon-link',
      :screenreader_text => I18n.t('icons.online_url_submission', 'Online Url Submission')
    },
    'online_text_entry' => {
      :icon_class => 'icon-text',
      :screenreader_text => I18n.t('icons.text_entry_submission', 'Text Entry Submission')
    },
    'online_upload' => {
      :icon_class => 'icon-document',
      :screenreader_text => I18n.t('icons.file_upload_submission', 'File Upload Submission')
    },
    'discussion_topic' => {
      :icon_class => 'icon-discussion',
      :screenreader_text => I18n.t('icons.discussion_submission', 'Discussion Submission')
    },
    'online_quiz' => {
      :icon_class => 'icon-quiz',
      :screenreader_text => I18n.t('icons.quiz_submission', 'Quiz Submission')
    },
    'media_recording' => {
      :icon_class => 'icon-filmstrip',
      :screenreader_text => I18n.t('icons.media_submission', 'Media Submission')
    },
  }

  PASS_FAIL_ICON_ATTRIBUTES = {
    pass: {
      icon_class: 'icon-check',
      screenreader_text: I18n.t('#gradebooks.grades.complete', 'Complete'),
    },
    fail: {
      icon_class: 'icon-x',
      screenreader_text: I18n.t('#gradebooks.grades.incomplete', 'Incomplete'),
    },
  }

  def display_grade(grade)
    grade.blank? ? "--" : grade
  end

  def student_score_display_for(submission, show_student_view = false)
    return '-' if submission.blank?
    score, grade = score_and_grade_for(submission, show_student_view)

    # Squelched icon placement for pending review items, until DB dependencies are resolved
    if submission && grade #&& submission.workflow_state != 'pending_review'
      graded_submission_display(grade, score, submission.assignment.grading_type)
    elsif submission.submission_type
      ungraded_submission_display(submission.submission_type)
    else
      '-'
    end
  end

  def graded_submission_display(grade, score, grading_type)
    if grading_type == "pass_fail"
      pass_fail_icon(score, grade)
    elsif grading_type == 'percent'
      grade
    elsif grade.to_f.round(2) == score.to_f.round(2)
      grade.to_f.round(2)
    end
  end

  def ungraded_submission_display(submission_type)
    sub_score = UNGRADED_SUBMISSION_ICON_ATTRIBUTES[submission_type]
    if sub_score
      screenreadable_icon(sub_score, %w{submission_icon})
    else
      '-'
    end
  end

  def pass_fail_icon(score, grade)
    if score && score > 0 || grade == "complete"
      icon_attrs = PASS_FAIL_ICON_ATTRIBUTES[:pass]
    else
      icon_attrs = PASS_FAIL_ICON_ATTRIBUTES[:fail]
    end
    screenreadable_icon(icon_attrs, %w{graded_icon})
  end

  def screenreadable_icon(icon_attrs, html_classes = [])
    html_classes << icon_attrs[:icon_class]
    content_tag('i', '', 'class' => html_classes.join(' '), 'aria-hidden' => true) +
      content_tag('span', icon_attrs[:screenreader_text], 'class' => 'screenreader-only')
  end

  def score_and_grade_for(submission, show_student_view = false)
    if show_student_view
      [submission.published_score, submission.published_grade]
    else
      [submission.score, submission.grade]
    end
  end
end
