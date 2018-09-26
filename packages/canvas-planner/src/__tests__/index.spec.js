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
import { initializePlanner, loadPlannerDashboard, resetPlanner, renderToDoSidebar } from '../index';
import moxios from 'moxios';
import { initialize as alertInitialize } from '../utilities/alertUtils';

function defaultPlannerOptions () {
  return {
    env: {
      MOMENT_LOCALE: 'en',
      TIMEZONE: 'UTC',
      current_user: {
        id: '42',
        display_name: 'Arthur Dent',
        avatar_image_url: 'http://example.com',
      },
      PREFERENCES: {
        custom_colors: {},
      },
    },
    flashError: jest.fn(),
    flashMessage: jest.fn(),
    srFlashMessage: jest.fn(),
    convertApiUserContent: jest.fn(),
  };
}

afterEach(() => { resetPlanner(); });

describe('with mock api', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="application"></div>
      <div id="dashboard-planner"></div>
      <div id="dashboard-planner-header"></div>
      <div id="dashboard-planner-header-aux"></div>
      <div id="dashboard-sidebar"></div>
    `;
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

  describe('initializePlanner', () => {
    it('cannot be called twice', () => {
      initializePlanner(defaultPlannerOptions());
      expect(() => initializePlanner(defaultPlannerOptions())).toThrow();
    });

    it('requires flash methods', () => {
      ['flashError', 'flashMessage', 'srFlashMessage'].forEach(flash => {
        const options = defaultPlannerOptions();
        options[flash] = null;
        expect(() => initializePlanner(options)).toThrow();
      });
    });

    it('requires convertApiUserContent', () => {
      const options = defaultPlannerOptions();
      options.convertApiUserContent = null;
      expect(() => initializePlanner(options)).toThrow();
    });

    it('requires timezone', () => {
      const options = defaultPlannerOptions();
      options.env.TIMEZONE = null;
      expect(() => initializePlanner(options)).toThrow();
    });

    it('requires locale', () => {
      const options = defaultPlannerOptions();
      options.env.MOMENT_LOCALE = null;
      expect(() => initializePlanner(options)).toThrow();
    });
  });

  describe('loadPlannerDashboard', () => {
    beforeEach(() => {
      initializePlanner(defaultPlannerOptions());
    });

    it('renders into provided divs', () => {
      loadPlannerDashboard();
      expect(document.querySelector('.PlannerApp')).toBeTruthy();
      expect(document.querySelector('.PlannerHeader')).toBeTruthy();
    });
  });

  describe('renderToDoSidebar', () => {
    beforeEach(() => {
      initializePlanner(defaultPlannerOptions());
    });

    it('renders into provided element', () => {
      renderToDoSidebar(document.querySelector('#dashboard-sidebar'));
      expect(document.querySelector('.todo-list-header')).toBeTruthy();
    });
  });
});
