define([
  'quiz_labels',
  'helpers/fixtures'
], (addAriaDescription, fixtures) => {
  var $elem = null

  module("Add aria descriptions", {
    setup() {
      $elem = $(
        '<div>' +
          '<input type="text" />' +
          '<div class="deleteAnswerId"></div>' +
          '<div class="editAnswerId"></div>' +
          '<div class="commentAnswerId"></div>' +
          '<div class="selectAsCorrectAnswerId"></div>' +
        '</div>'
      )

      $('#fixtures').html($elem[0])
    },

    teardown() {
      $('#fixtures').empty()
    }
  });

  test('add aria descriptions to quiz answer options', () => {
    addAriaDescription($elem, '1')
    equal($elem.find('input:text').attr('aria-describedby'), 'answer1')
    equal($elem.find('.deleteAnswerId').text(), 'Answer 1')
    equal($elem.find('.editAnswerId').text(), 'Answer 1')
    equal($elem.find('.commentAnswerId').text(), 'Answer 1')
    equal($elem.find('.selectAsCorrectAnswerId').text(), 'Answer 1')
  })
});
