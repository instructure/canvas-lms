/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import { render, renderHeader } from '../index';
import moxios from 'moxios';
import { initialize as alertInitialize } from '../utilities/alertUtils';

describe('with mock api', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="container"></div>';
    moxios.install();
    alertInitialize({
      visualSuccessCallback: jest.fn(),
      visualErrorCallback: jest.fn(),
      srAlertCallback: jest.fn(),
    });
  });

  afterEach(() => {
    moxios.uninstall();
  });

  describe('render', () => {
    it('calls render with PlannerApp', () => {
      render(document.getElementById('container'), {
        flashAlertFunctions: {}
      });
      expect(document.querySelector('.PlannerApp')).toBeTruthy();
    });

    it('throws an error if flashAlertFunctions are not provided', () => {
      expect(() => {
        render(document.getElementById('container'));
      }).toThrow();
    });
  });

  describe('renderHeader', () => {
    const options = {
      ariaHideElement: document.createElement('div')
    };
    beforeEach(() => {
      document.body.innerHTML = '<div id="header_container"></div>';
      moxios.install();
    });

    afterEach(() => {
      moxios.uninstall();
    });

    it('calls render with PlannerHeader', () => {
      renderHeader(document.getElementById('header_container'), options);
      // This assertion is a bit odd, we need to get class names working with
      // CSS modules under test then we can be more clear here.
      expect(document.querySelector('#header_container div')).toBeTruthy();
    });
  });
});
