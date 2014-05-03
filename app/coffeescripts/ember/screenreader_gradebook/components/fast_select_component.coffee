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
    ).observes('items').on('didInsertElement')

    arrayWillChange: (items, start, removeCount, addCount) ->
      select = get(this, 'element')
      options = select.childNodes
      i = start + removeCount - 1
      if get(this, 'hasDefaultOption')
        start = start + 1
        i = i + 1
      while i >= start
        select.removeChild(options[i])
        i--

    updateSelection: (->
      selected = get this, 'selected'
      return unless selected
      currentValue = get(selected, @valuePath)
      select = @$("[value=#{currentValue}]")
      select?[0]?.selected = true
      if currentValue and currentValue != @value
        set this, 'value', currentValue
    ).observes('selected')

    updateOptions: (->
      @arrayWillChange(@items, 0, get(@items, 'length'), 0)
      @arrayDidChange(@items, 0, 0, get(@items, 'length'))
    ).observes('labelPath')

    arrayDidChange: (items, start, removeCount, addCount) ->
      select = get(this, 'element')
      hasDefault = get(this, 'hasDefaultOption')
      if hasDefault
        start = start + 1
      i = start
      l = start + addCount

      while i < l
        ind = if hasDefault then i-1 else i
        item = items.objectAt(ind)
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

    insertDefaultOption: (->
      return unless @labelDefault and not @hasDefaultOption
      select = get(this, 'element')
      option = doc.createElement("option")
      option.textContent = @labelDefault
      option.value = @valueDefault
      select.appendChild(option)

      set(this, 'hasDefaultOption', true)
    ).observes('items').on('didInsertElement')


