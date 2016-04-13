define([
  'react',
  'jsx/course_settings/components/CourseImageSelector',
  'jsx/course_settings/store/initialState'
], (React, CourseImageSelector, initialState) => {

  const TestUtils = React.addons.TestUtils;

  module('CourseImageSelector View');

  const fakeStore = {
    subscribe () {},
    dispatch () {},
    getState () {
      return initialState;
    }
  };

  test('it renders', () => {
    const component = TestUtils.renderIntoDocument(
      <CourseImageSelector store={fakeStore} />
    );
    ok(component);
  });

  test('the hidden input reflects the state value of the selector', () => {
    const component = TestUtils.renderIntoDocument(
      <CourseImageSelector store={fakeStore} />
    );
    equal(React.findDOMNode(component.refs.hiddenInput).value, initialState.courseImage, 'the input matches');
  });

  test('the hidden inputs name property gets set appropriately', () => {
    const component = TestUtils.renderIntoDocument(
      <CourseImageSelector store={fakeStore} name="course[image]" />
    );
    equal(component.refs.hiddenInput.props.name, 'course[image]', 'the input matches');
  });

  test('it sets the background image style properly', () => {
    const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
      imageUrl: 'http://coolUrl'
    }));
    const component = TestUtils.renderIntoDocument(
      <CourseImageSelector store={fakeStore} name="course[image]" />
    );

    const selectorDiv = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImageSelector');
    equal(selectorDiv.props.style.backgroundImage, "url(http://coolUrl)", 'image set properly');

    dispatchStub.restore();
  });



});