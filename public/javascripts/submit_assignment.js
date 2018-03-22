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


import I18n from 'i18n!assignments'
import $ from 'jquery'
import _ from 'underscore'
import GoogleDocsTreeView from 'compiled/views/GoogleDocsTreeView'
import homework_submission_tool from 'jst/assignments/homework_submission_tool'
import HomeworkSubmissionLtiContainer from 'compiled/external_tools/HomeworkSubmissionLtiContainer'
import RCEKeyboardShortcuts from 'compiled/views/editor/KeyboardShortcuts' /* TinyMCE Keyboard Shortcuts for a11y */
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import { uploadFile } from 'jsx/shared/upload_file'
import {submitContentItem, recordEulaAgreement} from './submit_assignment_helper'
import 'compiled/jquery.rails_flash_notifications'
import './jquery.ajaxJSON'
import './jquery.inst_tree'
import './jquery.instructure_forms' /* ajaxJSONPreparedFiles, getFormData */
import 'jqueryui/dialog'
import './jquery.instructure_misc_plugins' /* fragmentChange, showIf, /\.log\(/ */
import './jquery.templateData'
import './media_comments'
import './vendor/jquery.scrollTo'
import 'jqueryui/tabs'

  var SubmitAssignment = {
    toolDropDownClickHandler: function(event) {
      event.preventDefault();

      var tool = $(this).data('tool');
      var url = "/courses/" + ENV.COURSE_ID + "/external_tools/" + tool.id + "/resource_selection?homework=1&assignment_id=" + ENV.SUBMIT_ASSIGNMENT.ID;

      var width = tool.get('homework_submission').selection_width || tool.get('selection_width');
      var height = tool.get('homework_submission').selection_height || tool.get('selection_height');
      var title = tool.get('display_text');
      var $div = $("<div/>", {id: "homework_selection_dialog", style: "padding: 0; overflow-y: hidden;"}).appendTo($("body"));

      $div.append($("<iframe/>", {
        frameborder: 0,
        src: url,
        id: "homework_selection_iframe",
        tabindex: '0'
      }).css({width: width, height: height}))
        .bind('selection', function(event, data) {
          submitContentItem(event.contentItems[0]);
          $div.off('dialogbeforeclose', SubmitAssignment.dialogCancelHandler)
          $div.dialog('close');
        })
        .on('dialogbeforeclose', SubmitAssignment.dialogCancelHandler)
        .dialog({
          width: 'auto',
          height: 'auto',
          title: title,
          close: function() {
            $div.remove();
          }
        });

      var tabHelperHeight = 35;
      $div.append(
      $('<div/>',
        {id: 'tab-helper', style: 'height:0px;padding:5px', tabindex: '0'}
      ).focus(function () {
        $(this).height(tabHelperHeight + 'px')
        var joke = document.createTextNode(I18n.t('Q: What goes black, white, black, white?  A: A panda rolling down a hill.'))
        this.appendChild(joke)
      }).blur(function () {
        $(this).html('').height('0px');
      }))

      return $div;
    },
    beforeUnloadHandler: function(e) {
      return (e.returnValue = I18n.t("Changes you made may not be saved."));
    },
    dialogCancelHandler: function(event, ui) {
      var r = confirm(I18n.t("Are you sure you want to cancel? Changes you made may not be saved."));
      if (r == false){
        event.preventDefault();
      }
    }
  };

  window.submissionAttachmentIndex = -1;

  RichContentEditor.preloadRemoteModule();

  $(document).ready(function() {
    var submitting = false,
        submissionForm = $('.submit_assignment_form');

    var homeworkSubmissionLtiContainer = new HomeworkSubmissionLtiContainer('#submit_from_external_tool_form');

    // Add the Keyboard shortcuts info button
    var keyboardShortcutsView = new RCEKeyboardShortcuts();
    keyboardShortcutsView.render().$el.insertBefore($(".switch_text_entry_submission_views:first"));

    // grow and shrink the comments box on focus/blur if the user
    // hasn't entered any content.
    submissionForm.delegate('#submission_comment', 'focus', function(e) {
      var box = $(this);
      if (box.val().trim() === '') { box.addClass('focus_or_content'); }
    }).delegate('#submission_comment', 'blur', function(e) {
      var box = $(this);
      if (box.val().trim() === '') { box.removeClass('focus_or_content'); }
    });

    submissionForm.submit(function(event) {
      var self = this;
      var $turnitin = $(this).find(".turnitin_pledge");
      var $vericite = $(this).find(".vericite_pledge");
      if($("#external_tool_submission_type").val() == "online_url_to_file") {
        event.preventDefault();
        event.stopPropagation();
        uploadFileFromUrl();
        return;
      }
      if($turnitin.length > 0 && !$turnitin.attr('checked')) {
        alert(I18n.t('messages.agree_to_pledge', "You must agree to the submission pledge before you can submit this assignment."));
        event.preventDefault();
        event.stopPropagation();
        return false;
      }

      if($vericite.length > 0 && !$vericite.attr('checked')) {
        alert(I18n.t('messages.agree_to_pledge', "You must agree to the submission pledge before you can submit this assignment."));
        event.preventDefault();
        event.stopPropagation();
        return false;
      }

      var valid = !$(this).is('#submit_online_text_entry_form') || $(this).validateForm({
        object_name: 'submission',
        required: ['body']
      });
      if (!valid) return false;

      $(this).find("button[type='submit']").text(I18n.t('messages.submitting', "Submitting..."));
      $(this).find("button").attr('disabled', true);
      if($(this).attr('id') == 'submit_online_upload_form') {
        event.preventDefault() && event.stopPropagation();
        var fileElements = $(this).find('input[type=file]:visible').filter(function() {
          return $(this).val() !== '';
        });

        var emptyFiles = $(this).find('input[type=file]:visible').filter(function() {
          return this.files[0] && this.files[0].size === 0;
        });

        var uploadedAttachmentIds = $(this).find('#submission_attachment_ids').val();

        var reenableSubmitButton = function () {
          $(self).find('button[type=submit]')
              .text(I18n.t('#button.submit_assignment', 'Submit Assignment'))
              .prop('disabled', false);
        };

        // warn user if they haven't uploaded any files
        if (fileElements.length === 0 && uploadedAttachmentIds === '') {
          $.flashError(I18n.t('#errors.no_attached_file', 'You must attach at least one file to this assignment'));
          reenableSubmitButton();
          return false;
        }

        // throw error if the user tries to upload an empty file
        // to prevent S3 from erroring
        if (emptyFiles.length) {
          $.flashError(I18n.t('Attached files must be greater than 0 bytes'));
          reenableSubmitButton();
          return false;
        }

        // If there are restrictions on file type, don't accept submission if the file extension is not allowed
        if(ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS.length > 0) {
          var subButton = $(this).find('button[type=submit]');
          var badExt = false;
          $.each(uploadedAttachmentIds.split(","), function(index, id) {
            if (id.length > 0) {
              var ext = $("#uploaded_files .file_" + id + " .name").text().split('.').pop().toLowerCase();
              if ($.inArray(ext, ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS) < 0) {
                badExt = true;
                $.flashError(I18n.t('#errors.wrong_file_extension', 'The file you selected with extension "%{extension}", is not authorized for submission', {extension: ext}));
              }
            }
          });
          if(badExt) {
            subButton
              .text(I18n.t('#button.submit_assignment', 'Submit Assignment'))
              .prop('disabled', false);
            return false;
          }
        }

        $.ajaxJSONPreparedFiles.call(this, {
          handle_files: function(attachments, data) {
            var ids = (data['submission[attachment_ids]'] || "").split(",");
            for(var idx in attachments) {
              ids.push(attachments[idx].id);
            }
            data['submission[attachment_ids]'] = ids.join(",");
            return data;
          },
          context_code: $("#submit_assignment").data('context_code'),
          asset_string: $("#submit_assignment").data('asset_string'),
          intent: "submit",
          file_elements: fileElements,
          formData: $(this).getFormData(),
          formDataTarget: 'url',
          url: $(this).attr('action'),
          success: function(data) {
            submitting = true;
            window.location = window.location.href.replace(/\#$/g, "").replace(window.location.hash, "");
          },
          error: function(data) {
            submissionForm.find("button[type='submit']").text(I18n.t('messages.submit_failed', "Submit Failed, please try again"));
            submissionForm.find("button").attr('disabled', false);
          }
        });
      } else {
        submitting = true;
      }
    });

    $(window).on('beforeunload', function(e) {
      if($("#submit_assignment:visible").length > 0 && !submitting) {
        e.returnValue = I18n.t('messages.not_submitted_yet', "You haven't finished submitting your assignment.  You still need to click \"Submit\" to finish turning it in.  Do you want to leave this page anyway?");
        return e.returnValue;
      }
    });

    $(document).fragmentChange(function(event, hash) {
      if(hash && hash.indexOf("#submit") == 0) {
        $(".submit_assignment_link").triggerHandler('click', true);
        if(hash == "#submit_google_doc") {
          $("#submit_assignment_tabs").tabs('select', ".google_doc_form");
        }
      }
    });

    $('input.turnitin_pledge').click((e) => {
      recordEulaAgreement('#eula_agreement_timestamp',
                          e.target.checked);
    })

    $(".submit_assignment_link").click(function(event, skipConfirmation) {
      event.preventDefault();
      var late = $(this).hasClass('late');
      var now = new Date();
      if(late && !skipConfirmation) {
        var result;
        if($(".resubmit_link").length > 0) {
          result = confirm(I18n.t('messages.now_overdue', "This assignment is now overdue.  Any new submissions will be marked as late.  Continue anyway?"));
        } else {
          result = confirm(I18n.t('messages.overdue', "This assignment is overdue.  Do you still want to submit it?"));
        }
        if(!result) { return; }
      }
      $("#submit_assignment").show();
      $(".submit_assignment_link").hide();
      $("html,body").scrollTo($("#submit_assignment"));
      createSubmitAssignmentTabs();
      homeworkSubmissionLtiContainer.loadExternalTools();
      $("#submit_assignment_tabs li").first().focus();
    });

    $(".switch_text_entry_submission_views").click(function(event) {
      event.preventDefault();
      RichContentEditor.callOnRCE($("#submit_online_text_entry_form textarea:first"), 'toggle')
      //  todo: replace .andSelf with .addBack when JQuery is upgraded.
      $(this).siblings(".switch_text_entry_submission_views").andSelf().toggle();
    });

    $(".submit_assignment_form .cancel_button").click(function() {
      $("#submit_assignment").hide();
      $(".submit_assignment_link").show();
    });

    function createSubmitAssignmentTabs() {
      $("#submit_assignment_tabs").tabs({
        beforeActivate: function( event, ui ) {
          // determine if this is an external tool
          if ($(event.currentTarget).hasClass('external-tool')) {
            var externalToolId = $(event.currentTarget).data('id');
            homeworkSubmissionLtiContainer.embedLtiLaunch(externalToolId)
          }
        },
        activate: function(event, ui) {
          if (ui.newTab.find('a').hasClass('submit_online_text_entry_option')) {
            var $el = $("#submit_online_text_entry_form textarea:first");
            if (!RichContentEditor.callOnRCE($el, 'exists?')) {
              RichContentEditor.loadNewEditor($el, {manageParent: true});
            }
          }

          if (ui.newTab.attr("aria-controls") === "submit_google_doc_form") {
            listGoogleDocs();
          }
        },
        create: function(event, ui) {
          if (ui.tab.find('a').hasClass('submit_online_text_entry_option')) {
            var $el = $("#submit_online_text_entry_form textarea:first");
            if (!RichContentEditor.callOnRCE($el, 'exists?')) {
              RichContentEditor.loadNewEditor($el, {manageParent: true});
            }
          }

          //list Google Docs if Google Docs tab is active
          if (ui.tab.attr("aria-controls") === "submit_google_doc_form") {
            listGoogleDocs();
          }
        }
      });
    }

    $("#uploaded_files > ul").instTree({
      autoclose: false,
      multi: true,
      dragdrop: false,
      onClick: function(e, node) {
        $("#submission_attachment_ids").val("");
        var ids = []; //submission_attachment_ids

        $("#uploaded_files .file.active-leaf").each(function() {
          var id = $(this).getTemplateData({textValues: ['id']}).id;
          ids.push(id);
        });
        $("#submission_attachment_ids").val(ids.join(","));
      }
    });

    $(".toggle_uploaded_files_link").click(function(event) {
      event.preventDefault();
      $("#uploaded_files").slideToggle();
    });

    $(".add_another_file_link").click(function(event) {
      event.preventDefault();
      $('#submission_attachment_blank').clone(true).removeAttr('id').show().insertBefore(this)
        .find("input").attr('name', 'attachments[' + (++submissionAttachmentIndex) + '][uploaded_data]');
      toggleRemoveAttachmentLinks();
    }).click();

    $(".remove_attachment_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".submission_attachment").remove();
      checkAllowUploadSubmit();
      toggleRemoveAttachmentLinks();
    });

    function listGoogleDocs(){
      var url = window.location.pathname + "/list_google_docs";
      $.get(url,{}, function(data, textStatus){

        var tree = new GoogleDocsTreeView({model: data});
        $('div#google_docs_container').html(tree.el);
        tree.render();
        tree.on('activate-file', function(file_id){
          $("#submit_google_doc_form").find("input[name='google_doc[document_id]']").val(file_id);
          var submitButton = $("#submit_google_doc_form").find("[disabled].btn-primary");
          if(submitButton) {
            submitButton.removeAttr("disabled")
          }
        });

      }, 'json');
    }

    $("#auth-google").live('click', function(e){
      e.preventDefault();
      var href = $(this).attr("href");
      reauth(href);
    });

    // Post message for anybody to listen to //
    if (window.opener) {
      try {
        window.opener.postMessage({
          "type": "event",
          "payload": "done"
        }, window.opener.location.toString());
      } catch (e) {
        console.error(e);
      }
    }


    function reauth(auth_url) {
      var modal = window.open(auth_url, "Authorize Google Docs", 'menubar=no,directories=no,location=no,height=500,width=500');
      $(window).on("message", function (event){
        event = event.originalEvent;
        if(!event || !event.data || event.origin !== window.location.protocol + "//" + window.location.host) return;

        if(event.data.type == "event" && event.data.payload == "done") {
          if (modal)
            modal.close();

          reloadGoogleDrive();
        }
      });
    }

    function reloadGoogleDrive() {
      $("#submit_google_doc_form.auth").hide();
      $("#submit_google_doc_form.submit_assignment_form").removeClass('hide');
      listGoogleDocs();
    }

    function toggleRemoveAttachmentLinks(){
      $('#submit_online_upload_form .remove_attachment_link').showIf($('#submit_online_upload_form .submission_attachment:not(#submission_attachment_blank)').length > 1);
    }
    function checkAllowUploadSubmit() {
      // disable the submit button if any extensions are bad
      $('#submit_online_upload_form button[type=submit]').attr('disabled', !!$(".bad_ext_msg:visible").length);
    }
    function updateRemoveLinkAltText(fileInput) {
      var altText = I18n.t("remove empty attachment");
      if(fileInput.val()){
        var filename = fileInput.val().replace(/^.*?([^\\\/]*)$/, '$1');
        altText = I18n.t("remove %{filename}", {filename: filename})
      }
      fileInput.parent().find('img').attr("alt", altText)
    }
    $(".submission_attachment input[type=file]").live('change', function() {
      updateRemoveLinkAltText($(this));
      if (ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS.length < 1 || $(this).val() == "")
        return;

      var ext = $(this).val().split('.').pop().toLowerCase();
      $(this).parent().find('.bad_ext_msg').showIf($.inArray(ext, ENV.SUBMIT_ASSIGNMENT.ALLOWED_EXTENSIONS) < 0);
      checkAllowUploadSubmit();
    });
  });

  $("#submit_google_doc_form").submit(function() {
    // make sure we have a document selected
    if (!$("#submit_google_doc_form").find("input[name='google_doc[document_id]']").val()){
      return false
    }

    $("#uploading_google_doc_message").dialog({
      title: I18n.t('titles.uploading', "Uploading Submission"),
      modal: true,
      overlay: {
        backgroundColor: "#000",
        opacity: 0.7
      }
    });
  });

  $(document).ready(function() {
    $("#submit_media_recording_form .submit_button").attr('disabled', true).text(I18n.t('messages.record_before_submitting', "Record Before Submitting"));
    $("#media_media_recording_submission_holder .record_media_comment_link").click(function(event) {
      event.preventDefault();
      $("#media_media_recording_submission").mediaComment('create', 'any', function(id, type) {
        $("#submit_media_recording_form .submit_button").attr('disabled', false).text(I18n.t('buttons.submit_assignment', "Submit Assignment"));
        $("#submit_media_recording_form .media_comment_id").val(id);
        $("#submit_media_recording_form .media_comment_type").val(type);
        $("#media_media_recording_submission_holder").children().hide();
        $("#media_media_recording_ready").show();
        $("#media_comment_submit_button").attr('disabled', false);
        $("#media_media_recording_thumbnail").attr('id', 'media_comment_' + id);
      });
    });
  });

  var $tools = $("#submit_from_external_tool_form");

  function uploadFileFromUrl() {
    const preflightUrl = $("#homework_file_url").attr('href');
    const preflightData = {
      url: $("#external_tool_url").val(),
      name: $("#external_tool_filename").val(),
      content_type: $("#external_tool_content_type").val()
    };
    const uploadPromise = uploadFile(preflightUrl, preflightData, null)
      .then((attachment) => {
        $("#external_tool_submission_type").val('online_upload');
        $("#external_tool_file_id").val(attachment.id);
        $tools.submit();
      })
      .catch((error) => {
        console.log(error);
        $tools.find(".submit").text(I18n.t('file_retrieval_error', "Retrieving File Failed"));
        $.flashError(I18n.t("invalid_file_retrieval", "There was a problem retrieving the file sent from this tool."));
      });
    $tools.disableWhileLoading(uploadPromise, {buttons: {'.submit': I18n.t('getting_file', 'Retrieving File...')}});
    return uploadPromise;
  };

  $("#submit_from_external_tool_form .tools li").live('click', SubmitAssignment.toolDropDownClickHandler);

export default SubmitAssignment;
