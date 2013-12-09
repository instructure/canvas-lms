define [
  'underscore'
  'jquery'
], (_, $) ->

  # Floating sticky
  #
  # allows an element to float (using fixed positioning) as the user
  # scrolls, "sticking" to the top of the window. the difference from
  # a regular sticky implementation is that the element is constrained
  # by a containing element (or top and bottom elements), allowing the
  # element to float and stick, but only within the given bounds.
  #
  # to use, simply call .floatingSticky(containing_element) on a
  # jQuery object. optionally the top or bottom constraining element
  # can be overridden by providing {top:...} or {bottom:...} as the
  # last argument when calling .floatingSticky(...).
  #
  # the returned array has a floating sticky instance for each object
  # in the jQuery set, allowing calls to reposition() (in case the
  # element should be repositioned outside of a scroll/resize event)
  # or remove() to remove the floating sticky instance from the
  # element.

  instanceID = 0
  class FloatingSticky
    constructor: (el, container, options={}) ->
      @instanceID = "floatingSticky#{instanceID++}"

      @$window = $(window)
      @$el = $(el)
      @$top = $(options.top || container)
      @$bottom = $(options.bottom || container)

      @$el.data('floatingSticky', this)

      @$window.on "scroll.#{@instanceID} resize.#{@instanceID}", =>
        @reposition()
      @reposition()

    remove: ->
      @$window.off @instanceID
      @$el.data('floatingSticky', null)

    reposition: ->
      windowTop = @$window.scrollTop()
      windowHeight = @$window.height()

      # handle overscroll (up or down)
      if windowTop < 0
        windowTop = 0
      else
        windowTop = Math.min(windowTop, document.body.scrollHeight - windowHeight)

      # handle top of container
      containerTop = @$top.offset().top
      if windowTop < containerTop
        if windowTop == 0
          newTop = containerTop
        else
          newTop = containerTop - windowTop

      # handle bottom of container
      else
        newTop = 0
        elHeight = @$el.height()
        containerBottom = @$bottom.offset().top + @$bottom.height()

        # stay within the container
        if windowTop + elHeight > containerBottom
          newTop = containerBottom - elHeight - windowTop

        # but don't go above the container
        if newTop < containerTop - windowTop
          newTop = containerTop - windowTop

      @$el.css(top: newTop)

  $.fn.floatingSticky = (container, options={}) ->
    @map ->
      floatingSticky = $(this).data('floatingSticky')
      floatingSticky = new FloatingSticky(this, container, options) unless floatingSticky
      floatingSticky

  FloatingSticky
