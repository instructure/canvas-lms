define([
  'INST' /* INST */,
  'i18n!conferences',
  'jquery' /* $ */,
  'underscore',
  'jst/conferences/newConference',
  'jst/conferences/concludedConference',
  'jst/conferences/editConferenceForm',
  'jst/conferences/userSettingOptions',
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, fillFormData */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */

], function(INST, I18n, $, _, newConferenceTemplate, concludedConferenceTemplate, editConferenceFormTemplate, userSettingOptionsTemplate) {

  $(document).ready(function() {

    var buildRow = function(conferenceData) {
      conferenceData['has_actions'] = (conferenceData['permissions']['edit'] || conferenceData['permissions']['delete']);
      conferenceData['join_url'] = conferenceData['url'] + '/join';
      conferenceData['close_url'] = conferenceData['url'] + '/close';
      conferenceData['show_end'] = conferenceData['permissions']['initiate'] && conferenceData['started_at'] && conferenceData['long_running'];
      $conference_row = $(newConferenceTemplate(conferenceData));
      $conference_row.data('conference', conferenceData);
      return $conference_row;
    };

    var buildConcludedRow = function(conferenceData) {
      conferenceData['has_actions'] = (conferenceData['permissions']['delete']);
      // grab the first recording from the possible list and add as own object.
      conferenceData['recording'] = conferenceData.recordings[0];
      $conference_row = $(concludedConferenceTemplate(conferenceData));
      $conference_row.data('conference', conferenceData);
      return $conference_row;
    };

    var buildConferenceForm = function(conferenceData, mode) {
      var is_editing = (mode == 'editing');
      var is_adding = !is_editing;
      var invite_all = is_adding;

      updateConferenceUserSettingDetailsForConference(conferenceData);

      conferenceData['http_method'] = ((is_adding) ? 'POST' : 'PUT');
      $form = $(editConferenceFormTemplate({
        settings: {
          is_editing: is_editing,
          is_adding: is_adding,
          disable_duration_changes: ((conferenceData['long_running'] || is_editing) && conferenceData['started_at']),
          auth_token: ENV.AUTHENTICITY_TOKEN
        },
        conferenceData: conferenceData,
        users: ENV.users,
        conferenceTypes: ENV.conference_type_details.map(function(type){
          return {name: type.name, type: type.type, selected: (conferenceData.conference_type === type.type)}
        }),
        inviteAll: invite_all
      }));

      return $form;
    };

    var updateConferenceUserSettingDetailsForConference = function(conferenceData){
      var undefined;   // for undefined comparison
      // make handlebars comparisons easy
      _.each(ENV.conference_type_details, function(conferenceInfo){
        _.each(conferenceInfo.settings, function(optionObj){
          optionObj['isBoolean'] = (optionObj['type'] == 'boolean');
          if (optionObj.isBoolean) {
            var currentVal = conferenceData.user_settings[optionObj.field];
            // if no value currently set, use the default.
            if (currentVal === undefined) {
              currentVal = optionObj['default'];
            }
            optionObj['checked'] = currentVal;
          }
        });
      });
    };

    var renderConferenceFormUserSettings = function(conferenceData, selectedConferenceType){
      // Grab the selected entry to pass in for rendering the appropriate user setting options.
      var selected = _.select(ENV.conference_type_details, function(conference_settings){return conference_settings.type === selectedConferenceType});
      if (selected.length > 0){
        selected = selected[0];
      }
      $('.web_conference_user_settings').html(userSettingOptionsTemplate({
        settings: selected.settings,
        conference: conferenceData,
        conference_started: !!conferenceData['started_at']
      }));
    };

    var updatedConferenceListCount = function(){
      // if no conferences displayed, show the "no new conferences" row.
      if ($("#new-conference-list .conference:visible").length <= 0){
        $('.no-new-conferences').show();
      } else {
        $('.no-new-conferences').hide();
      }
      // if no concluded conferences displayed, show the "no concluded conferences" row.
      if ($("#concluded-conference-list .conference:visible").length <= 0){
        $('.no-concluded-conferences').show();
      } else {
        $('.no-concluded-conferences').hide();
      }
    };

    // populate the conference list with inital set of data
    _.each(ENV.current_conferences, function(conference) {
      $("#new-conference-list").append(buildRow(conference));
    });
    _.each(ENV.concluded_conferences, function(conference) {
      $("#concluded-conference-list").append(buildConcludedRow(conference));
    });
    updatedConferenceListCount();


      $('#add_conference_form').dialog({
      autoOpen: false,
      width: 'auto',
      title: I18n.t('new_conference_title', 'New Conference')
    }).data('dialog');

    $.screenReaderFlashMessage(
      I18n.t('notifications.inaccessible',
             'Warning: This page contains third-party content which is not accessible ' +
             'to screen readers.'),
      20000
    );
    $('body').on('click', "#add_conference_form .cancel_button", function(){
      $("#add_conference_form").dialog('close');
    });
    $('body').on('change', "#add_conference_form select", function(){
      var conferenceData = $('#add_conference_form').data('conference');
      var selectedConferenceType = $('#web_conference_conference_type').val();
      renderConferenceFormUserSettings(conferenceData, selectedConferenceType);
    });
    $('body').on('change', ".all_users_checkbox", function() {
      if(!$(this).is(':checked')) {
        $("#members_list").slideDown();
      } else {
        $("#members_list").slideUp();
      }
    });

    $('.conference-wrapper h2 a').on('click', function(e) {
      var $icon = $(this).children('i');

      if ($icon.hasClass('icon-arrow-down')) {
        $icon.removeClass('icon-arrow-down').addClass('icon-arrow-right');
      } else {
        $icon.removeClass('icon-arrow-right').addClass('icon-arrow-down');
      }
    });
    $('body').on('change', '#web_conference_long_running', function(){
      if ($(this).is(':checked')) {
        $('#web_conference_duration').prop('disabled', true).val('');
      } else {
        // use restore time from data attribute
        $('#web_conference_duration').prop('disabled', false).val($('#web_conference_duration').data('restore-value'));
      }
    });

    $('body').on('click', ".edit_conference_link, .new-conference-btn", function(event) {
      event.preventDefault();
      var edit = $(this).hasClass('edit_conference_link');
      var $dialog = $("#add_conference_form");

      var $conference = $(this).closest(".conference");
      if(!edit) {
        $conference = buildRow(JSON.parse(JSON.stringify(ENV.default_conference)));
      }
      var conferenceData = $conference.data('conference');
      // Setup value to "restore" when toggling long_running option
      if (conferenceData.duration == null){
        conferenceData.restore_duration = ENV.default_conference.duration;
      } else {
        conferenceData.restore_duration = conferenceData.duration;
      }
      $dialog.data('editing-conf', $conference);
      if(edit) {
        $dialog.dialog({
          title: I18n.t('update_conference_title', 'Update Conference')
        });
        $dialog.html(buildConferenceForm(conferenceData, 'editing'));

        $dialog.find("#members_list").show().find(":checkbox").attr('checked', false).end().end()
          .find(".all_users_checkbox").attr('checked', false);
        _.each(conferenceData.user_ids, function(id) {
          $dialog.find("#members_list .member.user_" + id).find(":checkbox").attr('checked', true);
        });
      } else {
        //delete data.conference_type;
        $dialog.html(buildConferenceForm(conferenceData, 'adding'));
        $dialog.dialog({
          title: I18n.t('new_conference_title', 'New Conference')
        });
        $dialog.find(".all_users_checkbox").attr('checked', true).end()
          .find("#members_list").hide().find(":checkbox").attr('checked', false);
      }
      // Render the options for the currently selected conference types
      renderConferenceFormUserSettings(conferenceData, conferenceData.conference_type);

      // attach formSubmit event
      $dialog.find('form').formSubmit({
        object_name: 'web_conference',
        beforeSubmit: function(data) {
          var $conference = $dialog.data('editing-conf');
          $dialog.dialog('close');
          if(edit){
            $conference.loadingImage();
          } else {
            $('#new-conference-list').loadingImage();
          }
          return $conference;
        },
        success: function(data, $conference) {
          $("#no_conferences_message").slideUp();
          $conference.loadingImage('remove');
          // replace existing entry and update data
          $conference.html(buildRow(data).html());
          $conference.data('conference', data);
          if (!edit){
            $('#new-conference-list').loadingImage('remove');
            $("#new-conference-list").prepend($conference);
            updatedConferenceListCount();
          }
        },
        error: function(data, $conference) {
          if ($conference){
            $conference.loadingImage('remove');
            $conference.remove();
          }
          $dialog.dialog('open');
        }
      });

      // Attach the conference data to the dialog
      $dialog.data('conference', conferenceData);
      // Reflect the options for the currently selected conference type
      $dialog.find("#web_conference_conference_type").trigger('change');
      // Reflect the current 'all users" state
      $dialog.find(".all_users_checkbox").trigger('change');
      $dialog.dialog('open');
    });
    $('body').on('click', '.delete_conference_link', function(event) {
      event.preventDefault();
      $(this).parents(".conference").confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t('confirm.delete', "Are you sure you want to delete this conference?"),
        success: function() {
          $(this).slideUp(function() {
            $(this).remove();
            updatedConferenceListCount();
          });
        }
      });
    });
    $(document).fragmentChange(function(event, hash){
      if (match = hash.match(/^#conference_\d+$/)) {
        $(match[0]).find(".edit_conference_link").click();
      }
    });
    $('body').on('click', '.close_conference_link', function(event){
      event.preventDefault();
      var $conference = $(this).closest(".conference");
      if (confirm(I18n.t('confirm.close', "Are you sure you want to end this conference?\n\nYou will not be able to reopen it."))) {
        $conference.loadingImage();
        $conference.find(".close_conference_link, .join_conference_link, .edit_conference_link").hide();
        $.ajaxJSON($(this).attr('href'), "POST", {}, function(data) {
          $conference.loadingImage('remove');
          $conference.slideUp(function() {
            $conference.remove();
            updatedConferenceListCount();
          });
          // add updated entry to the concluded conferences list
          $('#concluded-conference-list').prepend(buildConcludedRow(data));
          updatedConferenceListCount();
        });
      }
    });
  
    $(".external_url").click(function(e) {
      e.preventDefault();
      var loading_text = I18n.t('loading_urls_message', "Loading, please wait...");
      var $self = $(this);
      var link_text = $self.text();
      if (link_text == loading_text) {
        return;
      }
      $self.text(loading_text);
      $.ajaxJSON($self.attr('href'), 'GET', {}, function(data) {
        $self.text(link_text);
        if (data.length == 0) {
          $.flashError(I18n.t('no_urls_error', "Sorry, it looks like there aren't any %{type} pages for this conference yet.", {type: $self.attr('name')}));
        } else if (data.length > 1) {
          $box = $(document.createElement('DIV'));
          $box.append($("<p />").text(I18n.t('multiple_urls_message', "There are multiple %{type} pages available for this conference. Please select one:", {type: $self.attr('name')})));
          for (var i = 0; i < data.length; i++) {
            $a = $("<a />", {href: data[i].url || $self.attr('href') + '&url_id=' + data[i].id, target: '_blank'});
            $a.text(data[i].name);
            $box.append($a).append("<br>");
          }
          $box.dialog({
            width: 425,
            minWidth: 425,
            minHeight: 215,
            resizable: true,
            height: "auto",
            title: $self.text()
          });
        } else {
          window.open(data[0].url);
        }
      });
    });
  });
});

