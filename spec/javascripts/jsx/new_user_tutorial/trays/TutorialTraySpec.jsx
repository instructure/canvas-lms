/* global QUnit */
define([
  'react',
  'enzyme',
  'jsx/new_user_tutorial/trays/TutorialTray',
  'jsx/new_user_tutorial/utils/createTutorialStore'
], (React, { shallow, mount }, TutorialTray, createTutorialStore) => {
  QUnit.module('TutorialTray Spec');

  const store = createTutorialStore();

  const getDefaultProps = overrides => (
    Object.assign({}, {
      label: 'TutorialTray Test',
      returnFocusToFunc () {
        return {
          focus () {
            return document.body;
          }
        }
      },
      store
    }, overrides)
  );

  test('Renders', () => {
    const wrapper = shallow(
      <TutorialTray {...getDefaultProps()}>
        <div>Some Content</div>
      </TutorialTray>
    );
    ok(wrapper.exists());
  });

  test('handleEntering sets focus on the toggle button', () => {
    const wrapper = mount(
      <TutorialTray {...getDefaultProps()}>
        <div>Some Content</div>
      </TutorialTray>
    );
    wrapper.setState({
      isCollapsed: false
    });

    wrapper.instance().handleEntering();

    ok(wrapper.instance().toggleButton.button.focused);
  });

  test('handleExiting calls focus on the return value of the returnFocusToFunc', () => {
    const spy = sinon.spy();
    const fakeReturnFocusToFunc = () => ({ focus: spy });
    const wrapper = mount(
      <TutorialTray {...getDefaultProps({returnFocusToFunc: fakeReturnFocusToFunc})}>
        <div>Some Content</div>
      </TutorialTray>
    );

    wrapper.instance().handleExiting();

    ok(spy.called);
  });

  test('handleToggleClick toggles the isCollapsed state of the store', () => {
    const wrapper = mount(
      <TutorialTray {...getDefaultProps()}>
        <div>Some Content</div>
      </TutorialTray>
    );

    wrapper.instance().handleToggleClick();

    ok(store.getState().isCollapsed);
  });
});
