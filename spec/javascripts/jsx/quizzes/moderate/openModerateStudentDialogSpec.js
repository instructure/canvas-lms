define([
  'jsx/quizzes/moderate/openModerateStudentDialog'
], (openModerateStudentDialog) => {
  let $fixture = null
  QUnit.module('openModerateStudentDialog', {
    setup() {
      $fixture = $('#fixtures').html(`
        <div id='parent'>
           <div id='moderate_student_dialog'>   
            </div>               
            <a class='ui-dialog-titlebar-close' href='#'>
            </a>                                           
            </div>                                         
          </div>`
      )
    },

    teardown() {
      $('#fixtures').empty()
    }
  })

  test('is a function', () => {
    ok(typeof openModerateStudentDialog === 'function')
  })

  test('focues on close button when opened', () => {
    let dialog = openModerateStudentDialog($('#moderate_student_dialog'), 500)
    let focusButton = dialog.parent().find('.ui-dialog-titlebar-close')[0]
    ok(focusButton === document.activeElement)
  })
})
