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

import I18n from 'i18n!publish_btn_module'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import htmlEscape from 'html-escape'
import '@canvas/forms/jquery/jquery.instructure_forms'

export default class PublishButton extends Backbone.View
  disabledClass: 'disabled'
  publishClass: 'btn-publish'
  publishedClass: 'btn-published'
  unpublishClass: 'btn-unpublish'

  # This value allows the text to include the item title
  @optionProperty 'title'

  # These values allow the default text to be overridden if necessary
  @optionProperty 'publishText'
  @optionProperty 'unpublishText'

  # This indicates that the button is disabled specifically because it is
  # associated with a moderated assignment that the current user does not
  # have the Select Final Grade permission.
  @optionProperty 'disabledForModeration'

  tagName:   'button'
  className: 'btn'

  events: {'click', 'hover'}

  els:
    'i':             '$icon'
    '.publish-text': '$text'

  initialize: ->
    super
    @model?.on 'change:unpublishable', =>
      @disable() if !@model.get('unpublishable') && @model.get('published')

  setElement: ->
    super
    @$el.attr 'data-tooltip', ''
    @disable() if !@model.get('unpublishable') && @model.get('published')

  # events

  hover: ({type}) ->
    if type is 'mouseenter'
      return if @keepState or @isPublish() or @isDisabled()
      @renderUnpublish()
      @keepState = true
    else
      @keepState = false
      @renderPublished() unless @isPublish() or @isDisabled()

  click: (event) ->
    event.preventDefault()
    event.stopPropagation()
    return if @isDisabled()
    @keepState = true
    if @isPublish()
      @publish()
    else if @isUnpublish() or @isPublished()
      @unpublish()

  addAriaLabel: (label) ->
    $label = @$el.find('span.screenreader-only.accessible_label')
    $label = $('<span class="screenreader-only accessible_label"></span>').appendTo(@$el) unless $label.length

    $label.text label
    @$el.attr 'aria-label', label

  setFocusToElement: ->
    @$el.focus()

  # calling publish/unpublish on the model expects a deferred object

  publish: (event) ->
    @renderPublishing()
    @model.publish().always =>
      @trigger("publish")
      @enable()
      @render()
      @setFocusToElement()

  unpublish: (event) ->
    @renderUnpublishing()
    @model.unpublish()
    .done =>
      @trigger("unpublish")
      @disable()
      @render()
      @setFocusToElement()
    .fail (error) =>
      if error.status == 403
        $.flashError @model.disabledMessage()
      @disable()
      @renderPublished()
      @setFocusToElement()

  # state

  isPublish: ->
    @$el.hasClass @publishClass

  isPublished: ->
    @$el.hasClass @publishedClass

  isUnpublish: ->
    @$el.hasClass @unpublishClass

  isDisabled: ->
    @$el.hasClass @disabledClass

  disable: ->
    @$el.addClass @disabledClass

  enable: ->
    @$el.removeClass @disabledClass

  reset: ->
    @$el.removeClass "#{@publishClass} #{@publishedClass} #{@unpublishClass}"
    @$icon.removeClass 'icon-publish icon-unpublish icon-unpublished'
    @$el.removeAttr 'aria-label'

  publishLabel: ->
    return @publishText if @publishText
    return I18n.t('Unpublished.  Click to publish %{title}.', title: @title) if @title
    I18n.t('Unpublished.  Click to publish.')

  unpublishLabel: ->
    return @unpublishText if @unpublishText
    return I18n.t('Published.  Click to unpublish %{title}.', title: @title) if @title
    I18n.t('Published.  Click to unpublish.')

  # render

  render: ->
    unless @$el.is("button")
      @$el.attr 'role', 'button'

    @$el.attr 'tabindex', '0'
    @$el.html '<i></i><span class="publish-text"></span>'
    @cacheEls()

    # don't read text of button with screenreader
    @$text.attr 'tabindex', '-1'

    if @model.get('published')
      @renderPublished()
    else
      @renderPublish()
    @

  renderPublish: ->
    @renderState
      text:        I18n.t 'buttons.publish', 'Publish'
      label:       @publishLabel()
      buttonClass: @publishClass
      iconClass:   'icon-unpublish'

  renderPublished: ->
    @renderState
      text:        I18n.t 'buttons.published', 'Published'
      label:       @unpublishLabel()
      buttonClass: @publishedClass
      iconClass:   'icon-publish icon-Solid'

  renderUnpublish: ->
    text = I18n.t 'buttons.unpublish', 'Unpublish'
    @renderState
      text:        text
      buttonClass: @unpublishClass
      iconClass:   'icon-unpublish'

  renderPublishing: ->
    @disable()
    text = I18n.t 'buttons.publishing', 'Publishing...'
    @renderState
      text:        text
      buttonClass: @publishClass
      iconClass:   'icon-publish icon-Solid'

  renderUnpublishing: ->
    @disable()
    text = I18n.t 'buttons.unpublishing', 'Unpublishing...'
    @renderState
      text:        text
      buttonClass: @unpublishClass
      iconClass:   'icon-unpublished'

  renderState: (options) ->
    @reset()
    @$el.addClass options.buttonClass
    @$el.attr 'aria-pressed', options.buttonClass is @publishedClass
    @$icon.addClass options.iconClass

    @$text.html "&nbsp;#{htmlEscape(options.text)}"

    # uneditable because the current user does not have the Select Final
    # Grade permission.
    if @model.get('disabledForModeration')
      @disableWithMessage('You do not have permissions to edit this moderated assignment')

    # unpublishable (i.e., able to be unpublished)
    else if !@model.get('unpublishable')? or @model.get('unpublishable')
      @enable()
      @$el.attr 'title', options.text

      # label for screen readers
      if options.label
        @addAriaLabel(options.label)

    # editable, but cannot be unpublished because submissions exist
    else
      @disableWithMessage(@model.disabledMessage()) if @model.get('published')

  disableWithMessage: (message) ->
    @disable()
    @$el.attr 'aria-disabled', true
    @$el.attr 'title', message
    @addAriaLabel(message)
