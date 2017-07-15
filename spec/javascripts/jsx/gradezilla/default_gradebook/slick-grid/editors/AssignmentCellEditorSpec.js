/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import ReactDOM from 'react-dom';
import AssignmentRowCellPropFactory from 'jsx/gradezilla/default_gradebook/components/AssignmentRowCellPropFactory';
import AssignmentCellEditor from 'jsx/gradezilla/default_gradebook/slick-grid/editors/AssignmentCellEditor';

QUnit.module('AssignmentCellEditor', {
  setup () {
    const assignment = {
      grading_type: 'points',
      id: '2301',
      points_possible: 10
    };
    this.$fixtures = document.querySelector('#fixtures');
    const getSubmissionTrayState = () => ({ open: false, studentId: '1101', assignmentId: '2301' });
    this.gridSupport = {
      events: {
        onKeyDown: {
          subscribe () {},
          unsubscribe () {}
        }
      }
    };
    this.options = {
      column: {
        assignmentId: '2301',
        field: 'assignment_2301',
        getGridSupport: () => this.gridSupport,
        object: assignment,
        propFactory: new AssignmentRowCellPropFactory(
          assignment,
          { options: {}, getSubmissionTrayState, toggleSubmissionTrayOpen () {} }
        )
      },
      grid: {
        onKeyDown: {
          subscribe () {},
          unsubscribe () {}
        }
      },
      item: { // student row object
        id: '1101',
        assignment_2301: { // submission
          user_id: '1101'
        }
      }
    };
  },

  createEditor (options = {}) {
    this.editor = new AssignmentCellEditor({ ...this.options, ...options, container: this.$fixtures });
  },

  teardown () {
    if (this.$fixtures.childNodes.length > 0) {
      this.editor.destroy();
    }
    this.$fixtures.innerHTML = '';
  }
});

test('creates an AssignmentRowCell in the given container', function () {
  this.spy(ReactDOM, 'render');
  this.createEditor();
  strictEqual(ReactDOM.render.callCount, 1, 'renders once with React');
  const [element, container] = ReactDOM.render.lastCall.args;
  equal(element.type.name, 'AssignmentRowCell');
  equal(container, this.$fixtures, 'container is the test #fixtures element');
});

test('stores a reference to the rendered AssignmentRowCell component', function () {
  this.createEditor();
  equal(this.editor.component.constructor.name, 'AssignmentRowCell');
});

test('includes editor options in AssignmentRowCell props', function () {
  this.createEditor();
  equal(this.editor.component.props.editorOptions, this.editor.options);
});

test('subscribes to gridSupport.events.onKeyDown', function () {
  this.spy(this.gridSupport.events.onKeyDown, 'subscribe');
  this.createEditor();
  strictEqual(this.gridSupport.events.onKeyDown.subscribe.callCount, 1, 'calls grid.onKeyDown.subscribe');
  const [handleKeyDown] = this.gridSupport.events.onKeyDown.subscribe.lastCall.args;
  equal(handleKeyDown, this.editor.handleKeyDown, 'subscribes using the editor handleKeyDown function');
});

test('#handleKeyDown delegates to the AssignmentRowCell component', function () {
  this.createEditor();
  this.spy(this.editor.component, 'handleKeyDown');
  const keyboardEvent = new KeyboardEvent('example');
  this.editor.handleKeyDown(keyboardEvent);
  strictEqual(this.editor.component.handleKeyDown.callCount, 1);
});

test('#handleKeyDown passes the event when delegating handleKeyDown', function () {
  this.createEditor();
  this.spy(this.editor.component, 'handleKeyDown');
  const keyboardEvent = new KeyboardEvent('example');
  this.editor.handleKeyDown(keyboardEvent);
  const [event] = this.editor.component.handleKeyDown.lastCall.args;
  equal(event, keyboardEvent);
});

test('#handleKeyDown returns the return value from the AssignmentRowCell component', function () {
  this.createEditor();
  this.stub(this.editor.component, 'handleKeyDown').returns(true);
  const keyboardEvent = new KeyboardEvent('example');
  const returnValue = this.editor.handleKeyDown(keyboardEvent);
  strictEqual(returnValue, true);
});

test('#destroy removes the reference to the AssignmentRowCell component', function () {
  this.createEditor();
  this.editor.destroy();
  strictEqual(this.editor.component, null);
});

test('#destroy unsubscribes from gridSupport.events.onKeyDown', function () {
  this.createEditor();
  this.spy(this.gridSupport.events.onKeyDown, 'unsubscribe');
  this.editor.destroy();
  strictEqual(this.gridSupport.events.onKeyDown.unsubscribe.callCount, 1, 'calls grid.onKeyDown.unsubscribe');
  const [handleKeyDown] = this.gridSupport.events.onKeyDown.unsubscribe.lastCall.args;
  equal(handleKeyDown, this.editor.handleKeyDown, 'unsubscribes using the editor handleKeyDown function');
});

test('#destroy unmounts the AssignmentRowCell component', function () {
  this.createEditor();
  this.editor.destroy();
  const unmounted = ReactDOM.unmountComponentAtNode(this.$fixtures);
  strictEqual(unmounted, false, 'component was already unmounted');
});

test('#focus delegates to the AssignmentRowCell component', function () {
  this.createEditor();
  this.spy(this.editor.component, 'focus');
  this.editor.focus();
  strictEqual(this.editor.component.focus.callCount, 1);
});

test('#isValueChanged delegates to the AssignmentRowCell component', function () {
  this.createEditor();
  this.stub(this.editor.component, 'isValueChanged').returns(true);
  const changed = this.editor.isValueChanged();
  strictEqual(this.editor.component.isValueChanged.callCount, 1);
  strictEqual(changed, true);
});

test('#serializeValue delegates to the AssignmentRowCell component', function () {
  this.createEditor();
  this.stub(this.editor.component, 'serializeValue').returns('9.7');
  const value = this.editor.serializeValue();
  strictEqual(this.editor.component.serializeValue.callCount, 1);
  strictEqual(value, '9.7');
});

test('#loadValue delegates to the AssignmentRowCell component', function () {
  this.createEditor();
  this.spy(this.editor.component, 'loadValue');
  this.editor.loadValue('9.7');
  strictEqual(this.editor.component.loadValue.callCount, 1);
  const [value] = this.editor.component.loadValue.lastCall.args;
  strictEqual(value, '9.7');
});

test('#loadValue renders the component', function () {
  this.createEditor();
  this.stub(this.editor, 'renderComponent');
  this.editor.loadValue('9.7');
  strictEqual(this.editor.renderComponent.callCount, 1);
});

test('#applyValue delegates to the AssignmentRowCell component', function () {
  this.createEditor();
  this.stub(this.editor.component, 'applyValue');
  this.editor.applyValue({ id: '1101' }, '9.7');
  strictEqual(this.editor.component.applyValue.callCount, 1);
  const [item, value] = this.editor.component.applyValue.lastCall.args;
  deepEqual(item, { id: '1101' });
  strictEqual(value, '9.7');
});

test('#validate delegates to the AssignmentRowCell component', function () {
  this.createEditor();
  this.stub(this.editor.component, 'validate').returns({ valid: true });
  const validation = this.editor.validate();
  strictEqual(this.editor.component.validate.callCount, 1);
  deepEqual(validation, { valid: true });
});
