define([
  'react',
  'jsx/collaborations/CollaborationsApp'
], (react, CollaborationsApp) => {
  const TestUtils = React.addons.TestUtils;

  module('CollaborationsApp');

  test('renders the collaborations app div', () => {
    let component = TestUtils.renderIntoDocument(<CollaborationsApp />);
    ok(TestUtils.findRenderedDOMComponentWithClass(component, 'CollaborationsApp'));
  });

});
