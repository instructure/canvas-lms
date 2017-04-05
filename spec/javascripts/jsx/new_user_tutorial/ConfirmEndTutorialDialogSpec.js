/* global QUnit */
define([
  'jquery',
  'react',
  'enzyme',
  'axios',
  'moxios',
  'jsx/new_user_tutorial/ConfirmEndTutorialDialog',
], ($, React, { shallow, mount }, axios, moxios, ConfirmEndTutorialDialog) => {
  let $appElement;
  QUnit.module('ConfirmEndTutorialDialog Spec', {
    setup () {
      $appElement = $('<div id="application"></div>').appendTo($('#fixtures'));
      moxios.install();
    },
    teardown () {
      $('#fixtures').empty();
      moxios.uninstall();
    }
  });

  const getDefaultProps = () => ({
    isOpen: true,
    handleRequestClose () {}
  });

  test('sets appElment to application div', () => {
    const wrapper = shallow(<ConfirmEndTutorialDialog {...getDefaultProps()} />);
    equal(wrapper.instance().appElement, $appElement[0]);
  });

  test('handleModalReady sets aria-hidden on appElement', () => {
    const wrapper = shallow(<ConfirmEndTutorialDialog {...getDefaultProps()} />);
    wrapper.instance().handleModalReady();
    equal($appElement.attr('aria-hidden'), 'true');
  });

  test('handleModalClose removes aria-hidden from appElement', () => {
    const wrapper = shallow(<ConfirmEndTutorialDialog {...getDefaultProps()} />);
    $appElement.attr('aria-hidden', 'true')
    wrapper.instance().handleModalClose()
    ok(!$appElement.attr('aria-hidden'));
  });

  test('handleOkayButtonClick calls the proper api endpoint and data', () => {
    const spy = sinon.spy(axios, 'put');
    const wrapper = shallow(<ConfirmEndTutorialDialog {...getDefaultProps()} />);
    wrapper.instance().handleOkayButtonClick();
    ok(spy.calledWith('/api/v1/users/self/features/flags/new_user_tutorial_on_off', { state: 'off'}));
    spy.restore();
  });

  test('handleOkayButtonClick calls onSuccessFunc after calling the api', (assert) => {
    const done = assert.async();
    const wrapper = shallow(<ConfirmEndTutorialDialog {...getDefaultProps()} />);
    const spy = sinon.spy();
    const fakeEvent = {};
    wrapper.instance().handleOkayButtonClick(fakeEvent, spy);
    moxios.wait(() => {
      const request = moxios.requests.mostRecent();
      request.respondWith({ status: 200}).then(() => {
        ok(spy.called);
        done();
      });
    });
  });
});
