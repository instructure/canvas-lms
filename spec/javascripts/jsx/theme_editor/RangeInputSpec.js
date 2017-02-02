define([
  'react',
  'react-dom',
  'jsx/theme_editor/RangeInput',
], (React, ReactDOM, RangeInput) => {

  let elem, props

  QUnit.module('RangeInput Component', {
    setup () {
      elem = document.createElement('div')
      props = {
        min: 1,
        max: 10,
        defaultValue: 5,
        labelText: 'Input Label',
        name: 'input_name',
        formatValue: sinon.stub(),
        onChange: sinon.stub()
      }
    }
  })

  test('renders range input', () => {
    const component = ReactDOM.render(<RangeInput {...props} />, elem)
    const input = component.refs.rangeInput.getDOMNode()
    equal(input.type, 'range', 'renders range input')
    equal(input.value, props.defaultValue, 'renders default value')
    equal(input.name, props.name, 'renders with name from props')
  })

  asyncTest('renders formatted output', () => {
    const component = ReactDOM.render(<RangeInput {...props} />, elem)
    const expected = 47
    const expectedFormatted = '47%'
    props.formatValue.returns(expectedFormatted)
    component.setState({value: 47}, () => {
      const output = component.getDOMNode().querySelector('output')
      ok(output, 'renders the output element')
      ok(props.formatValue.calledWith(expected), 'formats the value')
      equal(output.textContent, expectedFormatted, 'outputs value')
      start()
    })
  })

  test('handleChange', () => {
    const component = ReactDOM.render(<RangeInput {...props} />, elem)
    sinon.spy(component, 'setState')
    const event = {target: {value: 8}}
    component.handleChange(event)
    ok(
      component.setState.calledWithMatch({value: event.target.value}),
      'updates value in state'
    )
    ok(
      props.onChange.calledWith(event.target.value),
      'calls onChange with the new value'
    )
  })
})

