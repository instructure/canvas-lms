define([
  'react',
  'jsx/collaborations/Collaboration',
  'timezone'
], (React, Collaboration, tz) => {
  const TestUtils = React.addons.TestUtils;

  module('Collaboration');

  ENV.context_asset_string = 'courses_1'

  let collaboration = {
    title: 'Hello there',
    description: 'Im here to describe stuff',
    user_id: 1,
    user_name: 'Say my name',
    updated_at: (new Date(0)).toString()
  }

  test('renders the collaboration', () => {
    ENV.context_asset_string = 'courses_1'

    let component = TestUtils.renderIntoDocument(<Collaboration collaboration={collaboration} />);
    let title = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-title').getDOMNode().innerText;
    let description = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-description').getDOMNode().innerText;
    let author = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author').getDOMNode().innerText;
    let updateDate = TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay').getDOMNode().innerText;

    equal(title, collaboration.title);
    equal(description, collaboration.description);
    equal(author, `${collaboration.user_name},`);
    ok(updateDate);
  });

  test('renders a link to the user who created the collaboration', () => {
    ENV.context_asset_string = 'courses_1'

    let component = TestUtils.renderIntoDocument(<Collaboration collaboration={collaboration} />);
    let link = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author').getDOMNode();
    ok(link.href.includes('/users/1'));
  });

  test('renders the date time in the correct format', () => {
    ENV.context_asset_string = 'courses_1'

    let component = TestUtils.renderIntoDocument(<Collaboration collaboration={collaboration} />)
    let dateString = TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay').getDOMNode().innerText;
    equal(dateString, tz.format(collaboration.updated_at, '%b %d, %l:%M %p'));
  })
});
