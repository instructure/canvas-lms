#
# Copyright (C) 2012 Instructure, Inc.
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
#

define [
  'i18n!outcomes'
  'jquery'
  'underscore'
  'compiled/views/ValidatedFormView'
  'compiled/views/editor/KeyboardShortcuts'
  'tinymce.editor_box'
  'compiled/jquery.rails_flash_notifications'
  'jquery.disableWhileLoading'
  'compiled/tinymce',
], (I18n, $, _, ValidatedFormView, RCEKeyboardShortcuts) ->

  # Superclass for OutcomeView and OutcomeGroupView.
  # This view is used to show, add, edit, and delete outcomes and groups.
  class OutcomeContentBase extends ValidatedFormView

    # overriding superclass
    tagName: 'div'
    className: 'wrapper'

    events: _.extend
      'click .edit_button': 'edit'
      'click .cancel_button': 'cancel'
      'click .delete_button': 'delete'
      'keyup input.outcome_title': 'updateTitle'
    , ValidatedFormView::events

    # A validation key is the field name to validate.
    # The value is a function that takes the form
    # data from @getFormData() and should return
    # an error message if the field is invalid or undefined
    # if it is valid.
    validations:
      title: (data) ->
        if _.isEmpty data.title
          I18n.t('blank_error', 'Cannot be blank')
        else if data.title.length > 255
          I18n.t('length_error', 'Must be 255 characters or less')

    # Returns true if there are no errors in @validations.
    # Also creates an @errors object for use in @showErrors()
    isValid: ->
      @errors = {}
      data = @getFormData()
      for fieldName, validation of @validations
        if errorMessage = validation data
          @errors[fieldName] = [{message: errorMessage}]
      _.isEmpty @errors

    # all options are optional
    initialize: (opts) ->
      @state = opts.state
      @_readOnly = opts.readOnly
      @on 'success', @success, this
      @on 'fail', @fail, this
      @setModelUrl()
      if @model.isAbbreviated() and @state isnt 'add'
        @state = 'loading'
        @$el.disableWhileLoading @model.fetch success: =>
          @state = opts.state
          @render()
      super

    _cleanUpTiny: => @$el.find('[name="description"]').editorBox 'destroy'

    submit: (e) =>
      e.preventDefault()
      @setModelUrl()
      @getTinyMceCode()
      if @isValid()
        super e
        @_cleanUpTiny()
        $('.edit_button').focus()
      else
        @showErrors @errors

    success: ->
      if @state is 'add'
        @trigger 'addSuccess', @model
        $.flashMessage I18n.t 'flash.addSuccess', 'Creation successful'
      else
        $.flashMessage I18n.t 'flash.updateSuccess', 'Update successful'
      @state = 'show'
      @render()
      $('.edit_button').focus()
      this

    fail: ->
      $.flashError I18n.t 'flash.error', "An error occurred. Please refresh the page and try again."

    getTinyMceCode: ->
      textarea = @$('textarea')
      textarea.val textarea.editorBox 'get_code'

    setModelUrl: ->
      @model.setUrlTo switch @state
        when 'add' then 'add'
        when 'delete' then 'delete'
        else 'edit'

    # overriding superclass
    getFormData: ->
      @$('form').toJSON()

    remove: ->
      @_cleanUpTiny() if @tinymceExists()
      @$el.hideErrors()
      @model.destroy() if @state is 'add' and @model.isNew()
      super arguments...

    cancel: (e) =>
      e.preventDefault()
      @resetModel()
      @_cleanUpTiny()
      @$el.hideErrors()
      if @state is 'add'
        @$el.empty()
        @model.destroy()
        @state = 'show'
        $('.add_outcome_link').focus()
      else
        @state = 'show'
        @render()
        $('.edit_button').focus()
      this

    edit: (e) =>
      e.preventDefault()
      @state = 'edit'
      # save @model state
      @_modelAttributes = @model.toJSON()
      @render()

    delete: (e) =>
      e.preventDefault()
      return unless confirm I18n.t('confirm.delete', 'Are you sure you want to delete?')
      @state = 'delete'
      @setModelUrl()
      @$el.disableWhileLoading @model.destroy
        success: =>
          $.flashMessage I18n.t('flash.deleteSuccess', 'Deletion successful')
          @trigger 'deleteSuccess'
          @remove()
          $('.add_outcome_link').focus()
        error: => $.flashError I18n.t('flash.deleteError', 'Something went wrong. Unable to delete at this time.')

    resetModel: ->
      @model.set @_modelAttributes

    setupTinyMCEViewSwitcher: =>
      $('.rte_switch_views_link').click (e) =>
        e.preventDefault()
        @$('textarea').editorBox 'toggle'
        # hide the clicked link, and show the other toggle link.
        $(e.currentTarget).siblings('.rte_switch_views_link').andSelf().toggle()

    addTinyMCEKeyboardShortcuts: =>
      keyboardShortcutsView = new RCEKeyboardShortcuts()
      keyboardShortcutsView.render().$el.insertBefore($('.rte_switch_views_link:first'))

    # Called from subclasses in render.
    readyForm: ->
      setTimeout =>
        @$('textarea').editorBox() # tinymce initializer
        @setupTinyMCEViewSwitcher()
        @addTinyMCEKeyboardShortcuts()
        @$('input:first').focus()

    readOnly: ->
      @_readOnly || ! @model.get 'can_edit'

    updateTitle: (e) =>
      @model.set 'title', e.currentTarget.value

    tinymceExists: =>
      return @$el.find('[name="description"]').length > 0 and @$el.find('[name="description"]').editorBox('exists?')
