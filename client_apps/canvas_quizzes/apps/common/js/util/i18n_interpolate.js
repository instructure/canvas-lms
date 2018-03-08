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

define(function() {
  var INTERPOLATER = /\%\{([^\}]+)\}/g

  /**
   * @member Util
   * @method i18nInterpolate
   *
   * Stupid i18n interpolator that interpolates anything between %{} with
   * a value you pass in {@options}.
   *
   * @param {String} contents
   *        The i18n text block you're interpolating.
   *
   * @param {Object} options
   *        Pairs of variable names and their interpolation values.
   *        The variable names should be snake_cased.
   *
   * @return {String}
   *         The interpolated text.
   */
  return function i18nInterpolate(contents, options) {
    var variables = contents.match(INTERPOLATER)

    if (variables) {
      variables.forEach(function(variable) {
        var optionKey = variable.substr(2, variable.length - 3)
        contents = contents.replace(new RegExp(variable, 'g'), options[optionKey])
      })
    }

    return contents
  }
})
