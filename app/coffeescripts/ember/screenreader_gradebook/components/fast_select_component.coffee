#converted to coffeescript from:
#https://gist.github.com/kselden/7758990

define [
  'ember'
], ({Component, get, set}) ->
  doc = document

  FastSelectComponent = Component.extend

    initialized: false
    items: null
    valuePath: 'value'
    labelPath: 'label'
    labelDefault: null
    valueDefault: ''
    value: null
    selected: null

    tagName: 'select'

    didInsertElement: ->
      self = this
      @$().on('change', ->
        set(self, 'value', @value)
      )

    valueDidChange: (->
      items = @items
      value = @value
      selected = null
      if (value && items)
        selected = items.findBy(@valuePath, value)
      set(this, 'selected', selected)
    ).observes('value').on('init')

    itemsWillChange: (->
      items = @items
      if (items)
        items.removeArrayObserver(this)
        @arrayWillChange(items, 0, get(items, 'length'), 0)
    ).observesBefore('items').on('willDestroyElement')

    itemsDidChange: (->
      items = @items
      if (items)
        items.addArrayObserver(this)
        @arrayDidChange(items, 0, 0, get(items, 'length'))
        @insertDefaultOption()
    ).observes('items').on('didInsertElement')

    arrayWillChange: (items, start, removeCount, addCount) ->
      select = get(this, 'element')
      options = select.childNodes
      i = start + removeCount - 1
      while i >= start
        select.removeChild(options[i])
        i--

    arrayDidChange: (items, start, removeCount, addCount) ->
      select = get(this, 'element')
      i = start
      l = start + addCount

      while i < l
        item = items.objectAt(i)
        value = get(item, @valuePath)
        label = get(item, @labelPath)
        option = doc.createElement("option")
        option.textContent = label
        option.value = value
        if (@value == value)
          option.selected = true
          set(this, 'selected', item)
        select.appendChild(option)
        i++

      set(this, 'value', select.value)

    insertDefaultOption: ->
      return unless @labelDefault and not @isInitialized
      select = get(this, 'element')
      option = doc.createElement("option")
      option.textContent = @labelDefault
      option.value = @valueDefault
      select.appendChild(option)

      set(@, 'isInitialized', true)

