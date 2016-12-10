define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/course_settings/components/CourseImageSelector',
  'jsx/course_settings/store/initialState'
], (React, ReactDOM, TestUtils, CourseImageSelector, initialState) => {
  const wrapper = document.getElementById('fixtures');

  module('CourseImageSelector View', {
    renderComponent(props = {}) {
      const element = React.createElement(CourseImageSelector, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  const fakeStore = {
    subscribe () {},
    dispatch () {},
    getState () {
      return initialState;
    }
  };

  test('it renders', function() {
    let component = this.renderComponent({ store: fakeStore });
    ok(component);
  });

  test('it sets the background image style properly', function() {
    const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
      imageUrl: 'http://coolUrl'
    }));

    let component = this.renderComponent({ store: fakeStore, name: "course[image]" });

    const selectorDiv = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImageSelector');
    equal(selectorDiv.props.style.backgroundImage, "url(http://coolUrl)", 'image set properly');

    dispatchStub.restore();
  });

  asyncTest('it renders course image edit options when an image is present', function() {
    const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
      imageUrl: 'http://coolUrl'
    }));

    let component = this.renderComponent({ store: fakeStore });

    component.setState({gettingImage: false}, () => {
      start();
      ok(component.refs.editDropdown, 'edit drowpdown appears when image is present');
      dispatchStub.restore();
    });
    
  });

  asyncTest('it calls the correct methods when each edit option is selected', function() {
    const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
      imageUrl: 'http://coolUrl'
    }));

    let component = this.renderComponent({ store: fakeStore, name: "course[image]" });

    let calledChangeImage = false;
    let calledRemoveImage = false;

    component.changeImage = () => calledChangeImage = true;
    component.removeImage = () => calledRemoveImage = true;

    component.setState({gettingImage: false}, () => {
      start();

      TestUtils.Simulate.click(component.refs.changeImage);
      TestUtils.Simulate.click(component.refs.removeImage);
      
      ok(calledChangeImage && calledRemoveImage, 'called both change and remove image when options were selected');
      dispatchStub.restore();
    })
    
  });

});