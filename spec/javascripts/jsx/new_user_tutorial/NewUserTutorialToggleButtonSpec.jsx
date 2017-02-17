/* global QUnit */
define([
  'react',
  'enzyme',
  'jsx/new_user_tutorial/NewUserTutorialToggleButton',
  'instructure-icons/react/Line/IconArrowOpenLeftLine',
  'instructure-icons/react/Line/IconArrowOpenRightLine',
  'jsx/new_user_tutorial/utils/createTutorialStore'
], (React, { shallow }, NewUserTutorialToggleButton, { default: IconArrowOpenLeftLine }, { default: IconArrowOpenRightLine }, createTutorialStore) => {
  QUnit.module('NewUserTutorialToggleButton Spec');

  test('Deafaults to collapsed', () => {
    const store = createTutorialStore();
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(wrapper.state('isCollapsed'))
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
    ok(!wrapper.state('isCollapsed'))
  });

  test('shows IconArrowOpenLeftLine when isCollapsed is true', () => {
    const store = createTutorialStore();
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(wrapper.find(IconArrowOpenLeftLine).exists())
  });

  test('shows IconArrowOpenRightLine when isCollapsed is false', () => {
    const store = createTutorialStore({ isCollapsed: false });
    const wrapper = shallow(
      <NewUserTutorialToggleButton store={store} />
    );

    ok(wrapper.find(IconArrowOpenRightLine).exists())
  })
});
