require([
  'i18n!quizzes.statistics' /* I18n.t */,
  'jquery' /* $ */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* scrollSidebar */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */
], function(I18n, $) {

  $.scrollSidebar();
  $(".essay_answer").live('click', function(event) {
    event.preventDefault();
    $(this).addClass('expanded');
  });
  $('.download_submissions_link').click(function(event){
    event.preventDefault();
    INST.downloadSubmissions($(this).attr('href'));
  });
  $(".answer,.number_answer").live('click', function(event) {
    var data = $(this).getTemplateData({textValues: ['user_ids'], dataValues: ['responses']});
    var ids = data.user_ids;
    var responses = parseInt(data.responses, 10) || 0;
    if(ids != null && responses > 0) {
      var $dialog = $("#submitted_users_dialog");
      $dialog.find(".user:not(.blank)").remove();
      var names = [];
      var answer_text = $(this).find(".answer_text").text();
      var $tr = $(this).parents("tr");
      while($tr.length && $tr.find("td .question_name").length == 0) {
        $tr = $tr.prev();
      }
      var question_name = $tr.find("td .question_name").text();
      ids = ids.split(",");
      var uncounted = responses - ids.length;
      var unique_ids = $.unique(ids);
      for(var idx in unique_ids) {
        var id = unique_ids[idx];
        var cnt = $.grep(ids, function(i) { return i == id; }).length;
        var name = $("#submitted_users .user.user_" + id).text();
        if(cnt > 1) {
          name = name + " (" + I18n.t('count_attempts', "attempt", {count: cnt}) + ")";
        }
        if(name) {
          var $name = $dialog.find(".user.blank:first").clone(true).removeClass('blank');
          $name.fillTemplateData({data: {name: name}});
          $dialog.find(".users").append($name.show());
        } else {
          uncounted++;
        }
      }
      if(uncounted > 0) {
        var $name = $dialog.find(".user.blank:first").clone(true).removeClass('blank');
        $name.fillTemplateData({data: {name: I18n.t('uncounted_submissions', {one: '1 other submission', other: '%{count} other submissions'}, {count: uncounted})}});
        $name.addClass('uncounted');
        $dialog.find(".users").append($name.show());
      }
      $dialog.fillTemplateData({data: {
        answer_text: answer_text,
        question_name: question_name
      }});
      $dialog.dialog({
        title: I18n.t('titles.submitted_users_for_quesiton', "Submitted Users for %{user}", {user: question_name}),
        width: 500,
        height: 300
      });
    }
  });
});

