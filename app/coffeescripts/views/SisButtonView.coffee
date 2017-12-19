#
# Copyright (C) 2016 - present Instructure, Inc.
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
  'i18n!assignments',
  'Backbone',
  'jquery',
  'jst/_sisButton',
  '../util/SisValidationHelper'
], (I18n, Backbone, $, template, SisValidationHelper) ->

  class SisButtonView extends Backbone.View
    template: template
    tagName: 'span'
    className: 'sis-button'
    events:
      'click': 'togglePostToSIS'

    # {string}
    # text used to describe the SIS NAME
    @optionProperty 'sisName'

    # {boolean}
    # boolean used to determine if due date
    # is required
    @optionProperty 'dueDateRequired'

    # {boolean}
    # boolean used to determine if name length
    # is required
    @optionProperty 'maxNameLengthRequired'

    setAttributes: ->
      newSisAttributes = @sisAttributes()
      @$input.attr({
        'src': newSisAttributes['src'],
        'alt': newSisAttributes['description'],
        'title': newSisAttributes['description']
      })
      @$label.text(newSisAttributes['label'])

    togglePostToSIS: (e) =>
      e.preventDefault()
      sisUrl = @model.get('toggle_post_to_sis_url')
      post_to_sis = @model.postToSIS()
      validationHelper = new SisValidationHelper({
        postToSIS: !post_to_sis
        dueDateRequired: @dueDateRequired
        dueDate: @model.dueAt()
        name: @model.name()
        maxNameLength: @model.maxNameLength()
        maxNameLengthRequired: @maxNameLengthRequired
        allDates: @model.allDates()
      })
      errors = @errorsExist(validationHelper)
      if errors['has_error'] == true && @model.sisIntegrationSettingsEnabled()
        $.flashWarning(errors['message'])
      else if sisUrl
        @toggleAriaPressed(post_to_sis)
        @model.postToSIS(!post_to_sis)
        @model.save({ override_dates: false }, {
          type: 'POST',
          url: sisUrl,
          success: =>
            @setAttributes()
        })
      else
        @toggleAriaPressed(post_to_sis)
        @model.postToSIS(!post_to_sis)
        @model.save({ override_dates: false }, {
          success: =>
            @setAttributes()
        })

    toggleAriaPressed: (post_to_sis) =>
      label = @$el.find('label')
      label.attr 'aria-pressed', !post_to_sis

    errorsExist: (validationHelper) =>
      errors = {}
      base_message = "Unable to sync with #{@sisName}."
      if validationHelper.dueDateMissing() && validationHelper.nameTooLong()
        errors['has_error'] = true
        errors['message'] = I18n.t("%{base_message} Please make sure %{name} has a due date and name is not too long.", name: @model.name(), base_message: base_message)
      else if validationHelper.dueDateMissing()
        errors['has_error'] = true
        errors['message'] = I18n.t("%{base_message} Please make sure %{name} has a due date.", name: @model.name(), base_message: base_message)
      else if validationHelper.nameTooLong()
        errors['has_error'] = true
        errors['message'] = I18n.t("%{base_message} Please make sure %{name} name is not too long.", name: @model.name(), base_message: base_message)
      errors

    sisAttributes: =>
      if @model.postToSIS()
        {
          src: '/images/svg-icons/svg_icon_sis_synced.svg',
          description: I18n.t('Sync to %{name} enabled. Click to toggle.', name: @sisName),
          label: I18n.t('The grade for this assignment will sync to the student information system.'),
        }
      else
        {
          src: '/images/svg-icons/svg_icon_sis_not_synced.svg',
          description: I18n.t('Sync to %{name} disabled. Click to toggle.', name: @sisName),
          label: I18n.t('The grade for this assignment will not sync to the student information system.')
        }


    render: ->
      super
      labelId = 'sis-status-label-'+ @model.id
      @$label = @$el.find('label')
      @$input = @$el.find('input')
      @$input.attr('aria-describedby': labelId)
      @$label.attr('id', labelId)
      @setAttributes()

    toJSON: ->
      postToSIS: @model.postToSIS()
