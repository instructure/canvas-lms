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

import type {AuthProviderCard, AuthProviderConfig, CardConfig, DiscoveryConfig} from './types'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {htmlDecode} from '@canvas/util/TextHelper'

// ---------------------------------------------------------------------------
// converters: api <-> internal card format
// ---------------------------------------------------------------------------

export function toCardConfig(api: DiscoveryConfig): CardConfig {
  const toCard = (provider: AuthProviderConfig): AuthProviderCard => ({
    ...provider,
    label: htmlDecode(provider.label),
    id: crypto.randomUUID(),
  })

  return {
    discovery_page: {
      primary: api.discovery_page.primary.map(toCard),
      secondary: api.discovery_page.secondary.map(toCard),
      active: api.discovery_page.active,
    },
  }
}

export function toApiConfig(cards: CardConfig): DiscoveryConfig {
  const toProvider = (card: AuthProviderCard): AuthProviderConfig => ({
    authentication_provider_id: card.authentication_provider_id as number,
    label: card.label,
    ...(card.icon && {icon: card.icon}),
  })

  const validCards = (list: AuthProviderCard[]) =>
    list.filter(c => c.authentication_provider_id !== null).map(toProvider)

  return {
    discovery_page: {
      primary: validCards(cards.discovery_page.primary),
      secondary: validCards(cards.discovery_page.secondary),
      active: cards.discovery_page.active,
    },
  }
}

// ---------------------------------------------------------------------------
// api calls
// ---------------------------------------------------------------------------

export async function fetchDiscoveryConfig(): Promise<DiscoveryConfig> {
  const {json} = await doFetchApi<DiscoveryConfig>({
    path: '/api/v1/discovery_pages',
    method: 'GET',
  })

  if (!json) throw new Error('fetchDiscoveryConfig: response contained no JSON body')

  return json
}

export async function fetchPreviewToken(config: DiscoveryConfig): Promise<string> {
  const {json} = await doFetchApi<{token: string}>({
    path: '/api/v1/discovery_pages/token',
    method: 'POST',
    body: config,
  })

  return json?.token ?? ''
}

export async function saveDiscoveryConfig(config: DiscoveryConfig): Promise<DiscoveryConfig> {
  const {json} = await doFetchApi<DiscoveryConfig>({
    path: '/api/v1/discovery_pages',
    method: 'PUT',
    body: config,
  })

  if (!json) throw new Error('saveDiscoveryConfig: response contained no JSON body')

  return json
}
