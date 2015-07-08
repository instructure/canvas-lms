define [
  'jquery'
  'compiled/views/rubrics/EditRubricPage'
], ($, EditRubricPage) ->

  module 'EditRubricPage',

  test 'does not immediately create the dialog', ->
    clickSpy = sinon.spy EditRubricPage.prototype, 'attachInitialEvent'
    dialogSpy = sinon.spy EditRubricPage.prototype, 'createDialog'

    new EditRubricPage()
    ok clickSpy.called, 'sets up the initial click event'
    ok not dialogSpy.called, 'does not immediately create the dialog'

    clickSpy.restore()
    dialogSpy.restore()
