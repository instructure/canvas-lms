define([
  'react',
  'react-dom',
  'jquery',
  'jsx/shared/conditional_release/ConditionalRelease'
], (React, ReactDOM, $, ConditionalRelease) => {

  const TestUtils = React.addons.TestUtils;

  let component = null;
  const createComponent = (submitCallback) => {
    // prevent polluting with new tab from form submission
    $(document).on('submit', '#conditional-release-editor-form', (event) => {
      $(document).off('submit', '#conditional-release-editor-form');
      if (submitCallback) { submitCallback() }
      return false;
    })
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' />
    );
  };

  const connectComponent = () => {
    const postMessage = sinon.spy()
    component.connect({ postMessage: postMessage })
    // connect call has [port] as third arg:
    return postMessage.args[0][2][0];
  };

  const createMessage = (messageType, messageBody = null) => {
    return {
      context: 'conditional-release',
      messageType,
      messageBody
    }
  };

  module('Conditional Release component', {
    teardown: () => {
      if (component) {
        component.disconnect();
        const componentNode = ReactDOM.findDOMNode(component);
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode);
        }
      }
      component = null;
    }
  });

  const assignmentEnv = { assignment: { id: 1 }, edit_rule_url: 'about:blank', jwt: 'foo' }
  const noAssignmentEnv = { edit_rule_url: 'about:blank', jwt: 'foo' }
  const assignmentNoIdEnv = { assignment: { foo: 'bar' }, edit_rule_url: 'about:blank', jwt: 'foo' }

  module('load', () => {
    test('it submits the hidden form when mounted', (assert) => {
      const resolved = assert.async();
      createComponent(() => {
        expect(0);
        resolved();
      })
    });

    test('it removes the hidden form after submitting', () => {
      createComponent();
      notOk(document.contains($('#conditional-release-editor-form').get(0)))
    });
  });

  module('connect', () => {
    test('it connects MessageChannel to target', () => {
      createComponent();
      const target = { postMessage: sinon.spy() };

      component.connect(target);
      ok(target.postMessage.calledOnce);
      ok(target.postMessage.args[0][0].messageType === 'connect')
    });
  });

  module('save', () => {
    test('it returns success when iframe reports success', (assert) => {
      createComponent();
      const remotePort = connectComponent();
      const resolved = assert.async();
      remotePort.onmessage = (event) => {
        ok(event.data.messageType === 'save')
        remotePort.postMessage(createMessage('saveComplete'))
      }
      const promise = component.save();
      promise.done(() => {
        resolved();
      })
    });

    test('it reports error when iframe reports error', (assert) => {
      createComponent();
      const remotePort = connectComponent();
      const resolved = assert.async();
      remotePort.onmessage = (event) => {
        ok(event.data.messageType === 'save')
        remotePort.postMessage(createMessage('saveError', 'foobarbaz'))
      }
      const promise = component.save();
      promise.fail((reason) => {
        ok(reason.match(/foobarbaz/));
        resolved();
      })
    });

    test('it times out', (assert) => {
      createComponent();
      const remotePort = connectComponent();
      const resolved = assert.async();
      const promise = component.save(2);
      promise.fail((reason) => {
        ok(reason.match(/timeout/));
        resolved();
      })
    });
  });

  module('updateAssignment', () => {
    test('it updates iframe', (assert) => {
      createComponent();
      const remotePort = connectComponent();
      const resolved = assert.async();
      remotePort.onmessage = (event) => {
        ok(event.data.messageType === 'updateAssignment');
        ok(event.data.messageBody.id === 'asdf');
        resolved();
      }
      component.updateAssignment({ id: 'asdf' });
    });
  })
  module('handleMessage', () => {
    const sendMessage = (messageType, messageBody) => {
      component.handleMessage({
        data: createMessage(messageType, messageBody)
      })
    }

    test('it can set and retrieve validation errors', () => {
      createComponent();

      sendMessage('validationErrors', '[{ "index": 1, "error": "foo" }]');
      deepEqual(component.validateBeforeSave(), [{ message: 'foo' }]);

      sendMessage('validationErrors', null);
      ok(component.validateBeforeSave() == null);
    });
  });

  module('focusOnError', () => {
    test('it dispatches a focusOnError event', (assert) => {
      createComponent()
      const resolved = assert.async()
      const remotePort = connectComponent()
      remotePort.onmessage = (event) => {
        ok(event.data.messageType === 'focusOnError')
        resolved()
      }
      component.focusOnError()
    })
  });
});
