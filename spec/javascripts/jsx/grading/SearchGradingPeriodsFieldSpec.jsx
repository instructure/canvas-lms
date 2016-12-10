define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/grading/SearchGradingPeriodsField'
], (React, ReactDOM, {Simulate}, SearchGradingPeriodsField) => {
  const wrapper = document.getElementById('fixtures');

  module("SearchGradingPeriodsField", {
    renderComponent() {
      const props = { changeSearchText: this.spy() };
      const element = React.createElement(SearchGradingPeriodsField, props);
      return ReactDOM.render(element, wrapper);
    },

    teardown() {
      ReactDOM.unmountComponentAtNode(wrapper);
    }
  });

  test("onChange trims the search text and sends it to the parent component to filter", function() {
    let searchField = this.renderComponent();
    this.spy(searchField, "search");
    let input = ReactDOM.findDOMNode(searchField.refs.input);
    input.value = "   i love spaces!   ";
    Simulate.change(input);
    ok(searchField.search.calledWith("i love spaces!"));
  });
});
