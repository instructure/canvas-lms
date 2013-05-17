/**
 * Copyright (C) 2011 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'INST' /* INST */,
  'i18n!gradebook',
  'jquery' /* $ */,
  'underscore',
  'compiled/grade_calculator',
  'compiled/util/round',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* getFormData */,
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'media_comments' /* mediaComment, mediaCommentThumbnail */
], function(INST, I18n, $, _, GradeCalculator, round) {

  function updateStudentGrades() {
    var ignoreUngradedSubmissions = $("#only_consider_graded_assignments").attr('checked');
    var currentOrFinal = ignoreUngradedSubmissions ? 'current' : 'final';

    var calculatedGrades = GradeCalculator.calculate(
      ENV.submissions,
      ENV.assignment_groups,
      ENV.group_weighting_scheme
    );

    // mark dropped assignments
    $('.student_assignment').find('.points_possible').attr('aria-label', '');
    _.chain(calculatedGrades.group_sums).map(function(groupSum) {
      return groupSum[currentOrFinal].submissions;
    }).flatten().each(function(s) {
      $('#submission_' + s.submission.assignment_id).toggleClass('dropped', !!s.drop);
    });
    $('.dropped').attr('aria-label', I18n.t('titles.dropped_assignment_no_total', 'This assignment will not be considered in the total calculation'));

    var calculateGrade = function(score, possible) {
      if (possible === 0 || isNaN(score)) {
        grade = "N/A"
      } else {
        grade = Math.round((score / possible) * 1000) / 10;
      }
      return grade;
    };

    for (var i = 0; i < calculatedGrades.group_sums.length; i++) {
      var groupSum = calculatedGrades.group_sums[i];
      var $groupRow = $('#submission_group-' + groupSum.group.id);
      var groupGradeInfo = groupSum[currentOrFinal];
      $groupRow.find('.grade').text(
        calculateGrade(groupGradeInfo.score, groupGradeInfo.possible)
      );
      $groupRow.find('.score_teaser').text(
        round(groupGradeInfo.score, 2) + ' / ' + round(groupGradeInfo.possible, 2)
      );
    }

    var finalScore = calculatedGrades[currentOrFinal].score;
    var finalPossible = calculatedGrades[currentOrFinal].possible;
    var finalGrade = calculateGrade(finalScore, finalPossible);
    var $finalGradeRow = $(".student_assignment.final_grade");
    $finalGradeRow.find(".grade").text(finalGrade);
    $finalGradeRow.find(".score_teaser").text(
      round(finalScore, 2) + ' / ' + round(finalPossible, 2)
    );

    if(window.grading_scheme) {
      $(".final_letter_grade .grade").text(GradeCalculator.letter_grade(grading_scheme, finalGrade));
    }

    $(".revert_all_scores").showIf($("#grades_summary .revert_score_link").length > 0);
  }


  $(document).ready(function() {
    updateStudentGrades();
    $(".revert_all_scores_link").click(function(event) {
      event.preventDefault();
      $("#grades_summary .revert_score_link").each(function() {
        $(this).trigger('click', true);
      });
      $("#.show_guess_grades.exists").show();
      updateStudentGrades();
    });
    $("tr.student_assignment").mouseover(function() {
      if($(this).hasClass('dropped')) {
        $(this).attr('title', I18n.t('titles.dropped_assignment_no_total', 'This assignment will not be considered in the total calculation'));
      } else {
        $(this).attr('title', '');
      }
    });
    $(".toggle_comments_link").click(function(event) {
      event.preventDefault();
      var $row = $( '#' + $(this).attr('aria-controls') );

      $row.toggle();
      $row.attr('aria-expanded', $row.is(':visible'));
    });
    $(".toggle_rubric_assessments_link").click(function(event) {
      event.preventDefault();
      $(this).parents("tr.student_assignment").next("tr.comments").next("tr.rubric_assessments").toggle();
    });
    $('.student_assignment.editable .assignment_score').click(function(event) {
      if ($('#grades_summary.editable').length === 0 || $(this).find('#grade_entry').length > 0 || $(event.target).closest('.revert_score_link').length > 0) {
        return;
      }
      if (!$(this).find('.grade').data('originalValue')){
        $(this).find('.grade').data('originalValue', $(this).find('.grade').html());
      }
      $(this).find('.grade').empty().append($("#grade_entry"));
      $(this).find('.score_value').hide();
      var val = $(this).parents('.student_assignment').find('.score').text();
      $('#grade_entry').val(parseFloat(val)).show().focus().select();
    });
    $("#grade_entry").keydown(function(event) {
      if(event.keyCode == 13) {
        $(this)[0].blur();
      } else if(event.keyCode == 27) {
        var val = $(this).parents(".student_assignment")
          .addClass('dont_update')
          .find(".original_score").text();
        $(this).val(val || "")[0].blur();
      }
    });
    $('#grades_summary .student_assignment').bind('score_change', function(event, update) {
      var $assignment   = $(this),
          originalScore = $assignment.find('.original_score').text(),
          originalVal   = parseFloat(originalScore),
          val           = parseFloat($assignment.find('#grade_entry').val() || $(this).find('.score').text()),
          isChanged;

      if (isNaN(originalVal)) { originalVal = null; }
      if (isNaN(val)) { val = null; }
      if (!val && val !== 0) { val = originalVal; }
      isChanged = (originalVal != val);
      if (val == parseInt(val, 10)) {
        val = val + '.0';
      }
      $assignment.find('.score').text(val);
      if ($assignment.hasClass('dont_update')) {
        update = false;
        $assignment.removeClass('dont_update');
      }
      if (update) {
        var assignment_id = $assignment.getTemplateData({ textValues: ['assignment_id'] }).assignment_id,
            url           = $.replaceTags($('.update_submission_url').attr('href'), 'assignment_id', assignment_id);
        if (!isChanged) { val = null; }
        $.ajaxJSON(url, 'PUT', { 'submission[student_entered_score]': val }, function(data) {
          data = {student_entered_score: data.submission.student_entered_score};
          $assignment.fillTemplateData({ data: data });
        }, $.noop);
        if(!isChanged) { val = originalVal; }
      }
      $('#grade_entry').hide().appendTo($('body'));
      if (isChanged) {
        $assignment.find(".assignment_score").attr('title', '')
          .find(".score_teaser").text(I18n.t('titles.hypothetical_score', "This is a What-If score")).end()
          .find(".score_holder").append($("#revert_score_template").clone(true).attr('id', '').show())
          .find(".grade").addClass('changed');
      } else {
        var tooltip = $assignment.data('muted') ?
          I18n.t('student_mute_notification', 'Instructor is working on grades') :
          I18n.t('click_to_change', 'Click to test a different score');
        $assignment.find(".assignment_score").attr('title', I18n.t('click_to_change', 'Click to test a different score'))
          .find(".score_teaser").text(tooltip).end()
          .find(".grade").removeClass('changed');
        $assignment.find(".revert_score_link").remove();
      }
      if (val === 0) { val = '0.0'; }
      if (val === originalVal) { val = originalScore; }
      $assignment.find('.grade').html(val || $assignment.find('.grade').data('originalValue'));
      if (update) {
        updateScoreForAssignment(assignment_id, val);
      }
      updateStudentGrades();
    });
    $("#grade_entry").blur(function() {
      var $assignment = $(this).parents(".student_assignment");
      $assignment.find(".score").text($(this).val());
      $assignment.triggerHandler('score_change', true);
    });
    $("#grades_summary").delegate('.revert_score_link', 'click', function(event, skipEval) {
      event.preventDefault();
      event.stopPropagation();
      var $assignment = $(this).parents(".student_assignment"),
          val         = $assignment.find(".original_score").text(),
          tooltip     = $assignment.data('muted') ?
            I18n.t('student_mute_notification', 'Instructor is working on grades') :
            I18n.t('click_to_change', 'Click to test a different score');
      $assignment.find(".score").text(val);
      $assignment.data('muted') ? $assignment.find('.grade').html('<img alt="Muted" class="muted_icon" src="/images/sound_mute.png?1318436336">') : $assignment.find(".grade").text(val || "-");
      $assignment.find(".assignment_score").attr('title', I18n.t('click_to_change', 'Click to test a different score'))
        .find(".score_teaser").text(tooltip).end()
        .find(".grade").removeClass('changed');
      $assignment.find(".revert_score_link").remove();
      $assignment.find(".score_value").text(val);

      var assignmentId = $assignment.getTemplateValue('assignment_id');
      updateScoreForAssignment(assignmentId, val);
      if(!skipEval) {
        updateStudentGrades();
      }
    });
    $("#grades_summary:not(.editable) .assignment_score").css('cursor', 'default');
    $("#grades_summary tr").hover(function() {
      $(this).find("th.title .context").addClass('context_hover');
    }, function() {
      $(this).find("th.title .context").removeClass('context_hover');
    });
    $(".show_guess_grades_link").click(function(event) {
      $("#grades_summary .student_entered_score").each(function() {
        var val = parseFloat($(this).text(), 10);
        if(!isNaN(val) && (val || val === 0)) {
          var $assignment = $(this).parents(".student_assignment");
          $assignment.find(".score").text(val);
          $assignment.find(".score_value").hide();
          $assignment.triggerHandler('score_change', false);
        }
      });
      $(".show_guess_grades").hide();
    });
    $("#grades_summary .student_entered_score").each(function() {
      var val = parseFloat($(this).text(), 10);
      if(!isNaN(val) && val) {
        $(".show_guess_grades").show().addClass('exists');
      }
    });
    $(".comments .play_comment_link").mediaCommentThumbnail('normal');
    $(".play_comment_link").live('click', function(event) {
      event.preventDefault();
      var $parent = $(this).parents(".comment_media"),
          comment_id = $parent.getTemplateData({textValues: ['media_comment_id']}).media_comment_id;
      if(comment_id) {
        var mediaType = 'any';
        if ($(this).hasClass('video_comment'))
          mediaType = 'video';
        else if ($(this).hasClass('audio_comment'))
          mediaType = 'audio';
        $parent.children(":not(.media_comment_content)").remove();
        $parent.find(".media_comment_content").mediaComment('show_inline', comment_id, mediaType);
      }
    });
    $("#only_consider_graded_assignments").change(function() {
      updateStudentGrades();
    }).triggerHandler('change');
    $("#show_all_details_link").click(function(event) {
      event.preventDefault();
      $("tr.comments").show();
      $("tr.rubric_assessments").show();
    });
    $.scrollSidebar();
    $("#observer_user_url").change(function() {
      if(location.href != $(this).val()) {
        location.href = $(this).val();
      }
    });
  });

  function updateScoreForAssignment(assignmentId, score) {
    var submission = _.find(ENV.submissions, function(s) {
      return s.assignment_id == assignmentId;
    });
    submission.score = score;
  }
});

