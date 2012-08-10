define([
  'INST' /* INST */,
  'i18n!conferences',
  'jquery' /* $ */,
  'jquery.ajaxJSON' /* ajaxJSON */,
  'jquery.instructure_forms' /* formSubmit, fillFormData */,
  'jqueryui/dialog',
  'jquery.instructure_misc_helpers' /* replaceTags */,
  'jquery.instructure_misc_plugins' /* confirmDelete, fragmentChange, showIf */,
  'jquery.keycodes' /* keycodes */,
  'jquery.loadingImg' /* loadingImage */,
  'compiled/jquery.rails_flash_notifications',
  'jquery.templateData' /* fillTemplateData, getTemplateData */
], function(INST, I18n, $) {

  $(document).ready(function() {
    $("#add_conference_form .cancel_button").click(function() {
      if($("#add_conference_form").prev(".conference").length > 0) {
        $("#add_conference_form").hide();
      } else {
        $("#add_conference_form").slideUp();
      }
      $("#add_conference_form").prev(".conference").show();
    });
    $("#add_conference_form :text").keycodes('esc', function() {
      $("#add_conference_form").find(".cancel_button").click();
    });
    $("#add_conference_form").formSubmit({
      object_name: 'web_conference',
      beforeSubmit: function(data) {
        var $conference = $(this).prev(".conference");
        if($conference.length == 0) {
          $conference = $("#conference_blank").clone(true).attr('id', '');
          $("#conferences").prepend($conference.show());
        } else {
          $conference.show();
        }
        $("#add_conference_form").hide();
        $conference.loadingImage();
        if (!data.duration) {
          data.long_running = "1";
        }
        $conference.fillTemplateData({
          data: data
        });
        $conference.find(".join_conference_link").hide();
        return $conference;
      },
      success: function(data, $conference) {
        $("#no_conferences_message").slideUp();
        $conference.loadingImage('remove');
        $conference.fillTemplateData({
          data: data.web_conference,
          hrefValues: ['id']
        });
        if(data.web_conference && data.web_conference.permissions) {
          $conference.find(".edit_conference_link").showIf(data.web_conference.permissions.update);
          $conference.find(".delete_conference_link").showIf(data.web_conference.permissions['delete']);
          if(data.web_conference.permissions.initiate || data.web_conference.permissions.join) {
            $conference.find(".join_conference_link").show();
          }
        }
      },
      error: function(data, $conference) {
        $conference.loadingImage('remove');
        $conference.remove();
        $(this).show();
      }
    });
    $("#add_conference_form select").change(function(event){
      var settings = INST.webConferenceUserSettingTemplates[$(this).val()];
      var contents = ''
      $.each(settings, function(name, html){
        contents += html.html + "<br>";
      });
      $("#web_conference_user_settings").html(contents);
    });
    $(".edit_conference_link, .add_conference_link").click(function(event) {
      event.preventDefault();
      var $form = $("#add_conference_form");
      if ($form.is(":visible")) {
        if (confirm(I18n.t('confirm.quit', "It looks like you are already editing another conference. Do you wish to continue? Any unsaved changes will be lost."))) {
          $form.prev(".conference").show();
        } else {
          return;
        }
      }
      var edit = $(this).hasClass('edit_conference_link');
      var $conference = $(this).parents(".conference")
      if(!edit) {
        $conference = $("#conference_blank");
      }
      var data = $conference.getTemplateData({
        textValues: ['title', 'duration', 'description', 'user_ids', 'conference_type', 'long_running', 'has_advanced_settings', 'id'].concat(INST.webConferenceUserSettings)
      });
      if(edit) {
        $form.find("span.title").text(I18n.t('index.edit_conference_heading', "Edit Conference Details"));
        $form.find("button[type=submit]").text(I18n.t('index.buttons.update', "Update Conference"));
        $form.attr('method', 'PUT').attr('action', $(this).attr('href'));
        $form.find('select').attr("disabled", true);
        var $advanced_settings = $form.find('.advanced_settings').showIf(parseInt(data.has_advanced_settings));
        $advanced_settings.attr('href', $.replaceTags($advanced_settings.data('base-href'), {id: data.id}));
        $conference.after($form);
        $form.find("#members_list").show().find(":checkbox").attr('checked', false).end().end()
          .find(".all_users_checkbox").attr('checked', false);
        var ids = (data.user_ids || "").split(",");
        for(var idx in ids) {
          var id = ids[idx];
          $form.find("#members_list .member.user_" + id).find(":checkbox").attr('checked', true);
        }
        // this ensures our user_setting inputs exist so fillFormData can
        // populate them
        if (data.conference_type) {
          $form.find('select').val(data.conference_type).change();
          delete data.conference_type;
        }
      } else {
        delete data.conference_type;
        $form.find("span.title").text(I18n.t('index.new_conference_heading', "Start a New Conference"));
        $form.find("button[type=submit]").text(I18n.t('index.buttons.create', "Create Conference"));
        $form.attr('method', 'POST').attr('action', $(".add_conference_url").attr('href'));
        $form.find('select').attr("disabled", false);
        $form.find('.advanced_settings').hide();
        $form.find(".all_users_checkbox").attr('checked', true).end()
          .find("#members_list").hide().find(":checkbox").attr('checked', false);
        $("#conferences").before($form);
      }
      $form.fillFormData(data, {object_name: 'web_conference'});
      $form.find('#web_conference_long_running').change(function(){
        if ($(this).attr('checked')) {
          $form.find('#web_conference_duration').attr('disabled', true).val('');
        } else {
          $form.find('#web_conference_duration').attr('disabled', false).val(INST.webConferenceDefaultDuration);
        }
      }).change();
      $conference.hide();
      if(edit) {
        $form.show();
        $form.find(":input:visible:first").focus().select();
      } else {
        $form.slideDown(function() {
          $(this).find(":input:visible:first").focus().select();
        });
      }
    });
    $(".delete_conference_link").click(function(event) {
      event.preventDefault();
      $(this).parents(".conference").confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t('confirm.delete', "Are you sure you want to delete this conference?"),
        success: function() {
          if($("#conferences .conference:visible").length <= 1) {
            $("#no_conferences_message").slideDown();
          }
          $(this).slideUp(function() {
            $(this).remove();
          });
        }
      });
    });
    $(".all_users_checkbox").change(function() {
      if(!$(this).attr('checked')) {
        $("#members_list").slideDown();
      } else {
        $("#members_list").slideUp();
      }
    }).change();
    $(document).fragmentChange(function(event, hash){
      if (match = hash.match(/^#conference_\d+$/)) {
        $(match[0]).find(".edit_conference_link").click();
      }
    });
    $('.close_conference_link').click(function(){
      var $conference = $(this).parents(".conference");
      event.preventDefault();
      if (confirm(I18n.t('confirm.close', "Are you sure you want to end this conference? You will not be able to reopen it"))) {
        $conference.loadingImage();
        $conference.find(".close_conference_link, .join_conference_link, .edit_conference_link").hide();
        $.ajaxJSON($(this).attr('href'), "POST", {}, function(data) {
          $("#no_conferences_message").slideUp();
          $conference.loadingImage('remove');
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
          $box.dialog('close').dialog({
            autoOpen: false,
            width: 425,
            minWidth: 425,
            minHeight: 215,
            resizable: true,
            height: "auto",
            title: $self.text()
          }).dialog('open');
        } else {
          window.open(data[0].url);
        }
      });
    });
  });
});

