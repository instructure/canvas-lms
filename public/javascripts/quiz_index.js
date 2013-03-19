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
  'i18n!quizzes.index',
  'jquery' /* $ */,
  'compiled/util/vddTooltip',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins' /* confirmDelete */,
  'jquery.templateData' /* getTemplateData */
], function(I18n, $, vddTooltip) {

$(document).ready(function() {
  $(".delete_quiz_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".quiz").confirmDelete({
      url: $(this).attr('href'),
      message: I18n.t('confirms.delete_quiz', "Are you sure you want to delete this quiz?"),
      error: function(data) {
        $(this).formErrors(data);
      }
    });
  });
  $(".publish_multiple_quizzes_link").click(function(event) {
    event.preventDefault();
    var $dialog = $("#publish_multiple_quizzes_dialog");
    var $template = $dialog.find(".quiz_item.blank:first").clone(true);
    var $list = $dialog.find(".quiz_list").find(".quiz_item:not(.blank)").remove().end();
    $("#unpublished_quizzes .quiz").each(function() {
      var $quiz_item = $template.clone(true);
      var data = $(this).getTemplateData({textValues: ['quiz_id', 'quiz_title']});
      $quiz_item.removeClass('blank');
      $quiz_item.find(".id").val(data.quiz_id).attr('id', 'quiz_checkbox_' + data.quiz_id).end()
        .find(".title").text(data.quiz_title || I18n.t('default_title', 'Unnamed Quiz')).attr('for', 'quiz_checkbox_' + data.quiz_id);
      $list.append($quiz_item.show());
    });
    $dialog.find("button").attr('disabled', false);
    $dialog.dialog({
      width: 400
    });
  });
  $("#publish_quizzes_form").submit(function() {
    $(this).find("button").attr('disabled', true).filter('.submit_button').text(I18n.t('buttons.publishing_quizzes', 'Publishing Quizzes...'));
  });
  $("#publish_multiple_quizzes_dialog .cancel_button").click(function() {
    $("#publish_multiple_quizzes_dialog").dialog('close');
  });
  if($("#quiz_locks_url").length > 0) {
    var data = {};
    var assets = [];
    $("li.quiz").each(function() {
      assets.push("quiz_" + $(this).attr('id').substring(13));
    });
    data.assets = assets.join(",");
    $.ajaxJSON($("#quiz_locks_url").attr('href'), 'GET', data, function(data) {
      for(var idx in data) {
        var code = idx;
        var locked = !!data[idx];
        if(locked) {
          var $icon = $("#quiz_lock_icon").clone().removeAttr('id').toggle();
          data[idx].type = "quiz";
          $icon.data('lock_reason', data[idx]);
          $("#summary_" + code).find(".quiz_title").prepend($icon);
        }
      }
    }, function() {});
  }
  vddTooltip();
});

});
