define [
  'jquery'
  'compiled/models/GroupCategory'
  'compiled/views/groups/manage/GroupCategoryEditView'
  'helpers/fakeENV'
], ($, GroupCategory, GroupCategoryEditView, fakeENV) ->

  view = null
  groupCategory = null

  module 'GroupCategoryEditView',
    setup: ->
      fakeENV.setup({allow_self_signup: true})
      groupCategory = new GroupCategory()
      view = new GroupCategoryEditView({model: groupCategory})
      view.render()
      view.$el.appendTo($(document.body))

    teardown: ->
      fakeENV.teardown()
      view.remove()

  test 'auto leadership is unset without model state', ->
    groupCategory.set('auto_leader', null)
    view.setAutoLeadershipFormState()
    equal(view.$autoGroupLeaderToggle.prop('checked'), false)


  test 'auto leadership corresponds to model state', ->
    groupCategory.set('auto_leader', 'random')
    view.setAutoLeadershipFormState()
    equal(view.$autoGroupLeaderToggle.prop('checked'), true)
    equal(view.$autoGroupLeaderControls.find("input[value='RANDOM']").prop('checked'), true)
    equal(view.$autoGroupLeaderControls.find("input[value='FIRST']").prop('checked'), false)

