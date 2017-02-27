/* global QUnit */
define([
  'react',
  'enzyme',
  'jsx/new_user_tutorial/NewUserTutorialToggleButton',
  'instructure-icons/react/Line/IconArrowOpenLeftLine',
  'instructure-icons/react/Line/IconArrowOpenRightLine'
], (React, { shallow }, NewUserTutorialToggleButton, { default: IconArrowOpenLeftLine }, { default: IconArrowOpenRightLine }) => {
  QUnit.module('NewUserTutorialToggleButton Spec');

  test('Given no initiallyCollapsed prop it defaults to false', () => {
    const wrapper = shallow(
      <NewUserTutorialToggleButton />
    );

    ok(!wrapper.state('isCollapsed'))
  });

  test('Toggles isCollapsed when clicked', () => {
    const fakeEvent = {
      preventDefault () {}
    }

    const wrapper = shallow(
      <NewUserTutorialToggleButton />
    );

    wrapper.simulate('click', fakeEvent);
    ok(wrapper.state('isCollapsed'))
  });

  test('Calls onClick prop when provided', () => {
    const fakeEvent = {
      preventDefault () {}
    }

    const spy = sinon.spy();

    const wrapper = shallow(
      <NewUserTutorialToggleButton onClick={spy} />
    );

    wrapper.simulate('click', fakeEvent);
    ok(spy.called);
  });

  test('shows IconArrowOpenRightLine when isCollapsed is true', () => {
    const wrapper = shallow(
      <NewUserTutorialToggleButton />
    );

    ok(wrapper.find(IconArrowOpenRightLine).exists())
  });

  test('shows IconArrowOpenLeftLine when isCollapsed is false', () => {
    const wrapper = shallow(
      <NewUserTutorialToggleButton initiallyCollapsed />
    );

    ok(wrapper.find(IconArrowOpenLeftLine).exists())
  })
});
