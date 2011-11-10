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
  'i18n!learning_outcomes',
  'jquery' /* $ */,
  'find_outcome',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_helpers' /* replaceTags, /\$\.underscore/ */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'tinymce.editor_box' /* editorBox */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/sortable' /* /\.sortable/ */
], function(I18n, $, find_outcome) {

  var outcomes = {
    ratingCounter: 0,
    updateOutcome: function(outcome, $outcome) {
      if(!$outcome || $outcome.length === 0) {
        $outcome = $("#outcome_" + outcome.id);
      }
      if(!$outcome || $outcome.length === 0) {
        $outcome = $("#outcome_blank").clone(true).removeAttr('id');
        $("#outcomes .outcome_group:first").append($outcome.show());
        $("#outcomes .outcome_group:first .child_outcomes").sortable('refresh');
      }
      outcome.asset_string = $.underscore("learning_outcome_" + outcome.id);
      $outcome.find("textarea.description").val(outcome.description);
      $outcome.fillTemplateData({
        data: outcome,
        id: "outcome_" + outcome.id,
        htmlValues: ['description'],
        hrefValues: ['id']
      });
      $outcome.addClass('loaded');
      $outcome.find(".rubric_criterion .rating:not(.blank)").remove();
      if(outcome.data && outcome.data.rubric_criterion) {
        for(var idx in outcome.data.rubric_criterion.ratings) {
          var rating = outcome.data.rubric_criterion.ratings[idx]
          var $rating = $outcome.find(".rubric_criterion .rating.blank:first").clone(true).removeClass('blank');
          var jdx = outcomes.ratingCounter++;
          $rating.find(".description").text(rating.description);
          $rating.find(".points").text(rating.points);
          $outcome.find(".add_holder").before($rating.show());
        }
        $outcome.find(".mastery_points").text(outcome.data.rubric_criterion.mastery_points);
        $outcome.find(".points_possible").text(outcome.data.rubric_criterion.points_possible);
      }
        if(outcome.permissions) {
          $outcome.find(".edit_outcome_link").showIf(outcome.permissions.update && for_context);
          var for_context = (outcome.context_code == $("#find_outcome_dialog .context_code").text());
          $outcome.find(".really_delete_outcome_link").showIf(for_context);
          $outcome.find(".remove_outcome_link").showIf(!for_context);
        }
        return $outcome;
      },
      sizeRatings: function() {
      },
      hideEditOutcome: function() {
        // remove .prev('.outcome') if id is 'outcome_new'
        $("#edit_outcome_form textarea").editorBox('destroy');
        var $outcome = $("#outcomes #edit_outcome_form").prev(".learning_outcome");
        $("body").append($("#edit_outcome_form").hide());
        if($outcome.attr('id') == 'outcome_new') {
          $outcome.remove();
        } else {
          $outcome.show();
        }
      },
      editOutcome: function($outcome, $group) {
        // set id to "outcome_new"
        if($outcome && $outcome.length > 0 && !$outcome.hasClass('loaded')) {
          $outcome.find(".show_details_link").triggerHandler('click', function() {
            outcomes.editOutcome($outcome, $group);
          });
          return;
        }
        outcomes.hideEditOutcome();
        if(!$outcome || $outcome.length === 0) {
        $outcome = $("#outcome_blank").clone(true).attr('id', 'outcome_new');
        if(!$group || $group.length == 0) {
          $group = $("#outcomes .outcome_group:first");
        }
        $('#outcomes .child_outcomes:first').append($outcome.show());
        $group.find('.child_outcomes').sortable('refresh');
      }
      var $form = $("#edit_outcome_form");
      $form.attr('action', $outcome.find(".edit_outcome_link").attr('href'));
      $form.attr('method', 'PUT');
      if($outcome.attr('id') == 'outcome_new') {
        $form.attr('action', $("#outcome_links .add_outcome_url").attr('href'));
        $form.attr('method', 'POST');
      }
      var data = $outcome.getTemplateData({textValues: ['short_description', 'description', 'mastery_points']});
      
      // the OR here is because of a wierdness in chrome where .val() is an 
      // empty string but .html() is the actual imputed html that we want
      data.description = $outcome.find("textarea.description").val() || $outcome.find("textarea.description").html();
      $form.fillFormData(data, {object_name: 'learning_outcome'});
      $form.find("#outcome_include_rubric_example").attr('checked', true).change();
      $form.find(".rubric_criterion .rating:not(.blank)").remove();
      $outcome.find(".rubric_criterion .rating:not(.blank)").each(function() {
        $form.find("#outcome_include_rubric_example").attr('checked', true);
        var $rating = $form.find(".rubric_criterion .rating.blank:first").clone(true).removeClass('blank');
        var ratingData = $(this).getTemplateData({textValues: ['description', 'points']});
        var idx = outcomes.ratingCounter++;
        $rating.find(".outcome_rating_description").val(ratingData.description).attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][description]');
        $rating.find(".outcome_rating_points").val(ratingData.points).attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][points]');
        $form.find(".add_holder").before($rating.show());
      });
      $form.find(".mastery_points").val(data.mastery_points);
      $form.find("#outcome_include_rubric_example").change();
      $outcome.after($form.show());
      $outcome.hide();
      $form.find(":text:visible:first").focus().select();
      $form.find("textarea").editorBox();
    },
    deleteOutcome: function($outcome) {
      $outcome.confirmDelete({
        message: I18n.t("remove_learning_outcome", "Are you sure you want to remove this learning outcome?"),
        url: $outcome.find(".delete_outcome_link").attr('href'),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    },
    updateOutcomeGroup: function(group, $group) {
      if(!$group || $group.length === 0) {
        $group = $("#group_" + group.id);
      }
      if(!$group || $group.length === 0) {
        $group = $("#group_blank").clone(true).removeAttr('id');
        $("#outcomes .outcome_group:first").append($group.show());
        $("#outcomes .outcome_group:first .child_outcomes").sortable('refresh');
        $group.find('.child_outcomes').sortable(outcomes.sortableOptions);
        $(".outcome_group .child_outcomes").sortable('option', 'connectWith', '.child_outcomes');
      }
      group.asset_string = $.underscore("learning_outcome_group_" + group.id);
      $group.find("textarea.description").val(group.description);
      $group.fillTemplateData({
        data: group,
        id: "group_" + group.id,
        hrefValues: ['id'],
        htmlValues: ['description']
      });
      return $group;
    },
    hideEditOutcomeGroup: function() {
      // remove .prev('.group') if id is 'group_new'
      $("#edit_outcome_group_form textarea").editorBox('destroy');
      var $group = $("#outcomes #edit_outcome_group_form").prev(".outcome_group");
      $("body").append($("#edit_outcome_group_form").hide());
      if($group.attr('id') == 'group_new') {
        $group.remove();
      } else {
        $group.show();
      }
    },
    editOutcomeGroup: function($group) {
      // set id to "outcome_new"
      outcomes.hideEditOutcomeGroup();
      if(!$group || $group.length === 0) {
        $group = $("#group_blank").clone(true).attr('id', 'group_new');
        $("#outcomes .child_outcomes:first").append($group.show());
        $("#outcomes .outcome_group:first .child_outcomes").sortable('refresh');
        $group.find('.child_outcomes').sortable(outcomes.sortableOptions);
        $(".outcome_group .child_outcomes").sortable('option', 'connectWith', '.child_outcomes');
      }
      var $form = $("#edit_outcome_group_form");
      $form.attr('action', $group.find(".edit_group_link").attr('href'));
      $form.attr('method', 'PUT');
      if($group.attr('id') == 'group_new') {
        $form.attr('action', $("#outcome_links .add_outcome_group_url").attr('href'));
        $form.attr('method', 'POST');
      }
      var data = $group.getTemplateData({textValues: ['title', 'description']});
      data.description = $group.find("textarea.description").val();
      $form.fillFormData(data, {object_name: 'learning_outcome_group'});
      $group.after($form.show());
      $group.hide();
      $form.find(":text:visible:first").focus().select();
      $form.find("textarea").editorBox();
    },
    deleteOutcomeGroup: function($group) {
      $group.confirmDelete({
        message: I18n.t("remove_outcome_group", "Are you sure you want to remove this learning outcome group and all its outcomes?"),
        url: $group.find(".delete_group_link").attr('href'),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    },
    sortableOptions: {
      axis: 'y',
      connectWith: '#outcomes .child_outcomes',
      containment: '#outcomes',
      handle: '.reorder_link',
      update: function(event, ui) {
        var $group = $(ui.item).parent().closest('.outcome_group'),
            id     = $group.children('.header').getTemplateData({ textValues: [ 'asset_string', 'id' ] }).id,
            data   = {},
            url    = $.replaceTags($("#outcome_links .reorder_items_url").attr('href'), 'id', id),
            assets = $group.find('.child_outcomes').children('.learning_outcome, .outcome_group').map(function(i, el){
              return $(el).children('.header').getTemplateData({ textValues: [ 'asset_string', 'id' ] }).asset_string;
            });
        for (var _i = 0, _max = assets.length; _i < _max; _i++){
          data['ordering[' + assets[_i] + ']'] = _i;
        }
        $.ajaxJSON(url, 'POST', data);
      }
    }
  };
  $(document).ready(function() {
    $("#outcome_information_link").click(function(event) {
      event.preventDefault();
      $("#outcome_criterion_dialog").dialog('close').dialog({
        autoOpen: false,
        title: I18n.t("outcome_criterion", "Learning Outcome Criterion"),
        width: 400
      }).dialog('open');
    });
    $(".show_details_link,.hide_details_link").click(function(event, callback) {
      event.preventDefault();
      var $outcome = $(this).closest(".learning_outcome");
      if($(this).hasClass('show_details_link')) {
        if($outcome.hasClass('loaded')) {
          $outcome.addClass('expanded');
        } else {
          var $link = $(this);
          $link.text("loading details...");
          var url = $outcome.find("a.show_details_link").attr('href');
          $.ajaxJSON(url, 'GET', {}, function(data) {
            $link.text(I18n.t("show_details", "show details"));
            outcomes.updateOutcome(data.learning_outcome, $outcome);
            $outcome.addClass('expanded');
            if(callback && $.isFunction(callback)) {
              callback();
            }
          }, function(data) {
            $link.text(I18n.t("details_failed_to_load", "details failed to load, please try again"));
          });
        }
      } else {
        $outcome.removeClass('expanded');
      }
    });
    $('#outcomes .child_outcomes').sortable(outcomes.sortableOptions);
    $(".delete_group_link").click(function(event) {
      event.preventDefault();
      outcomes.deleteOutcomeGroup($(this).closest(".outcome_group"));
    });
    $(".edit_group_link").click(function(event) {
      event.preventDefault();
      outcomes.editOutcomeGroup($(this).closest(".outcome_group"));
    });
    $("#find_outcome_dialog .select_outcomes_link").click(function(event) {
      event.preventDefault();
      $("#find_outcome_dialog .select_outcome_checkbox:checked").each(function() {
        var $outcome_select = $(this).parents(".outcomes_dialog_select");
        var id = $outcome_select.getTemplateData({textValues: ['id']}).id;
        var $outcome = $("#outcome_dialog_" + id);
        var id = $outcome.getTemplateData({textValues: ['id']}).id;
        var group_id = $("#outcomes .outcome_group:first > .header").getTemplateData({textValues: ['id']}).id;
        var url = $.replaceTags($("#find_outcome_dialog .add_outcome_url").attr('href'), 'learning_outcome_id', id);
        url = $.replaceTags(url, 'learning_outcome_group_id', group_id);
        var data = $outcome.getTemplateData({textValues: ['id', 'short_description', 'description']});
        data.permissions = {};
        var $outcome = outcomes.updateOutcome(data);
        $("html,body").scrollTo($outcome);
        $outcome.loadingImage();
        $("#find_outcome_dialog").dialog('close');
        $.ajaxJSON(url, 'POST', {}, function(data) {
          $outcome.loadingImage('remove');
          outcomes.updateOutcome(data.learning_outcome);
        }, function() {
          $outcome.loadingImage('remove');
          $outcome.remove();
        });
      });
    });
    $(".edit_outcome_link").click(function(event) {
      event.preventDefault();
      outcomes.editOutcome($(this).parents(".learning_outcome"));
    });
    $(".delete_outcome_link").click(function(event) {
      event.preventDefault();
      outcomes.deleteOutcome($(this).parents(".learning_outcome"));
    });
    $(".add_outcome_link").click(function(event) {
      event.preventDefault();
      var $group = $(this).closest(".outcome_group");
      if($group.length == 0) { $group = null; }
      outcomes.editOutcome(null, $group);
    });
    $(".add_outcome_group_link").click(function(event) {
      event.preventDefault();
      outcomes.editOutcomeGroup();
    });
    $("#edit_outcome_group_form .cancel_button").click(function(event) {
      outcomes.hideEditOutcomeGroup();
    });
    $("#edit_outcome_form .cancel_button").click(function(event) {
      outcomes.hideEditOutcome();
    });
    $("#find_outcome_dialog .outcomes_dialog_select").click(function(event) {
      if($(event.target).closest("input").length > 0) { return; }
      event.preventDefault();
      $("#find_outcome_dialog .outcomes_dialog_select.selected_side_tab").removeClass('selected_side_tab');
      $(this).addClass('selected_side_tab');
      var id = $(this).getTemplateData({textValues: ['id']}).id;
      $("#find_outcome_dialog").find(".outcomes_dialog_outcome").hide().end()
        .find("#outcome_dialog_" + id).show();
    });
    $(".find_outcome_link").click(function(event) {
      var $dialog = $("#find_outcome_dialog");
      event.preventDefault();
      $dialog.dialog('close').dialog({
        autoOpen: true,
        width: 600,
        height: 350,
        title: I18n.t("find_existing_outcome", 'Find Existing Outcome')
      }).dialog('open');
      if(!$dialog.hasClass('loaded')) {
        $dialog.find(".loading_message").text(I18n.t("loading_outcomes", "Loading outcomes..."));
        var url = $dialog.find(".outcomes_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $dialog.find(".loading_message").remove();
          if(data.length === 0) {
            $dialog.find(".loading_message").text("No outcomes found");
          }
          for(var idx in data) {
            var outcome = data[idx].learning_outcome
            var $outcome_select = $dialog.find(".outcomes_dialog_select.blank:first").clone(true);
            $outcome_select.fillTemplateData({data: outcome}).removeClass('blank');
            $dialog.find(".outcomes_dialog_outcomes_select").append($outcome_select.show());
            var $outcome = $dialog.find(".outcomes_dialog_outcome.blank:first").clone(true);
            $outcome.removeClass('blank');
            $outcome.data('outcome', outcome);
            $outcome.find(".criterion.blank").hide();
            outcome.outcome_total = outcome.points_possible;
            $outcome.fillTemplateData({
              data: outcome,
              htmlValues: ['description'],
              id: 'outcome_dialog_' + outcome.id
            });
            $dialog.find(".outcomes_dialog_outcomes").append($outcome);
          }
          $dialog.find(".outcomes_dialog_holder").show();
          $dialog.find(".outcomes_dialog_outcomes_select .outcomes_dialog_select:visible:first").click();
          $dialog.addClass('loaded');
        }, function(data) {
          $dialog.find(".loading_message").text(I18n.t("loading_outcomes_failed", "Loading outcomes failed, please try again"));
        });
      }
    });
    $("#edit_outcome_form").formSubmit({
      processData: function(data) {
        data['learning_outcome_group_id'] = $(this).closest(".outcome_group").find(".header").first().getTemplateData({textValues: ['id']}).id;
        return data;
      },
      beforeSubmit: function(data) {
        var $outcome = $(this).prev(".outcome");
        if($outcome.attr('id') == 'outcome_new') {
          $outcome.attr('id', 'outcome_adding');
        }
        $(this).loadingImage();
      },
      success: function(data) {
        $(this).loadingImage('remove');
        outcomes.updateOutcome(data.learning_outcome, $(this).prev(".learning_outcome"));
        outcomes.hideEditOutcome();
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).formErrors(data);
      }
    });
    $("#edit_outcome_group_form").formSubmit({
      processData: function(data) {
        var group_id = $(this).parent().closest(".outcome_group").children(".header").getTemplateData({textValues: ['id']}).id;
        data['learning_outcome_group[learning_outcome_group_id]'] = group_id;
        return data;
      },
      beforeSubmit: function(data) {
        var $group = $(this).prev(".outcome_group");
        if($group.attr('id') == 'group_new') {
          $group.attr('id', 'group_adding');
        }
        $(this).loadingImage();
      },
      success: function(data) {
        $(this).loadingImage('remove');
        outcomes.updateOutcomeGroup(data.learning_outcome_group, $(this).prev(".outcome_group"));
        outcomes.hideEditOutcomeGroup();
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).formErrors(data);
      }
    });
    $("#edit_outcome_form .switch_views_link").click(function(event) {
      event.preventDefault();
      $("#edit_outcome_form textarea:first").editorBox('toggle');
    });
    $("#outcome_include_rubric_example").change(function() {
      var $form = $(this).parents("form");
      $form.find(".rubric_criterion").showIf($(this).attr('checked'));
      $form.find(".outcome_rating_points:first").blur();
      if(!$form.find(".outcome_criterion_title").val()) {
        $form.find(".outcome_criterion_title").val($form.find(".outcome_short_description").val());
      }
      if($form.find(".rating:not(.blank)").length === 0) {
        var $rating = $form.find(".rating.blank:first").clone(true).removeClass('blank');
        var idx = outcomes.ratingCounter++;
        $rating.find(".outcome_rating_description").val(I18n.t("criteria.exceeds_expectations", "Exceeds Expectations")).attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][description]');
        $rating.find(".outcome_rating_points").val("5").attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][points]');
        $form.find(".add_holder").before($rating.show());

        idx = outcomes.ratingCounter++;
        $rating = $form.find(".rating.blank:first").clone(true).removeClass('blank');
        $rating.find(".outcome_rating_description").val(I18n.t("criteria.meets_expectations", "Meets Expectations")).attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][description]');
        $rating.find(".outcome_rating_points").val("3").attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][points]');
        $form.find(".add_holder").before($rating.show());

        idx = outcomes.ratingCounter++;
        $rating = $form.find(".rating.blank:first").clone(true).removeClass('blank');
        $rating.find(".outcome_rating_description").val(I18n.t("criteria.does_not_meet_expectations", "Does Not Meet Expectations")).attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][description]');
        $rating.find(".outcome_rating_points").val("0").attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][points]');
        $form.find(".add_holder").before($rating.show());

        $form.find(".mastery_points").val("3");
      }
      $form.find(".outcome_rating_points:first").blur();
    });
    $("#edit_outcome_form .outcome_rating_points").blur(function() {
      var maxPoints = 0;
      $(this).val(parseFloat($(this).val()));
      $("#edit_outcome_form .rating:not(.blank) .outcome_rating_points").each(function() {
        var points = parseFloat($(this).val(), 10);
        if(points) {
          maxPoints = Math.max(points, maxPoints);
        }
      });
      $("#edit_outcome_form .points_possible").text(maxPoints);
    })
    $("#edit_outcome_form .mastery_points").blur(function() {
      $(this).val(parseFloat($(this).val()) || 0);
    });
    $("#edit_outcome_form .add_rating_link").click(function(event) {
      event.preventDefault();
      var $rating = $(this).parents("table").find("tr.rating:visible:first").clone(true).removeClass('blank');
      if($rating.length === 0) {
        $rating = $(this).parents("table").find("tr.rating.blank").clone(true).removeClass('blank');
      }
      $(this).parents("table").find(".criterion_title").after($rating.show());
      var idx = outcomes.ratingCounter++;
      $rating.find(".outcome_rating_description").attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][description]');
      $rating.find(".outcome_rating_points").attr('name', 'learning_outcome[rubric_criterion][ratings][' + idx + '][points]');
      $rating.find(".outcome_rating_points").val(parseFloat($rating.find(".outcome_rating_points").val(), 10) + 1);
      $rating.find(".outcome_rating_points:first").blur();
      outcomes.sizeRatings();
    });
    $("#edit_outcome_form .delete_rating_link").click(function(event) {
      event.preventDefault();
      $(this).parents("tr").remove();
      outcomes.sizeRatings();
    });
  });
});
