define([
  'react',
  'jsx/collaborations/NewCollaborationsDropDown'
], (react, NewCollaborationsDropDown) => {
  const TestUtils = React.addons.TestUtils;

  module('NewCollaborationsDropDown');

  let defaultProps = {
    ltiCollaborators: [{name: "A name", id: '1'}],
    onItemClicked: () => {}
  }

  test('renders the create-collaborations-dropdown div', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...defaultProps} />);
    ok(TestUtils.findRenderedDOMComponentWithClass(component, 'create-collaborations-dropdown'));
  });

  test('calls onItemClicked with the correct url when an item is clicked', () => {
    ENV.context_asset_string = 'courses_1';

    let onItemClicked = false
    let props = {
      ...defaultProps,
      onItemClicked: (url) => {
        onItemClicked = true
        equal(url, '/courses/1/external_tools/1?launch_type=collaboration&display=borderless')
      }
    }
    let component = TestUtils.renderIntoDocument(<NewCollaborationsDropDown {...props} />);
    let button = TestUtils.findRenderedDOMComponentWithClass(component, 'Button').getDOMNode();
    TestUtils.Simulate.click(button);
    let tool = TestUtils.findRenderedDOMComponentWithTag(component, 'Button').getDOMNode();
    TestUtils.Simulate.click(tool);
    ok(onItemClicked)
  })
});
