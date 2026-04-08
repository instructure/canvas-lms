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
import type {
  AuthProviderCard,
  DiscoverySection,
  MoveDirection,
  UseDiscoveryConfigOptions,
  UseDiscoveryConfigReturn,
} from '../types'

export function useDiscoveryConfig({
  initialConfig,
}: UseDiscoveryConfigOptions): UseDiscoveryConfigReturn {
  const [config, setConfig] = useState(initialConfig)
  const [isDirty, setIsDirty] = useState(false)

  const handleAddCard = (section: DiscoverySection): string => {
    const id = crypto.randomUUID()
    const newCard: AuthProviderCard = {
      id,
      authentication_provider_id: null,
      label: '',
      icon: undefined,
    }

    setConfig(prev => ({
      ...prev,
      discovery_page: {
        ...prev.discovery_page,
        [section]: [...prev.discovery_page[section], newCard],
      },
    }))

    return id
  }

  const handleUpdateCard = (
    section: DiscoverySection,
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
  }

  const handleDeleteCard = (section: DiscoverySection, cardId: string) => {
    setConfig(prev => ({
      ...prev,
      discovery_page: {
        ...prev.discovery_page,
        [section]: prev.discovery_page[section].filter(card => card.id !== cardId),
      },
    }))
  }

  const handleMoveCard = (section: DiscoverySection, cardId: string, direction: MoveDirection) => {
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
        otherCards.unshift(card)
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
      const cardToMove = cards[index]
      cards[index] = cards[newIndex]
      cards[newIndex] = cardToMove

      return {
        ...prev,
        discovery_page: {
          ...prev.discovery_page,
          [section]: cards,
        },
      }
    })
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
