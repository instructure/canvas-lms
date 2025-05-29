/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import CriterionInfo from '../CriterionInfo'

describe('The CriterionInfo component', () => {
  it('renders an info button that toggles a modal with help content', () => {
    const component = shallow(<CriterionInfo />)

    // Initially should show just the info button
    expect(component.find('IconButton')).toHaveLength(1)
    expect(component.find('Modal')).toHaveLength(0)

    // Check IconButton properties
    const iconButton = component.find('IconButton')
    expect(iconButton.prop('screenReaderLabel')).toBe('More Information About Ratings')
    expect(iconButton.prop('color')).toBe('secondary')
    expect(iconButton.prop('withBackground')).toBe(false)
    expect(iconButton.prop('withBorder')).toBe(false)
    expect(iconButton.prop('renderIcon').type.name).toBe('IconQuestionLine')

    // Click the button to open modal
    iconButton.prop('onClick')()
    component.update()

    // Should now show both button and modal
    expect(component.find('IconButton')).toHaveLength(1)
    expect(component.find('Modal')).toHaveLength(1)

    // Check Modal properties
    const modal = component.find('Modal')
    expect(modal.prop('label')).toBe('Criterion Ratings')
    expect(modal.prop('open')).toBe(true)
    expect(modal.prop('size')).toBe('medium')

    // Check modal content structure
    expect(modal.find('ModalHeader')).toHaveLength(1)
    expect(modal.find('ModalBody')).toHaveLength(1)
    expect(modal.find('CloseButton')).toHaveLength(1)
    expect(modal.find('Heading')).toHaveLength(1)

    // Check modal text content
    const modalText = modal.find('Text')
    expect(modalText).toHaveLength(1)
    expect(modalText.children().text()).toContain(
      'Learning outcomes can be included in assignment rubrics',
    )
    expect(modalText.children().text()).toContain('define mastery of this outcome')

    // Check heading content
    const heading = modal.find('Heading')
    expect(heading.children().text()).toBe('Criterion Ratings')
    expect(heading.prop('level')).toBe('h2')
  })
})
