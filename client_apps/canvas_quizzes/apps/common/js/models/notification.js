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
  var K = require('../constants')
  var ATTRIBUTES = [
    {name: 'id', required: true},
    {name: 'code', required: true},
    {name: 'context', required: false}
  ]

  /**
   * @class Models.Notification
   */
  var Notification = function(attrs) {
    ATTRIBUTES.forEach(
      function(attr) {
        if (attr.required && !attrs.hasOwnProperty(attr.name)) {
          throw new Error("Notification is missing a required attribute '" + attr.name + "'")
        }

        this[attr.name] = attrs[attr.name]
      }.bind(this)
    )

    if (this.code === undefined) {
      throw new Error('You must register the notification code as a constant.')
    }

    return this
  }

  Notification.prototype.toJSON = function() {
    return ATTRIBUTES.reduce(
      function(attributes, attr) {
        attributes[attr.name] = this[attr.name]
        return attributes
      }.bind(this),
      {}
    )
  }

  return Notification
})
