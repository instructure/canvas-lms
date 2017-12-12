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
import Button from '@instructure/ui-core/lib/components/Button'
import CourseImagePicker from 'jsx/course_settings/components/CourseImagePicker'

const wrapper = document.getElementById('fixtures');

QUnit.module('CourseImagePicker Component', {
  renderComponent(props = {}) {
    let courseImagePicker
    const element = React.createElement(CourseImagePicker, {
      ref: (node) => { courseImagePicker = node },
      courseId: 0,
      ...props
    });
    ReactDOM.render(element, wrapper);
    return courseImagePicker
  },

  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper);
  }
});

test('dragging overlay modal appears when accepting a drag', function() {
  const component = this.renderComponent();

  const area = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker');

  TestUtils.Simulate.dragEnter(area, {
    dataTransfer: {
      types: ['Files']
    }
  });

  ok(TestUtils.scryRenderedDOMComponentsWithClass(component, 'DraggingOverlay').length === 1, 'the dragging overlay appeared');
});

test('dragging overlay modal does not appear when denying a non-file drag', function() {
  const component = this.renderComponent();

  const area = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker');

  TestUtils.Simulate.dragEnter(area, {
    dataTransfer: {
      types: ['notFile']
    }
  });

  ok(TestUtils.scryRenderedDOMComponentsWithClass(component, 'DraggingOverlay').length === 0, 'the dragging overlay did not appear');
});

test('dragging overlay modal disappears when you leave the drag area', function() {
  const component = this.renderComponent();

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

test('calls the handleFileUpload prop when drop occurs', function() {
  let called = false;
  const handleFileUploadFunc = () => { called = true };
  const component = this.renderComponent({ courseId: "101", handleFileUpload: handleFileUploadFunc });

  const area = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseImagePicker');

  TestUtils.Simulate.drop(area);

  ok(called, 'handleFileUpload was called');
});
