define [
  'compiled/gradebook/GradebookHelpers'
  'jsx/gradebook/shared/constants'
], (GradebookHelpers, GradebookConstants) ->
  QUnit.module "GradebookHelpers#noErrorsOnPage",
    setup: ->
      @mockFind = @mock($, "find")

  test "noErrorsOnPage returns true when the dom has no errors", ->
    @mockFind.expects("find").once().returns([])

    ok GradebookHelpers.noErrorsOnPage()

  test "noErrorsOnPage returns false when the dom contains errors", ->
    @mockFind.expects("find").once().returns(["dom element with error message"])

    notOk GradebookHelpers.noErrorsOnPage()

  QUnit.module "GradebookHelpers#textareaIsGreaterThanMaxLength"

  test "textareaIsGreaterThanMaxLength is false at exactly the max allowed length", ->
    notOk GradebookHelpers.textareaIsGreaterThanMaxLength(GradebookConstants.MAX_NOTE_LENGTH)

  test "textareaIsGreaterThanMaxLength is true at greater than the max allowed length", ->
    ok GradebookHelpers.textareaIsGreaterThanMaxLength(GradebookConstants.MAX_NOTE_LENGTH + 1)

  QUnit.module "GradebookHelpers#maxLengthErrorShouldBeShown",
    setup: ->
      @mockFind = @mock($, "find")

  test "maxLengthErrorShouldBeShown is false when text length is exactly the max allowed length", ->
    notOk GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH)

  test "maxLengthErrorShouldBeShown is false when there are DOM errors", ->
    @mockFind.expects("find").once().returns(["dom element with error message"])
    notOk GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH + 1)

  test "maxLengthErrorShouldBeShown is true when text length is greater than" +
      "the max allowed length AND there are no DOM errors", ->
    @mockFind.expects("find").once().returns([])
    ok GradebookHelpers.maxLengthErrorShouldBeShown(GradebookConstants.MAX_NOTE_LENGTH + 1)
