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
  const defaultWidth = 700;
  const defaultHeight = 700;
  QUnit.module('ExternalToolModalLauncher', hooks => {
    hooks.beforeEach(() => {
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
    })
    hooks.afterEach(() => {
      ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
    })

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

    test('getDimensions returns the modalStyle', () => {
      const component = TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...generateProps()} />);

      deepEqual(component.getDimensions().modalStyle, {width: defaultWidth});
    });

    test('getDimensions returns the modalBodyStyle', () => {
      const component = TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...generateProps()} />);

      deepEqual(
        component.getDimensions().modalBodyStyle,
        {width: defaultWidth, height: defaultHeight, padding: 0, display: 'flex', flexDirection: 'column'});
    });

    test('getDimensions returns the modalLaunchStyle', () => {
      const component = TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...generateProps()} />);

      deepEqual(component.getDimensions().modalLaunchStyle, {width: defaultWidth, height: defaultHeight, border: 'none'});
    });

    test('getDimensions returns the modalLaunchStyle with custom height & width', () => {
      const height = 111;
      const width = 222;

      const overrides = {
        tool: { placements: { course_assignments_menu: { launch_width: width, launch_height: height } } },
        isOpen: true }

      const component = TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...generateProps(overrides)} />);

      deepEqual(component.getDimensions().modalLaunchStyle, {width: width, height: height, border: 'none'});
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

    test('sets the iframe allowances', () => {
      const component = TestUtils.renderIntoDocument(<ExternalToolModalLauncher {...generateProps({isOpen: true})} />);
      equal(component.iframe.getAttribute('allow'), ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '));
    });
  });
});
