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
  'i18n!wiki_pages',
  'jquery' /* $ */,
  'wikiSidebar',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_date_and_time' /* parseFromISO */,
  'jquery.instructure_forms' /* formSubmit, formErrors */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */,
  'jquery.templateData' /* fillTemplateData */,
  'tinymce.editor_box' /* editorBox */
], function(I18n, $, wikiSidebar) {

  // private variables & methods
  function initEditViewSecondary(){
    $("#wiki_page_rename_link").click(function(e){
      e.preventDefault();
      $("#wiki_page_rename_section").slideToggle("fast", function() {
        $(this).find(":text:visible:first").focus().select();
      });
    });
    wikiSidebar.init();
    wikiSidebar.attachToEditor($("#wiki_page_body"));
  };
  
  function initShowViewSecondary(){
    $("#wiki_show_view_secondary a.edit_link").click(function(event){
      event.preventDefault();
      toggleView();
    });
    $("#wiki_page_new").find("a.new")
      .click(function(e){
        e.preventDefault();
        $("#wiki_page_new").find("form").slideToggle("fast", function() {
          $("#wiki_page_new :text:visible:first").focus().select();
        });
      }).end()
      .find("form").hide();
  }
  
  function initForm(){
    // we need to temporarily show the form so that the layout will be computed correctly.
    // this all happens within 1 event loop, so it doesn't cause a flash of content.
    $("#wiki_edit_view_main").show();
    $("#wiki_page_body").editorBox({
      fullHeight: true,
      elementToLeaveInViewport: $("#below_editor")
    });
    $("#wiki_edit_view_main").hide();
    $('#wiki_edit_view_main #cancel_editing').click(function(event){
      event.preventDefault();
      toggleView();
    });
    $('#wiki_edit_view_main .wiki_switch_views_link').click(function(event) {
      event.preventDefault();
      $("#wiki_page_body").editorBox('toggle');
    });
    if ($("a#page_doesnt_exist_so_start_editing_it_now").length) {
      $("a#page_doesnt_exist_so_start_editing_it_now").click(function(event){
        event.preventDefault();
        toggleView();
      });
      $(function(){
        // trigger its hanlder on page load so that it toggles to the edit view. 
        // its kinda hoaky because tinymce has to be initialized before the whole dom is loaded and so we have to 
        // trigger it in a callback to the domloaded event.
        $("a#page_doesnt_exist_so_start_editing_it_now:not(.dont_click)").triggerHandler("click");
      });
    }
  }
  
  function toggleView(){
    $("#wiki_edit_view_main, #wiki_show_view_main, #wiki_show_view_secondary, #wiki_edit_view_secondary").toggle();
    $("#wiki_edit_view_page_tools").showIf($("#wiki_edit_view_page_tools li").length > 0);
    wikiSidebar.toggle();
    $(window).triggerHandler("resize");
  }

  // public variables & methods
  var wikiPage = {
    init: function(){
      // init up the form now
      initForm();
      // init the rest on domReady 
      $(function(){
        initEditViewSecondary();
        initShowViewSecondary();
      });
    },
  
    updateComment: function($comment, comment, top) {
      if(!$comment || $comment.length == 0) {
        $comment = $("#wiki_page_comment_blank").clone(true).removeAttr('id');
        if(top) {
          $("#add_wiki_page_comment_form").after($comment);
        } else {
          $("#wiki_page_comments .wiki_page_comment:last").after($comment);
        }
        $comment.show();
      }
      comment.created_at_formatted = $.parseFromISO(comment.created_at).datetime_formatted;
      $comment.fillTemplateData({
        data: comment,
        id: 'wiki_page_commment_' + comment.id,
        hrefValues: ['id'],
        htmlValues: ['formatted_body']
      });
      $comment.toggleClass('current', comment.workflow_state == 'current');
      $comment.toggleClass('deletable_comment', !!(comment.permissions && comment.permissions['delete']));
    }
  };
  
  // miscellaneous things to do on domready
  $(document).ready(function() {
    $(document).fragmentChange(function(event, hash){
      if (hash === "#edit") {
        $("#wiki_show_view_secondary a.edit_link:visible").click();
      }
    });
    var interactionHappened = false;
    $(document).bind('mousemove focus keypress', function() {
      interactionHappened = true;
    });
    var checkForChanges = function() {
      if(!interactionHappened) {
        setTimeout(checkForChanges, 120000);
        return;
      }
      interactionHappened = false;
      $.ajaxJSON($("#latest_page_version").attr('href'), 'GET', {}, function(data) {
        var oldVersion = parseInt($("#wiki_page_version_number").text(), 10);
        var newVersion = data && data && data.wiki_page && data.wiki_page.version_number;
        var changed = oldVersion && newVersion && newVersion > oldVersion;
        if(changed) { 
          $(".someone_else_edited").slideDown();
          setTimeout(checkForChanges, 240000);
        } else {
          setTimeout(checkForChanges,  120000);
        }
      }, function(data) {
        setTimeout(checkForChanges, 60000);
      });
    };
    setTimeout(checkForChanges, 5000);

    $(".more_pages_link").click(function(event) {
      event.preventDefault();
      $(this).parents("ul").find("li").show();
      $(this).parent("li").remove();
    });
    $(".add_comment_link,.wiki_page_comment .cancel_button").click(function(event) {
      event.preventDefault();
      $(this).parents(".wiki_page_comment")
        .toggleClass('commenting')
        .find("textarea:visible")
          .val("").focus().select();
    });
    $(".delete_comment_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".wiki_page_comment").confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t('delete_comment_confirmation', "Are you sure you want to delete this comment?"),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $("#add_wiki_page_comment_form").formSubmit({
      beforeSubmit: function(data) {
        $(this).find("button").attr('disabled', true).filter(".submit_button").text(I18n.t('notices.adding_comment', "Adding Comment..."));
      },
      success: function(data) {
        $(this).find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('buttons.add_comment', "Add Comment"));
        wikiPage.updateComment(null, data.wiki_page_comment, true);
        $(this).removeClass('commenting');
      },
      error: function(data) {
        $(this).formErrors(data);
        $(this).find("button").attr('disabled', false).filter(".submit_button").text(I18n.t('notices.add_comment_failed', "Add comment failed, please try again"));
      }
    });
    $("#add_wiki_page_form,#rename_wiki_page_form").formSubmit({
      success: function(data) {
        location.href = data.success_url;
      },
      error: function(data) {
        $(this).formErrors(data);
      }
    });
  });

  return wikiPage;
});
