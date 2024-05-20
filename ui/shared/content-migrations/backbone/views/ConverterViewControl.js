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

import $ from 'jquery'
import 'jquery-tinypubsub'
import {find} from 'lodash'

// Handles rendering the correct view depending on the
// value selected.
function ConverterViewControl() {}

ConverterViewControl.subscribed = false

ConverterViewControl.registeredViews = []

// Returns an instance of the model. This model has
// been cached so can only be set once. Used to
// ensure multiple bundle files are using the same
// model instance
// -----------------------------------------------
// @api public
// @returns Object (Backbone Model)
ConverterViewControl.getModel = function () {
  return this._model
}

// Set and instance of a model. Only sets the model
// once so we don't have more than one model used
// between multiple bundle files.
// -----------------------------------------------
// @api public
// @expects Backbone.Model instance
ConverterViewControl.setModel = function (model) {
  if (!this._model) {
    return (this._model = model)
  }
}

// Adds the options to the registeredViews
// The options should include a 'view' and
// a value in the options hash. This also
// will subscribe to the pubsub one time
// if there haven't been any previous
// subscriptions.
//
// options look like this
// ie:
//     {key: 'id_of_view', view: new BackboneView}
//
// @api public
ConverterViewControl.register = function (options) {
  this.registeredViews.push(options)
  if (!this.subscribed) {
    $.subscribe('contentImportChange', this.renderView)
    return (this.subscribed = true)
  }
}

// Clears and resets this control class.
// * sets subscribed to false
// * clears out any old views
ConverterViewControl.resetControl = function () {
  this.subscribed = false
  return (this.registeredViews.length = 0)
}

ConverterViewControl.getView = key =>
  find(ConverterViewControl.registeredViews, rv => rv.key === key)

// Find the view for which the value we are looking for
// exists and render it in the parent view. This is tightly
// coupled to a converter view being passed in. Maybe there
// is a better way to handle this. Sets the migrationConverterView's
// validateBeforeSave function which is an override comming from
// the ValidatedFormView which the migrationConverterView should
// be extending.
//
// @api private
ConverterViewControl.renderView = function (options) {
  const value = options.value
  const migrationConverterView = options.migrationConverter
  const regView = ConverterViewControl.getView(value)
  let ref
  // eslint-disable-next-line no-void
  if (regView != null ? ((ref = regView.view) != null ? ref.validateBeforeSave : void 0) : void 0) {
    migrationConverterView.validateBeforeSave = regView.view.validateBeforeSave
  }
  // eslint-disable-next-line no-void
  return migrationConverterView.renderConverter(regView != null ? regView.view : void 0)
}

export default ConverterViewControl
