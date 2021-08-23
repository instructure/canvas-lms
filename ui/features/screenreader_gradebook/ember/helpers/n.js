//
// Copyright (C) 2017 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import Ember from 'ember'
import I18n from '@canvas/i18n'
import numberFormat from '@canvas/i18n/numberFormat'

Ember.Handlebars.registerBoundHelper('n', (number, options) => I18n.n(number, options.hash))

export default Ember.Handlebars.registerBoundHelper('nf', (number, options) =>
  numberFormat[options.hash.format](number)
)
