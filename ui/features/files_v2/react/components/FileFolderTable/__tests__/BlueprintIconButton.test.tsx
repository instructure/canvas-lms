/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import BlueprintIconButton from '../BlueprintIconButton'
import {FAKE_FILES, FAKE_FOLDERS} from '../../../../fixtures/fakeData'

let defaultProps: any

const renderComponent = () => render(<BlueprintIconButton {...defaultProps} />)

describe('BlueprintIconButton', () => {
  beforeEach(() => {
    defaultProps = {
      item: {...FAKE_FILES[0], ...{
        restricted_by_master_course: true,
        is_master_course_master_content: true,
      }}
    }
  })

  describe('when master BP', () => {
    it('displays the locked button', () => {
      const {container} = renderComponent()
      const button = container.querySelector('button')

      expect(button).toBeInTheDocument()
      expect(button).toHaveAttribute('title', 'Locked')
    })

    it('displays the unlocked button', () => {
      defaultProps.item.restricted_by_master_course = false
      const {container} = renderComponent()
      const button = container.querySelector('button')
      expect(button).toBeInTheDocument()
      expect(button).toHaveAttribute('title', 'Unlocked')
    })
  })

  describe('when child BP', () => {
    beforeEach(() => {
      defaultProps.item.is_master_course_master_content = false
    })

    it('displays the locked icon', () => {
      const {container} = renderComponent()
      const svg = container.querySelector('svg')
      expect(svg).toBeInTheDocument()
      expect(svg).toHaveAttribute('name', 'IconBlueprintLock')
    })

    it('displays the unlocked icon', () => {
      defaultProps.item.restricted_by_master_course = false
      const {container} = renderComponent()
      const svg = container.querySelector('svg')
      expect(svg).toBeInTheDocument()
      expect(svg).toHaveAttribute('name', 'IconBlueprint')
    })
  })

  it('does not display when the item is a folder', () => {
    defaultProps.item = FAKE_FOLDERS[0]
    const {container} = renderComponent()
    expect(container).toBeEmptyDOMElement()
  })
})
