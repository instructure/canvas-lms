$(document).ready(function() {
  $(".show_rubric_link").click(function(event) {
    event.preventDefault();
    var url = $(this).attr('rel');
    var $dialog = $("#rubrics.rubric_dialog");
    if($dialog.length) {
      ready();
    } else {
      var $loading = $("<div/>");
      $loading.html("Loading...");
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
        title: "Assignment Rubric Details",
        width: 600,
        modal: false,
        resizable: true,
        autoOpen: false
      }).dialog('open');
    }
  });
});