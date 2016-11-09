define([
  'react',
  'react-addons-test-utils',
  'jsx/collaborations/CollaborationsApp'
], (React, TestUtils, CollaborationsApp) => {

  module('CollaborationsApp');

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
