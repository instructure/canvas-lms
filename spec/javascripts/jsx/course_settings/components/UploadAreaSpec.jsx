define([
  'react',
  'react-addons-test-utils',
  'jsx/course_settings/components/UploadArea',
], (React, TestUtils, UploadArea) => {

  module('UploadArea Component');

  test('it renders', () => {
    const component = TestUtils.renderIntoDocument(
      <UploadArea />
    );

    ok(component);
  });

  test('calls the handleFileUpload prop when change occurs on the file input', () => {
    let called = false;
    const handleFileUploadFunc = () => called = true;
    const component = TestUtils.renderIntoDocument(
      <UploadArea
        courseId="101"
        handleFileUpload={handleFileUploadFunc}
      />
    );

    const input = TestUtils.findRenderedDOMComponentWithClass(component, 'FileUpload__Input');
    TestUtils.Simulate.change(input);
    ok(called, 'handleFileUpload was called');
  });

});