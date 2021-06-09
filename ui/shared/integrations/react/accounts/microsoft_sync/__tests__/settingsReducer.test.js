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

import {validateTenant, doUpdateSettings} from '../lib/settingsHelper'
import {defaultState, settingsReducer, reducerActions} from '../lib/settingsReducer'

jest.mock('../lib/settingsHelper', () => {
  return {
    ...jest.requireActual('../lib/settingsHelper'),
    validateTenant: jest.fn(),
    doUpdateSettings: jest.fn()
  }
})

const flushPromises = () => new Promise(setImmediate)

const expectedSettings = {
  microsoft_sync_enabled: true,
  microsoft_sync_tenant: 'canvastest2.onmicrosoft.com',
  microsoft_sync_login_attribute: 'email'
}

describe('settingsReducer', () => {
  beforeAll(() => {
    doUpdateSettings.mockImplementation(async state => state)
    validateTenant.mockImplementation(state => state)
  })

  describe('basic state updates', () => {
    it('updates the tenant', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.updateTenant,
        payload: {microsoft_sync_tenant: expectedSettings.microsoft_sync_tenant}
      })

      expect(result.microsoft_sync_tenant).toBe(expectedSettings.microsoft_sync_tenant)
    })

    it('updates the login attribute', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.updateAttribute,
        payload: {
          microsoft_sync_login_attribute: expectedSettings.microsoft_sync_login_attribute
        }
      })

      expect(result.microsoft_sync_login_attribute).toBe(
        expectedSettings.microsoft_sync_login_attribute
      )
    })

    it('clears errorMessages', () => {
      const state = settingsReducer(defaultState, {
        type: reducerActions.removeAlerts
      })

      expect(state.errorMessage).toEqual('')
      expect(state.successMessage).toEqual('')
    })
  })

  describe('initial data fetching', () => {
    it('updates state to match returned data on success', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.fetchSuccess,
        payload: {
          ...expectedSettings
        }
      })
      expect(result).toStrictEqual({
        ...defaultState,
        ...expectedSettings
      })
    })

    it('adds an error message on fetch failure', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.fetchError
      })

      expect(result.errorMessage).toBeTruthy()
    })

    it('updates the loading status when told to', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.fetchLoading,
        payload: {
          loading: false
        }
      })

      expect(result.loading).toBeFalsy()
    })
  })

  describe('updating settings', () => {
    const dispatchMock = jest.fn()

    afterEach(() => {
      dispatchMock.mockClear()
      doUpdateSettings.mockClear()
      validateTenant.mockClear()
    })

    it('tries to validate the tenant, stops if there are errors, and keeps the UI enabled', async () => {
      validateTenant.mockImplementationOnce(state => {
        return {
          ...state,
          tenantErrorMessages: ['error!']
        }
      })
      const state = settingsReducer(defaultState, {
        type: reducerActions.updateSettings,
        dispatch: dispatchMock
      })

      await flushPromises()

      expect(validateTenant).toHaveBeenCalledTimes(1)
      expect(doUpdateSettings).toHaveBeenCalledTimes(0)
      expect(dispatchMock).toHaveBeenCalledTimes(0)
      expect(state.uiEnabled).toBeTruthy()
    })

    it('tries to update settings and indicates success', async () => {
      settingsReducer(
        {
          ...defaultState,
          ...expectedSettings
        },
        {
          type: reducerActions.updateSettings,
          dispatch: dispatchMock
        }
      )
      await flushPromises()

      expect(doUpdateSettings).toHaveBeenCalledTimes(1)
      const [enable, tenant, loginAttribute] = doUpdateSettings.mock.calls.pop()

      expect(enable).toBe(expectedSettings.microsoft_sync_enabled)
      expect(tenant).toBe(expectedSettings.microsoft_sync_tenant)
      expect(loginAttribute).toBe(expectedSettings.microsoft_sync_login_attribute)
      expect(dispatchMock).toHaveBeenCalledTimes(1)
      expect(dispatchMock).toHaveBeenLastCalledWith({type: reducerActions.updateSuccess})
    })

    it('tries to update settings and indicates failure', async () => {
      doUpdateSettings.mockImplementationOnce(async () => {
        throw new Error('test failure!')
      })
      settingsReducer(defaultState, {
        type: reducerActions.updateSettings,
        dispatch: dispatchMock
      })

      await flushPromises()

      expect(doUpdateSettings).toHaveBeenCalledTimes(1)
      expect(dispatchMock).toHaveBeenCalledTimes(1)
      expect(dispatchMock).toHaveBeenLastCalledWith({type: reducerActions.updateError})
    })

    describe('toggling sync', () => {
      it('tries to validate the tenant and stops if there were errors', () => {
        validateTenant.mockImplementationOnce(state => {
          return {
            ...state,
            tenantErrorMessages: ['error!']
          }
        })
        settingsReducer(defaultState, {
          type: reducerActions.toggleSync,
          dispatch: dispatchMock
        })

        expect(validateTenant).toHaveBeenCalledTimes(1)
        expect(doUpdateSettings).toHaveBeenCalledTimes(0)
        expect(dispatchMock).toHaveBeenCalledTimes(0)
      })

      it('tries to toggle sync and indicate success', async () => {
        settingsReducer(defaultState, {
          type: reducerActions.toggleSync,
          dispatch: dispatchMock
        })

        await flushPromises()

        expect(doUpdateSettings).toHaveBeenCalledTimes(1)
        expect(dispatchMock).toHaveBeenCalledTimes(1)
        expect(dispatchMock).toHaveBeenLastCalledWith({type: reducerActions.updateSuccess})
      })

      it('tries to toggle sync and indicate failure', async () => {
        doUpdateSettings.mockImplementationOnce(async () => {
          throw new Error('test error!')
        })
        settingsReducer(defaultState, {
          type: reducerActions.toggleSync,
          dispatch: dispatchMock
        })

        await flushPromises()

        expect(doUpdateSettings).toHaveBeenCalledTimes(1)
        expect(dispatchMock).toHaveBeenCalledTimes(1)
        expect(dispatchMock).toHaveBeenLastCalledWith({type: reducerActions.toggleError})
      })

      it('disables the UI while trying to update or toggle sync', () => {
        for (const type of [reducerActions.updateSettings, reducerActions.toggleSync]) {
          const {uiEnabled} = settingsReducer(defaultState, {
            type
          })

          expect(uiEnabled).toBeFalsy()
        }
      })
    })
  })

  describe('update and toggle callbacks', () => {
    it('reenables the UI after success or failure', () => {
      for (const type of [
        reducerActions.updateSuccess,
        reducerActions.updateError,
        reducerActions.toggleError
      ]) {
        const {uiEnabled} = settingsReducer(defaultState, {
          type
        })
        expect(uiEnabled).toBeTruthy()
      }
    })

    it('adds a success message on success', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.updateSuccess
      })

      expect(result.successMessage).toBeTruthy()
    })

    it('adds an error message on failure to update', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.updateError
      })

      expect(result.errorMessage).toBeTruthy()
    })

    it('adds an error message on failure to toggle and inverts enabled', () => {
      const result = settingsReducer(defaultState, {
        type: reducerActions.toggleError
      })

      expect(result.errorMessage).toBeTruthy()
      // The default state is disabled, so it should be switched back to true
      expect(result.microsoft_sync_enabled).toBeTruthy()
    })
  })
})
