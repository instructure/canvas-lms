require([
  'i18n!quizzes.rubric',
  'jquery' /* $ */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */
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
      $dialog.dialog('close').dialog({
        title: I18n.t('titles.details', "Assignment Rubric Details"),
        width: 600,
        modal: false,
        resizable: true,
        autoOpen: false
      }).dialog('open');
    }
  });
});

});
