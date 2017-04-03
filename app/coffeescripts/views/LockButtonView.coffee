define [
  'i18n!lock_btn_module'
  'jquery'
  'compiled/fn/preventDefault'
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
    @optionProperty 'unlockedText'

    tagName:   'button'
    className: 'btn'

    events: {'click', 'hover'}

    els:
      'i': '$icon'
      '.lock-text': '$text'

    initialize: ->
      super
      # button is enabled only for master courses
      @disabled = !@model.get('is_master_course_master_content')
      @disabledClass = if @disabled then 'disabled' else ''

      @lockedText = @lockedText || I18n.t 'Locked. Click to unlock.'
      @unlockedText = @unlockedText || I18n.t 'Unlocked. Click to lock.'

    setElement: ->
      super
      @$el.attr 'data-tooltip', ''

    # events

    hover: ({type}) ->
      if type is 'mouseenter'
        if @isLocked()
          @renderUnlocked()
        else
          @renderLocked()
      else if type is 'mouseleave'
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
        "/api/v1/courses/#{@model.get('course_id')}/blueprint_templates/default/restrict_item",
        "PUT", {
          content_type: @options.type,
          content_id: @model.get('id'),
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

    reset: ->
      @$el.removeClass "#{@lockedClass} #{@unlockedClass} #{@disabledClass}"
      @$icon.removeClass 'icon-lock icon-unlock icon-unlocked'
      @$el.removeAttr 'aria-label'
      @closeTooltip()

    closeTooltip: ->
      $(".ui-tooltip").remove()

    # render

    render: ->
      if(!@disabled)
        @$el.attr 'role', 'button'
        @$el.attr 'tabindex', '0'

      @$el.html '<i></i><span class="lock-text screenreader-only"></span>'
      @cacheEls()

      if @isLocked()
        @renderLocked()
      else
        @renderUnlocked()

    renderUnlocked: () ->
      @renderState
        hint:        I18n.t 'Lock'
        label:       @unlockedText
        buttonClass: "#{@unlockedClass} #{@disabledClass}"
        iconClass:   'icon-unlock'

    renderLocked: () ->
      @renderState
        hint:        I18n.t 'Unlock'
        label:       @lockedText
        buttonClass: "#{@lockedClass} #{@disabledClass}"
        iconClass:   'icon-lock'

    renderLocking: () ->
      @renderState
        hint:        I18n.t 'Locking...'
        buttonClass: "#{@unlockedClass} #{@disabledClass}"
        iconClass:   'icon-unlock'

    renderUnlocking: () ->
      @renderState
        hint:        I18n.t 'Unlocking...'
        buttonClass: "#{@lockedClass} #{@disabledClass}"
        iconClass:   'icon-lock'

    renderState: (options) ->
      @reset()
      @$el.addClass options.buttonClass
      if !@disabled
        @$el.attr 'aria-pressed', options.buttonClass is @lockedClass
      @$icon.addClass options.iconClass

      @$text.html "#{htmlEscape(options.label || options.hint)}"

      @$el.attr 'title', options.hint   # tooltip picks this up (and htmlEscapes it)
