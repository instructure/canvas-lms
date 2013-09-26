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
  'i18n!context.inbox',
  'jquery' /* $ */,
  'str/pluralize',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* datetimeString */,
  'jquery.instructure_forms' /* formSubmit */,
  'jquery.instructure_misc_helpers' /* /\$\.underscore/ */,
  'jquery.templateData' /* fillTemplateData */,
  'vendor/jquery.pageless' /* pageless */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(I18n, $, pluralize) {

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
  });
  window.messages = {
    updateInboxItem: function($message, data, add_position) {
      var message = data.inbox_item;
      message.created_at = $.datetimeString(message.created_at);
      if(!$message || $message.length === 0) {
        $message = $("#inbox_item_blank:first").clone(true).removeAttr('id');
      }
      $message.addClass($.underscore(message.asset_type));
      message.sender_name = message.sender_name;
      var code = message.context_code.split("_");
      message.context_id = code.pop();
      message.context_type_pluralized = pluralize(code.join("_"));
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
    }
  };
});
