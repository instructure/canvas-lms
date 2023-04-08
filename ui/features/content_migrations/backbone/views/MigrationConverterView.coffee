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

import $ from 'jquery'
import _ from 'underscore'
import template from '../../jst/MigrationConverter.handlebars'
import ValidatedFormView from '@canvas/forms/backbone/views/ValidatedFormView'
import {useScope as useI18nScope} from '@canvas/i18n'
import 'jquery-tinypubsub'
import '@canvas/jquery/jquery.disableWhileLoading'
import {Alert} from '@instructure/ui-alerts'
import React from 'react'
import ReactDOM from 'react-dom'

I18n = useI18nScope('content_migrations')

# This is an abstract class that is inherited
# from by other MigrationConverter views
export default class MigrationConverterView extends ValidatedFormView
  @optionProperty 'selectOptions'

  template: template

  initialize: ->
    super
    $.subscribe 'resetForm', @resetForm

  els:
    '#converter'                : '$converter'
    '#chooseMigrationConverter' : '$chooseMigrationConverter'
    '#submitMigration'          : '$submitBtn'
    '.form-container'           : '$formActions'
    '#overwrite-warning'        : '$overwriteWarning'

  events: _.extend({}, @::events,
    'change #chooseMigrationConverter' : 'selectConverter'
    'click .cancelBtn'                 : 'resetForm'
  )

  toJSON: (json) ->
    json = super
    json.selectOptions = @selectOptions || ENV.SELECT_OPTIONS
    json

  # Render a backbone view (converter view) into
  # the converter div. Removes anything in the
  # converter div if there were any previous
  # items set.

  renderConverter: (converter) ->
    if converter
      # Set timeout ensures that all of the html is loaded at once. We need
      # this for accessibility to work correct.
      _.defer =>
        @$converter.html converter.render().$el
        @trigger 'converterRendered'
    else
      @resetForm()
      @trigger 'converterReset'

  # This is the actual action for making the view swaps when selecting
  # a different converter view. Ensures that when you select a new view
  # you are resetting the models data to it's dynamic defaults and setting
  # it's migration_type to the view being shown.
  #
  # @api private

  selectConverter: (event) ->
    @$formActions.show()
    @model.resetModel()
    @$chooseMigrationConverter.attr "aria-activedescendant", @$chooseMigrationConverter.val() # This is purely for accessibility
    @model.set 'migration_type', @$chooseMigrationConverter.val()
    $.publish 'contentImportChange', {value: @$chooseMigrationConverter.val(), migrationConverter: this}

  # Submit the form and call .save on the model. Handles validations. This override will
  # wait until the save is complete then publish the models attributes on an event that
  # is listened to in the content_migration bundle file. It also resets the form and
  # model. The awkward typeof is there because super may return null or a number on failure :(
  #
  # @expects event
  # @api ValidatedFormView override

  submit: (event) ->
    @enterUploadingState()
    dfd = super
    if dfd && typeof dfd == 'object'
      dfd.always =>
        @exitUploadingState()
      dfd.done =>
        $.publish 'migrationCreated', @model.attributes
        @model.resetModel()
        @resetForm()
    else
      @exitUploadingState()

  # Reseting the form will hide the submit buttons,
  # clear the form html and change the dropdown menu to be nothing. Model date gets reset
  # when switching dropdowns so should be fine.
  #
  # @api private

  resetForm: =>
    @$formActions.hide()
    @$converter.empty()
    @$chooseMigrationConverter.val('none')

  # Starts the progress bar or spinner, sets the button text to "Uploading",
  # enables the warning about navigating away from the page
  #
  # @api private
  enterUploadingState: =>
    @btnText = @$submitBtn.val()
    @$submitBtn.val(I18n.t('uploading', 'Uploading...'))
    $(window).on 'beforeunload', ->
      I18n.t('upload_warning', "Navigating away from this page will cancel the upload process.")
    if @model.get('migration_type') == 'course_copy_importer'
      @disableWhileLoadingOpts = {}
    else
      @disableWhileLoadingOpts = {noSpinner: true}
      $('#migration_upload_progress_container').show()

  # Resets button text, clears the beforeunload warning, and unmounts the progress bar
  # (otherwise, a 100% bar will briefly appear when a second content migration is started)
  #
  # @api private
  exitUploadingState: =>
    $(window).off 'beforeunload'
    $('#migration_upload_progress_container').hide()
    ReactDOM.unmountComponentAtNode(document.getElementById('migration_upload_progress_bar'))
    @$submitBtn.val(@btnText)

  afterRender: ->
    alert = React.createElement(Alert,
      {
        children: I18n.t('Importing the same course content more than once will overwrite any existing content in the course.'),
        variant: 'warning',
        hasShadow: false,
        margin: '0 0 medium 0'
      })
    ReactDOM.render(alert, @$overwriteWarning[0])
