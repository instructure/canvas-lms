define([
  'react',
  'react-addons-test-utils',
  'jsx/gradezilla/default_gradebook/components/StudentColumnHeader'
], (React, TestUtils, StudentColumnHeader) => {
  module('StudentColumnHeader');

  test('currently has no behavior', function () {
    const component = TestUtils.renderIntoDocument(<div><StudentColumnHeader /></div>);
    ok(component);
  });
});
