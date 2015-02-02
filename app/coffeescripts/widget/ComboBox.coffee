define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/ComboBox'
  'str/htmlEscape'
  'vendor/ui.selectmenu'
], ($, _, Backbone, template, htmlEscape) ->

  ##
  # Build a combo box to represent a list of items.
  class ComboBox
    ##
    # Takes a list of items to fill the combobox, and the following options:
    #
    #      value: A function that produces the option value for a given item.
    #             Defaults to pulling the value property of the item.
    #
    #      label: A function that produces the option content for a given item.
    #             Defaults to pulling the label property of the item.
    #
    #   selected: The value of the initial selection. If absent, the first item
    #             will be the initial selection.
    #
    # Aside from evalutation by the value and label functions, the provided
    # items are opaque to the combo box. Whenever the selection changes, the
    # 'change' event on this object will be triggered with the item as
    # argument.
    constructor: (@items, opts={}) ->
      # override item transforms
      @_value = opts.value if opts.value?
      @_label = opts.label if opts.label?

      # construct dom tree and cache relevant pieces
      @$el = $ template()
      @$container = $('.ui-combobox-container', @$el)
      @$prev = $('.ui-combobox-prev', @$el)
      @$next = $('.ui-combobox-next', @$el)
      @$menu = $('select', @$container)

      # populate and instantiate the selectmenu
      @$menu.append (_.map @items, @_buildOption)...
      @$menu.selectmenu
        style: 'dropdown'
        width: '230px'
        format: @_formatOption
      @$selectmenu = @$menu.data('selectmenu').list

      # set initial selection
      @select opts.selected if opts.selected?

      # attach event handlers
      _.extend @, Backbone.Events
      @$menu.change => @trigger 'change', @selected()
      @$prev.bind 'click', @_previous
      @$next.bind 'click', @_next

    ##
    # Select a specific item by value.
    select: (value) ->
      oldIndex = @_index()
      @$menu.selectmenu "value", value

      # setting the value directly doesn't fire the change event, so we'll
      # trigger it ourselves, but only if there was an actual change.
      @$menu.change() unless @_index() is oldIndex

      # return self for chaining
      this

    ##
    # Retrieve the currently selected item.
    selected: ->
      @items[@_index()]

    ##
    # @api private
    # The index of the selected item.
    _index: ->
      @$menu[0].selectedIndex

    ##
    # @api private
    # Select the previous item in the combo.
    _previous: (e) =>
      e.preventDefault()
      e.stopPropagation()

      # n-1 and -1 are equal modulo n
      newIndex = (@_index() + @items.length - 1) % @items.length
      @select @_value @items[newIndex]

    ##
    # @api private
    # Select the next item in the combo.
    _next: (e) =>
      e.preventDefault()
      e.stopPropagation()

      newIndex = (@_index() + 1) % @items.length
      @select @_value @items[newIndex]

    ##
    # @api private
    # Default item to value conversion.
    _value: (item) ->
      item.value

    ##
    # @api private
    # Default item to label conversion.
    _label: (item) ->
      item.label

    ##
    # @api private
    # Build an <option> tag for an item.
    _buildOption: (item) =>
      "<option value='#{htmlEscape @_value item}'>#{htmlEscape @_label item}</option>"

    ##
    # @api private
    # Convert an option label to the displayed selectmenu item.
    _formatOption: (label) =>
      "<span class='ui-selectmenu-item'>#{htmlEscape label}</span>"
