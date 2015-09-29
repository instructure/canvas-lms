define([
  'bower/reflux/dist/reflux',
  'jquery'
], function (Reflux, $) {
  const SAVE_COLUMN_SIZE_URL = ENV.GRADEBOOK_OPTIONS.gradebook_column_size_settings_url;

  var SettingsActions = Reflux.createActions([
    'resize',
    'saveColumnSize'
  ]);

  SettingsActions.saveColumnSize.preEmit = (newColumnWidth, dataKey) => {
    $.ajaxJSON(SAVE_COLUMN_SIZE_URL, 'POST', {
      column_id: dataKey,
      column_size: newColumnWidth
    });
  };

  return SettingsActions;
});
