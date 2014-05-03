define ['jquery', 'underscore', 'compiled/views/gradebook/CheckboxView'], ($, _, CheckboxView) ->

  module 'gradebook/CheckboxView',
    setup: ->
      @view = new CheckboxView(color: 'red', label: 'test label')
      @view.render()
      @view.$el.appendTo('#fixtures')
      @checkbox = @view.$el.find('.checkbox')

    teardown: ->
      $('#fixtures').empty()

  test 'displays checkbox and label', ->
    ok @view.$el.html().match(/test label/), 'should display label'
    ok @view.$el.find('.checkbox').length, 'should display checkbox'

  test 'toggles active state', ->
    ok @view.checked, 'should default to checked'
    @view.$el.click()
    ok !@view.checked, 'should uncheck when clicked'
    @view.$el.click()
    ok @view.checked, 'should check when clicked'

  test 'visually indicates state', ->
    checkedColor = @view.$el.find('.checkbox').css('background-color')
    ok _.include(['rgb(255, 0, 0)', 'red'], checkedColor), 'displays checked state'
    @view.$el.click()
    uncheckedColor = @view.$el.find('.checkbox').css('background-color')
    ok _.include(['rgba(0, 0, 0, 0)', 'transparent'], uncheckedColor), 'displays unchecked state'
