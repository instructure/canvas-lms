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
import {render, screen, waitFor, cleanup} from '@testing-library/react'
import {ZAccountId} from '../../model/AccountId'
import {ZDeveloperKeyId} from '../../model/developer_key/DeveloperKeyId'
import {InheritedKeyRegistrationWizard} from '../InheritedKeyRegistrationWizard'
import {
  openInheritedKeyWizard,
  useInheritedKeyWizardState,
} from '../InheritedKeyRegistrationWizardState'
import type {InheritedKeyService} from '../InheritedKeyService'
import {success} from '../../../common/lib/apiResult/ApiResult'
import {mockRegistrationWithAllInformation} from '../../pages/manage/__tests__/helpers'
import userEvent from '@testing-library/user-event'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'

const getHeadingByText = (text: RegExp) => screen.getByText(text, {selector: 'h2, h3'})

const getButtonByText = (text: RegExp) => {
  const element = screen.getByText((content, el) => {
    return Boolean(el?.closest('button') && text.test(content))
  })
  return element.closest('button')!
}

describe('RegistrationWizardModal', () => {
  let error: (...data: any[]) => void
  let warn: (...data: any[]) => void

  beforeAll(() => {
    // instui logs an error when we render a component
    // immediately under Modal

    error = console.error
    warn = console.warn
    console.error = vi.fn()
    console.warn = vi.fn()
  })

  afterAll(() => {
    console.error = error
    console.warn = warn
  })

  const bindGlobalLtiRegistration = vi.fn()
  const fetchRegistrationByClientId = vi.fn()
  const updateRegistration = vi.fn()
  const installInheritedRegistration = vi.fn()

  const inheritedKeyService: InheritedKeyService = {
    bindGlobalLtiRegistration,
    fetchRegistrationByClientId,
    updateRegistration,
    installInheritedRegistration,
  }

  const accountId = ZAccountId.parse('123')
  const developerKeyId = ZDeveloperKeyId.parse('abc')
  const onSuccessfulInstallation = vi.fn()

  const mockRegistrationData = () =>
    mockRegistrationWithAllInformation({
      n: 'An Example App',
      i: 2,
      configuration: {
        description: 'An Example App Description',
        placements: [
          {
            placement: 'course_navigation',
            message_type: 'LtiResourceLinkRequest',
            text: 'Course Nav Placement',
          },
        ],
        scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
      },
    })

  const setupTest = () => {
    bindGlobalLtiRegistration.mockReset()
    fetchRegistrationByClientId.mockReset()
    installInheritedRegistration.mockReset()
    updateRegistration.mockReset()
    onSuccessfulInstallation.mockClear()

    useInheritedKeyWizardState.setState(prev => ({
      ...prev,
      state: {
        ...prev.state,
        _type: 'Initial' as const,
        open: false,
        service: inheritedKeyService,
        accountId,
      },
    }))
  }

  const open = async () => {
    openInheritedKeyWizard(developerKeyId, onSuccessfulInstallation)
    render(<InheritedKeyRegistrationWizard accountId={accountId} service={inheritedKeyService} />)

    const headerText = getHeadingByText(/Install App/i)
    await waitFor(() => {
      expect(headerText).toBeInTheDocument()
    })
  }

  const mockFetch = () => {
    fetchRegistrationByClientId.mockResolvedValue(success(mockRegistrationData()))
  }

  const teardownTest = () => {
    useInheritedKeyWizardState.setState(prev => ({
      ...prev,
      state: {
        ...prev.state,
        _type: 'Initial' as const,
        open: false,
        reviewing: false,
        service: {} as InheritedKeyService,
        accountId: undefined,
        developerKeyId: undefined,
      },
    }))
    cleanup()
  }

  describe('When flag is OFF (old behavior)', () => {
    beforeEach(() => {
      window.ENV = {FEATURES: {lti_registrations_templates: false}} as GlobalEnv
      setupTest()
    })

    afterEach(() => {
      teardownTest()
    })

    it('should render the modal title', async () => {
      mockFetch()
      await open()
      const headerText = getHeadingByText(/Install App/i)
      expect(headerText).toBeInTheDocument()
    })

    it('should request the registration and show the old review screen', async () => {
      mockFetch()
      await open()

      expect(getHeadingByText(/^Review$/i)).toBeInTheDocument()
      expect(fetchRegistrationByClientId).toHaveBeenCalledWith(accountId, developerKeyId)
    })

    it('should show the old review screen with Cancel and Install buttons', async () => {
      mockFetch()
      await open()

      const cancelButton = getButtonByText(/Cancel/i)
      expect(cancelButton).toBeInTheDocument()

      const installButton = getButtonByText(/Install App/i)
      expect(installButton).toBeInTheDocument()
    })

    it('should disable the install button while the registration is loading', async () => {
      fetchRegistrationByClientId.mockClear()
      fetchRegistrationByClientId.mockReturnValue(new Promise(() => {}))

      useInheritedKeyWizardState.setState(prev => ({
        ...prev,
        state: {
          ...prev.state,
          _type: 'Initial' as const,
          open: false,
          service: inheritedKeyService,
          accountId,
        },
      }))

      await open()

      expect(screen.getByTestId('inherited-modal-loading-registration')).toBeInTheDocument()

      const installButton = getButtonByText(/Install App/i)
      expect(installButton).toBeInTheDocument()
      expect(installButton).toBeDisabled()
    })

    it('should enable the install button when the registration loads', async () => {
      mockFetch()
      await open()

      const installButton = getButtonByText(/Install App/i)
      expect(installButton).toBeEnabled()
    })

    it('should install the app and call onSuccessfulInstallation when Install App is clicked', async () => {
      mockFetch()
      bindGlobalLtiRegistration.mockResolvedValue(success({}))
      updateRegistration.mockResolvedValue(success({}))
      installInheritedRegistration.mockResolvedValue({
        _type: 'Success',
        registrationId: '2',
        registrationName: 'An Example App',
      })
      await open()

      const installButton = getButtonByText(/Install App/i)
      expect(installButton).toBeEnabled()

      await userEvent.click(installButton)

      await waitFor(() => expect(onSuccessfulInstallation).toHaveBeenCalled())
      expect(updateRegistration).not.toHaveBeenCalled()
    })

    it('should close the modal when Cancel is clicked', async () => {
      mockFetch()
      await open()

      expect(getButtonByText(/Cancel/i)).toBeInTheDocument()

      await userEvent.click(getButtonByText(/Cancel/i))

      expect(useInheritedKeyWizardState.getState().state.open).toBe(false)
    })
  })

  describe('When flag is ON (new multi-step wizard)', () => {
    beforeEach(() => {
      window.ENV = {FEATURES: {lti_registrations_templates: true}} as GlobalEnv
      setupTest()
    })

    afterEach(() => {
      teardownTest()
    })

    const goToReviewScreen = async () => {
      await waitFor(() => {
        expect(getHeadingByText(/Launch Settings/i)).toBeInTheDocument()
      })

      for (let i = 0; i < 7; i++) {
        await userEvent.click(getButtonByText(/Next/i))
      }

      await waitFor(() => {
        expect(getHeadingByText(/^Review$/i)).toBeInTheDocument()
      })
    }

    it('should show the Launch Settings screen first when registration loads', async () => {
      mockFetch()
      await open()

      expect(getHeadingByText(/Launch Settings/i)).toBeInTheDocument()
    })

    it('should show Cancel and Next buttons on the first screen', async () => {
      mockFetch()
      await open()

      expect(getButtonByText(/Cancel/i)).toBeInTheDocument()
      expect(getButtonByText(/Next/i)).toBeInTheDocument()
    })

    it('should navigate through all screens in order when clicking Next', async () => {
      mockFetch()
      await open()

      expect(getHeadingByText(/Launch Settings/i)).toBeInTheDocument()

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/^Permissions$/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/Data Sharing/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/^Placements$/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/Override URIs/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/Nickname/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/^Icon URLs$/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/^Review$/i)).toBeInTheDocument()
      })
    })

    it('should show Install App button on the Review screen', async () => {
      mockFetch()
      await open()
      await goToReviewScreen()

      expect(getButtonByText(/Install App/i)).toBeInTheDocument()
    })

    it('should navigate backwards through screens when clicking Previous', async () => {
      mockFetch()
      await open()

      expect(getHeadingByText(/Launch Settings/i)).toBeInTheDocument()

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/^Permissions$/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Next/i))
      await waitFor(() => {
        expect(getHeadingByText(/Data Sharing/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Previous/i))
      await waitFor(() => {
        expect(getHeadingByText(/^Permissions$/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Previous/i))
      await waitFor(() => {
        expect(getHeadingByText(/Launch Settings/i)).toBeInTheDocument()
      })
    })

    it('should close the modal when Cancel is clicked on the first screen', async () => {
      mockFetch()
      await open()

      await waitFor(() => {
        expect(getButtonByText(/Cancel/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Cancel/i))

      expect(useInheritedKeyWizardState.getState().state.open).toBe(false)
    })

    it('should close the modal when the X close button is clicked', async () => {
      mockFetch()
      await open()

      await waitFor(() => {
        expect(getHeadingByText(/Launch Settings/i)).toBeInTheDocument()
      })

      const closeButton = getButtonByText(/Close/i)
      await userEvent.click(closeButton)

      await waitFor(() => {
        expect(useInheritedKeyWizardState.getState().state.open).toBe(false)
      })
    })

    it('should allow editing a section from Review and return with Back to Review', async () => {
      mockFetch()
      await open()
      await goToReviewScreen()

      const editNamingButton = getButtonByText(/Edit Naming/i)
      await userEvent.click(editNamingButton)

      await waitFor(() => {
        expect(getHeadingByText(/Nickname/i)).toBeInTheDocument()
        expect(getButtonByText(/Back to Review/i)).toBeInTheDocument()
      })

      await userEvent.click(getButtonByText(/Back to Review/i))

      await waitFor(() => {
        expect(getHeadingByText(/^Review$/i)).toBeInTheDocument()
      })
    })

    it('should install the tool when clicking Install App on the Review screen', async () => {
      mockFetch()
      bindGlobalLtiRegistration.mockResolvedValue(success({registration_id: '2'}))
      updateRegistration.mockResolvedValue(success({}))
      installInheritedRegistration.mockResolvedValue({
        _type: 'Success',
        registrationId: '2',
        registrationName: 'An Example App',
      })
      await open()
      await goToReviewScreen()

      await userEvent.click(getButtonByText(/Install App/i))

      await waitFor(() => {
        expect(installInheritedRegistration).toHaveBeenCalled()
        expect(onSuccessfulInstallation).toHaveBeenCalled()
      })
    })

    describe('Editing data on screens', () => {
      const screenOrder = [
        /Launch Settings/i,
        /^Permissions$/i,
        /Data Sharing/i,
        /^Placements$/i,
        /Override URIs/i,
        /Nickname/i,
        /^Icon URLs$/i,
        /^Review$/i,
      ]

      const navigateToScreen = async (targetScreenIndex: number) => {
        await waitFor(() => {
          expect(getHeadingByText(/Launch Settings/i)).toBeInTheDocument()
        })

        for (let i = 0; i < targetScreenIndex; i++) {
          await userEvent.click(getButtonByText(/Next/i))
          await waitFor(() => {
            expect(getHeadingByText(screenOrder[i + 1])).toBeInTheDocument()
          })
        }
      }

      const continueToReview = async (currentScreenIndex: number) => {
        for (let i = currentScreenIndex; i < 7; i++) {
          await userEvent.click(getButtonByText(/Next/i))
          await waitFor(() => {
            expect(getHeadingByText(screenOrder[i + 1])).toBeInTheDocument()
          })
        }
      }

      const getOverlayState = () => {
        const state = useInheritedKeyWizardState.getState().state
        if ('overlayStore' in state && state.overlayStore) {
          return state.overlayStore.getState().state
        }
        return null
      }

      it('should save toggled scope when installing', async () => {
        mockFetch()
        bindGlobalLtiRegistration.mockResolvedValue(success({registration_id: '2'}))
        updateRegistration.mockResolvedValue(success({}))
        installInheritedRegistration.mockResolvedValue({
          _type: 'Success',
          registrationId: '2',
          registrationName: 'An Example App',
        })
        await open()
        await navigateToScreen(1)

        const scopeCheckbox = screen.getByTestId(
          'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
        )
        await userEvent.click(scopeCheckbox)

        await continueToReview(1)
        await userEvent.click(getButtonByText(/Install App/i))

        await waitFor(() => {
          expect(installInheritedRegistration).toHaveBeenCalled()
        })

        const overlayState = getOverlayState()
        expect(overlayState?.permissions.scopes).not.toContain(
          'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
        )
      })

      it('should save changed privacy level when installing', async () => {
        mockFetch()
        bindGlobalLtiRegistration.mockResolvedValue(success({registration_id: '2'}))
        updateRegistration.mockResolvedValue(success({}))
        installInheritedRegistration.mockResolvedValue({
          _type: 'Success',
          registrationId: '2',
          registrationName: 'An Example App',
        })
        await open()
        await navigateToScreen(2)

        const privacySelect = screen.getByLabelText(/User Data Shared With This App/i)
        await userEvent.click(privacySelect)
        const publicOption = screen.getByText(/All user data/i)
        await userEvent.click(publicOption)

        await continueToReview(2)
        await userEvent.click(getButtonByText(/Install App/i))

        await waitFor(() => {
          expect(installInheritedRegistration).toHaveBeenCalled()
        })

        const overlayState = getOverlayState()
        expect(overlayState?.data_sharing.privacy_level).toBe('public')
      })

      it('should save toggled placement when installing', async () => {
        mockFetch()
        bindGlobalLtiRegistration.mockResolvedValue(success({registration_id: '2'}))
        updateRegistration.mockResolvedValue(success({}))
        installInheritedRegistration.mockResolvedValue({
          _type: 'Success',
          registrationId: '2',
          registrationName: 'An Example App',
        })
        await open()
        await navigateToScreen(3)

        const placementCheckbox = screen.getByTestId('placement-checkbox-course_navigation')
        await userEvent.click(placementCheckbox)

        await continueToReview(3)
        await userEvent.click(getButtonByText(/Install App/i))

        await waitFor(() => {
          expect(installInheritedRegistration).toHaveBeenCalled()
        })

        const overlayState = getOverlayState()
        expect(overlayState?.placements.placements).not.toContain('course_navigation')
      })

      it('should save changed admin nickname when installing', async () => {
        mockFetch()
        bindGlobalLtiRegistration.mockResolvedValue(success({registration_id: '2'}))
        updateRegistration.mockResolvedValue(success({}))
        installInheritedRegistration.mockResolvedValue({
          _type: 'Success',
          registrationId: '2',
          registrationName: 'An Example App',
        })
        await open()
        await navigateToScreen(5)

        const nicknameInput = screen.getByLabelText(/Administration Nickname/i)
        await userEvent.clear(nicknameInput)
        await userEvent.type(nicknameInput, 'My Custom Nickname')

        await continueToReview(5)
        await userEvent.click(getButtonByText(/Install App/i))

        await waitFor(() => {
          expect(installInheritedRegistration).toHaveBeenCalled()
        })

        const overlayState = getOverlayState()
        expect(overlayState?.naming.nickname).toBe('My Custom Nickname')
      })
    })
  })
})
