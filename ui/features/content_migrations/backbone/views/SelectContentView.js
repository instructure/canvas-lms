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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import $ from 'jquery'
import {isEmpty, pick} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import template from '../../jst/SelectContent.handlebars'
import wrapperTemplate from '@canvas/forms/jst/EmptyDialogFormWrapper.handlebars'
import checkboxCollectionTemplate from '../../jst/ContentCheckboxCollection.handlebars'
import DialogFormView from '@canvas/forms/backbone/views/DialogFormView'
import CollectionView from '@canvas/backbone-collection-view'
import CheckboxCollection from '../collections/ContentCheckboxCollection'
import CheckboxView from './ContentCheckboxView'
import NavigationForTree from './NavigationForTree'
import ExpandCollapseContentSelectTreeItems from './ExpandCollapseContentSelectTreeItems'
import CheckingCheckboxesForTree from './CheckingCheckboxesForTree'
import ScrollPositionForTree from './ScrollPositionForTree'

const I18n = useI18nScope('content_migrations')

extend(SelectContentView, DialogFormView)

function SelectContentView() {
  this.maintainTheTree = this.maintainTheTree.bind(this)
  this.selectContentDialogEvents = this.selectContentDialogEvents.bind(this)
  this.setSubmitButtonState = this.setSubmitButtonState.bind(this)
  this.firstOpen = this.firstOpen.bind(this)
  this.submit = this.submit.bind(this)
  return SelectContentView.__super__.constructor.apply(this, arguments)
}

SelectContentView.prototype.els = {
  '.form-dialog-content': '$formDialogContent',
  '#selectContentBtn': '$selectContentBtn',
}

SelectContentView.prototype.template = template

SelectContentView.prototype.wrapperTemplate = wrapperTemplate

// Remove attributes from the model that shouldn't be sent by picking
// them out of the original attributes, clearning the model then
// re-setting the model. Trigger the models continue event which
// will start polling the progress bar again. See the
// ProgressingMigrationView for the 'continue' event handler.
//
// @api private
SelectContentView.prototype.submit = function (event) {
  const attr = pick(this.model.attributes, 'id', 'workflow_state', 'user_id')
  this.model.clear({
    silent: true,
  })
  this.model.set(attr)
  this.$el.find('.module_options').each(function () {
    const $mo = $(this)
    if ($mo.find('input[value="separate"]').is(':checked')) {
      $mo.data('checkbox').prop({
        checked: false,
      })
      return $('input[name="copy[all_context_modules]"]').prop({
        checked: false,
      })
    }
  })
  if (isEmpty(this.getFormData())) {
    event.preventDefault()
    alert(I18n.t('no_content_selected', 'You have not selected any content to import.'))
    return false
  } else {
    const dfd = SelectContentView.__super__.submit.apply(this, arguments)
    return dfd != null
      ? dfd.done(
          (function (_this) {
            return function () {
              return _this.model.trigger('continue')
            }
          })(this)
        )
      : void 0
  }
}

// Fetch top level checkboxes that have lower level checkboxes.
// If the dialog has been opened before it will cache the old
// dialog window and re-open it instead of fetching the
// check boxes again.
// @api private
SelectContentView.prototype.firstOpen = function () {
  let ref, ref1
  SelectContentView.__super__.firstOpen.apply(this, arguments)
  this.checkboxCollection ||
    (this.checkboxCollection = new CheckboxCollection(null, {
      courseID: (ref = this.model) != null ? ref.course_id : void 0,
      migrationID: (ref1 = this.model) != null ? ref1.get('id') : void 0,
      isTopLevel: true,
      ariaLevel: 1,
    }))
  this.checkboxCollectionView ||
    (this.checkboxCollectionView = new CollectionView({
      collection: this.checkboxCollection,
      itemView: CheckboxView,
      el: this.$formDialogContent,
      template: checkboxCollectionTemplate,
    }))
  const dfd = this.checkboxCollection.fetch()
  this.$el.disableWhileLoading(dfd)
  dfd.done(
    (function (_this) {
      return function () {
        _this.maintainTheTree(_this.$el.find('ul[role=tree]'))
        return _this.selectContentDialogEvents()
      }
    })(this)
  )
  return this.checkboxCollectionView.render()
}

// You must have at least one checkbox selected in order to submit the form. Disable the submit
// button if there are not items selected.
SelectContentView.prototype.setSubmitButtonState = function () {
  let buttonState = true
  this.$el.find('input[type=checkbox]').each(function () {
    if (this.checked) {
      return (buttonState = false)
    }
  })
  return this.$selectContentBtn.prop('disabled', buttonState)
}

// Add SelectContent dialog box events. These events are general to the whole box.
// Keeps everything in one place
SelectContentView.prototype.selectContentDialogEvents = function () {
  this.$el.on(
    'click',
    '#cancelSelect',
    (function (_this) {
      return function () {
        return _this.close()
      }
    })(this)
  )
  return this.$el.on('change', 'input[type=checkbox]', this.setSubmitButtonState)
}

// These are the classes that help modify the tree. These methods will add events to the
// tree and keep things like scroll position correct as well as ensuring focus is being mantained.
SelectContentView.prototype.maintainTheTree = function ($tree) {
  new NavigationForTree($tree)
  new ExpandCollapseContentSelectTreeItems($tree)
  new CheckingCheckboxesForTree($tree)
  return new ScrollPositionForTree($tree, this.$formDialogContent)
}

export default SelectContentView
