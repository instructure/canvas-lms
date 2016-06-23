define([
  'react',
  'jquery',
  'jsx/shared/conditional_release/ConditionalRelease'
], (React, $, ConditionalRelease) => {

  const TestUtils = React.addons.TestUtils;
  let component = null;

  module('Conditional Release component', {
    teardown: () => {
      if (component) {
        const componentNode = React.findDOMNode(component);
        if (componentNode) {
          React.unmountComponentAtNode(componentNode.parentNode);
        }
      }
      component = null;
    }
  });

  const assignmentEnv = { assignment: { id: 1 }, edit_rule_url: 'about:blank', jwt: 'foo' }
  const noAssignmentEnv = { edit_rule_url: 'about:blank', jwt: 'foo' }
  const assignmentNoIdEnv = { assignment: { foo: 'bar' }, edit_rule_url: 'about:blank', jwt: 'foo' }

  test('it disables its button when no assignment', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={noAssignmentEnv} type='foo' />
    );
    const button = React.findDOMNode(component.refs.button);
    equal(button.disabled, true)
  });

  test('it shows the help text when no assignment', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={noAssignmentEnv} type='foo' />
    );
    ok(component.refs.saveDataMessage);
  });

  test('it shows the help text when an assignment but no id', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentNoIdEnv} type='foo' />
    );
    ok(component.refs.saveDataMessage);
  });

  test('it enabled its button when there is an assignment', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' />
    );
    const button = React.findDOMNode(component.refs.button);
    equal(button.disabled, false)
  });

  test('it does not show the help text when there is an assignment', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' />
    );
    notOk(component.refs.saveDataMessage);
  });

  test('it adds the hidden form when mounted', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' />
    );
    ok(document.contains(component.hiddenContainer().get(0)))
  });

  test('it removes the hidden form when unmounted', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' />
    );
    const removed = React.unmountComponentAtNode(React.findDOMNode(component).parentNode);
    ok(removed)
    notOk(document.contains(component.hiddenContainer().get(0)))

    component = null; // we've already removed, skip teardown
  });

  test('it pops up the modal when the button is clicked', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' />
    );
    sinon.spy(component, 'submitForm');
    TestUtils.Simulate.click(component.refs.button);
    ok(component.submitForm.called);
  });

  test('it disables when data is dirty', () => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' assignmentDirty={true} />
    );
    notOk(component.enabled());
  });
});
