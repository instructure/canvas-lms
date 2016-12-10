define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/collaborations/NewCollaborationsDropDown'
], (React, ReactDOM, TestUtils, NewCollaborationsDropDown) => {

  module('NewCollaborationsDropDown');

  let defaultProps = {
    ltiCollaborators: [{name: "A name", id: '1'}]
  }

  test('renders the create-collaborations-dropdown div', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...defaultProps} />);
    ok(TestUtils.findRenderedDOMComponentWithClass(component, 'create-collaborations-dropdown'));
  });

  test('has a link to open the lti tool to create a collaboration', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...defaultProps} />);
    let button = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[0];
    ok(ReactDOM.findDOMNode(button).href.includes('/courses/1/lti_collaborations/external_tools/1?launch_type=collaboration&display=borderless'));
  })

  test('has a dropdown if there is more than one tool', () => {
    ENV.context_asset_string = 'courses_1';

    let props = {
      ltiCollaborators: [{
        name: "A name",
        id: '1'
      }, {
        name: "Another name",
        id: '2'
      }]
    }

    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...props} />);
    let dropdownButton = TestUtils.findRenderedDOMComponentWithTag(component, 'button');
    TestUtils.Simulate.click(dropdownButton);

    let links = TestUtils.scryRenderedDOMComponentsWithTag(component, 'a');
    equal(links.length, 2)
  })
});
