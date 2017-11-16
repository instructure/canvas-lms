/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import I18n from 'i18n!profile'
import $ from 'jquery'
import './jquery.ajaxJSON'
import './jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors */
import 'jqueryui/dialog'
import './jquery.instructure_misc_helpers' /* replaceTags */
import './jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import './jquery.loadingImg'
import 'compiled/jquery.rails_flash_notifications'
import './jquery.templateData' /* fillTemplateData, getTemplateData */
import 'jqueryui/tabs'

$(document).ready(function() {
  $("#communication_channels").tabs();
  $("#communication_channels").bind('tabsshow', function(event) {
    var channelInputField;
    if($(this).css('display') != 'none') {
      // TODO: This is always undefined - where did this come from?
      var idx = $(this).data('selected.tabs');
      if(idx == 0) {
        channelInputField = $("#register_email_address").find(":text:first");
      } else {
        channelInputField = $("#register_sms_number").find("input[type=tel]:first");
      }
    }
    formatTabs(channelInputField);
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
      modal: true
    });
    if($(this).hasClass('add_contact_link')) {
      $("#communication_channels").tabs('select', '#register_sms_number');
      view = "sms";
    } else {
      $("#communication_channels").tabs('select', '#register_email_address');
    }
  });

  var formatTabs = function (tabs) {
    var $form = $(tabs).parents("#register_sms_number");
    var sms_number = $form.find(".sms_number").val().replace(/[^\d]/g, "");

    var useEmail = !ENV.INTERNATIONAL_SMS_ENABLED || $form.find(".country option:selected").data('useEmail');

    // Don't show the 10-digit warning if we're not expecting a U.S. number
    $form.find(".should_be_10_digits").showIf(useEmail && sms_number && sms_number.length != 10);

    // Show the "international text messaging rates may apply" warning if international SMS is enabled, the user has
    // selected a country, and that country is not the U.S.
    $form.find('.intl_rates_may_apply').showIf(
      ENV.INTERNATIONAL_SMS_ENABLED &&
      !useEmail &&
      $form.find(".country option:selected").val() !== 'undecided'
    );

    if (useEmail) {
      $form.find('.sms_email_group').show();
      var email = $form.find(".carrier").val();
      $form.find(".sms_email").attr('disabled', email != 'other');
      if(email == "other") { return; }
      email = email.replace("#", sms_number);
      $form.find(".sms_email").val(email);
    } else {
      $form.find('.sms_email_group').hide();
    }
  }

  $("#register_sms_number .user_selected").bind('change blur keyup focus', function() {
    formatTabs(this);
  });

  $("#register_sms_number,#register_email_address").formSubmit({
    object_name: 'communication_channel',
    processData: function(data) {
      var address;
      var type;
      if (data['communication_channel[type]'] === 'email') {
        // Email channel
        type = 'email';
        address = data.communication_channel_email;
      } else if (ENV.INTERNATIONAL_SMS_ENABLED && $('#communication_channel_sms_country').val() === 'undecided') {
        // Haven't selected a country yet
        $(this).formErrors({communication_channel_sms_country: I18n.t("Country is required")});
        return false;
      } else if (!ENV.INTERNATIONAL_SMS_ENABLED || $('#communication_channel_sms_country option:selected').data('useEmail')) {
        // SMS channel using an email address
        type = 'sms_email';
        address = data.communication_channel_sms_email;
      } else {
        // SMS channel using a phone number
        type = 'sms_number';
        address = '+' + data.communication_channel_sms_country + data.communication_channel_sms_number;
      }

      delete data.communication_channel_sms_country;

      if (type == 'email' || type == 'sms_email') {
        // Make sure it's a valid email address
        var match = address.match(/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/);
        if (!match) {
          // Not a valid email address. Show a message on the relevant field, then bail.
          var errorMessage = address === "" ? I18n.t("Email is required") : I18n.t("Email is invalid!");
          if (type == 'email') {
            $(this).formErrors({communication_channel_email: errorMessage});
          } else {
            $(this).formErrors({communication_channel_sms_email: errorMessage});
          }
          return false;
        }
      } else {
        // Make sure it's a valid phone number. Validate the phone number they typed instead of the address because
        // the address will already have the country code prepended, and this will result in our regex failing always
        // because it's not expecting the leading plus sign (and it can't just be added to the regex because then
        // we can't detect when they entered a blank phone number). libphonenumber plz
        var match = data.communication_channel_sms_number.match(/^[0-9]+$/);
        if (!match) {
          var errorMessage = address === "" ? I18n.t("Cell Number is required") : I18n.t("Cell Number is invalid!");
          $(this).formErrors({communication_channel_sms_number: errorMessage});
          return false;
        }
      }

      // Don't need these anymore
      delete data.communication_channel_sms_number;
      delete data.communication_channel_sms_email;

      data['communication_channel[address]'] = address;
    },
    beforeSubmit: function(data) {
      var $list = $(".email_channels");
      if($(this).attr('id') == "register_sms_number") {
        $list = $(".other_channels");
      }
      var path = data['communication_channel[address]'];
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
      $("#communication_channels").hide();
      $channel.loadingImage({image_size: 'small'});
      return $channel;
    }, success: function(channel, $channel) {
      $("#communication_channels").dialog('close');
      $("#communication_channels").hide();
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

  var manageAfterDeletingAnEmailFocus = function(currentElement) {
    // There may be a better way to do this but I'm not aware of another way. I'm trying to
    // find the closest prev() or next() sibling
    var $elementToFocusOn = $(currentElement).next('.channel:not(.blank)').last();
    if (!$elementToFocusOn.length) {
      $elementToFocusOn = $(currentElement).prev('.channel:not(.blank)').last();
    }

    if ($elementToFocusOn.length) {
      $elementToFocusOn.find('.email_channel').first().focus();
    } else {
      $(this).parents(".channel_list .email_channel").first().focus();
    }
  }

  $(".channel_list .channel .delete_channel_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".channel").confirmDelete({
      url: $(this).attr('href'),
      success: function(data) {
        var $list = $(this).parents(".channel_list");
        manageAfterDeletingAnEmailFocus(this);
        $(this).remove();
        $list.toggleClass('single', $list.find(".channel:visible").length <= 1);
      }
    });
  });
  $(".channel_list .channel .reset_bounce_count_link").click(function(event) {
    event.preventDefault();
    $.ajaxJSON($(this).attr('href'), 'POST', {}, function(data) {
      $(this).parents('.channel').find('.bouncing-channel').remove();
      $(this).remove();
      $.flashMessage(I18n.t('Bounce count reset!'))
    }.bind(this));
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
      $(this).find(".status_message").css('visibility', 'hidden');
      $.flashError( I18n.t("Confirmation failed.  Please try again.") );
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
      $(".channel.default").removeClass('default').find('a.default_link span.screenreader-only.default_label').remove();
      $(".channel#channel_" + channel_id).addClass('default').find('a.default_link').append( $('<span class="screenreader-only" />').text(I18n.t("This is the default email address")) );
      $(".default_email.display_data").text(data.user.communication_channel.path);
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
