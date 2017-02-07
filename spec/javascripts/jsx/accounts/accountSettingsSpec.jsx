define([
  'jquery',
  'account_settings'
], ($, {addUsersLink, openReportDescriptionLink}) => {
  module('AccountSettings.openReportDescriptionLink', {
    setup () {
      const $html = $('<div>').addClass('title').addClass('reports')
        .append($('<span>').addClass('title').text('Title'))
        .append($('<div>').addClass('report_description').text('Description'))
        .append($('<a>').addClass('trigger'));
      $html.find('a').click(openReportDescriptionLink);
      $('#fixtures').append($html);
    },
    teardown () {
      $('#fixtures').empty();
      $('.ui-dialog').remove();
    }
  });

  test('keeps the description in the DOM', () => {
    $('#fixtures .trigger').click();
    ok($('#fixtures .report_description').length);
  });

  module('AccountSettings.addUsersLink', {
    setup () {
      const $select = $('<select>').attr('id', 'admin_role_id')
        .append($('<option>').attr('val', '1'));
      const $form = $('<div>').attr('id', 'enroll_users_form')
        .append($select);
      const $trigger = $('<a>').addClass('trigger').click(addUsersLink);
      $('#fixtures').append($form);
      $('#fixtures').append($trigger);
      $form.hide();
    },
    teardown () {
      $('#fixtures').empty();
    }
  });

  test('keeps the description in the DOM', () => {
    $('#fixtures .trigger').click();
    equal(document.activeElement, $('#admin_role_id')[0]);
  });
})
