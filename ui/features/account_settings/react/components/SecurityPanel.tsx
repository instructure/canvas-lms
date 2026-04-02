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

import React, {useReducer, useEffect, useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Grid} from '@instructure/ui-grid'
import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {Alert} from '@instructure/ui-alerts'
import {showFlashError} from '@instructure/platform-alerts'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Whitelist} from './Whitelist'

const I18n = createI18nScope('security_panel')

export interface AssociatedTool {
  id: string
  name: string
  account_id: string
}

export interface WhitelistedDomains {
  account: string[]
  effective: string[]
  inherited: string[]
  tools: Record<string, AssociatedTool[]>
}

interface CspSettingsResponse {
  enabled: boolean
  inherited: boolean
  effective_whitelist?: string[]
  current_account_whitelist?: string[]
  tools_whitelist?: Record<string, AssociatedTool[]>
}

export interface SecurityPanelProps {
  context: 'course' | 'account'
  contextId: string
  isSubAccount?: boolean
  maxDomains?: number
  initialCspSettings?: {
    enabled: boolean
    inherited: boolean
  }
}

interface CspState {
  loadStatus: 'loading' | 'loaded' | 'error'
  cspEnabled: boolean
  cspInherited: boolean
  isDirty: boolean
  whitelistedDomains: WhitelistedDomains
}

type CspAction =
  | {type: 'FETCH_SUCCESS'; enabled: boolean; inherited: boolean; domains: WhitelistedDomains}
  | {type: 'FETCH_ERROR'}
  | {type: 'SET_ENABLED'; enabled: boolean}
  | {type: 'SET_INHERITED'; inherited: boolean}
  | {
      type: 'INHERIT_SUCCESS'
      enabled: boolean
      inherited: boolean
      domains: WhitelistedDomains
      shouldReset: boolean
      markDirty: boolean
    }
  | {type: 'SET_ACCOUNT_DOMAINS'; domains: string[]}
  | {type: 'SET_DIRTY'; dirty: boolean}

function cspReducer(state: CspState, action: CspAction): CspState {
  switch (action.type) {
    case 'FETCH_SUCCESS':
      return {
        ...state,
        loadStatus: 'loaded',
        cspEnabled: action.enabled,
        cspInherited: action.inherited,
        whitelistedDomains: action.domains,
      }
    case 'FETCH_ERROR':
      return {...state, loadStatus: 'error'}
    case 'SET_ENABLED':
      return {...state, cspEnabled: action.enabled}
    case 'SET_INHERITED':
      return {...state, cspInherited: action.inherited}
    case 'INHERIT_SUCCESS': {
      let whitelistedDomains: WhitelistedDomains
      if (action.shouldReset) {
        whitelistedDomains = action.domains
      } else {
        const prev = state.whitelistedDomains
        whitelistedDomains = {
          account: Array.from(new Set([...prev.account, ...action.domains.account])),
          effective: Array.from(new Set([...prev.effective, ...action.domains.effective])),
          tools: {...prev.tools, ...action.domains.tools},
          inherited: action.domains.inherited,
        }
      }
      return {
        ...state,
        cspEnabled: action.enabled,
        cspInherited: action.inherited,
        whitelistedDomains,
        isDirty: action.markDirty ? true : state.isDirty,
      }
    }
    case 'SET_ACCOUNT_DOMAINS':
      return {
        ...state,
        whitelistedDomains: {
          ...state.whitelistedDomains,
          account: action.domains,
        },
      }
    case 'SET_DIRTY':
      return {...state, isDirty: action.dirty}
    default:
      return state
  }
}

function getInheritedList(
  toolsWhitelist: Record<string, AssociatedTool[]>,
  effectiveWhitelist: string[],
): string[] {
  const toolsKeys = Object.keys(toolsWhitelist)
  return effectiveWhitelist.filter(domain => !toolsKeys.includes(domain))
}

export function SecurityPanel({
  context,
  contextId,
  isSubAccount = false,
  maxDomains = 50,
  initialCspSettings,
}: SecurityPanelProps) {
  const [state, dispatch] = useReducer(cspReducer, {
    loadStatus: 'loading',
    cspEnabled: initialCspSettings?.enabled ?? false,
    cspInherited: initialCspSettings?.inherited ?? false,
    isDirty: false,
    whitelistedDomains: {
      account: [],
      effective: [],
      inherited: [],
      tools: {},
    },
  })

  // Fetch CSP settings on mount
  useEffect(() => {
    const fetchSettings = async () => {
      const path = `/api/v1/${context}s/${contextId}/csp_settings`
      try {
        const {json} = await doFetchApi<CspSettingsResponse>({path})
        const effective = json?.effective_whitelist || []
        const account = json?.current_account_whitelist || []
        const tools = json?.tools_whitelist || {}
        const inherited = getInheritedList(tools, effective)

        dispatch({
          type: 'FETCH_SUCCESS',
          enabled: json!.enabled,
          inherited:
            isSubAccount && json?.inherited !== undefined ? json.inherited : state.cspInherited,
          domains: {effective, account, tools, inherited},
        })
      } catch {
        dispatch({type: 'FETCH_ERROR'})
      }
    }
    fetchSettings()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [context, contextId, isSubAccount])

  const handleCspToggleChange = useCallback(
    async (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.currentTarget.checked
      const status = value ? 'enabled' : 'disabled'
      const path = `/api/v1/${context}s/${contextId}/csp_settings`
      try {
        const {json} = await doFetchApi<CspSettingsResponse>({
          path,
          method: 'PUT',
          body: {status},
        })
        dispatch({type: 'SET_ENABLED', enabled: json!.enabled})
      } catch {
        showFlashError(I18n.t('Failed to update Content Security Policy'))()
      }
    },
    [context, contextId],
  )

  const handleCspInheritChange = useCallback(
    async (e: React.ChangeEvent<HTMLInputElement>) => {
      const value = e.currentTarget.checked
      const path = `/api/v1/${context}s/${contextId}/csp_settings`
      try {
        const {json} = await doFetchApi<CspSettingsResponse>({
          path,
          method: 'PUT',
          body: {status: value ? 'inherited' : state.cspEnabled ? 'enabled' : 'disabled'},
        })

        const effective = json?.effective_whitelist || []
        const account = json?.current_account_whitelist || []
        const tools = json?.tools_whitelist || {}
        const inherited = getInheritedList(tools, effective)
        const shouldReset = !state.cspInherited && value

        dispatch({
          type: 'INHERIT_SUCCESS',
          enabled: json!.enabled,
          inherited: json!.inherited,
          domains: {effective, account, tools, inherited},
          shouldReset,
          markDirty: state.cspInherited && !value && account.length === 0,
        })
      } catch {
        showFlashError(I18n.t('Failed to update Content Security Policy inheritance'))()
      }
    },
    [context, contextId, state.cspEnabled, state.cspInherited],
  )

  const copyInheritedIfNeeded = useCallback(
    async (modifiedDomainOption: {add?: string; delete?: string} = {}) => {
      if (!state.isDirty) return

      dispatch({type: 'SET_DIRTY', dirty: false})
      let domains = [...state.whitelistedDomains.inherited]
      if (modifiedDomainOption.add) domains.push(modifiedDomainOption.add)
      if (modifiedDomainOption.delete)
        domains = domains.filter(d => d !== modifiedDomainOption.delete)

      const path = `/api/v1/${context}s/${contextId}/csp_settings/domains/batch_create`
      try {
        const {json} = await doFetchApi<CspSettingsResponse>({
          path,
          method: 'POST',
          body: {domains},
        })
        dispatch({type: 'SET_ACCOUNT_DOMAINS', domains: json!.current_account_whitelist!})
      } catch {
        dispatch({type: 'SET_DIRTY', dirty: true})
        showFlashError(I18n.t('Failed to copy inherited domains'))()
      }
    },
    [state.isDirty, state.whitelistedDomains.inherited, context, contextId],
  )

  const handleAddDomain = useCallback(
    async (domain: string) => {
      const path = `/api/v1/${context}s/${contextId}/csp_settings/domains`
      try {
        const {json} = await doFetchApi<CspSettingsResponse>({
          path,
          method: 'POST',
          body: {domain},
        })
        dispatch({type: 'SET_ACCOUNT_DOMAINS', domains: json!.current_account_whitelist!})
        await copyInheritedIfNeeded({add: domain})
      } catch {
        showFlashError(I18n.t('Failed to add to allowed domains'))()
      }
    },
    [context, contextId, copyInheritedIfNeeded],
  )

  const handleRemoveDomain = useCallback(
    async (domain: string) => {
      const path = `/api/v1/${context}s/${contextId}/csp_settings/domains`
      try {
        const {json} = await doFetchApi<CspSettingsResponse>({
          path,
          method: 'DELETE',
          params: {domain},
        })
        dispatch({type: 'SET_ACCOUNT_DOMAINS', domains: json!.current_account_whitelist!})
        await copyInheritedIfNeeded({delete: domain})
      } catch {
        showFlashError(I18n.t('Failed to remove from allowed domains'))()
      }
    },
    [context, contextId, copyInheritedIfNeeded],
  )

  if (state.loadStatus === 'error') {
    return (
      <View as="div" margin="large" textAlign="center">
        <Alert variant="error">{I18n.t('Failed to load Content Security Policy settings')}</Alert>
      </View>
    )
  }

  if (state.loadStatus === 'loading') {
    return (
      <View as="div" margin="large" textAlign="center">
        <Spinner size="large" renderTitle={I18n.t('Loading')} />
      </View>
    )
  }

  return (
    <div>
      <Heading margin="small 0" level="h3" as="h2" border="bottom">
        {I18n.t('Canvas Content Security Policy')}
      </Heading>
      <View as="div" margin="small 0">
        <Text as="p">
          {I18n.t(
            `The Content Security Policy allows you to restrict custom
             JavaScript that runs in your instance of Canvas. You can manually add
             up to %{max_domains} allowed domains. Wild cards are recommended
             (e.g. *.instructure.com). Canvas and Instructure domains are included
             automatically and do not count against your %{max_domains} domain limit.`,
            {
              max_domains: maxDomains,
            },
          )}
        </Text>
      </View>
      <Grid>
        <Grid.Row>
          <Grid.Col>
            {isSubAccount && (
              <View margin="0 xx-small">
                <Checkbox
                  variant="toggle"
                  label={I18n.t('Inherit Content Security Policy')}
                  onChange={handleCspInheritChange}
                  checked={state.cspInherited}
                />
              </View>
            )}
            <Checkbox
              variant="toggle"
              label={I18n.t('Enable Content Security Policy')}
              onChange={handleCspToggleChange}
              checked={state.cspEnabled}
              disabled={state.cspInherited && isSubAccount}
            />
          </Grid.Col>
        </Grid.Row>
        <Grid.Row>
          <Grid.Col>
            <Whitelist
              isSubAccount={isSubAccount}
              inherited={state.cspInherited}
              maxDomains={maxDomains}
              whitelistedDomains={state.whitelistedDomains}
              onAddDomain={handleAddDomain}
              onRemoveDomain={handleRemoveDomain}
            />
          </Grid.Col>
        </Grid.Row>
      </Grid>
    </div>
  )
}
