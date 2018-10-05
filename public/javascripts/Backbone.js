/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

/////
// if you want Backbone, import 'Backbone' (this file). It will give you
// back a Backbone with all of our instructure specific patches to it.

// Get the unpatched Backbone
const Backbone = require('node_modules-version-of-backbone')

// Apply all of our patches
require('compiled/backbone-ext/Backbone.syncWithMultipart')
require('compiled/backbone-ext/Model')
require('compiled/backbone-ext/View')
require('compiled/backbone-ext/Collection')

module.exports = Backbone
