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

require([
  'i18n!topics',
  'jquery' /* $ */,
  'wikiSidebar',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* parseFromISO */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, clickLink, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'tinymce.editor_box' /* editorBox */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(I18n, $, wikiSidebar) {

  function editEntry($entry, params) {
    $("#add_entry_bottom").hide();
    var $form = $("#add_entry_form").clone(true);
    if($entry.attr('id') == 'entry_id') { $entry.attr('id', 'entry_new'); }
    var id = $entry.attr('id');
    $form.addClass('add_entry_form_new').attr('id', 'add_entry_form_' + id)
      .find(".entry_content").addClass('entry_content_new').attr('id', 'entry_content_' + id);
    var data = $entry.getTemplateData({
      textValues: ['title', 'parent_id', 'attachment_name'],
      htmlValues: ['message']
    });
    data.message = $entry.find(".content > .message_html").val();
    if(params && params.message) {
      data.message = params.message;
    }
    var addOrUpdateEntry = I18n.t('update_entry', "Update Entry");
    $form.attr('method', 'PUT')
      .attr('action', $entry.find(".edit_entry_url").attr('href'));
    $form.find(".entry_remove_attachment").val("0");
    $form.find(".add_attachment").show().end()
      .find(".no_attachment").showIf(!data.attachment_name).end()
      .find(".current_attachment").showIf(data.attachment_name).end()
      .find(".upload_attachment").hide().end()
      .find(".attachment_name").text(data.attachment_name);
    if($entry.attr('id') == "entry_new") {
      addOrUpdateEntry = I18n.t('add_new_entry', "Add New Entry");

      $entry.find(".user_name")
        .text(CURRENT_USER_NAME_FOR_TOPICS)
        .attr('href', function(i, href){
          return $.replaceTags(href, 'user_id', $('#identity .user_id').text());
        });

      $form.attr('method', 'POST')
        .attr('action', $("#topic_urls .add_entry_url").attr('href'));
    }
    $form.fillFormData(data, {object_name: "discussion_entry"});
    $entry.children(".content").show()
        .children(".subcontent").hide().end()
        .find(".message").hide().end()
      .append($form.show()).end()
      .children(".header")
        .find(".post_date").hide().end()
        .find(".link_box").hide().end()
        .find(".title").hide().end()
        .prepend("<div class='add_message title' style='float: left; padding-right: 20px;'>" + addOrUpdateEntry + "<\/div>")
      .show();
    $form.find(".entry_content_new").editorBox()
        .editorBox('set_code', data.message);
    if(wikiSidebar) {
      wikiSidebar.attachToEditor($form.find(".entry_content_new"));
      $("#sidebar_content").hide();
      wikiSidebar.show();
    }
    $form.find("button[type='submit']").val(addOrUpdateEntry);
    setTimeout(function() { doFocus('entry_content_' + id); }, 500);
    selectEntry($entry);
    $("html,body").scrollTo($form);
  }
  function cancelEditEntry(id) {
    $("#" + id).find(".cancel_button").click();
  }
  function doFocus(id) {
    if(!$("#" + id).editorBox('focus')) {
      setTimeout(function() { doFocus(id); }, 500);
      return;
    }
  }
  function removeEntryForm() {
    var $form = $(".add_entry_form_new");
    var $entry = $form.parents(".discussion_entry");
    $form.find(".entry_content_new").editorBox('destroy');
    $form.hide();
    if(wikiSidebar) {
      $("#sidebar_content").show();
      wikiSidebar.hide();
    }
    $entry.children(".header").show()
        .find(".post_date").show().end()
        .find(".add_message").remove().end()
        .find(".title").show().end()
        .find(".link_box").show().end().end()
      .children(".content").show()
        .children(".subcontent").show().end()
        .find(".message").show().end();
    $form.appendTo($("body"));
  }
  function removeEntry($entry) {
    prevEntry();
    var $subtopic = $entry.parents(".discussion_subtopic:first");
    $entry.next().remove();
    $entry.remove();
    updateTopicList($subtopic);
  }

  function nextEntry() {
    var $selected = $(".discussion_topic.selected,.discussion_entry.selected,.communication_sub_message.selected");
    if($selected.length === 0) {
      $selected = $(".discussion_topic:first").addClass('selected');
    } else {
      var $entries = $(".discussion_topic,.discussion_entry,.communication_sub_message");
      var idx = $(".discussion_topic,.discussion_entry,.communication_sub_message").index($selected.get(0));
      var $next = null;
      for(var i = idx + 1; i < $entries.length; i++) {
        var $entry = $($entries.get(i));
        if($entry.css('display') != 'none') {
          $next = $entry;
          break;
        }
      }
      if($next) { $selected = $next; }
    }
    selectEntry($selected, true);
  }
  function prevEntry() {
    var $selected = $(".discussion_topic.selected,.discussion_entry.selected,.communication_sub_message.selected");
    if($selected.length === 0) {
      $selected = $(".discussion_topic:first").addClass('selected');
    } else {
      var $entries = $(".discussion_topic,.discussion_entry,.communication_sub_message");
      var idx = $(".discussion_topic,.discussion_entry,.communication_sub_message").index($selected.get(0));
      var $prev = null;
      for(var i = idx - 1; i >= 0; i--) {
        var $entry = $($entries.get(i));
        if($entry.css('display') != 'none') {
          $prev = $entry;
          break;
        }
      }
      if($prev) { $selected = $prev; }
    }
    selectEntry($selected, true);
  }
  function clearEntrySelection() {
    var $selected = $(".discussion_topic.selected,.discussion_entry.selected,.communication_sub_message.selected");
    $selected.removeClass('selected');
  }
  function selectEntry($entry, scroll) {
    var $selected = $(".discussion_topic.selected,.discussion_entry.selected,.communication_sub_message.selected");
    clearEntrySelection();
    if($entry.length === 0) {
      $entry = $(".discussion_topic:first").addClass('selected');
    } else {
      $entry.addClass('selected');
    }
    if(scroll) {
      $("html,body").scrollTo($entry);
      $entry.mouseover();
      $entry.find(":tabbable:visible:first").focus();
    }
  }
  function updateTopicList($list) {
    var $children = $("#entry_list").children(".discussion_entry");
    $children.removeClass('discussion_start').removeClass('discussion_end');
    if($children.length === 0) {
      $(".discussion_topic").addClass('discussion_end');
    } else {
      $(".discussion_topic").removeClass('discussion_end');
    }
    $children.filter(":last").addClass('discussion_end');
    $(".message_count").text(messageCount);
    $(".message_count_text").text(messageCount == 1 ? "post" : "posts");
    $(".total_message_count").text(totalMessageCount);
    if($list) {
      $children = $list.children(".discussion_entry");
      $children.removeClass('discussion_start').removeClass('discussion_end');
      $children.filter(":first").addClass('discussion_start');
      $children.filter(":last").addClass('discussion_end');
      var $entry = $list.prev(".discussion_entry");
      if($entry.hasClass('has_loaded')) {
        $entry.fillTemplateData({data: {replies: I18n.t('number_of_replies',
          {zero: "No Replies", one: "1 Reply", other: "%{count} Replies"},
          {count: $list.children(".discussion_entry").length})}});
      }
    }
  }

  $(document).ready(function() {
    setTimeout(function() {
      $(".communication_sub_message.blank").each(function() {
        $(this).find(".user_name").text('');
      });
    }, 500);
    var permissionsList = [];
    $.ajaxJSON($(".discussion_entry_permissions_url").attr('href'), 'GET', {}, function(data) {
      for(var idx in data) {
        var entry = data[idx].discussion_entry;
        permissionsList.push({
          id: "entry_" + entry.id,
          permissions: entry.permissions || {}
        });
      }
      setTimeout(nextPermission, 500);
    }, function() { });
    var nextPermission = function() {
      for(var idx = 0; idx < 10; idx++) {
        var obj = permissionsList.shift();
        if(obj) {
          var permissions = obj.permissions;
          var id = obj.id;
          if(permissions.update || permissions['delete'] || permissions.reply) {
            var $entry = $("#" + id);
            if(permissions.update) {
              $entry.find(".header .edit_entry_link").removeClass('disabled_link');
            }
            if(permissions['delete']) {
              $entry.find(".header .delete_entry_link").removeClass('disabled_link');
            }
            if(permissions.reply) {
              $entry.find(".add_entry_link").removeClass('disabled_link');
              $entry.find(".reply_message").show();
            }
          }
        }
      }
      if(permissionsList.length > 0) { 
        setTimeout(nextPermission, 500);
      }
    };

    $(".show_rubric_link").click(function(event) {
      event.preventDefault();
      var url = $(this).attr('rel');
      var $dialog = $("#rubrics.rubric_dialog");
      if($dialog.length) {
        ready();
      } else {
        var $loading = $("<div/>");
        $loading.text(I18n.t('loading', "Loading..."));
        $("body").append($loading);
        $loading.dialog({
          width: 400,
          height: 200
        });
        $.get(url, function(html) {
          $("body").append(html);
          $loading.dialog('close');
          $loading.remove();
          ready();
        });
      }
      function ready() {
        $dialog = $("#rubrics.rubric_dialog");
        $dialog.dialog('close').dialog({
          title: I18n.t('titles.assignment_rubric_details', "Assignment Rubric Details"),
          width: 600,
          modal: false,
          resizable: true,
          autoOpen: false
        }).dialog('open');
      }
    });
    $(".add_topic_rubric_link").click(function(event) {
      event.preventDefault();
      var $dialog = $("#rubrics.rubric_dialog");
      $dialog.dialog('close').dialog({
        title: I18n.t('titles.assignment_rubric_details', "Assignment Rubric Details"),
        width: 600,
        modal: false,
        resizable: true,
        autoOpen: false
      }).dialog('open');
      $(".add_rubric_link").click();
    });
    $("#add_entry_form .add_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".no_attachment").slideUp().addClass('current');
      $form.find(".current_attachment").hide().removeClass('current');
      $form.find(".upload_attachment").slideDown();
    });
    $("#add_entry_form .delete_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".current_attachment").slideUp().removeClass('current');
      $form.find(".no_attachment").slideDown().addClass('current');
      $form.find(".upload_attachment").hide();
      $form.find(".entry_remove_attachment").val("1");
    });
    $("#add_entry_form .replace_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".upload_attachment").slideDown();
      $form.find(".no_attachment").hide().removeClass('current');
      $form.find(".current_attachment").slideUp().addClass('current');
    });
    $("#add_entry_form .cancel_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".no_attachment.current").slideDown();
      $form.find(".upload_attachment").slideUp();
      $form.find(".current_attachment.current").slideDown();
      $form.find(".attachment_uploaded_data").val("");
      $form.find(".entry_remove_attachment").val("0");
    });
    $("#add_entry_form").formSubmit({
      fileUpload: function(data) {
        var doUpload = data['attachment[uploaded_data]'];
        if(doUpload) { $(this).attr('action', $(this).attr('action') + '.text'); }
        return doUpload;
      },
      object_name: 'discussion_entry',
      processData: function() {
        var data = $(this).getFormData({object_name: 'discussion_entry'});
        data.message = $(this).find(".entry_content_new").editorBox('get_code');
        data['discussion_entry[message]'] = data.message;
        return data;
      },
      beforeSubmit: function(data) {
        var $entry = $(this).parents(".discussion_entry");
        var addingMessage = I18n.t('updating', "Updating...");
        if($entry.attr('id') == "entry_new") {
          addingMessage = I18n.t('adding', "Adding...");
          $entry.attr('id', 'entry_id');
        }
        $entry.next().attr('id', 'replies_entry_id');
        data.post_date = addingMessage;
        $entry.fillTemplateData({
          data: data, 
          except: ['message'],
          avoid: '.subcontent'
        });
        removeEntryForm();
        var $subtopic = $entry.parents(".discussion_subtopic");
        updateTopicList($subtopic);
        $entry.find(".content").loadingImage();
        return $entry;
      }, success: function(data, $entry) {
        var entry = data.discussion_entry;
        entry.user_name = entry.user_name ? entry.user_name : I18n.t('default_user_name', "User Name");
        delete entry['user'];
        var date_data = $.parseFromISO(entry.created_at, 'event');
        entry.post_date = date_data.datetime_formatted;
        if($entry.attr('id') == 'entry_id') {
          totalMessageCount++;
          if($entry.parents(".discussion_subtopic").length === 0) {
            messageCount++;
          }
          updateTopicList();
        }
        if(entry.attachment) {
          entry.attachment_name = entry.attachment.display_name;
          var url = $.replaceTags($entry.find(".entry_attachment_url").attr('href'), 'attachment_id', entry.attachment.id);
          $entry.find(".attachment_name").attr('href', url);
        }
        $entry.find(".attachment_data").showIf(entry.attachment);
        $entry.find("input.parent_id").val(entry.id);
        $entry.find("span.parent_id").text(entry.id);
        $entry.find(".content > .message_html").val(entry.message);
        $entry.fillTemplateData({
          id: 'entry_' + entry.id,
          data: entry,
          htmlValues: ['message'],
          hrefValues: ['id', 'user_id', 'discussion_topic_id'],
          avoid: '.subcontent'
        });
        $entry.find(".add_entry_link").toggleClass("disabled_link", !entry.permissions.reply).end()
          .find(".edit_entry_link").toggleClass("disabled_link", !entry.permissions.update).end()
          .find(".delete_entry_link").toggleClass("disabled_link", !entry.permissions['delete']);
        $entry.find(".content").loadingImage('remove');
        $entry.find(".user_content").removeClass('enhanced');
        if($("#initial_post_required").length) {
          location.reload();
        }
        $(document).triggerHandler('user_content_change');
      }, error: function(data, $entry) {
        $entry.find(".content").loadingImage('remove');
        editEntry($entry);
        if($entry.attr('id') == "entry_id") {
          $entry.attr('id', 'entry_new');
        }
        return $entry.find("form");
      }
    });
    $("#add_entry_form .cancel_button").click(function(event) {
      var $entry = $(this).parents(".discussion_entry");
      $("#add_entry_bottom").show();
      removeEntryForm();
      if($entry.attr('id') == 'entry_new') {
        removeEntry($entry);
      }
    });
    $(".add_entry_link").live('click', function(event, params) {
      event.preventDefault();
      event.stopPropagation();
      if($("#entry_new").length > 0) {
        return;
      }
      var $entryList = $("#entry_list");
      var data = { parent_id: 0 };
      if($(this).parents(".discussion_subtopic").length > 0) {
        $entryList = $(this).parents(".discussion_subtopic");
        data.parent_id = $entryList.prev().getTemplateData({ textValues: ['id'] }).id;
      } else if($(this).parents(".discussion_entry").length > 0) {
        $entryList = $(this).parents(".discussion_entry").next();
        data.parent_id = $entryList.prev().getTemplateData({ textValues: ['id'] }).id;
      }
      var $parent_entry = $entryList.prev(".discussion_entry");
      if($parent_entry.length > 0 && $parent_entry.find(".replies_link").text() != I18n.t('no_replies', "No Replies") && !$parent_entry.hasClass('has_loaded')) {
        return;
      }
      var $entry = $("#entry_blank").clone(true);
      var $entryReplies = $("#replies_entry_blank").clone(true);
      $entry.fillTemplateData({ data: data });
      $entryList.append($entry.show());
      $entryList.append($entryReplies);
      updateTopicList($entry.parents(".discussion_subtopic:first"));
      $entry.attr('id', 'entry_new');
      editEntry($entry, params);
    });
    $(".switch_entry_views_link").live('click', function(event) {
      event.preventDefault();
      $(this).parents("form").find("textarea").editorBox('toggle');
    });
    $(".edit_entry_link").live('click', function(event) {
      event.preventDefault();
      if($(this).parents(".discussion_entry").length > 0) {
        var $entry = $(this).parents(".discussion_entry");
        editEntry($entry);
      } else {
        $(".discussion_topic:first .edit_topic_link").click();
      }
    });
    $(".delete_entry_link").live('click', function(event) {
      event.preventDefault();
      var data = $("#add_entry_form").getFormData({ values: ['authenticity_token'] });
      $(this).closest(".discussion_entry,.communication_sub_message").confirmDelete({
        token: data.authenticity_token,
        url: $(this).attr('href'),
        message: I18n.t('confirms.delete_entry', "Are you sure you want to delete this entry?"),
        success: function() {
          $(this).fadeOut('normal', function() {
            var $subtopic = $(this).parents(".discussion_subtopic:first");
            $(this).remove();
            updateTopicList($subtopic);
          });
          totalMessageCount--;
          if($(this).parents(".discussion_subtopic").length === 0) {
            messageCount--;
          }
          updateTopicList();
        }
      });
    });
    $("#entry_list").delegate('.replies_link', 'click', function(event) {
      event.preventDefault();
    });
    $(".toggle_subtopics_link").live('click', function(event) {
      event.preventDefault();
      if($(this).text().indexOf(I18n.t('expand', "Expand")) != -1) {
        $(".toggle_subtopics_link").toggle();
      } else {
        $(".toggle_subtopics_link").toggle();
      }
    });
    $(document).click(function(event) {
      if($(event.target).parents(".discussion_entry,.discussion_topic").length === 0) {
        clearEntrySelection();
      } else {
        selectEntry($(event.target).closest(".communication_sub_message,.discussion_entry,.discussion_topic").filter(":first"));
      }
    });
    $.scrollSidebar();
    $("#add_entry_form :input").keydown(function(event, keyCode) {
      if(event.keyCode == 27 || keyCode == 27) {
        event.preventDefault();
        var id = $(this).parents("form").attr('id');
        setTimeout("cancelEditEntry('" + id + "')", 100);
      }
    });
    $(document).fragmentChange(function(event, fragment) {
      if(fragment.match(/^#reply/)) {
        var params = null;
        try {
          params = $.parseJSON(fragment.substring(6));
        } catch(e) { }
        $("#sidebar .add_entry_link:visible:first").triggerHandler('click', params);
      }
    });
    $(document).keycodes('j k d e r n', function(event) {
      event.preventDefault();
      event.stopPropagation();
      var $selected = $(".discussion_entry,.discussion_topic,.communication_sub_message").filter(".selected:first");
      if(event.keyCode == 74) { // j for next
        nextEntry();
      } else if(event.keyCode == 75) { // k for prev
        prevEntry();
      } else if(event.keyCode == 68) { // d for delete
        $selected.find(".delete_topic_link,.delete_entry_link").clickLink();
      } else if(event.keyCode == 69) { // e for edit
        $selected.find(".edit_topic_link,.edit_entry_link").clickLink();
      } else if(event.keyCode == 82) { // r for reply
        if($selected.find(".add_entry_link").length) {
          $selected.find(".add_entry_link").clickLink();
        } else {
          $selected.closest(".communication_message").find(".add_entry_link").clickLink();
        }
        var $form = $(".add_sub_message_form,.new_discussion_entry").filter(":visible:first");
        if($form.length) {
          $("html,body").scrollTo($form);
        }
      } else if(event.keyCode == 78) { // n for new entry
        $(document).find(".add_entry_link:first").clickLink();
      }
    });
  });
});
