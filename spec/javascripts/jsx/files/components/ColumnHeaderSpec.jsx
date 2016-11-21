define([
  'react',
  'react-addons-test-utils',
  'jsx/files/ColumnHeaders'
], (React, TestUtils, ColumnHeaders) => {

  module('ColumnHeaders');

  test('`queryParamsFor` returns correct values', () => {
    const SORT_UPDATED_AT_DESC = {sort: 'updated_at', order: 'desc'};
    const queryParamsFor = ColumnHeaders.prototype.queryParamsFor;

    deepEqual(queryParamsFor({}, 'updated_at'), SORT_UPDATED_AT_DESC, 'was not sorted by anything');
    deepEqual(queryParamsFor({sort: 'created_at', order: 'desc'}, 'updated_at'), SORT_UPDATED_AT_DESC, 'was sorted by other column');
    deepEqual(queryParamsFor({sort: 'updated_at', order: 'asc' }, 'updated_at'), SORT_UPDATED_AT_DESC, 'was sorted by this column ascending');
    deepEqual(queryParamsFor({sort: 'updated_at', order: 'desc'}, 'updated_at'), {sort: 'updated_at', order: 'asc'});
  });

  test('headers have the proper href', () => {
    const props = {
      pathname: '/some/path/to/files',
      query: {
        sort: 'something',
        order: 'asc'
      },
      areAllItemsSelected () {},
      toggleAllSelected () {}
    };

    const component = TestUtils.renderIntoDocument(<ColumnHeaders {...props} />);
    const nameLink = TestUtils.scryRenderedDOMComponentsWithTag(component, 'a')[0];
    equal(nameLink.props.href, `${props.pathname}?sort=name&order=desc`, 'the href is correct');
  });

});




