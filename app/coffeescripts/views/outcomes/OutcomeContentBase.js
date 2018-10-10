//
// Copyright (C) 2012 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
//

import I18n from 'i18n!outcomes'
import $ from 'jquery'
import _ from 'underscore'
import ValidatedFormView from '../ValidatedFormView'
import RCEKeyboardShortcuts from '../editor/KeyboardShortcuts'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import '../../jquery.rails_flash_notifications'
import 'jquery.disableWhileLoading'

RichContentEditor.preloadRemoteModule()

export default class OutcomeContentBase extends ValidatedFormView {
  constructor(...args) {
    {
      // Hack: trick Babel/TypeScript into allowing this before super.
      if (false) { super(); }
      let thisFn = (() => { return this; }).toString();
      let thisName = thisFn.slice(thisFn.indexOf('return') + 6 + 1, thisFn.lastIndexOf(';')).trim();
      eval(`${thisName} = this;`);
    }
    this._cleanUpTiny = this._cleanUpTiny.bind(this)
    this.submit = this.submit.bind(this)
    this.cancel = this.cancel.bind(this)
    this.edit = this.edit.bind(this)
    this.delete = this.delete.bind(this)
    this.move = this.move.bind(this)
    this.setupTinyMCEViewSwitcher = this.setupTinyMCEViewSwitcher.bind(this)
    this.addTinyMCEKeyboardShortcuts = this.addTinyMCEKeyboardShortcuts.bind(this)
    this.updateTitle = this.updateTitle.bind(this)
    this.tinymceExists = this.tinymceExists.bind(this)
    super(...args)
  }

  static initClass() {
    // overriding superclass
    this.prototype.tagName = 'div'
    this.prototype.className = 'wrapper'

    this.prototype.events = _.extend(
      {
        'click .edit_button': 'edit',
        'click .cancel_button': 'cancel',
        'click .delete_button': 'delete',
        'click .move_button': 'move',
        'keyup input.outcome_title': 'updateTitle'
      },
      ValidatedFormView.prototype.events
    )

    // A validation key is the field name to validate.
    // The value is a function that takes the form
    // data from @getFormData() and should return
    // an error message if the field is invalid or undefined
    // if it is valid.
    this.prototype.validations = {
      title(data) {
        if (_.isEmpty(data.title)) {
          return I18n.t('blank_error', 'Cannot be blank')
        } else if (data.title.length > 255) {
          return I18n.t('length_error', 'Must be 255 characters or less')
        }
      }
    }
  }

  // Returns true if there are no errors in @validations.
  // Also creates an @errors object for use in @showErrors()
  isValid() {
    this.errors = {}
    const data = this.getFormData()
    for (const fieldName in this.validations) {
      var errorMessage
      const validation = this.validations[fieldName]
      if ((errorMessage = validation(data))) {
        this.errors[fieldName] = [{message: errorMessage}]
      }
    }
    return _.isEmpty(this.errors)
  }

  // all options are optional
  initialize(opts) {
    this.state = opts.state
    this._readOnly = opts.readOnly
    this.on('success', this.success, this)
    this.on('fail', this.fail, this)
    this.setModelUrl()
    if (this.model.isAbbreviated() && this.state !== 'add') {
      this.state = 'loading'
      this.$el.disableWhileLoading(
        this.model.fetch({
          success: () => {
            this.state = opts.state
            return this.render()
          }
        })
      )
    }
    return super.initialize(...arguments)
  }

  _cleanUpTiny() {
    return RichContentEditor.destroyRCE(this.$el.find('[name="description"]'))
  }

  submit(e) {
    e.preventDefault()
    this.setModelUrl()
    this.getTinyMceCode()
    if (this.isValid()) {
      super.submit(e)
      this._cleanUpTiny()
      $('.edit_button').focus()
    } else {
      return this.showErrors(this.errors)
    }
  }

  success() {
    if (this.state === 'add') {
      this.trigger('addSuccess', this.model)
      $.flashMessage(I18n.t('flash.addSuccess', 'Creation successful'))
    } else {
      $.flashMessage(I18n.t('flash.updateSuccess', 'Update successful'))
    }
    this.state = 'show'
    this.render()
    $('.edit_button').focus()
    return this
  }

  fail() {
    return $.flashError(
      I18n.t('flash.error', 'An error occurred. Please refresh the page and try again.')
    )
  }

  getTinyMceCode() {
    const textarea = this.$('textarea')
    return textarea.val(RichContentEditor.callOnRCE(textarea, 'get_code'))
  }

  setModelUrl() {
    return this.model.setUrlTo(
      (() => {
        switch (this.state) {
          case 'add':
            return 'add'
          case 'delete':
            return 'delete'
          case 'move':
            return 'move'
          default:
            return 'edit'
        }
      })()
    )
  }

  // overriding superclass
  getFormData() {
    return this.$('form').toJSON()
  }

  remove() {
    if (this.tinymceExists()) {
      this._cleanUpTiny()
    }
    this.$el.hideErrors()
    if (this.state === 'add' && this.model.isNew()) {
      this.model.destroy()
    }
    return super.remove(...arguments)
  }

  cancel(e) {
    e.preventDefault()
    this.resetModel()
    this._cleanUpTiny()
    this.$el.hideErrors()
    if (this.state === 'add') {
      this.$el.empty()
      this.model.destroy()
      this.state = 'show'
      $('.add_outcome_link').focus()
    } else {
      this.state = 'show'
      this.render()
      $('.edit_button').focus()
    }
    return this
  }

  edit(e) {
    e.preventDefault()
    this.state = 'edit'
    // save @model state
    this._modelAttributes = this.model.toJSON()
    return this.render()
  }

  delete(e) {
    e.preventDefault()
    if (!confirm(I18n.t('confirm.delete', 'Are you sure you want to delete?'))) return
    this.state = 'delete'
    this.setModelUrl()
    return this.$el.disableWhileLoading(
      this.model.destroy({
        success: () => {
          $.flashMessage(I18n.t('flash.deleteSuccess', 'Deletion successful'))
          this.trigger('deleteSuccess')
          this.remove()
          $('.add_outcome_link').focus()
        },
        error: () =>
          $.flashError(
            I18n.t('flash.deleteError', 'Something went wrong. Unable to delete at this time.')
          )
      })
    )
  }

  move(e) {
    e.preventDefault()
    return this.trigger('move', this.model)
  }

  resetModel() {
    return this.model.set(this._modelAttributes)
  }

  setupTinyMCEViewSwitcher() {
    $('.rte_switch_views_link').click(e => {
      e.preventDefault()
      RichContentEditor.callOnRCE(this.$('textarea'), 'toggle')
      // hide the clicked link, and show the other toggle link.
      $(e.currentTarget)
        .siblings('.rte_switch_views_link')
        .andSelf()
        .toggle()
        .focus()
    })
  }

  addTinyMCEKeyboardShortcuts() {
    const keyboardShortcutsView = new RCEKeyboardShortcuts()
    return keyboardShortcutsView.render().$el.insertBefore($('.rte_switch_views_link:first'))
  }

  // Called from subclasses in render.
  readyForm() {
    return setTimeout(() => {
      RichContentEditor.loadNewEditor(this.$('textarea'), {
        getRenderingTarget(t) {
          const wrappedTextarea = $(t)
            .wrap(`<div id='parent-of-${t.id}'></div>`)
            .get(0)
          return wrappedTextarea.parentNode
        }
      }) // tinymce initializer
      this.setupTinyMCEViewSwitcher()
      this.addTinyMCEKeyboardShortcuts()
      return this.$('input:first').focus()
    })
  }

  readOnly() {
    return this._readOnly
  }

  updateTitle(e) {
    return this.model.set('title', e.currentTarget.value)
  }

  tinymceExists() {
    const localElExists = this.$el.find('[name="description"]').length > 0
    const editorElExists = RichContentEditor.callOnRCE(
      this.$el.find('[name="description"]'),
      'exists?'
    )
    return localElExists && editorElExists
  }
}
OutcomeContentBase.initClass()
