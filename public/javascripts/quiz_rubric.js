define([
  'i18n!quizzes.rubric',
  'jquery' /* $ */,
  'jqueryui/dialog'
], function(I18n, $) {

$(document).ready(function() {
  $(".show_rubric_link").click(function(event) {
    event.preventDefault();
    var url = $(this).attr('rel');
    var $dialog = $("#rubrics.rubric_dialog");
    if($dialog.length) {
      ready();
    } else {
      var $loading = $("<div/>");
      $loading.text(I18n.t('loading', "Loading..."));
      $("body").append($loading);
      $loading.dialog({
        width: 400,
        height: 200
      });
      $.get(url, function(html) {
        $("body").append(html);
        $loading.dialog('close');
        $loading.remove();
        ready();
      });
    }
    function ready() {
      $dialog = $("#rubrics.rubric_dialog");
      $dialog.dialog({
        title: I18n.t('titles.details', "Assignment Rubric Details"),
        width: 600,
        resizable: true
      });
    }
  });
});

});
