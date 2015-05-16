define [
  'jquery'
  'compiled/models/GroupCategory'
  'compiled/views/groups/manage/GroupCategoryCreateView'
  'helpers/fakeENV'
], ($, GroupCategory, GroupCategoryCreateView, fakeENV) ->

  view = null
  groupCategory = null

  module 'GroupCategoryCreateView',
    setup: ->
      fakeENV.setup({allow_self_signup: true})
      groupCategory = new GroupCategory()
      view = new GroupCategoryCreateView({model: groupCategory})
      view.render()
      view.$el.appendTo($("#fixtures"))

    teardown: ->
      fakeENV.teardown()
      view.remove()
      document.getElementById("fixtures").innerHTML = ""

  test 'toggling auto group leader enables and disables accompanying controls', ->
    $('.auto-group-leader-toggle').prop( "checked", true )
    $(".auto-group-leader-toggle").trigger('click')
    view.$autoGroupLeaderControls.find('label.radio').each ->
      equal $(this).css('opacity'), "1"
    $('.auto-group-leader-toggle').prop( "checked", false )
    $(".auto-group-leader-toggle").trigger('click')
    view.$autoGroupLeaderControls.find('label.radio').each ->
      equal $(this).css('opacity'), "0.5"

  test 'auto group leader controls are hidden if we arent splitting groups automatically', ->
    view.$autoGroupSplitControl.prop("checked", true)
    view.$autoGroupSplitControl.trigger('click')
    ok(view.$autoGroupLeaderControls.is(":visible"))
    view.$autoGroupSplitControl.prop("checked", false)
    view.$autoGroupSplitControl.trigger('click')
    ok(view.$autoGroupLeaderControls.is(":hidden"))
