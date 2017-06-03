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

define([
  'react',
  'react-addons-test-utils',
  'jquery',
  'jsx/shared/ExternalToolModalLauncher',
  'jsx/shared/modal',
], (React, TestUtils, $, ExternalToolModalLauncher, Modal) => {
  QUnit.module('ExternalToolModalLauncher');

  function generateProps (overrides = {}) {
    return {
      tool: { placements: { course_assignments_menu: {} } },
      isOpen: false,
      onRequestClose: () => {},
      contextType: 'course',
      contextId: 5,
      launchType: 'course_assignments_menu',
      ...overrides
    };
  }

  test('renders a Modal', () => {
    const component = TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...generateProps()} />);
    const modalCount = TestUtils.scryRenderedComponentsWithType(component, Modal).length;

    equal(modalCount, 1);
  });

  test('invokes onRequestClose prop when window receives externalContentReady event', () => {
    const sandbox = sinon.sandbox.create();
    const stub = sandbox.stub();
    const props = generateProps({ onRequestClose: stub });

    $(window).off('externalContentReady');
    TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...props} />);
    $(window).trigger('externalContentReady');

    equal(1, stub.callCount);
    sandbox.restore();
  });

  test('invokes onRequestClose prop when window receives externalContentCancel event', () => {
    const sandbox = sinon.sandbox.create();
    const stub = sandbox.stub();
    const props = generateProps({ onRequestClose: stub });

    $(window).off('externalContentCancel');
    TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...props} />);
    $(window).trigger('externalContentCancel');

    equal(1, stub.callCount);
    sandbox.restore();
  });
});
