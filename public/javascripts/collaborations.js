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
  'i18n!collaborations',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* fillFormData, getFormData, errorBox */,
  'jquery.instructure_jquery_patches' /* /\.dialog/ */,
  'jquery.instructure_misc_plugins' /* .dim, confirmDelete, fragmentChange, showIf */,
  'jquery.templateData' /* getTemplateData */,
  'vendor/jquery.scrollTo' /* /\.scrollTo/ */
], function(I18n, $) {

  function removeCollaborationDiv(div) {
    if($("#collaborations .collaboration:visible").length <= 1) {
      $("#no_collaborations_message").slideDown();
      $(".add_collaboration_link").click();
    }
    div.slideUp(function() {
      div.remove();
    });
  }

  $(document).ready(function() {
    $("#add_collaboration_form").submit(function(event) {
      var data = $(this).getFormData();
      if(!data['collaboration[title]']) {
        event.preventDefault();
        event.stopPropagation();
        $(this).find("#collaboration_title").errorBox(I18n.t('errors.no_name', "Please enter a name for this document"));
        $("html,body").scrollTo($(this));
        return false;
      }
      setTimeout(function() {
        //reload the page but get rid of anything in the hash so that it doesnt automatically
        //open the Start a New Collaboration section when it reloads
        window.location = window.location.href.replace(window.location.hash, "");
      }, 2500);
    });
    $(".toggle_collaborators_link").live('click', function() {
      $(this).parents(".collaboration").find(".collaborators").slideToggle();
    });
    $(".add_collaboration_link").click(function(event) {
      event.preventDefault();
      if($(this).is(":hidden")) return;
      $(this).hide();
      $("#add_collaboration_form").slideToggle(function() {
        $("html,body").scrollTo($(this));
        $(this).find(":text:visible:first").focus().select();
      });
    });
    $("#add_collaboration_form .cancel_button").click(function(event) {
      $(".add_collaboration_link").show();
      $("#add_collaboration_form").slideToggle();
    });
    $("#delete_collaboration_dialog .cancel_button").click(function() {
      $("#delete_collaboration_dialog").dialog('close');
    });
    $("#delete_collaboration_dialog .delete_button").click(function() {
      var delete_document = $(this).hasClass('delete_document_button'),
          data = {delete_doc: delete_document},
          $collaboration = $("#delete_collaboration_dialog").data('collaboration'),
          url = $collaboration.find(".delete_collaboration_link").attr('href');
      $collaboration.dim();
      $("#delete_collaboration_dialog").dialog('close');
      $.ajaxJSON(url, 'DELETE', data, function(data) {
        removeCollaborationDiv($collaboration);
      }, function(data) {
      });
    });
    $(".delete_collaboration_link").click(function(event) {
      event.preventDefault();
      var $collaboration = $(this).parents(".collaboration");
      if($(this).parents(".collaboration").hasClass('google_docs')) {
        $("#delete_collaboration_dialog").data('collaboration', $collaboration);
        $("#delete_collaboration_dialog").dialog('close').dialog({
          autoOpen: false,
          title: "Delete Collaboration?",
          width: 350
        }).dialog('open');
      } else {
        $collaboration.confirmDelete({
          message: "Are you sure you want to delete this collaboration?",
          url: $(this).attr('href'),
          success: function(data) {
            removeCollaborationDiv($(this));
          }
        });
      }
    });
    $(".edit_collaboration_link").click(function(event) {
      event.preventDefault();
      var $form = $("#edit_collaboration_form").clone(true);
      $form.attr('action', $(this).attr('href'));
      var $collaboration = $(this).parents(".collaboration");
      $form.attr('class', $collaboration.attr('class'));
      var ids = [];
      var data = $collaboration.getTemplateData({textValues: ['title', 'description']});
      $form.fillFormData(data, {object_name: 'collaboration'});
      var collaborators = $collaboration.find(".collaborators li").each(function() {
        var id = $(this).getTemplateData({textValues: ['id']}).id;
        if(id) {
          ids.push(id);
        }
      });
      $form.find(":checkbox").each(function() {
        $(this).attr('checked', false);
      });
      for(var idx in ids) {
        var id = ids[idx];
        $form.find(".collaborator_" + id + " :checkbox").attr('checked', true);
      }
      $collaboration.hide().after($form.show());
    });
    $("#edit_collaboration_form .cancel_button").click(function() {
      var $form = $(this).parents("form");
      $form.hide().prev(".collaboration").show();
      $form.remove();
    });
    $(document).fragmentChange(function(event, hash) {
      if(hash == "#add_collaboration") {
        $(".add_collaboration_link").click();
      }
    });
    $(".collaboration .show_participants_link.verbose_footer_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".collaboration").find(".collaborators").slideToggle();
    });
    $("#collaboration_collaboration_type").change(function(event) {
      var name = $(this).val();
      var type = name;
      if(INST.collaboration_types) {
        for(var idx in INST.collaboration_types) {
          var collab = INST.collaboration_types[idx];
          if(collab.name == name) {
            type = collab.type;
          }
        }
      }
      $("#add_collaboration_form .collaboration_type").hide();
      var $description = $("#add_collaboration_form #" + type + "_description");
      $description.show();
      $(".collaborate_data").showIf(!$description.hasClass('unauthorized'));
      $(".collaboration_authorization").hide();
      $("#collaborate_authorize_" + type).showIf($description.hasClass('unauthorized'));
    }).change();
    $(".select_all_link,.deselect_all_link").click(function(event) {
      event.preventDefault();
      var checked = $(this).hasClass('select_all_link');
      $(this).parents("form").find(":checkbox").each(function() {
        $(this).attr('checked', checked);
      });
    });
    if($("#collaborations .collaboration:visible").length < 1)
      $(".add_collaboration_link").click();
  });
});

