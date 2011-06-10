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

$(function() {
  var $profile_table = $(".profile_table"),
      $update_profile_form = $("#update_profile_form"),
      $default_email_id = $("#default_email_id");
  
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
      required: ['name'],
      object_name: 'user',
      property_validations: {
        '=default_email_id': function(val, data) {
          if($("#default_email_id").length && (!val || val == "new")) {
            return "Please select an option";
          }
        }
      },
      beforeSubmit: function(data) {
        $update_profile_form.loadingImage();
      },
      success: function(data) {
        var user = data.user;
        $update_profile_form.loadingImage('remove');
        if ($default_email_id.length > 0) {
          var default_email = $default_email_id.find('option:selected').text();
          $('.default_email.display_data').text(default_email);
        }
        $('.channel').removeClass('default');
        $("#channel_" + user.communication_channel.id).addClass('default');
        var templateData = {
          short_name: user.short_name,
          full_name: user.name,
          time_zone: user.time_zone
        };
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
      $(this).loadingImage('remove').errorBox('Registration failed. Check the user name and password, and try again.');
    }
  });
  $("#unregistered_services li.service .content form .cancel_button").click(function(event) {
    $(this).parents(".content").dialog('close');
  });
  $("#registered_services li.service .delete_service_link").click(function(event) {
    event.preventDefault();
    $(this).parents("li.service").confirmDelete({
      message: "Are you sure you want to unregister this service?",
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
    $.ajaxJSON($("#update_profile_form").attr('action'), 'PUT', {'user[show_user_services]': $(this).attr('checked')}, function(data) {
    }, function(data) {
    });
  });
  $(".delete_pseudonym_link").click(function(event) {
    event.preventDefault();
    $(this).parents(".pseudonym").confirmDelete({
      url: $(this).attr('href'),
      message: "Are you sure you want to delete this login?"
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
      message: "Are you sure you want to delete this access key?",
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
      $(this).find("button").attr('disabled', true).filter(".submit_button").text("Generating Token...");
    },
    success: function(data) {
      $(this).find("button").attr('disabled', false).filter(".submit_button").text("Generate Token");
      $("#add_access_token_dialog").dialog('close');
      $("#no_approved_integrations").hide()
      $("#access_tokens_holder").show();
      var $token = $(".access_token.blank:first").clone(true).removeClass('blank');
      data.created = $.parseFromISO(data.created_at).datetime_formatted || "--";
      data.expires = $.parseFromISO(data.expires_at).datetime_formatted || "never";
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
      $(this).find("button").attr('disabled', false).filter(".submit_button").text("Generating Token Failed");
    }
  });
  $("#token_details_dialog .regenerate_token").click(function() {
    var result = confirm("Are you sure you want to regenerate this token?  Anything using this token will have to be updated.");
    if(!result) { return; }
    
    var $dialog = $("#token_details_dialog");
    var $token = $dialog.data('token');
    var url = $dialog.data('token_url');
    var $button = $(this);
    $button.text("Regenerating token...").attr('disabled', true);
    $.ajaxJSON(url, 'PUT', {'access_token[regenerate]': '1'}, function(data) {
      data.created = $.parseFromISO(data.created_at).datetime_formatted || "--";
      data.expires = $.parseFromISO(data.expires_at).datetime_formatted || "never";
      data.used = $.parseFromISO(data.last_used_at).datetime_formatted || "--";
      data.visible_token = data.visible_token || "protected";
      $dialog.fillTemplateData({data: data})
        .find(".full_token_warning").showIf(data.visible_token.length > 10);
      $token.data('token', data);
      $button.text("Regenerate Token").attr('disabled', false);
    }, function() {
      $button.text("Regenerating Token Failed").attr('disabled', false);
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
        .find(".regenerate_token").text("Regenerate Token").attr('disabled', false);
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
        data.expires = $.parseFromISO(data.expires_at).datetime_formatted || "never";
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
    $("#access_token_form").find("button").attr('disabled', false).filter(".submit_button").text("Generate Token");
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
      $(this).find("button").attr('disabled', true).text("Adding File...");
      var $span = $("<span class='img'><img/></span>");
      var $img = $span.find("img");
      $img.attr('src', '/images/ajax-loader.gif');
      $img.addClass('pending');
      return $img;
    },
    success: function(data, $img) {
      $(this).find("button").attr('disabled', false).text("Add File");
      var attachment = data.attachment;
      if($img) {
        $img.removeClass('pending');
        $img.attr('src', '/images/thumbnails/' + attachment.id + '/' + attachment.uuid);
        $img.attr('data-type', 'attachment');
        $img.attr('alt', attachment.display_name);
        $img[0].onerror = function() {
          $img.attr('src', '/images/dotted_pic.png');
        }
        $("#profile_pic_dialog .profile_pic_list div").before($img);
        $img.click();
      }
    },
    error: function(data, $img) {
      $(this).find("button").attr('disabled', false).text("Adding File Failed");
      if($img) {
        $img.remove();
      }
    }
  });
  $("#profile_pic_dialog .cancel_button").click(function() {
    $("#profile_pic_dialog").dialog('close');
  });
  $("#profile_pic_dialog .select_button").click(function() {
    var url = $("#update_profile_form").attr('action');
    var $dialog = $("#profile_pic_dialog");
    $dialog.find("button").attr('disabled', true).filter(".select_button").text("Selecting Image...");
    var $img = $("#profile_pic_dialog .profile_pic_list .img.selected img");
    if($img.length == 0) {
      return;
    }
    var src = $img.attr('src');
    var data = {
      'user[avatar_image][url]': src,
      'user[avatar_image][type]': $img.attr('data-type')
    };
    $.ajaxJSON(url, 'PUT', data, function(data) {
      $dialog.find("button").attr('disabled', false).filter(".select_button").text("Select Image");
      var user = data.user;
      if(user.avatar_url == '/images/no_pic.gif') {
        user.avatar_url = '/images/dotted_pic.png';
      }
      $(".profile_pic_link img").attr('src', user.avatar_url);
      $dialog.dialog('close');
    }, function(data) {
      $dialog.find("button").attr('disabled', false).filter(".select_button").text("Selecting Image Failed, please try again");
    });
  });
  $(".profile_pic_link").click(function(event) {
    event.preventDefault();
    var $dialog = $("#profile_pic_dialog");
    $dialog.find(".img.selected").removeClass('selected');
    $dialog.find(".select_button").attr('disabled', true);
    if($(this).hasClass('locked')) {
      alert("Your profile picture has been locked by an administrator, and cannot be changed.");
      return;
    }
    if(!$dialog.hasClass('loaded')) {
      $dialog.find(".profile_pic_list h3").text("Loading Images...");
      $.ajaxJSON($(".profile_pics_url").attr('href'), 'GET', {}, function(data) {
        if(data && data.length > 0) {
          $dialog.addClass('loaded')
          $dialog.find(".profile_pic_list h3").remove();
          for(var idx in data) {
            var image = data[idx];
            var $span = $("<span class='img'><img/></span>");
            $img = $span.find("img");
            $img.attr('src', image.url);
            $img.attr('alt', image.alt || image.type);
            $img.attr('title', image.alt || image.type);
            $img.attr('data-type', image.type);
            $img[0].onerror = function() {
              $span.remove();
            }
            $dialog.find(".profile_pic_list div").before($span);
          }
        } else {
          $dialog.find(".profile_pic_list h3").text("Loading Images Failed, please try again");
        }
      }, function(data) {
        $dialog.find(".profile_pic_list h3").text("Loading Images Failed, please try again");
      });
    }
    $("#profile_pic_dialog").dialog('close').dialog({
      autoOpen: false,
      title: "Select Profile Pic",
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
