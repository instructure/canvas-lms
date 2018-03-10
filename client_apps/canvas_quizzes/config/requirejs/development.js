/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

requirejs.config({
  map: {
    '*': {
      'underscore': 'lodash',
      'canvas_packages': '../../../vendor/packages',
    }
  },

  paths: {
    'text': '../../../vendor/js/require/text',
    'i18n': '../../../vendor/js/require/i18n',
    'jsx': '../../../vendor/js/require/jsx',
    'JSXTransformer': '../../../vendor/js/require/JSXTransformer-0.11.0.min',

    // ========================================================================
    // CQS dependencies
    'rsvp': '../../../vendor/js/rsvp.min',
    'qtip': '../../../vendor/js/jquery.qtip',
    'old_version_of_react_used_by_canvas_quizzes_client_apps': '../../../vendor/js/old_version_of_react_used_by_canvas_quizzes_client_apps',
    'old_version_of_react-router_used_by_canvas_quizzes_client_apps': '../../../vendor/js/old_version_of_react-router_used_by_canvas_quizzes_client_apps',
    // ========================================================================

    // ========================================================================
    // Aliases to frequently-used Canvas packages
    'lodash': '../../../vendor/packages/lodash',
    'd3': '../../../vendor/canvas_public/javascripts/symlink_to_node_modules/d3/d3',
    // ========================================================================

    // ========================================================================
    // Internal, for package providers only:
    'canvas': '../../../vendor/canvas_public/javascripts'
  },

  shim: {
    qtip: [ 'jquery' ]
  },
});
