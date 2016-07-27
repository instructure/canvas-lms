define([
  'react',
  'jsx/collaborations/Collaboration',
  'timezone'
], (React, Collaboration, tz) => {
  const TestUtils = React.addons.TestUtils;

  module('Collaboration');

  let props = {
    collaboration: {
      title: 'Hello there',
      description: 'Im here to describe stuff',
      user_id: 1,
      user_name: 'Say my name',
      updated_at: (new Date(0)).toString(),
      update_url: 'http://google.com'
    },
    openModal: () => {}
  }

  test('renders the collaboration', () => {
    ENV.context_asset_string = 'courses_1'

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let title = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-title').getDOMNode().innerText;
    let description = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-description').getDOMNode().innerText;
    let author = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author').getDOMNode().innerText;
    let updateDate = TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay').getDOMNode().innerText;

    equal(title, props.collaboration.title);
    equal(description, props.collaboration.description);
    equal(author, `${props.collaboration.user_name},`);
    ok(updateDate);
  });

  test('renders a link to the user who created the collaboration', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let link = TestUtils.findRenderedDOMComponentWithClass(component, 'Collaboration-author').getDOMNode();
    ok(link.href.includes('/users/1'));
  });

  test('renders the date time in the correct format', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />)
    let dateString = TestUtils.findRenderedDOMComponentWithClass(component, 'DatetimeDisplay').getDOMNode().innerText;
    equal(dateString, tz.format(props.collaboration.updated_at, '%b %d, %l:%M %p'));
  });

  test('when the user clicks the trash button it opens the delete confirmation', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let trashIcon = TestUtils.findRenderedDOMComponentWithClass(component, 'icon-trash').getDOMNode();
    TestUtils.Simulate.click(trashIcon);
    let deleteConfirmation = TestUtils.findRenderedDOMComponentWithClass(component, 'DeleteConfirmation');
    ok(deleteConfirmation);
  });

  test('when the user clicks the cancel button on the delete confirmation it removes the delete confirmation', () => {
    ENV.context_asset_string = 'courses_1';

    let component = TestUtils.renderIntoDocument(<Collaboration {...props} />);
    let trashIcon = TestUtils.findRenderedDOMComponentWithClass(component, 'icon-trash').getDOMNode();
    TestUtils.Simulate.click(trashIcon);
    let cancelButton = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[1].getDOMNode();
    TestUtils.Simulate.click(cancelButton);
    let deleteConfirmation = TestUtils.scryRenderedDOMComponentsWithClass(component, 'DeleteConfirmation');
    equal(deleteConfirmation.length, 0);
  });

  test('calls openModal when the edit button is clicked', () => {
    ENV.context_asset_string = 'courses_1';

    let openModalCalled = false
    let newProps = {
      ...props,
      openModal: (url) => {
        openModalCalled = true;
        equal(url, `/courses/1/external_tools/retrieve?content_item_id=${props.collaboration.id}&placement=collaboration&url=${props.collaboration.update_url}&display=borderless`)
      }
    }

    let component = TestUtils.renderIntoDocument(<Collaboration {...newProps} />);
    let editIcon = TestUtils.findRenderedDOMComponentWithClass(component, 'icon-edit');
    TestUtils.Simulate.click(editIcon);
    ok(openModalCalled);
  });
});
