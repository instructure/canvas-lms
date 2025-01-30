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
        },
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
