/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

function dispatchConsentEvent(granted: boolean): void {
  window.dispatchEvent(
    new CustomEvent('OneTrustGroupsUpdated', {
      detail: granted ? ['C0002'] : [],
    }),
  )
}

describe('pendo/index', () => {
  let initializePendo: () => Promise<any>
  let mockInitialize: ReturnType<typeof vi.fn>
  let removeRegisteredListeners: () => void

  const baseEnv = {
    RAILS_ENVIRONMENT: 'development',
    PENDO_APP_ID: 'test-app-id',
    PENDO_APP_ENV: 'io',
    current_user_usage_metrics_id: 'user-123',
    current_user_roles: ['student'],
    LOCALE: 'en',
    DOMAIN_ROOT_ACCOUNT_UUID: 'account-uuid-123',
    DOMAIN_ROOT_ACCOUNT_SFID: 'sf-id-123',
    FEATURES: {account_survey_notifications: true, pendo_extended: false},
    USAGE_METRICS_METADATA: null,
  }

  beforeEach(async () => {
    vi.resetModules()

    mockInitialize = vi.fn()
    vi.doMock('@pendo/agent', () => ({
      initialize: mockInitialize,
      Replay: {},
      VocPortal: {},
    }))

    // Track listeners added to window so they can be removed after each test.
    // Without this, listeners from prior tests accumulate on the jsdom window
    // and fire (with stale module state) when later tests dispatch events.
    const registeredListeners: Array<
      [string, EventListenerOrEventListenerObject, (boolean | AddEventListenerOptions)?]
    > = []
    const origAdd = window.addEventListener.bind(window)
    vi.spyOn(window, 'addEventListener').mockImplementation((type, listener, options) => {
      registeredListeners.push([type, listener as EventListenerOrEventListenerObject, options])
      origAdd(type, listener as any, options as any)
    })
    removeRegisteredListeners = () => {
      registeredListeners.forEach(([type, listener, options]) => {
        window.removeEventListener(type, listener, options)
      })
    }

    ;(globalThis as any).ENV = {...baseEnv}
    window.CANVAS_COOKIE_CONSENT_STATE = null
    delete (window as any).CANVAS_DEBUGTAP

    const module = await import('../index')
    initializePendo = module.initializePendo
  })

  afterEach(() => {
    removeRegisteredListeners?.()
    vi.restoreAllMocks()
  })

  describe('initializePendo', () => {
    it('returns null when user has not consented to cookies', async () => {
      window.CANVAS_COOKIE_CONSENT_STATE = false

      const result = await initializePendo()

      expect(result).toBeNull()
      expect(mockInitialize).not.toHaveBeenCalled()
    })

    it('returns null and logs info when PENDO_APP_ID is missing', async () => {
      window.CANVAS_COOKIE_CONSENT_STATE = true
      ;(globalThis as any).ENV = {...baseEnv, PENDO_APP_ID: undefined}
      const consoleSpy = vi.spyOn(console, 'info').mockImplementation(() => {})

      const result = await initializePendo()

      expect(result).toBeNull()
      expect(consoleSpy).toHaveBeenCalledWith('Pendo not initialized: PENDO_APP_ID missing')
      expect(mockInitialize).not.toHaveBeenCalled()
    })

    it('calls initialize with correct visitor and account data', async () => {
      window.CANVAS_COOKIE_CONSENT_STATE = true
      mockInitialize.mockResolvedValue({isReady: vi.fn().mockReturnValue(true), teardown: vi.fn()})

      await initializePendo()

      expect(mockInitialize).toHaveBeenCalledWith(
        expect.objectContaining({
          apiKey: 'test-app-id',
          env: 'io',
          globalKey: 'canvasUsageMetrics',
          visitor: expect.objectContaining({
            id: 'user-123',
            canvasRoles: ['student'],
            locale: 'en',
          }),
          account: expect.objectContaining({
            id: 'account-uuid-123',
            surveyOptOut: false,
          }),
        }),
      )
    })

    it('does not re-initialize on subsequent calls', async () => {
      window.CANVAS_COOKIE_CONSENT_STATE = true
      mockInitialize.mockResolvedValue({isReady: vi.fn().mockReturnValue(true), teardown: vi.fn()})

      await initializePendo()
      await initializePendo()

      expect(mockInitialize).toHaveBeenCalledTimes(1)
    })
  })

  describe('OneTrustGroupsUpdated event listener', () => {
    it('initializes pendo when consent is granted and pendo has not been started', async () => {
      // Register the listener without starting pendo
      window.CANVAS_COOKIE_CONSENT_STATE = false
      await initializePendo()

      mockInitialize.mockResolvedValue({isReady: vi.fn().mockReturnValue(true), teardown: vi.fn()})
      dispatchConsentEvent(true)

      await vi.waitFor(() => expect(mockInitialize).toHaveBeenCalledTimes(1))
      expect(window.CANVAS_COOKIE_CONSENT_STATE).toBe(true)
    })

    it('calls thePendo.initialize() when pendo exists but is not ready on consent re-grant', async () => {
      window.CANVAS_COOKIE_CONSENT_STATE = true
      const mockPendo = {isReady: vi.fn().mockReturnValue(false), initialize: vi.fn()}
      mockInitialize.mockResolvedValue(mockPendo)

      await initializePendo()

      dispatchConsentEvent(true)

      expect(mockPendo.initialize).toHaveBeenCalledWith(
        expect.objectContaining({apiKey: 'test-app-id'}),
      )
    })

    it('tears down pendo immediately when consent is revoked and pendo is ready', async () => {
      window.CANVAS_COOKIE_CONSENT_STATE = true
      const mockPendo = {isReady: vi.fn().mockReturnValue(true), teardown: vi.fn()}
      mockInitialize.mockResolvedValue(mockPendo)

      await initializePendo()

      dispatchConsentEvent(false)

      expect(window.CANVAS_COOKIE_CONSENT_STATE).toBe(false)
      expect(mockPendo.teardown).toHaveBeenCalledTimes(1)
    })

    it('defers teardown until initialization completes when consent is revoked mid-init', async () => {
      window.CANVAS_COOKIE_CONSENT_STATE = true

      let resolveInitialize!: (value: any) => void
      mockInitialize.mockReturnValue(
        new Promise(resolve => {
          resolveInitialize = resolve
        }),
      )

      const mockPendo = {isReady: vi.fn().mockReturnValue(true), teardown: vi.fn()}

      const pendingInit = initializePendo()

      // Revoke consent while initialization is still in flight
      dispatchConsentEvent(false)
      expect(mockPendo.teardown).not.toHaveBeenCalled()

      // Resolve initialization — teardown should now be queued and run
      resolveInitialize(mockPendo)
      await pendingInit

      expect(mockPendo.teardown).toHaveBeenCalledTimes(1)
    })
  })
})
