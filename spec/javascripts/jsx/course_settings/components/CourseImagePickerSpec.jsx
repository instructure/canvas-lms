define([
  'react',
  'jsx/course_settings/components/CourseImagePicker',
  'jsx/course_settings/store/initialState'
], (React, CourseImagePicker, initialState) => {

  const TestUtils = React.addons.TestUtils;

  module('CourseImagePicker Component');

  test('calls handleClose prop when the close button is clicked', () => {
    let called = false;
    const handleCloseFunc = () => called = true;
    const component = TestUtils.renderIntoDocument(
      <CourseImagePicker handleClose={handleCloseFunc} />
    );

    const btn = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker__CloseBtn');

    TestUtils.Simulate.click(btn);

    ok(called, 'handleClose was called');
  });
  
  test('dragging overlay modal appears when accepting a drag', () => {
    const component = TestUtils.renderIntoDocument(
      <CourseImagePicker />
    );

    const area = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker');

    TestUtils.Simulate.dragEnter(area, {
      dataTransfer: {
        types: ['Files']
      }
    });

    ok(TestUtils.scryRenderedDOMComponentsWithClass(component, 'DraggingOverlay').length === 1, 'the dragging overlay appeared');
  });

  test('dragging overlay modal does not appear when denying a non-file drag', () => {
    const component = TestUtils.renderIntoDocument(
      <CourseImagePicker />
    );

    const area = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker');

    TestUtils.Simulate.dragEnter(area, {
      dataTransfer: {
        types: ['notFile']
      }
    });

    ok(TestUtils.scryRenderedDOMComponentsWithClass(component, 'DraggingOverlay').length === 0, 'the dragging overlay did not appear');
  });

  test('dragging overlay modal disappears when you leave the drag area', () => {
    const component = TestUtils.renderIntoDocument(
      <CourseImagePicker />
    );

    const area = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker');

    TestUtils.Simulate.dragEnter(area, {
      dataTransfer: {
        types: ['Files']
      }
    });

    ok(component.state.draggingFile, 'draggingFile state is set');
    TestUtils.Simulate.dragLeave(area);
    ok(!component.state.draggingFile, 'draggingFile state is correctly false');
  });

  test('calls the handleFileUpload prop when drop occurs', () => {
    let called = false;
    const handleFileUploadFunc = () => called = true;
    const component = TestUtils.renderIntoDocument(
      <CourseImagePicker
        courseId="101"
        handleFileUpload={handleFileUploadFunc}
      />
    );

    const area = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker');

    TestUtils.Simulate.drop(area);

    ok(called, 'handleFileUpload was called');
  });
});