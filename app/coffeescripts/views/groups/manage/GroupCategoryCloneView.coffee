#
# Copyright (C) 2015 - present Instructure, Inc.
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

define [
  'i18n!groups'
  '../../DialogFormView'
  'jst/EmptyDialogFormWrapper'
  'jst/groups/manage/groupCategoryClone'
], (I18n, DialogFormView, wrapperTemplate, template) ->

  class GroupCategoryCloneView extends DialogFormView

    template: template
    wrapperTemplate: wrapperTemplate
    className: "form-dialog group-category-clone"
    cloneSuccess: false
    changeGroups: false

    defaults:
      width: 520
      height: 450
      title: I18n.t("Clone Group Set")

    events: Object.assign {},
      DialogFormView::events
      'click .dialog_closer': 'close'
      'click .clone-options-toggle': 'toggleCloneOptions'

    openAgain: ->
      @cloneSuccess = false
      @changeGroups = false
      super
      # reset the form contents
      @render()
      $('.ui-dialog-titlebar-close').focus()

    toJSON: ->
      json = super
      json.displayCautionOptions = @options.openedFromCaution
      json

    toggleCloneOptions: ->
      cloneOption = @$("input:radio[name=clone_option]:checked").val()
      if cloneOption == "clone"
        @$('.cloned_category_name_option').show()
        @$('.cloned_category_name_option').attr('aria-hidden', false)
      else
        @$('.cloned_category_name_option').hide()
        @$('.cloned_category_name_option').attr('aria-hidden', true)

    submit: (event) ->
      event.preventDefault()

      data = @getFormData()

      if data['clone_option'] == 'do_not_clone'
        @changeGroups = true
        @close()
      else
        super(event)

    saveFormData: (data) ->
      @model.cloneGroupCategoryWithName(data['name'])

    onSaveSuccess: =>
      @cloneSuccess = true
      super
