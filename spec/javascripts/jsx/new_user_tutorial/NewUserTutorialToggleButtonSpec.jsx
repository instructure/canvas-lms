/* global QUnit */
define([
  'react',
  'enzyme',
  'jsx/new_user_tutorial/NewUserTutorialToggleButton',
  'instructure-icons/react/Line/IconMoveLeftLine',
  'instructure-icons/react/Line/IconMoveRightLine',
  'jsx/new_user_tutorial/utils/createTutorialStore'
], (React, { shallow }, NewUserTutorialToggleButton, { default: IconMoveLeftLine }, { default: IconMoveRightLine }, createTutorialStore) => {
  QUnit.module('NewUserTutorialToggleButton Spec');

  test('Deafaults to expanded', () => {
    const store = createTutorialStore();
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(!wrapper.state('isCollapsed'))
  });

  test('Toggles isCollapsed when clicked', () => {
    const fakeEvent = {
      preventDefault () {}
    }

    const store = createTutorialStore();
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    wrapper.simulate('click', fakeEvent);
    ok(wrapper.state('isCollapsed'))
  });

  test('shows IconMoveLeftLine when isCollapsed is true', () => {
    const store = createTutorialStore({ isCollapsed: true });
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(wrapper.find(IconMoveLeftLine).exists())
  });

  test('shows IconMoveRightLine when isCollapsed is false', () => {
    const store = createTutorialStore({ isCollapsed: false });
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(wrapper.find(IconMoveRightLine).exists())
  })
});
