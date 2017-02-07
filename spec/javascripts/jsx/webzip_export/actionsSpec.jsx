define([
  'jsx/webzip_export/actions',
], (Actions) => {
  module('WebZip Export Actions');

  test('createNewExport returns the proper action', () => {
    const payload = {date: 'July 20, 1969 @ 20:18 UTC', link: 'http://example.com/manonthemoon'}
    const actual = Actions.actions.createNewExport(payload);
    const expected = {
      type: 'CREATE_NEW_EXPORT',
      payload
    };

    deepEqual(actual, expected);
  })
})
