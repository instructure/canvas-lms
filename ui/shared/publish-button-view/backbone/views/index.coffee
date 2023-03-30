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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import htmlEscape from 'html-escape'
import '@canvas/forms/jquery/jquery.instructure_forms'
import tz from '@canvas/timezone'
import React from 'react'
import ReactDOM from 'react-dom'
import DelayedPublishDialog from '@canvas/publish-button-view/react/components/DelayedPublishDialog'

I18n = useI18nScope('publish_btn_module')

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
    '.dpd-mount':    '$dpd_mount'

  initialize: ->
    super
    @model?.on 'change:unpublishable', =>
      @disable() if !@model.get('unpublishable') && @model.get('published')

  setElement: ->
    super
    @disable() if !@model.get('unpublishable') && @model.get('published')

  # events

  hover: ({type}) ->
    return if @isDelayedPublish()

    if type is 'mouseenter'
      return if @keepState or @isPublish() or @isDisabled()
      @renderUnpublish()
      @keepState = true
    else
      @keepState = false
      @renderPublished() unless @isPublish() or @isDisabled()

  click: (event) ->
    return @openDelayedPublishDialog() if @isDelayedPublish()

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
      $sgLink = $("#speed-grader-container-" + @model.attributes.module_type + "-" + @model.attributes.content_id)
      $sgLink.removeClass("hidden")

  unpublish: (event) ->
    @renderUnpublishing()
    @model.unpublish()
    .done =>
      @trigger("unpublish")
      @disable()
      @render()
      @setFocusToElement()
      $sgLink = $("#speed-grader-container-" + @model.attributes.module_type + "-" + @model.attributes.content_id)
      $sgLink.addClass("hidden")
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

  isDelayedPublish: ->
    ENV?.FEATURES?.scheduled_page_publication && !@model.get('published') && @model.get('publish_at')

  disable: ->
    @$el.addClass @disabledClass

  enable: ->
    @$el.removeClass @disabledClass

  reset: ->
    @$el.removeClass "#{@publishClass} #{@publishedClass} #{@unpublishClass} published-status restricted"
    @$icon.removeClass 'icon-publish icon-unpublish icon-unpublished'
    @$el.removeAttr 'title aria-label'

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
    @$el.html '<i></i><span class="publish-text"></span><span class="dpd-mount"></span>'
    @cacheEls()

    # don't read text of button with screenreader
    @$text.attr 'tabindex', '-1'

    if @model.get('published')
      @renderPublished()
    else if @isDelayedPublish()
      @renderDelayedPublish()
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

  renderDelayedPublish: =>
    @renderState
      text: I18n.t('Will publish on %{publish_date}', {publish_date: tz.format(@model.get('publish_at'), 'date.formats.short')})
      iconClass: 'icon-calendar-month'
      buttonClass: if @$el.is("button") then '' else 'published-status restricted'

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
      @$el.data 'tooltip', 'left'
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
    @$el.data 'tooltip', 'left'
    @addAriaLabel(message)

  openDelayedPublishDialog: () ->
    props =
      name: @model.get('title') || @model.get('module_item_name')
      courseId: ENV.COURSE_ID
      contentId: @model.get('page_url') || @model.get('url') || @model.get('id')
      publishAt: @model.get('publish_at')
      onPublish: () => @publish()
      onUpdatePublishAt: (val) =>
        @model.set('publish_at', val)
        @render()
        @setFocusToElement()
      onClose: () => ReactDOM.unmountComponentAtNode @$dpd_mount[0]
    ReactDOM.render React.createElement(DelayedPublishDialog, props), @$dpd_mount[0]
