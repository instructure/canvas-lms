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
  'jsx/collaborations/CollaborationsApp'
], (React, TestUtils, CollaborationsApp) => {

  QUnit.module('CollaborationsApp');

  let applicationState = {
    listCollaborations: {
      list: [{
        id: 1,
        title: 'Hello there',
        description: 'Im here to describe stuff',
        user_id: 1,
        user_name: 'Say my name',
        updated_at: (new Date(0)).toString(),
        permissions: {
          update: true,
          "delete": true
        }
      }]
    },
    ltiCollaborators: {
      ltiCollaboratorsData: []
    }
  };

  function setEnvironment () {
    ENV.context_asset_string = 'courses_1'
    ENV.current_user_roles = 'teacher';
  }

  test('renders the getting started component when there are no collaborations', () => {
    setEnvironment();

    let appState = {
      ...applicationState,
      listCollaborations: {
        list: []
      }
    }
    let component = TestUtils.renderIntoDocument(<CollaborationsApp applicationState={appState} actions={{}} />);
    let gettingStarted = TestUtils.findRenderedDOMComponentWithClass(component, 'GettingStartedCollaborations');
    ok(gettingStarted);
  });

  test('renders the list of collaborations when there are some', () => {
    setEnvironment();

    let component = TestUtils.renderIntoDocument(<CollaborationsApp applicationState={applicationState} actions={{}} />);
    let collaborationsList = TestUtils.findRenderedDOMComponentWithClass(component, 'CollaborationsList');
    ok(collaborationsList);
  })
});
