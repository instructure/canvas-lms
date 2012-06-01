define([
  'i18n!account_settings',
  'jquery', // $
  'jquery.ajaxJSON', // ajaxJSON
  'jquery.instructure_date_and_time', // date_field, time_field, datetime_field, /\$\.datetime/
  'jquery.instructure_forms', // formSubmit, getFormData, validateForm
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers', // replaceTags
  'jquery.instructure_misc_plugins', // confirmDelete, showIf, /\.log/
  'jquery.loadingImg', // loadingImg, loadingImage
  'compiled/tinymce',
  'tinymce.editor_box', // editorBox
  'vendor/date', // Date.parse
  'vendor/jquery.scrollTo', // /\.scrollTo/
  'jqueryui/tabs' // /\.tabs/
], function(I18n, $) {

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
    $("#add_notification_form textarea").editorBox().width('100%');
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
        message: I18n.t('confirms.delete_announcement', "Are you sure you want to delete this announcement?"),
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
        title: I18n.t('titles.what_are_quiz_ip_filters', "What are Quiz IP Filters?"),
        width: 400
      }).dialog('open');
    });
    $(".open_registration_delegated_warning_link").click(function(event) {
      event.preventDefault();
      $("#open_registration_delegated_warning_dialog").dialog('close').dialog({
        autoOpen: false,
        title: I18n.t('titles.open_registration_delegated_warning_dialog', "An External Identity Provider is Enabled"),
        width: 400
      }).dialog('open');
    });


    var $blankCustomHelpLink = $('.custom_help_link.blank').detach().removeClass('blank'),
        uniqueCounter = 1000;
    $(".add_custom_help_link").click(function(event) {
      event.preventDefault();
      var $newContainer = $blankCustomHelpLink.clone(true).appendTo('#custom_help_links').show(),
          newId = uniqueCounter++;
      // need to replace the unique id in the inputs so they get sent back to rails right,
      // chage the 'for' on the lables to match.
      $.each(['id', 'name', 'for'], function(i, prop){
        $newContainer.find('['+prop+']').attr(prop, function(i, previous){
          return previous.replace(/\d+/, newId);
        });
      });
    });
    $(".custom_help_link .delete").click(function(event) {
      event.preventDefault();
      $(this).parents(".custom_help_link").remove();
    });

    $(".remove_account_user_link").click(function(event) {
      event.preventDefault();
      var $item = $(this).parent("li");
      $item.confirmDelete({
        message: I18n.t('confirms.remove_account_admin', "Are you sure you want to remove this account admin?"),
        url: $(this).attr('href'),
        success: function() {
          $item.slideUp(function() {
            $(this).remove();
          });
        }
      });
    });

    $("#turnitin, #account_settings_global_includes, #enable_equella").change(function() {
      var $myFieldset = $('#'+ $(this).attr('id') + '_settings'),
          iAmChecked = $(this).attr('checked');
      $myFieldset.showIf(iAmChecked);
      if (!iAmChecked) {
        $myFieldset.find("input,textarea").val("");
      }
    }).change();

    $(".turnitin_account_settings").change(function() {
      $(".confirm_turnitin_settings_link").text(I18n.t('links.turnitin.confirm_settings', "confirm Turnitin settings"));
    });
    $(".confirm_turnitin_settings_link").click(function(event) {
      event.preventDefault();
      var $link = $(this);
      var url = $link.attr('href');
      var account = $("#account_settings").getFormData({object_name: 'account'});
      url = $.replaceTags($.replaceTags(url, 'account_id', account.turnitin_account_id), 'shared_secret', account.turnitin_shared_secret);
      $link.text(I18n.t('notices.turnitin.checking_settings', "checking Turnitin settings..."));
      $.ajaxJSON(url, 'GET', {}, function(data) {
        if(data && data.success) {
          $link.text(I18n.t('notices.turnitin.setings_confirmed', "Turnitin settings confirmed!"));
        } else {
          $link.text(I18n.t('notices.turnitin.invalid_settings', "invalid Turnitin settings, please check your account id and shared secret from Turnitin"))
        }
      }, function(data) {
        $link.text(I18n.t('notices.turnitin.invalid_settings', "invalid Turnitin settings, please check your account id and shared secret from Turnitin"))
      });
    });

    // Admins tab
    $(".add_users_link").click(function(event) {
        var $enroll_users_form = $("#enroll_users_form");
        $(this).hide();
        event.preventDefault();
        $enroll_users_form.show();
        $("html,body").scrollTo($enroll_users_form);
        $enroll_users_form.find("textarea").focus().select();
      });

    $(".open_report_description_link").click(function(event) {
      event.preventDefault();
      var title = $(this).parents(".title").find("span.title").text();
      $(this).parent(".reports").find(".report_description").dialog('close').dialog({
        title: title,
        width: 800
      });
    });

    $(".run_report_link").click(function(event) {
      event.preventDefault();
      $(this).parent("form").submit();
    });

    $(".run_report_form").formSubmit({
      resetForm: true,
      beforeSubmit: function(data) {
        $(this).loadingImage();
        return true;
      },
      success: function(data) {
        $(this).loadingImage('remove');
        var report = $(this).find('input[name="report_type"]').val();
        $("#" + report).find('.run_report_link').hide()
          .end().find('.configure_report_link').hide()
          .end().find('.running_report_message').show();
        $(this).parent(".report_dialog").dialog('close');
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).parent(".report_dialog").dialog('close');
      }
    });

    $(".configure_report_link").click(function(event) {
      event.preventDefault();
      var data = $(this).data(),
        $dialog = data.$report_dialog;
      if (!$dialog) {
        $dialog = data.$report_dialog = $(this).parent("td").find(".report_dialog").dialog({
          autoOpen: false,
          width: 400,
          title: I18n.t('titles.configure_report', 'Configure Report')
        });
      }
      $dialog.dialog('open');
    })

    $('.service_help_dialog').each(function(index) {
      var $dialog = $(this),
          serviceName = $dialog.attr('id').replace('_help_dialog', '');

      $dialog.dialog({
        autoOpen: false,
        width: 560
      });

      $('<a class="help" href="#">&nbsp;</a>')
        .click(function(event){
          event.preventDefault();
          $dialog.dialog('open');
        })
        .appendTo('label[for="account_services_' + serviceName + '"]');
    });
  });

});


