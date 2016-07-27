define([
  'react',
  'jquery',
  'jsx/theme_editor/ThemeEditorColorRow'
], (React, jQuery, ThemeEditorColorRow) => {

  let elem, props

  module('ThemeEditorColorRow Component', {
    setup () {
      elem = document.createElement('div')
      props = {
        varDef: {},
        onChange: sinon.spy()
      }
      // element needs to be attached to test focus
      document.body.appendChild(elem)
    },

    teardown () {
      document.body.removeChild(elem)
    }
  })

  test('showWarning', () => {
    let component = React.render(<ThemeEditorColorRow {...props} />, elem)
    notOk(component.showWarning(), 'not invalid')
    props.userInput = {invalid: true}
    sinon.stub(component, 'inputNotFocused').returns(false)
    component = React.render(<ThemeEditorColorRow {...props} />, elem)
    notOk(component.showWarning(), 'invalid but input focused')
    component.inputNotFocused.returns(true)
    ok(component.showWarning(), 'invalid and input not focused')
  })

  test('changedColor', () => {
    const cssStub = sinon.stub()
    sinon.stub(jQuery.fn, 'css').returns({css: cssStub})
    const component = React.render(<ThemeEditorColorRow {...props} />, elem)
    cssStub.returns('transparent')
    equal(
      component.changedColor('foo'),
      null,
      'returns null if backgroud-color is transparent and value is not'
    )
    const expected = '#047'
    const ret = '#004477'
    cssStub.returns(ret)
    equal(component.changedColor(expected), ret, 'return background-color')
    ok(
      jQuery.fn.css.calledWith('background-color', expected),
      'sets background color of element to value'
    )
    jQuery.fn.css.restore()
  })

  test('invalidHexString', () => {
    const component = React.render(<ThemeEditorColorRow {...props} />, elem)
    notOk(component.invalidHexString('foo'), 'hex string is not valid')
    ok(component.invalidHexString('#aabbccc'), 'hex string is valid')
    ok(component.invalidHexString('#abcc'), 'short hex string is valid')
  })

  test('inputChange', () => {
    const component = React.render(<ThemeEditorColorRow {...props} />, elem)
    const expected = 'foo'
    sinon.stub(component, 'changedColor').returns(true)
    sinon.stub(component, 'invalidHexString').returns(false)

    component.inputChange(expected)
    ok(
      props.onChange.calledWith(expected, false),
      'calls onChange with value and invalid false when valid'
    )

    component.changedColor.returns(false)
    props.onChange.reset()
    component.inputChange(expected)
    ok(
      props.onChange.calledWith(expected, true),
      'calls onChange with value and invalid true when invalid'
    )

    component.changedColor.returns(true)
    component.invalidHexString.returns(true)
    props.onChange.reset()
    component.inputChange(expected)
    ok(
      props.onChange.calledWith(expected, true),
      'calls onChange with value and invalid true when invalid'
    )
  })

  test('inputNotFocused', () => {
    const component = React.render(<ThemeEditorColorRow {...props} />, elem)
    document.body.focus()
    ok(component.inputNotFocused, 'input is not focused')
    component.refs.textInput.getDOMNode().focus()
    notOk(component.inputNotFocused(), 'input is focused')
  }) 
})
