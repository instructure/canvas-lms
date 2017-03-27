/**
 * Copyright (C) 2011 - 2017 Instructure, Inc.
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
  'jsx/gradebook/CourseGradeCalculator',
  'jsx/gradebook/EffectiveDueDates',
  'jsx/gradebook/GradingSchemeHelper',
  'compiled/api/gradingPeriodSetsApi',
  'compiled/util/round',
  'str/htmlEscape',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* getFormData */,
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'compiled/jquery/mediaCommentThumbnail', /* mediaCommentThumbnail */
  'media_comments' /* mediaComment, mediaCommentThumbnail */
], function (
  INST, I18n, $, _, CourseGradeCalculator, EffectiveDueDates, GradingSchemeHelper, gradingPeriodSetsApi, round,
  htmlEscape
) {

  var GradeSummary = {
    getSelectedGradingPeriodId: function () {
      var $select = document.querySelector('.grading_periods_selector');
      return ($select && $select.value !== '0') ? $select.value : null;
    }
  };

  function getGradingPeriodSet () {
    if (ENV.grading_period_set) {
      return gradingPeriodSetsApi.deserializeSet(ENV.grading_period_set);
    }
    return null;
  }

  function calculateGrades () {
    var grades;

    if (ENV.effective_due_dates && ENV.grading_period_set) {
      grades = CourseGradeCalculator.calculate(
        ENV.submissions,
        ENV.assignment_groups,
        ENV.group_weighting_scheme,
        getGradingPeriodSet(),
        EffectiveDueDates.scopeToUser(ENV.effective_due_dates, ENV.student_id)
      );
    } else {
      grades = CourseGradeCalculator.calculate(
        ENV.submissions,
        ENV.assignment_groups,
        ENV.group_weighting_scheme
      );
    }

    var selectedGradingPeriodId = GradeSummary.getSelectedGradingPeriodId();
    if (selectedGradingPeriodId) {
      return grades.gradingPeriods[selectedGradingPeriodId];
    }

    return grades;
  }

  var whatIfAssignments = [];

  function addWhatIfAssignment (assignmentId) {
    whatIfAssignments = _.unique(whatIfAssignments.concat([assignmentId]));
  }

  function removeWhatIfAssignment (assignmentId) {
    whatIfAssignments = _.without(whatIfAssignments, assignmentId);
  }

  function listAssignmentGroupsForGradeCalculation () {
    return _.map(ENV.assignment_groups, function (assignmentGroup) {
      var unmutedAssignments = _.reject(assignmentGroup.assignments, function (assignment) {
        return assignment.muted && whatIfAssignments.indexOf(assignment.id) === -1;
      })
      return _.extend({}, assignmentGroup, { assignments: unmutedAssignments });
    });
  }

  function canBeConvertedToGrade (score, possible) {
    return possible > 0 && !isNaN(score);
  }

  function calculatePercentGrade (score, possible) {
    return round((score / possible) * 100, round.DEFAULT);
  }

  function formatPercentGrade (percentGrade) {
    return I18n.n(percentGrade, {percentage: true});
  }

  function calculateGrade (score, possible) {
    if (canBeConvertedToGrade(score, possible)) {
      return formatPercentGrade(calculatePercentGrade(score, possible));
    }

    return I18n.t('N/A');
  }

  function calculateTotals (calculatedGrades, currentOrFinal, groupWeightingScheme) {
    var showTotalGradeAsPoints = ENV.show_total_grade_as_points;

    for (var i = 0; i < ENV.assignment_groups.length; i++) {
      var assignmentGroupId = ENV.assignment_groups[i].id;
      var grade = calculatedGrades.assignmentGroups[assignmentGroupId];
      var $groupRow = $('#submission_group-' + assignmentGroupId);
      if (grade) {
        grade = grade[currentOrFinal];
      } else {
        grade = { score: 0, possible: 0 };
      }
      $groupRow.find('.grade').text(
        calculateGrade(grade.score, grade.possible)
      );
      $groupRow.find('.score_teaser').text(
        I18n.n(grade.score, {precision: round.DEFAULT}) + ' / ' + I18n.n(grade.possible, {precision: round.DEFAULT})
      );
    }

    var finalScore = calculatedGrades[currentOrFinal].score;
    var finalPossible = calculatedGrades[currentOrFinal].possible;
    var scoreAsPoints = I18n.n(finalScore, {precision: round.DEFAULT}) + ' / ' + I18n.n(finalPossible, {precision: round.DEFAULT});
    var scoreAsPercent = calculateGrade(finalScore, finalPossible);

    var finalGrade;
    var teaserText;

    if (showTotalGradeAsPoints && groupWeightingScheme !== 'percent') {
      finalGrade = scoreAsPoints;
      teaserText = scoreAsPercent;
    } else {
      finalGrade = scoreAsPercent;
      teaserText = scoreAsPoints;
    }

    var $finalGradeRow = $('.student_assignment.final_grade');
    $finalGradeRow.find('.grade').text(finalGrade);
    $finalGradeRow.find('.score_teaser').text(teaserText);
    if (groupWeightingScheme === 'percent') {
      $finalGradeRow.find('.score_teaser').hide()
    }

    if ($('.grade.changed').length > 0) {
      // User changed their points for an assignment => let's let them know their updated points
      var msg = I18n.t('Based on What-If scores, the new total is now %{grade}', {grade: finalGrade});
      $.screenReaderFlashMessageExclusive(msg);
    }

    if (ENV.grading_scheme) {
      $('.final_letter_grade .grade').text(
        GradingSchemeHelper.scoreToGrade(
          calculatePercentGrade(finalScore, finalPossible), ENV.grading_scheme
        )
      );
    }

    $('.revert_all_scores').showIf($('#grades_summary .revert_score_link').length > 0);
  }

  function updateStudentGrades () {
    var droppedMessage = I18n.t('This assignment is dropped and will not be considered in the total calculation');
    var ignoreUngradedSubmissions = $('#only_consider_graded_assignments').attr('checked');
    var currentOrFinal = ignoreUngradedSubmissions ? 'current' : 'final';
    var groupWeightingScheme = ENV.group_weighting_scheme;
    var includeTotal = !ENV.exclude_total;

    var calculatedGrades = calculateGrades();

    $('.dropped').attr('aria-label', '');
    $('.dropped').attr('title', '');

    // mark dropped assignments
    $('.student_assignment').find('.points_possible').attr('aria-label', '');

    _.forEach(calculatedGrades.assignmentGroups, function (grades) {
      _.forEach(grades[currentOrFinal].submissions, function (submission) {
        $('#submission_' + submission.submission.assignment_id).toggleClass('dropped', !!submission.drop);
      });
    });

    $('.dropped').attr('aria-label', droppedMessage);
    $('.dropped').attr('title', droppedMessage);

    if (includeTotal) {
      calculateTotals(calculatedGrades, currentOrFinal, groupWeightingScheme);
    }
  }

  function updateScoreForAssignment (assignmentId, score) {
    var submission = _.find(ENV.submissions, function (s) {
      return ('' + s.assignment_id) === ('' + assignmentId);
    });
    if (submission) {
      submission.score = score;
    } else {
      ENV.submissions.push({assignment_id: assignmentId, score: score});
    }
  }

  function bindShowAllDetailsButton ($ariaAnnouncer) {
    $('#show_all_details_button').click(function (event) {
      event.preventDefault();
      var $button = $('#show_all_details_button');
      $button.toggleClass('showAll');

      if ($button.hasClass('showAll')) {
        $button.text(I18n.t('Hide All Details'));
        $('tr.student_assignment.editable').each(function () {
          var assignmentId = $(this).getTemplateValue('assignment_id');
          var muted = $(this).data('muted');
          if (!muted) {
            $('#comments_thread_' + assignmentId).show();
            $('#rubric_' + assignmentId).show();
            $('#grade_info_' + assignmentId).show();
            $('#final_grade_info_' + assignmentId).show();
          }
        });
        $ariaAnnouncer.text(I18n.t('assignment details expanded'));
      } else {
        $button.text(I18n.t('Show All Details'));
        $('tr.rubric_assessments').hide();
        $('tr.comments').hide();
        $ariaAnnouncer.text(I18n.t('assignment details collapsed'));
      }
    });
  }

  function setup () {
    $(document).ready(function () {
      updateStudentGrades();
      var showAllWhatIfButton = $(this).find('#student-grades-whatif button');
      var revertButton = $(this).find('#revert-all-to-actual-score');
      var $ariaAnnouncer = $(this).find('#aria-announcer');

      $('.revert_all_scores_link').click(function (event) {
        event.preventDefault();
        // we pass in refocus: false here so the focus won't go to the revert arrows within the grid
        $('#grades_summary .revert_score_link').each(function () {
          $(this).trigger('click', {skipEval: true, refocus: false});
        });
        $('#.show_guess_grades.exists').show();
        updateStudentGrades();
        showAllWhatIfButton.focus();
        $.screenReaderFlashMessageExclusive(I18n.t('Grades are now reverted to original scores'));
      });

      // manages toggling and screenreader focus for comments, scoring, and rubric details
      $('.toggle_comments_link, .toggle_score_details_link, ' +
        '.toggle_rubric_assessments_link, .toggle_final_grade_info').click(function (event) {
          event.preventDefault();
          var $row = $('#' + $(this).attr('aria-controls'));
          var originEl = this;

          $(originEl).attr('aria-expanded', $row.css('display') === 'none');
          $row.toggle();

          if ($row.css('display') !== 'none') {
            $row.find('.screenreader-toggle').focus();
          }
        });

      $('.screenreader-toggle').click(function (event) {
        event.preventDefault();
        var ariaControl = $(this).data('aria');
        var originEl = $("a[aria-controls='" + ariaControl + "']");

        $(originEl).attr('aria-expanded', false);
        $(originEl).focus();
        $(this).closest('.rubric_assessments, .comments').hide();
      });

      var editWhatifGrade = function (event) {
        if (event.type === 'click' || event.keyCode === 13) {
          if ($('#grades_summary.editable').length === 0 ||
              $(this).find('#grade_entry').length > 0 ||
              $(event.target).closest('.revert_score_link').length > 0) {
            return;
          }

          // Store the original score so that we can restore it after "What-If" calculations
          if (!$(this).find('.grade').data('originalValue')) {
            $(this).find('.grade').data('originalValue', $(this).find('.grade').html());
          }

          var $screenreaderLinkClone = $(this).find('.screenreader-only').clone(true);
          $(this).find('.grade').data('screenreader_link', $screenreaderLinkClone);
          $(this).find('.grade').empty().append($('#grade_entry'));
          $(this).find('.score_value').hide();
          $ariaAnnouncer.text(I18n.t('Enter a What-If score.'));

          // Get the current shown score (possibly a "What-If" score) and use it as the default value in the text entry field
          var val = $(this).parents('.student_assignment').find('.what_if_score').text();
          $('#grade_entry').val(parseFloat(val) || '0')
            .show()
            .focus()
            .select();
        }
      };

      $('.student_assignment.editable .assignment_score').on('click keypress', editWhatifGrade);

      $('#grade_entry').keydown(function (event) {
        if (event.keyCode === 13) {
          // Enter Key: Finish Changes
          $ariaAnnouncer.text('');
          $(this)[0].blur();
        } else if (event.keyCode === 27) {
          // Enter Key: Clear the Text Field
          $ariaAnnouncer.text('');
          var val = $(this).parents('.student_assignment')
            .addClass('dont_update')
            .find('.original_score')
            .text();
          $(this).val(val || '')[0].blur();
        }
      });

      $('#grades_summary .student_assignment').bind('score_change', function (event, options) {
        var $assignment = $(this);
        var originalScore = $assignment.find('.original_score').text();
        var originalVal = parseFloat(originalScore);
        var val = parseFloat($assignment.find('#grade_entry').val() || $(this).find('.what_if_score').text());
        var isChanged;
        var shouldUpdate = options.update;

        if (isNaN(originalVal)) { originalVal = null; }
        if (isNaN(val)) { val = null; }
        if (!val && val !== 0) { val = originalVal; }
        isChanged = (originalVal != val); // eslint-disable-line eqeqeq
        if (val || val === 0) { val = round(val, round.DEFAULT); }
        if (val == parseInt(val, 10)) { // eslint-disable-line eqeqeq
          val += '.0';
        }
        $assignment.find('.what_if_score').text(val);
        if ($assignment.hasClass('dont_update')) {
          shouldUpdate = false;
          $assignment.removeClass('dont_update');
        }
        var assignmentId = $assignment.getTemplateData({ textValues: ['assignment_id'] }).assignment_id;
        if (shouldUpdate) {
          var url = $.replaceTags($('.update_submission_url').attr('href'), 'assignment_id', assignmentId);
          if (!isChanged) { val = null; }
          $.ajaxJSON(url, 'PUT', { 'submission[student_entered_score]': val },
            function (data) {
              var updatedData = {student_entered_score: data.submission.student_entered_score};
              $assignment.fillTemplateData({ data: updatedData });
            },
            $.noop
          );
          if (!isChanged) { val = originalVal; }
        }
        $('#grade_entry').hide().appendTo($('body'));
        if (isChanged) {
          $assignment.find('.assignment_score').attr('title', '')
            .find('.score_teaser').text(I18n.t('This is a What-If score')).end()
            .find('.score_holder').append($('#revert_score_template').clone(true).attr('id', '').show())
            .find('.grade').addClass('changed');
          // this is to distinguish between the revert_all_scores_link in the right nav and
          // the revert arrows within the grade_summary page grid
          if (options.refocus) {
            setTimeout(function () { $assignment.find('.revert_score_link').focus(); }, 0);
          }
        } else {
          var tooltip = $assignment.data('muted') ?
            I18n.t('Instructor is working on grades') :
            I18n.t('Click to test a different score');
          $assignment.find('.assignment_score').attr('title', I18n.t('Click to test a different score'))
            .find('.score_teaser').text(tooltip).end()
            .find('.grade').removeClass('changed');
          $assignment.find('.revert_score_link').remove();
        }
        if (val === 0) { val = '0.0'; }
        if (val === originalVal) { val = originalScore; }

        var $grade = $assignment.find('.grade');
        var gradeValue = htmlEscape((val || '').trim());
        var originalValue = $grade.data('originalValue');
        $grade.html($.raw(gradeValue || originalValue));

        if (!isChanged) {
          var $screenreaderLinkClone = $assignment.find('.grade').data('screenreader_link');
          $assignment.find('.grade').prepend($screenreaderLinkClone);
          removeWhatIfAssignment(assignmentId);
        } else {
          addWhatIfAssignment(assignmentId);
        }

        updateScoreForAssignment(assignmentId, val);
        updateStudentGrades();
      });

      $('#grade_entry').blur(function () {
        var $assignment = $(this).parents('.student_assignment');
        $assignment.triggerHandler('score_change', { update: true, refocus: true });
      });

      $('#grades_summary').delegate('.revert_score_link', 'click', function (event, options) {
        var opts = _.defaults(options || {}, { refocus: true, skipEval: false });
        event.preventDefault();
        event.stopPropagation();
        var $assignment = $(this).parents('.student_assignment');
        var val = $assignment.find('.original_score').text();
        var tooltip;
        if ($assignment.data('muted')) {
          tooltip = I18n.t('Instructor is working on grades');
        } else {
          tooltip = I18n.t('Click to test a different score');
        }
        $assignment.find('.what_if_score').text(val);
        $assignment.find('.assignment_score').attr('title', I18n.t('Click to test a different score'))
          .find('.score_teaser').text(tooltip).end()
          .find('.grade').removeClass('changed');
        $assignment.find('.revert_score_link').remove();
        $assignment.find('.score_value').text(val);

        if (isNaN(parseFloat(val))) { val = null; }
        if ($assignment.data('muted')) {
          $assignment.find('.grade').html('<img alt="Muted" class="muted_icon" src="/images/sound_mute.png?1318436336">')
        } else {
          $assignment.find('.grade').text(val || '-');
        }

        var assignmentId = $assignment.getTemplateValue('assignment_id');
        removeWhatIfAssignment(assignmentId);
        updateScoreForAssignment(assignmentId, val);
        if (!opts.skipEval) {
          updateStudentGrades();
        }
        var $screenreaderLinkClone = $assignment.find('.grade').data('screenreader_link');
        $assignment.find('.grade').prepend($screenreaderLinkClone);
        // this is to distinguish between the revert_all_scores_link in the right nav and
        // the revert arrows within the grade_summary grid
        if (opts.refocus) {
          setTimeout(function () { $assignment.find('.grade').focus() }, 0);
        }
      });

      $('#grades_summary:not(.editable) .assignment_score').css('cursor', 'default');

      $('#grades_summary tr').hover(function () {
        $(this).find('th.title .context').addClass('context_hover');
      }, function () {
        $(this).find('th.title .context').removeClass('context_hover');
      });

      $('.show_guess_grades_link').click(function () {
        $('#grades_summary .student_entered_score').each(function () {
          var val = parseFloat($(this).text(), 10);
          if (!isNaN(val) && (val || val === 0)) {
            var $assignment = $(this).parents('.student_assignment');
            $assignment.find('.what_if_score').text(val);
            $assignment.find('.score_value').hide();
            $assignment.triggerHandler('score_change', { update: false, focus: false });
          }
        });
        $('.show_guess_grades').hide();
        revertButton.focus();
        $.screenReaderFlashMessageExclusive(I18n.t('Grades are now showing what-if scores'));
      });

      $('#grades_summary .student_entered_score').each(function () {
        var val = parseFloat($(this).text(), 10);
        if (!isNaN(val) && (val || val === 0)) {
          $('.show_guess_grades').show().addClass('exists');
        }
      });

      $('.comments .play_comment_link').mediaCommentThumbnail('normal');

      $('.play_comment_link').live('click', function (event) {
        event.preventDefault();
        var $parent = $(this).parents('.comment_media');
        var commentId = $parent.getTemplateData({textValues: ['media_comment_id']}).media_comment_id;
        if (commentId) {
          var mediaType = 'any';
          if ($(this).hasClass('video_comment')) {
            mediaType = 'video';
          } else if ($(this).hasClass('audio_comment')) {
            mediaType = 'audio';
          }
          $parent.children(':not(.media_comment_content)').remove();
          $parent.find('.media_comment_content').mediaComment('show_inline', commentId, mediaType);
        }
      });

      $('#only_consider_graded_assignments').change(function () {
        updateStudentGrades();
      }).triggerHandler('change');

      $('#observer_user_url').change(function () {
        if (location.href !== $(this).val()) {
          location.href = $(this).val();
        }
      });

      $('#assignment_order').change(function () {
        this.form.submit();
      });

      bindShowAllDetailsButton($ariaAnnouncer);
    });

    $(document).on('change', '.grading_periods_selector', function () {
      var newGP = $(this).val();
      var matches = location.href.match(/grading_period_id=\d*/);
      if (matches) {
        location.href = location.href.replace(matches[0], 'grading_period_id=' + newGP);
        return;
      }
      matches = location.href.match(/#tab-assignments/);
      if (matches) {
        location.href = location.href.replace(matches[0], '') + '?grading_period_id=' + newGP + matches[0];
      } else {
        location.href += '?grading_period_id=' + newGP;
      }
    });
  }

  _.extend(GradeSummary, {
    setup: setup,
    addWhatIfAssignment: addWhatIfAssignment,
    removeWhatIfAssignment: removeWhatIfAssignment,
    getGradingPeriodSet: getGradingPeriodSet,
    listAssignmentGroupsForGradeCalculation: listAssignmentGroupsForGradeCalculation,
    canBeConvertedToGrade: canBeConvertedToGrade,
    calculateGrade: calculateGrade,
    calculateGrades: calculateGrades,
    calculateTotals: calculateTotals,
    calculatePercentGrade: calculatePercentGrade,
    formatPercentGrade: formatPercentGrade
  });

  return GradeSummary;
});
