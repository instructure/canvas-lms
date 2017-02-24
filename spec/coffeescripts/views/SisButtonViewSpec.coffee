define [
  'jquery'
  'compiled/views/SisButtonView'
  'Backbone'
], ($, SisButtonView, Backbone) ->

  class AssignmentStub extends Backbone.Model
    url: '/fake'
    postToSIS: (postToSisBoolean) =>
      return @get 'post_to_sis' unless arguments.length > 0
      @set 'post_to_sis', postToSisBoolean

  class QuizStub extends Backbone.Model
    url: '/fake'
    postToSIS: (postToSisBoolean) =>
      return @get 'post_to_sis' unless arguments.length > 0
      @set 'post_to_sis', postToSisBoolean

  QUnit.module 'SisButtonView',
    setup: ->
      @assignment = new AssignmentStub()
      @quiz = new QuizStub()
      @quiz.set('toggle_post_to_sis_url', '/some_other_url')

  test 'properly populates initial settings', ->
    @assignment.set('post_to_sis', true)
    @quiz.set('post_to_sis', false)
    @view1 = new SisButtonView(model: @assignment, sisName: 'SIS')
    @view2 = new SisButtonView(model: @quiz, sisName: 'SIS')
    @view1.render()
    @view2.render()
    equal @view1.$input.attr('title'), 'Sync to SIS enabled. Click to toggle.'
    equal @view2.$input.attr('title'), 'Sync to SIS disabled. Click to toggle.'

  test 'properly populates initial settings with custom SIS name', ->
    @assignment.set('post_to_sis', true)
    @quiz.set('post_to_sis', false)
    @view1 = new SisButtonView(model: @assignment, sisName: 'PowerSchool')
    @view2 = new SisButtonView(model: @quiz, sisName: 'PowerSchool')
    @view1.render()
    @view2.render()
    equal @view1.$input.attr('title'), 'Sync to PowerSchool enabled. Click to toggle.'
    equal @view2.$input.attr('title'), 'Sync to PowerSchool disabled. Click to toggle.'

  test 'properly toggles model sis status when clicked', ->
    @assignment.set('post_to_sis', false)
    @view = new SisButtonView(model: @assignment)
    @view.render()
    @view.$el.click()
    ok @assignment.postToSIS()
    @view.$el.click()
    ok !@assignment.postToSIS()

  test 'does not override dates', ->
    saveStub = @stub(@assignment, 'save').callsFake(() ->)
    @view = new SisButtonView(model: @assignment)
    @view.render()
    @view.$el.click()
    ok saveStub.calledWith(override_dates: false)

  test 'properly saves model with a custom url if present', ->
    @stub @quiz, 'save', (attributes, options) ->
      ok options['url'], '/some_other_url'
    @quiz.set('post_to_sis', false)
    @view = new SisButtonView(model: @quiz)
    @view.render()
    @view.$el.click()
    ok @quiz.postToSIS()

  test 'properly associates button label via aria-describedby', ->
    @assignment.set('id', '1')
    @view = new SisButtonView(model: @assignment)
    @view.render()
    equal @view.$input.attr('aria-describedby'), 'sis-status-label-1'
    equal @view.$label.attr('id'), 'sis-status-label-1'
