define [
  'compiled/views/assignments/GroupCategorySelector'
  'compiled/models/Assignment'
  'jsx/due_dates/StudentGroupStore'
  'jquery'
], (GroupCategorySelector, Assignment, StudentGroupStore, $) ->

  module "GroupCategorySelector",
    setup: ->
      @assignment = new Assignment
      @assignment.groupCategoryId("1")
      @groupCategories = [
        {id: "1", name: 'GS1'},
        {id: "2", name: 'GS2'}]
      @groupCategorySelector =
        new GroupCategorySelector parentModel: @assignment, groupCategories: @groupCategories
      @groupCategorySelector.render()
      $('#fixtures').append @groupCategorySelector.$el

    teardown: ->
      @groupCategorySelector.remove()
      $('#fixtures').empty()

  test "groupCategorySelected should set StudentGroupStore's group set", ->
    strictEqual StudentGroupStore.getSelectedGroupSetId(), "1"
    @groupCategorySelector.$groupCategoryID.val(2)
    @groupCategorySelector.groupCategorySelected()
    strictEqual StudentGroupStore.getSelectedGroupSetId(), "2"

