$("form.edit_plugin_setting").live('submit', function() {
  $(this).find("button").attr('disabled', true).filter(".save_button").text("Saving...");
});