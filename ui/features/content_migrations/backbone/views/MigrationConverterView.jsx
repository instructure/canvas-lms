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
import $ from 'jquery'
import {extend as lodashExtend, defer} from 'lodash'
import template from '../../jst/MigrationConverter.handlebars'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import {useScope as useI18nScope} from '@canvas/i18n'
import 'jquery-tinypubsub'
import '@canvas/jquery/jquery.disableWhileLoading'
import {Alert} from '@instructure/ui-alerts'
import React from 'react'
import ReactDOM from 'react-dom'

const I18n = useI18nScope('content_migrations')

extend(MigrationConverterView, ValidatedFormView)

// This is an abstract class that is inherited
// from by other MigrationConverter views
function MigrationConverterView() {
  this.exitUploadingState = this.exitUploadingState.bind(this)
  this.enterUploadingState = this.enterUploadingState.bind(this)
  this.resetForm = this.resetForm.bind(this)
  return MigrationConverterView.__super__.constructor.apply(this, arguments)
}

MigrationConverterView.optionProperty('selectOptions')

MigrationConverterView.prototype.template = template

MigrationConverterView.prototype.initialize = function () {
  MigrationConverterView.__super__.initialize.apply(this, arguments)
  return $.subscribe('resetForm', this.resetForm)
}

MigrationConverterView.prototype.els = {
  '#converter': '$converter',
  '#chooseMigrationConverter': '$chooseMigrationConverter',
  '#submitMigration': '$submitBtn',
  '.form-container': '$formActions',
  '#overwrite-warning': '$overwriteWarning',
}

MigrationConverterView.prototype.events = lodashExtend(
  {},
  MigrationConverterView.prototype.events,
  {
    'change #chooseMigrationConverter': 'selectConverter',
    'click .cancelBtn': 'resetForm',
  }
)

MigrationConverterView.prototype.toJSON = function (json) {
  json = MigrationConverterView.__super__.toJSON.apply(this, arguments)
  json.selectOptions = this.selectOptions || ENV.SELECT_OPTIONS
  return json
}

// Render a backbone view (converter view) into
// the converter div. Removes anything in the
// converter div if there were any previous
// items set.

MigrationConverterView.prototype.renderConverter = function (converter) {
  if (converter) {
    return defer(
      (function (_this) {
        return function () {
          _this.$converter.html(converter.render().$el)
          return _this.trigger('converterRendered')
        }
      })(this)
    )
  } else {
    this.resetForm()
    return this.trigger('converterReset')
  }
}

// This is the actual action for making the view swaps when selecting
// a different converter view. Ensures that when you select a new view
// you are resetting the models data to it's dynamic defaults and setting
// it's migration_type to the view being shown.
//
// @api private
MigrationConverterView.prototype.selectConverter = function (_event) {
  this.$formActions.show()
  this.model.resetModel()
  this.$chooseMigrationConverter.attr('aria-activedescendant', this.$chooseMigrationConverter.val())
  this.model.set('migration_type', this.$chooseMigrationConverter.val())
  return $.publish('contentImportChange', {
    value: this.$chooseMigrationConverter.val(),
    migrationConverter: this,
  })
}

// Submit the form and call .save on the model. Handles validations. This override will
// wait until the save is complete then publish the models attributes on an event that
// is listened to in the content_migration bundle file. It also resets the form and
// model. The awkward typeof is there because super may return null or a number on failure :(
//
// @expects event
// @api ValidatedFormView override
MigrationConverterView.prototype.submit = function (_event) {
  this.enterUploadingState()
  const dfd = MigrationConverterView.__super__.submit.apply(this, arguments)
  if (dfd && typeof dfd === 'object') {
    dfd.always(
      (function (_this) {
        return function () {
          return _this.exitUploadingState()
        }
      })(this)
    )
    return dfd.done(
      (function (_this) {
        return function () {
          $.publish('migrationCreated', _this.model.attributes)
          _this.model.resetModel()
          return _this.resetForm()
        }
      })(this)
    )
  } else {
    return this.exitUploadingState()
  }
}

// Reseting the form will hide the submit buttons,
// clear the form html and change the dropdown menu to be nothing. Model date gets reset
// when switching dropdowns so should be fine.
//
// @api private
MigrationConverterView.prototype.resetForm = function () {
  this.$formActions.hide()
  this.$converter.empty()
  return this.$chooseMigrationConverter.val('none')
}

// Starts the progress bar or spinner, sets the button text to "Uploading",
// enables the warning about navigating away from the page
//
// @api private
MigrationConverterView.prototype.enterUploadingState = function () {
  this.btnText = this.$submitBtn.val()
  this.$submitBtn.val(I18n.t('uploading', 'Uploading...'))
  $(window).on('beforeunload', function () {
    return I18n.t(
      'upload_warning',
      'Navigating away from this page will cancel the upload process.'
    )
  })
  if (this.model.get('migration_type') === 'course_copy_importer') {
    return (this.disableWhileLoadingOpts = {})
  } else {
    this.disableWhileLoadingOpts = {
      noSpinner: true,
    }
    return $('#migration_upload_progress_container').show()
  }
}

// Resets button text, clears the beforeunload warning, and unmounts the progress bar
// (otherwise, a 100% bar will briefly appear when a second content migration is started)
//
// @api private
MigrationConverterView.prototype.exitUploadingState = function () {
  $(window).off('beforeunload')
  $('#migration_upload_progress_container').hide()
  ReactDOM.unmountComponentAtNode(document.getElementById('migration_upload_progress_bar'))
  return this.$submitBtn.val(this.btnText)
}

MigrationConverterView.prototype.afterRender = function () {
  // eslint-disable-next-line react/no-children-prop
  const alert = React.createElement(Alert, {
    children: I18n.t(
      'Importing the same course content more than once will overwrite any existing content in the course.'
    ),
    variant: 'warning',
    hasShadow: false,
    margin: '0 0 medium 0',
  })
  if (this.$overwriteWarning[0]) {
    return ReactDOM.render(alert, this.$overwriteWarning[0])
  }
}

export default MigrationConverterView
