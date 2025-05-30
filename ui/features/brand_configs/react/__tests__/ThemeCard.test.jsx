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
import ThemeCard from '../ThemeCard'
import {render} from '@testing-library/react'

let props

describe('ThemeCard Component', () => {
  beforeEach(() => {
    props = {
      name: 'Test Theme',
      isActiveBrandConfig: false,
      isDeleteable: true,
      isBeingDeleted: false,
      open: jest.fn(),
      startDeleting: jest.fn(),
      cancelDelete: jest.fn(),
      onDelete: jest.fn(),
      getVariable: jest.fn(),
      cancelDeleting: jest.fn(),
      showMultipleCurrentThemesMessage: false,
      isDeletable: true,
    }
  })
  test('Renders the name', () => {
    const {getByTestId} = render(<ThemeCard {...props} />)
    expect(getByTestId('themecard-name-button-name')).toHaveTextContent(props.name)
  })

  test('Renders preview of colors', () => {
    render(<ThemeCard {...props} />)
    const getVar = props.getVariable
    expect(getVar).toHaveBeenCalledWith('ic-brand-primary')
    expect(getVar).toHaveBeenCalledWith('ic-brand-button--primary-bgd')
    expect(getVar).toHaveBeenCalledWith('ic-brand-button--secondary-bgd')
    expect(getVar).toHaveBeenCalledWith('ic-brand-global-nav-bgd')
    expect(getVar).toHaveBeenCalledWith('ic-brand-global-nav-ic-icon-svg-fill')
    expect(getVar).toHaveBeenCalledWith('ic-brand-global-nav-menu-item__text-color')
  })

  test('Indicates if it is the current theme', () => {
    const {container, rerender} = render(<ThemeCard {...props} />)
    expect(container.querySelector('.ic-ThemeCard-status__text')).not.toBeInTheDocument()

    const updatedProps = {...props, isActiveBrandConfig: true}
    rerender(<ThemeCard {...updatedProps} />)
    expect(container.querySelector('.ic-ThemeCard-status__text')).toHaveTextContent('Current theme')
  })

  test('Shows delete modal if isBeingDeleted is true', () => {
    const {container, rerender, queryByText} = render(<ThemeCard {...props} />)
    expect(queryByText('Delete Test Theme?')).not.toBeInTheDocument()

    const updatedProps = {...props, isBeingDeleted: true}
    rerender(<ThemeCard {...updatedProps} />)
    expect(queryByText('Delete Test Theme?')).toBeInTheDocument()
  })

  test('Shows tooltip if there are multiple cards of the same theme', () => {
    const {container, rerender} = render(<ThemeCard {...props} />)
    expect(container.querySelector('.Button--icon-active-rev')).not.toBeInTheDocument()

    const updatedProps = {
      ...props,
      showMultipleCurrentThemesMessage: true,
      isActiveBrandConfig: true,
    }
    rerender(<ThemeCard {...updatedProps} />)
    expect(
      container.querySelector('.Button--icon-action-rev[data-tooltip][title]'),
    ).toBeInTheDocument()
  })
})
