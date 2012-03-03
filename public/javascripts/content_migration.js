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
  'i18n!content_imports',
  'jquery' /* $ */,
  'jquery.instructure_forms' /* formSubmit, formErrors */,
  'jquery.instructure_misc_plugins' /* ifExists, showIf */
], function(I18n, $) {

$(function(){
  var $config_options = $("#config_options"),
      $export_file_enabled = $("#export_file_enabled"),
      $migration_form = $('#migration_form'),
      $submit_button = $migration_form.find(".submit_button"),
      $file_upload = $migration_form.find("#file_upload"),
      $upload_extension = $migration_form.find("#upload_extension"),
      $export_file_input = $migration_form.find("#export_file_input"),
      $migration_config = $migration_form.find("#migration_config"),
      $migration_configs = $("#migration_configs"),
      $migration_alt_div = $("#migration_alt_div"),
      $overwrite_questions_config = $("#overwrite_questions_config"),
      $overwrite_questions = $("#overwrite_questions");

  function enableFileUpload(file_type){
    file_type = typeof(file_type) != 'undefined' ? file_type : ".zip";
    $upload_extension.text(file_type);
    $export_file_enabled.val("1");
    $file_upload.show();
  }
  
   function showQuestionOverwrite(){
     $overwrite_questions_config.show();
   }

  function resetMigrationForm(){
    $config_options.find("#migration_config > div").hide();
    $export_file_enabled.val("0");
    $file_upload.hide();
    $export_file_input.val("");
    $submit_button.attr('disabled', true);
    $overwrite_questions_config.hide();
    $overwrite_questions.removeAttr("checked");

    $migration_config.find(".migration_config").ifExists(function(){
      $plugin_mother = $migration_configs.find($(this).data("mother_id"));
      $plugin_mother.append($(this));
      $plugin_mother.triggerHandler("pluginHidden", [$migration_form, $migration_alt_div]);

      $alt_config = $migration_alt_div.find(".migration_alt_config");
      if($alt_config){
        $plugin_mother.append($alt_config);
      }          
    });
  }

  $("#choose_migration_system").change(function() {
    resetMigrationForm();
    
    if($(this).val() == "none") {
      $config_options.hide();
    } else {
      plugin_config_id = "#plugin_" + $(this).val();
      $plugin_mother_div = $migration_configs.find(plugin_config_id);
      $plugin_config = $plugin_mother_div.find(".migration_config");
      $plugin_config.data("mother_id", plugin_config_id);
      $migration_config.append($plugin_config);
      $plugin_alt_config = $plugin_mother_div.find(".migration_alt_config");
      if($plugin_alt_config){
        $plugin_alt_config.data("mother_id", plugin_config_id);
        $migration_alt_div.append($plugin_alt_config);
      }

      $config_options.show();
      $plugin_mother_div.triggerHandler("pluginShown", [enableFileUpload, $migration_form, showQuestionOverwrite]);
    }
  }).change();

  $("#import_subset").change(function() {
    $("#import_subset_options").showIf($(this).attr('checked'));
  }).change();

  $("#export_file_input").change(function() {
    if($(this).val().match(/\.zip$|\.imscc$/i)) {
      $submit_button.attr('disabled', false);
      $('.zip_error').hide();
    } else {
      $submit_button.attr('disabled', true);
      $('.zip_error').show();
    }
  });

  $("#migration_form").formSubmit({
    fileUpload: function() {
      return $export_file_enabled.val() == '1';
    },
    fileUploadOptions: {
      preparedFileUpload: true,
      singleFile: true,
      object_name: 'migration_settings',
      context_code: $("#current_context_code").text(),
      upload_only: true,
      uploadDataUrl: $migration_form.attr('action'),
      postFormData: true
    },
    processData: function(data) {
      if($export_file_enabled.val() != '1'){
        data['export_file'] = null;
      }
      return data;
    },
    beforeSubmit: function(data) {
      if($export_file_enabled.val() == '1'){
        $(this).find(".submit_button").attr('disabled', true).text(I18n.t('messages.uploading', "Uploading Course Export..."));
      }
    },
    success: function(data) {
      $(this).find(".submit_button").attr('disabled', false).text(I18n.t('buttons.import', "Import Course"));
      $(this).slideUp();
      $("#file_uploaded").slideDown();
    },
    error: function(data) {
      if($export_file_enabled.val() == '1'){
        $(this).find(".submit_button").attr('disabled', false).text(I18n.t('errors.upload_failed', "Upload Failed, please try again"));
      }
      $(this).formErrors(data);
    }
  });
});
});

