define([
  'bower/reflux/dist/reflux',
  'jquery',
  'jsx/gradebook/grid/constants'
], function (Reflux, $, GradebookConstants) {
  const SAVE_COLUMN_SIZE_URL = GradebookConstants.gradebook_column_size_settings_url;

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
