/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {fireEvent, render, within} from '@testing-library/react'

import {
  ExternalToolSelectionDialog,
  ExternalToolSelectionDialogProps,
} from '../ExternalToolSelectionDialog/ExternalToolSelectionDialog'
import {RceToolWrapper} from '../../RceToolWrapper'
import {createDeepMockProxy} from '../../../../../util/__tests__/deepMockProxy'
import {ExternalToolsEnv} from '../../ExternalToolsEnv'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'

describe('ExternalToolSelectionDialog', () => {
  const fakeEnv = createDeepMockProxy<ExternalToolsEnv>()

  function buildProps(
    override: Partial<ExternalToolSelectionDialogProps> = {}
  ): ExternalToolSelectionDialogProps {
    return {
      onDismiss: () => null,
      ltiButtons: RceToolWrapper.forEditorEnv(fakeEnv, [
        {
          name: 'Tool 1',
          id: 1,
          description: 'This is tool 1.',
          icon_url: 'tool1/icon.png',
        },
        {
          name: 'Tool 2',
          id: 2,
          description: 'This is tool 2',
          icon_url: '/tool2/image.png',
        },
        {
          name: 'Tool 3',
          id: 3,
          icon_url: 'https://www.edu-apps.org/assets/lti_public_resources/tool3.png',
        },
        {
          name: 'Diffrient Tool',
          id: 4,
          icon_url: 'https://www.edu-apps.org/assets/lti_public_resources/tool3.png',
        },
      ]),
      ...override,
    }
  }

  function renderComponent(propOverrides: Partial<ExternalToolSelectionDialogProps> = {}) {
    return render(<ExternalToolSelectionDialog {...buildProps(propOverrides)} />)
  }

  beforeEach(() => {
    fakeEnv.mockClear()
    document.body.innerHTML = ''
    createLiveRegion()
  })

  afterEach(() => {
    removeLiveRegion()
  })

  it('is labeled "Apps"', () => {
    const {getByLabelText} = renderComponent()
    expect(getByLabelText('Apps')).toBeInTheDocument()
  })

  it('has heading "All Apps"', () => {
    const {getByText} = renderComponent()
    expect(getByText('All Apps')).toBeInTheDocument()
  })

  it('shows the 3 tools', () => {
    const {baseElement, getByText} = renderComponent()
    const tool1 = getByText('Tool 1')
    const tool1Row = within(tool1.closest('div')!)
    const tool2 = getByText('Tool 2')
    const tool2Row = within(tool2.closest('div')!)
    const tool3 = getByText('Tool 3')
    const tool3Row = within(tool3.closest('div')!)

    expect(tool1).toBeInTheDocument()
    expect(tool1Row.getByText('View description')).toBeInTheDocument()
    expect(baseElement.querySelector('img[src="tool1/icon.png"]')).toBeInTheDocument()
    expect(tool2).toBeInTheDocument()
    expect(tool2Row.getByText('View description')).toBeInTheDocument()
    expect(baseElement.querySelector('img[src="/tool2/image.png"]')).toBeInTheDocument()
    expect(tool3).toBeInTheDocument()
    expect(tool3Row.queryByText('View description')).toBeNull()
    expect(
      baseElement.querySelector(
        'img[src="https://www.edu-apps.org/assets/lti_public_resources/tool3.png"]'
      )
    ).toBeInTheDocument()
  })

  it('calls onDismiss when clicking Done', () => {
    const handleDismiss = jest.fn()
    const {getByText} = renderComponent({onDismiss: handleDismiss})
    const cancelButton = getByText('Done')
    cancelButton.click()
    expect(handleDismiss).toHaveBeenCalled()
  })

  it('calls onDismiss when clicking the close button', () => {
    const handleDismiss = jest.fn()
    const {getByText} = renderComponent({onDismiss: handleDismiss})
    const closeButton = getByText('Close')
    closeButton.click()
    expect(handleDismiss).toHaveBeenCalled()
  })

  it('calls onAction when clicking a tool', () => {
    const helpers = RceToolWrapper.forEditorEnv(
      createDeepMockProxy<ExternalToolsEnv>({
        ltiIframeAllowPolicy: 'allow',
        containingCanvasLtiToolId: null,
        editorSelection: null,
        editorContent: null,
        rceWrapper: {
          getResourceIdentifiers: () => ({}),
        },
      }),
      [
        {
          name: 'Tool 1',
          id: 1,
          description: 'This is tool 1.',
          icon_url: 'tool1/icon.png',
        },
      ],
      []
    )

    const doAction = jest.spyOn(helpers[0], 'openDialog')
    const onDismiss = jest.fn()

    const {getByText} = renderComponent({
      onDismiss,
      ltiButtons: helpers,
    })
    const tool1 = getByText('Tool 1')
    tool1.click()

    expect(onDismiss).toHaveBeenCalled()
    expect(doAction).toHaveBeenCalled()

    // Ensure onDismiss() was called before doAction(), otherwise the new dialog won't open
    // From https://github.com/facebook/jest/issues/4402#issuecomment-534516219
    expect(onDismiss.mock.invocationCallOrder[0]).toBeLessThan(doAction.mock.invocationCallOrder[0])
  })

  describe('filtering', () => {
    it('shows only results that match the filter value', () => {
      const component = renderComponent()
      const searchBox = component.getByPlaceholderText('Search')

      fireEvent.change(searchBox, {target: {value: 'diff'}})

      expect(component.queryByText('Tool 1')).not.toBeInTheDocument()
      expect(component.getByText('Diffrient Tool')).toBeInTheDocument()
    })

    it('shows a no results alert when there are no results', () => {
      const {getAllByText, getByPlaceholderText} = renderComponent()
      const searchBox = getByPlaceholderText('Search')
      fireEvent.change(searchBox, {target: {value: 'instructure'}})
      expect(getAllByText('No results found for instructure')[0]).toBeInTheDocument()
    })
  })
})
