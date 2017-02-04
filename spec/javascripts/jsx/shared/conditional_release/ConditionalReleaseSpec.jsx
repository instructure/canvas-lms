define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jquery',
  'jsx/shared/conditional_release/ConditionalRelease'
], (React, ReactDOM, TestUtils, $, ConditionalRelease) => {

  let editor = null
  window.conditional_release_module = {
    ConditionalReleaseEditor: (env) => {
      editor = {
        attach: sinon.stub(),
        updateAssignment: sinon.stub(),
        saveRule: sinon.stub(),
        getErrors: sinon.stub(),
        focusOnError: sinon.stub(),
        env
      }
      return editor
    }
  }

  let component = null
  const createComponent = (submitCallback) => {
    component = TestUtils.renderIntoDocument(
      <ConditionalRelease.Editor env={assignmentEnv} type='foo' />
    )
    component.createEditor()
  }

  const makePromise = () => {
    const promise = {}
    promise.then = sinon.stub().returns(promise)
    promise.catch = sinon.stub().returns(promise)
    return promise
  }

  let ajax = null
  const assignmentEnv = { assignment: { id: 1 }, editor_url: 'editorurl', jwt: 'foo' }
  const noAssignmentEnv = { edit_rule_url: 'about:blank', jwt: 'foo' }
  const assignmentNoIdEnv = { assignment: { foo: 'bar' }, edit_rule_url: 'about:blank', jwt: 'foo' }

  QUnit.module('Conditional Release component', {
    setup: () => {
      ajax = sinon.stub($, 'ajax')
      createComponent()
    },

    teardown: () => {
      if (component) {
        const componentNode = ReactDOM.findDOMNode(component)
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode)
        }
      }
      component = null
      editor = null
      ajax.restore()
    }
  })

  test('it loads a cyoe editor on mount', () => {
    ok(ajax.calledOnce)
    ok(ajax.calledWithMatch({ url: 'editorurl' }))
  })

  test('it creates a cyoe editor', () => {
    ok(editor.attach.calledOnce)
  })

  test('it forwards focusOnError', () => {
    component.focusOnError()
    ok(editor.focusOnError.calledOnce)
  })

  test('it transforms validations', () => {
    editor.getErrors.returns([
      { index: 0, error: 'foo bar' },
      { index: 0, error: 'baz bat' },
      { index: 1, error: 'foo baz' }
    ])
    const transformed = component.validateBeforeSave()
    deepEqual(transformed, [
      { message: 'foo bar' },
      { message: 'baz bat' },
      { message: 'foo baz' }
    ])
  })

  test('it returns null if no errors on validation', () => {
    editor.getErrors.returns([])
    equal(null, component.validateBeforeSave())
  })

  test('it saves successfully when editor saves successfully', (assert) => {
    const resolved = assert.async()
    const cyoePromise = makePromise()

    editor.saveRule.returns(cyoePromise)

    const promise = component.save()
    promise.then(() => {
      ok(true)
      resolved()
    })
    cyoePromise.then.args[0][0]()
  })

  test('it fails when editor fails', (assert) => {
    const resolved = assert.async()
    const cyoePromise = makePromise()
    editor.saveRule.returns(cyoePromise)

    const promise = component.save()
    promise.fail((reason) => {
      equal(reason, 'stuff happened')
      resolved()
    })
    cyoePromise.catch.args[0][0]('stuff happened')
  })

  test('it times out', (assert) => {
    const resolved = assert.async()
    const cyoePromise = makePromise()
    editor.saveRule.returns(cyoePromise)

    const promise = component.save(2)
    promise.fail((reason) => {
      ok(reason.match(/timeout/))
      resolved()
    })
  })

  test('it updates assignments', (assert) => {
    component.updateAssignment({
      points_possible: 100
    })
    ok(editor.updateAssignment.calledWithMatch({ points_possible: 100 }))
  })
})
