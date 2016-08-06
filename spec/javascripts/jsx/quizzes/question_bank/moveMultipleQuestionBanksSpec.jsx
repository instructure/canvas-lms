define([
  'jsx/quizzes/question_bank/moveMultipleQuestionBanks'
  ], (moveMultipleQuestionBanks) => {
  var $modal = null

  module("Move Multiple Question Banks", {
    setup() {
      $modal = $('#fixtures').html(
        "<div id='parent'>"                                +
        "  <div id='move_question_dialog'>"                +
        "  </div>"                                         +
        "  <a class='ui-dialog-titlebar-close' href='#'>"  +
        "  </a>"                                           +
        "  </div>"                                         +
        "</div>"
      )
    },

    teardown() {
      $('#fixtures').empty()
    }
  })


  test('is an object', () => {
    ok(typeof moveMultipleQuestionBanks === 'object')
  })

  test('set focus to the delete button when dialog opens', () => {
    sinon.stub(moveMultipleQuestionBanks, 'prepDialog')
    sinon.stub(moveMultipleQuestionBanks, 'showDialog')
    sinon.stub(moveMultipleQuestionBanks, 'loadData')
    let focusesButton = $modal.find('.ui-dialog-titlebar-close')[0]
    moveMultipleQuestionBanks.onClick({preventDefault: e => e})
    ok(focusesButton === document.activeElement)
  })
});
