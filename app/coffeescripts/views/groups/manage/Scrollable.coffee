define [
  'underscore'
  'jquery'
], (_, $) ->

  CLASS_ATTRIBUTE = 'ui-cnvs-scrollable'
  SCROLL_RATE = 10

  $footer = $window = $document = null
  p = (str) -> parseInt str, 10

  {
    afterRender: ->
      return if @_rendered

      @$el.addClass CLASS_ATTRIBUTE
      @$el.css 'overflowY', 'auto'

      @_initializeDragAndDropHandling()
      _.defer => @_initializeAutoResize()

      @_rendered = true

    _initializeAutoResize: ->
      $window or= $(window)
      # This procedure for finding $minHeightParent is not optimal. It's an 
      # attempt to find the first container with a min-height. (There will be 
      # at least one, the #main div whose min-height is 450px.) The number 30 
      # here is a weak way to skip over a more recent parent container whose 
      # min-height is inexplicably set to 30px.
      minHeightParent = _.find @$el.parents(), (el) ->
        p($(el).css('minHeight')) > 30
      return unless minHeightParent # bail out; probably in a test
      $minHeightParent = $(minHeightParent)
      oldMaxHeight = $minHeightParent.css('maxHeight')
      $minHeightParent.css 'maxHeight', $minHeightParent.css('minHeight')
      verticalOffset = $minHeightParent.offset().top || 0
      verticalOffset += p $minHeightParent.css('paddingTop')
      @_minHeight = $minHeightParent.height() + verticalOffset
      $minHeightParent.css 'maxHeight', oldMaxHeight
      $window.resize _.throttle (=> @_resize()), 50
      @_resize()

    _resize: ->
      $footer or= $('#footer')
      $document or= $(document)
      bottomSpacing = _.reduce @$el.parents(), (sum, el) ->
        $el = $(el)
        sum += p $el.css('marginBottom')
        sum += p $el.css('paddingBottom')
        sum += p $el.css('borderBottomWidth')
      , 0
      @_resize = ->
        offsetTop = @$el.offset().top
        availableHeight = $window.height()
        availableHeight -= $footer.outerHeight(true)
        availableHeight -= offsetTop
        availableHeight -= bottomSpacing
        @$el.height Math.max availableHeight, @_minHeight - offsetTop
      @_resize()

    _initializeDragAndDropHandling: ->
      @$el.on 'dragstart', (event, ui) =>
        @_$pointerScrollable = @$el

      @$el.on 'drag', ({pageX, pageY}, ui) =>
        clearTimeout @_checkScrollTimeout
        @_checkScroll = =>
          ui.helper.hide()
          $pointerElement = $ document.elementFromPoint(pageX, pageY)
          ui.helper.show()
          $scrollable = $pointerElement.closest(".#{CLASS_ATTRIBUTE}")
          $scrollable = @_$pointerScrollable unless $scrollable.length
          scrollTop = $scrollable.scrollTop()
          offsetTop = $scrollable.offset().top
          if scrollTop > 0 and ui.offset.top < offsetTop
            $scrollable.scrollTop scrollTop - SCROLL_RATE
          else if ui.offset.top + ui.helper.height() > offsetTop + $scrollable.height()
            $scrollable.scrollTop scrollTop + SCROLL_RATE
          @_$pointerScrollable = $scrollable
          @_checkScrollTimeout = setTimeout @_checkScroll, 50
        @_checkScroll()

      @$el.on 'dragstop', (event, ui) =>
        clearTimeout @_checkScrollTimeout
  }
