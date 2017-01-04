define([
  'jquery',
  'account_settings'
], ($, {openReportDescriptionLink}) => {
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
})
