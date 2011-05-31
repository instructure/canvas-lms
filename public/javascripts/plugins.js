$("form.edit_plugin_setting").live('submit', function() {
  $(this).find("button").attr('disabled', true).filter(".save_button").text("Saving...");
});
$(document).ready(function() {
  $(".disabled_checkbox").change(function() {
    $("#settings .plugin_settings").showIf(!$(this).attr('checked'));
  }).change();
});