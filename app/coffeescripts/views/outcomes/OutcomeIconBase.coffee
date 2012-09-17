define [
  'jquery'
  'Backbone'
  'str/htmlEscape'
  'jqueryui/draggable'
], ($, Backbone, h) ->

  # View for outcomes/groups shown in the directory view.
  class OutcomeIconBase extends Backbone.View

    tagName: 'li'

    events:
      'click': 'triggerSelect'

    initialize: (opts) ->
      @readOnly = opts.readOnly
      @dir = opts.dir
      @model.on 'change:title', @updateTitle, this
      @model.on 'remove', @remove, this
      @model.on 'select', @triggerSelect, this

    triggerSelect: (e) =>
      e.preventDefault() if e
      @trigger 'select', this
      @select()

    select: ->
      @$el.addClass 'selected'

    unSelect: ->
      @$el.removeClass 'selected'

    remove: ->
      @model.off 'change:title', @updateTitle, this
      @model.off 'remove', @remove, this
      @model.off 'select', @triggerSelect, this
      super

    updateTitle: ->
      @$('span').text h(@model.get 'title')

    render: ->
      @initDraggable() unless @readOnly
      @$el.data 'view', this
      this

    initDraggable: ->
      @$el.draggable
        scope: 'outcomes'
        containment: '.outcomes-sidebar'
        opacity: 0.7
        helper: 'clone'
        revert: 'invalid'
        scroll: false
        drag: (event, ui) ->
          i = $(this).data("draggable")
          o = i.options
          scrolled = false
          sidebar = i.relative_container
          sidebarOffsetLeft = sidebar.offset().left
          sidebarWidth = sidebar.width()

          if event.pageX - sidebarOffsetLeft < o.scrollSensitivity
            sidebar[0].scrollLeft = scrolled = sidebar[0].scrollLeft - o.scrollSpeed
          else if (sidebarOffsetLeft + sidebarWidth) - event.pageX < o.scrollSensitivity
            sidebar[0].scrollLeft = scrolled = sidebar[0].scrollLeft + o.scrollSpeed

          if scrolled isnt false and $.ui.ddmanager and !o.dropBehaviour
            $.ui.ddmanager.prepareOffsets i, event
