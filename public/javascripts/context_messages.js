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

I18n.scoped('context.inbox', function(I18n) {
  $(document).ready(function() {
    var previous_visible_types = [];
    $("#visible_message_types :checkbox").each(function() {
      if($(this).attr('checked')) {
        previous_visible_types.push($(this).val());
      }
    });
    previous_visible_types = previous_visible_types.join(",");
    $("#visible_message_types :checkbox").change(function() {
      var visible_types = [];
      $("#visible_message_types :checkbox").each(function() {
        $("#message_list").toggleClass('show_' + $(this).val(), !!$(this).attr('checked'));
        if($(this).attr('checked')) {
          visible_types.push($(this).val());
        }
      });
      visible_types = visible_types.join(",");
      if(visible_types != previous_visible_types) {
        $.ajaxJSON($(".update_user_url").attr('href'), 'PUT', {'user[visible_inbox_types]': visible_types}, function(data) {
          previous_visible_types = data.user.visible_types;
        }, function() { });
      }
    }).change();
    $("#mark_inbox_as_read_form").formSubmit({
      beforeSubmit: function(data) {
        $(this).find("button").attr('disabled', true)
          .find(".msg").text(I18n.t('status.marking_all_as_read', "Marking All as Read..."));
      },
      success: function(data) {
        $("#message_list .inbox_item:visible").addClass('read');
        $(this).find("button").attr('disabled', false)
          .find(".msg").text(I18n.t('buttons.mark_all_as_read', "Mark All Messages as Read"));
        $("#identity .unread-messages-count").remove();
        $(this).slideUp();
      },
      error: function(data) {
        $(this).find("button").attr('disabled', false)
          .find(".msg").text(I18n.t('errors.mark_as_read_failed', "Marking failed, please try again"));
      }
    });
    $(".context_message.read").find(".header_icon,.title").attr('title', I18n.t('actions.click_to_expand', 'Click to Expand Message'));
    $(".recipients_dialog .select_all_recipients_link").click(function(event) {
      event.preventDefault();
      var $dialog = $(this).parents(".recipients_dialog");
      $dialog.find(".right_side :checkbox").attr('checked', true);
      $dialog.find(".left_side .select_recipients_link").addClass('selected');
    });
    $(".recipients_dialog .clear_recipients_link").click(function(event) {
      event.preventDefault();
      var $dialog = $(this).parents(".recipients_dialog");
      $dialog.find(".right_side :checkbox").attr('checked', false);
      $dialog.find(".left_side .select_recipients_link").removeClass('selected');
    });
    $(".recipients_dialog .right_side :checkbox").change(function() {
      $(this).parents(".recipients_dialog").triggerHandler('recipients_change');
    });
    $(".recipients_dialog").bind('recipients_change', function() {
      var $dialog = $(this);
      $dialog.find(".left_side .select_recipients_link.selected").each(function() {
        var allChecked = true;
        $(this).find(".group_recipient").each(function() {
          var id = $(this).find(".user_id").text();
          if($dialog.find(".right_side #" + $dialog.attr('id') + "_user_" + id).length > 0) {
            var checked = $dialog.find(".right_side #" + $dialog.attr('id') + "_user_" + id).attr('checked');
            if(!checked) {
              allChecked = false;
            }
          }
        });
        $(this).toggleClass('selected', allChecked);
      });
    });
    $(".recipients_dialog").bind('recipients_group_select', function() {
      var $dialog = $(this);
      $dialog.find(".left_side .select_recipients_link.selected").each(function() {
        $(this).find(".group_recipient").each(function() {
          var id = $(this).find(".user_id").text();
          $dialog.find(".right_side #" + $dialog.attr('id') + "_user_" + id).attr('checked', true);
        });
      });
    });
    $(".recipients_dialog .select_recipients_link").click(function(event) {
      event.preventDefault();
      var $dialog = $(this).parents(".recipients_dialog");
      $(this).toggleClass('selected');
      if(!$(this).hasClass('selected')) {
        $(this).find(".group_recipient").each(function() {
          var id = $(this).find(".user_id").text();
          $dialog.find(".right_side #" + $dialog.attr('id') + "_user_" + id).attr('checked', false);
        });
      }
      $dialog.triggerHandler('recipients_group_select');
    });
    $(".send_message_form").formSubmit({
      fileUpload: function() {
        return $(this).find(".file_input:visible").length > 0;
      },
      object_name: 'context_message',
      required: ['subject', 'body'],
      processData: function(data) {
        var recipients = [];
        $(this).find(".recipients .recipient:visible").each(function() {
          var id = $(this).getTemplateData({textValues: ['id']}).id;
          if(id) {
            recipients.push(id);
          }
        });
        if(recipients.length === 0) {
          $(this).errorBox(I18n.t('errors.no_recipients_selected', "Please select at least one recipient"));
          return false;
        }
        $(this).find(".recipient_ids").val(recipients.join(","));
        data['context_message[recipients]'] = recipients.join(",");
        if(!$(this).attr('action').match(/\.text$/)) {
          $(this).attr('action', $(this).attr('action') + '.text');
        }
        return data;
      },
      beforeSubmit: function() {
        $(this).loadingImage();
        $(this).find(".send_button").attr('disabled', true).text(I18n.t('status.sending_message', "Sending Message..."));
        $(this).find(".cancel_button").attr('disabled', true);
      },
      success: function(data) {
        $(this).find(".send_button").attr('disabled', false).text(I18n.t('buttons.send_message', "Send Message"));
        $(this).find(".cancel_button").attr('disabled', false);
        $(this).loadingImage('remove');
        if($("#messages_view").data('view') == "sentbox") {
          $(this).find(".cancel_button").click();
          var $message = messages.updateMessage(null, data, "top");
          $("#message_list").prepend($message);
        } else {
          $.flashMessage(I18n.t('notices.message_sent', 'Message Sent!'));
          $("#context_message_body").text("");
          var $form = $(this);
          setTimeout(function() {
            $form.slideUp(function() {
              $form.find(".cancel_button").click();
            });
          }, 500);
        }
      },
      error: function(data) {
        $(this).find(".send_button").attr('disabled', false).text(I18n.t('buttons.send_message', "Send Message"));
        $(this).find(".cancel_button").attr('disabled', false);
        $(this).loadingImage('remove');
        $(this).formErrors(data);
      }
    });
    $(".send_message_form .select_recipients").click(function() {
      var $form = $(this).parents(".send_message_form");
      var url = $form.find(".recipients_url").attr('href');
      var $dialog = $("#" + $form.attr('id') + "_dialog");
      if($dialog.hasClass('loaded')) {
        $form.triggerHandler('recipients_loaded');
      } else {
        $dialog.children(".left_side,.right_side").children().hide();
        $dialog.children(".left_side").append("<div class='message'>" + $.h(I18n.t('status.loading_recipients', 'Loading Recipients List...')) + "</div>");
        $.ajaxJSON(url, 'GET', {}, function(data) {
          $dialog.find(".message").remove();
          $dialog.children(".left_side,.right_side").children().show();
          var groups = data.groups;
          var categories = {};
          student_ids = {};
          $dialog.find(".message_groups").showIf(data.groups && data.groups.length > 0);
          for(var idx in data.groups) {
            var group = (groups[idx].group || groups[idx].course_assigned_group);
            categories[group.category] = categories[group.category] || [];
            categories[group.category].push(group);
          }
          $dialog.find(".message_all_teachers_link").parents(".message_group").showIf(data.students && data.students.length);
          for(var idx in data.teachers) {
            var user_id = data.teachers[idx];
            var $user = $dialog.find(".group_recipient.blank:first").clone(true).removeClass('blank');
            $user.find(".user_id").text(user_id);
            $dialog.find(".message_all_teachers_link").append($user);
          }
          $dialog.find(".message_all_students_link").parents(".message_group").showIf(data.students && data.students.length);
          for(var idx in data.students) {
            var user_id = data.students[idx];
            var $user = $dialog.find(".group_recipient.blank:first").clone(true).removeClass('blank');
            student_ids[user_id] = true;
            $user.find(".user_id").text(user_id);
            $dialog.find(".message_all_students_link").append($user);
          }
          $dialog.find(".message_all_observers_link").parents(".message_group").showIf(data.observers && data.observers.length);
          for(var idx in data.observers) {
            var user_id = data.observers[idx];
            var $user = $dialog.find(".group_recipient.blank:first").clone(true).removeClass('blank');
            $user.find(".user_id").text(user_id);
            $dialog.find(".message_all_observers_link").append($user);
          }
          for(var category in categories) {
            var groups = categories[category];
            var $category = $dialog.find(".category.blank").clone(true).removeClass('blank');
            for(var idx in groups) {
              var group = groups[idx];
              var $group = $category.find(".message_group.blank").clone(true).removeClass('blank');
              $group.find(".group_name").text(group.name);
              for(var jdx in data.group_members[group.id]) {
                var user_id = data.group_members[group.id][jdx];
                var $user = $group.find(".group_recipient.blank").clone(true).removeClass('blank');
                $user.find(".user_id").text(user_id);
                $group.find(".message_group_link").append($user);
              }
              $category.append($group.show());
            }
            $dialog.find(".left_side .message_groups").show()
              .append($category.show());
          }
          for(var idx in data.users) {
            var user = data.users[idx].user;
            var $user = $dialog.find(".right_side .recipient.blank").clone(true).removeClass('blank');
            if(student_ids[user.id]){
              $user.find(":checkbox").addClass('student');
            }
            $user.find(":checkbox").attr('id', $dialog.attr('id') + "_user_" + user.id).val(user.id);
            $user.find(".user_name").attr('for', $dialog.attr('id') + "_user_" + user.id)
              .text(user.name || user.short_name || user.id);
            $dialog.find(".right_side .recipients").append($user.show());
          }
          var users = data.users;
          $dialog.addClass('loaded');
          $dialog.find(".left_side.not_course").hide();
          $form.triggerHandler('recipients_loaded');
        });
      }
      $dialog.dialog('close').dialog({
        autoOpen: false,
        width: 600,
        open: function() {
          $(this).find(".clear_recipients_link").click();
        }
      }).dialog('open');
    });
    $(".recipients_dialog .select_button").click(function() {
      var $form = $("#" + $(this).parents(".recipients_dialog").attr('id').substring().replace("_dialog", ""));
      var recipients = [];
      $(this).parents(".recipients_dialog").find(".right_side :checkbox:checked").each(function() {
        var id = $(this).attr('id').split('_').pop();
        var name = $(this).next("label").text();
        var is_student = $(this).hasClass('student');
        recipients.push({id: id, user_name: name, is_student: is_student});
      });
      messages.addRecipientsToForm($form, recipients);
      $(this).parents(".recipients_dialog").dialog('close');
    });
    $(".send_message_form .recipient .delete_recipient_link").click(function(event) {
      event.preventDefault();
      $form = $(this).parents('form');
      $(this).parents(".recipient").remove();
      messages.updateFacultyJournalOption($form);
    });
    $(".recipients_dialog .cancel_button").click(function() {
      $(this).parents(".recipients_dialog").dialog('close');
    });
    $(".context_message .mark_as_read_link").click(function(event) {
      event.preventDefault();
      var $message = $(this).parents(".context_message");
      $message.loadingImage();
      $.ajaxJSON($(this).attr('href'), 'PUT', {}, function(data) {
        $message.loadingImage('remove');
        $message.find(".content:visible").css('display', 'block');
        $message.addClass('read');
        $message.find(".content").slideUp();
      }, function(data) {
        $message.loadingImage('remove');
      });
    });
    $(".context_message").find(".show_message_body_link,.header_title").click(function(event) {
      if($(event.target).closest(".sub_title").length == 0) {
        event.preventDefault();
      }
      var $message = $(this).parents(".context_message");
      if($(event.target).closest("a:not(.show_message_body_link)").length === 0) {
        $message.find(".show_message_body").remove();
        $message.toggleClass('read_open'); //find(".content").toggle();
      }
    });
    $(".context_message .content").click(function(event) {
      if($(this).parents(".context_message.read:not(.read_open)").length > 0 && $(event.target).closest("a").length === 0) {
        $(this).parents(".context_message").find(".header_title").click();
      }
    });
    $(".context_message.read:visible").each(function() {
      if($(this).find(".content").height() + 10 > $(this).find(".content .inner_content").height()) {
        $(this).find(".header_title").click();
      }
    });
    $("#current_message_context").change(function() {
      var $prevForm = $(".send_message_form:visible");
      var $form = $("#" + $(this).val() + "_recipients");
      if ($prevForm.length) {
        $prevForm.hide();
        messages.moveFormData($prevForm, $form);
      }
      $form.show();
    }).change();
    $(".send_message_form .cancel_button").click(function() {
      $("#send_message").hide();
    });
    $(".new_message_link").click(function(event) {
      event.preventDefault();
      $("#send_message .context_message").remove();
      messages.resetFormData($("#send_message .send_message_form"));
      $("#current_message_context").change();
      $("#send_message").show()
      $("html,body").scrollTo($("#send_message"));
    });
    $(document).fragmentChange(function(event, fragment) {
      if(fragment == "#new_students_message") {
        $(".message_link").click();
      } else if(fragment.match(/^#reply/)) {
        var params = null;
        try {
          params = JSON.parse(decodeURIComponent(fragment.substring(6)));
        } catch(e) { }
        if(params) {
          $(document).triggerHandler('message_recipients', params);
        }
      }
    });
    $(document).bind('message_recipients', function(event, data) {
      if(!data || !data.context_code) { return; }
      if(data.reply_id && $("#context_message_" + data.reply_id)) {
        $("#context_message_" + data.reply_id + " .reply_link").click();
        return;
      }
      var ids = (data.recipients || "").split(",");
      var recipients = [];
      $(".new_message_link").click();
      $("#current_message_context").val(data.context_code).change();
      var $form = $(".send_message_form:visible:first");
      $form.find(".root_context_message_id").val(data.reply_id || data.root_id || "");
      $form.find("textarea:first").val(data.body || "");
      if(data.subject){
        $form.find(".subject").val(data.subject.replace(/\+/g, " ") || "");
      }
      if($("#current_message_context").val() != data.context_code) {
        $form.find(".cancel_button").click();
        alert(I18n.t('errors.course_or_group_unavailable', "You don't have permissions to create messages for that course or group"));
        return;
      }
      for(var idx in ids) {
        var recipient = ids[idx];
        var name = messages.findUserName(recipient);
        recipients.push({id: recipient, user_name: name, is_student: true});
      }
      messages.addRecipientsToForm($form, recipients, data.context_code);
    });
    $(".context_message").find(".reply_link,.reply_to_all_link").click(function(event) {
      event.preventDefault();
      var $message = $(this).parents(".context_message");
      var context_code = $message.getTemplateData({textValues: ['context_code']}).context_code;
      $(".new_message_link:first").click();
      $("#current_message_context").val(context_code).change();
      var $form = $(".send_message_form:visible:first");
      messages.resetFormData($form);
      if($("#current_message_context").val() != context_code) {
        $form.find(".cancel_button").click();
        alert(I18n.t('errors.course_or_group_unavailable', "You don't have permissions to create messages for that course or group"));
        return;
      }
      var recipients = [];
      if($("#messages_view").data('view') == "sentbox") {
        $message.find(".recipients_list .recipient").each(function() {  
          var data = $(this).getTemplateData({textValues: ['id', 'user_name']});
          recipients.push(data);
        });
      } else {
        var name = $message.find(".sub_title .sender_name").text();
        var id = $message.find(".sub_title .sender_name").attr('href').split('/').pop();
        var is_student = $message.hasClass('student');
        recipients.push({id: id, user_name: name, is_student: is_student});
      }
      messages.addRecipientsToForm($form, recipients, context_code);
      var subject = messages.replySubject($message.getTemplateData({textValues: ['subject']}).subject);
      var root_id = $message.getTemplateData({textValues: ['root_context_message_id']}).root_context_message_id;
      $form.fillFormData({subject: subject, root_context_message_id: root_id}, {object_name: 'context_message'});
      $message = $message.clone(true).removeClass('read');
      $message.find(".link_box,.sub_title,.show_recipients_link").remove();
      $message.find(".subject").text(I18n.t('original_message_subject', "Original Message")); //$message.find(".subject")
      $form.find("textarea:first").next().after($message);
    });
    var attachmentIndex = 0;
    $(".send_message_form .add_attachment_link").click(function(event) {
      event.preventDefault();
      var $attachment = $(this).parents("td").find(".context_message_attachment.blank").clone(true);
      attachmentIndex++;
      $attachment.find(".file_input").attr('name', 'context_message[attachments][' + attachmentIndex + ']');
      $attachment.removeClass('blank');
      $(this).parents("td").append($attachment);
      $attachment.slideDown();
    });
    $(".send_message_form .remove_attachment_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".context_message_attachment").slideUp(function() {
        $(this).remove();
      });
    });
    $(".context_message").find(".show_recipients_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".context_message").find(".recipients_list_holder").slideToggle();
    });
  });
  window.messages = {
    replySubject: function(subject) {
      var pattern = new RegExp($.regexEscape(I18n.t('#subject_reply_to', "Re: %{subject}", {subject: '.*'})).replace(/\\\.\\\*/, '.*'), 'gmi');
      return subject.match(pattern) ? subject : I18n.t('#subject_reply_to', "Re: %{subject}", {subject: subject});
    },
    findUserName: function(id, users) {
      var name = $.trim($(".user_name_" + id + ":first").text());
      if(!name) {
        for(var idx in users) {
          var user = users[idx].user;
          if(user.id == id) {
            name = user.name;
          }
        }
      }
      return name;
    },
    addRecipientsToForm: function($form, recipients, context_code) {
      var success = false;
      for(var idx in recipients) {
        var recipient = recipients[idx];
        if(recipient.id && recipient.user_name) {
          if(!context_code || $("#possible_recipients .user_name_" + recipient.id + ".for_" + context_code).length > 0) {
            success = true;
            var $recipient = $form.find(".recipients .recipient.blank").clone(true).removeClass('blank');
            $recipient.find(".user_name").text(recipient.user_name);
            $recipient.find(".id").text(recipient.id);
            $recipient.addClass('user_' + recipient.id);
            if(recipient["is_student"]){
              $recipient.addClass('student');
            }
            if($form.find(".recipients .user_" + recipient.id).length === 0) {
              $form.find(".recipients .recipients_scroll").append($recipient.show());
            }
            $form.find(".recipients .no_recipients").remove();
          }
        }
      } 
      if (!success) {
        $("#context_message_recipient_not_available_dialog").dialog({
          modal: true,
          width: 466,
          title: $('<span class="ui-icon ui-icon-alert" style="float: left; margin-right: 0.3em; "></span> <span>' + $.h(I18n.beforeLabel('alert', 'Alert')) + '</span>'),
          buttons: {
            Ok: function() {
              $(this).dialog("close");
            }
          }
        });
      }
      messages.updateFacultyJournalOption($form);
    },
    updateFacultyJournalOption: function($form){
      $add_as_user_note = $form.find('.add_as_user_note');
      if($add_as_user_note){
        // the '2' accounts for the template 'blank' recipient
        if($form.find(".recipients .recipient").size() == 2 && $form.find(".recipients .recipient.student").size() == 1){
          $add_as_user_note.attr('disabled', false);
        }else{
          $add_as_user_note.attr('disabled', true);
          $add_as_user_note.attr('checked', false);
        }
      }
    },
    updateInboxItem: function($message, data, add_position) {
      var message = data.inbox_item;
      message.created_at = $.parseFromISO(message.created_at).datetime_formatted;
      if(!$message || $message.length === 0) {
        $message = $("#inbox_item_blank:first").clone(true).removeAttr('id');
      }
      for(var idx in message.recipients) {
        var id = message.recipients[idx];
        var name = messages.findUserName(id, message.users);
        var $user = $message.find(".recipient_blank").clone(true);
        $user.removeClass('recipient_blank').fillTemplateData({
          data: {id: id, recipient_id: id, name: name},
          hrefValues: ['recipient_id']
        });
        $message.find(".recipients_list").append($user.show());
      }
      message.recipient_id = message.user_id;
      message.recipient_name = messages.findUserName(message.user_id);
      $message.addClass($.underscore(message.asset_type));
      $message.find(".reply_inbox_item_link").showIf(message.asset_type == 'ContextMessage');
      message.sender_name = message.sender_name || messages.findUserName(message.sender_id);
      var code = message.context_code.split("_");
      message.context_id = code.pop();
      message.context_type_pluralized = $.pluralize(code.join("_"));
      message.context_name = $(".context_name_for_" + message.context_code).text();
      $message.fillTemplateData({
        data: message,
        id: 'inbox_item_' + message.id,
        hrefValues: ['id', 'user_id', 'sender_id', 'context_id', 'context_type_pluralized']
      });
      $("#message_list .no_messages").remove();
      if($message.parents("#message_list").length === 0) {
        $message.css('display', '');
        if(add_position && add_position == 'top') {
          $("#message_list").prepend($message);
          $("html,body").scrollTo($("#messages_view"));
        } else {
          var already_read = message.workflow_state == 'read';
          $message.toggleClass('read', already_read);
          if($("#message_list #pageless-loader").length > 0) {
            $("#message_list #pageless-loader").before($message);
          } else {
            $("#message_list").append($message);
          }
        }
      }
      return $message;
    },
    updateMessage: function($message, data, add_position) {
      var message = data.context_message;
      message.created_at = $.parseFromISO(message.created_at).datetime_formatted;
      if(!$message || $message.length === 0) {
        $message = $(".context_message_blank.for_" + $.underscore(message.context_type) + "_" + message.context_id + ":first").clone(true);      
      }
      $message.removeClass('context_message_blank');
      if(message.is_student){
          $message.addClass('student');
        }
      if(message.protect_recipients && !message.recipients) {
        var $user = $message.find(".recipient_blank").clone(true);
        $user.removeClass('recipient_blank').text("Recipient list is protected");
        $message.find(".recipients_list").append($user.show());
        $message.find(".single_recipient_link").showIf(true).end()
          .find(".multiple_recipient_link").showIf(false);
        message.recipient_id = $("#identity .user_id").text()
        message.recipient_name = messages.findUserName(message.recipient_id, []);
        message.users_count = 1;
      } else {
        for(var idx in message.recipients) {
          var id = message.recipients[idx];
          var name = messages.findUserName(id, message.users);
          var $user = $message.find(".recipient_blank").clone(true);
          $user.removeClass('recipient_blank').fillTemplateData({
            data: {id: id, recipient_id: id, name: name},
            hrefValues: ['recipient_id']
          });
          $message.find(".recipients_list").append($user.show());
        }
        $message.find(".single_recipient_link").showIf(message.recipients.length == 1).end()
          .find(".multiple_recipient_link").showIf(message.recipients.length != 1);
        message.recipient_id = message.recipients[0];
        message.recipient_name = messages.findUserName(message.recipients[0], message.users);
        message.users_count = message.recipients.length;
      }
      $message.addClass('context_message_' + message.id);
      message.sender_name = messages.findUserName(message.user_id, message.users);
      $message.fillTemplateData({
        data: message,
        id: 'context_message_' + message.id,
        hrefValues: ['user_id', 'recipient_id', 'id'],
        htmlValues: ['formatted_body']
      });
      for(var idx in message.attachments) {
        var attachment = message.attachments[idx].attachment;
        attachment.attachment_id = attachment.id;
        var $attachment = $message.find(".attachment_blank").clone(true).removeClass('attachment_blank');
        $attachment.fillTemplateData({
          data: attachment,
          hrefValues: ['attachment_id']
        });
        $message.find(".attachments_list").show().append($attachment.show());
      }
      $("#message_list .no_messages").remove();
      if($message.parents("#message_list").length === 0) {
        $message.show()
        if(add_position && add_position == 'top') {
          $("#message_list").prepend($message);
          $("html,body").scrollTo($("#messages_view"));
        } else {
          var current_user_id = parseInt($("#identity .user_id").text(), 10);
          var already_read = $.inArray(current_user_id, message.viewed_user_ids || []) != -1;
          $message.toggleClass('read', already_read);
          $("#message_list").append($message);
        }
      }
      return $message;
    },
    // move data from one context message form to another (e.g. when you change the dropdown option).
    // recipient fu makes sure invalid recipients for the context get omitted.
    moveFormData: function($source, $target) {
      var target_context = $target[0].id.replace(/_recipients$/, ''),
          recipients = [],
          $attachment_td = $target.find(".context_message_attachment:.blank").parents("td");
  
      messages.resetFormData($target);
  
      $source.find(".recipients .recipient:not(.blank)").each(function() {
        var data = $(this).getTemplateData({textValues: ['id', 'user_name']});
        // note: when switching contexts, recipients will be blanked out completely if the target
        // recipient list has not been loaded yet.
        $valid_recipient = $("#" + target_context + "_recipients_dialog_user_" + data.id + ":checkbox");
        if ($valid_recipient.length > 0) {
          data['is_student'] = $valid_recipient.is('.student');
          recipients.push(data);
        }
      });
      if (recipients.length > 0) {
        messages.addRecipientsToForm($target, recipients, target_context);
      }
      $source.find(".context_message_attachment:not(.blank)").each(function() {
        // cloning file inputs is problematic (browser security), so we move it instead
        $attachment_td.append($(this).remove());
      });
      $target.find(".also_announcement").attr('checked', $source.find(".also_announcement").attr('checked'));
      $target.find(".subject").val($source.find(".subject").val());
      $target.find("textarea").val($source.find("textarea").val());
      $target.find('.add_as_user_note').attr('checked', $source.find(".add_as_user_note").attr('checked'));
      messages.updateFacultyJournalOption($target);
  
      messages.resetFormData($source);
    },
    resetFormData: function($form) {
      $form.find(".recipients .recipient:not(.blank)").remove();
      $form.find(".no_recipients").remove();
      $form.find(".recipients .recipients_scroll").append("<div class='no_recipients'>" + $.h(I18n.t('no_recipients', "No Recipients")) + "</div>");
      $form.find(".context_message_attachment:not(.blank)").remove();
      $form.find(".also_announcement").attr('checked', false);
      $form.find(".root_context_message_id").val("");
      $form.find(":text,textarea").val("");
      messages.updateFacultyJournalOption($form);
    }
  };
});
