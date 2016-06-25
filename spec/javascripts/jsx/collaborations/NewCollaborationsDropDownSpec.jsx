define([
  'react',
  'jsx/collaborations/NewCollaborationsDropDown'
], (react, NewCollaborationsDropDown) => {
  const TestUtils = React.addons.TestUtils;

  module('NewCollaborationsDropDown');

  test('renders the create-collaborations-dropdown div', () => {
    let props = {ltiCollaborators: [{name: "this is a name"}]}
    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...props}/>);
    ok(TestUtils.findRenderedDOMComponentWithClass(component, 'create-collaborations-dropdown'));
  });
});
