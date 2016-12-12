define([
  'symlink_to_node_modules/moment/min/moment-with-locales',

  // put any other custom moment locales we want to make available here (and in baseWebpackConfig.js):
  'custom_moment_locales/mi_nz'

], function (moment) {
  return moment
})
