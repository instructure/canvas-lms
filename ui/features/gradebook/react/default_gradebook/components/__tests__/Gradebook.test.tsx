/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import {defaultGradebookProps} from '../../__tests__/GradebookSpecHelper'
import {darken, statusColors, defaultColors} from '../../constants/colors'
import {render, within} from '@testing-library/react'
import Gradebook from '../../Gradebook'
import store from '../../stores/index'
import '@testing-library/jest-dom/extend-expect'

const originalState = store.getState()

describe('Gradebook', () => {
  beforeEach(() => {
    fetchMock.mock('*', 200)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('renders', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gradebookMenuNode={node} />)
    const {getByText} = within(node)
    expect(node).toContainElement(getByText(/Gradebook/i))
  })
})

describe('SettingsModalButton', () => {
  it('renders', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} settingsModalButtonContainer={node} />)
    const {getByText} = within(node)
    expect(node).toContainElement(getByText(/Gradebook Settings/i))
  })
})

describe('GridColor', () => {
  it('renders', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gridColorNode={node} />)
    const {getByTestId} = within(node)
    expect(node).toContainElement(getByTestId('grid-color'))
  })

  it('renders the correct styles', () => {
    const node = document.createElement('div')
    render(<Gradebook {...defaultGradebookProps} gridColorNode={node} colors={statusColors()} />)
    const styleText = [
      `.even .gradebook-cell.late { background-color: ${defaultColors.blue}; }`,
      `.odd .gradebook-cell.late { background-color: ${darken(defaultColors.blue, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.late { background-color: white; }',
      `.even .gradebook-cell.missing { background-color: ${defaultColors.salmon}; }`,
      `.odd .gradebook-cell.missing { background-color: ${darken(defaultColors.salmon, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.missing { background-color: white; }',
      `.even .gradebook-cell.resubmitted { background-color: ${defaultColors.green}; }`,
      `.odd .gradebook-cell.resubmitted { background-color: ${darken(defaultColors.green, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.resubmitted { background-color: white; }',
      `.even .gradebook-cell.dropped { background-color: ${defaultColors.orange}; }`,
      `.odd .gradebook-cell.dropped { background-color: ${darken(defaultColors.orange, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.dropped { background-color: white; }',
      `.even .gradebook-cell.excused { background-color: ${defaultColors.yellow}; }`,
      `.odd .gradebook-cell.excused { background-color: ${darken(defaultColors.yellow, 5)}; }`,
      '.slick-cell.editable .gradebook-cell.excused { background-color: white; }',
    ].join('')
    expect(node.innerHTML).toContain(styleText)
  })

  describe('FlashAlert', () => {
    it('renders flash alerts if the flashAlerts prop has content', () => {
      const node = document.createElement('div')
      const alert = {key: 'alert', message: 'Uh oh!', variant: 'error'}
      render(
        <Gradebook {...defaultGradebookProps} flashAlerts={[alert]} flashMessageContainer={node} />
      )
      const {getByText} = within(node)
      expect(node).toContainElement(getByText(/Uh oh!/i))
    })
  })
})

describe('ExportProgressBar', () => {
  it('renders', () => {
    const {getByTestId} = render(<Gradebook {...defaultGradebookProps} />)
    expect(getByTestId('export-progress-bar')).toBeInTheDocument()
  })
})
