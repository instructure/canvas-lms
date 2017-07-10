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

import { destroyContainer, showFlashAlert } from 'jsx/shared/FlashAlert';

QUnit.module('FlashAlert', function (hooks) {
  let clock;

  hooks.beforeEach(function () {
    clock = sinon.useFakeTimers();
  });

  hooks.afterEach(function () {
    // ensure the automatic close timeout (10000ms) has elapsed
    // add 500ms for the animation
    // add 10ms for cushion
    clock.tick(10510);
    clock.restore();
  });

  function callShowFlashAlert (props = {}) {
    const defaultProps = {
      message: 'Example Message'
    };
    showFlashAlert({ ...defaultProps, ...props });
  }

  QUnit.module('.showFlashAlert');

  test('closes after 10.5 seconds', function () {
    callShowFlashAlert();
    clock.tick(10510);
    strictEqual(document.querySelector('#flash_message_holder').innerHTML, '');
  });

  test('has no effect when the container element has been removed', function () {
    callShowFlashAlert();
    destroyContainer();
    clock.tick(10510);
    ok('no error was thrown');
  });
});
