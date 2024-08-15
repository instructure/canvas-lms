/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {Editor, Frame, useEditor} from '@craftjs/core'

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {NewPageStepper} from '../NewPageStepper/NewPageStepper'
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {buildPageContent} from '../../../utils/buildPageContent'

let deserializeMock = jest.fn()
let buildPageContentMock = jest.fn()
let onFinish = jest.fn()
let onCancel = jest.fn()

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        enabled: true,
        actions: {
          deserialize: () => deserializeMock(),
          selectNode: jest.fn(),
        },
        query: {},
      }
    }),
  }
})

jest.mock('../../../utils/buildPageContent', () => {
  return {
    buildPageContent: () => buildPageContentMock(),
  }
})

const user = userEvent.setup()

const renderStepper = () => {
  return render(
    <Editor>
      <NewPageStepper open={true} onFinish={onFinish} onCancel={onCancel} />
    </Editor>
  )
}

describe('NewPageStepper', () => {
  beforeEach(() => {
    deserializeMock = jest.fn()
    buildPageContentMock = jest.fn()
    onFinish = jest.fn()
    onCancel = jest.fn()
  })

  it('renders', () => {
    const {getByText} = renderStepper()

    expect(getByText('Create a new page')).toBeInTheDocument()
    expect(getByText('Start from Scratch')).toBeInTheDocument()
    expect(getByText('Select a Template')).toBeInTheDocument()
    expect(getByText('Close')).toBeInTheDocument()
    expect(getByText('Cancel')).toBeInTheDocument()
    expect(getByText('Next')).toBeInTheDocument()
  })

  describe('Start from Scratch', () => {
    it('walks through the stepper', async () => {
      const {getByText, getByTestId} = renderStepper()

      const nextButton = getByText('Next').closest('button') as HTMLButtonElement
      expect(nextButton).toBeInTheDocument()

      const startFromScratchBtn = document
        .querySelector('[aria-labelledby="start-from-scratch-desc"]')
        ?.closest('button') as HTMLButtonElement
      expect(startFromScratchBtn).toBeInTheDocument()
      await user.click(startFromScratchBtn)

      await user.click(nextButton)
      expect(getByTestId('stepper-page-sections')).toBeInTheDocument()

      await user.click(nextButton)
      expect(getByTestId('stepper-color-palette')).toBeInTheDocument()

      await user.click(nextButton)
      expect(getByTestId('stepper-font-pairings')).toBeInTheDocument()

      const startBtn = getByText('Start Creating').closest('button') as HTMLButtonElement
      expect(startBtn).toBeInTheDocument()

      await user.click(startBtn)
      expect(buildPageContentMock).toHaveBeenCalled()
      expect(onFinish).toHaveBeenCalled()
    })
  })

  describe('Select a Template', () => {
    it('walks through the stepper', async () => {
      const {getByText, getByTestId} = renderStepper()

      const nextButton = getByText('Next').closest('button') as HTMLButtonElement
      expect(nextButton).toBeInTheDocument()

      const selectTemplateBtn = document
        .querySelector('[aria-labelledby="select-a-template-desc"]')
        ?.closest('button') as HTMLButtonElement
      expect(selectTemplateBtn).toBeInTheDocument()
      await user.click(selectTemplateBtn)

      await user.click(nextButton)
      expect(getByTestId('stepper-page-template')).toBeInTheDocument()

      await user.click(document.querySelector('#template-1') as HTMLButtonElement)
      const startBtn = getByText('Start Editing').closest('button') as HTMLButtonElement
      expect(startBtn).toBeInTheDocument()

      await user.click(startBtn)
      expect(deserializeMock).toHaveBeenCalled()
      expect(onFinish).toHaveBeenCalled()
    })
  })

  describe('misc functions', () => {
    it('goes back on clicking the back button', async () => {
      const {getByText, getByTestId} = renderStepper()
      expect(getByTestId('step-1')).toBeInTheDocument()

      const nextButton = getByText('Next').closest('button') as HTMLButtonElement
      await user.click(nextButton)
      expect(getByTestId('stepper-page-sections')).toBeInTheDocument()

      const backBtn = getByText('Back').closest('button') as HTMLButtonElement
      await user.click(backBtn)
      expect(getByTestId('step-1')).toBeInTheDocument()
    })

    it('calls onCancel on clicking the close button', async () => {
      const {getByText} = renderStepper()

      const closeBtn = getByText('Close').closest('button') as HTMLButtonElement
      await user.click(closeBtn)
      expect(onCancel).toHaveBeenCalled()
    })

    it('calls onCancel on clicking hte Cancel button', async () => {
      const {getByText} = renderStepper()

      const cancelBtn = getByText('Cancel').closest('button') as HTMLButtonElement
      await user.click(cancelBtn)
      expect(onCancel).toHaveBeenCalled()
    })
  })
})
