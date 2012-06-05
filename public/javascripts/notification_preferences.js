require([
  'i18n!profile' /* I18n.t */,
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* getFormData */,
  'jquery.instructure_misc_plugins' /* showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.rails_flash_notifications' /* flashMessage, flashError */,
  'jquery.templateData' /* getTemplateData */
], function(I18n, $) {

$(document).ready(function() {
  $(".notification_preferences .frequency").click(function(event) {
    event.preventDefault();
    if(!$(this).hasClass('selected')) {    
      $(this).parents("tr").find(".frequency").removeClass('selected').removeClass('selected_pending');
      $(this).addClass('selected_pending');
    }
  });
  $(".notification_preferences .add_notification_link").click(function(event) {
    event.preventDefault();
    var $prev = $(this).parents("tr").prev();
    var $next = $prev.clone(true);
    $next.find(".delete_preference_link").show();
    $next.find(".frequency.selected").removeClass('selected').addClass('selected_pending');
    $prev.after($next);
    var $prev = $next.prev(".preference");
    while($prev.length > 0) {
      $prev.find(".delete_preference_link").show();
      $prev = $prev.prev(".preference");
    }
    $next.find(".contact_type_select").change();
  });
  $(".delete_preference_link").bind('click', function(event, skipAnimate) {
    event.preventDefault();
    var $first = $(this).parents(".preference");
    while($first.prev(".preference").length > 0) {
      $first = $first.prev(".preference");
    }
    var cnt = 1;
    var $last = $first;
    while($last.next(".preference").length > 0) {
      $last = $last.next(".preference");
      cnt++;
    }
    var speed = skipAnimate ? 0 : 'normal';
    $(this).parents(".preference").fadeOut(speed, function() {
      if(cnt < 3) {
        $first.find(".delete_preference_link").hide();
        while($first.next(".preference").length > 0) {
          $first = $first.next(".preference");
          $first.find(".delete_preference_link").hide();
        }
      }
      $(this).remove();
    });
  });
  $(".sms_select").change(function(event) {
    if($(this).val() == "new") {
      $(".add_contact_link").click();
    }
  });
  $(".email_select").change(function(event) {
    if($(this).val() == "new") {
      $(".add_email_link").click();
    }
  });
  $(".contact_type_select").change(function(event) {
    var $preference = $(this).parents("tr.preference");
    var val = $(this).val();
    if($preference.find(".contact_select").hasClass(val)) { return; }
    var $new_select = $("#select_templates ." + val).clone(true);
    $new_select[0].selectedIndex = 0;
    $preference.find(".contact_select").after($new_select).remove();
    $preference.find(".at").showIf(val == 'email_select' || val == 'sms_select');
  }).each(function() { $(this).change(); });
  $(".save_preferences_button").click(function(event) {
    event.preventDefault();
    var $button = $(this);
    $(".notification_preferences").loadingImage();
    var data = $(".notification_preferences").getFormData();
    $(".notification_preferences tr.preference").each(function() {
      var params = $(this).getTemplateData({textValues: ['category_slug', 'channel_id']});
      var frequency = 'immediately';
      params.channel_id = $(this).getFormData().channel_id;
      var $frequency = $(this).find(".frequency.selected,.frequency.selected_pending");
      if($frequency.hasClass('never')) {
        frequency = 'never';
      } else if($frequency.hasClass('daily')) {
        frequency = 'daily';
      } else if($frequency.hasClass('weekly')) {
        frequency = 'weekly';
      }
      if(params.category_slug && params.channel_id) {
        data["category_" + params.category_slug + "[channel_" + params.channel_id + "]"] = frequency;
      }
    });
    var url = $("#contact_urls .update_communication_url").filter(":last").attr('href');
    $button.text(I18n.t('communication.buttons.saving_preferences', "Saving Preferences...")).attr('disabled', true);
    $.ajaxJSON(url, 'POST', data, function(data) {
      $button.text(I18n.t('communication.buttons.saved_preferences', "Saved Preferences!")).attr('disabled', false);
      setTimeout(function() {
        $button.text(I18n.t('communication.buttons.save_preferences', "Save Preferences"));
      }, 2500);
      $.flashMessage(I18n.t('communication.notices.communication_preferences_updated', 'Communication Preferences updated'));
      $(".notification_preferences").loadingImage('remove');
      $("tr.preference .frequency.selected_pending").removeClass('selected_pending').addClass('selected');
      var found = {};
      $("tr.preference").each(function() {
        var slug = $(this).getTemplateData({textValues: ['category_slug']}).category_slug;
        if(found[slug]) {
          $(this).find(".delete_preference_link").triggerHandler('click', true);
        }
        found[slug] = true;
      });
      found = {}
      for(var idx in data) {
        var policy = data[idx].notification_policy;
        if(found[policy.notification_id]) {
          $(".add_notification_" + policy.notification_id).click();
        }
        found[policy.notification_id] = true;
        var $preference = $(".preference_" + policy.notification_id + ":last");
        var type = "email_select";
        if($(".channel_option_" + policy.communication_channel_id).parents("select").hasClass('sms_select')) {
          type = "sms_select";
        } else if($(".channel_option_" + policy.communication_channel_id).parents("select").hasClass('facebook_select')) {
          type = "facebook_select";
        } else if($(".channel_option_" + policy.communication_channel_id).parents("select").hasClass('twitter_select')) {
          type = "twitter_select";
        }
        $preference.find(".contact_type_select").val(type).change();
        $preference.find(".contact_select").val(policy.communication_channel_id);
        $preference.find(".frequency." + policy.frequency).click();
      }
      $("tr.preference .frequency.selected_pending").removeClass('selected_pending').addClass('selected');
    }, function(data) {
      $button.text(I18n.t('communication.buttons.problem_saving_preferences', "Problem Saving Preferences")).attr('disabled', false);
      $(".notification_preferences").loadingImage('remove');
      $.flashError(I18n.t('communication.errors.saving_preferences_failed', 'Oops! Something broke.  Try saving again'));
    });
  });
  $(".sms_select, .email_select").change(function() {
    if($(this).parents("tr.preference").length > 0) {
      $(this).parents("tr.preference td.frequency.selected").removeClass('selected').addClass('selected_pending');
    }
  });
});
});
