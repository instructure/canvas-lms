$(document).ready(function() {
  $("#account_settings").submit(function() {
    $(".ip_filter .value").each(function() {
      $(this).removeAttr('name');
    }).filter(":not(.blank)").each(function() {
      var name = $.trim($(this).parents(".ip_filter").find(".name").val().replace(/\[|\]/g, '_'));
      if(name) {
        $(this).attr('name', 'account[ip_filters][' + name + ']');
      }
    });
  });
  $(".datetime_field").datetime_field();
  $(".add_notification_link").click(function(event) {
    event.preventDefault();
    $("#add_notification_form").slideToggle(function() {
      $("#add_notification_form textarea:not(.enabled)").addClass('enabled').editorBox();
    });
  });
  $("#add_notification_form .datetime_field").bind('blur change', function() {
    var date = Date.parse($(this).val());
    if(date) {
      date = date.toString($.datetime.defaultFormat);
    }
    $(this).val(date);
  });
  $("#add_notification_form").submit(function(event) {
    var result = $(this).validateForm({
      object_name: 'account_notification',
      required: ['start_at', 'end_at', 'subject', 'message'],
      date_fields: ['start_at', 'end_at']
    });
    if(!result) {
      return false;
    }
  });
  $(".delete_notification_link").click(function(event) {
    event.preventDefault();
    var $link = $(this);
    $link.parents("li").confirmDelete({
      url: $link.attr('rel'),
      message: "Are you sure you want to delete this alert?",
      success: function() {
        $(this).slideUp(function() {
          $(this).remove();
        });
      }
    });
  });
  $("#account_settings_tabs").tabs().show();
  $(".add_ip_filter_link").click(function(event) {
    event.preventDefault();
    var $filter = $(".ip_filter.blank:first").clone(true).removeClass('blank');
    $("#ip_filters").append($filter.show());
  });
  $(".delete_filter_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".ip_filter").remove();
  });
  if($(".ip_filter:not(.blank)").length == 0) {
    $(".add_ip_filter_link").click();
  }
  $(".ip_help_link").click(function(event) {
    event.preventDefault();
    $("#ip_filters_dialog").dialog('close').dialog({
      autoOpen: false,
      title: "What are Quiz IP Filters?",
      width: 400
    }).dialog('open');
  });
  $(".remove_account_user_link").click(function(event) {
    event.preventDefault();
    var $item = $(this).parent("li");
    $item.confirmDelete({
      message: "Are you sure you want to remove this account admin?",
      url: $(this).attr('href'),
      success: function() {
        $item.slideUp(function() {
          $(this).remove();
        });
      }
    });
  });
  $("#turnitin").change(function() {
    $("tr.turnitin_settings").showIf($(this).attr('checked'));
  }).change();
  $(".turnitin_account_settings").change(function() {
    $(".confirm_turnitin_settings_link").text("confirm Turnitin settings");
  });
  $(".confirm_turnitin_settings_link").click(function(event) {
    event.preventDefault();
    var $link = $(this);
    var url = $link.attr('href');
    var account = $("#account_settings").getFormData({object_name: 'account'});
    url = $.replaceTags($.replaceTags(url, 'account_id', account.turnitin_account_id), 'shared_secret', account.turnitin_shared_secret);
    $link.text("checking Turnitin settings...");
    $.ajaxJSON(url, 'GET', {}, function(data) {
      if(data && data.success) {
        $link.text("Turnitin settings confirmed!");
      } else {
        $link.text("invalid Turnitin settings, please check your account id and shared secret from Turnitin")
      }
    }, function(data) {
      $link.text("invalid Turnitin settings, please check your account id and shared secret from Turnitin")
    });
  });
  $("#enable_equella").change(function() {
    $("tr.equella_row").showIf($(this).attr('checked'));
    if(!$(this).attr('checked')) {
      $("tr.equella_row").find("input,textarea").each(function() { $(this).val(""); });
    }
  }).change();

  $(".run_report_link").click(function(event) {
      event.preventDefault();
      $(this).parent("form").submit();
  });

  $(".run_report_form").formSubmit({
      resetForm: true,
      beforeSubmit: function(data) {
          $(this).find('.run_report_link').hide();
          $(this).find('.running_report_message').show();
          return true;
      },
      success: function(data) {
      },
      error: function(data) {
      }
  });

});
