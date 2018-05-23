#
# Copyright (C) 2017 - present Instructure, Inc.
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
  'i18n!lock_btn_module'
  'jquery'
  '../fn/preventDefault'
  'Backbone'
  'str/htmlEscape'
  'jquery.instructure_forms'
], (I18n, $, preventDefault, Backbone, htmlEscape) ->

  # render as a working button when in a master course,
  # and as a plain old span if not
  class LockButton extends Backbone.View
    lockedClass: 'btn-locked'
    unlockedClass: 'btn-unlocked'
    disabledClass: 'disabled'

    # These values allow the default text to be overridden if necessary
    @optionProperty 'lockedText'
    @optionProperty 'unlockedText',
    @optionProperty 'course_id',
    @optionProperty 'content_id'
    @optionProperty 'content_type'

    tagName:   'button'
    className: 'btn'

    events: {'click', 'hover', 'focus', 'blur'}

    els:
      'i': '$icon'
      '.lock-text': '$text'

    initialize: ->
      super
      # button is enabled only for master courses
      @disabled = !@isMasterCourseMasterContent()
      @disabledClass = if @disabled then 'disabled' else ''

      @lockedText = @lockedText || I18n.t 'Locked. Click to unlock.'
      @unlockedText = @unlockedText || I18n.t 'Unlocked. Click to lock.'

    setElement: ->
      super
      @$el.attr 'data-tooltip', ''

    # events

    hover: ({type}) ->
      return if @disabled
      if type is 'mouseenter'
        if @isLocked()
          @renderWillUnlock()
        else
          @renderWillLock()
      else if type is 'mouseleave'
        if @isLocked()
          @renderLocked()
        else
          @renderUnlocked()

    focus: () ->
      @focusblur()

    blur: () ->
      @focusblur()

    # this causes the button to re-render as it is which seems dumb,
    # but if you don't, the tooltip gets stuck forever with the hover text
    # after mouseenter/leave. Even now,
    # focus-blur-mouseenter-mouseleave-focus and the tooltip is left from hover
    # follow with blur-focus and it's corrected
    # I believe this is a but in jquery's tooltip.
    focusblur: () ->
      return if @disabled
      if @isLocked()
        @renderLocked()
      else
        @renderUnlocked()

    click: (event) ->
      event.preventDefault()
      event.stopPropagation()
      return if @disabled
      if @isLocked()
        @unlock()
      else
        @lock()

    setFocusToElement: ->
      @$el.focus()

    lock: (event) ->
      @renderLocking()
      @setLockState(true)

    unlock: (event) ->
      @renderUnlocking()
      @setLockState(false)

    setLockState: (locked) ->
      $.ajaxJSON(
        "/api/v1/courses/#{@course_id}/blueprint_templates/default/restrict_item",
        "PUT", {
          content_type: @content_type,
          content_id: @content_id,
          restricted: locked
        },
        (response) =>
          @model.set('restricted_by_master_course', locked)
          @trigger(if locked then "lock" else "unlock")
          @render()
          @setFocusToElement()
          @closeTooltip()
          null
        ,
        (error) =>
          @setFocusToElement()
      )

    # state
    isLocked: ->
      @model.get('restricted_by_master_course')

    isMasterCourseMasterContent: ->
      !!@model.get('is_master_course_master_content')

    isMasterCourseChildContent: ->
      !!@model.get('is_master_course_child_content')

    isMasterCourseContent: ->
      @isMasterCourseMasterContent() || @isMasterCourseChildContent()

    reset: ->
      @$el.removeClass "#{@lockedClass} #{@unlockedClass} #{@disabledClass}"
      @$icon.removeClass 'icon-lock icon-unlock icon-unlocked'
      @$el.removeAttr 'aria-label'
      @closeTooltip()

    closeTooltip: ->
      $(".ui-tooltip").remove()

    # render

    render: ->
      return unless @isMasterCourseContent()

      @$el.attr 'role', 'button'
      if(!@disabled)
        @$el.attr 'tabindex', '0'

      @$el.html '<i></i><span class="lock-text screenreader-only"></span>'
      @cacheEls()

      if @isLocked()
        @renderLocked()
      else
        @renderUnlocked()

    # when locked can...
    renderLocked: () ->
      @renderState
        hint:        I18n.t 'Locked'
        label:       @lockedText
        buttonClass: "#{@lockedClass} #{@disabledClass}"
        iconClass:   'icon-blueprint-lock'

    renderWillUnlock: () ->
      @renderState
        hint:        I18n.t 'Unlock'
        label:       @lockedText
        buttonClass: "#{@unlockedClass} #{@disabledClass}"
        iconClass:   'icon-blueprint'

    renderUnlocking: () ->
      @renderState
        hint:        I18n.t 'Unlocking...'
        buttonClass: "#{@lockedClass} #{@disabledClass}"
        iconClass:   'icon-blueprint-lock'

    # when unlocked can..
    renderUnlocked: () ->
      @renderState
        hint:        I18n.t 'Unlocked'
        label:       @unlockedText
        buttonClass: "#{@unlockedClass} #{@disabledClass}"
        iconClass:   'icon-blueprint'

    renderWillLock: () ->
      @renderState
        hint:        I18n.t 'Lock'
        label:       @unlockedText
        buttonClass: "#{@lockedClass} #{@disabledClass}"
        iconClass:   'icon-blueprint-lock'

    renderLocking: () ->
      @renderState
        hint:        I18n.t 'Locking...'
        buttonClass: "#{@unlockedClass} #{@disabledClass}"
        iconClass:   'icon-blueprint'

    renderState: (options) ->
      @reset()
      @$el.addClass options.buttonClass
      if !@disabled
        @$el.attr 'aria-pressed', options.buttonClass is @lockedClass
      else
        @$el.attr 'aria-disabled', true
      @$icon.attr('class', options.iconClass)

      @$text.html "#{htmlEscape(options.label || options.hint)}"

      @$el.attr 'title', options.hint   # tooltip picks this up (and htmlEscapes it)
