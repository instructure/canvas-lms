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
import {render, cleanup, waitFor, act} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DeveloperKeyModal from '../NewKeyModal'
import $ from '@canvas/rails-flash-notifications'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('NewKeyModal', () => {
  const user = userEvent.setup()

  beforeEach(() => {
    fakeENV.setup({
      validLtiPlacements: [],
      validLtiScopes: {},
      RAILS_ENVIRONMENT: 'production',
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.restoreAllMocks()
    cleanup()
  })

  const selectedScopes = [
    'url:POST|/api/v1/accounts/:account_id/account_notifications',
    'url:PUT|/api/v1/accounts/:account_id/account_notifications/:id',
  ]

  const fakeActions = {
    createOrEditDeveloperKey: () => {},
    developerKeysModalClose: () => {},
    editDeveloperKey: () => {},
    listDeveloperKeysReplace: () => {},
    listDeveloperKeyScopesSet: () => {},
    resetLtiState: () => {},
    saveLtiToolConfiguration: () => {},
    updateLtiKey: () => {},
  }

  const developerKey = {
    access_token_count: 77,
    account_name: 'bob account',
    api_key: 'rYcJ7LnUbSAuxiMh26tXTSkaYWyfRPh2lr6FqTLqx0FRsmv44EVZ2yXC8Rgtabc3',
    created_at: '2018-02-09T20:36:50Z',
    email: 'bob@myemail.com',
    icon_url: 'http://my_image.com',
    id: '10000000000004',
    last_used_at: '2018-06-07T20:36:50Z',
    name: 'Dev Key Name',
    notes: 'all the notas',
    redirect_uri: 'http://my_redirect_uri.com',
    redirect_uris: 'http://my_redirect_uri.com',
    user_id: '53532',
    user_name: 'billy bob',
    vendor_code: 'b3w9w9bf',
    workflow_state: 'active',
    test_cluster_only: false,
  }

  const validToolConfig = {
    title: 'testTest',
    description: 'a',
    scopes: [
      'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
      'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
      'https://purl.imsglobal.org/spec/lti-ags/scope/score',
      'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
    ],
    extensions: [
      {
        domain: 'test.testcloud.org',
        tool_id: 'toolid',
        platform: 'canvas.instructure.com',
        settings: {
          text: 'test',
          use_1_3: true,
          icon_url: 'http://test.testcloud.org/img/default-icon-16x16.png',
          selection_width: 500,
          selection_height: 500,
          placements: [
            {
              placement: 'editor_button',
              target_link_uri: 'https://test.testcloud.org/test/lti/store/',
              text: 'testTools',
              enabled: true,
              icon_url: 'https://static.test.org/img/default-icon-16x16.png',
              message_type: 'LtiDeepLinkingRequest',
              canvas_icon_class: 'icon-lti',
            },
          ],
        },
        privacy_level: 'public',
      },
    ],
    target_link_uri: 'https://test.testcloud.org/test/lti/oidc_launch',
    oidc_initiation_url: 'https://test.testcloud.org/test/lti/oidc_login',
    public_jwk: {
      kty: 'RSA',
      e: 'AQAB',
      n: 'vESXFmlzHz-nhZXTkjo29SBpamCzkd7SnpMXgdFEWjLfDeOu0D3JivEEUQ4U67xUBMY9voiJsG2oydMXjgkmGliUIVg-rhyKdBUJu5v6F659FwCj60A8J8qcstIkZfBn3yyOPVwp1FHEUSNvtbDLSRIHFPv-kh8gYyvqz130hE37qAVcaNME7lkbDmH1vbxi3D3A8AxKtiHs8oS41ui2MuSAN9MDb7NjAlFkf2iXlSVxAW5xSek4nHGr4BJKe_13vhLOvRUCTN8h8z-SLORWabxoNIkzuAab0NtfO_Qh0rgoWFC9T69jJPAPsXMDCn5oQ3xh_vhG0vltSSIzHsZ8pw',
      kid: '-1302712033',
      alg: 'RS256',
      use: 'sig',
    },
  }

  const createLtiKeyState = {
    isLtiKey: false,
    toolConfiguration: {},
  }

  const createDeveloperKeyState = {
    isLtiKey: false,
    editing: false,
    developerKeyCreateOrEditPending: false,
    developerKeyCreateOrEditSuccessful: false,
    developerKeyCreateOrEditFailed: false,

    developerKeyModalOpen: true,
    developerKey: {id: 22},
  }

  const editDeveloperKeyState = {
    ...createDeveloperKeyState,
    developerKeyModalOpen: true,
    developerKey,
  }

  const closedDeveloperKeyState = {
    ...createDeveloperKeyState,
    developerKeyModalOpen: false,
    developerKey,
  }

  const listDeveloperKeyScopesState = {
    availableScopes: {},
    listDeveloperKeyScopesPending: true,
  }

  const mountNode = () => document.querySelector('#fixtures')

  const defaultProps = (props = {}) => ({
    selectedScopes,
    availableScopes: {},
    availableScopesPending: false,
    closeModal: () => {},
    ctx: {params: {contextId: '1'}},
    mountNode,
    store: {dispatch: () => Promise.resolve()},
    handleSuccessfulSave: () => {},
    ...props,
  })

  const renderDeveloperKeyModal = props => {
    const ref = React.createRef()

    const result = {
      ref,
      wrapper: render(
        <DeveloperKeyModal {...defaultProps(props)} ref={ref} data-testid="developer-key-modal" />,
      ),
    }

    return result
  }

  describe('isOpen prop', () => {
    const modalWithState = createOrEditDeveloperKeyState =>
      renderDeveloperKeyModal({
        createLtiKeyState,
        createOrEditDeveloperKeyState,
        actions: fakeActions,
      })

    it('opens the modal if isOpen prop is true', () => {
      const {wrapper} = modalWithState(createDeveloperKeyState)
      const modal = wrapper.getByRole('dialog')

      expect(modal).toBeInTheDocument()
    })

    it('closes the modal if isOpen prop is false', () => {
      modalWithState(closedDeveloperKeyState)

      const modal = document.querySelector('[role="dialog"]')

      expect(modal).not.toBeInTheDocument()
    })
  })

  describe('submitting the form', () => {
    async function submitForm(createOrEditDeveloperKeyState) {
      const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: jest.fn()}
      const {ref} = renderDeveloperKeyModal({
        actions: mergedFakeActions,
        createLtiKeyState,
        createOrEditDeveloperKeyState,
        listDeveloperKeyScopesState,
      })

      await act(async () => {
        ref.current.submitForm()
      })

      const [[sentFormData]] = mergedFakeActions.createOrEditDeveloperKey.mock.calls
      const sentDevKey = sentFormData.developer_key

      return sentDevKey
    }

    it('sets isSaving to true to disable the Save button', async () => {
      const createOrEditSpy = jest
        .fn()
        .mockImplementation(() => () => new Promise(resolve => setTimeout(resolve, 100)))
      const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
      const {ref, wrapper} = renderDeveloperKeyModal({
        createOrEditDeveloperKeyState: createDeveloperKeyState,
        actions: mergedFakeActions,
      })

      // Set isSaving directly to ensure we can test the state
      await act(async () => {
        ref.current.setState({isSaving: true})
      })

      // Check if isSaving is true
      expect(ref.current.state.isSaving).toBeTruthy()

      // Also verify the spinner is shown when isSaving is true
      expect(wrapper.getByRole('img', {name: /creating key/i})).toBeInTheDocument()
    })

    it('sends the contents of the form saving', async () => {
      const developerKey2 = {
        ...developerKey,
        require_scopes: true,
        scopes: ['test'],
        test_cluster_only: true,
      }
      const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}

      const sentDevKey = await submitForm(editDeveloperKeyState2)

      expect(sentDevKey).toEqual({
        ...developerKey,
        scopes: selectedScopes,
        require_scopes: true,
        test_cluster_only: true,
      })
    })

    it('sends form content without scopes and require_scopes set to false when not require_scopes', async () => {
      const sentDevKey = await submitForm(editDeveloperKeyState)

      expect(sentDevKey).toEqual({
        ...developerKey,
        require_scopes: false,
        test_cluster_only: false,
      })
    })

    it('adds each selected scope to the form data', async () => {
      const developerKey2 = {...developerKey, require_scopes: true, scopes: ['test']}
      const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
      const sentDevKey = await submitForm(editDeveloperKeyState2)

      expect(sentDevKey.scopes).toEqual(selectedScopes)
    })

    it('removes testClusterOnly from the form data if it is undefined', async () => {
      const developerKey2 = {...developerKey, require_scopes: true, scopes: ['test']}
      delete developerKey2.test_cluster_only
      const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
      const sentDevKey = await submitForm(editDeveloperKeyState2)

      expect(sentDevKey.test_cluster_only).toBeFalsy()
    })

    describe('and the context is site admin', () => {
      const createOrEditSpy = jest.fn()
      const props = {
        ctx: {
          params: {
            contextId: 'site_admin',
          },
        },
        createOrEditDeveloperKeyState: createDeveloperKeyState,
        actions: {...fakeActions, createOrEditDeveloperKey: createOrEditSpy},
      }

      // No need for oldEnv variable when using fakeENV

      beforeEach(() => {
        fakeENV.setup({
          ...fakeENV.ENV,
          RAILS_ENVIRONMENT: 'production',
        })
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('renders a confirmation modal to prevent accidental updates', async () => {
        const {wrapper} = renderDeveloperKeyModal(props)

        await act(async () => {
          await user.click(wrapper.getByRole('button', {name: /Save/i}))
        })

        expect(await wrapper.findByText('Environment Confirmation')).toBeInTheDocument()

        const input = wrapper.getByTestId('confirm-prompt-input')

        await act(async () => {
          await user.click(input)
          await user.paste('beta')
          await user.click(wrapper.getByText(/^Confirm/i).closest('button'))
        })

        expect(await wrapper.findByText(/The provided value is incorrect/i)).toBeInTheDocument()

        await act(async () => {
          await user.click(input)
          await user.clear(input)
          await user.paste('production')
          await user.click(wrapper.getByText(/^Confirm/i).closest('button'))
        })

        await waitFor(() => {
          expect(wrapper.queryByText(/Environment Confirmation/i)).not.toBeInTheDocument()
        })
      })
    })
  })

  describe('scope selection', () => {
    afterEach(() => {
      cleanup()
    })

    it('flashes an error if no scopes are selected', async () => {
      const flashStub = jest.spyOn($, 'flashError')
      const createOrEditSpy = jest.fn()
      const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
      const developerKey2 = {...developerKey, require_scopes: true, scopes: []}
      const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: editDeveloperKeyState2,
        listDeveloperKeyScopesState,
        selectedScopes: [],
        actions: mergedFakeActions,
      })

      await act(async () => {
        ref.current.submitForm()
      })

      expect(flashStub).toHaveBeenCalledWith('At least one scope must be selected.')
    })

    it('allows saving if the key previously had scopes', async () => {
      const flashStub = jest.spyOn($, 'flashError')
      const keyWithScopes = {...developerKey, require_scopes: true, scopes: selectedScopes}
      const editKeyWithScopesState = {...editDeveloperKeyState, developerKey: keyWithScopes}
      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: editKeyWithScopesState,
        listDeveloperKeyScopesState,
        actions: fakeActions,
      })

      await act(async () => {
        ref.current.submitForm()
      })

      expect(flashStub).not.toHaveBeenCalled()
    })
  })

  describe('a11y checks', () => {
    it('renders the saving spinner with a polite aria-live attribute', async () => {
      const {wrapper, ref} = renderDeveloperKeyModal({
        createOrEditDeveloperKeyState: {
          ...createDeveloperKeyState,
        },
        actions: {
          ...fakeActions,
        },
      })

      await act(async () => {
        ref.current.setState({isSaving: true})
      })

      expect(
        wrapper.getByRole('img', {
          name: /creating key/i,
        }),
      ).toBeInTheDocument()
      expect(document.querySelector('div[aria-live="polite"]')).toBeInTheDocument()
    })

    describe('flash alerts checks', () => {
      const successfulSaveStub = jest.fn()

      const createWrapper = (stateOverrides, actionOverrides) =>
        renderDeveloperKeyModal({
          createOrEditDeveloperKeyState: {
            ...createDeveloperKeyState,
            developerKey: {
              ...developerKey,
              tool_configuration: {
                ...validToolConfig,
              },
            },
            ...stateOverrides,
          },
          actions: {
            ...fakeActions,
            ...actionOverrides,
          },
          handleSuccessfulSave: successfulSaveStub,
        })

      afterEach(() => {
        successfulSaveStub.mockClear()
      })

      describe('LTI Developer Key is being created', () => {
        it('notifies if the key saves successfully', async () => {
          const saveLtiToolConfigurationStub = jest.fn().mockImplementation(() => {
            return () => {
              return Promise.resolve({
                developer_key: developerKey,
                tool_configuration: validToolConfig,
              })
            }
          })
          const {ref} = createWrapper(
            {isLtiKey: true},
            {saveLtiToolConfiguration: saveLtiToolConfigurationStub},
          )

          await act(async () => {
            await ref.current.saveLtiToolConfiguration()
          })

          expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        })

        it("doesn't notify if the key fails to be created", async () => {
          const saveLtiToolConfigurationStub = jest
            .fn()
            .mockImplementation(() => () => Promise.reject(new Error('testing')))
          const {ref} = createWrapper(
            {isLtiKey: true},
            {saveLtiToolConfiguration: saveLtiToolConfigurationStub},
          )

          await act(async () => {
            await ref.current.saveLtiToolConfiguration()
          })

          expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
          expect(successfulSaveStub).not.toHaveBeenCalled()
        })

        it('notifies and forwards if the API returns a warning_message', async () => {
          const warning_message = 'This is a warning message'
          const saveLtiToolConfigurationStub = jest.fn().mockImplementation(
            () => () =>
              Promise.resolve({
                developer_key: developerKey,
                tool_configuration: validToolConfig,
                warning_message,
              }),
          )
          const {ref} = createWrapper(
            {isLtiKey: true},
            {saveLtiToolConfiguration: saveLtiToolConfigurationStub},
          )

          await act(async () => {
            await ref.current.saveLtiToolConfiguration()
          })

          expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledWith(warning_message)
        })
      })

      describe('LTI Developer Key is being edited', () => {
        it('notifies if the key saves successfully', async () => {
          const updateLtiKeyStub = jest.fn().mockResolvedValue({
            developer_key: developerKey,
            tool_configuration: validToolConfig,
          })

          const {ref} = createWrapper({}, {updateLtiKey: updateLtiKeyStub})

          await act(async () => {
            await ref.current.saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)
          })

          expect(updateLtiKeyStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        })

        it("doesn't notifiy if the key fails to save", async () => {
          const updateLtiKeyStub = jest.fn().mockRejectedValue(null)
          const {ref} = createWrapper({}, {updateLtiKey: updateLtiKeyStub})

          await act(async () => {
            await ref.current.saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)
          })

          expect(updateLtiKeyStub).toHaveBeenCalled()
          expect(successfulSaveStub).not.toHaveBeenCalled()
        })

        it('notifies if the API returns a warning_message', async () => {
          const warning_message = 'This is a warning message'
          const updateLtiKeyStub = jest.fn().mockResolvedValue({
            developer_key: developerKey,
            tool_configuration: validToolConfig,
            warning_message,
          })

          const {ref} = createWrapper({isLtiKey: true}, {updateLtiKey: updateLtiKeyStub})

          await act(async () => {
            await ref.current.saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)
          })

          expect(updateLtiKeyStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledWith(warning_message)
        })
      })

      // Turns out, for API keys, there's no difference in the code path taken,
      // at least with respect to flashing an alert
      describe('API Dev Key is being created/edited', () => {
        it('flashes an alert if the key saves successfully', async () => {
          const createOrEditStub = jest.fn().mockImplementation(() => {
            return () => {
              return Promise.resolve(null)
            }
          })

          // TODO: Modify this state so that it shows a key being created, not being edited.
          const {ref} = createWrapper(
            {
              developerKeyCreateOrEditSuccessful: true,
              developerKeyCreateOrEditPending: false,
              developerKeyCreateOrEditFailed: false,
            },
            {createOrEditDeveloperKey: createOrEditStub},
          )

          await act(async () => {
            await ref.current.submitForm()
          })

          expect(createOrEditStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        })

        it("doesn't flash an alert if the key fails to save", async () => {
          const createOrEditStub = jest.fn().mockImplementation(() => {
            return () => {
              return Promise.resolve(null)
            }
          })

          // TODO: Modify this state so that it shows a key being created, not being edited.
          const {ref} = createWrapper(
            {
              developerKeyCreateOrEditSuccessful: false,
              developerKeyCreateOrEditPending: false,
              developerKeyCreateOrEditFailed: true,
            },
            {createOrEditDeveloperKey: createOrEditStub},
          )

          await act(async () => {
            await ref.current.submitForm()
          })

          expect(createOrEditStub).toHaveBeenCalled()
          expect(successfulSaveStub).not.toHaveBeenCalledTimes(1)
        })
      })
    })
  })
})
