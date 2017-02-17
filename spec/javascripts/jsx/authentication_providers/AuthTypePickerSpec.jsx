define([
  'react',
  'react-dom',
  'jsx/authentication_providers/AuthTypePicker',
  'enzyme'
], (React, ReactDOM, AuthTypePicker, enzyme) => {
  const authTypes = [
    {name: 'TypeOne', value: '1'},
    {name: 'TypeTwo', value: '2'}
  ];
  const { mount } = enzyme;

  QUnit.module('AuthTypePicker');

  test('rendered structure', () => {
    const wrapper = mount(<AuthTypePicker authTypes={authTypes} />)
    equal(wrapper.find('option').length, 2)
  });

  test('choosing an auth type fires the provided callback', () => {
    const spy = sinon.spy();
    const wrapper = mount(
      <AuthTypePicker
        authTypes={authTypes}
        onChange={spy}
      />
    );
    wrapper.find('select').simulate('change');
    ok(spy.called)
  });
});
