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
  'INST' /* INST */,
  'i18n!topics',
  'jquery' /* $ */,
  'wikiSidebar',
  'ajax_errors' /* INST.log_error */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* parseFromISO, time_field, datetime_field */,
  'jquery.instructure_forms' /* formSubmit, fillFormData, getFormData, formErrors, errorBox, hideErrors, formSuggestion */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'tinymce.editor_box' /* editorBox */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/sortable' /* /\.sortable/ */
], function(INST, I18n, $, wikiSidebar) {

  // TODO AMD: get this stuff out of the global ns and the views
  var attachAddAssignment = window.attachAddAssignment;
  var topics = window.topics = {};

  topics.updateTopic = updateTopic;
  function updateTopic($topic, data) {
    if(!$topic) {
      $topic = $("#topic_blank").clone(true);
      if(true || canDeleteTopics) {
        $topic.find(".delete_topic_link").show();
      } else {
        $topic.find(".delete_topic_link").hide();
      }
      if(true || canEditTopics) {
        $topic.find(".edit_topic_link").show();
      } else {
        $topic.find(".edit_topic_link").hide();
      }
      $topic.appendTo($("#topic_list")).show();
      $topic.attr('id', 'topic_new');
    }
    var topic = data.discussion_topic || data.announcement;
    if(topic.assignment) {
      topic.points_possible = topic.assignment.points_possible;
      topic.due_at = $.parseFromISO(topic.assignment.due_at).datetime_formatted;
      topic.assignment_group_id = topic.assignment.assignment_group_id;
    }
    var $topic_sortable = $("#topics_reorder_list topic_" + topic.id);
    if($topic_sortable.length === 0) {
      $topic_sortable = $("<li class='topic'/>");
      $topic_sortable.addClass('topic_' + topic.id);
      $("#topics_reorder_list").prepend($topic_sortable);
    }
    $topic_sortable.text(topic.title);
    $("#topics_reorder_list").sortable('refresh');
    $topic.toggleClass('has_podcast', !!topic.podcast_enabled);
    $("#podcast_link_holder").showIf(topic.podcast_enabled);
    $topic.toggleClass('announcement', !!data.announcement);
    topic.user_name = topic.user_name ? topic.user_name : "";
    delete topic['user'];
    var date_data = $.parseFromISO(topic.created_at, 'event');
    topic.post_date = date_data.datetime_formatted;
    if(topic.assignment) {
      topic.assignment_title = topic.assignment.title;
      $topic.find(".topic_assignment_link").attr('href',$.replaceTags($topic.find(".topic_assignment_url").attr('href'), 'assignment_id', topic.assignment_id));
      if(topic.assignment.points_possible) {
        topic.assignment_points_possible = topic.assignment.points_possible;
      }
    }
    $topic.find(".attachment_data").showIf(topic.attachment);
    if(topic.attachment) {
      topic.attachment_name = topic.attachment.display_name;
      var url = $.replaceTags($topic.find(".topic_attachment_url").attr('href'), 'attachment_id', topic.attachment.id);
      $topic.find(".attachment_name").attr('href', url);
    }
    if(topic.workflow_state == 'post_delayed' && topic.delayed_post_at) {
      topic.delayed_post_at = $.parseFromISO(topic.delayed_post_at).datetime_formatted;
    }
    $topic.find(".locked_icon").toggleClass('locked', topic.workflow_state == 'locked');
    topic.assignment_title = topic.title;
    $topic.find(".content .message_html").val(topic.message);
    $topic.fillTemplateData({
      id: 'topic_' + topic.id,
      data: topic,
      htmlValues: ['message'],
      hrefValues: ['id', 'user_id', 'discussion_topic_id']
    });
    //the a.user_name link is display:none in the #topic_blank, so make sure to show it if there is a name in there.
    if ($topic.find("a.user_name").text().length) {
      $topic.find("a.user_name").show();
    }
    if(topic.discussion_subentry_count) {
      $topic.find(".replies").text(I18n.t('number_of_replies',
        {zero: "No Replies", one: "1 Reply", other: "%{count} Replies"},
	{count: topic.discussion_subentry_count}));
    }
    $topic.find(".for_assignment").showIf(topic.assignment_id);
    $topic.find(".assignment_points").showIf(topic.assignment && topic.assignment.points_possible);
    $topic.find(".delayed_posting").showIf(topic.workflow_state == 'post_delayed' && topic.delayed_post_at);
    $topic.find(".edit_topic_link").showIf(topic.permissions && topic.permissions.update);
    $topic.find(".delete_topic_link").showIf(topic.permissions && topic.permissions['delete']);
  }
  function editTopic($topic) {
      hideTopicForm(true);
      var $form = $("#add_topic_form").clone(true);
      if($topic.attr('id') == 'topic_id') { $topic.attr('id', 'topic_new'); }
      var id = $topic.attr('id');
      $form.addClass('add_topic_form_new').attr('id', 'add_topic_form_' + id)
        .find(".topic_content").addClass('topic_content_new').attr('id', 'topic_content_' + id);
      var data = $topic.getTemplateData({
        textValues: ['title', 'is_announcement', 'delayed_post_at', 'assignment[id]', 'attachment_name', 'assignment[points_possible]', 'assignment[assignment_group_id]', 'assignment[due_at]', 'podcast_enabled', 'podcast_has_student_posts', 'require_initial_post'],
        htmlValues: ['message']
      });
      data.message = $topic.find(".content .message_html").val();
      if(data.title == I18n.t('no_title', "No Title")) {
        data.title = I18n.t('default_topic_title', "Topic Title");
      }
      if(data.delayed_post_at) {
        data.delay_posting = '1';
      }
      if(data['assignment[id]']) {
        data['assignment[set_assignment]'] = '1';
      }
      var addOrUpdate = $topic.hasClass('announcement') ?
        I18n.t('update_announcment', "Update Announcement") :
        I18n.t('update_topic', "Update Topic");
      $form.attr('method', "PUT");
      $form.attr('action', $topic.find(".edit_topic_url").attr('href'));
      $form.find(".discussion_remove_attachment").val("0");
      $form.find(".add_attachment").show().end()
        .find(".no_attachment").showIf(!data.attachment_name).end()
        .find(".current_attachment").showIf(data.attachment_name).end()
        .find(".upload_attachment").hide().end()
        .find(".attachment_name").text(data.attachment_name || "").end()
        .find(".more_options_link").show().end()
        .find(".more_options_holder").hide();
      $form.find(".datetime_field").datetime_field();
      $form.find(".announcement_option").showIf($topic.attr('id') == "topic_new");
      if($topic.attr('id') == "topic_new") {
        addOrUpdate = $topic.hasClass('announcement') ?
          I18n.t('add_new_announcement', "Add New Announcement") :
          I18n.t('add_new_topic', "Add New Topic");
        $form.attr('method', "POST");
        $form.attr('action', $("#topic_urls .add_topic_url").attr('href'));
      }
      $form.fillFormData(data, {object_name: "discussion_topic"});
      $form.find(".is_announcement").change();

      $topic.find(".content").show()
          .find(".links").hide().end()
          .find(".message").hide().end()
        .append($form.show()).end()
        .find(".header")
          .find(".post_date").hide().end()
          .find(".link_box").hide().end()
          .find(".title").hide().end()
          .find(".topic_icon").hide().end()
          .prepend("<span class='add_message title'>" + addOrUpdate + "</span>")
        .hide();
      $form.find("#topic_content_" + id).editorBox();
      $form.find("#topic_content_" + id).editorBox('set_code', data.message);
      if(wikiSidebar) {
        wikiSidebar.attachToEditor($form.find("#topic_content_" + id));
        wikiSidebar.show();
        $("#sidebar_content").hide();
      }
      $form.find("button.submit_button").html(addOrUpdate);
      $form.find("input[type='text']:first").focus().select();
      $("html,body").scrollTo($form);
  }
  function hideTopicForm(andTopicIfNew) {
    var $form = $(".add_topic_form_new");
    if ($form.length == 0) {
      return;
    }
    $form.hideErrors();
    var $topic = $form.parents(".topic");
    try {
      $form.find(".topic_content_new").editorBox('destroy');
    } catch(e) {
      INST.log_error({
        'message': e.message || e.description || "",
        'line': e.lineNumber || ''
      });
    }
    $form.hide();
    $topic.find(".header .add_message").remove();
    $topic.find(".header").show()
        .find(".post_date").show().end()
        .find(".add_message").remove().end()
        .find(".title").show().end()
        .find(".topic_icon").css('display', '').end()
        .find(".link_box").show().end().end()
      .find(".content").show()
        .find(".links").show().end()
        .find(".message").show().end();
    $form.appendTo($("body"));
    if(wikiSidebar) {
      wikiSidebar.hide();
      $("#sidebar_content").show();
    }
    if(andTopicIfNew) {
      if($topic.attr('id') == "topic_new") {
        $topic.remove();
      }
      if($('#topic_list > .topic').length === 0) {
        $("#no_topics_message").show();
      }
    }
  }
  $(document).ready(function() {
    if(wikiSidebar) {
      wikiSidebar.init();
      $.scrollSidebar();
    }
    if(attachAddAssignment && $.isFunction(attachAddAssignment)) {
      attachAddAssignment($("#add_topic_form .assignment_id_value"), null, ".assignment_id_value", function() {
        return $(this).parents("form").find(".topic_title").val();
      });
    }
    $(".reorder_topics_link").click(function(event) {
      event.preventDefault();
      $("#reorder_topics_dialog").dialog('close').dialog({
        autoOpen: false,
        title: I18n.t('titles.reorder_discussions', "Reorder Discussions"),
        width: 400,
        modal: true
      }).dialog('open');
    });
    $("#topics_reorder_list").sortable({
      axis: 'y'
    });
    $("#reorder_topics_form").submit(function() {
      var ids = [];
      $("#reorder_topics_form .reorder_topics_button").text(I18n.t('reordering', "Reordering..."));
      $("#reorder_topics_form button").attr('disabled', true);
      $("#topics_reorder_list li").each(function() {
        var classes = $(this).attr('class').split(/\s/);
        var id = null;
        for(var idx in classes) {
          var c = classes[idx];
          if(c.match(/topic_/)) {
            id = c.substring(6);
          }
        }
        if(id) {
          ids.push(id);
        }
      });
      $("#reorder_topics_ids").val(ids.join(','));
    });
    $("#reorder_topics_form .cancel_button").click(function() {
      $("#reorder_topics_dialog").dialog('close');
    });
    $("#add_topic_form .topic_title").formSuggestion();
    $("#add_topic_form")
    .find(".delay_posting").change(function() {
      $(this).parents("form").find(".delay_posting_option").showIf($(this).attr('checked'));
    }).change().end()
    .find(".set_assignment").change(function() {
      $(this).parents("form").find(".set_assignment_option").showIf($(this).attr('checked'));
      $(this).parents("form").find(".announcement_option").showIf(!$(this).attr('checked') && $(this).parents("form").attr('id').match(/_new$/));
    }).change().end()
    .find(".is_announcement").change(function() {
      $(this).parents("form").find(".assignment_options").showIf(!$(this).attr('checked'));
      $(this).parents("form").find(".podcast_options").showIf(!$(this).attr('checked'));
    }).end()
    .find(".podcast_enabled_checkbox").change(function() {
      $(this).parents("form").find(".podcast_sub_options").showIf($(this).attr('checked'));
    }).end()
    .find(".more_options_link").click(function(event) {
      event.preventDefault();
      $(this).hide().parents("form").find(".more_options_holder").show();
    }).end()
    .find(".add_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".no_attachment").slideUp().addClass('current');
      $form.find(".current_attachment").hide().removeClass('current');
      $form.find(".upload_attachment").slideDown();
    }).end()
    .find(".delete_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".current_attachment").slideUp().removeClass('current');
      $form.find(".no_attachment").slideDown().addClass('current');
      $form.find(".upload_attachment").hide();
      $form.find(".discussion_remove_attachment").val("1");
    }).end()
    .find(".replace_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".upload_attachment").slideDown();
      $form.find(".no_attachment").hide().removeClass('current');
      $form.find(".current_attachment").slideUp().addClass('current');
    }).end()
    .find(".cancel_attachment_link").click(function(event) {
      event.preventDefault();
      var $form = $(this).parents("form");
      $form.find(".no_attachment.current").slideDown();
      $form.find(".upload_attachment").slideUp();
      $form.find(".current_attachment.current").slideDown();
      $form.find(".attachment_uploaded_data").val("");
      $form.find(".discussion_remove_attachment").val("0");
    });
    $(".topic .editable_locked_icon").click(function(event) {
      event.preventDefault();
      var $topic = $(this).parents(".topic");
      var lock = $(this).hasClass('locked') ? '0' : '1';
      var $link = $(this);
      $link.loadingImage({image_size: 'small'});
      var url = $(this).parents(".topic").find(".edit_topic_link").attr('href');
      $.ajaxJSON(url, 'PUT', {'discussion_topic[lock]': lock}, function(data) {
        $link.loadingImage('remove');
        var topic = data.discussion_topic || data.announcement;
        $topic.find(".locked_icon").toggleClass('locked', topic.workflow_state == 'locked');
        $topic.find(".locked_icon").attr('title', topic.workflow_state == 'locked' ? I18n.t('titles.unlock_this_topic', 'Unlock this Topic') : I18n.t('titles.lock_this_topic', 'Lock this Topic'));
      }, function(data) {
        $link.loadingImage('remove');
      });
    });
    $("#add_topic_form").formSubmit({
      fileUpload: function(data) { 
        var doUpload = data['attachment[uploaded_data]'];
        if(doUpload) { $(this).attr('action', $(this).attr('action') + '.text'); }
        return doUpload; 
      },
      object_name: 'discussion_topic',
      required: ['title'],
      processData: function(data) {
        var formData = $(this).getFormData({object_name: "discussion_topic"});
        try {
          formData.message = $(this).find(".topic_content_new").editorBox('get_code');
        } catch(e) {
          return;
        }
        formData.message = $(this).find(".topic_content_new").editorBox('get_code');
        formData['discussion_topic[message]'] = formData.message;
        if(!formData.message) {
          if($(this).find(".topic_content").is(":visible")) {
            $(this).find(".topic_content").errorBox(I18n.t('errors.enter_a_message', 'Please enter a message'));
          } else {
            $(this).find(".topic_content").next().find(".mceIframeContainer").errorBox(I18n.t('errors.enter_a_message', 'Please enter a message'));
          }
          return false;
        }
        if(data.delay_posting == '1') {
          if(!formData['discussion_topic[delayed_post_at]']) {
            $(this).find(".delayed_post_at_value").errorBox(I18n.t('errors.invalid_date_time', "Please select a valid date time"));
            return false;
          }
        }
        return formData;
      },
      beforeSubmit: function(data) {
        var addingMessage = I18n.t('updating', "Updating...");
        var $topic = $(this).parents(".topic");
        if($topic.attr('id') == "topic_new") {
          addingMessage = I18n.t('adding', "Adding...");
          $topic.attr('id', 'topic_id');
        }
        data.post_date = addingMessage;
        $topic.fillTemplateData({
          data: data,
          except: ['message']
        });
        $topic.find(".content").loadingImage();
        hideTopicForm();
        return $topic;
      },
      success: function(data, $topic) {
        updateTopic($topic, data);
        $topic.find(".content").loadingImage('remove');
      },
      error: function(data, $topic) {
        $topic.find(".content").loadingImage('remove');
        editTopic($topic);
        if($topic.attr('id') == "topic_id") {
          addingMessage = I18n.t('adding', "Adding...");
          $topic.attr('id', 'topic_new');
        }
        return $topic.find("form");
      }
    });
    $("#add_topic_form .cancel_button").click(function(event) {
      var $topic = $(this).parents(".topic");
      hideTopicForm(true);
    });
    $(".add_topic_link").click(function(event) {
      event.preventDefault();
      $("#no_topics_message").hide();
      if($("#topic_new").length > 0) {
        return;
      }
      var $topic = $("#topic_blank").clone(true);
      if(true || canDeleteTopics) {
        $topic.find(".delete_topic_link").show();
      } else {
        $topic.find(".delete_topic_link").hide();
      }
      if(true || canEditTopics) {
        $topic.find(".edit_topic_link").show();
      } else {
        $topic.find(".edit_topic_link").hide();
      }
      $topic.prependTo($("#topic_list")).show();
      $topic.attr('id', 'topic_new');
      editTopic($topic);
    });
    $(".switch_topic_views_link").click(function(event) {
      event.preventDefault();
      $(this).parents("form").find("textarea").editorBox('toggle');
    });
    $(".topic").bind('mouseover focus', function() {
      $(this).find(".header .locked_icon").addClass('locked_icon_hover');
    })
    .bind('mouseout blur', function() {
      $(this).find(".header .locked_icon").removeClass('locked_icon_hover');
    });
    $(".edit_topic_link").click(function(event) {
      event.preventDefault();
      $topic = $(this).parents(".topic");
      if($topic.length == 0) {
        $topic = $("#topic_list .topic:visible:first");
      }
      if($topic.length > 0) {
        editTopic($topic);
      }
    });
      $(".delete_topic_link").click(function(event) {
        event.preventDefault();
        var token = $("form:first").getFormData().authenticity_token;
        var $topic = $(this).parents(".topic");
        $topic.confirmDelete({
          message: $topic.hasClass('announcement') ?
            I18n.t('confirms.delete_announcement', "Are you sure you want to delete this announcement?") :
            I18n.t('confirms.delete_topic', "Are you sure you want to delete this topic?"),
          token: token,
          url: $(this).attr('href'),
          success: function() {
            $(this).fadeOut('slow', function() {
              $(this).remove();
              if(!$('#topic_list > .topic').length) {
                $("#no_topics_message").show();
              }
            });
          },
          error: function(data) {
            $(this).formErrors(data);
          }
        });
      });
      $("#add_topic_form :text").keycodes('tab esc', function(event) {
        if($(this).hasClass('topic_title') && event.keyCode == 9) {
          $(this).blur();
          $(this).parents("form").find(".topic_content_new").editorBox('focus');
          event.preventDefault();
          return;
        }
        if(event.keyCode == 27) {
          event.preventDefault();
          hideTopicForm(true);
        }
      });
    $(document).fragmentChange(function(event, fragment) {
      if(fragment == "#new") {
        $(".add_topic_link:visible:first").click();
      }
    }).fragmentChange();
  });
});

