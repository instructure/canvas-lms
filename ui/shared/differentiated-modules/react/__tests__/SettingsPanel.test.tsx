/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import SettingsPanel, {type SettingsPanelProps} from '../SettingsPanel'
import doFetchApi from '@canvas/do-fetch-api-effect'
import * as miscUtils from '../../utils/miscHelpers'
import * as moduleUtils from '../../utils/moduleHelpers'
import * as alerts from '@canvas/alerts/react/FlashAlert'
import RelockModulesDialog from '@canvas/context-modules/backbone/views/RelockModulesDialog'

jest.mock('@canvas/do-fetch-api-effect')
jest.mock('@canvas/context-modules/backbone/views/RelockModulesDialog')

describe('SettingsPanel', () => {
  const props: SettingsPanelProps = {
    moduleElement: document.createElement('div'),
    moduleId: '1',
    moduleName: 'Week 1',
    unlockAt: '',
    height: '500px',
    onDismiss: () => {},
    addModuleUI: () => {},
  }

  const renderComponent = (overrides = {}) => render(<SettingsPanel {...props} {...overrides} />)

  it('renders', () => {
    const {getByText} = renderComponent()
    expect(getByText('Module Name')).toBeInTheDocument()
  })

  it('renders the module name', () => {
    const {getByDisplayValue} = renderComponent()
    expect(getByDisplayValue('Week 1')).toBeInTheDocument()
  })

  it('renders the date time input when lock until is checked', () => {
    const {getByRole, getByText} = renderComponent()
    getByRole('checkbox').click()
    expect(getByText('Date')).toBeInTheDocument()
  })

  it('renders the date time input when unlockAt is set', () => {
    const {getByText} = renderComponent({unlockAt: '2020-01-01T00:00:00Z'})
    expect(getByText('Date')).toBeInTheDocument()
  })

  it('does not render prerequisites when there are no modules available', () => {
    const {queryByTestId} = renderComponent()
    expect(queryByTestId('prerequisite-form')).not.toBeInTheDocument()
  })

  it('renders prerequisite when there are modules available', () => {
    const {getByTestId} = renderComponent({
      moduleList: [
        {id: '0', name: 'Week 0'},
        {id: '1', name: 'Week 1'},
      ],
    })
    expect(getByTestId('prerequisite-form')).toBeInTheDocument()
  })

  it('does not render requirements when there are no module items', () => {
    const {queryByTestId} = renderComponent()
    expect(queryByTestId('requirement-form')).not.toBeInTheDocument()
  })

  it('renders requirements when there are moduleItems', () => {
    const {getByTestId} = renderComponent({
      moduleItems: [{id: '0', name: 'Page 0', type: 'page'}],
    })
    expect(getByTestId('requirement-form')).toBeInTheDocument()
  })

  it('does not render publish final grade if not enabled', () => {
    const {queryByRole} = renderComponent()
    expect(queryByRole('checkbox', {name: /Publish final grade/})).not.toBeInTheDocument()
  })

  it('renders publish final grade if enabled', () => {
    const {getByRole} = renderComponent({enablePublishFinalGrade: true})
    expect(getByRole('checkbox', {name: /Publish final grade/})).toBeInTheDocument()
  })

  describe('on update', () => {
    beforeAll(() => {
      window.ENV.COURSE_ID = '1'
    })

    beforeEach(() => {
      jest.clearAllMocks()
      doFetchApi.mockReset()
    })

    it('validates the module name', () => {
      const {getByRole, getByText} = renderComponent({moduleName: ''})
      const updateButton = getByRole('button', {name: 'Update Module'})

      updateButton.click()
      updateButton.focus()
      expect(getByText('Please fix errors before continuing')).toBeInTheDocument()
      expect(getByText('Module Name is required.')).toBeInTheDocument()
    })

    it('makes a request to the modules update endpoint', () => {
      doFetchApi.mockResolvedValue({response: {ok: true}, json: {}})
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Update Module'}).click()
      expect(doFetchApi).toHaveBeenCalledWith(
        expect.objectContaining({
          path: '/courses/1/modules/1',
          method: 'PUT',
          body: expect.anything(),
        })
      )
    })

    it('formats the form state for the request body', () => {
      jest.spyOn(miscUtils, 'convertModuleSettingsForApi')
      doFetchApi.mockResolvedValue({response: {ok: true}, json: {}})
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Update Module'}).click()
      expect(miscUtils.convertModuleSettingsForApi).toHaveBeenCalled()
    })

    it('updates the modules page UI', async () => {
      jest.spyOn(moduleUtils, 'updateModuleUI')
      doFetchApi.mockResolvedValue({response: {ok: true}, json: {}})
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Update Module'}).click()
      await waitFor(() => {
        expect(moduleUtils.updateModuleUI).toHaveBeenCalled()
      })
    })

    it('shows a flash alert on success', async () => {
      jest.spyOn(alerts, 'showFlashAlert')
      doFetchApi.mockResolvedValue({response: {ok: true}, json: {}})
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Update Module'}).click()
      await waitFor(() => {
        expect(alerts.showFlashAlert).toHaveBeenCalledWith({
          type: 'success',
          message: 'Week 1 settings updated successfully.',
        })
      })
    })

    it('shows a flash alert on failure', async () => {
      jest.spyOn(alerts, 'showFlashAlert')
      const e = new Error('error')
      doFetchApi.mockRejectedValue(e)
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Update Module'}).click()
      await waitFor(() => {
        expect(alerts.showFlashAlert).toHaveBeenCalledWith({
          err: e,
          message: 'Error updating Week 1 settings.',
        })
      })
    })

    it('calls the render function on the re-lock dialog', async () => {
      doFetchApi.mockResolvedValue({response: {ok: true}, json: {}})
      const {getByRole} = renderComponent()
      getByRole('button', {name: 'Update Module'}).click()
      await waitFor(() => expect(RelockModulesDialog.prototype.renderIfNeeded).toHaveBeenCalled())
    })
  })

  describe('on create', () => {
    it('calls addModuleUI when module is created', async () => {
      jest.spyOn(alerts, 'showFlashAlert')
      const addModuleUI = jest.fn()
      doFetchApi.mockResolvedValue({response: {ok: true}, json: {}})
      const {getByRole} = renderComponent({moduleId: undefined, addModuleUI})
      getByRole('button', {name: 'Add Module'}).click()
      await waitFor(() => {
        expect(alerts.showFlashAlert).toHaveBeenCalledWith({
          type: 'success',
          message: 'Week 1 created successfully.',
        })
        expect(addModuleUI).toHaveBeenCalled()
      })
    })
  })
})
