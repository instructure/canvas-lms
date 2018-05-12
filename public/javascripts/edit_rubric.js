/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import ReactDOM from 'react-dom'
import RubricAddCriterionPopover from 'jsx/rubrics/RubricAddCriterionPopover'
import I18n from 'i18n!edit_rubric'
import changePointsPossibleToMatchRubricDialog from 'jst/changePointsPossibleToMatchRubricDialog'
import $ from 'jquery'
import _ from 'underscore'
import htmlEscape from './str/htmlEscape'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import 'find_outcome'
import './jquery.ajaxJSON'
import './jquery.instructure_forms' /* formSubmit, fillFormData, getFormData */
import 'jqueryui/dialog'
import './jquery.instructure_misc_helpers' /* replaceTags */
import './jquery.instructure_misc_plugins'  /* confirmDelete, showIf */
import './jquery.loadingImg'
import './jquery.templateData' /* fillTemplateData, getTemplateData */
import 'compiled/jquery.rails_flash_notifications'
import 'vendor/jquery.ba-tinypubsub'
import './vendor/jquery.scrollTo'
import 'compiled/jquery/fixDialogButtons'

  var rubricEditing = {
    htmlBody: null,

    localizedPoints: function(points) {
      return I18n.n(points, {precision: 2, strip_insignificant_zeros: true})
    },
    updateCriteria: function($rubric) {
      $rubric.find(".criterion:not(.blank)").each(function(i) {
        $(this).attr('id', 'criterion_' + (i + 1));
      });
    },
    updateAddCriterionLinks($rubric, focusTarget = null) {
      if (!$rubric.is(":visible") || $rubric.find("#add_criterion_holder").length === 0) { return; }
      $("#add_criterion_container").remove();
      $rubric.find("#add_criterion_holder").append($('<span/>').attr('id', 'add_criterion_container'));
      setTimeout(() => {
        ReactDOM.render(
          <RubricAddCriterionPopover rubric={$rubric} duplicateFunction={rubricEditing.copyCriterion} />,
          document.getElementById("add_criterion_container")
        );
        if (focusTarget) {
          $rubric.find(`"#add_criterion_container ${focusTarget}:visible`).focus()
        }
      }, 0)
    },
    copyCriterion($rubric, criterion_index) {
      const $criterion = rubricEditing.addCriterion($rubric, criterion_index);
      $criterion.removeClass("new_criterion");
      $criterion.find(".criterion_id").text("blank");
      $criterion.find(".rating_id").text("blank");
      rubricEditing.editCriterion($criterion);
    },
    addCriterion($rubric, criterion_index) {
      let $blank;
      if (typeof criterion_index !== "undefined") {
        $blank = $rubric.find(`.criterion:not(.blank):eq(${criterion_index})`)
      } else {
        $blank = $rubric.find(".criterion.blank:first");
      }
      var $criterion = $blank.clone(true);
      $criterion.addClass("new_criterion");
      $criterion.removeClass('blank');
      $rubric.find(".summary").before($criterion.show());
      const focusTarget = $criterion.hasClass("learning_outcome_criterion") ? '.icon-plus' : null
      rubricEditing.updateCriteria($rubric);
      rubricEditing.sizeRatings($criterion);
      rubricEditing.updateAddCriterionLinks($rubric, focusTarget);
      return $criterion;
    },
    addNewRatingColumn: function($this) {
      var $rubric = $this.parents(".rubric");
      $this.addClass('add_column');
      if($rubric.hasClass('editing')){
        var $td = $this.clone(true).removeClass('edge_rating'),
            pts = numberHelper.parse($this.find(".points").text()),
            $criterion = $this.parents(".criterion"),
            $criterionPoints = $criterion.find(".criterion_points"),
            data = { description: "", rating_long_description: "", min_points: pts },
            hasClassAddLeft = $this.hasClass('add_left');
        if($this.hasClass('add_left')) {
          var more_points = numberHelper.parse($this.prev(".rating").find(".points").text());
          data.points = Math.round((pts + more_points) / 2);
          if(data.points == pts || data.points == more_points) {
            data.points = pts;
          }
        } else {
          var less_points = numberHelper.parse($this.next(".rating").find(".points").text());
          data.min_points = less_points;
          data.points = Math.round((pts + less_points) / 2);
          if(data.points == pts || data.points == less_points) {
            data.points = less_points;
          }
        }
        $td.fillTemplateData({data: data});
        rubricEditing.flagInfinitesimalRating($td, $criterion.find('.criterion_use_range').attr('checked'));
        if(hasClassAddLeft) {
          $this.before($td);
        } else {
          $td.addClass("new_rating")
          $this.after($td);
        }
        const $previousRating = $td.prev('.rating')
        if ($previousRating) {
          $previousRating.fillTemplateData({data: {min_points: data.points} })
        }
        rubricEditing.hideCriterionAdd($rubric);
        rubricEditing.updateCriterionPoints($criterion);
        rubricEditing.sizeRatings($criterion);
        setTimeout(function() {
          $.screenReaderFlashMessageExclusive(I18n.t("New Rating Created"));
          $(".new_rating").find(".edit_rating_link").click();
        }, 100);
      }
      return false;
    },
    onFindOutcome: function(outcome) {
      var $rubric = $('.rubric table.rubric_table:visible:first'),
          $criterion;

      $rubric.find(".criterion.learning_outcome_" + outcome.id).find(".delete_criterion_link").click();
      rubricEditing.addCriterion($rubric);

      $criterion = $rubric.find('.criterion:not(.blank):last');
      $criterion.removeClass("new_criterion");
      $criterion.toggleClass('ignore_criterion_for_scoring', !outcome.useForScoring);
      $criterion.find('.mastery_points').val(outcome.get('mastery_points'));
      $criterion.addClass('learning_outcome_criterion');
      $criterion.find('.outcome_sr_content').attr('aria-hidden', false)
      $criterion.find('.learning_outcome_id').text(outcome.id);
      $criterion.find('.hide_when_learning_outcome').hide();
      $criterion.find(".criterion_points").val(outcome.get('ratings')[0].points).blur();

      for (var i = 0; i < outcome.get('ratings').length - 2; i++) {
        $criterion.find('.rating:not(.blank):first').addClass('add_column').click();
      }

      $criterion.find('.rating:not(.blank)').each(function(i) {
        var rating = outcome.get('ratings')[i];
        $(this).fillTemplateData({data: rating});
      });

      $criterion.find(".cancel_button").click();

      $criterion.find("div.long_description").remove();
      $criterion.find("textarea.long_description").text(outcome.get('description'));
      $criterion.find(".long_description_holder").toggleClass('empty', !outcome.get('description'));

      $criterion.find(".description_title").text(outcome.get('title'));
      $criterion.find(".criterion_description").val(outcome.get('title')).focus().select();

      $criterion.find(".mastery_points").text(outcome.get('mastery_points'));
      $criterion.find(".edit_criterion_link").remove();
      $criterion.find(".rating .links").remove();
      rubricEditing.updateAddCriterionLinks($rubric, '.icon-search');
      $criterion.find(".long_description_holder").show();
    },
    hideCriterionAdd: function($rubric) {
      $rubric.find('.add_right, .add_left, .add_column').removeClass('add_left add_right add_column');
    },
    updateRubricPoints: function($rubric) {
      var total = 0;
      $rubric.find(".criterion:not(.blank):not(.ignore_criterion_for_scoring) .criterion_points").each(function() {
        var points = numberHelper.parse($(this).val());
        if(!isNaN(points)) {
          total += points;
        }
      });
      total = round(total, 2);
      $rubric.find(".rubric_total").text(rubricEditing.localizedPoints(total));
    },
    updateCriterionPoints: function($criterion, baseOnRatings) {
      var ratings = $.makeArray($criterion.find(".rating")).reverse();
      var rating_points = -1;
      var points = numberHelper.parse($criterion.find(".criterion_points").val());
      const use_range = $criterion.find('.criterion_use_range').attr('checked')
      if(isNaN(points)) {
        points = 5;
      } else {
        points = round(points, 2);
      }
      $criterion.find(".rating:first .points").text(rubricEditing.localizedPoints(points));
      // From right to left, make sure points never decrease
      // and round to 2 decimal places.
      $.each(ratings, function(i, rating) {
        var $rating = $(rating);
        var data = $rating.getTemplateData({textValues: ['points']});
        data.points = numberHelper.parse(data.points);
        if(data.points < rating_points) {
          data.points = rating_points;
        }
        data.points = round(data.points, 2);
        rating_points = data.points;
        data.points = rubricEditing.localizedPoints(data.points);
        $rating.fillTemplateData({data: data});
        rubricEditing.flagInfinitesimalRating($rating, use_range);
      });
      if(baseOnRatings && rating_points > points) { points = rating_points; }
      $criterion.find(".criterion_points").val(rubricEditing.localizedPoints(points));
      $criterion.find(".display_criterion_points").text(rubricEditing.localizedPoints(points));
      if(!$criterion.data('criterion_points') || numberHelper.parse($criterion.data('criterion_points')) != points) {
        if(!$criterion.data('criterion_points')) {
          var pts = $criterion.find(".rating:first .points").text();
          $criterion.data('criterion_points', numberHelper.parse(pts));
        }
        var oldMax = numberHelper.parse($criterion.data('criterion_points'));
        var newMax = points;
        if (oldMax !== newMax) {
          var $ratingList = $criterion.find(".rating");
          $($ratingList[0]).find(".points").text(rubricEditing.localizedPoints(points));
          var lastPts = points;
          // From left to right, scale points proportionally to new range.
          // So if originally they were 3,2,1 and now we increased the
          // total possible to 9, they'd be 9,6,3
          for(var i = 1; i < $ratingList.length - 1; i++) {
            var pts = numberHelper.parse($($ratingList[i]).find(".points").text());
            var newPts = Math.round((pts / oldMax) * newMax);
            if(isNaN(pts) || (pts == 0 && lastPts > 0)) {
              newPts = lastPts - Math.round(lastPts / ($ratingList.length - i));
            }
            if(newPts >= lastPts) {
              newPts = lastPts - 1;
            }
            newPts = Math.max(0, newPts);
            lastPts = newPts;
            $($ratingList[i]).find(".points").text(rubricEditing.localizedPoints(newPts));
            rubricEditing.flagInfinitesimalRating($($ratingList[i]), use_range);
            if (i > 0) {
              $($ratingList[i - 1]).find('.min_points').text(rubricEditing.localizedPoints(newPts));
              rubricEditing.flagInfinitesimalRating($($ratingList[i - 1]), use_range);
            }
          }
        }
        $criterion.data('criterion_points', points);
      }
      rubricEditing.updateRubricPoints($criterion.parents(".rubric"));
    },
    flagInfinitesimalRating($rating, use_range) {
      const data = $rating.getTemplateData({textValues: ['points', 'min_points']});
      if (numberHelper.parse(data.min_points) === numberHelper.parse(data.points)) {
        $rating.addClass("infinitesimal");
        $rating.find(".range_rating").hide()
      }
      else {
        $rating.removeClass("infinitesimal");
        $rating.find(".range_rating").showIf(use_range)
      }
    },
    capPointChange(points, $neighbor, action, compare_target) {
      const data = $neighbor.getTemplateData({textValues: [compare_target]});
      return rubricEditing.localizedPoints(action(points, numberHelper.parse(data[compare_target])));
    },
    editCriterion: function($criterion) {
      if(!$criterion.parents(".rubric").hasClass('editing')) { return; }
      if($criterion.hasClass('learning_outcome_criterion')) { return; }
      $criterion.find(".edit_criterion_link").click()
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
                  $this.find(".criterion_description .container .description_content").height()
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
        const use_range = !!$criterion.find('.criterion_use_range').attr('checked');
        if(!$criterion.hasClass('learning_outcome_criterion')) {
          var masteryPoints = $criterion.find("input.mastery_points").val();
          $criterion.find("span.mastery_points").text(numberHelper.validate(masteryPoints) ? masteryPoints : 0);
        }
        var vals = $criterion.getTemplateData({textValues: ['description', 'display_criterion_points', 'learning_outcome_id', 'mastery_points', 'long_description', 'criterion_id']});
        if($criterion.hasClass('learning_outcome_criterion')) {
          vals.long_description = $criterion.find("textarea.long_description").val();
        }
        vals.mastery_points = $criterion.find("span.mastery_points").text();
        var pre_criterion = "rubric[criteria][" + criterion_idx + "]";
        data[pre_criterion + "[description]"] = vals.description;
        data[pre_criterion + "[points]"] = vals.display_criterion_points;
        data[pre_criterion + "[learning_outcome_id]"] = vals.learning_outcome_id;
        data[pre_criterion + "[long_description]"] = vals.long_description;
        data[pre_criterion + "[id]"] = vals.criterion_id;
        data[pre_criterion + "[criterion_use_range]"] = use_range;
        if ($criterion.hasClass('ignore_criterion_for_scoring')) {
          data[pre_criterion + "[ignore_for_scoring]"] = '1';
        }
        if(vals.learning_outcome_id) {
          data[pre_criterion + "[mastery_points]"] = vals.mastery_points;
        }
        var rating_idx = 0;
        $criterion.find(".rating").each(function() {
          var $rating = $(this);
          const rating_vals = $rating.getTemplateData({textValues: ['description', 'rating_long_description', 'points', 'rating_id']});
          var pre_rating = pre_criterion + "[ratings][" + rating_idx + "]";
          data[pre_rating + "[description]"] = rating_vals.description;
          data[pre_rating + "[long_description]"] = rating_vals.rating_long_description;
          data[pre_rating + "[points]"] = numberHelper.parse(rating_vals.points);
          data[pre_rating + "[id]"] = rating_vals.rating_id;
          rating_idx++;
        });
        criterion_idx++;
      });
      data.title = data['rubric[title]'];
      data.points_possible = numberHelper.parse(data['rubric[points_possible]']);
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
      $("#add_criterion_container").remove();
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
      rubricEditing.updateAddCriterionLinks($rubric);

      return $rubric;
    },
    hideEditRubric: function($rubric, remove) {
      rubricEditing.isEditing = false;
      $rubric = $rubric.filter(":first");
      if(!$rubric.hasClass('editing')) {
        $rubric = $rubric.next(".editing");
      }
      $rubric.removeClass('editing');
      $rubric.find(".edit_rubric").remove();
      if(remove) {
        if($rubric.attr('id') != 'rubric_new') {
          var $display_rubric = $rubric.prev(".rubric");
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
        $criterion.find('.criterion_use_range').attr('checked', criterion.criterion_use_range === true);
        $criterion.find(".ratings").empty();
        $criterion.find('.hide_when_learning_outcome').showIf(!criterion.learning_outcome_id);
        $criterion.toggleClass('learning_outcome_criterion', !!criterion.learning_outcome_id);
        $criterion.toggleClass('ignore_criterion_for_scoring', !!criterion.ignore_for_scoring);
        $criterion.find('.outcome_sr_content').attr('aria-hidden', !criterion.learning_outcome_id);
        if (criterion.learning_outcome_id) {
          $criterion.find(".long_description_holder").show();
          $criterion.find("div.long_description").remove();
          if (criterion.long_description) {
            $criterion.find(".long_description_link").removeClass("hidden");
          }
        }
        var count = 0;
        criterion.ratings.forEach(function(rating) {
          count++;
          rating.rating_id = rating.id;
          rating.rating_long_description = rating.long_description;
          rating.min_points = 0
          if (count < criterion.ratings.length) {
            rating.min_points = rubricEditing.localizedPoints(criterion.ratings[count].points)
          }
          var $rating = $rating_template.clone(true);
          $rating.toggleClass('edge_rating', count === 1 || count === criterion.ratings.length);
          $rating.fillTemplateData({data: rating});
          $rating.find('.range_rating').showIf(criterion.criterion_use_range === true && rating.min_points !== rating.points);
          $criterion.find(".ratings").append($rating);
        });
        if (criterion.learning_outcome_id) {
          $criterion.find(".edit_criterion_link").remove();
          $criterion.find(".rating .links").remove();
        }
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
    var limitToOneRubric = !$("#rubrics").hasClass('raw_listing');
    var $rubric_dialog = $("#rubric_dialog"),
        $rubric_long_description_dialog = $("#rubric_long_description_dialog"),
        $rubric_rating_dialog = $("#rubric_rating_dialog");

    rubricEditing.htmlBody = $('html,body');

    $("#rubrics")
    .delegate(".edit_criterion_link, .long_description_link", 'click', function(event) {
      event.preventDefault();
      var editing           = $(this).parents(".rubric").hasClass('editing'),
          $criterion        = $(this).parents(".criterion"),
          isLearningOutcome = $(this).parents(".criterion").hasClass("learning_outcome_criterion"),
          title             = I18n.t("Edit Criterion"),
          data              = $criterion.getTemplateData({textValues: ['long_description', 'description']});

      if(editing && !isLearningOutcome) {
        // Override the default description if this is a new criterion.
        if ($criterion.hasClass("new_criterion")) {
          data.description = ""
          title = I18n.t("Add Criterion")
          $rubric_long_description_dialog.find('.save_button').text(I18n.t("Create Criterion"))
        }
        else {
          $rubric_long_description_dialog.find('.save_button').text(I18n.t("Update Criterion"))
        }
        $rubric_long_description_dialog
          .fillFormData(data).fillTemplateData({data: data})
          .find('.editing').show().end()
          .find(".displaying").hide().end();
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
        title = I18n.t("Criterion Long Description")
        $rubric_long_description_dialog
          .fillTemplateData({data: data, htmlValues: ['description', 'long_description'], avoid: 'textarea'})
          .find(".displaying").show().end()
          .find('.editing').hide().end();
      }

      const closeFunction = function() {
        // If the criterion is still in the new state (user either canceled or closed dialog)
        // delete the criterion.
        if ($criterion.hasClass("new_criterion")) {
          setTimeout(() => {
            $.screenReaderFlashMessageExclusive(I18n.t("New Criterion Canceled"));
          }, 100);
          $criterion.find(".delete_criterion_link").click();
        }
      };

      const beforeCloseFunction = function() {
        if ($criterion.hasClass("new_criterion")) {
          $criterion.parents('.rubric_container').first().find("#add_criterion_container .icon-plus").focus()
        } else {
          $criterion.find('.edit_criterion_link').focus()
        }
      };

      $rubric_long_description_dialog
        .data('current_criterion', $criterion)
        .dialog({
          title: title,
          width: 416,
          buttons: [],
          close: closeFunction,
          beforeClose: beforeCloseFunction
        });

      if(editing && !isLearningOutcome) {
        $rubric_long_description_dialog.fixDialogButtons();
      }
    })
    .delegate(".edit_rating_link", 'click', function(event) {
      event.preventDefault();
      const $criterion = $(this).parents(".criterion");
      const $rating = $(this).parents(".rating");
      const data = $rating.getTemplateData({textValues: ['description', 'points', 'min_points', 'rating_long_description']});
      const criterion_data = $criterion.getTemplateData({textValues: ['description']});

      if(!$rating.parents(".rubric").hasClass('editing')) { return; }
      if($rating.parents(".criterion").hasClass('learning_outcome_criterion')) { return; }
      const $nextRating = $rating.closest('td').next('.rating')
      const use_range = $rating.parents('.criterion').find('.criterion_use_range').attr('checked')
      $rubric_rating_dialog.find('.range_rating').showIf(use_range);
      $rubric_rating_dialog.find('.min_points').prop('disabled', !$nextRating.length)
      rubricEditing.hideCriterionAdd($rating.parents(".rubric"));
      $rubric_rating_dialog.find('#edit_rating_form_criterion_description').text(criterion_data.description)
      const points_element = $rubric_rating_dialog.find("#points")
      if (use_range) {
        points_element.attr("aria-labelledby", "rating_form_max_score_label");
        points_element.attr("placeholder", I18n.t("max"));
      } else {
        points_element.attr("aria-labelledby", "rating_form_score_label");
        points_element.removeAttr("placeholder");
      }
      let close_function = function() {
        const $current_rating = $rubric_rating_dialog.data('current_rating');
        // If the rating is still in the new state (user either canceled or closed dialog)
        // delete the rating.
        if ($current_rating.hasClass("new_rating")) {
          setTimeout(function() {
            $.screenReaderFlashMessageExclusive(I18n.t("New Rating Canceled"));
          }, 100);
          $current_rating.find(".delete_rating_link").click();
        }
      };
      $rubric_rating_dialog
        .fillFormData(data)
        .find('.editing').show().end()
        .find(".displaying").hide().end();
      $rubric_rating_dialog
        .data('current_criterion', $criterion)
        .data('current_rating', $rating)
        .dialog({
          title: I18n.t('titles.edit_rubric_rating', "Edit Rating"),
          width: 400,
          buttons: [],
          close: close_function
        });
      $rubric_rating_dialog.fixDialogButtons();
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
          description      = $rubric_long_description_dialog.find("textarea.description").val(),
          $criterion       = $rubric_long_description_dialog.data('current_criterion');
      if($criterion) {
        $criterion.fillTemplateData({data: {long_description: long_description, description_title: description}});
        $criterion.find("textarea.long_description").val(long_description);
        $criterion.find("textarea.description").val(description);
        $criterion.find(".long_description_holder").toggleClass('empty', !long_description);
        let screenreaderMessage = I18n.t("Criterion Updated")
        if ($criterion.hasClass("new_criterion")) {
          screenreaderMessage = I18n.t("Criterion Created")
        }
        $criterion.removeClass("new_criterion");
        $criterion.show();
        const $rubric = $criterion.parents(".rubric")
        rubricEditing.updateCriteria($rubric);
        rubricEditing.updateRubricPoints($rubric);
        rubricEditing.updateAddCriterionLinks($rubric);
        setTimeout(() => {
          $.screenReaderFlashMessageExclusive(screenreaderMessage);
          $criterion.find(".edit_criterion_link").focus();
        }, 100);
      }
      $rubric_long_description_dialog.dialog('close');
    });
    $rubric_long_description_dialog.find(".cancel_button").click(function() {
      $rubric_long_description_dialog.dialog('close');
    });

    $rubric_rating_dialog.find(".save_button").click(function(event) {
      const $rating = $rubric_rating_dialog.data('current_rating');
      const $criterion = $rubric_rating_dialog.data('current_criterion');
      const $target = $rating.find('.edit_rating_link');
      const use_range = $criterion.find('.criterion_use_range').attr('checked')
      const $nextRating = $rating.next('.rating')
      const $previousRating = $rating.prev('.rating')
      event.preventDefault();
      event.stopPropagation();
      const data = $rubric_rating_dialog.find("#edit_rating_form").getFormData();
      data.points = round(numberHelper.parse(data.points), 2);
      if (isNaN(data.points)) {
        data.points = numberHelper.parse($criterion.find(".criterion_points").val());
        if(isNaN(data.points)) { data.points = 5; }
        if(data.points < 0) { data.points = 0; }
      }
      data.min_points = round(numberHelper.parse(data.min_points), 2);
      if (isNaN(data.min_points) || (data.min_points < 0)) {
        data.min_points = 0;
      }
      if (use_range) {
        // Fix up min and max if the user reversed them.
        if (data.points < data.min_points) {
          const tmp_points = data.points;
          data.points = data.min_points;
          data.min_points = tmp_points;
        }
        if ($previousRating && $previousRating.length !== 0) {
          data.points = rubricEditing.capPointChange(data.points, $previousRating, Math.min, "points");
        }
        if ($nextRating && $nextRating.length !== 0) {
          data.min_points = rubricEditing.capPointChange(data.min_points, $nextRating, Math.max, "min_points");
        }
      }
      $rating.fillTemplateData({data});
      rubricEditing.flagInfinitesimalRating($rating, use_range)
      if($rating.prev(".rating").length === 0) {
        $criterion.find(".criterion_points").val(rubricEditing.localizedPoints(data.points));
      }
      if ($nextRating) {
        $nextRating.fillTemplateData({data: {points: data.min_points} })
        rubricEditing.flagInfinitesimalRating($nextRating, use_range);
      }
      if ($previousRating) {
        $previousRating.fillTemplateData({data: {min_points: data.points} })
        rubricEditing.flagInfinitesimalRating($previousRating, use_range);
      }
      rubricEditing.updateCriterionPoints($criterion, true);
      rubricEditing.originalSizeRatings();
      $rating.removeClass("new_rating");
      $rubric_rating_dialog.dialog('close');
      setTimeout(function() {
        $.screenReaderFlashMessageExclusive(I18n.t("Rating Updated"));
        $target.focus();
      }, 100);

    });
    $rubric_rating_dialog.find(".cancel_button").click(function() {
      $rubric_rating_dialog.dialog('close');
    });

    $(".add_rubric_link").click(function(event) {
      event.preventDefault();
      if($("#rubric_new").length > 0) { return; }
      if(limitToOneRubric && $("#rubrics .rubric:visible").length > 0) { return; }
      var $rubric = rubricEditing.addRubric();
      $("#rubrics").append($rubric.show());
      $(".add_rubric_link").hide();
      rubricEditing.updateAddCriterionLinks($rubric);
      var $target = $rubric.find('.find_rubric_link:visible:first');
      if ($target.length > 0) {
        $target.focus();
      } else {
        $rubric.find(":text:first").focus().select();
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
        rubric.use_for_grading = data.rubric_association.use_for_grading;
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
        if (ENV.MASTER_COURSE_DATA && ENV.MASTER_COURSE_DATA.restricted_by_master_course &&
          ENV.MASTER_COURSE_DATA.is_master_course_child_content && ENV.MASTER_COURSE_DATA.master_course_restrictions.points) {
          skipPointsUpdate = true;
        } else if (data['rubric_association[use_for_grading]'] == '1') {
          const assignmentPoints = numberHelper.parse($("#assignment_show .points_possible, #rubrics.rubric_dialog .assignment_points_possible").text());
          var rubricPoints = parseFloat(data.points_possible);
          if (assignmentPoints != null && assignmentPoints != undefined && rubricPoints != assignmentPoints && !forceSubmit) {
            var pointRatio = assignmentPoints === 0 ? rubricPoints : rubricPoints / assignmentPoints;
            var $confirmDialog = $(changePointsPossibleToMatchRubricDialog({
              assignmentPoints: assignmentPoints,
              rubricPoints: rubricPoints,
              pointRatio: pointRatio
            }));
            var closeDialog = function(skip){
              forceSubmit = true;
              skipPointsUpdate = skip === true;
              $confirmDialog.remove();
              $("#edit_rubric_form").submit();
            };
            $confirmDialog.dialog({
              dialogClass: 'edit-rubric-confirm-points-change',
              buttons: [
                {
                  text: I18n.t('change', 'Change'),
                  click: closeDialog
                },
                {
                  text: I18n.t('leave_different', "Leave different"),
                  click: function() { closeDialog(true); }
                }
              ],
              width: 400,
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
        rubric.use_for_grading = data.rubric_association.use_for_grading;
        rubric.permissions = rubric.permissions || {};
        if(data.rubric_association.permissions) {
          rubric.permissions.update_association = data.rubric_association.permissions.update;
          rubric.permissions.delete_association = data.rubric_association.permissions['delete'];
        }
        rubricEditing.updateRubric($rubric, rubric);
        if (data.rubric_association && data.rubric_association.use_for_grading && !data.rubric_association.skip_updating_points_possible) {
          $("#assignment_show .points_possible").text(rubric.points_possible);
          var discussion_points_text = I18n.t('discussion_points_possible',
                                          {one: '%{count} point possible', other: '%{count} points possible' },
                                          {count: rubric.points_possible || 0})
          $(".discussion-title .discussion-points").text(discussion_points_text);
        }
        if(!limitToOneRubric) {
          $(".add_rubric_link").show();
        }
        $rubric.find(".rubric_title .links:not(.locked)").show();
      }
    });

    $("#edit_rubric_form .cancel_button").click(function() {
      rubricEditing.hideEditRubric($(this).parents(".rubric"), true);
    });

    $("#rubrics").delegate('.add_criterion_link', 'click', function(event) {
      var $criterion = rubricEditing.addCriterion($(this).parents(".rubric")); //"#default_rubric"));
      $criterion.hide();
      rubricEditing.editCriterion($criterion);
      return false;
    }).delegate('.description_title', 'click', function() {
      var $criterion = $(this).parents(".criterion")
      rubricEditing.editCriterion($criterion);
      return false;
    }).delegate('.delete_criterion_link', 'click', function(event) {
      var $criterion = $(this).parents('.criterion');

      // this is annoying, but the current code doesn't care where in the list
      // of rows the "blank" template element is, so we have to account for the
      // fact that it could be the previous row
      var $prevCriterion = $criterion.prevAll('.criterion:not(.blank)').first();
      let $target = $prevCriterion.find('.edit_criterion_link');
      if ($prevCriterion.length == 0) {
        $target = $criterion.parents('.rubric_container').find('.rubric_title input');
      }
      const $rubric = $criterion.parents(".rubric");
      if ($criterion.hasClass("new_criterion")) {
        $criterion.remove();
        rubricEditing.updateAddCriterionLinks($rubric, '.icon-plus');
      } else {
        // focusing before the fadeOut so safari
        // screenreader can handle focus properly
        $target.focus();

        $criterion.fadeOut(function() {
          $criterion.remove();
          rubricEditing.updateCriteria($rubric);
          rubricEditing.updateRubricPoints($rubric);
          rubricEditing.updateAddCriterionLinks($rubric);
        });
      }
      return false;
    }).delegate('.rating_description_value', 'click', function(event) {
      return false;
    }).bind('mouseover', function(event) {
      var $target = $(event.target);
      if(!$target.closest('.ratings').length) {
        rubricEditing.hideCriterionAdd($target.parents('.rubric'));
      }
    }).delegate('.delete_rating_link', 'click', function(event) {
      const $rating_cell = $(this).closest('td')
      const $target = $rating_cell.prev().find('.add_rating_link_after');
      const $previousRating = $rating_cell.prev('.rating')
      const previous_data = {min_points: $rating_cell.next('.rating').find('.points').text()}
      $previousRating.fillTemplateData({data: previous_data})
      event.preventDefault();
      rubricEditing.hideCriterionAdd($(this).parents(".rubric"));
      $(this).parents(".rating").fadeOut(function() {
        const $criterion = $(this).parents(".criterion");
        rubricEditing.flagInfinitesimalRating($previousRating, $criterion.find('.criterion_use_range').attr('checked'))
        $(this).remove();
        rubricEditing.sizeRatings($criterion);
        $target.focus();
      });
    }).delegate('.add_rating_link_after', 'click', function(event) {
      event.preventDefault();
      var $this = $(this).parents('td.rating');
      $this.addClass('add_right');
      rubricEditing.addNewRatingColumn($this);
    }).delegate('.add_column', 'click', function(event) {
      var $this = $(this);
      rubricEditing.addNewRatingColumn($this);
    });
    $(".criterion_points").keydown(function(event) {
      if(event.keyCode == 13) {
        rubricEditing.updateCriterionPoints($(this).parents(".criterion"));
      }
    }).blur(function(event) {
      rubricEditing.updateCriterionPoints($(this).parents(".criterion"));
    });
    $("#edit_rating").delegate(".cancel_button", 'click', function(event) {
      var $target = $(this).closest('td.rating').find('.edit_rating_link');
    });
    $("#edit_rubric_form .rubric_custom_rating").change(function() {
      $(this).parents(".rubric").find("tr.criterion")
        .find(".ratings").showIf(!$(this).attr('checked')).end()
        .find('.criterion_use_range_div')
          .showIf(!$(this).attr('checked')).end()
        .find(".custom_ratings")
          .showIf($(this).attr('checked'));
    }).triggerHandler('change');
    $("#edit_rubric_form #totalling_rubric").change(function() {
      $(this).parents(".rubric").find(".total_points_holder").showIf(!$(this).attr('checked'));
    });
    $("#edit_rubric_form .grading_rubric_checkbox").change(function() {
      $(this).parents(".rubric").find(".totalling_rubric").css('visibility', $(this).attr('checked') ? 'hidden' : 'visible');
      $(this).parents(".rubric").find(".totalling_rubric_checkbox").attr('checked', false);
    }).triggerHandler('change');
    $('.criterion_use_range').change(function () {
      const checked = $(this).attr('checked')
      $(this).parents('tr.criterion').find('.rating').each(function() {
        const use_range = checked  && !$(this).hasClass("infinitesimal")
        $(this).find('.range_rating').showIf(use_range);
      });
    }).triggerHandler('change');
    $("#criterion_blank").find(".criterion_points").val("5");
    if($("#default_rubric").find(".criterion").length <= 1) {
      rubricEditing.addCriterion($("#default_rubric"));
      $("#default_rubric").find(".criterion").removeClass("new_criterion");
    }
    setInterval(rubricEditing.sizeRatings, 10000);
    $.publish('edit_rubric/initted')
  };

export default rubricEditing;
