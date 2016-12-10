define([
  'context_modules_helper'
], (Helper) => {
  module('ContextModulesHelper', {
    setup() {
      sinon.stub(Helper, 'setWindowLocation')
    },

    teardown() {
      Helper.setWindowLocation.restore()
    },
  })

  test('externalUrlLinkClick', () => {
    const event = {
      preventDefault: sinon.spy()
    }
    const elt = {
      attr: sinon.spy()
    }
    Helper.externalUrlLinkClick(event, elt)
    ok(event.preventDefault.calledOnce, 'preventDefault not called')
    ok(elt.attr.calledWith('data-item-href'), 'elt.attr not called')
    ok(Helper.setWindowLocation.calledOnce, 'window redirected')
  })
})
