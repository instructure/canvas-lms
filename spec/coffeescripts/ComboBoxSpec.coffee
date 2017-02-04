define [
  'jquery'
  'compiled/widget/ComboBox'
  'helpers/simulateClick'
], ($, ComboBox, simulateClick)->
  QUnit.module 'ComboBox',
    setup: ->

    teardown: ->
      # remove a combobox if one was created
      @combobox.$el.remove() if @combobox?

  confirmSelected = (combobox, item) ->
    equal combobox.$menu.val(), combobox._value item

  test 'constructor: dom setup', ->
    items = [
      {label: 'label1', value: 'value1'}
      {label: 'label2', value: 'value2'}
      {label: 'label3', value: 'value3'}
    ]
    @combobox = new ComboBox items

    # should have the infrastructure in place
    ok @combobox.$el.hasClass 'ui-combobox'
    ok @combobox.$prev.hasClass 'ui-combobox-prev'
    ok @combobox.$next.hasClass 'ui-combobox-next'
    ok @combobox.$menu[0].tagName, 'SELECT'

    # should have the options (both flavors) set up according to items
    options = $('option', @combobox.$menu)

    equal options.length, 3
    for item, i in items
      equal options.eq(i).prop('value'), item.value
      equal options.eq(i).text(), item.label

    # should have the first item selected
    confirmSelected @combobox, items[0]

  test 'constructor: value', ->
    items = [
      {label: 'label1', id: 'id1'}
      {label: 'label2', id: 'id2'}
      {label: 'label3', id: 'id3'}
    ]
    valueFunc = (item) -> item.id
    @combobox = new ComboBox items, value: valueFunc

    options = $('option', @combobox.$menu)
    for item, i in items
      equal options.eq(i).prop('value'), valueFunc item

  test 'constructor: label', ->
    items = [
      {name: 'name1', value: 'value1'}
      {name: 'name2', value: 'value2'}
      {name: 'name3', value: 'value3'}
    ]
    labelFunc = (item) -> item.name
    @combobox = new ComboBox items, label: labelFunc

    options = $('option', @combobox.$menu)
    for item, i in items
      equal options.eq(i).text(), labelFunc item

  test 'constructor: selected', ->
    items = [
      {label: 'label1', value: 'value1'}
      {label: 'label2', value: 'value2'}
      {label: 'label3', value: 'value3'}
    ]
    selectedItem = items[2]
    @combobox = new ComboBox items, selected: selectedItem.value

    # should have the specified item selected
    confirmSelected @combobox, selectedItem

  test 'constructor: value and selected', ->
    items = [
      {label: 'label1', id: 'id1'}
      {label: 'label2', id: 'id2'}
      {label: 'label3', id: 'id3'}
    ]
    selectedItem = items[2]
    valueFunc = (item) -> item.id
    @combobox = new ComboBox items,
      value: valueFunc
      selected: valueFunc selectedItem

    # should have the specified item selected
    confirmSelected @combobox, selectedItem

  test 'select', ->
    items = [
      {label: 'label1', value: 'value1'}
      {label: 'label2', value: 'value2'}
      {label: 'label3', value: 'value3'}
    ]
    @combobox = new ComboBox items
    spy = @spy()
    @combobox.on 'change', spy

    # calling select should change selection and trigger callback with new
    # selected item
    @combobox.select items[2].value
    confirmSelected @combobox, items[2]
    # for some reason spy.withArgs(items[2]).calledOnce doesn't work
    ok spy.calledOnce
    equal spy.getCall(0).args[0], items[2]

    # calling with the current selection should not trigger callback
    spy.reset()
    @combobox.select items[2].value
    ok not spy.called

  test 'prev button', ->
    items = [
      {label: 'label1', value: 'value1'}
      {label: 'label2', value: 'value2'}
      {label: 'label3', value: 'value3'}
    ]
    @combobox = new ComboBox items, selected: items[1].value
    spy = @spy()
    @combobox.on 'change', spy

    # clicking prev button selects previous element
    simulateClick @combobox.$prev[0]
    confirmSelected @combobox, items[0]
    ok spy.calledOnce
    equal spy.getCall(0).args[0], items[0]

    # clicking from the front wraps around
    spy.reset()
    simulateClick @combobox.$prev[0]
    confirmSelected @combobox, items[2]
    ok spy.calledOnce
    equal spy.getCall(0).args[0], items[2]

  test 'prev button: one item', ->
    items = [{label: 'label1', value: 'value1'}]
    @combobox = new ComboBox items
    spy = @spy()
    @combobox.on 'change', spy

    # clicking prev button does nothing
    simulateClick @combobox.$prev[0]
    confirmSelected @combobox, items[0]
    ok not spy.called

  test 'next button', ->
    items = [
      {label: 'label1', value: 'value1'}
      {label: 'label2', value: 'value2'}
      {label: 'label3', value: 'value3'}
    ]
    @combobox = new ComboBox items, selected: items[1].value
    spy = @spy()
    @combobox.on 'change', spy

    # clicking prev button selects previous element
    simulateClick @combobox.$next[0]
    confirmSelected @combobox, items[2]
    ok spy.calledOnce
    equal spy.getCall(0).args[0], items[2]

    # clicking from the front wraps around
    spy.reset()
    simulateClick @combobox.$next[0]
    confirmSelected @combobox, items[0]
    ok spy.calledOnce
    equal spy.getCall(0).args[0], items[0]

  test 'next button: one item', ->
    items = [{label: 'label1', value: 'value1'}]
    @combobox = new ComboBox items
    spy = @spy()
    @combobox.on 'change', spy

    # clicking prev button does nothing
    simulateClick @combobox.$next[0]
    confirmSelected @combobox, items[0]
    ok not spy.called
