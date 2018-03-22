/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import 'jqueryui/dialog'
import I18n from 'i18n!account_settings'
import $ from 'jquery'
import htmlEscape from 'str/htmlEscape'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import 'jqueryui/tabs'
import globalAnnouncements from './global_announcements'
import './jquery.ajaxJSON'
import './jquery.instructure_date_and_time' // date_field, time_field, datetime_field, /\$\.datetime/
import './jquery.instructure_forms' // formSubmit, getFormData, validateForm
import './jquery.instructure_misc_helpers' // replaceTags
import './jquery.instructure_misc_plugins' // confirmDelete, showIf, /\.log/
import './jquery.loadingImg'
import './vendor/date' // Date.parse
import './vendor/jquery.scrollTo'

  export function openReportDescriptionLink (event) {
    event.preventDefault();
    var title = $(this).parents('.title').find('span.title').text();
    var $desc = $(this).parent('.reports').find('.report_description');
    $desc.clone().dialog({
      title: title,
      width: 800
    });
  }

  export function addUsersLink (event) {
    event.preventDefault();
    var $enroll_users_form = $('#enroll_users_form');
    $(this).hide();
    $enroll_users_form.show();
    $('html,body').scrollTo($enroll_users_form);
    $enroll_users_form.find('#admin_role_id').focus().select();
  }

  $(document).ready(function() {
    function checkFutureListingSetting () {
      if ($('#account_settings_restrict_student_future_view_value').is(':checked')) {
        $('.future_listing').show();
      } else {
        $('.future_listing').hide();
      }
    }
    checkFutureListingSetting();
    $('#account_settings_restrict_student_future_view_value').change(checkFutureListingSetting);

    $("#account_settings").submit(function() {
      var $this = $(this);
      var remove_ip_filters = true;
      $(".ip_filter .value").each(function() {
        $(this).removeAttr('name');
      }).filter(":not(.blank)").each(function() {
        var name = $.trim($(this).parents(".ip_filter").find(".name").val().replace(/\[|\]/g, '_'));
        if(name) {
          remove_ip_filters = false;
          $(this).attr('name', 'account[ip_filters][' + name + ']');
        }
      });

      if (remove_ip_filters) {
        $this.append("<input class='remove_ip_filters' type='hidden' name='account[remove_ip_filters]' value='1'/>");
      } else {
        $this.find('.remove_ip_filters').remove(); // just in case it's left over after a failed validation
      }

      var account_validations = {
        object_name: 'account',
        required: ['name'],
        property_validations: {
          'name': function(value){
            if (value && value.length > 255) { return I18n.t("account_name_too_long", "Account Name is too long")}
          }
        }
      };

      var result = $this.validateForm(account_validations)

      // Work around for Safari to enforce help menu name validation until `required` is supported
      if ($('#custom_help_link_settings').length > 0) {
        var help_menu_validations = {
          object_name: 'account[settings]',
          required: ['help_link_name'],
          property_validations: {
            'help_link_name': function(value){
              if (value && value.length > 30) { return I18n.t("help_menu_name_too_long", "Help menu name is too long")}
            }
          }
        }
        result = (result && $this.validateForm(help_menu_validations));
      }

      if(!result) {
        return false;
      }
    });
    $("#account_notification_start_at,#account_notification_end_at").datetime_field({addHiddenInput: true});
    $(".datetime_field").datetime_field();

    globalAnnouncements.augmentView()
    globalAnnouncements.bindDomEvents()

    $("#account_settings_tabs").tabs().show();
    $(".add_ip_filter_link").click(function(event) {
      event.preventDefault();
      var $filter = $(".ip_filter.blank:first").clone(true).removeClass('blank');
      $("#ip_filters").append($filter.show());
    });
    $(".delete_filter_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".ip_filter").remove();
    });
    if($(".ip_filter:not(.blank)").length == 0) {
      $(".add_ip_filter_link").click();
    }
    $(".ip_help_link").click(function(event) {
      event.preventDefault();
      $("#ip_filters_dialog").dialog({
        title: I18n.t('titles.what_are_quiz_ip_filters', "What are Quiz IP Filters?"),
        width: 400
      });
    });

    $(".open_registration_delegated_warning_link").click(function(event) {
      event.preventDefault();
      $("#open_registration_delegated_warning_dialog").dialog({
        title: I18n.t('titles.open_registration_delegated_warning_dialog', "An External Identity Provider is Enabled"),
        width: 400
      });
    });

    $('#account_settings_external_notification_warning_checkbox').on('change', function(e) {
      $('#account_settings_external_notification_warning').val($(this).prop('checked') ? 1 : 0);
    });

    $(".custom_help_link .delete").click(function(event) {
      event.preventDefault();
      $(this).parents(".custom_help_link").find(".custom_help_link_state").val('deleted');
      $(this).parents(".custom_help_link").hide();
    });

    var $blankCustomHelpLink = $('.custom_help_link.blank').detach().removeClass('blank'),
        uniqueCounter = 1000;
    $(".add_custom_help_link").click(function(event) {
      event.preventDefault();
      var $newContainer = $blankCustomHelpLink.clone(true).appendTo('#custom_help_links').show(),
          newId = uniqueCounter++;
      // need to replace the unique id in the inputs so they get sent back to rails right,
      // chage the 'for' on the lables to match.
      $.each(['id', 'name', 'for'], function(i, prop){
        $newContainer.find('['+prop+']').attr(prop, function(i, previous){
          return previous.replace(/\d+/, newId);
        });
      });
    });

    $(".remove_account_user_link").click(function(event) {
      event.preventDefault();
      var $item = $(this).parent("li");
      $item.confirmDelete({
        message: I18n.t('confirms.remove_account_admin', "Are you sure you want to remove this account admin?"),
        url: $(this).attr('href'),
        success: function() {
          $item.slideUp(function() {
            $(this).remove();
          });
        }
      });
    });

    $('#enable_equella, ' +
      '#account_settings_sis_syncing_value, ' +
      '#account_settings_sis_default_grade_export_value').change(function () {
        var $myFieldset = $('#'+ $(this).attr('id') + '_settings');
        var iAmChecked = $(this).prop('checked');
      $myFieldset.showIf(iAmChecked);
      if (!iAmChecked) {
        $myFieldset.find(":text").val("");
        $myFieldset.find(":checkbox").prop("checked", false);
      }
    }).change();

    $('#account_settings_sis_syncing_value,' +
      '#account_settings_sis_default_grade_export_value,' +
      '#account_settings_sis_assignment_name_length_value').change(function() {
        var attr_id = $(this).attr('id');
        var $myFieldset = $('#'+ attr_id + '_settings');
        var iAmChecked = $(this).attr('checked');
        $myFieldset.showIf(iAmChecked);
    }).change();

    $(".turnitin_account_settings").change(function() {
      $(".confirm_turnitin_settings_link").text(I18n.t('links.turnitin.confirm_settings', "confirm Turnitin settings"));
    });

    $("input[name='account[services][avatars]']").change(function() {
      if(this.checked) {
        $("#account_settings_gravatar_checkbox").show();
      } else {
        $("#account_settings_gravatar_checkbox").hide();
      }
    }).change();

    $(".confirm_turnitin_settings_link").click(function(event) {
      event.preventDefault();
      var $link = $(this);
      var url = $link.attr('href');
      var account = $("#account_settings").getFormData({object_name: 'account'});
      var turnitin_data = {
        turnitin_account_id: account.turnitin_account_id,
        turnitin_shared_secret: account.turnitin_shared_secret,
        turnitin_host: account.turnitin_host
      }
      $link.text(I18n.t('notices.turnitin.checking_settings', "checking Turnitin settings..."));
      $.getJSON(url, turnitin_data, function(data) {
        if(data && data.success) {
          $link.text(I18n.t('notices.turnitin.setings_confirmed', "Turnitin settings confirmed!"));
        } else {
          $link.text(I18n.t('notices.turnitin.invalid_settings', "invalid Turnitin settings, please check your account id and shared secret from Turnitin"))
        }
      }, function(data) {
        $link.text(I18n.t('notices.turnitin.invalid_settings', "invalid Turnitin settings, please check your account id and shared secret from Turnitin"))
      });
    });

    // Admins tab
    $(".add_users_link").click(addUsersLink);

    $(".open_report_description_link").click(openReportDescriptionLink);

    $(".run_report_link").click(function(event) {
      event.preventDefault();
      $(this).parent("form").submit();
    });

    $(".run_report_form").formSubmit({
      resetForm: true,
      beforeSubmit: function(data) {
        $(this).loadingImage();
        return true;
      },
      success: function(data) {
        $(this).loadingImage('remove');
        var report = $(this).attr('id').replace('_form', '');
        $("#" + report).find('.run_report_link').hide()
          .end().find('.configure_report_link').hide()
          .end().find('.running_report_message').show();
        $(this).parent(".report_dialog").dialog('close');
      },
      error: function(data) {
        $(this).loadingImage('remove');
        $(this).parent(".report_dialog").dialog('close');
      }
    });

    $(".configure_report_link").click(function(event) {
      event.preventDefault();
      var data = $(this).data(),
        $dialog = data.$report_dialog;
      if (!$dialog) {
        $dialog = data.$report_dialog = $(this).parent("td").find(".report_dialog").dialog({
          autoOpen: false,
          width: 400,
          title: I18n.t('titles.configure_report', 'Configure Report')
        });
      }
      $dialog.dialog('open');
    })

    $('.service_help_dialog').each(function(index) {
      var $dialog = $(this),
          serviceName = $dialog.attr('id').replace('_help_dialog', '');

      $dialog.dialog({
        autoOpen: false,
        width: 560
      });

      $(`<button class="Button Button--icon-action" type="button">
        <i class="icon-question"></i>
        <span class="screenreader-only">${htmlEscape(I18n.t("About this service"))}</span>
      </button>`)
        .click((event) => {
          event.preventDefault();
          $dialog.dialog('open');
        })
        .appendTo('label[for="account_services_' + serviceName + '"]');
    });

    function displayCustomEmailFromName(){
      let displayText = $('#account_settings_outgoing_email_default_name').val();
      if (displayText == '') {
        displayText = I18n.t('custom_text_blank', '[Custom Text]');
      }
      $('#custom_default_name_display').text(displayText);
    }
    $('.notification_from_name_option').on('change', () => {
      const $useCustom = $('#account_settings_outgoing_email_default_name_option_custom');
      const $customName = $('#account_settings_outgoing_email_default_name');
      if ($useCustom.attr('checked')) {
        $customName.removeAttr('disabled');
        $customName.focus()
      }
      else {
        $customName.attr('disabled', 'disabled');
      }
    });
    $('#account_settings_outgoing_email_default_name').on('keyup', () =>{
      displayCustomEmailFromName();
    });
    // Setup initial display state
    displayCustomEmailFromName();
    $('.notification_from_name_option').trigger('change');

    $('#account_settings_self_registration').change(function() {
      $('#self_registration_type_radios').toggle(this.checked);
    }).trigger('change');

    $('#account_settings_global_includes').change(function() {
      $('#global_includes_warning_message_wrapper').toggleClass('alert', this.checked);
    }).trigger('change');

    const $rce_container = $('#custom_tos_rce_container')
    $('#terms_of_service_modal').hide()
    if ($rce_container.length > 0) {
      const $textarea = $rce_container.find('textarea');
      RichContentEditor.preloadRemoteModule();
      if ($("#account_terms_of_service_terms_type").find(":selected").text() === 'Custom') {
        $('#terms_of_service_modal').show()
        $rce_container.show();
        setTimeout (() => {
          RichContentEditor.loadNewEditor($textarea, { manageParent: true, defaultContent: ENV.TERMS_OF_SERVICE_CUSTOM_CONTENT || ''})
        }, 1000);
      }
      $( "#account_terms_of_service_terms_type" ).change(function() {
        if (this.value === 'custom') {
          $('#terms_of_service_modal').show()
          $rce_container.show();
          RichContentEditor.loadNewEditor($textarea, {
            focus: true,
            manageParent: true,
            defaultContent: ENV.TERMS_OF_SERVICE_CUSTOM_CONTENT || ''
          });
        } else {
          $rce_container.hide();
          $('#terms_of_service_modal').hide()
        }
      });
    }
  });
