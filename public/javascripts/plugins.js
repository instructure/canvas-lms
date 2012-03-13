define([
  'i18n!plugins',
  'jquery' /* $ */,
  'jquery.instructure_misc_plugins' /* showIf */
], function(I18n, $) {

  $("form.edit_plugin_setting").live('submit', function() {
    $(this).find("button").attr('disabled', true).filter(".save_button").text(I18n.t('buttons.saving', "Saving..."));
  });
  $(document).ready(function() {
    $(".disabled_checkbox").change(function() {
      $("#settings .plugin_settings").showIf(!$(this).attr('checked'));
    }).change();
  });
});

