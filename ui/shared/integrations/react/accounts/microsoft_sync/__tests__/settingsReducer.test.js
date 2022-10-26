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

import {
  getTenantErrorMessages,
  doUpdateSettings,
  getSuffixErrorMessages,
} from '../lib/settingsHelper'
import {defaultState, settingsReducer, reducerActions} from '../lib/settingsReducer'

jest.mock('../lib/settingsHelper', () => {
  return {
    ...jest.requireActual('../lib/settingsHelper'),
    tenantErrorMessages: jest.fn(),
    doUpdateSettings: jest.fn(),
    getSuffixErrorMessages: jest.fn(),
    getTenantErrorMessages: jest.fn(),
  }
})

const flushPromises = () => new Promise(setTimeout)

/**
 * @type {import('../lib/settingsReducer').State}
 */
const expectedState = {
  microsoft_sync_enabled: true,
  microsoft_sync_tenant: 'canvastest2.onmicrosoft.com',
  last_saved_microsoft_sync_tenant: 'canvastest2.onmicrosoft.com',
  microsoft_sync_login_attribute: 'email',
  microsoft_sync_login_attribute_suffix: '@example.com',
  microsoft_sync_remote_attribute: 'mailNickname',
}

const cloneDefaultState = () => {
  return {...defaultState}
}

describe('settingsReducer', () => {
  beforeEach(() => {
    doUpdateSettings.mockImplementation(async state => state)
    getTenantErrorMessages.mockImplementation(_ => [])
    getSuffixErrorMessages.mockImplementation(_ => [])
  })

  afterEach(() => {
    doUpdateSettings.mockReset()
    getTenantErrorMessages.mockReset()
    getSuffixErrorMessages.mockReset()
  })

  describe('basic state updates', () => {
    it('updates the tenant', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.updateTenant,
        payload: {microsoft_sync_tenant: expectedState.microsoft_sync_tenant},
      })

      expect(result.microsoft_sync_tenant).toBe(expectedState.microsoft_sync_tenant)
    })

    it('updates the login attribute', () => {
      const result = settingsReducer(cloneDefaultState, {
        type: reducerActions.updateAttribute,
        payload: {
          microsoft_sync_login_attribute: expectedState.microsoft_sync_login_attribute,
        },
      })

      expect(result.microsoft_sync_login_attribute).toBe(
        expectedState.microsoft_sync_login_attribute
      )
    })

    it('clears errorMessages', () => {
      const state = settingsReducer(cloneDefaultState(), {
        type: reducerActions.removeAlerts,
      })

      expect(state.errorMessage).toEqual('')
      expect(state.successMessage).toEqual('')
    })

    it('updates the login attribute suffix', () => {
      const actualState = settingsReducer(cloneDefaultState, {
        type: reducerActions.updateSuffix,
        payload: {
          microsoft_sync_login_attribute_suffix:
            expectedState.microsoft_sync_login_attribute_suffix,
        },
      })

      expect(actualState.microsoft_sync_login_attribute_suffix).toEqual(
        expectedState.microsoft_sync_login_attribute_suffix
      )
    })

    it('updates the Active Directory lookup attribute', () => {
      const actualState = settingsReducer(cloneDefaultState, {
        type: reducerActions.updateRemoteAttribute,
        payload: {
          microsoft_sync_remote_attribute: expectedState.microsoft_sync_remote_attribute,
        },
      })

      expect(actualState.microsoft_sync_remote_attribute).toEqual(
        expectedState.microsoft_sync_remote_attribute
      )
    })

    describe('that affect the info message', () => {
      const state = {
        ...cloneDefaultState(),
        microsoft_sync_tenant: 'saved_value',
        last_saved_microsoft_sync_tenant: 'saved_value',
      }

      it('does not set info message if the tenant is unchanged', () => {
        const result = settingsReducer(state, {
          type: reducerActions.updateTenant,
          payload: {microsoft_sync_tenant: 'saved_value'},
        })

        expect(result.tenantInfoMessages.length).toBe(0)
      })

      it('sets an info message if the tenant is changed', () => {
        const result = settingsReducer(state, {
          type: reducerActions.updateTenant,
          payload: {microsoft_sync_tenant: 'new_value'},
        })

        expect(result.tenantInfoMessages.length).toBe(1)
      })

      it('updates the last saved tenant value on save', () => {
        const result = settingsReducer(
          {
            ...cloneDefaultState(),
            microsoft_sync_tenant: 'new_value',
          },
          {
            type: reducerActions.updateSuccess,
          }
        )

        expect(result.last_saved_microsoft_sync_tenant).toBe('new_value')
      })

      it('does not update the last saved tenant or error', () => {
        const result = settingsReducer(
          {
            ...cloneDefaultState(),
            microsoft_sync_tenant: 'new_value',
          },
          {
            type: reducerActions.updateError,
          }
        )

        expect(result.last_saved_microsoft_sync_tenant).not.toBe('new_value')
      })
    })
  })

  describe('initial data fetching', () => {
    it('updates state to match returned data on success', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.fetchSuccess,
        payload: {
          ...expectedState,
        },
      })
      expect(result).toStrictEqual({
        ...cloneDefaultState(),
        ...expectedState,
      })
    })

    it('still works even if no sync settings are returned', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.fetchSuccess,
        payload: {},
      })

      expect(result).toStrictEqual(cloneDefaultState())
    })

    it('adds an error message on fetch failure', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.fetchError,
      })

      expect(result.errorMessage).toBeTruthy()
    })

    it('updates the loading status when told to', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.fetchLoading,
        payload: {
          loading: false,
        },
      })

      expect(result.loading).toBeFalsy()
    })
  })

  describe('updating settings', () => {
    const dispatchMock = jest.fn()

    afterEach(() => {
      dispatchMock.mockClear()
    })

    it('tries to validate the tenant and suffix, stops if there are errors, and keeps the UI enabled', async () => {
      getTenantErrorMessages.mockImplementationOnce(_ => {
        return ['error!']
      })
      getSuffixErrorMessages.mockImplementationOnce(_ => {
        return ['error']
      })
      const state = settingsReducer(cloneDefaultState(), {
        type: reducerActions.updateSettings,
        dispatch: dispatchMock,
      })

      await flushPromises()

      expect(getTenantErrorMessages).toHaveBeenCalledTimes(1)
      expect(getSuffixErrorMessages).toHaveBeenCalledTimes(1)
      expect(doUpdateSettings).toHaveBeenCalledTimes(0)
      expect(dispatchMock).toHaveBeenCalledTimes(0)
      expect(state.uiEnabled).toBeTruthy()
    })

    it('tries to update settings and indicates success', async () => {
      settingsReducer(
        {
          ...cloneDefaultState(),
          ...expectedState,
        },
        {
          type: reducerActions.updateSettings,
          dispatch: dispatchMock,
        }
      )
      await flushPromises()

      expect(doUpdateSettings).toHaveBeenCalledTimes(1)
      const [call] = doUpdateSettings.mock.calls.pop()

      expect(call).toEqual({...cloneDefaultState(), ...expectedState, uiEnabled: false})

      expect(dispatchMock).toHaveBeenCalledTimes(1)
      expect(dispatchMock).toHaveBeenLastCalledWith({type: reducerActions.updateSuccess})
    })

    it('tries to update settings and indicates failure', async () => {
      doUpdateSettings.mockImplementationOnce(async () => {
        throw new Error('test failure!')
      })
      settingsReducer(cloneDefaultState(), {
        type: reducerActions.updateSettings,
        dispatch: dispatchMock,
      })

      await flushPromises()

      expect(doUpdateSettings).toHaveBeenCalledTimes(1)
      expect(dispatchMock).toHaveBeenCalledTimes(1)
      expect(dispatchMock).toHaveBeenLastCalledWith({type: reducerActions.updateError})
    })

    describe('toggling sync', () => {
      it('tries to validate the tenant and suffix, stops if there were errors, and keeps the UI enabled', () => {
        getTenantErrorMessages.mockImplementationOnce(_ => {
          return ['error!']
        })
        getSuffixErrorMessages.mockImplementationOnce(_ => {
          return ['error']
        })
        const newState = settingsReducer(cloneDefaultState(), {
          type: reducerActions.toggleSync,
          dispatch: dispatchMock,
        })

        expect(getTenantErrorMessages).toHaveBeenCalledTimes(1)
        expect(getSuffixErrorMessages).toHaveBeenCalledTimes(1)
        expect(doUpdateSettings).toHaveBeenCalledTimes(0)
        expect(dispatchMock).toHaveBeenCalledTimes(0)
        expect(newState.uiEnabled).toBeTruthy()
      })

      it('tries to toggle sync and indicate success', async () => {
        settingsReducer(cloneDefaultState(), {
          type: reducerActions.toggleSync,
          dispatch: dispatchMock,
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
        settingsReducer(cloneDefaultState(), {
          type: reducerActions.toggleSync,
          dispatch: dispatchMock,
        })

        await flushPromises()

        expect(doUpdateSettings).toHaveBeenCalledTimes(1)
        expect(dispatchMock).toHaveBeenCalledTimes(1)
        expect(dispatchMock).toHaveBeenLastCalledWith({type: reducerActions.toggleError})
      })

      it('disables the UI while trying to update or toggle sync', () => {
        for (const type of [reducerActions.updateSettings, reducerActions.toggleSync]) {
          const {uiEnabled} = settingsReducer(cloneDefaultState(), {
            type,
            dispatch: dispatchMock,
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
        reducerActions.toggleError,
      ]) {
        const {uiEnabled} = settingsReducer(cloneDefaultState(), {
          type,
        })
        expect(uiEnabled).toBeTruthy()
      }
    })

    it('adds a success message on success', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.updateSuccess,
      })

      expect(result.successMessage).toBeTruthy()
    })

    it('adds an error message on failure to update', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.updateError,
      })

      expect(result.errorMessage).toBeTruthy()
    })

    it('adds an error message on failure to toggle and inverts enabled', () => {
      const result = settingsReducer(cloneDefaultState(), {
        type: reducerActions.toggleError,
      })

      expect(result.errorMessage).toBeTruthy()
      // The default state is disabled, so it should be switched back to true
      expect(result.microsoft_sync_enabled).toBeTruthy()
    })
  })
})
