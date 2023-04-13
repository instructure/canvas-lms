/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import Backbone from '@canvas/backbone'
import _ from 'underscore'

extend(MigrationView, Backbone.View)

function MigrationView() {
  this.validateBeforeSave = this.validateBeforeSave.bind(this)
  return MigrationView.__super__.constructor.apply(this, arguments)
}

// Validations for this view that should be made
// on the client side before save.
// ---------------------------------------------
// @expects void
// @returns ErrorMessage
// @api private override ValidateFormView

MigrationView.prototype.validateBeforeSave = function () {
  // There might be a better way to do this with reduce
  const validations = {}
  _.each(
    this.children,
    (function (_this) {
      return function (child) {
        if (child.validations) {
          return _.extend(validations, child.validations())
        }
      }
    })(this)
  )
  return validations
}

export default MigrationView
