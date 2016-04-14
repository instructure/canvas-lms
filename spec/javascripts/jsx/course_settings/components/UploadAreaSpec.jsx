define([
  'react',
  'jsx/course_settings/components/UploadArea',
], (React, UploadArea) => {

  const TestUtils = React.addons.TestUtils;

  module('UploadArea Component');

  test('it renders', () => {
    const component = TestUtils.renderIntoDocument(
      <UploadArea />
    );

    ok(component);
  });

});