#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import Backbone from 'Backbone'
import _ from 'underscore'

export default class MigrationView extends Backbone.View

  # Validations for this view that should be made
  # on the client side before save.
  # ---------------------------------------------
  # @expects void
  # @returns ErrorMessage
  # @api private override ValidateFormView

  validateBeforeSave: =>
    # There might be a better way to do this with reduce
    validations = {}
    _.each @children, (child) =>
      _.extend(validations, child.validations()) if child.validations

    validations
