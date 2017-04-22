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
