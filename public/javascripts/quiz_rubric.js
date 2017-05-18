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

define([
  'i18n!quizzes.rubric',
  'jquery' /* $ */,
  'jqueryui/dialog',
  'rubricEditBinding' // event handler for rubricEditDataReady
], function(I18n, $) {

  var quizRubric = {
    ready: function() {
      var $dialog = $("#rubrics.rubric_dialog");
      $dialog.dialog({
        title: I18n.t('titles.details', "Assignment Rubric Details"),
        width: 600,
        resizable: true
      });
    },

    buildLoadingDialog: function(){
      var $loading = $("<div/>");
      $loading.text(I18n.t('loading', "Loading..."));
      $("body").append($loading);
      $loading.dialog({
        width: 400,
        height: 200
      });
      return $loading;
    },

    replaceLoadingDialog: function(html, $loading){
      $("body").append(html);
      $loading.dialog('close');
      $loading.remove();
      quizRubric.ready();
    },

    createRubricDialog: function(url, preloadedHtml) {
      var $dialog = $("#rubrics.rubric_dialog");
      if($dialog.length) {
        quizRubric.ready();
      } else {
        var $loading = quizRubric.buildLoadingDialog();
        if(preloadedHtml === undefined || preloadedHtml === null){
          $.get(url, function(html) {
            quizRubric.replaceLoadingDialog(html, $loading);
          });
        } else {
          quizRubric.replaceLoadingDialog(preloadedHtml, $loading);
        }
      }
    }
  };

  $(document).ready(function() {
    $(".show_rubric_link").click(function(event) {
      event.preventDefault();
      var url = $(this).attr('rel');
      quizRubric.createRubricDialog(url);
    });
  });

  return quizRubric;

});
