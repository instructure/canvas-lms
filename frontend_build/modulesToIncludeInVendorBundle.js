/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

module.exports = [
  'setWebpackCdnHost',
  'jquery.instructure_jquery_patches', // this needs to be before anything else that requires jQuery
  'Backbone',
  'classnames',

  // This needs to be loaded before all our handlebars templates so they
  // can have access to these helpers
  'coffeescripts/handlebars_helpers.coffee',

  'jquery',
  'jquery.ajaxJSON',
  'jquery.google-analytics',
  'spin.js/jquery.spin',
  'jqueryui/effects/drop',
  'jqueryui/progressbar',
  'jqueryui/tabs',
  'jqueryui/dialog',
  'moment',
  'react',
  'react-modal',
  'underscore',
  'vendor/date',
  'vendor/i18n',
  'vendor/i18n_js_extension',
  'vendor/jquery.ba-tinypubsub',
  'vendor/jquery.pageless',
  'vendor/jquery.scrollTo',
  'vendor/jqueryui/dialog',
  'vendor/mediaelement-and-player',

  // without putting these here, they get included in each bundle
  // seperately. since they are not actual vendor libs, we should get
  // them out of here eventually
  'compiled/views/PaginatedCollectionView',
  'compiled/util/brandableCss',
  'i18nObj',
  'jquery.disableWhileLoading',
  'compiled/jquery/fixDialogButtons',
  'jquery.instructure_misc_plugins',
  'jquery.instructure_misc_helpers',
  'jquery.loadingImg',
  'compiled/str/i18nLolcalize',
  'instructure',

   // 'instructure-ui/Spinner',
   // 'jsx/shared/rce/RichContentEditor'
]
