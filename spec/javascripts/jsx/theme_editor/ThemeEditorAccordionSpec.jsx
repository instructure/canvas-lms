define([
  'react',
  'jquery',
  'jsx/theme_editor/ThemeEditorAccordion',
  'jsx/theme_editor/RangeInput',
  'jsx/theme_editor/ThemeEditorColorRow',
  'jsx/theme_editor/ThemeEditorImageRow',
], (React, jQuery, ThemeEditorAccordion, RangeInput, ColorRow, ImageRow) => {

  let elem, props

  module('ThemeEditorAccordion Component', {
    setup () {
      elem = document.createElement('div')
      props = {
        variableSchema: [],
        brandConfigVariables: {},
        changedValues: sinon.stub(),
        changeSomething: sinon.stub(),
        getDisplayValue: sinon.stub()
      }
    }
  })

  test('Initializes jQuery accordion', () => {
    sinon.spy(jQuery.fn, 'accordion')
    const component = React.render(<ThemeEditorAccordion {...props} />, elem)
    ok(
      jQuery(jQuery.fn.accordion.calledOn(component.getDOMNode())),
      'called jquery accordion plugin on dom node'
    )
    ok(
      jQuery.fn.accordion.calledWithMatch({
        header: 'h3',
        heightStyle: 'content'
      }),
      'passes configuration options to jquery plugin'
    )
    jQuery.fn.accordion.restore()
  })

  function testRenderRow (type, Component) {
    return () => {
      props.variableSchema = [{
        group_name: 'test',
        variables: [{
          default: 'default',
          human_name: 'Friendly Foo',
          variable_name: 'foo',
          type
        }],
      }]
      props.brandConfigVariables = {
        foo: 'bar'
      }
      props.changedValues = {
        foo: {val: 'baz'}
      }
      const component = React.render(<ThemeEditorAccordion {...props} />, elem)
      const varDef = props.variableSchema[0].variables[0]
      const expectedDisplayValue = 'display value'
      props.getDisplayValue.returns(expectedDisplayValue)
      const row = component.renderRow(varDef)
      equal(row.type, Component, 'renders a ThemeEditorColorRow')
      equal(row.props.key, varDef.variableName, 'uses variable name as key')
      equal(
        row.props.currentValue,
        props.brandConfigVariables.foo,
        'passes current value from brandConfigVariables'
      )
      equal(
        row.props.userInput,
        props.changedValues.foo,
        'passes changed value as user input'
      )
      row.props.onChange()
      ok(
        props.changeSomething.calledWith(varDef.variable_name),
        'passes bound onChange with variable name'
      )
      ok(
        props.getDisplayValue.calledWith(varDef.variable_name),
        'calls props.getDisplayName with variable name'
      )
      equal(
        row.props.placeholder,
        expectedDisplayValue,
        'uses display value as placeholder'
      )
      equal(row.props.varDef, varDef, 'passes varDef as prop')
    }
  }

  test('renderRow color', testRenderRow('color', ColorRow))
  test('renderRow image', testRenderRow('image', ImageRow))

  test('renderRow percentage', () => {
    props.variableSchema = [{
      group_name: 'test',
      variables: [{
        default: '0.1',
        human_name: 'Friendly Foo',
        variable_name: 'foo',
        type: 'percentage'
      }],
    }]
    props.brandConfigVariables = {
      foo: 0.2
    }
    props.changedValues = {
      foo: {val: 0.3}
    }
    const component = React.render(<ThemeEditorAccordion {...props} />, elem)
    const varDef = props.variableSchema[0].variables[0]
    const expectedDisplayValue = 'display value'
    props.getDisplayValue.returns(expectedDisplayValue)
    let row = component.renderRow(varDef)
    equal(row.type, RangeInput, 'renders a ThemeEditorColorRow')
    equal(row.props.key, varDef.variableName, 'uses variable name as key')
    equal(
      row.props.labelText,
      varDef.human_name,
      'passes human name as label text'
    )
    equal(
      row.props.defaultValue,
      0.2,
      'passes currentValue to defaultValue as float'
    )
    row.props.onChange()
    ok(
      props.changeSomething.calledWith(varDef.variable_name),
      'passes bound onChange with variable name'
    )
    ok(
      props.getDisplayValue.calledWith(varDef.variable_name),
      'calls props.getDisplayName with variable name'
    )
    equal(
      row.props.formatValue(0.472),
      '47%',
      'formateValue returns a whole number percent string'
    )
  })

  test('renders each group', () => {
    props.variableSchema = [{
      group_name: 'Foo',
      variables: [],
    }, {
      group_name: 'Bar',
      variables: []
    }]
    const component = React.render(<ThemeEditorAccordion {...props} />, elem)
    const node = component.getDOMNode()
    const headings = node.querySelectorAll('.Theme__editor-accordion > h3')
    props.variableSchema.forEach((group, index) => {
      equal(
        headings[index].textContent,
        group.group_name,
        `has heading for "${group.group_name}" group`
      )
    })
  })

  test('renders a row for each variable in the group', () => {
    props.variableSchema = [{
      group_name: 'Test Group',
      variables: [{
        default: '#047',
        human_name: 'Color',
        variable_name: 'color',
        type: 'color'
      }, {
        default: 'image.png',
        human_name: 'Image',
        variable_name: 'image',
        type: 'image',
        accept: 'image/*'
      }]
    }]
    const shallowRenderer = React.addons.TestUtils.createRenderer()
    shallowRenderer.render(<ThemeEditorAccordion {...props} />)
    const vdom = shallowRenderer.getRenderOutput()
    const rows = vdom.props.children[0][1]._store.props.children
    equal(rows[0].type, ColorRow, 'renders color row')
    equal(rows[1].type, ImageRow, 'renders image row')
  })
})

