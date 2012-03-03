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

require([
  'i18n!shared.aligned_outcomes',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_jquery_patches' /* /\.dialog/, /\.disabled/ */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(I18n, $) {

$(document).ready(function() {
  var url = $("#aligned_outcomes .outcomes_url").attr('href');
  var updateOutcomesList = function(data) {
    $("#aligned_outcomes .outcomes .outcome:not(.blank)").remove();
    var mastery = parseFloat($("#full_assignment_holder input[name='assignment[mastery_score]']").val());
    var possible = parseFloat($("#full_assignment_holder input[name='assignment[points_possible]']").val());
    var mastery_points = null;
    if(isFinite(mastery) || isFinite(possible)) {
      mastery_points = mastery || possible || 0;
    }
    for(var idx in data) {
      var tag = data[idx].content_tag;
      var outcome = tag.learning_outcome;
      var $outcome = $("#aligned_outcomes .outcomes .outcome.blank:first").clone(true).removeClass('blank');
      outcome.mastery = "";
      if(tag.rubric_association_id) {
        $outcome.addClass('rubric_alignment');
        outcome.mastery = I18n.t('mastery_info_see_rubric', "see the rubric for mastery details");
      } else {
        if(mastery_points) {
          outcome.mastery = I18n.t('mastery_score_info', "mastery with a score of %{score} or higher", {score: mastery_points});
        }
      }
      $outcome.fillTemplateData({
        data: outcome,
        hrefValues: ['id'],
        htmlValues: ['description']
      });
      $("#aligned_outcomes .outcomes").append($outcome.show());
    }
    $("#aligned_outcomes").showIf(data.length > 0);
    if($("#align_outcomes_dialog:visible").length > 0) {
      $(".align_outcomes_link:first").click();
    }
  };
  if (typeof(url) != 'undefined') {
    $.ajaxJSON(url, 'GET', {}, function(data) {
      updateOutcomesList(data);
    });
  }
  $(".align_outcomes_link").click(function(event) {
    event.preventDefault();
    $("#aligned_outcomes").show();
    $("html,body").scrollTo($("#aligned_outcomes"));
    var mastery = parseFloat($("#full_assignment_holder input[name='assignment[mastery_score]']").val());
    mastery = mastery || "";
    $("#align_outcomes_dialog .outcome_checkbox").each(function() { $(this).attr('checked', false).attr('disabled', false); });
    $("#align_outcomes_dialog .rubric_aligned").hide();
    $("#aligned_outcomes .outcomes .outcome:not(.blank):not(.rubric_alignment)").each(function() {
      var id = $(this).getTemplateData({textValues: ['id']}).id;
      $("#align_outcome_for_" + id).attr('checked', true);
    });
    $("#aligned_outcomes .outcomes .outcome.rubric_alignment:not(.blank)").each(function() {
      var id = $(this).getTemplateData({textValues: ['id']}).id;
      $("#align_outcome_for_" + id).attr('checked', true).attr('disabled', true);
      $(this).parents(".outcome").find(".rubric_aligned").show();
    });
    $("#align_outcomes_dialog .outcome_checkbox").each(function() { $(this).change(); });
    $("#aligned_outcomes_mastery_score").val(mastery);
    $("#align_outcomes_dialog").dialog('close').dialog({
      autoOpen: false,
      title: I18n.t('buttons.align_outcomes', 'Align Outcomes'),
      width: 500
    }).dialog('open');
  });
  $("#align_outcomes_dialog .cancel_button").click(function() {
    $("#align_outcomes_dialog").dialog('close');
  });
  $("#align_outcomes_dialog .outcome_checkbox").change(function() {
    $(this).parents(".outcome").toggleClass('selected_outcome', $(this).attr('checked'));
  });
  $("#align_outcomes_dialog .save_button").click(function() {
    var ids = [];
    $(".outcome_checkbox:checked").each(function() { ids.push($(this).val()); });
    ids = ids.join(",");
    var url = $("#aligned_outcomes .outcomes_url").attr('href');
    var mastery_score = parseFloat($("#aligned_outcomes_mastery_score").val()) || "";
    var $button = $(this);
    $button.text(I18n.t('status.aligning_outcomes', 'Aligning Outcomes...'));
    $("#align_outcomes_dialog .button-container .button").attr('disabled', true);
    $.ajaxJSON(url, 'POST', {outcome_ids: ids, mastery_score: mastery_score}, function(data) {
      $("#align_outcomes_dialog .button-container .button").attr('disabled', false);
      $button.text(I18n.t('buttons.align_outcomes', 'Align Outcomes'));
      $("#full_assignment_holder input[name='assignment[mastery_score]']").val(mastery_score);
      updateOutcomesList(data);
      $("#align_outcomes_dialog").dialog('close');
    }, function() {
      $("#align_outcomes_dialog .button-container .button").attr('disabled', false);
      $button.text(I18n.t('errors.align_outcomes_failed', 'Aligning Outcomes Failed, Please Try Again'));
    });
  });
});
});
