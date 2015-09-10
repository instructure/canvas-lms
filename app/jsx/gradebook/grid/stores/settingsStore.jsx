define([
  'bower/reflux/dist/reflux',
  'jquery',
  '../actions/settingsActions'
], function (Reflux, $, SettingsActions) {
  const MOUNT_ELEMENT = document.getElementById('gradebook-grid-wrapper'),
        PADDING = 20,
        TOOLBAR_HEIGHT = $('#gradebook-toolbar').height(),
        TOOLBAR_OFFSET = $('#gradebook-toolbar').offset().top;

  var SettingsStore = Reflux.createStore({
    listenables: [SettingsActions],

    init () {
      this.columnWidths = ENV.GRADEBOOK_OPTIONS.gradebook_column_size_settings || {};
    },

    getInitialState() {
      this.settings = {
        width: this.getGradebookWidth(),
        height: this.getGradebookHeight(),
        columnWidths: this.columnWidths
      };
      return this.settings;
    },

    onResize() {
      this.settings.width = this.getGradebookWidth();
      this.settings.height = this.getGradebookHeight();
      this.trigger(this.settings);
    },

    onSaveColumnSize(newColumnWidth, dataKey) {
      this.columnWidths[dataKey] = newColumnWidth;
      this.trigger(this.settings);
    },

    getGradebookWidth() {
      return $(MOUNT_ELEMENT).width();
    },

    getGradebookHeight() {
      var windowHeight  = $(window).innerHeight();
      return windowHeight - (TOOLBAR_HEIGHT + TOOLBAR_OFFSET + PADDING);
    }
  });

  return SettingsStore;
});
