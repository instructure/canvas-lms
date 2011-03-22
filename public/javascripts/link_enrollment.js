var link_enrollment = (function() {
  return {
    choose: function(user_name, enrollment_id, current_user_id, callback) {
      var $user = $(this).parents(".user");
      var $dialog = $("#link_student_dialog");
      var user_data = {};
      user_data.short_name = user_name;
      $dialog.fillTemplateData({data: user_data});
      if(!$dialog.data('loaded')) {
        $dialog.find(".loading_message").text("Loading Students...");
        var url = $dialog.find(".student_url").attr('href');
        $.ajaxJSON(url, 'GET', {}, function(data) {
          for(var idx in data) {
            var user = data[idx];
            var $option = $("<option/>");
            if(user.id && user.name) {
              $option.val(user.id).text(user.name);
              $dialog.find(".student_options").append($option);
            }
          }
          var $option = $("<option/>");
          $option.val("none").text("[ No Link ]");
          $dialog.data('loaded', true);
          $dialog.find(".student_options").append($option);
          
          $dialog.find(".enrollment_id").val(enrollment_id);
          $dialog.find(".student_options").val("none").val(current_user_id);
          $dialog.find(".loading_message").hide().end()
            .find(".students_link").show();
          $dialog.find(".existing_user").showIf(current_user_id);
          $dialog.data('callback', callback);
          user_data.existing_user_name = $dialog.find(".student_options option[value='" + current_user_id + "']").text();
          $dialog.fillTemplateData({data: user_data});
        }, function() {
          $dialog.find(".loading_message").text("Loading Students Failed, please try again");
          $dialog.data('callback', callback);
        });
      } else {
        $dialog.find(".enrollment_id").val(enrollment_id);
        $dialog.find(".existing_user").showIf(current_user_id);
        $dialog.find(".student_options").val("none").val(current_user_id);
        user_data.existing_user_name = $dialog.find(".student_options option[value='" + current_user_id + "']").text();
        $dialog.fillTemplateData({data: user_data});
      }
      $dialog.find(".existing_user").showIf(current_user_id);
      $dialog.find(".student_options option:not(.blank)").remove();
      
      $dialog
        .dialog('close').dialog({
          autoOpen: false,
          title: "Link to Student",
          width: 400
        }).dialog('open');
    }
  };
})();
$(document).ready(function() {
  $(document).bind('enrollment_added', function() {
    $("#link_student_dialog").data('loaded', false);
  });
  $("#link_student_dialog .cancel_button").click(function() {
    $("#link_student_dialog").dialog('close');
  });
  $("#link_student_dialog_form").formSubmit({
    beforeSubmit: function(data) {
      $(this)
        .find("button").attr('disabled', true).end()
        .find(".save_button").text("Linking to Student...");
    },
    success: function(data) {
      $(this)
        .find("button").attr('disabled', false).end()
        .find(".save_button").text("Link to Student");
      var enrollment = data.enrollment;
      var callback = $("#link_student_dialog").data('callback');
      $("#link_student_dialog").dialog('close');
      if($.isFunction(callback) && enrollment) {
        callback(enrollment);
      }
    },
    error: function(data) {
      $(this)
        .find("button").attr('disabled', false)
        .find(".save_button").text("Linking Failed, please try again");
    }
  });
});