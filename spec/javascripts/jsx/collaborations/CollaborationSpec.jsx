define([
  'react',
  'react-dom',
  'jsx/collaborations/Collaboration',
  'timezone'
], (React, ReactDOM, Collaboration, tz) => {
  const TestUtils = React.addons.TestUtils;

  module('Collaboration');

  let props = {
    collaboration: {
      title: 'Hello there',
      description: 'Im here to describe stuff',
      user_id: 1,
      user_name: 'Say my name',
      updated_at: (new Date(0)).toString(),
      update_url: 'http://google.com',
      id: 1
    }
  }

  test('renders the collaboration', () => {
    ENV.context_asset_string = 'courses_1'

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let title = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-title')).innerText;
    let description = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-description')).innerText;
    let author = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author')).innerText;
    let updateDate = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay')).innerText;

    equal(title, props.collaboration.title);
    equal(description, props.collaboration.description);
    equal(author, `${props.collaboration.user_name},`);
    ok(updateDate);
  });

  test('renders a link to the user who created the collaboration', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let link = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author'));
    ok(link.href.includes('/users/1'));
  });

  test('renders the date time in the correct format', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
    let dateString = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay')).innerText;
    equal(dateString, tz.format(props.collaboration.updated_at, '%b %d, %l:%M %p'));
  });

  test('when the user clicks the trash button it opens the delete confirmation', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let trashIcon = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'icon-trash'));
    TestUtils.Simulate.click(trashIcon);
    let deleteConfirmation = TestUtils.findRenderedDOMComponentWithClass(component, 'DeleteConfirmation');
    ok(deleteConfirmation);
  });

  test('when the user clicks the cancel button on the delete confirmation it removes the delete confirmation', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let trashIcon = ReactDOM.findDOMNode(TestUtils.findRenderedDOMComponentWithClass(component, 'icon-trash'));
    TestUtils.Simulate.click(trashIcon);
    let cancelButton = ReactDOM.findDOMNode(TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[1]);
    TestUtils.Simulate.click(cancelButton);
    let deleteConfirmation = TestUtils.scryRenderedDOMComponentsWithClass(component, 'DeleteConfirmation');
    equal(deleteConfirmation.length, 0);
  });

  test('has an edit button that links to the proper url', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let editIcon = TestUtils.findRenderedDOMComponentWithClass(component, 'icon-edit');
    ok(ReactDOM.findDOMNode(editIcon).href.includes(`/courses/1/lti_collaborations/external_tools/retrieve?content_item_id=${props.collaboration.id}&placement=collaboration&url=${props.collaboration.update_url}&display=borderless`))
  });
});
