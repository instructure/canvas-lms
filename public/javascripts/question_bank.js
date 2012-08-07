define([
  'i18n!question_bank',
  'jquery' /* $ */,
  'find_outcome',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_misc_plugins' /* .dim */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */
], function(I18n, $, find_outcome) {

$(document).ready(function() {
  function updateAlignments(alignments) {
    $(".add_outcome_text").text(I18n.t("updating_outcomes", "Updating Outcomes...")).attr('disabled', true);
    var params = {};
    for(var idx in alignments) {
      var alignment = alignments[idx];
      params['assessment_question_bank[alignments][' + alignment[0] + ']'] = alignment[1];
    }
    if(alignments.length == 0) {
      params['assessment_question_bank[alignments]'] = '';
    }
    var url = $(".edit_bank_link").attr('href');
    $.ajaxJSON(url, 'PUT', params, function(data) {
      var alignments = data.assessment_question_bank.learning_outcome_alignments.sort(function(a, b) {
        var a_name = ((a.content_tag && a.content_tag.learning_outcome && a.content_tag.learning_outcome.short_description) || 'none').toLowerCase();
        var b_name = ((b.content_tag && b.content_tag.learning_outcome && b.content_tag.learning_outcome.short_description) || 'none').toLowerCase();
        if(a_name < b_name) { return -1; }
        else if(a_name > b_name) { return 1; }
        else { return 0; }
      });
      $(".add_outcome_text").text(I18n.t("align_outcomes", "Align Outcomes")).attr('disabled', false);
      var $outcomes = $("#aligned_outcomes_list");
      $outcomes.find(".outcome:not(.blank)").remove();
      var $template = $outcomes.find(".blank:first").clone(true).removeClass('blank');
      for(var idx in alignments) {
        var alignment = alignments[idx].content_tag;
          var outcome = {
            short_description: alignment.learning_outcome.short_description,
            mastery_threshold: Math.round(alignment.mastery_score * 10000) / 100.0
          };
          var $outcome = $template.clone(true);
          $outcome.attr('data-id', alignment.learning_outcome_id);
          $outcome.fillTemplateData({
            data: outcome
          });
          $outcomes.append($outcome.show());
      }
    }, function(data) {
      $(".add_outcome_text").text(I18n.t("update_outcomes_fail", "Updating Outcomes Failed")).attr('disabled', false);
    });
  }
  $("#aligned_outcomes_list").delegate('.delete_outcome_link', 'click', function(event) {
    event.preventDefault();
    var result = confirm(I18n.t("remove_outcome_from_bank", "Are you sure you want to remove this outcome from the bank?"));
    var $outcome = $(this).parents(".outcome");
    var alignments = [];
    var outcome_id = $outcome.attr('data-id');
    if(result) {
      $(this).parents(".outcome").dim();
      $("#aligned_outcomes_list .outcome:not(.blank)").each(function() {
        var id = $(this).attr('data-id');
        var pct = $(this).getTemplateData({textValues: ['mastery_threshold']}).mastery_threshold / 100;
        if(id != outcome_id) {
          alignments.push([id, pct]);
        }
      });
      updateAlignments(alignments);
    }
  });
  $(".add_outcome_link").click(function(event) {
    event.preventDefault();
    find_outcome.find(function($outcome) {
      var outcome_id = $outcome.find(".learning_outcome_id").text();
      var mastery = (parseFloat($outcome.find(".mastery_level").val()) / 100.0) || 1.0;
      var alignments = [];
      $("#aligned_outcomes_list .outcome:not(.blank)").each(function() {
        var id = $(this).attr('data-id');
        var pct = $(this).getTemplateData({textValues: ['mastery_threshold']}).mastery_threshold / 100.0;
        alignments.push([id, pct]);
      });
      alignments.push([outcome_id, mastery]);
      updateAlignments(alignments);
    });
  });
});
});
