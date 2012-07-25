/**
 * Copyright (C) 2011 Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
define([
  'INST' /* INST */,
  'i18n!profile',
  'jquery' /* $ */,
  'compiled/util/BackoffPoller',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* parseFromISO, time_field, datetime_field */,
  'jquery.instructure_forms' /* formSubmit, formErrors, errorBox */,
  'jqueryui/dialog',
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData */,
  'jqueryui/sortable' /* /\.sortable/ */
], function(INST, I18n, $, BackoffPoller) {

  var $profile_table = $(".profile_table"),
      $update_profile_form = $("#update_profile_form"),
      $default_email_id = $("#default_email_id"),
      profile_pics_url = '/api/v1/users/self/avatars';

  var thumbnailPoller = new BackoffPoller(profile_pics_url, function(data) {
    var loadedImages = {},
        $images = $('img.pending'),
        image,
        $image,
        associatedUrl,
        count = 0;
    for (var i = 0, l = data.length; i < l; i++) {
      image = data[i];
      if (!image.pending) loadedImages[image.token] = image.url;
    }
    $images.each(function() {
      $image = $(this);
      associatedUrl = loadedImages[$image.data('token')]
      if (associatedUrl != null) {
        $image.removeClass('pending');
        $image.attr('src', associatedUrl);
        count++;
      }
    });
    if (count === $images.length) return 'stop';
    if (count > 0) return 'reset';
    return 'continue';
  });
  
  $(".edit_profile_link").click(function(event) {
    $profile_table.addClass('editing')
      .find(".edit_data_row").show().end()
      .find(":text:first").focus().select();
    return false;
  });
  
  $profile_table.find(".cancel_button").click(function(event) {
    $profile_table
      .removeClass('editing')
      .find(".change_password_row,.edit_data_row,.more_options_row").hide().end()
      .find("#change_password_checkbox").attr('checked', false);
    return false;
  });
  
  $profile_table.find("#change_password_checkbox")
    .click(function(){
      //this is a hack because in ie it did not fire the "change" event untill you click away from the checkbox.
      if (INST.browser.ie) {
        $(this).triggerHandler('change');
      }
    })
    .change(function(event) {
      event.preventDefault();
      if(!$(this).attr('checked')) {
        $profile_table.find(".change_password_row").hide().find(":password").val("");
      } else {
        $(this).addClass('showing');
        $profile_table.find(".change_password_row").show().find(":password:first").focus().select();
      }
    })
    .attr('checked', false)
    .change();
    
  $update_profile_form
    .attr('method', 'PUT')
    .formSubmit({
      required: ($update_profile_form.find('#user_name').length ? ['name'] : []),
      object_name: 'user',
      property_validations: {
        '=default_email_id': function(val, data) {
          if($("#default_email_id").length && (!val || val == "new")) {
            return I18n.t('please_select_an_option', "Please select an option");
          }
        },
        'birthdate(1i)': function(val, data) {
          if (!val && (data['birthdate(2i)'] || data['birthdate(3i)'])) {
            return I18n.t('please_select_a_year', "Please select a year");
          }
        },
        'birthdate(2i)': function(val, data) {
          if (!val && (data['birthdate(1i)'] || data['birthdate(3i)'])) {
            return I18n.t('please_select_a_month', "Please select a month");
          }
        },
        'birthdate(3i)': function(val, data) {
          if (!val && (data['birthdate(1i)'] || data['birthdate(2i)'])) {
            return I18n.t('please_select_a_day', "Please select a day");
          }
        }
      },
      beforeSubmit: function(data) {
        $update_profile_form.loadingImage();
      },
      success: function(data) {
        var user = data.user;
        var templateData = {
          short_name: user.short_name,
          full_name: user.name,
          sortable_name: user.sortable_name,
          time_zone: user.time_zone,
          birthdate: (user.birthdate ? $.parseFromISO(user.birthdate).date_formatted : '-'),
          locale: $("#user_locale option[value='" + user.locale + "']").text()
        };
        if (templateData.locale != $update_profile_form.find('.locale').text()) {
          location.reload();
          return;
        }
        $update_profile_form.loadingImage('remove');
        if ($default_email_id.length > 0) {
          var default_email = $default_email_id.find('option:selected').text();
          $('.default_email.display_data').text(default_email);
        }
        $('.channel').removeClass('default');
        $("#channel_" + user.communication_channel.id).addClass('default');
        $update_profile_form.fillTemplateData({
          data: templateData
        }).find(".cancel_button").click();
      },
      error: function(data) {
        $update_profile_form.loadingImage('remove').formErrors(data.errors || data);
        $(".edit_profile_link").click();
      }
    })
    .find(".more_options_link").click(function() {
      $update_profile_form.find(".more_options_link_row").hide();
      $update_profile_form.find(".more_options_row").show();
      return false;
    });
    
  $("#default_email_id").change(function() {
    if($(this).val() == "new") {
      $(".add_email_link:first").click();
    }
  });
  
  $("#unregistered_services li.service").click(function(event) {
    event.preventDefault();
    $("#" + $(this).attr('id') + "_dialog").dialog('close').dialog({
      width: 350,
      autoOpen: false
    }).dialog('open');
  });
  $(".create_user_service_form").formSubmit({
    object_name: 'user_service',
    beforeSubmit: function(data) {
      $(this).loadingImage();
    },
    success: function(data) {
      $(this).loadingImage('remove').parents(".content").dialog('close');
      document.location.reload();
    },
    error: function(data) {
      $(this).loadingImage('remove').errorBox(I18n.t('errors.registration_failed', 'Registration failed. Check the user name and password, and try again.'));
    }
  });
  $("#unregistered_services li.service .content form .cancel_button").click(function(event) {
    $(this).parents(".content").dialog('close');
  });
  $("#registered_services li.service .delete_service_link").click(function(event) {
    event.preventDefault();
    $(this).parents("li.service").confirmDelete({
      message: I18n.t('confirms.unregister_service', "Are you sure you want to unregister this service?"),
      url: $(this).attr('href'),
      success: function(data) {
        $(this).slideUp(function() {
          $("#unregistered_services").find("#unregistered_" + $(this).attr('id')).slideDown();
        });
      }
    });
  });
  $(".service").hover(function() {
    $(this).addClass('service-hover');
  }, function() {
    $(this).removeClass('service-hover');
  });
  $("#show_user_services").change(function() {
    $.ajaxJSON($("#update_profile_form").attr('action'), 'PUT', {'user[show_user_services]': $(this).prop('checked')}, function(data) {
    }, function(data) {
    });
  });
  $(".delete_pseudonym_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".pseudonym").confirmDelete({
      url: $(this).attr('href'),
      message: I18n.t('confirms.delete_login', "Are you sure you want to delete this login?")
    });
  });
  $(".datetime_field").datetime_field();
  $(".expires_field").bind('change keyup', function() {
    $(this).closest("td").find(".hint").showIf(!$(this).val());
  });
  $(".delete_key_link").click(function(event) {
    event.preventDefault();
    $(this).closest(".access_token").confirmDelete({
      url: $(this).attr('rel'),
      message: I18n.t('confirms.delete_access_key', "Are you sure you want to delete this access key?"),
      success: function() {
        $(this).remove();
        if(!$(".access_token:visible").length) {
          $("#no_approved_integrations,#access_tokens_holder").toggle();
        }
      }
    });
  });
  $("#add_access_token_dialog .cancel_button").click(function() {
    $("#add_access_token_dialog").dialog('close');
  });
  $("#access_token_form").formSubmit({
    object_name: 'access_token',
    required: ['purpose'],
    beforeSubmit: function() {
      $(this).find("button").attr('disabled', true).filter(".submit_button").text(I18n.t('buttons.generating_token', "Generating Token..."));
    },
    success: function(data) {
      $(this).find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('buttons.generate_token', "Generate Token"));
      $("#add_access_token_dialog").dialog('close');
      $("#no_approved_integrations").hide()
      $("#access_tokens_holder").show();
      var $token = $(".access_token.blank:first").clone(true).removeClass('blank');
      data.created = $.parseFromISO(data.created_at).datetime_formatted || "--";
      data.expires = $.parseFromISO(data.expires_at).datetime_formatted || I18n.t('token_never_expires', "never");
      data.used = "--";
      $token.fillTemplateData({
        data: data,
        hrefValues: ['id']
      });
      $token.data('token', data);
      $("#access_tokens > tbody").append($token.show());
      $token.find(".show_token_link").click();
    },
    error: function() {
      $(this).find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('errors.generating_token_failed', "Generating Token Failed"));
    }
  });
  $("#token_details_dialog .regenerate_token").click(function() {
    var result = confirm(I18n.t('confirms.regenerate_token', "Are you sure you want to regenerate this token?  Anything using this token will have to be updated."));
    if(!result) { return; }
    
    var $dialog = $("#token_details_dialog");
    var $token = $dialog.data('token');
    var url = $dialog.data('token_url');
    var $button = $(this);
    $button.text(I18n.t('buttons.regenerating_token', "Regenerating token...")).attr('disabled', true);
    $.ajaxJSON(url, 'PUT', {'access_token[regenerate]': '1'}, function(data) {
      data.created = $.parseFromISO(data.created_at).datetime_formatted || "--";
      data.expires = $.parseFromISO(data.expires_at).datetime_formatted || I18n.t('token_never_expires', "never");
      data.used = $.parseFromISO(data.last_used_at).datetime_formatted || "--";
      data.visible_token = data.visible_token || "protected";
      $dialog.fillTemplateData({data: data})
        .find(".full_token_warning").showIf(data.visible_token.length > 10);
      $token.data('token', data);
      $button.text(I18n.t('buttons.regenerate_token', "Regenerate Token")).attr('disabled', false);
    }, function() {
      $button.text(I18n.t('errors.regenerating_token_failed', "Regenerating Token Failed")).attr('disabled', false);
    });
  });
  $(".show_token_link").click(function(event) {
    event.preventDefault();
    var $dialog = $("#token_details_dialog");
    var url = $(this).attr('rel');
    $dialog.dialog('close').dialog({
      autoOpen: false,
      width: 600
    }).dialog('open');
    var $token = $(this).parents(".access_token");
    $dialog.data('token', $token);
    $dialog.find(".loading_message").show().end()
      .find(".results,.error_loading_message").hide();
    function tokenLoaded(token) {
      $dialog.fillTemplateData({data: token});
      $dialog.data('token_url', url);
      $dialog.find(".refresh_token").showIf(token.visible_token && token.visible_token !== "protected")
        .find(".regenerate_token").text(I18n.t('buttons.regenerate_token', "Regenerate Token")).attr('disabled', false);
      $dialog.find(".loading_message,.error_loading_message").hide().end()
        .find(".results").show().end()
        .find(".full_token_warning").showIf(token.visible_token.length > 10);
    }
    var token = $token.data('token');
    if(token) {
      tokenLoaded(token);
    } else {
      $.ajaxJSON(url, 'GET', {}, function(data) {
        data.created = $.parseFromISO(data.created_at).datetime_formatted || "--";
        data.expires = $.parseFromISO(data.expires_at).datetime_formatted || I18n.t('token_never_expires', "never");
        data.used = $.parseFromISO(data.last_used_at).datetime_formatted || "--";
        data.visible_token = data.visible_token || "protected";
        $token.data('token', data);
        tokenLoaded(data);
      }, function() {
        $dialog.find(".error_loading_message").show().end()
          .find(".results,.loading_message").hide();
      });
    }
    
  });
  $(".add_access_token_link").click(function(event) {
    event.preventDefault();
    $("#access_token_form").find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('buttons.generate_token', "Generate Token"));
    $("#add_access_token_dialog").find(":input").val("").end()
    .dialog({
      width: 500
    });
  });
  $(document).fragmentChange(function(event, hash) {
    var type = hash.substring(1);
    if(type.match(/^register/)) {
      type = type.substring(9);
    }
    if($("#unregistered_service_" + type + ":visible").length > 0) {
      $("#unregistered_service_" + type + ":visible").click();
    }
  }).fragmentChange();
  $("#profile_pic_dialog .add_pic_link").click(function(event) {
    event.preventDefault();
    $("#add_pic_form").slideToggle();
  });
  $("#profile_pic_dialog").delegate('img', 'click', function() {
    if(!$(this).hasClass('pending')) {
      $("#profile_pic_dialog .img.selected").removeClass('selected');
      $(this).parent().addClass('selected');
      $("#profile_pic_dialog .select_button").attr('disabled', false);
    }
  });
  $("#add_pic_form").formSubmit({
    fileUpload: true,

    beforeSubmit: function() {
      $(this).find("button").attr('disabled', true).text(I18n.t('buttons.adding_file', "Adding File..."));
      var $span = $("<span class='img'><img/></span>");
      var $img = $span.find("img");
      $img.attr('src', '/images/ajax-loader.gif');
      $img.addClass('pending');
      $("#profile_pic_dialog .profile_pic_list div").before($span);
      return $span;
    },

    success: function(data, $span) {
      var attachment = data.attachment,
          avatar     = data.avatar,
          addPicForm = $('#add_pic_form')

      $(this).find('button')
        .prop('disabled', false)
        .text(I18n.t('buttons.add_file', 'Add File'));

      addPicForm.slideToggle();

      if ($span) {
        var $img = $span.find('img');

        $img
          .data('type', 'attachment')
          .data('token', data.avatar.token)
          .attr('alt', attachment.display_name);

        $img[0].onerror = function() {
          $img.attr('src', '/images/dotted_pic.png');
        }

        thumbnailPoller.start().then(function() { $img.click(); });
      }
    },

    error: function(data, $span) {
      $(this).find("button").attr('disabled', false).text(I18n.t('errors.adding_file_failed', "Adding File Failed"));
      if ($span) {
        $span.remove();
      }
    }
  });

  $("#profile_pic_dialog .cancel_button").click(function() {
    $("#profile_pic_dialog").dialog('close');
  });

  $("#profile_pic_dialog .select_button").click(function() {
    var url = '/api/v1/users/self',
        $dialog = $('#profile_pic_dialog'),
        $buttons = $dialog.find('button'),
        $img = $('#profile_pic_dialog .profile_pic_list .img.selected img'),
        data = { 'user[avatar][token]': $img.data('token') }

    $buttons
      .prop('disabled', true)
      .filter('.select_button')
      .text(I18n.t('buttons.selecting_image', 'Selecting Image...'));

    if ($img.length === 0) { return; }

    $.ajaxJSON(url, 'PUT', data, function(user) {
      // on success
      var profilePicLink = $('.profile_pic_link img'),
          newSrc = $('#profile_pic_dialog .img.selected img').attr('src');

      $buttons
        .prop('disabled', false)
        .filter('.select_button')
        .text(I18n.t('buttons.select_image', 'Select Image'));

      if (user.avatar_url === '/images/no_pic.gif') {
        user.avatar_url = '/images/dotted_pic.png';
      }

      profilePicLink.attr('src', newSrc);
      $dialog.dialog('close');
    }, function(response) {
      // on error
      $buttons
        .prop('disabled', false)
        .filter('.select_button')
        .text(I18n.t('errors.selecting_image_failed', 'Selecting image failed, please try again'));
    });
  });

  $(".profile_pic_link").click(function(event) {
    event.preventDefault();
    var $dialog = $("#profile_pic_dialog");
    $dialog.find(".img.selected").removeClass('selected');
    $dialog.find(".select_button").prop('disabled', true);

    if($(this).hasClass('locked')) {
      alert(I18n.t('alerts.profile_picture_locked', "Your profile picture has been locked by an administrator, and cannot be changed."));
      return;
    }

    if(!$dialog.hasClass('loaded')) {
      $dialog.find(".profile_pic_list h3").text(I18n.t('headers.loading_images', "Loading Images..."));
      $.ajaxJSON(profile_pics_url, 'GET', {}, function(data) {
        if(data && data.length > 0) {
          $dialog.addClass('loaded')
          $dialog.find(".profile_pic_list h3").remove();
          var pollThumbnails = false;
          for(var idx in data) {
            var image = data[idx],
                $span = $('<span />', { 'class': 'img' }),
                $img  = $('<img />').appendTo($span);

            if (image.pending) {
              $img
                .addClass('pending')
                .attr('src', '/images/ajax-loader.gif')
                .data('token', image.token);
              pollThumbnails = true;
            } else {
              $img
                .attr('src', image.url)
                .data('token', image.token);
            }
            $img
              .data('token', image.token)
              .attr('alt', image.display_name || image.type)
              .attr('title', image.display_name || image.type)
              .attr('data-type', image.type);

            $img[0].onerror = function() {
              $span.remove();
            }
            $dialog.find(".profile_pic_list div").before($span);
          }
          if (pollThumbnails) thumbnailPoller.start();
        } else {
          $dialog.find(".profile_pic_list h3").text(I18n.t('errors.loading_images_failed', "Loading Images Failed, please try again"));
        }
      }, function(data) {
        $dialog.find(".profile_pic_list h3").text(I18n.t('errors.loading_images_failed', "Loading Images Failed, please try again"));
      });
    }
    $("#profile_pic_dialog").dialog('close').dialog({
      autoOpen: false,
      title: I18n.t('titles.select_profile_pic', "Select Profile Pic"),
      width: 500,
      height: 300
    }).dialog('open');
  });
  var checkImage = function() {
    var img = $(".profile_pic_link img")[0];
    if(img) {
      if(!img.complete) {
        setTimeout(checkImage, 500);
      } else {
        if(img.width < 5) {
          img.src = '/images/dotted_pic.png';
        }
      }
    }
  };
  setTimeout(checkImage, 500);
});
