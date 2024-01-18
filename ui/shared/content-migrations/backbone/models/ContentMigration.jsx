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
import {forEach} from 'lodash'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import {completeUpload} from '@canvas/upload-file'
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import ReactDOM from 'react-dom'
import {ProgressBar} from '@instructure/ui-progress'
import '@canvas/jquery/jquery.instructure_forms'

const I18n = useI18nScope('content_migrations')

extend(ContentMigration, Backbone.Model)

function ContentMigration() {
  this.onProgress = this.onProgress.bind(this)
  this.translateDateAdjustmentParams = this.translateDateAdjustmentParams.bind(this)
  this.addDaySubsitutions = this.addDaySubsitutions.bind(this)
  this.save = this.save.bind(this)
  this.urlRoot = this.urlRoot.bind(this)
  return ContentMigration.__super__.constructor.apply(this, arguments)
}

ContentMigration.prototype.urlRoot = function () {
  return '/api/v1/courses/' + this.get('course_id') + '/content_migrations'
}

ContentMigration.dynamicDefaults = {}

// Creates a dynamic default for this models attributes. This means that
// the default values for this model (instance) will be whatever it was
// set to originally.
//   id:
//      model = new ContentMigration foo: 'bar', cat: 'Fluffy'
//      model.set('pill', adderall) # don't do drugs...
//
//      model.dynamicDefaults = {foo: 'bar', cat: 'Fluffy'}
// @api public backbone override

ContentMigration.prototype.initialize = function (attributes) {
  ContentMigration.__super__.initialize.apply(this, arguments)
  return (this.dynamicDefaults = attributes)
}

// Clears all attributes on the model and reset's the model to it's
// origional state when initialized. Uses the dynamicDefaults to
// determin which properties were used.
//
// @api public

ContentMigration.prototype.resetModel = function () {
  this.clear()
  this.resetDynamicDefaultCollections()
  return this.set(this.dynamicDefaults)
}

// Loop through all defaults and reset any collections to be blank that
// might exist.
//
// @api private

ContentMigration.prototype.resetDynamicDefaultCollections = function () {
  forEach(this.dynamicDefaults, function (value, _key, _list) {
    let collection, models
    if (value instanceof Backbone.Collection) {
      collection = value
      // Force models into an new array since we modify collections
      // models in the .each which effects the loop since
      // collection.models is pass by reference.
      models = collection.map(function (model) {
        return model
      })
      forEach(models, model => collection.remove(model))
      return models
    }
  })
  return this.dynamicDefaults
}

// Handles two cases. Migration with a file and without a file.
//
// The presence of a file in the migration is indicated by a
// `pre_attachment` field on the model. This field will contain a
// `fileElement` (a DOM node for an <input type="file">). A migration
// without a file (e.g. a course copy) is executed as a normal save.
//
// A migration with a file (e.g. an import) is executed in multiple stages.
// We first set aside the fileElement and save the remainder of the
// migration. In addition to creating the migration on the server, this acts
// as the preflight for the upload of the migration's file, with the
// preflight results being stored back into the model's `pre_attachment`. We
// then complete the upload as for any other file upload. Once completed, we
// reload the model to set the polling url, then resolve the deferred.
//
//  @returns deferred object
//  @api public backbone override

ContentMigration.prototype.save = function () {
  if (!this.get('pre_attachment')) {
    return ContentMigration.__super__.save.apply(this, arguments)
  }
  const dObject = $.Deferred()
  const resolve = (function (_this) {
    return function () {
      // sets the poll url
      return _this.fetch({
        success() {
          return dObject.resolve()
        },
      })
    }
  })(this)
  const reject = (function (_this) {
    return function (message) {
      return dObject.rejectWith(_this, message)
    }
  })(this)
  const fileElement = this.get('pre_attachment').fileElement
  delete this.get('pre_attachment').fileElement
  const file = fileElement.files[0]
  const {file: _omittedFile, ...args} = arguments[0]
  ContentMigration.__super__.save.call(this, args, {
    error: (function (_this) {
      return function (xhr) {
        return reject(xhr.responseText)
      }
    })(this),
    success: (function (_this) {
      return function (_model, _xhr, _options) {
        return completeUpload(_this.get('pre_attachment'), file, {
          ignoreResult: true,
          onProgress: _this.onProgress,
        })
          .catch(reject)
          .then(resolve)
      }
    })(this),
  })
  return dObject
}

// These models will have many SubDayModels via a collection. This model has attributes
// that must go with the request.
//
// @api private backbone override

ContentMigration.prototype.toJSON = function () {
  const json = ContentMigration.__super__.toJSON.apply(this, arguments)
  this.addDaySubsitutions(json)
  this.translateDateAdjustmentParams(json)
  return json
}

// Add day substituions to a json object if this model has a daySubCollection.
// remember json is pass by reference so changes are reflected on the origional
// json object
//
// @api private

ContentMigration.prototype.addDaySubsitutions = function (json) {
  const collection = this.daySubCollection
  json.date_shift_options || (json.date_shift_options = {})
  if (collection) {
    return (json.date_shift_options.day_substitutions = collection.toJSON())
  }
}

// Convert date adjustment (shift / remove) radio buttons into the format
// expected by the Canvas API
//
// @api private

ContentMigration.prototype.translateDateAdjustmentParams = function (json) {
  if (json.adjust_dates) {
    if (json.adjust_dates.enabled === '1') {
      json.date_shift_options[json.adjust_dates.operation] = '1'
    }
    return delete json.adjust_dates
  }
}

ContentMigration.prototype.progressValue = function (h) {
  return I18n.t('%{percent}%', {
    percent: Math.round((h.valueNow * 100) / h.valueMax),
  })
}

ContentMigration.prototype.onProgress = function (event) {
  let mountPoint
  if (event.lengthComputable) {
    mountPoint = document.getElementById('migration_upload_progress_bar')
    if (mountPoint) {
      // eslint-disable-next-line react/no-render-return-value
      return ReactDOM.render(
        React.createElement(ProgressBar, {
          screenReaderLabel: I18n.t('Uploading progress'),
          valueMax: event.total,
          valueNow: event.loaded,
          renderValue: this.progressValue,
          formatScreenReaderValue: this.progressValue,
          tabindex: 0,
        }),
        mountPoint
      )
    }
  }
}

export default ContentMigration
