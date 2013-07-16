define [
  'jquery'
  'compiled/jquery/sticky'
], ($) ->

  # Remember, you must define a toolbar with data attribute 'data-sticky'
  # for this to work. Also don't forget to create your own styles for the 
  # sticky class that gets added to the dom element

  afterRender: ->
    @stickyHeader.remove() if @stickyHeader
    @stickyHeader = @$('[data-sticky]').sticky()
