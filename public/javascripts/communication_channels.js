require([
  'i18n!profile' /* I18n.t */,
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'jqueryui/tabs' /* /\.tabs/ */
], function(I18n, $) {

$(document).ready(function() {
  $("#communication_channels").tabs();
  $("#communication_channels").bind('tabsshow', function(event) {
    if($(this).css('display') != 'none') {
      var idx = $(this).data('selected.tabs');
      if(idx == 0) {
        $("#register_email_address").find(":text:first").focus().select();
      } else {
        $("#register_sms_number").find(":text:first").focus().select();
      }
    }
  });
  $(".channel_list tr").hover(function() {
    if($(this).hasClass('unconfirmed')) {
      var title =  I18n.t('titles.contact_not_confirmed', 'This contact has not been confirmed.  Click the address for more details') ;
      if($(this).closest(".email_channels").length > 0) {
        title =  I18n.t('titles.email_not_confirmed', 'This email has not been confirmed.  Click the address for more details') ;
      }
      $(this).attr('title', title);
      $(this).find("a.path").parent().attr('title', title);
    }
  }, function() {
    $(this).attr('title', '');
    $(this).find("a.path").parent().attr('title', $(this).find("a.path").text());
  });
  $(".add_email_link,.add_contact_link").click(function(event) {
    event.preventDefault();
    var view = "email";
    $("#communication_channels").show().dialog({
      title:  I18n.t('titles.register_communication', "Register Communication") ,
      width: 600,
      resizable: false,
      modal: true,
      open: function() {
        $("#communication_channels").triggerHandler('tabsshow');
      }
    });
    if($(this).hasClass('add_contact_link')) {
      $("#communication_channels").tabs('select', '#register_sms_number');
      view = "sms";
    } else {
      $("#communication_channels").tabs('select', '#register_email_address');
    }
  });
  $("#register_sms_number .user_selected").bind('change blur keyup focus', function() {
    var $form = $(this).parents("#register_sms_number");
    var sms_number = $form.find(".sms_number").val().replace(/[^\d]/g, "");
    $form.find(".should_be_10_digits").showIf(sms_number && sms_number.length != 10);
    var email = $form.find(".carrier").val();
    $form.find(".sms_email").attr('disabled', email != 'other');
    if(email == "other") { return; }
    email = email.replace("#", sms_number);
    $form.find(".sms_email").val(email);
  });

  $("#register_sms_number,#register_email_address").formSubmit({
    object_name: 'communication_channel',
    required: ['address'],
    property_validations: {
      address: function (value) {
        var match = value.match(/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/);
        return !match && !(match && match.length !== value.length) && !(value.length === 0) && I18n.t("Email is invalid!");
      }
    },
    beforeSubmit: function(data) {
      var $list = $(".email_channels");
      if($(this).attr('id') == "register_sms_number") {
        $list = $(".other_channels");
      }
      var path = $(this).getFormData({object_name: 'communication_channel'}).address;
      $(this).data('email', path);
      $list.find(".channel .path").each(function() {
        if($(this).text() == path) { path = ""; }
      });
      $list.removeClass('single');
      var $channel = null;
      if(path) {
        $channel = $list.find(".channel.blank").clone(true).removeClass('blank');
        $channel.find(".path").attr('title',  I18n.t('titles.unconfirmed_click_to_confirm', "Unconfirmed.  Click to confirm") );
        $channel.fillTemplateData({
          data: {path: path}
        });
        $list.find(".channel.blank").before($channel.show());
      }
      if(!path) { return false; }
      $("#communication_channels").dialog('close');
      $channel.loadingImage({image_size: 'small'});
      return $channel;
    }, success: function(channel, $channel) {
      $("#communication_channels").dialog('close');
      $channel.loadingImage('remove');

      channel.channel_id = channel.id;
      var select_type = "email_select";
      if($(this).attr('id') == 'register_sms_number') {
        select_type = "sms_select";
      }
      var $select = $("#select_templates ." + select_type);
      var $option = $(document.createElement('option'));
      $option.val(channel.id).text(channel.address);
      $select.find("option:last").before($option);
      $select.find("option.blank_option").remove();
      $("." + select_type).each(function() {
        var val = $(this).val();
        if(val == "new") {
          val = channel.id;
        }
        $(this).after($select.clone(true).val(val)).remove();
      });
      $channel.fillTemplateData({
        data: channel,
        id: 'channel_' + channel.id,
        hrefValues: ['user_id', 'pseudonym_id', 'channel_id']
      });
      $channel.find(".path").triggerHandler('click');
    },
    error: function(data, $channel) {
      $channel.loadingImage('remove');
      $channel.remove();
    }
  });
  $("a.email_address_taken_learn_more").live('click', function(event) {
    event.preventDefault();

  });
  $(".channel_list .channel .delete_channel_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".channel").confirmDelete({
      url: $(this).attr('href'),
      success: function(data) {
        var $list = $(this).parents(".channel_list");
        $(this).remove();
        $list.toggleClass('single', $list.find(".channel:visible").length <= 1);
      }
    });
  });
  $("#confirm_communication_channel .cancel_button").click(function(event) {
    $("#confirm_communication_channel").dialog('close');
  });
  $(".email_channels .channel .path,.other_channels .channel .path").click(function(event) {
    event.preventDefault();
    var $channel = $(this).parents(".channel");
    if($channel.hasClass('unconfirmed')) {
      var type = "email address", confirm_title =  I18n.t('titles.confirm_email_address', "Confirm Email Address") ;
      if($(this).parents(".channel_list").hasClass('other_channels')) {
        type = "sms number", confirm_title =  I18n.t('titles.confirm_sms_number', "Confirm SMS Number") ;
      }
      var $box = $("#confirm_communication_channel");
      if($channel.parents(".email_channels").length > 0) {
        $box = $("#confirm_email_channel");
      }
      var data = $channel.getTemplateData({textValues: ['user_id', 'pseudonym_id', 'channel_id']});
      var path = $(this).text();
      if(type == "sms number") {
        path = path.split("@")[0];
      }
      data.code = "";
      $box.fillTemplateData({data: {
        path: path,
        path_type: type,
        user_id: data.user_id,
        channel_id: data.channel_id
      }});
      $box.find(".status_message").css('visibility', 'hidden');
      var url = $(".re_send_confirmation_url").attr('href');
      url = $.replaceTags(url, "id", data.channel_id);
      url = $.replaceTags(url, "pseudonym_id", data.pseudonym_id);
      url = $.replaceTags(url, "user_id", data.user_id);
      $box.find(".re_send_confirmation_link").attr('href', url)
        .text( I18n.t('links.resend_confirmation', "Re-Send Confirmation") );
      $box.fillFormData(data);
      $box.show().dialog({
        title: confirm_title,
        width: 350,
        open: function() {
          $(this).closest('.ui-dialog').focus()
        }
      });
    }
  });
  $("#confirm_communication_channel").formSubmit({
    formErrors: false,
    processData: function(data) {
      var url = $(this).find(".register_channel_link").attr('href');
      url = $.replaceTags(url, "id", data.channel_id);
      url = $.replaceTags(url, "code", data.code);
      $(this).attr('action', url);
    },
    beforeSubmit: function(data) {
      $(this).find(".status_message").text( I18n.t('confirming_contact', "Confirming...") ).css('visibility', 'visible');
    },
    success: function(data) {
      $(this).find(".status_message").css('visibility', 'hidden');
      var pseudonym_id = data.communication_channel.pseudonym_id;
      $("#channel_" + data.communication_channel.id).removeClass('unconfirmed');
      $(".channel.pseudonym_" + pseudonym_id).removeClass('unconfirmed');
      $("#confirm_communication_channel").dialog('close');
      $.flashMessage( I18n.t('notices.contact_confirmed', "Contact successfully confirmed!") );
    },
    error: function(data) {
      $(this).find(".status_message").text( I18n.t('errors.confirmation_failed', "Confirmation failed.  Please try again.") );
    }
  });
  $(".channel_list .channel .default_link").click(function(event) {
    event.preventDefault();
    var channel_id = $(this).parents(".channel").getTemplateData({textValues: ['channel_id']}).channel_id;
    var formData = {
      'default_email_id': channel_id
    }
    $.ajaxJSON($(this).attr('href'), 'PUT', formData, function(data) {
      var channel_id = data.user.communication_channel.id;
      $(".channel.default").removeClass('default');
      $(".channel#channel_" + channel_id).addClass('default');
      $(".default_email.display_data").text(data.user.pseudonym.unique_id);
    });
  });
  $(".dialog .re_send_confirmation_link").click(function(event) {
    event.preventDefault();
    var $link = $(this);
    $link.text( I18n.t('links.resending_confirmation', "Re-Sending...") );
    $.ajaxJSON($link.attr('href'), 'POST', {}, function(data) {
      $link.text( I18n.t('links.resent_confirmation', "Done! Message may take a few minutes.") );
    }, function(data) {
      $link.text( I18n.t('links.resend_confirmation_failed', "Request failed. Try again.") );
    });
  });
  $("#communication_channels .cancel_button").click(function(event) {
    $("#communication_channels").dialog('close');
  });
  $("#confirm_email_channel .cancel_button").click(function() {
    $("#confirm_email_channel").dialog('close');
  });
});
});
