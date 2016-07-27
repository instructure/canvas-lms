define([
  'react',
  'jsx/collaborations/DeleteConfirmation'
], (React, DeleteConfirmation) => {
  const TestUtils = React.addons.TestUtils;

  module('DeleteConfirmation');

  let props = {
    collaboration: {
      title: 'Hello there',
      description: 'Im here to describe stuff',
      user_id: 1,
      user_name: 'Say my name',
      updated_at: (new Date(0)).toString()
    },
    onDelete: () => {},
    onCancel: () => {}
  }

  test('renders the message and action buttons', () => {
    let component = TestUtils.renderIntoDocument(<DeleteConfirmation {...props} />);
    let message = TestUtils.findRenderedDOMComponentWithClass(component, 'DeleteConfirmation-message');
    let buttons = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button');

    equal(message.getDOMNode().innerText, 'Remove "Hello there"?');
    equal(buttons.length, 2);
    equal(buttons[0].getDOMNode().innerText, 'Yes, remove');
    equal(buttons[1].getDOMNode().innerText, 'Cancel');
  });

  test('Clicking on the confirmation button calls onDelete', () => {
    let onDeleteCalled = false
    let newProps = {
      ...props,
      onDelete: () => {
        onDeleteCalled = true
      }
    }

    let component = TestUtils.renderIntoDocument(<DeleteConfirmation {...newProps} />);
    let confirmButton = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[0].getDOMNode();
    TestUtils.Simulate.click(confirmButton);
    ok(onDeleteCalled);
  });

  test('Clicking on the cancel button calls onCancel', () => {
    let onCancelCalled = false
    let newProps = {
      ...props,
      onCancel: () => {
        onCancelCalled = true
      }
    }

    let component = TestUtils.renderIntoDocument(<DeleteConfirmation {...newProps} />);
    let cancelButton = TestUtils.scryRenderedDOMComponentsWithClass(component, 'Button')[1].getDOMNode();
    TestUtils.Simulate.click(cancelButton);
    ok(onCancelCalled);
  })
})
