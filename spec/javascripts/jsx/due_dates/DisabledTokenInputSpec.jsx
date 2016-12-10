define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/due_dates/DisabledTokenInput'
], (React, ReactDOM, {scryRenderedDOMComponentsWithTag}, DisabledTokenInput) => {
  const wrapper = document.getElementById("fixtures");
  const tokens = ["John Smith", "Section 2", "Group 1"];

  module('DisabledTokenInput', {
    setup() {
      this.input = ReactDOM.render(<DisabledTokenInput tokens={tokens}/>, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test('renders a list item for each token passed in', function() {
    const listItems = scryRenderedDOMComponentsWithTag(this.input, "li");
    propEqual(listItems.map(item => item.textContent), tokens);
  });
});
