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
      var $this = $(this);
      $(".ip_filter .value").each(function() {
        $(this).removeAttr('name');
      }).filter(":not(.blank)").each(function() {
        var name = $.trim($(this).parents(".ip_filter").find(".name").val().replace(/\[|\]/g, '_'));
        if(name) {
          $(this).attr('name', 'account[ip_filters][' + name + ']');
        }
      });
      var validations = {
        object_name: 'account',
        required: ['name'],
        property_validations: {
          'name': function(value){
            if (value && value.length > 255) { return I18n.t("account_name_too_long", "Account Name is too long")}
          }
        }
      };
      var result = $this.validateForm(validations);
      if(!result) {
        return false;
      }
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
      var $this = $(this);
      var $confirmation = $this.find('#confirm_global_announcement:visible:not(:checked)');
      if ($confirmation.length > 0) {
        $confirmation.errorBox(I18n.t('confirms.global_announcement', "You must confirm the global announcement"));
        return false;
      }
      var validations = {
        object_name: 'account_notification',
        required: ['start_at', 'end_at', 'subject', 'message'],
        date_fields: ['start_at', 'end_at'],
        numbers: []
      };
      if ($('#account_notification_months_in_display_cycle').length > 0) {
        validations.numbers.push('months_in_display_cycle');
      }
      var result = $this.validateForm(validations);
      if(!result) {
        return false;
      }
    });
    $("#account_notification_required_account_service").click(function(event) {
      $this = $(this);
      $("#confirm_global_announcement_field").showIf(!$this.is(":checked"));
      $("#account_notification_months_in_display_cycle").prop("disabled", !$this.is(":checked"));
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
      $("#ip_filters_dialog").dialog({
        title: I18n.t('titles.what_are_quiz_ip_filters', "What are Quiz IP Filters?"),
        width: 400
      });
    });

    $(".open_registration_delegated_warning_link").click(function(event) {
      event.preventDefault();
      $("#open_registration_delegated_warning_dialog").dialog({
        title: I18n.t('titles.open_registration_delegated_warning_dialog', "An External Identity Provider is Enabled"),
        width: 400
      });
    });

    $('#account_settings_external_notification_warning_checkbox').on('change', function(e) {
      $('#account_settings_external_notification_warning').val($(this).prop('checked') ? 1 : 0);
    });

    $(".custom_help_link .delete").click(function(event) {
      event.preventDefault();
      $(this).parents(".custom_help_link").find(".custom_help_link_state").val('deleted');
      $(this).parents(".custom_help_link").hide();
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
      var turnitin_data = {
        turnitin_account_id: account.turnitin_account_id,
        turnitin_shared_secret: account.turnitin_shared_secret,
        turnitin_host: account.turnitin_host
      }
      $link.text(I18n.t('notices.turnitin.checking_settings', "checking Turnitin settings..."));
      $.getJSON(url, turnitin_data, function(data) {
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
      $(this).parent(".reports").find(".report_description").dialog({
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
        var report = $(this).attr('id').replace('_form', '');
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

      $('<a href="#"><i class="icon-question standalone-icon"></i></a>')
        .click(function(event){
          event.preventDefault();
          $dialog.dialog('open');
        })
        .appendTo('label[for="account_services_' + serviceName + '"]');
    });

    function displayCustomEmailFromName(){
      var displayText = $('#account_settings_outgoing_email_default_name').val();
      if (displayText == '') {
        displayText = I18n.t('custom_text_blank', '[Custom Text]');
      }
      $('#custom_default_name_display').text(displayText);
    }
    $('.notification_from_name_option').on('change', function(){
      var $useCustom = $('#account_settings_outgoing_email_default_name_option_custom');
      var $customName = $('#account_settings_outgoing_email_default_name');
      if ($useCustom.attr('checked')) {
        $customName.removeAttr('disabled');
        $customName.focus()
      }
      else {
        $customName.attr('disabled', 'disabled');
      }
    });
    $('#account_settings_outgoing_email_default_name').on('keyup', function(){
      displayCustomEmailFromName();
    });
    // Setup initial display state
    displayCustomEmailFromName();
    $('.notification_from_name_option').trigger('change');

    $('#account_settings_self_registration').change(function() {
      $('#self_registration_type_radios').toggle(this.checked);
    }).trigger('change');

  });

});
