define([
  'react',
  'react-addons-test-utils',
  'jsx/gradezilla/default_gradebook/components/TotalGradeColumnHeader'
], (React, TestUtils, TotalGradeColumnHeader) => {
  module('TotalGradeColumnHeader title');

  test('currently has no behavior', function () {
    const component = TestUtils.renderIntoDocument(<div><TotalGradeColumnHeader /></div>);
    ok(component);
  });
});
