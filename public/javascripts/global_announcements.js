define([
  'i18n!account_settings',
  'jquery',
  'jsx/shared/rce/RichContentEditor',
  'jquery.instructure_forms', // errorBox, validateForm
  'jquery.instructure_misc_plugins' // confirmDelete, showIf
], function(I18n, $, RichContentEditor) {
  // optimization so user isn't waiting on RCS to
  // respond when they hit announcements
  RichContentEditor.preloadRemoteModule()

  // account_settings.js mixes a lot of dom management for each of it's
  // tabs, so this file is meant to encapsulate just the javascript
  // used for working with the Announcements tab
  return {
    bindDomEvents: function(){
      $(".add_notification_toggle_focus").click(function() {
        var aria_expanded = $('add_notification_form').attr('aria-expanded') === "true";
        if(!aria_expanded) {
          setTimeout(function() {$('#account_notification_subject').focus()}, 100);
        }
      });

      $(".edit_notification_toggle_focus").click(function() {
        var id = $(this).attr('data-edit-toggle-id');
        var form_id = '#edit_notification_form_' + id;
        var aria_expanded = $(form_id).attr('aria-expanded') === "true";
        if(!aria_expanded) {
          setTimeout(function() {$('#account_notification_subject_' + id).focus()}, 100);
        }
      });

      $(".add_notification_cancel_focus").click(function() {
        $("#add_announcement_button").focus();
      });

      $(".edit_cancel_focus").click(function() {
        var id = $(this).attr('data-cancel-focus-id');
        $("#notification_edit_" + id).focus();
      });

      $("#add_notification_form, .edit_notification_form").submit(function(event) {
        var $this = $(this);
        var $confirmation = $this.find('#confirm_global_announcement:visible:not(:checked)');
        if ($confirmation.length > 0) {
          $confirmation.errorBox(I18n.t('confirms.global_announcement', "You must confirm the global announcement"));
          return false;
        }
        var validations = {
          object_name: 'account_notification',
          required: ['start_at', 'end_at', 'subject', 'message'],
          date_fields: ['start_at', 'end_at'],
          numbers: []
        };
        if ($this[0].id == 'add_notification_form' && $('#account_notification_months_in_display_cycle').length > 0) {
          validations.numbers.push('months_in_display_cycle');
        }
        var result = $this.validateForm(validations);
        if(!result) {
          return false;
        }
      });

      $("#account_notification_required_account_service").click(function(event) {
        $this = $(this);
        $("#confirm_global_announcement_field").showIf(!$this.is(":checked"));
        $("#account_notification_months_in_display_cycle").prop("disabled", !$this.is(":checked"));
      });

      $(".delete_notification_link").click(function(event) {
        event.preventDefault();
        var $link = $(this);
        $link.parents("li").confirmDelete({
          url: $link.attr('rel'),
          message: I18n.t('confirms.delete_announcement', "Are you sure you want to delete this announcement?"),
          success: function() {
            $(this).slideUp(function() {
              $(this).remove();
            });
          }
        });
      });
    },

    augmentView: function(){
      $("textarea.edit_notification_form, #add_notification_form textarea").each(function(i){
        RichContentEditor.loadNewEditor($(this));
      })
    }
  };
});
