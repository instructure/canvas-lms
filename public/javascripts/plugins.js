I18n.scoped('plugins', function(I18n) {
  $("form.edit_plugin_setting").live('submit', function() {
    $(this).find("button").attr('disabled', true).filter(".save_button").text(I18n.t('buttons.saving', "Saving..."));
  });
  $(document).ready(function() {
    $(".disabled_checkbox").change(function() {
      $("#settings .plugin_settings").showIf(!$(this).attr('checked'));
    }).change();
  });
})
