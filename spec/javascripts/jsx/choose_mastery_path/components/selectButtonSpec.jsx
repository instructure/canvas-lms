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
import TestUtils from 'react-dom/test-utils'
import SelectButton from 'ui/features/choose_mastery_path/react/components/select-button'

QUnit.module('Select Button')

const defaultProps = () => ({
  isSelected: false,
  isDisabled: false,
  onSelect: () => {},
})

const renderComponent = props => TestUtils.renderIntoDocument(<SelectButton {...props} />)

test('renders component', () => {
  const props = defaultProps()
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'cmp-button')
  equal(renderedList.length, 1, 'renders component')
})

test('renders button when not selected or disabled', () => {
  const props = defaultProps()
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(component, 'btn-primary')
  equal(renderedList.length, 1, 'renders as button')
})

test('renders selected badge when selected', () => {
  const props = defaultProps()
  props.isSelected = true
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'cmp-button__selected'
  )
  equal(renderedList.length, 1, 'renders selected')
})

test('renders disabled badge when disabled', () => {
  const props = defaultProps()
  props.isDisabled = true
  const component = renderComponent(props)

  const renderedList = TestUtils.scryRenderedDOMComponentsWithClass(
    component,
    'cmp-button__disabled'
  )
  equal(renderedList.length, 1, 'renders disabled')
})
