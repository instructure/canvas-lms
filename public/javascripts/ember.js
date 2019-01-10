/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

var jQuery = require('jquery')
// this gets the full handlebars.js file, instead of just handlebars.runtime that we alias 'handlebars' to in baseWebpackConfig.js
var Handlebars = require('handlebars/dist/cjs/handlebars').default

window.Ember = {
  imports: {
    Handlebars: Handlebars,
    jQuery: jQuery
  }
}

window.Handlebars = Handlebars

var Ember = require('exports-loader?Ember!bower/ember/ember')

module.exports = Ember
