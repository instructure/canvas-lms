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

// There's technically a security vulnerability here.  Since we let
// the user insert arbitrary content into their page, it's possible
// they'll create elements with the same class names we're using to
// find endpoints for updating settings and content.  However, since
// only the portfolio's owner can set this content, it seems like
// the worst they can do is override endpoint urls for eportfolio 
// settings on their own personal eportfolio, they can't 
// affect anyone else

define([
  'i18n!eportfolio',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.inst_tree' /* instTree */,
  'jquery.instructure_forms' /* formSubmit, getFormData, formErrors, errorBox */,
  'jqueryui/dialog',
  'compiled/jquery/fixDialogButtons' /* fix dialog formatting */,
  'jquery.instructure_misc_helpers' /* replaceTags, scrollSidebar */,
  'jquery.instructure_misc_plugins' /* confirmDelete, showIf */,
  'jquery.loadingImg' /* loadingImage */,
  'jquery.templateData' /* fillTemplateData, getTemplateData */,
  'compiled/tinymce',
  'tinymce.editor_box' /* editorBox */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */,
  'jqueryui/progressbar' /* /\.progressbar/ */,
  'jqueryui/sortable' /* /\.sortable/ */
], function(I18n, $) {

  var ePortfolioValidations = {
    object_name: 'eportfolio',
    property_validations: {
      'name': function(value){
        if (!value || value.trim() == '') { return I18n.t("errors.name_required", "Name is required")}
        if (value && value.length > 255) { return I18n.t("errors.name_too_long", "Name is too long")}
      }
    }
  };

  function ePortfolioFormData() {
    var data = $("#edit_page_form").getFormData({
      object_name: "eportfolio_entry", 
      values: ['eportfolio_entry[name]', 'eportfolio_entry[allow_comments]', 'eportfolio_entry[show_comments]']
    });
    var idx = 0;
    $("#edit_page_form .section").each(function() {
      var section_type = $(this).getTemplateData({textValues: ['section_type']}).section_type;
      if(section_type == "rich_text" || section_type == "html" || $(this).hasClass('read_only')) {
        idx++;
        var name = "section_" + idx;
        if(section_type == "rich_text") {
          data[name + '[section_type]'] = "rich_text";
          data[name + '[content]'] = $(this).find(".edit_section").editorBox('get_code');
        } else if(section_type == "html") {
          data[name + '[section_type]'] = "html";
          data[name + '[content]'] = $(this).find(".edit_section").val();
        } else if(section_type == "submission") {
          data[name + '[section_type]'] = "submission";
          data[name + '[submission_id]'] = $(this).getTemplateData({textValues: ['submission_id']}).submission_id;
        } else if(section_type == "attachment") {
          data[name + '[section_type]'] = "attachment";
          data[name + '[attachment_id]'] = $(this).getTemplateData({textValues: ['attachment_id']}).attachment_id;
        }
      }
    });
    data['section_count'] = idx;
    return data;
  }
  $(document).ready(function() {
    $(".portfolio_settings_link").click(function(event) {
      event.preventDefault();
      $("#edit_eportfolio_form").dialog({
        width: "auto",
        title: I18n.t('eportfolio_settings', "ePortfolio Settings")
      }).fixDialogButtons();
    });
    // Add ePortfolio related
    $(".add_eportfolio_link").click(function(event) {
      event.preventDefault();
      $("#whats_an_eportfolio").slideToggle();
      $("#add_eportfolio_form").slideToggle(function() {
        $(this).find(":text:first").focus().select();
      });
    });
    $("#add_eportfolio_form .cancel_button").click(function() {
      $("#add_eportfolio_form").slideToggle();
      $("#whats_an_eportfolio").slideToggle();
    });
    $('#add_eportfolio_form').submit(function(){
      var $this = $(this);
      var result = $this.validateForm(ePortfolioValidations);
      if(!result) {
        return false;
      }
    });
    // Edit ePortfolio related
    $("#edit_eportfolio_form .cancel_button").click(function(event) {
      $("#edit_eportfolio_form").dialog('close');
    });
    $("#edit_eportfolio_form").formSubmit($.extend(ePortfolioValidations, {
      beforeSubmit: function(data) {
        $(this).loadingImage();
      },
      success: function(data) {
        $(this).loadingImage('remove');
        $(this).dialog('close');
      }
    }));
    $(".edit_content_link").click(function(event) {
      event.preventDefault();
      $(".edit_content_link_holder").hide();
      $("#page_content").addClass('editing');
      $("#edit_page_form").addClass('editing');
      $("#page_sidebar").addClass('editing');
      $("#edit_page_form .section").each(function() {
        var $section = $(this);
        var sectionData = $section.getTemplateData({
          textValues: ['section_type'],
          htmlValues: ['section_content']
        });
        sectionData.section_content = $.trim(sectionData.section_content);
        var section_type = sectionData.section_type;
        var edit_type = "edit_" + section_type + "_content";
        
        var $edit = $("#edit_content_templates ." + edit_type).clone(true);
        $section.append($edit.show());
        if(edit_type == "edit_html_content") {
          $edit.find(".edit_section").attr('id', 'edit_' + $section.attr('id'));
          $edit.find(".edit_section").val(sectionData.section_content);
        } else if(edit_type == "edit_rich_text_content") {
          $edit.find(".edit_section").attr('id', 'edit_' + $section.attr('id'));
          $edit.find(".edit_section").editorBox()
            .editorBox('set_code', sectionData.section_content);
        }
      });
      $("#edit_page_form :text:first").focus().select();
      $("#page_comments_holder").hide();
      $(document).triggerHandler('editing_page');
    });
    $("#edit_page_form").find(".allow_comments").change(function() {
      $("#edit_page_form .show_comments_box").showIf($(this).attr('checked'));
    }).change();
    $("#edit_page_sidebar .submit_button").click(function(event) {
      $("#edit_page_form").submit();
    });
    $("#edit_page_form,#edit_page_sidebar").find(".preview_button").click(function(){
      $("#page_content .section.failed").remove();
      $("#edit_page_form,#page_content,#page_sidebar").addClass('previewing');
      $("#page_content .section").each(function() {
        var $preview = $(this).find(".section_content").clone().removeClass('section_content').addClass('preview_content').addClass('preview_section');
        var section_type = $(this).getTemplateData({textValues: ['section_type']}).section_type;
        if(section_type == "html") {
          $preview.html($(this).find(".edit_section").val());
          $(this).find(".section_content").after($preview);
        } else if (section_type == "rich_text") {
          $preview.html($(this).find(".edit_section").editorBox('get_code'));
          $(this).find(".section_content").after($preview);
        }
      });
    }).end().find(".keep_editing_button").click(function() {
      $("#edit_page_form,#page_content,#page_sidebar").removeClass('previewing');
      $("#page_content .preview_section").remove();
    }).end().find(".cancel_button").click(function() {
      $('.edit_section').editorBox('destroy');
      $("#edit_page_form,#page_content,#page_sidebar").removeClass('editing');
      $("#page_content .section.unsaved").remove();
      $(".edit_content_link_holder").show();
      $("#edit_page_form .edit_section").each(function() {
        $(this).remove();
      });
      $("#page_content .section .form_content").remove();
      $("#page_comments_holder").show();
    });
    $("#edit_page_form").formSubmit({
      processData: function(data) {
        $("#page_content .section.unsaved").removeClass('unsaved');
        $("#page_content .section.failed").remove();
        $("#page_content .section").each(function() {
          var section_type = $(this).getTemplateData({textValues: ['section_type']}).section_type;
          if(section_type == "rich_text" || section_type == "html") {
            var code = $(this).find(".edit_section").val();
            if(section_type == "rich_text") { 
              code = $(this).find(".edit_section").editorBox('get_code');
            }
            $(this).find(".section_content").html($.raw(code));
          } else if(!$(this).hasClass('read_only')) {
            $(this).remove();
          }
        });
        var data = ePortfolioFormData();
        return data;
      },
      beforeSubmit: function(data) {
        $('.edit_section').editorBox('destroy');
        $("#edit_page_form,#page_content,#page_sidebar").removeClass('editing').removeClass('previewing');
        $("#page_content .section.unsaved,#page_content .section .form_content").remove();
        $("#edit_page_form .edit_section").each(function() {
          $(this).remove();
        });
        $(this).loadingImage();
      },
      success: function(data) {
        $(document).triggerHandler('page_updated', data);
        $(".edit_content_link_holder").show();
        if(data.eportfolio_entry.allow_comments) {
          $("#page_comments_holder").slideDown('fast');
        }
        $(this).loadingImage('remove');
      }
    });
    $("#edit_page_form .switch_views_link").click(function(event) {
      event.preventDefault();
      $("#edit_page_content").editorBox('toggle');
      //  todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(this).siblings(".switch_views_link").andSelf().toggle();
    });
    $("#edit_page_sidebar .add_content_link").click(function(event) {
      event.preventDefault();
      $("#edit_page_form .keep_editing_button:first").click();
      var $section = $("#page_section_blank").clone(true).attr('id', 'page_section_' + sectionCountIdx);
      $section.addClass('unsaved');
      $section.attr('id', 'page_section_' + sectionCountIdx++);
      $("#page_content").append($section);
      var section_type = "rich_text";
      var section_type_name = I18n.t('#eportfolios._page_section.section_types.rich_text', "Rich Text Content")
      if($(this).hasClass('add_html_link')) {
        section_type = "html";
        section_type_name = I18n.t('#eportfolios._page_section.section_types.html', "HTML/Embedded Content");
      } else if($(this).hasClass('add_submission_link')) {
        section_type = "submission";
        section_type_name = I18n.t('#eportfolios._page_section.section_types.submission', "Course Submission");
      } else if($(this).hasClass('add_file_link')) {
        section_type = "attachment";
        section_type_name = I18n.t('#eportfolios._page_section.section_types.attachment', "Image/File Upload");
      }
      var edit_type = "edit_" + section_type + "_content";
      $section.fillTemplateData({
        data: {section_type: section_type, section_type_name: section_type_name} 
      });
      var $edit = $("#edit_content_templates ." + edit_type).clone(true);
      $section.append($edit.show());
      if(edit_type == "edit_html_content") {
        $edit.find(".edit_section").attr('id', 'edit_' + $section.attr('id'));
      } else if(edit_type == "edit_rich_text_content") {
        $edit.find(".edit_section").attr('id', 'edit_' + $section.attr('id'));
        $edit.find(".edit_section").editorBox();
      }
      $section.hide().slideDown('fast', function() {
        $("html,body").scrollTo($section);
        if(section_type == "rich_text") {
          $edit.find(".edit_section").editorBox('focus', true);
        } else if(section_type == "html") {
          $edit.find(".edit_section").focus().select();
        }
      });
    });
    $(".delete_page_section_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".section").confirmDelete({
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $("#page_content").sortable({
      handle: '.move_link',
      helper: 'clone',
      axis: 'y',
      start: function(event, ui) {
        var $item = $(ui.item);
        if($item.getTemplateData({textValues: ['section_type']}).section_type == 'rich_text') {
          $item.find("textarea").editorBox('destroy');
        }
      },
      stop: function(event, ui) {
        var $item = $(ui.item);
        if($item.getTemplateData({textValues: ['section_type']}).section_type == 'rich_text') {
          $item.find("textarea").editorBox();
        }
      }
    });
    $("#page_content").delegate('.cancel_content_button', 'click', function(event) {
      event.preventDefault();
      $(this).parents('.section').slideUp(function() {
        $(this).remove();
      });
    }).delegate('.select_submission_button', 'click', function(event) {
      event.preventDefault();
      var $section = $(this).parents(".section");
      var $selection = $section.find(".submission_list li.active-leaf:first");
      if($selection.length === 0) { return; }
      var url = $selection.find(".submission_preview_url").attr('href');
      var id = $selection.attr('id').substring(11);
      $section.fillTemplateData({
        data: {submission_id: id}
      });
      $section.find(".section_content").empty();
      var $frame = $("#edit_content_templates").find(".submission_preview").clone();
      $frame.attr('src', url);
      $section.append($frame);
      $section.addClass('read_only');
    }).delegate('.upload_file_button', 'click', function(event) {
      event.preventDefault();
      event.stopPropagation();
      var $section = $(this).parents(".section")
      var $message = $("#edit_content_templates").find(".uploading_file").clone();
      var $upload = $(this).parents(".section").find(".file_upload");
      
      if(!$upload.val() && $section.find(".file_list .leaf.active").length === 0) {
        return;
      }
      
      $message.fillTemplateData({
        data: {file_name: $upload.val()}
      });
      $(this).parents(".section").find(".section_content").empty().append($message.show());
      var $form = $("#upload_file_form").clone(true).attr('id', '');
      $("body").append($form.css({position: 'absolute', zIndex: -1}));
      $form.data('section', $section);
      $form.find(".file_upload").remove().end()
        .append($upload)
        .submit();
      $section.addClass('read_only');
    });
    $("#upload_file_form").formSubmit({
      fileUpload: true,
      fileUploadOptions: {
        preparedFileUpload: true,
        upload_only: true,
        singleFile: true,
        context_code: ENV.context_code,
        folder_id: ENV.folder_id,
        formDataTarget: 'uploadDataUrl'
      },
      object_name: 'attachment',
      processData: function(data) {
        if(!data.uploaded_data) {
          var $section = $(this).data('section');
          var $file = $section.find(".file_list .leaf.active");
          // If the user has selected a file from the list instead of uploading
          if($file.length > 0) {
            var data = $file.getTemplateData({textValues: ['id', 'name']});
            var id = data.id;
            var uuid = $("#file_uuid_" + id).text();
            var name = data.name;
            $section.find(".attachment_id").text(id);
            var url = $(".eportfolio_download_url").attr('href');
            url = $.replaceTags(url, 'uuid', uuid);
            if($file.hasClass('image')) {
              var $image = $("#eportfolio_view_image").clone(true).removeAttr('id');
              $image.find(".eportfolio_image").attr('src', url).attr('alt', name);
              $image.find(".eportfolio_download").attr('href', url);
              $section.find(".section_content")
                .empty()
                .append($image);
            } else {
              var $download = $("#eportfolio_download_file").clone(true).removeAttr('id');
              $download.fillTemplateData({
                data: {filename: data.name}
              });
              $download.find(".eportfolio_download").attr('href', url);
              $section.find(".section_content")
                .empty()
                .append($download);
            }
            $(this).remove();
          } else {
            $(this).errorBox(I18n.t('errors.missing_file', 'Please select a file'));
          }
          return false;
        }
      },
      success: function(data) {
        var $section = $(this).data('section');
        var attachment = data.attachment;
        $section.find(".attachment_id").text(attachment.id);
        var url = $(".eportfolio_download_url").attr('href');
        url = $.replaceTags(url, 'uuid', attachment.uuid);
        if(attachment.content_type.indexOf("image") != -1) {
          var $image = $("#eportfolio_view_image").clone(true).removeAttr('id');
          $image.find(".eportfolio_image").attr('src', url).attr('alt', attachment.display_name);
          $image.find(".eportfolio_download").attr('href', url);
          $section.find(".section_content")
            .empty()
            .append($image);
        } else {
          var $download = $("#eportfolio_download_file").clone(true).removeAttr('id');
          $download.fillTemplateData({
            data: {filename: attachment.display_name}
          });
          $download.find(".eportfolio_download").attr('href', url);
          $section.find(".section_content")
            .empty()
            .append($download);
        }
        $(this).remove();
      },
      error: function(data) {
        var $section = $(this).data("section");
        $section.find(".uploading_file").text(I18n.t('errors.upload_failed', "Upload Failed."));
        $section.addClass('failed');
        $section.formErrors(data.errors || data);
      }
    });
    $("#recent_submissions .submission").click(function(event) {
      if($(event.target).closest('a').length === 0) {
        event.preventDefault();
        event.stopPropagation();
        $(this).removeClass('active-leaf');
        $("#category_select").triggerHandler('change');
        var id = $(this).getTemplateData({textValues: ['submission_id']}).submission_id;
        $("#add_submission_form .submission_id").val(id);
        var assignment = $(this).find(".assignment_title").text();
        var context = $(this).find(".context_name").text();
        $("#add_submission_form .submission_description").val(
          I18n.t('default_description', "This is my %{assignment} submission for %{course}.",
            { 'assignment': assignment, 'course': context }));
        $("#add_submission_form").dialog({
          title: I18n.t('titles.add_submission', 'Add Page for Submission'),
          width: 400,
          open: function() {
            $(this).find(":text:visible:first").val(assignment).focus().select();
            $(document).triggerHandler('submission_dialog_opened');
          }
        }).fixDialogButtons();
      }
    });
    $("#add_submission_form .cancel_button").click(function() {
      $("#add_submission_form").dialog('close');
    });
    $("#add_submission_form").formSubmit({
      processData: function(data) {
        var url = $(this).find(".add_eportfolio_entry_url").attr('href');
        $(this).attr('action', url);
      },
      beforeSubmit: function(data) {
        $(this).loadingImage();
      },
      success: function(data) {
        $(this).loadingImage('remove');
        $(this).dialog('close');
        var entry = data.eportfolio_entry;
        try {
          var submission_id = entry.content[1].submission_id;
          $("#submission_" + submission_id + ",#recent_submission_" + submission_id).addClass('already_used');
        } catch(e) { }
        var url = $(this).find(".eportfolio_named_entry_url").attr('href');
        url = $.replaceTags(url, "category_slug", entry.category_slug);
        url = $.replaceTags(url, "slug", entry.slug);
        location.href = url;
        $(document).triggerHandler('page_added', data);
      }
    });
    $("#category_select").change(function(event) {
      var id = $(this).val();
      if(id == "new") {
        return;
      }
      $("#page_select_list .page_select:not(#page_select_blank)").remove();
      $("#structure_category_" + id).find(".entry_list li.entry").each(function() {
        var $page = $("#page_select_blank").clone(true).removeAttr('id');
        $page.text($(this).getTemplateData({textValues: ['name']}).name);
        $("#page_select_list").append($page.show());
      });
    }).triggerHandler('change');
    $.scrollSidebar();
    
    $(".delete_comment_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".comment").confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t('confirm_delete_message', "Are you sure you want to delete this message?"),
        success: function(data) {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $(".delete_eportfolio_link").click(function(event) {
      event.preventDefault();
      $("#delete_eportfolio_form").toggle(function() {
        $("html,body").scrollTo($("#delete_eportfolio_form"));
      });
    });
    $(document).blur(function() {
    });
  });

  $(document).ready(function() {
    $(".submission_list").instTree({
      multi: false,
      dragdrop: false
    });
    $(".file_list > ul").instTree({
      autoclose: false,
      multi: false,
      dragdrop: false,
      overrideEvents: true,
      onClick: function(e, node) {
        $(this).parents('.file_list').find('li.active').removeClass('active');
        $(this).addClass('active');
        if($(this).hasClass('file')) {
          var id = $(this).getTemplateData({textValues: ['id']}).id;
          
        }
      }
    });
  });

  function hideEditObject(type) {
    var $box = $("#" + type + "_name_holder");
    var $input = $("#" + type + "_name");
    var val = $input.val();
    var $obj = $box.parents("li." + type);
    $obj.find(".name").text(val);
    if($obj.parent("ul").length > 0) {
      $box.hide().appendTo($("body"));
      $obj.find("." + type + "_url").show();
    }
    if($obj.attr('id') == type + '_new') {
      $obj.remove();
    }
  }
  function saveObject($obj, type) {
    var isSaving = $obj.data('event_pending');
    if(isSaving || $obj.length === 0) { return; }
    var method = "PUT";
    var url = $obj.find(".rename_" + type + "_url").attr('href');
    if($obj.attr('id') == type + '_new') {
      method = "POST";
      url = $(".add_" + type + "_url").attr('href');
    }
    var $objs = $obj.parents("ul").find("." + type + ":not(.unsaved)");
    var newName = $obj.find("#" + type + "_name").val()
    $objs.each(function() {
      if(this != $obj[0] && $(this).find(".name").text() == newName) {
        newName = "";
      }
    });
    if(!newName) { return false; }
    var object_name = "eportfolio_category";
    if(type == "page") { object_name = "eportfolio_entry"; }
    var data = {};
    data[object_name + '[name]'] = newName;
    if(type == "page") {
      data[object_name + '[eportfolio_category_id]'] = $("#eportfolio_category_id").text();
    }
    if(method == "POST") {
      $obj.attr('id', type + '_saving');
    }
    $obj.data('event_pending', true);
    $obj.addClass('event_pending');
    $.ajaxJSON(url, method, data, function(data) {
      $obj.removeClass('event_pending');
      $obj.removeClass('unsaved');
      var obj = data[object_name];
      if(method == "POST") {
        $obj.remove();
        $(document).triggerHandler(type + "_added", data);
      } else {
        $(document).triggerHandler(type + '_updated', data);
      }
      $obj.fillTemplateData({
        data: obj,
        id: type + '_' + obj.id,
        hrefValues: ['id', 'slug']
      });
      $obj.data('event_pending', false);
      countObjects(type);
    },
    // error callback
    function(data, xhr, textStatus, errorThrown){
      $obj.removeClass('event_pending');
      $obj.data('event_pending', false);
      var name_message = I18n.t("errors.section_name_invalid", "Section name is not valid")
      if (xhr['name'] && xhr['name'].length > 0 && xhr['name'][0]['message'] == 'too_long') {
        name_message = I18n.t("errors.section_name_too_long", "Section name is too long");
      }
      if ($obj.hasClass('unsaved')) {
        alert(name_message);
        $obj.remove();
      }
      else {
        // put back in "edit" mode
        $obj.find('.edit_section_link').click();
        $obj.find('#section_name').errorBox(name_message).css('z-index', 20)
      }
    },
    // options
    {skipDefaultError: true});
    return true;
  }
  function editObject($obj, type) {
    var $name = $obj.find("." + type + "_url");
    var width = $name.outerWidth() - 30;
    if(type == 'page') {
      width = 145;
    } else {
      width = 145;
    }
    var $box = $("#" + type + "_name_holder");
    var $input = $("#" + type + "_name");
    $input.width(width);
    $name.hide().before($box);
    $input.val($.trim($name.find(".name").text()));
    $box.show();
    $input.focus().select();
  }
  function countObjects(type) {
    var cnt = $("#" + type + "_list ." + type + ":not(.unsaved)").length;
    if(cnt > 1) {
      $("#" + type + "_list .remove_page_link").css('display', '');
    } else {
      $("#" + type + "_list .remove_page_link").hide();
    }  
  }
  $(document).ready(function() {
    countObjects('page');
    $(document).bind('page_deleted', function(event, data) {
      if(!data) { return; }
      var entry = data.eportfolio_entry;
      $("#page_" + entry.id).remove();
      $("#structure_entry_" + entry.id).remove();
      countObjects('page');
    });
    $(document).bind('page_added page_updated', function(event, data) {
      var entry = data.eportfolio_entry;
      var $page = $("#page_" + entry.id);
      if($page.length === 0) {
        $page = $("#page_blank").clone(true).removeAttr('id');
        $("#page_list").append($page.show());
      }
      $page.removeClass('unsaved');
      $page.fillTemplateData({
        data: entry,
        id: 'page_' + entry.id,
        hrefValues: ['id', 'slug']
      });
      // update links (unable to take advantage of fillTemplateData's hrefValues for updates)
      if(event.type == "page_updated"){
        var page_url = $("#page_blank .page_url").attr('href');
        var rename_page_url = $("#page_blank .rename_page_url").attr('href');
        page_url = $.replaceTags(page_url, 'slug', entry.slug);
        rename_page_url = $.replaceTags(page_url, 'id', entry.id);
        $page.find(".page_url").attr('href', page_url);
        $page.find(".rename_page_url").attr('href', rename_page_url);
      }
      var $entry = $("#structure_entry_" + entry.id);
      if($entry.length === 0) {
        $entry = $("#structure_entry_blank").clone(true).removeAttr('id');
        $("#structure_category_" + entry.eportfolio_category_id + " .entry_list").append($entry);
      }
      $entry.fillTemplateData({
        id: 'structure_entry_' + entry.id,
        data: entry
      });
      var $activePage = $("#eportfolio_entry_" + entry.id);
      if($activePage.length) {
        $activePage.fillTemplateData({
          id: 'eportfolio_entry_' + entry.id,
          data: entry
        });
      }
      countObjects('page');
    });
    $(".manage_pages_link,#section_pages .done_editing_button").click(function(event) {
      event.preventDefault();
      if($("#page_list").hasClass('editing')) {
        $("#page_list").removeClass('editing');
        $("#page_list .page").attr('title', '');
        $("#page_list").sortable('destroy');
        $("#section_pages").removeClass('editing');
      } else {
        $("#page_list").addClass('editing');
        $("#page_list .page").attr('title', I18n.t('links.manage_pages', 'Click to edit, drag to reorder'));
        $("#page_list").sortable({
          axis: 'y',
          helper: 'clone',
          stop: function(event, ui) {
            ui.item.addClass('just_dropped');
          },
          update: function(event, ui) {
            var ids = $("#page_list").sortable('toArray');
            var valid_ids = [];
            for(var idx in ids) {
              var id = ids[idx];
              id = id.substring(5);
              if(!isNaN(id)) { valid_ids.push(id); }
            }
            var order = valid_ids.join(",");
            var data = {order: order};
            $("#page_list").loadingImage({image_size: 'small'});
            $.ajaxJSON($(".reorder_pages_url").attr('href'), 'POST', data, function(data) {
              $("#page_list").loadingImage('remove');
            });
          }
        });
        $("#section_pages").addClass('editing');
      }
    });
    $("#page_list").delegate('.edit_page_link', 'click', function(event) {
      if($(this).parents("li").hasClass('unsaved')) {
        event.preventDefault();
      }
      if($(this).parents("#page_list").hasClass('editing')) {
        event.preventDefault();
        var $li = $(this).parents("li");
        if($li.hasClass('just_dropped')) {
          $li.removeClass('just_dropped');
          return;
        }
        editObject($li, 'page');
      }
    });
    $(".add_page_link").click(function(event) {
      event.preventDefault();
      var $page = $("#page_blank").clone(true).attr('id', 'page_new');
      $("#page_list").append($page.show());
      editObject($page, 'page');
    });
    $(".remove_page_link").click(function(event) {
      event.preventDefault();
      hideEditObject('page');
      $(this).parents("li").confirmDelete({
        message: I18n.t('confirm_delete_page', "Delete this page and all its content?"),
        url: $(this).parents("li").find(".rename_page_url").attr('href'),
        success: function(data) {
          $(this).fadeOut(function() {
            $(this).remove();
            $(document).triggerHandler('page_deleted', data);
            countObjects('page');
          });
        }
      });
    });
    $("#page_name").keydown(function(event) {
      if(event.keyCode == 27) { // esc
        hideEditObject('page');
      } else if(event.keyCode == 13) { // enter
        $(this).parents("li").find(".name").text($(this).val());
        var result = saveObject($(this).parents("li"), 'page');
        if(result) {
          hideEditObject('page');
        }
      }
    }).blur(function(event) {
      var result = true;
      var $page = $(this).parents("li.page");
      result = saveObject($page, 'page');
      if(result) {
        hideEditObject('page');
      }
    });
  });

  $(document).ready(function() {
    countObjects('section');
    $(document).bind('section_deleted', function(event, data) {
      var category = data.eportfolio_category;
      $("#section_" + category.id).remove();
      $("#structure_category_" + category.id).remove();
      countObjects('section');
    });
    $(document).bind('section_added section_updated', function(event, data) {
      var category = data.eportfolio_category;
      var $section = $("#section_" + category.id);
      if($section.length === 0) {
        $section = $("#section_blank").clone(true).removeAttr('id');
        $("#section_list").append($section.show());
      }
      $section.removeClass('unsaved');
      $section.fillTemplateData({
        data: category,
        id: 'section_' + category.id,
        hrefValues: ['id', 'slug']
      });
      var $category = $("#structure_category_" + category.id);
      if($category.length === 0) {
        $category = $("#structure_category_blank").clone(true).removeAttr('id');
        $("#eportfolio_structure").append($category);
      }
      $category.fillTemplateData({
        id: 'structure_category_' + category.id,
        data: category
      });
      var $category_select = $("#category_select_" + category.id);
      if($category_select.length === 0) {
        $category_select = $("#category_select_blank").clone(true).removeAttr('id');
        $("#category_select").append($category_select.show());
      }
      $category_select.attr('id', 'category_select_' + category.id)
        .val(category.id).text(category.name);
      countObjects('section');
    });
    $(".manage_sections_link,#section_list_manage .done_editing_button").click(function(event) {
      event.preventDefault();
      if($("#section_list").hasClass('editing')) {
        $("#section_list").sortable('destroy');
        $("#section_list_manage").removeClass('editing');
        $("#section_list").removeClass('editing').sortable('disable');
        var manage_sections = I18n.t('buttons.manage_sections', "Manage Sections");
        $(".arrange_sections_link").text(manage_sections).val(manage_sections);
        $(".add_section").hide();
        $("#section_list > li").attr('title', "");
      } else {
        $("#section_list_manage").addClass('editing');
        $("#section_list").sortable({
          axis: 'y',
          helper: 'clone',
          stop: function(event, ui) {
            ui.item.addClass('just_dropped');
          },
          update: function(event, ui) {
            var ids = $("#section_list").sortable('toArray');
            var valid_ids = [];
            for(var idx in ids) {
              var id = ids[idx];
              id = id.substring(8);
              if(!isNaN(id)) { valid_ids.push(id); }
            }
            var order = valid_ids.join(",");
            var data = {order: order};
            $("#section_list").loadingImage({image_size: 'small'});
            $.ajaxJSON($(".reorder_sections_url").attr('href'), 'POST', data, function(data) {
              $("#section_list").loadingImage('remove');
            });
          }
        });
        $("#section_list").addClass('editing').sortable('enable');
        var done_editing = I18n.t('buttons.done_editing', "Done Editing");
        $(".arrange_sections_link").text(done_editing).val(done_editing);
        $(".add_section").show();
        $("#section_list > li").attr('title', I18n.t('titles.section_list', "Drag to Arrange, Click to Edit"));
      }
    });
    $(".add_section_link").click(function(event) {
      event.preventDefault();
      var $section = $("#section_blank").clone(true).attr('id', 'section_new');
      $("#section_list").append($section.show());
      editObject($section, 'section');
    });
    $(".remove_section_link").click(function(event) {
      event.preventDefault();
      hideEditObject('section');
      $(this).parents("li").confirmDelete({
        message: I18n.t('confirm_delete_section', "Delete this section and all its pages?"),
        url: $(this).parents("li").find(".rename_section_url").attr('href'),
        success: function(data) {
          $(this).fadeOut(function() {
            $(this).remove();
            $(document).triggerHandler('section_deleted', data);
            countObjects('section');
          });
        }
      });
    });
    $("#section_list").delegate('.edit_section_link', 'click', function(event) {
      if($(this).parents("li").hasClass('unsaved')) {
        event.preventDefault();
      }
      if($(this).parents("#section_list").hasClass('editing')) {
        event.preventDefault();
        var $li = $(this).parents("li");
        if($li.hasClass('just_dropped')) {
          $li.removeClass('just_dropped');
          return;
        }
        editObject($li, 'section');
      }
    });
    $("#section_name").keydown(function(event) {
      if(event.keyCode == 27) { // esc
        hideEditObject('section');
      } else if(event.keyCode == 13) { // enter
        $(this).parents("li").find(".name").text($(this).val());
        var result = saveObject($(this).parents("li"), 'section');
        if(result) {
          hideEditObject('section');
        }
      }
    }).blur(function(event) {
      var result = true;
      var $section = $(this).parents("li.section");
      result = saveObject($section, 'section');
      if(result) {
        hideEditObject('section');
      }
    });
    $(".download_eportfolio_link").click(function(event) {
      $(this).slideUp();
      event.preventDefault();
      $("#export_progress").progressbar().progressbar('option', 'value', 0);
      var $box = $("#downloading_eportfolio_message")
      $box.slideDown();
      $box.find(".message").text(I18n.t('#eportfolios.show.headers.export_progress', "Collecting ePortfolio resources. this may take a while if you have a lot of files in your ePortfolio."));
      var url = $(this).attr('href');
      var errorCount = 0;
      var check = function(first) {
        req_url = url;
        if (first) {
          req_url = url + "?compile=1";
        }
        $.ajaxJSON(req_url, 'GET', {}, function(data) {
          if(data.attachment && data.attachment.file_state && data.attachment.file_state == "available") {
            $("#export_progress").progressbar('option', 'value', 100);
            location.href = url + ".zip";
            return;
          } else if(data.attachment && data.attachment.file_state) {
            var progress = parseInt(data.attachment.file_state, 10);
            $("#export_progress").progressbar('option', 'value', Math.max(Math.min($("#export_progress").progressbar('option', 'value') + .1, 90), progress));
          } else {
            $("#export_progress").progressbar('option', 'value', Math.min($("#export_progress").progressbar('option', 'value') + .1, 90));
          }
          setTimeout(check, 2000);
        }, function(data) {
          errorCount++;
          if(errorCount > 5) {
            $box.find(".message").text(I18n.t('errors.compiling', "There was an error compiling your eportfolio.  Please try again in a little while."));
          } else {
            setTimeout(check, 5000);
          }
        });
      };
      check(true);
    });
    $(".download_eportfolio_link").click(function(event) {
      $("#downloading_eportfolio_dialog").dialog({
        title: I18n.t('titles.download_eportfolio', "Download ePortfolio")
      });
    });
  });
});
