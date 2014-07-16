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
  'i18n!edit_rubric',
  'jst/changePointsPossibleToMatchRubricDialog',
  'jquery' /* $ */,
  'underscore' /* _ */,
  'str/htmlEscape',
  'find_outcome',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'vendor/jquery.ba-tinypubsub',
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'compiled/jquery/fixDialogButtons'
], function(I18n, changePointsPossibleToMatchRubricDialog, $, _, htmlEscape) {

  var rubricEditing = {
    htmlBody: null,

    updateCriteria: function($rubric) {
      $rubric.find(".criterion:not(.blank)").each(function(i) {
        $(this).attr('id', 'criterion_' + (i + 1));
      });
    },
    addCriterion: function($rubric) {
      var $blank = $rubric.find(".criterion.blank:first");
      var $criterion = $blank.clone(true);
      $criterion.removeClass('blank');
      $rubric.find(".summary").before($criterion.show());
      rubricEditing.updateCriteria($rubric);
      rubricEditing.updateRubricPoints($rubric);
      rubricEditing.sizeRatings($criterion);
      return $criterion;
    },
    onFindOutcome: function(outcome) {
      var $rubric = $('.rubric table.rubric_table:visible:first'),
          $criterion;

      $rubric.find(".criterion.learning_outcome_" + outcome.id).find(".delete_criterion_link").click();
      $rubric.find(".add_criterion_link").click();

      $criterion = $rubric.find('.criterion:not(.blank):last');

      $criterion.toggleClass('ignore_criterion_for_scoring', !outcome.useForScoring);
      $criterion.find('.mastery_points').val(outcome.get('mastery_points'));
      $criterion.addClass('learning_outcome_criterion');
      $criterion.find('.learning_outcome_id').text(outcome.id);
      $criterion.find(".criterion_points").val(outcome.get('ratings')[0].points).blur();

      for (var i = 0; i < outcome.get('ratings').length - 2; i++) {
        $criterion.find('.rating:not(.blank):first').addClass('add_column').click();
      }

      $criterion.find('.rating:not(.blank)').each(function(i) {
        var rating = outcome.get('ratings')[i];
        $(this).fillTemplateData({data: rating});
      });

      $criterion.find(".cancel_button").click();

      $criterion.find(".long_description").val(outcome.get('description'));
      $criterion.find(".long_description_holder").toggleClass('empty', !outcome.get('description'));

      $criterion.find(".criterion_description_value").text(outcome.get('title'));
      $criterion.find(".criterion_description").val(outcome.get('title')).focus().select();

      $criterion.find(".mastery_points").text(outcome.get('mastery_points'));
    },
    hideCriterionAdd: function($rubric) {
      $rubric.find('.add_right, .add_left, .add_column').removeClass('add_left add_right add_column');
    },
    updateRubricPoints: function($rubric) {
      var total = 0;
      $rubric.find(".criterion:not(.blank):not(.ignore_criterion_for_scoring) .criterion_points").each(function() {
        var points = parseFloat($(this).val(), 10);
        if(!isNaN(points)) {
          total += points;
        }
      });
      total = round(total, 2);
      $rubric.find(".rubric_total").text(total);
    },
    updateCriterionPoints: function($criterion, baseOnRatings) {
      rubricEditing.hideEditRating();
      var ratings = $.makeArray($criterion.find(".rating")).reverse();
      var rating_points = -1;
      var points = parseFloat($criterion.find(".criterion_points").val());
      if(isNaN(points)) {
        points = 5;
      } else {
        points = round(points, 2);
      }
      $criterion.find(".rating:first .points").text(points);
      // From right to left, make sure points never decrease
      // and round to 2 decimal places.
      $.each(ratings, function(i, rating) {
        var $rating = $(rating);
        var data = $rating.getTemplateData({textValues: ['points']});
        if(data.points < rating_points) {
          data.points = rating_points;
        }
        data.points = round(data.points, 2);
        $rating.fillTemplateData({data: data});
        rating_points = parseFloat(data.points);
      });
      if(baseOnRatings && rating_points > points) { points = rating_points; }
      $criterion.find(".criterion_points").val(points);
      $criterion.find(".display_criterion_points").text(points);
      if(!$criterion.data('criterion_points') || $criterion.data('criterion_points') != points) {
        if(!$criterion.data('criterion_points')) {
          var pts = parseFloat($criterion.find(".rating:first .points").text());
          $criterion.data('criterion_points', pts);
        }
        var oldMax = parseFloat($criterion.data('criterion_points'));
        var newMax = points;
        if (oldMax !== newMax) {
          var $ratingList = $criterion.find(".rating");
          $($ratingList[0]).find(".points").text(points);
          var lastPts = points;
          // From left to right, scale points proportionally to new range.
          // So if originally they were 3,2,1 and now we increased the
          // total possible to 9, they'd be 9,6,3
          for(var i = 1; i < $ratingList.length - 1; i++) {
            var pts = parseFloat($($ratingList[i]).find(".points").text());
            var newPts = Math.round((pts / oldMax) * newMax);
            if(isNaN(pts) || (pts == 0 && lastPts > 0)) {
              newPts = lastPts - Math.round(lastPts / ($ratingList.length - i));
            }
            if(newPts >= lastPts) {
              newPts = lastPts - 1;
            }
            newPts = Math.max(0, newPts);
            lastPts = newPts;
            $($ratingList[i]).find(".points").text(newPts);
          }
        }
        $criterion.data('criterion_points', points);
      }
      rubricEditing.updateRubricPoints($criterion.parents(".rubric"));
    },
    editRating: function($rating) {
      if(!$rating.parents(".rubric").hasClass('editing')) { return; }
      if($rating.parents(".criterion").hasClass('learning_outcome_criterion')) { return; }
      rubricEditing.hideEditRating(true);
      rubricEditing.hideCriterionAdd($rating.parents(".rubric"));
      var height = Math.max(40, $rating.find(".rating").height());
      var data = $rating.getTemplateData({textValues: ['description', 'points']});
      var $box = $("#edit_rating");
      $box.fillFormData(data);
      $rating.find(".container").hide();
      $rating.append($box.show());
      $box.find(":input:first").focus().select();
      $rating.addClass('editing');
      rubricEditing.sizeRatings($rating.parents(".criterion"));
    },
    hideEditRating: function(updateCurrent) {
      var $form = $("#edit_rating");
      if($form.filter(":visible").length > 0 && updateCurrent) { $form.find("form").submit(); }
      var $rating = $form.parents(".rating");
      $rating.removeClass('editing');
      $form.appendTo($("body")).hide();
      $rating.find(".container").show();
      rubricEditing.sizeRatings($rating.parents(".criterion"));
      rubricEditing.hideCriterionAdd($rating.parents(".rubric"));
    },
    editCriterion: function($criterion) {
      if(!$criterion.parents(".rubric").hasClass('editing')) { return; }
      if($criterion.hasClass('learning_outcome_criterion')) { return; }
      rubricEditing.hideEditCriterion(true);
      var $td = $criterion.find(".criterion_description");
      var height = Math.max(40, $td.find(".description").height());
      var data = $td.getTemplateData({textValues: ['description']});
      var $box = $("#edit_criterion");
      $box.fillFormData(data);
      $td.find(".container").hide().after($box.show());
      $box.find(":input:first").focus().select();
      rubricEditing.sizeRatings($criterion);
    },
    hideEditCriterion: function(updateCurrent) {
      var $form = $("#edit_criterion");
      if($form.filter(":visible").length > 0 && updateCurrent) { $form.find("form").submit(); }
      var $criterion = $form.parents(".criterion");
      $form.appendTo("body").hide();
      $criterion.find(".criterion_description").find(".container").show();
      rubricEditing.sizeRatings($criterion);
    },

    originalSizeRatings: function() {
      var $visibleCriteria = $(".rubric:not(.rubric_summary) .criterion:visible");
      if ($visibleCriteria.length) {
        var scrollTop = $.windowScrollTop();
        $visibleCriteria.each(function() {
          var $this = $(this),
              $ratings = $this.find(".ratings:visible");
          if($ratings.length) {
            var $ratingsContainers = $ratings.find('.rating .container').css('height', ""),
                maxHeight = Math.max(
                  $ratings.height(),
                  $this.find(".criterion_description .container").height()
                );
            // the -10 here is the padding on the .container.
            $ratingsContainers.css('height', (maxHeight - 10) + 'px');
          }
        });
        rubricEditing.htmlBody.scrollTop(scrollTop);
      }
    },

    rubricData: function($rubric) {
      $rubric = $rubric.filter(":first");
      if(!$rubric.hasClass('editing')) {
        $rubric = $rubric.next(".editing");
      }
      $rubric.find(".criterion_points").each(function() {
        var val = $(this).val();
        $(this).parents(".criterion").find(".display_criterion_points").text(val);
      });
      var vals = $rubric.getFormData();
      $rubric.find(".rubric_title .title").text(vals.title);
      $rubric.find(".rubric_table caption .title").text(vals.title);
      var vals = $rubric.getTemplateData({textValues: ['title', 'description', 'rubric_total', 'rubric_association_id']});
      var data = {};
      data['rubric[title]'] = vals.title;
      data['rubric[points_possible]'] = vals.rubric_total;
      data['rubric_association[use_for_grading]'] = $rubric.find(".grading_rubric_checkbox").attr('checked') ? "1" : "0";
      data['rubric_association[hide_score_total]'] = "0";
      if(data['rubric_association[use_for_grading]'] == '0') {
        data['rubric_association[hide_score_total]'] = $rubric.find(".totalling_rubric_checkbox").attr('checked') ? "1" : "0";
      }
      data['rubric[free_form_criterion_comments]'] = $rubric.find(".rubric_custom_rating").attr('checked') ? "1" : "0";
      data['rubric_association[id]'] = vals.rubric_association_id;
      // make sure the association is always updated, see the comment on
      // RubricsController#update
      data['rubric_association_id'] = vals.rubric_association_id;
      var criterion_idx = 0;
      $rubric.find(".criterion:not(.blank)").each(function() {
        var $criterion = $(this);
        if(!$criterion.hasClass('learning_outcome_criterion')) {
          $criterion.find("span.mastery_points").text(parseFloat($criterion.find("input.mastery_points").val(), 10) || "0");
        }
        var vals = $criterion.getTemplateData({textValues: ['description', 'display_criterion_points', 'learning_outcome_id', 'mastery_points', 'long_description', 'criterion_id']});
        vals.long_description = $criterion.find("textarea.long_description").val();
        vals.mastery_points = $criterion.find("span.mastery_points").text();
        var pre_criterion = "rubric[criteria][" + criterion_idx + "]";
        data[pre_criterion + "[description]"] = vals.description;
        data[pre_criterion + "[points]"] = vals.display_criterion_points;
        data[pre_criterion + "[learning_outcome_id]"] = vals.learning_outcome_id;
        data[pre_criterion + "[long_description]"] = vals.long_description;
        data[pre_criterion + "[id]"] = vals.criterion_id;
        if ($criterion.hasClass('ignore_criterion_for_scoring')) {
          data[pre_criterion + "[ignore_for_scoring]"] = '1';
        }
        if(vals.learning_outcome_id) {
          data[pre_criterion + "[mastery_points]"] = vals.mastery_points;
        }
        var rating_idx = 0;
        $criterion.find(".rating").each(function() {
          var $rating = $(this);
          var vals = $rating.getTemplateData({textValues: ['description', 'points', 'rating_id']});
          var pre_rating = pre_criterion + "[ratings][" + rating_idx + "]";
          data[pre_rating + "[description]"] = vals.description;
          data[pre_rating + "[points]"] = vals.points;
          data[pre_rating + "[id]"] = vals.rating_id;
          rating_idx++;
        });
        criterion_idx++;
      });
      data.title = data['rubric[title]'];
      data.points_possible = data['rubric[points_possible]'];
      data.rubric_id = $rubric.attr('id').substring(7);
      data = $.extend(data, $("#rubrics #rubric_parameters").getFormData());
      return data;
    },
    addRubric: function() {
      var $rubric = $("#default_rubric").clone(true).attr('id', 'rubric_new').addClass('editing');
      $rubric.find(".edit_rubric").remove();
      var $tr = $("#edit_rubric").clone(true).show().removeAttr('id').addClass('edit_rubric');
      var $form = $tr.find("#edit_rubric_form");
      $rubric.find('.rubric_table').append($tr);
      $form.attr('method', 'POST').attr('action', $("#add_rubric_url").attr('href'));
      // I believe this should only be visible on the assignment page (not
      // rubric page or quiz page) but we need to audit uses of the add rubric
      // dialog before we make it that restrictive
      var $assignPoints = $("#assignment_show .points_possible,#rubrics.rubric_dialog .assignment_points_possible")
      var $quizPage = $("#quiz_show,#quiz_edit_wrapper")
      $form.find(".rubric_grading").showIf($assignPoints.length > 0 && $quizPage.length === 0);
      return $rubric;
    },
    editRubric: function($original_rubric, url) {
      var $rubric, data, $tr, $form;

      rubricEditing.isEditing = true;

      $rubric = $original_rubric.clone(true).addClass('editing');
      $rubric.find(".edit_rubric").remove();

      data = $rubric.getTemplateData({textValues: ['use_for_grading', 'free_form_criterion_comments', 'hide_score_total']});
      $original_rubric.hide().after($rubric.show());

      $tr = $("#edit_rubric").clone(true).show().removeAttr('id').addClass('edit_rubric');
      $form = $tr.find("#edit_rubric_form");
      $rubric.find('.rubric_table').append($tr);

      $rubric.find(":text:first").focus().select();
      $form.find(".grading_rubric_checkbox").attr('checked', data.use_for_grading == "true").triggerHandler('change');
      $form.find(".rubric_custom_rating").attr('checked', data.free_form_criterion_comments == "true").triggerHandler('change');
      $form.find(".totalling_rubric_checkbox").attr('checked', data.hide_score_total == "true").triggerHandler('change');
      var createText = I18n.t('buttons.create_rubric', "Create Rubric");
      var updateText = I18n.t('buttons.update_rubric', "Update Rubric");
      $form.find(".save_button").text($rubric.attr('id') == 'rubric_new' ? createText : updateText);
      $form.attr('method', 'PUT').attr('action', url);
      rubricEditing.sizeRatings();

      return $rubric;
    },
    hideEditRubric: function($rubric, remove) {
      rubricEditing.isEditing = false;
      $rubric = $rubric.filter(":first");
      if(!$rubric.hasClass('editing')) {
        $rubric = $rubric.next(".editing");
      }
      $rubric.removeClass('editing');
      $("#edit_criterion").hide().appendTo('body');
      $rubric.find(".edit_rubric").remove();
      if(remove) {
        if($rubric.attr('id') != 'rubric_new') {
          $display_rubric = $rubric.prev(".rubric");
          $display_rubric.show();
          $display_rubric.find('.rubric_title .title').focus();
        } else {
          $(".add_rubric_link").show().focus();
        }
        $rubric.remove();
      } else {
        $rubric.find(".rubric_title .links").show();
      }
    },
    updateRubric: function($rubric, rubric) {
      $rubric.find(".criterion:not(.blank)").remove();
      var $rating_template = $rubric.find(".rating:first").clone(true).removeAttr('id');
      $rubric.fillTemplateData({
        data: rubric,
        id: "rubric_" + rubric.id,
        hrefValues: ['id', 'rubric_association_id'],
        avoid: '.criterion'
      });
      $rubric.fillFormData(rubric);
      rubricEditing.isEditing = false;

      var url = $.replaceTags($rubric.find(".edit_rubric_url").attr('href'), 'rubric_id', rubric.id);
      $rubric.find(".edit_rubric_link").
        attr('href', url).
        showIf(rubric.permissions.update_association);

      url = $.replaceTags($rubric.find(".delete_rubric_url").attr('href'), 'association_id', rubric.rubric_association_id);
      $rubric.find(".delete_rubric_link").
        attr('href', url).
        showIf(rubric.permissions['delete_association']);

      $rubric.find(".find_rubric_link").
        showIf(rubric.permissions.update_association && !$("#rubrics").hasClass('raw_listing'));

      $rubric.find(".criterion:not(.blank) .ratings").empty();
      rubric.criteria.forEach(function(criterion) {
        criterion.display_criterion_points = criterion.points;
        criterion.criterion_id = criterion.id;
        var $criterion = $rubric.find(".criterion.blank:first").clone(true).show().removeAttr('id');
        $criterion.removeClass('blank');
        $criterion.fillTemplateData({data: criterion});
        $criterion.find(".long_description_holder").toggleClass('empty', !criterion.long_description);
        $criterion.find(".ratings").empty();
        $criterion.toggleClass('learning_outcome_criterion', !!criterion.learning_outcome_id);
        $criterion.toggleClass('ignore_criterion_for_scoring', !!criterion.ignore_for_scoring);
        var count = 0;
        criterion.ratings.forEach(function(rating) {
          count++;
          rating.rating_id = rating.id;
          var $rating = $rating_template.clone(true);
          $rating.toggleClass('edge_rating', count === 0 || count === criterion.ratings.length - 1);
          $rating.fillTemplateData({data: rating});
          $criterion.find(".ratings").append($rating);
        });
        $rubric.find(".summary").before($criterion);
        $criterion.find(".criterion_points").val(criterion.points).blur();
      });
      $rubric.find(".criterion:not(.blank)")
        .find(".ratings").showIf(!rubric.free_form_criterion_comments).end()
        .find(".custom_ratings").showIf(rubric.free_form_criterion_comments);
      $rubric.find('.rubric_title .title').focus();
    }
  };
  rubricEditing.sizeRatings = _.debounce(rubricEditing.originalSizeRatings, 10);

  var round = function(number, precision) {
    precision = Math.pow(10, precision || 0).toFixed(precision < 0 ? -precision : 0);
    return Math.round(number * precision) / precision;
  }



  rubricEditing.init = function() {
    var limitToOneRubric = true;
    var $rubric_dialog = $("#rubric_dialog"),
        $rubric_long_description_dialog = $("#rubric_long_description_dialog");

    rubricEditing.htmlBody = $('html,body');

    $("#rubrics")
    .delegate(".long_description_link", 'click', function(event) {
      event.preventDefault();
      var editing           = $(this).parents(".rubric").hasClass('editing'),
          $criterion        = $(this).parents(".criterion"),
          isLearningOutcome = $(this).parents(".criterion").hasClass("learning_outcome_criterion"),
          data              = $criterion.getTemplateData({textValues: ['long_description', 'description']});

      if(editing && !isLearningOutcome) {
        $rubric_long_description_dialog
          .fillFormData(data)
          .find('.editing').show()
          .find(".displaying").hide();
      } else {
        if(!isLearningOutcome) {
          // We want to prevent XSS in this dialog but users expect to have line
          // breaks preserved when they view the long description. Previously we
          // were letting fillTemplateData do the htmlEscape dance but that
          // wouldn't let us preserve the line breaks because it munged the <br>
          // tags we were inserting.
          //
          // Finally, we're not making any changes in the case of this being a
          // learning outcome criterion because they come from elsewhere in the
          // app and may have legitimate markup in the text (at least according
          // to the tests that broke while putting this together).
          data.long_description = htmlEscape(data.long_description).replace(/(\r?\n)/g, '<br>$1');
        }

        $rubric_long_description_dialog
          .fillTemplateData({data: data, htmlValues: ['long_description'], avoid: 'textarea'})
          .find(".displaying").show().end()
          .find('.editing').hide().end();
      }

      $rubric_long_description_dialog
        .data('current_criterion', $criterion)
        .dialog({
          title: I18n.t('titles.criterion_long_description', "Criterion Long Description"),
          width: 400
        }).fixDialogButtons().find("textarea:visible:first").focus().select();
    })
    .delegate(".find_rubric_link", 'click', function(event) {
      event.preventDefault();
      $rubric_dialog.dialog({
        width: 800,
        height: 380,
        resizable: true,
        title: I18n.t('titles.find_existing_rubric', 'Find Existing Rubric')
      });
      if(!$rubric_dialog.hasClass('loaded')) {
        $rubric_dialog.find(".loading_message").text(I18n.t('messages.loading_rubric_groups', "Loading rubric groups..."));
        var url = $rubric_dialog.find(".grading_rubrics_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          data.forEach(function(context) {
            var $context = $rubric_dialog.find(".rubrics_dialog_context_select.blank:first").clone(true).removeClass('blank');
            $context.fillTemplateData({
              data: {
                name: context.name,
                context_code: context.context_code,
                rubrics: context.rubrics + " rubrics"
              }
            });
            $rubric_dialog.find(".rubrics_dialog_contexts_select").append($context.show());
          });
          var codes = {};
          if(data.length == 0) {
            $rubric_dialog.find(".loading_message").text("No rubrics found");
          } else {
            $rubric_dialog.find(".loading_message").remove();
          }
          $rubric_dialog.find(".rubrics_dialog_rubrics_holder").slideDown();
          $rubric_dialog.find(".rubrics_dialog_contexts_select .rubrics_dialog_context_select:visible:first").click();
          $rubric_dialog.addClass('loaded');
        }, function(data) {
          $rubric_dialog.find(".loading_message").text(I18n.t('errors.load_rubrics_failed', "Loading rubrics failed, please try again"));
        });
      }
    })
    .delegate(".edit_rubric_link", 'click', function(event) {
      event.preventDefault();

      var $link   = $(this),
          $rubric = $link.parents('.rubric'),
          prompt  = I18n.t('prompts.read_only_rubric', "You can't edit this " +
                           "rubric, either because you don't have permission " +
                           "or it's being used in more than one place. Any " +
                           "changes you make will result in a new rubric based " +
                           "on the old rubric. Continue anyway?");

      if (rubricEditing.isEditing) return false;
      if (!$link.hasClass('copy_edit') || confirm(prompt)) {
        rubricEditing.editRubric($rubric, $link.attr('href'));
      }
    });

    // cant use delegate because events bound to a .delegate wont get triggered when you do .triggerHandler('click') because it wont bubble up.
    $(".rubric .delete_rubric_link").bind('click', function(event, callback) {
      event.preventDefault();
      var message = I18n.t('prompts.confirm_delete', "Are you sure you want to delete this rubric?");
      if(callback && callback.confirmationMessage) {
        message = callback.confirmationMessage;
      }
      $(this).parents(".rubric").confirmDelete({
        url: $(this).attr('href'),
        message: message,
        success: function() {
          $(this).fadeOut(function() {
            $(".add_rubric_link").show().focus();
            if(callback && $.isFunction(callback)) {
              callback();
            }
          });
        }
      });
    });

    $rubric_long_description_dialog.find(".save_button").click(function() {
      var long_description = $rubric_long_description_dialog.find("textarea.long_description").val(),
          $criterion       = $rubric_long_description_dialog.data('current_criterion');
      if($criterion) {
        $criterion.fillTemplateData({data: {long_description: long_description}});
        $criterion.find("textarea.long_description").val(long_description);
        $criterion.find(".long_description_holder").toggleClass('empty', !long_description);
      }
      $rubric_long_description_dialog.dialog('close');
    });
    $rubric_long_description_dialog.find(".cancel_button").click(function() {
      $rubric_long_description_dialog.dialog('close');
    });

    $(".add_rubric_link").click(function(event) {
      event.preventDefault();
      if($("#rubric_new").length > 0) { return; }
      if(limitToOneRubric && $("#rubrics .rubric:visible").length > 0) { return; }
      var $rubric = rubricEditing.addRubric();
      $("#rubrics").append($rubric.show());
      $rubric.find(":text:first").focus().select();
      if(limitToOneRubric) {
        $(".add_rubric_link").hide();
      }
    });

    $("#rubric_dialog")
    .delegate(".rubrics_dialog_context_select", 'click', function(event) {
      event.preventDefault();
      $(".rubrics_dialog_contexts_select .selected_side_tab").removeClass('selected_side_tab');
      var $link = $(this);
      $link.addClass('selected_side_tab');
      var context_code = $link.getTemplateData({textValues: ['context_code']}).context_code;
      if($link.hasClass('loaded')) {
        $rubric_dialog.find(".rubrics_loading_message").hide();
        $rubric_dialog.find(".rubrics_dialog_rubrics,.rubrics_dialog_rubrics_select").show();
        $rubric_dialog.find(".rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select").hide();
        $rubric_dialog.find(".rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select." + context_code).show();
        $rubric_dialog.find(".rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select:visible:first").click();
      } else {
        $rubric_dialog.find(".rubrics_loading_message").text(I18n.t('messages.loading_rubrics', "Loading rubrics...")).show();
        $rubric_dialog.find(".rubrics_dialog_rubrics,.rubrics_dialog_rubrics_select").hide();
        var url = $rubric_dialog.find(".grading_rubrics_url").attr('href') + "?context_code=" + context_code;
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $link.addClass('loaded');
          $rubric_dialog.find(".rubrics_loading_message").hide();
          $rubric_dialog.find(".rubrics_dialog_rubrics,.rubrics_dialog_rubrics_select").show();
          data.forEach(function(item) {
            var association = item.rubric_association;
            var rubric = association.rubric;
            var $rubric_select = $rubric_dialog.find(".rubrics_dialog_rubric_select.blank:first").clone(true);
            $rubric_select.addClass(association.context_code);
            rubric.criterion_count = rubric.data.length;
            $rubric_select.fillTemplateData({data: rubric}).removeClass('blank');
            $rubric_dialog.find(".rubrics_dialog_rubrics_select").append($rubric_select.show());
            var $rubric = $rubric_dialog.find(".rubrics_dialog_rubric.blank:first").clone(true);
            $rubric.removeClass('blank');
            $rubric.find(".criterion.blank").hide();
            rubric.rubric_total = rubric.points_possible;
            $rubric.fillTemplateData({
              data: rubric,
              id: 'rubric_dialog_' + rubric.id
            });
            rubric.data.forEach(function(criterion) {
              criterion.criterion_points = criterion.points;
              criterion.criterion_points_possible = criterion.points;
              criterion.criterion_description = criterion.description;
              var ratings = criterion['ratings'];
              delete criterion['ratings'];
              var $criterion = $rubric.find(".criterion.blank:first").clone().removeClass('blank');
              $criterion.fillTemplateData({
                data: criterion
              });
              $criterion.find(".rating_holder").addClass('blank');
              ratings.forEach(function(rating) {
                var $rating = $criterion.find(".rating_holder.blank:first").clone().removeClass('blank');
                rating.rating = rating.description;
                $rating.fillTemplateData({
                  data: rating
                });
                $criterion.find(".ratings").append($rating.show());
              });
              $criterion.find(".rating_holder.blank").remove();
              $rubric.find(".rubric.rubric_summary tr.summary").before($criterion.show());
            });
            $rubric_dialog.find(".rubrics_dialog_rubrics").append($rubric);
          });
          $rubric_dialog.find(".rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select").hide();
          $rubric_dialog.find(".rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select." + context_code).show();
          $rubric_dialog.find(".rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select:visible:first").click();
        }, function(data) {
          $rubric_dialog.find(".rubrics_loading_message").text("Loading rubrics failed, please try again");
        });
      }
    })
    .delegate(".rubrics_dialog_rubric_select", 'click', function(event) {
      event.preventDefault();
      var $select = $(this);
      $select.find("a").focus();
      var id = $select.getTemplateData({textValues: ['id']}).id;
      $(".rubric_dialog .rubrics_dialog_rubric_select").removeClass('selected_side_tab'); //.css('fontWeight', 'normal');
      $select.addClass('selected_side_tab');
      $(".rubric_dialog .rubrics_dialog_rubric").hide();
      $(".rubric_dialog #rubric_dialog_" + id).show();
    })
    .delegate(".select_rubric_link", 'click', function(event) {
      event.preventDefault();
      var data = {};
      var params = $rubric_dialog.getTemplateData({textValues: ['rubric_association_type', 'rubric_association_id', 'rubric_association_purpose']});
      data['rubric_association[association_type]'] = params.rubric_association_type;
      data['rubric_association[association_id]'] = params.rubric_association_id;
      data['rubric_association[rubric_id]'] = $(this).parents(".rubrics_dialog_rubric").getTemplateData({textValues: ['id']}).id;
      data['rubric_association[purpose]'] = params.rubric_association_purpose;
      $rubric_dialog.loadingImage();
      var url = $rubric_dialog.find(".select_rubric_url").attr('href');
      $.ajaxJSON(url, 'POST', data, function(data) {
        $rubric_dialog.loadingImage('remove');
        var $rubric = $("#rubrics .rubric:visible:first");
        if($rubric.length === 0) {
          $rubric = rubricEditing.addRubric();
        }
        var rubric = data.rubric;
        rubric.rubric_association_id = data.rubric_association.id;
        rubric.permissions = rubric.permissions || {};
        if(data.rubric_association.permissions) {
          rubric.permissions.update_association = data.rubric_association.permissions.update;
          rubric.permissions.delete_association = data.rubric_association.permissions['delete'];
        }
        rubricEditing.updateRubric($rubric, rubric);
        rubricEditing.hideEditRubric($rubric, false);
        $rubric_dialog.dialog('close');
      }, function() {
        $rubric_dialog.loadingImage('remove');
      });
    });

    $rubric_dialog.find(".cancel_find_rubric_link").click(function(event) {
      event.preventDefault();
      $rubric_dialog.dialog('close');
    });
    $rubric_dialog.find(".rubric_brief").find(".expand_data_link,.collapse_data_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".rubric_brief").find(".expand_data_link,.collapse_data_link").toggle().end()
        .find(".details").slideToggle();
    });

    var forceSubmit = false,
        skipPointsUpdate = false;
    $("#edit_rubric_form").formSubmit({
      processData: function(data) {
        var $rubric = $(this).parents(".rubric");
        if (!$rubric.find(".criterion:not(.blank)").length) return false;
        var data = rubricEditing.rubricData($rubric);
        if (data['rubric_association[use_for_grading]'] == '1') {
          var assignmentPoints = parseFloat($("#assignment_show .points_possible, .discussion-title .discussion-points").text());
          var rubricPoints = parseFloat(data.points_possible);
          if (assignmentPoints != null && assignmentPoints != undefined && rubricPoints != assignmentPoints && !forceSubmit) {
            var $confirmDialog = $(changePointsPossibleToMatchRubricDialog({
              assignmentPoints: assignmentPoints,
              rubricPoints: rubricPoints
            }));
            var closeDialog = function(skip){
              forceSubmit = true;
              skipPointsUpdate = skip === true;
              $confirmDialog.remove();
              $("#edit_rubric_form").submit();
            };
            $confirmDialog.dialog({
              buttons: {
                "Change" : closeDialog,
                "Leave different" : function(){ closeDialog(true); }
              },
              width: 320,
              resizable: false,
              close: $confirmDialog.remove
            });
            return false;
          }
        }
        data.skip_updating_points_possible = skipPointsUpdate;
        skipPointsUpdate = false;
        forceSubmit = false;
        return data;
      },
      beforeSubmit: function(data) {
        var $rubric = $(this).parents(".rubric");
        $rubric.find(".rubric_title .title").text(data['rubric[title]']);
        $rubric.find(".rubric_table caption .title").text(data['rubric[title]']);
        $rubric.find(".rubric_total").text(data['points_possible']);
        $rubric.removeClass('editing');
        if($rubric.attr('id') == 'rubric_new') {
          $rubric.attr('id', 'rubric_adding');
        } else {
          $rubric.prev(".rubric").remove();
        }
        $(this).parents("tr").hide();
        $rubric.loadingImage();
        return $rubric;
      },
      success: function(data, $rubric) {
        var rubric = data.rubric;
        $rubric.loadingImage('remove');
        rubric.rubric_association_id = data.rubric_association.id;
        rubric.permissions = rubric.permissions || {};
        if(data.rubric_association.permissions) {
          rubric.permissions.update_association = data.rubric_association.permissions.update;
          rubric.permissions.delete_association = data.rubric_association.permissions['delete'];
        }
        rubricEditing.updateRubric($rubric, rubric);
        if (data.rubric_association && data.rubric_association.use_for_grading && !data.rubric_association.skip_updating_points_possible) {
          $("#assignment_show .points_possible").text(rubric.points_possible);
          discussion_points_text = I18n.t('discussion_points_possible',
                                          {one: '%{count} point possible', other: '%{count} points possible' },
                                          {count: rubric.points_possible || 0})
          $(".discussion-title .discussion-points").text(discussion_points_text);
        }
        $rubric.find(".rubric_title .links:not(.locked)").show();
      }
    });

    $("#edit_rubric_form .cancel_button").click(function() {
      rubricEditing.hideEditRubric($(this).parents(".rubric"), true);
    });

    $("#rubrics").delegate('.add_criterion_link', 'click', function(event) {
      var $criterion = rubricEditing.addCriterion($(this).parents(".rubric")); //"#default_rubric"));
      rubricEditing.editCriterion($criterion);
      return false;
    }).delegate('.criterion_description_value', 'click', function(event) {
      var $criterion = $(this).parents(".criterion")
      rubricEditing.editCriterion($criterion);
      return false;
    }).delegate('.edit_criterion_link', 'click', function(event) {
      var $criterion = $(this).parents(".criterion")
      rubricEditing.editCriterion($criterion);
      return false;
    }).delegate('.delete_criterion_link', 'click', function(event) {
      var $criterion = $(this).parents(".criterion");
      $criterion.fadeOut(function() {
        var $rubric = $criterion.parents(".rubric");
        $criterion.remove();
        rubricEditing.updateCriteria($rubric);
        rubricEditing.updateRubricPoints($rubric);
      });
      return false;
    }).delegate('.rating_description_value,.edit_rating_link', 'click', function(event) {
      rubricEditing.editRating($(this).parents(".rating"));
      return false;
    }).bind('mouseover', function(event) {
      $target = $(event.target);
      if(!$target.closest('.ratings').length) {
        rubricEditing.hideCriterionAdd($target.parents('.rubric'));
      }
    }).delegate('.rating', 'mousemove', function(event) {
      var $this   = $(this),
          $rubric = $this.parents(".rubric");
      if($rubric.find(".rating.editing").length > 0 || $this.parents(".criterion").hasClass('learning_outcome_criterion')) {
        rubricEditing.hideCriterionAdd($rubric);
        return false;
      }
      var expandPadding = 10;
      if(!$.data(this, 'hover_offset')) {
        $.data(this, 'hover_offset', $this.offset());
        $.data(this, 'hover_width', $this.outerWidth());
        var points = $.data(this, 'points', parseFloat($this.find(".points").text()));
        var prevPoints = $.data(this, 'prev_points', parseFloat($this.prev(".rating").find(".points").text()));
        var nextPoints = $.data(this, 'next_points', parseFloat($this.next(".rating").find(".points").text()));
        $.data(this, 'prev_diff', Math.abs(points - prevPoints));
        $.data(this, 'next_diff', Math.abs(points - nextPoints));
      }
      var offset = $.data(this, 'hover_offset');
      var width = $.data(this, 'hover_width');
      var $ratings = $this.parents(".ratings");
      var x = event.pageX;
      var y = event.pageY;
      var leftSide = false;
      if(x <= offset.left + (width / 2)) {
        leftSide = true;
      }
      var $lastHover = $ratings.data('hover_rating');
      var lastLeftSide = $ratings.data('hover_left_side');
      if(!$lastHover || $this[0] != $lastHover[0] || leftSide != lastLeftSide) {
        rubricEditing.hideCriterionAdd($rubric);
        var $prevRating, $nextRating;
        if(leftSide && ($prevRating = $this.prev(".rating")) && $prevRating.length) {// && $(this).data('prev_diff') > 1) {
          $this.addClass('add_left');
          $prevRating.addClass('add_right');
          $this[(x <= offset.left + expandPadding) ? 'addClass': 'removeClass']('add_column');
        } else if(!leftSide && ($nextRating = $this.next(".rating")) && $nextRating.length) {// && $(this).data('next_diff') > 1) {
          $this.addClass('add_right');
          $nextRating.addClass('add_left');
          $this[(x >= offset.left + width - expandPadding) ? 'addClass' : 'removeClass']('add_column');
        }
      } else if($lastHover) {
        if(leftSide) {
          if(x <= offset.left + expandPadding && $.data(this, 'prev_diff') > 1) {
            $this.addClass('add_column');
          } else {
            $this.removeClass('add_column');
          }
        } else {
          if(x >= offset.left + width - expandPadding && $.data(this, 'next_diff') > 1) {
            $this.addClass('add_column');
          } else {
            $this.removeClass('add_column');
          }
        }
      }
      return false;
    }).delegate('.rating', 'mouseout', function(event) {
      $(this).data('hover_offset', null).data('hover_width', null);
    }).delegate('.delete_rating_link', 'click', function(event) {
      event.preventDefault();
      rubricEditing.hideCriterionAdd($(this).parents(".rubric"));
      $(this).parents(".rating").fadeOut(function() {
        var $criterion = $(this).parents(".criterion");
        $(this).remove();
        rubricEditing.sizeRatings($criterion);
      });
    }).delegate('.add_column', 'click', function(event) {
      var $this = $(this),
          $rubric = $this.parents(".rubric");
      if($rubric.hasClass('editing')){
        var $td = $this.clone(true).removeClass('edge_rating'),
            pts = parseFloat($this.find(".points").text()),
            $criterion = $this.parents(".criterion"),
            $criterionPoints = $criterion.find(".criterion_points"),
            criterion_total = parseFloat($criterionPoints.val(), 10) || 5,
            data = { description: "Rating Description" },
            hasClassAddLeft = $this.hasClass('add_left');
        if($this.hasClass('add_left')) {
          var more_points = parseFloat($this.prev(".rating").find(".points").text());
          data.points = Math.round((pts + more_points) / 2);
          if(data.points == pts || data.points == more_points) {
            data.points = pts;
          }
        } else {
          var less_points = parseFloat($this.next(".rating").find(".points").text());
          data.points = Math.round((pts + less_points) / 2);
          if(data.points == pts || data.points == less_points) {
            data.points = less_points;
          }
        }
        $td.fillTemplateData({data: data});
        if(hasClassAddLeft) {
          $this.before($td);
        } else {
          $this.after($td);
        }
        rubricEditing.hideCriterionAdd($rubric);
        rubricEditing.updateCriterionPoints($criterion);
        rubricEditing.sizeRatings($criterion);
      }
      return false;
    });
    $(".criterion_points").keydown(function(event) {
      if(event.keyCode == 13) {
        rubricEditing.updateCriterionPoints($(this).parents(".criterion"));
        $(this).blur();
      }
    }).blur(function(event) {
      rubricEditing.updateCriterionPoints($(this).parents(".criterion"));
    });
    $("#edit_criterion").delegate(".cancel_button", 'click', function(event) {
      rubricEditing.hideEditCriterion();
    });
    $("#edit_criterion_form").submit(function(event) {
      event.preventDefault();
      event.stopPropagation();
      var data = $(this).parents("#edit_criterion").getFormData();
      data.criterion_description_value = data.description;
      delete data['description'];
      $(this).parents(".criterion").fillTemplateData({data: data});
      rubricEditing.hideEditCriterion();
    });
    $("#edit_rating").delegate(".cancel_button", 'click', function(event) {
      rubricEditing.hideEditRating();
    });
    $("#edit_rating_form").submit(function(event) {
      event.preventDefault();
      event.stopPropagation();
      var data = $(this).parents("#edit_rating").getFormData();
      data.points = parseFloat(data.points);
      if(isNaN(data.points)) {
        data.points = parseFloat($(this).parents(".criterion").find(".criterion_points").val());
        if(isNaN(data.points)) { data.points = 5; }
      }
      var $rating = $(this).parents(".rating");
      $rating.fillTemplateData({data: data});
      if($rating.prev(".rating").length === 0) {
        $(this).parents(".criterion").find(".criterion_points").val(data.points);
      }
      rubricEditing.updateCriterionPoints($(this).parents(".criterion"), true);
    });
    $("#edit_rubric_form .rubric_custom_rating").change(function() {
      $(this).parents(".rubric").find("tr.criterion")
        .find(".ratings").showIf(!$(this).attr('checked')).end()
        .find(".custom_ratings").showIf($(this).attr('checked'));
    }).triggerHandler('change');
    $("#edit_rubric_form #totalling_rubric").change(function() {
      $(this).parents(".rubric").find(".total_points_holder").showIf(!$(this).attr('checked'));
    });
    $("#edit_rubric_form .grading_rubric_checkbox").change(function() {
      $(this).parents(".rubric").find(".totalling_rubric").css('visibility', $(this).attr('checked') ? 'hidden' : 'visible');
      $(this).parents(".rubric").find(".totalling_rubric_checkbox").attr('checked', false);
    }).triggerHandler('change');
    $("#criterion_blank").find(".criterion_points").val("5");
    if($("#default_rubric").find(".criterion").length <= 1) {
      rubricEditing.addCriterion($("#default_rubric"));
    }
    setInterval(rubricEditing.sizeRatings, 10000);
    $.publish('edit_rubric/initted')
  };

  return rubricEditing;
});

