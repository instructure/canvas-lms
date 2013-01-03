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
  'compiled/grade_calculator',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* getFormData */,
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'media_comments' /* mediaComment, mediaCommentThumbnail */
], function(INST, I18n, $, GradeCalculator) {

  function setGroupData(groups, $group) {
    if($group.length === 0) { return; }
    var data = $group.getTemplateData({textValues: ['assignment_group_id', 'rules', 'group_weight']});
    data = $.extend(data, $group.getFormData());
    var groupData = groups[data.assignment_group_id] || {};
    if(!groupData.group_weight) {
      groupData.group_weight = parseFloat(data.group_weight) / 100.0;
    }
    groupData.scores = groupData.scores || [];
    groupData.full_points = groupData.full_points || [];
    groupData.count = groupData.count || 0;
    groupData.submissions = groupData.submissions || [];
    groupData.sorted_submissions = groupData.sorted_submissions || [];
    if (isNaN(groupData.score_total)) { groupData.score_total = null; }
    if (isNaN(groupData.full_total)) { groupData.full_total = null; }
    if(groupData.score_total !== null || groupData.full_total !== null) {
      groupData.calculated_score = (groupData.score_total / groupData.full_total);
      if(isNaN(groupData.calculated_score) || !isFinite(groupData.calculated_score)) {
        groupData.calculated_score = 0.0;
      }
    } else {
      groupData.score_total = 0;
      groupData.full_total = 0;
    }
    if(!groupData.rules) {
      data.rules = data.rules || "";
      var rules = {drop_highest: 0, drop_lowest: 0, never_drop: []};
      var rulesList = data.rules.split("\n");
      for(var idx in rulesList) {
        var rule = rulesList[idx].split(":");
        var drop = null;
        if(rule.length > 1) {
          drop = parseInt(rule[1], 10);
        }
        if(drop && !isNaN(drop) && isFinite(drop)) {
          if(rule[0] == 'drop_lowest') {
            rules['drop_lowest'] = drop;
          } else if(rule[0] == 'drop_highest') {
            rules['drop_highest'] = drop;
          } else if(rule[0] == 'never_drop') {
            rules['never_drop'].push(drop);
          }
        }
      }
      groupData.rules = rules;
    }
    groups[data.assignment_group_id] = groupData;
    return groupData;
  }
  function updateStudentGrades() {
    var ignoreUngradedSubmissions = $("#only_consider_graded_assignments").attr('checked');
    var $submissions = $("#grades_summary .student_assignment");
    var groups = {};
    var $groups = $(".group_total");
    $groups.each(function() {
      setGroupData(groups, $(this));
    });
    $submissions.removeClass('dropped');
    $submissions.find('.points_possible').attr('aria-label', '');
    $submissions.each(function() {
      var $submission = $(this),
          submission;
      if($submission.hasClass('hard_coded')) { return; }
      
      var data = $submission.getTemplateData({textValues: ['assignment_group_id', 'score', 'points_possible', 'assignment_id']});
      if((!data.score || isNaN(parseFloat(data.score))) && ignoreUngradedSubmissions) {
        $submission.addClass('dropped')
                   .find('.points_possible')
                   .attr('aria-label', I18n.t('titles.dropped_assignment_no_total', 'This assignment will not be considered in the total calculation'));
        return;
      }
      var groupData = groups[data.assignment_group_id];
      
      if(!groupData) {
        groupData = setGroupData(groups, $("#submission_group-" + data.assignment_group_id));
      }
      if(!groupData) {
        return;
      }
      var score = parseFloat(data.score);
      if(!score || isNaN(score) || !isFinite(score)) {
        score = 0;
      }
      var possible = parseFloat(data.points_possible);
      if(!possible || isNaN(possible)) {
        possible = 0;
      }
      var percent = score / possible;
      if(isNaN(percent) || !isFinite(percent)) {
        percent = 0;
      }
      data.calculated_score = score;
      data.calculated_possible = possible;
      data.calculated_percent = percent;
      groupData.submissions.push(data);
      groups[data.assignment_group_id] = groupData;
    });
    for(var idx in groups) {
      var groupData = groups[idx];
      groupData.sorted_submissions = groupData.submissions.sort(function(a, b) {
        var aa = [a.calculated_percent];
        var bb = [b.calculated_percent];
        if(aa > bb) { return 1; }
        if(aa == bb) { return 0; }
        return -1;
      });
      var lowDrops = 0, highDrops = 0;
      for(var jdx = 0; jdx < groupData.sorted_submissions.length; jdx++) {
        groupData.sorted_submissions[jdx].calculated_drop = false;
      }
      for(jdx = 0; jdx < groupData.sorted_submissions.length; jdx++) {
        submission = groupData.sorted_submissions[jdx];
        if(!submission.calculated_drop && lowDrops < groupData.rules.drop_lowest && submission.calculated_possible > 0 && $.inArray(submission.assignment_id, groupData.rules.never_drop) == -1) {
          lowDrops++;
          submission.calculated_drop = true;
        }
        groupData.sorted_submissions[jdx] = submission;
      }
      for(jdx = groupData.sorted_submissions.length - 1; jdx >= 0; jdx--) {
        submission = groupData.sorted_submissions[jdx];
        if(!submission.calculated_drop && highDrops < groupData.rules.drop_highest && submission.calculated_possible > 0 && $.inArray(submission.assignment_id, groupData.rules.never_drop) == -1) {
          highDrops++;
          submission.calculated_drop = true;
        }
        groupData.sorted_submissions[jdx] = submission;
      }
      for(jdx = 0; jdx < groupData.sorted_submissions.length; jdx++) {
        submission = groupData.sorted_submissions[jdx];
        if(submission.calculated_drop) {
          $("#submission_" + submission.assignment_id).addClass('dropped');
          lowDrops++;
        } else {
          $("#submission_" + submission.assignment_id).removeClass('dropped');
          groupData.scores.push(submission.calculated_score);
          groupData.full_points.push(submission.calculated_possible);
          groupData.count++;
          groupData.score_total += submission.calculated_score;
          groupData.full_total += submission.calculated_possible;
        }
      }
      groups[idx] = groupData;
    }
    var finalWeightedGrade = 0.0, 
            finalGrade = 0.0, 
            totalPointsPossible = 0.0, 
            possibleWeightFromSubmissions = 0.0,
            totalUserPoints = 0.0;
    $.each(groups, function(i, group) {
      var groupData = setGroupData(groups, $("#submission_group-" + i));
      var score = Math.round(group.calculated_score * 1000.0) / 10.0;
    $("#submission_group-" + i).find(".grade").text(score).end()
      .find(".score_teaser").text(group.score_total + " / " + group.full_total);
      
      score = group.calculated_score * group.group_weight;
      if(isNaN(score) || !isFinite(score)) {
        score = 0;
      }
      if(ignoreUngradedSubmissions && group.count > 0) {
        possibleWeightFromSubmissions += group.group_weight;      
      }
      finalWeightedGrade += score;
      totalUserPoints += group.score_total;
      totalPointsPossible += group.full_total;
    });
    var total = parseFloat($("#total_groups_weight").text());
    if(isNaN(total) || !isFinite(total) || total === 0) { // if not weighting by group percents
      finalGrade = Math.round(1000.0 * totalUserPoints / totalPointsPossible) / 10.0;
      $(".student_assignment.final_grade .score_teaser").text(totalUserPoints + ' / ' + totalPointsPossible);
    } else {
      var totalPossibleWeight = parseFloat($("#total_groups_weight").text()) / 100;
      if(isNaN(totalPossibleWeight) || !isFinite(totalPossibleWeight) || totalPossibleWeight === 0) {
        totalPossibleWeight = 1.0;
      }
      if(ignoreUngradedSubmissions && possibleWeightFromSubmissions < 1.0) {
        var possible = totalPossibleWeight < 1.0 ? totalPossibleWeight : 1.0 ;
        finalWeightedGrade = possible * finalWeightedGrade / possibleWeightFromSubmissions;
      }
      
      finalGrade = finalWeightedGrade;
      finalGrade = Math.round(finalGrade * 1000.0) / 10.0;
      $(".student_assignment.final_grade .score_teaser").text(I18n.t('percent', 'Percent'));
    }
    if(isNaN(finalGrade) || !isFinite(finalGrade)) {
      finalGrade = 0;
    }
    $(".student_assignment.final_grade").find(".grade").text(finalGrade);

    if(window.grading_scheme) {
      $(".final_letter_grade .grade").text(GradeCalculator.letter_grade(grading_scheme, finalGrade));
    }

    $(".revert_all_scores").showIf($("#grades_summary .revert_score_link").length > 0);
    var eTime = (new Date()).getTime();
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
      if(!skipEval) {
        updateStudentGrades();
      }
    });
    $("#grades_summary:not(.editable) .assignment_score").css('cursor', 'default');
    $("#grades_summary tr").hover(function() {
      $(this).find("td.title .context").addClass('context_hover');
    }, function() {
      $(this).find("td.title .context").removeClass('context_hover');
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
        $parent.children(":not(.media_comment_content)").remove();
        $parent.find(".media_comment_content").mediaComment('show_inline', comment_id, 'any');
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

});

