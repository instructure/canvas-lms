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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {AuthProviderCard, CardConfig} from '../types'
import {DISCOVERY_PAGE_ICONS} from '../constants'

const I18n = createI18nScope('discovery_page')

export function backfillLabels(cards: CardConfig): CardConfig {
  return {
    discovery_page: {
      primary: cards.discovery_page.primary.map(c => ({
        ...c,
        label: c.label.trim() || I18n.t('User login'),
      })),
      secondary: cards.discovery_page.secondary.map(c => ({
        ...c,
        label: c.label.trim() || I18n.t('User login'),
      })),
    },
  }
}

interface UseDiscoveryConfigOptions {
  initialConfig: CardConfig
  authProviders?: Array<{id: string; url: string; auth_type: string}>
}

interface UseDiscoveryConfigReturn {
  config: CardConfig
  setConfig: (config: CardConfig) => void
  isDirty: boolean
  setIsDirty: (dirty: boolean) => void
  handleAddCard: (section: 'primary' | 'secondary') => void
  handleUpdateCard: (
    section: 'primary' | 'secondary',
    cardId: string,
    updates: Partial<AuthProviderCard>,
  ) => void
  handleDeleteCard: (section: 'primary' | 'secondary', cardId: string) => void
  handleMoveCard: (
    section: 'primary' | 'secondary',
    cardId: string,
    direction: 'up' | 'down',
  ) => void
}

export function useDiscoveryConfig({
  initialConfig,
  authProviders,
}: UseDiscoveryConfigOptions): UseDiscoveryConfigReturn {
  const [config, setConfig] = useState(initialConfig)
  const [isDirty, setIsDirty] = useState(false)

  const handleAddCard = (section: 'primary' | 'secondary') => {
    const id = crypto.randomUUID()
    const defaultIcon = DISCOVERY_PAGE_ICONS.find(icon => icon.id === 'default')
    const defaultProviderId = authProviders?.[0] ? Number(authProviders[0].id) : 0
    const newCard: AuthProviderCard = {
      id,
      authentication_provider_id: defaultProviderId,
      label: I18n.t('User login'),
      icon: defaultIcon?.id || 'default',
    }
    setConfig(prev => ({
      ...prev,
      discovery_page: {
        ...prev.discovery_page,
        [section]: [...prev.discovery_page[section], newCard],
      },
    }))
    setIsDirty(true)
  }

  const handleUpdateCard = (
    section: 'primary' | 'secondary',
    cardId: string,
    updates: Partial<AuthProviderCard>,
  ) => {
    setConfig(prev => ({
      ...prev,
      discovery_page: {
        ...prev.discovery_page,
        [section]: prev.discovery_page[section].map(card =>
          card.id === cardId ? {...card, ...updates} : card,
        ),
      },
    }))
    setIsDirty(true)
  }

  const handleDeleteCard = (section: 'primary' | 'secondary', cardId: string) => {
    setConfig(prev => ({
      ...prev,
      discovery_page: {
        ...prev.discovery_page,
        [section]: prev.discovery_page[section].filter(card => card.id !== cardId),
      },
    }))
    setIsDirty(true)
  }

  const handleMoveCard = (
    section: 'primary' | 'secondary',
    cardId: string,
    direction: 'up' | 'down',
  ) => {
    setConfig(prev => {
      const cards = [...prev.discovery_page[section]]
      const index = cards.findIndex(card => card.id === cardId)
      if (index === -1) return prev

      const otherSection = section === 'primary' ? 'secondary' : 'primary'

      if (direction === 'up' && index === 0) {
        const otherCards = [...prev.discovery_page[otherSection]]
        const [card] = cards.splice(index, 1)
        otherCards.push(card)
        return {
          ...prev,
          discovery_page: {
            ...prev.discovery_page,
            [section]: cards,
            [otherSection]: otherCards,
          },
        }
      }

      if (direction === 'down' && index === cards.length - 1) {
        const otherCards = [...prev.discovery_page[otherSection]]
        const [card] = cards.splice(index, 1)
        otherCards.push(card)
        return {
          ...prev,
          discovery_page: {
            ...prev.discovery_page,
            [section]: cards,
            [otherSection]: otherCards,
          },
        }
      }

      const newIndex = direction === 'up' ? index - 1 : index + 1
      ;[cards[index], cards[newIndex]] = [cards[newIndex], cards[index]]
      return {
        ...prev,
        discovery_page: {
          ...prev.discovery_page,
          [section]: cards,
        },
      }
    })
    setIsDirty(true)
  }

  return {
    config,
    setConfig,
    isDirty,
    setIsDirty,
    handleAddCard,
    handleUpdateCard,
    handleDeleteCard,
    handleMoveCard,
  }
}
