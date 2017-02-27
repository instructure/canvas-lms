define([
  'react',
  'react-addons-test-utils',
  'jsx/shared/load-more'
], (React, TestUtils, LoadMore) => {

  QUnit.module('LoadMore');

  function defaultProps () {
    return {
        hasMore: false,
        loadMore: ()=> {},
        isLoading: false
      };
  }

  test('renders the load more component', () => {
    let component = TestUtils.renderIntoDocument(<LoadMore {...defaultProps()} />);
    let loadMore = TestUtils.findRenderedDOMComponentWithClass(component, 'LoadMore');
    ok(loadMore);
  });

  test('function is called on load more link click', () => {
    let onItemClicked = false
    let props = defaultProps();
    props.hasMore = true;
    props.loadMore = () => {
      onItemClicked = true
    }
    let component = TestUtils.renderIntoDocument(<LoadMore {...props} />);
    let loadMore = TestUtils.findRenderedDOMComponentWithClass(component, 'LoadMore');
    let button = TestUtils.findRenderedDOMComponentWithClass(component, 'Button--link').getDOMNode();
    TestUtils.Simulate.click(button);
    ok(onItemClicked)
  });
});
