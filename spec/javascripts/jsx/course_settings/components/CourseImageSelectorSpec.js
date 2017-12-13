/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import CourseImageSelector from 'jsx/course_settings/components/CourseImageSelector'
import initialState from 'jsx/course_settings/store/initialState'

QUnit.module('CourseImageSelector View', {
  renderComponent(props = {}) {
    const element = React.createElement(CourseImageSelector, props);
    return ReactDOM.render(element, wrapper);
  },

  setup() {
    wrapper = document.getElementById('fixtures')
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
  const component = this.renderComponent({ store: fakeStore });
  ok(component);
});

test('it sets the background image style properly', function() {
  const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
    imageUrl: 'http://coolUrl'
  }));

  const component = this.renderComponent({ store: fakeStore, name: "course[image]" });

  const selectorDiv = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImageSelector');
  equal(selectorDiv.props.style.backgroundImage, "url(http://coolUrl)", 'image set properly');

  dispatchStub.restore();
});

test('it renders course image edit options when an image is present', function(assert) {
  const done = assert.async()
  const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
    imageUrl: 'http://coolUrl'
  }));

  const component = this.renderComponent({ store: fakeStore });

  component.setState({gettingImage: false}, () => {
    ok(component.refs.editDropdown, 'edit drowpdown appears when image is present');
    dispatchStub.restore();
    done();
  });

});

test('it calls the correct methods when each edit option is selected', function(assert) {
  const done = assert.async()
  const dispatchStub = sinon.stub(fakeStore, 'getState').returns(Object.assign(initialState, {
    imageUrl: 'http://coolUrl'
  }));

  const component = this.renderComponent({ store: fakeStore, name: "course[image]" });

  let calledChangeImage = false;
  let calledRemoveImage = false;

  component.changeImage = () => calledChangeImage = true;
  component.removeImage = () => calledRemoveImage = true;

  component.setState({gettingImage: false}, () => {

    TestUtils.Simulate.click(component.refs.changeImage);
    TestUtils.Simulate.click(component.refs.removeImage);

    ok(calledChangeImage && calledRemoveImage, 'called both change and remove image when options were selected');
    dispatchStub.restore();
    done()
  })

});
