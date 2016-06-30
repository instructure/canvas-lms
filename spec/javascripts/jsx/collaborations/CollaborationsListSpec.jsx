define([
  'react',
  'jsx/collaborations/CollaborationsList'
], (React, CollaborationsList) => {
  const TestUtils = React.addons.TestUtils;

  module('CollaborationsList');

  let collaborations = [{
    id: 1,
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: (new Date(0)).toString()
  }, {
    id: 2,
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: (new Date(0)).toString()
  }];

  let collaborationsState = {
    nextPage: 'www.testurl.com',
    listCollaborationsPending: 'true',
    list: collaborations
  };

  test('renders the list of collaborations', () => {
    ENV.context_asset_string = 'courses_1'
    let component = TestUtils.renderIntoDocument(<CollaborationsList collaborationsState={collaborationsState}/>);
    let collaborationComponents = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Collaboration');
    equal(collaborationComponents.length, 2);
  })
})
