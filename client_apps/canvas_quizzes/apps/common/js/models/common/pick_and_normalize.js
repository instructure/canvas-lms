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

define(function(require) {
  var convertCase = require('../../util/convert_case')
  var _ = require('lodash')
  var pick = _.pick
  var camelize = convertCase.camelize

  /**
   * @method pickAndNormalize
   * @member Models
   *
   * Pick certain keys out of an object, and converts them to camelCase.
   *
   * @param  {Object} set
   * @param  {String[]} keys
   * @return {Object}
   */
  return function pickAndNormalize(set, keys) {
    return camelize(pick(set || {}, keys))
  }
})
