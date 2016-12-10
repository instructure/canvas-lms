var glob = require("glob");

var entries = {};

var bundlesPattern = __dirname + "/../app/coffeescripts/bundles/**/*.coffee";
var pluginBundlesPattern = __dirname + "/../gems/plugins/*/app/coffeescripts/bundles/*.coffee";
var bundleNameRegexp = /\/coffeescripts\/bundles\/(.*).coffee/;
var fileNameRegexp = /\/([^/]+)\.coffee/;
var pluginNameRegexp = /plugins\/([^/]+)\/app/;

var appBundles = glob.sync(bundlesPattern, []);
var pluginBundles = glob.sync(pluginBundlesPattern, []);

// these are bundles that are dependencies, and therefore should not be compiled
//  as entry points (webpack won't allow that).
// TODO: Ultimately we should move them to other directories.
var nonEntryPoints = ['common', 'modules/account_quota_settings', 'modules/content_migration_setup'];

appBundles.forEach(function(entryFilepath){
  var entryBundlePath = entryFilepath.replace(/^.*app\/coffeescripts\/bundles/, "./app/coffeescripts/bundles")
  var entryName = bundleNameRegexp.exec(entryBundlePath)[1];
  if(nonEntryPoints.indexOf(entryName) < 0){
    entries[entryName] = entryBundlePath;
  }
});



// TODO: Include this from source rather than after the ember app compilation step.
//      This whole "compiled" folder should eventually go away
entries['screenreader_gradebook'] = "./public/javascripts/compiled/bundles/screenreader_gradebook.js";

pluginBundles.forEach(function(entryFilepath){
  var pluginName = pluginNameRegexp.exec(entryFilepath)[1];
  var fileName = fileNameRegexp.exec(entryFilepath)[1];
  var bundleName = pluginName + "-" + fileName;
  entries[bundleName] = entryFilepath;
});


entries['instructure-common'] = [
  'ajax_errors',
  'coffeescripts/bundles/common',
  'classnames',
  'compiled/helpDialog',
  'compiled/badge_counts',
  'compiled/behaviors/activate',
  'compiled/behaviors/admin-links',
  'compiled/behaviors/authenticity_token',
  'compiled/behaviors/elementToggler',
  'compiled/behaviors/instructure_inline_media_comment',
  'compiled/behaviors/ping',
  'compiled/behaviors/tooltip',
  'compiled/behaviors/ujsLinks',
  'compiled/collections/AssignmentOverrideCollection',
  'compiled/collections/DateGroupCollection',
  'compiled/collections/GroupUserCollection',
  'compiled/editor/stocktiny',
  'compiled/grade_calculator',
  'compiled/jquery/ModuleSequenceFooter',
  'compiled/jquery/serializeForm',
  'compiled/models/Assignment',
  'compiled/models/grade_summary/CalculationMethodContent',
  'compiled/models/AssignmentOverride',
  'compiled/models/DateGroup',
  'compiled/models/Group',
  'compiled/models/Outcome',
  'compiled/models/Progress',
  'compiled/models/Pseudonym',
  'compiled/models/Section',
  'compiled/models/TurnitinSettings',
  'compiled/models/VeriCiteSettings',
  'compiled/models/User',
  'compiled/PandaPub',
  'compiled/registration/incompleteRegistrationWarning',
  'compiled/util/brandableCss',
  'compiled/util/DateValidator',
  'compiled/util/PandaPubPoller',
  'compiled/util/Popover',
  'compiled/util/round',
  'compiled/views/CollectionView',
  'compiled/views/DialogBaseView',
  'compiled/views/DialogFormView',
  'compiled/views/editor/KeyboardShortcuts',
  'compiled/views/MessageStudentsDialog',
  'compiled/views/PaginatedCollectionView',
  'compiled/views/PaginatedView',
  'compiled/views/PublishButtonView',
  'compiled/views/PublishIconView',
  'compiled/views/TreeBrowserView',
  'compiled/views/ValidatedFormView',
  'compiled/views/ValidatedMixin',
  'i18nObj',
  'instructure',
  'jquery.instructure_forms',
  'jquery.toJSON',
  'jst/_avatar',
  'jst/collectionView',
  'jst/DialogFormWrapper',
  'jst/editor/KeyboardShortcuts',
  'jst/EmptyDialogFormWrapper',
  'jst/ExternalTools/_external_tool_menuitem',
  'jst/messageStudentsDialog',
  'jst/outcomes/_calculationMethodExample',
  'jst/paginatedCollection',
  'jst/PaginatedView',
  'jsx/shared/helpers/createStore',
  'link_enrollment',
  'LtiThumbnailLauncher',
  'media_comments',
  'page_views',
  'reminders',
  'jsx/fakeRequireJSFallback'
];

entries['vendor'] = [
  'Backbone',
  'handlebars',
  'jquery',
  'jquery.ajaxJSON',
  'jquery.fancyplaceholder',
  'jquery.google-analytics',
  'jqueryui/autocomplete',
  'jqueryui/effects/drop',
  'jqueryui/progressbar',
  'jqueryui/tabs',
  'moment',
  'react',
  'react-modal',
  'underscore',
  'vendor/backbone-identity-map',
  'backbone',
  'vendor/date',
  'vendor/graphael',
  'vendor/i18n',
  'vendor/i18n_js_extension',
  'vendor/jquery-1.7.2',
  'vendor/jquery.ba-hashchange',
  'vendor/jquery.ba-tinypubsub',
  'vendor/jquery.cookie',
  'vendor/jquery.pageless',
  'vendor/jquery.scrollTo',
  'vendor/mediaelement-and-player',
  'vendor/raphael',
  'vendor/slickgrid/slick.grid',
  'vendor/slickgrid/slick.editors',
  'vendor/slickgrid/plugins/slick.rowselectionmodel',
  'vendor/swfobject/swfobject'
];

module.exports = entries;
