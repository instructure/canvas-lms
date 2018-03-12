/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import jQuery from 'jquery'
import ThemeEditorAccordion from 'jsx/theme_editor/ThemeEditorAccordion'
import RangeInput from 'jsx/theme_editor/RangeInput'
import ColorRow from 'jsx/theme_editor/ThemeEditorColorRow'
import ImageRow from 'jsx/theme_editor/ThemeEditorImageRow'

let elem, props

QUnit.module('ThemeEditorAccordion Component', {
  setup() {
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
  const component = ReactDOM.render(<ThemeEditorAccordion {...props} />, elem)
  ok(
    jQuery(jQuery.fn.accordion.calledOn(component.rootNode)),
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

test('Opens last used accordion tab', () => {
  let options // Stores the last object passed to $dom.accorion({...})
  sinon.stub(jQuery.fn, 'accordion').callsFake(opts => {
    // Allows us to save the last accordion call if it was an object
    // Ex: it won't save if $dom.accordion('options','active') is called
    if (typeof opts === 'object') {
      options = opts
    }
  })

  let mem // the saved index
  let cur // the current index
  const dom = document.createElement('div')
  const context = {
    rootNode: dom,
    getStoredAccordionIndex: () => mem || 0,
    rememberActiveIndex: () => {
      mem = cur
    }
  }

  const component = ReactDOM.render(
    <ThemeEditorAccordion {...props} accordionContextOverride={context} />,
    elem
  )

  function initAccordion() {
    component.initAccordion()
  }

  // Simulate opening a pane
  function selectPane(index) {
    cur = index
    options.activate()
  }

  initAccordion()
  // The active pane index is expected to be 0 by default
  equal(options.active, 0, 'Opens first pane if none previously recorded')

  selectPane(1)
  initAccordion() // Simulate page refresh
  equal(options.active, 1, 'Remembers and opens second pane after refresh')

  selectPane(2)
  initAccordion()
  equal(options.active, 2, 'Remembers and opens third pane after refresh')

  jQuery.fn.accordion.restore()
})

function testRenderRow(type, Component) {
  return () => {
    props.variableSchema = [
      {
        group_name: 'test',
        variables: [
          {
            default: 'default',
            human_name: 'Friendly Foo',
            variable_name: 'foo',
            type
          }
        ]
      }
    ]
    props.brandConfigVariables = {
      foo: 'bar'
    }
    props.changedValues = {
      foo: {val: 'baz'}
    }
    const component = ReactDOM.render(<ThemeEditorAccordion {...props} />, elem)
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
    equal(row.props.userInput, props.changedValues.foo, 'passes changed value as user input')
    row.props.onChange()
    ok(
      props.changeSomething.calledWith(varDef.variable_name),
      'passes bound onChange with variable name'
    )
    ok(
      props.getDisplayValue.calledWith(varDef.variable_name),
      'calls props.getDisplayName with variable name'
    )
    equal(row.props.placeholder, expectedDisplayValue, 'uses display value as placeholder')
    equal(row.props.varDef, varDef, 'passes varDef as prop')
  }
}

test('renderRow color', testRenderRow('color', ColorRow))
test('renderRow image', testRenderRow('image', ImageRow))

test('renderRow percentage', () => {
  props.variableSchema = [
    {
      group_name: 'test',
      variables: [
        {
          default: '0.1',
          human_name: 'Friendly Foo',
          variable_name: 'foo',
          type: 'percentage'
        }
      ]
    }
  ]
  props.brandConfigVariables = {
    foo: 0.2
  }
  props.changedValues = {
    foo: {val: 0.3}
  }
  const component = ReactDOM.render(<ThemeEditorAccordion {...props} />, elem)
  const varDef = props.variableSchema[0].variables[0]
  const expectedDisplayValue = 'display value'
  props.getDisplayValue.returns(expectedDisplayValue)
  const row = component.renderRow(varDef)
  equal(row.type, RangeInput, 'renders a ThemeEditorColorRow')
  equal(row.props.key, varDef.variableName, 'uses variable name as key')
  equal(row.props.labelText, varDef.human_name, 'passes human name as label text')
  equal(row.props.defaultValue, 0.2, 'passes currentValue to defaultValue as float')
  row.props.onChange()
  ok(
    props.changeSomething.calledWith(varDef.variable_name),
    'passes bound onChange with variable name'
  )
  ok(
    props.getDisplayValue.calledWith(varDef.variable_name),
    'calls props.getDisplayName with variable name'
  )
  equal(row.props.formatValue(0.472), '47%', 'formateValue returns a whole number percent string')
})

test('renders each group', () => {
  props.variableSchema = [
    {
      group_name: 'Foo',
      variables: []
    },
    {
      group_name: 'Bar',
      variables: []
    }
  ]
  const component = ReactDOM.render(<ThemeEditorAccordion {...props} />, elem)
  const node = component.rootNode
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
  props.variableSchema = [
    {
      group_name: 'Test Group',
      variables: [
        {
          default: '#047',
          human_name: 'Color',
          variable_name: 'color',
          type: 'color'
        },
        {
          default: 'image.png',
          human_name: 'Image',
          variable_name: 'image',
          type: 'image',
          accept: 'image/*'
        }
      ]
    }
  ]
  const shallowRenderer = TestUtils.createRenderer()
  shallowRenderer.render(<ThemeEditorAccordion {...props} />)
  const vdom = shallowRenderer.getRenderOutput()
  const rows = vdom.props.children[0][1].props.children
  equal(rows[0].type, ColorRow, 'renders color row')
  equal(rows[1].type, ImageRow, 'renders image row')
})
