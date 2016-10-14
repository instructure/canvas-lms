define [
  'jquery'
  'Backbone'
  'helpers/fakeENV'
  'compiled/models/OutcomeGroup'
  'compiled/views/outcomes/OutcomeGroupView'
  'helpers/fixtures'
], ($, Backbone, fakeENV, OutcomeGroup, OutcomeGroupView, fixtures) ->

  createView = (opts) ->
    view = new OutcomeGroupView(opts)
    view.$el.appendTo($("#fixtures"))
    view.render()

  module 'OutcomeGroupView',
    setup: ->
      fixtures.setup()
      fakeENV.setup()
      ENV.PERMISSIONS = {manage_outcomes: true}
      @outcomeGroup = new OutcomeGroup({
        "context_type" : "Course",
        'url': 'www.example.com',
        "context_id" : 1,
        'parent_outcome_group': {
          'subgroups_url': "www.example.com"
        }
      })

    teardown: ->
      fixtures.teardown()
      fakeENV.teardown()

  test 'placeholder text is rendered properly for new outcome groups', ->
    view = createView(state: 'add', model: @outcomeGroup)
    equal view.$('input[name="title"]').attr("placeholder"), 'New Outcome Group'
    view.remove()

  test 'validates title is present', ->
    view = createView(state: 'add', model: @outcomeGroup)
    view.$('#outcome_group_title').val("")
    ok !view.isValid()
    ok view.errors.title
    view.remove()
