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

  test('it renders course image edit options when an image is present', () => {
    const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
      imageUrl: 'http://coolUrl'
    }));
    const component = TestUtils.renderIntoDocument(
      <CourseImageSelector store={fakeStore} />
    );
    ok(component.refs.editDropdown, 'edit drowpdown appears when image is present');

    dispatchStub.restore();
  });

  test('it calls the correct methods when each edit option is selected', () => {
    const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
      imageUrl: 'http://coolUrl'
    }));

    const component = TestUtils.renderIntoDocument(
      <CourseImageSelector store={fakeStore} name="course[image]" />
    );

    let calledChangeImage = false;
    let calledRemoveImage = false;

    component.changeImage = () => calledChangeImage = true;
    component.removeImage = () => calledRemoveImage = true;

    TestUtils.Simulate.click(component.refs.changeImage);
    TestUtils.Simulate.click(component.refs.removeImage);

    ok(calledChangeImage && calledRemoveImage, 'called both change and remove image when options were selected');

    dispatchStub.restore();
  });

});