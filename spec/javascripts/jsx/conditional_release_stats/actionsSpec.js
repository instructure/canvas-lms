import { actions } from 'jsx/conditional_release_stats/actions'

QUnit.module('Conditional Release Stats actions')

test('closeSidebar dispatches CLOSE_SIDEBAR action', () => {
  const trigger = { focus: sinon.stub() }
  const dispatch = sinon.stub()
  const getState = sinon.stub().returns({ sidebarTrigger: trigger })
  actions.closeSidebar()(dispatch, getState)
  ok(dispatch.calledOnce)
  equal(dispatch.args[0][0].type, 'CLOSE_SIDEBAR')
})

test('closeSidebar focuses sidebar trigger', () => {
  const trigger = { focus: sinon.stub() }
  const dispatch = sinon.stub()
  const getState = sinon.stub().returns({ sidebarTrigger: trigger })
  actions.closeSidebar()(dispatch, getState)
  ok(trigger.focus.calledOnce)
})
