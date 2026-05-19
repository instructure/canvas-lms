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

import {useEffect, useRef, useState} from 'react'
import type {
  AuthProviderCard,
  AuthProviderCardDraft,
  DiscoverySection,
  UseCardEditingOptions,
  UseCardEditingReturn,
} from '../types'

export function useCardEditing({
  config,
  handleAddCard,
  handleUpdateCard,
  handleDeleteCard,
  setIsDirty,
}: UseCardEditingOptions): UseCardEditingReturn {
  const [editingCardId, setEditingCardId] = useState<string | null>(null)
  const [editingCardSnapshot, setEditingCardSnapshot] = useState<AuthProviderCard | null>(null)
  const [scrollToCardId, setScrollToCardId] = useState<string | null>(null)
  const cardRefs = useRef<Map<string, HTMLElement>>(new Map())

  useEffect(() => {
    if (!scrollToCardId) return
    cardRefs.current.get(scrollToCardId)?.scrollIntoView({behavior: 'smooth', block: 'nearest'})
    setScrollToCardId(null)
  }, [scrollToCardId])

  const handleAddAndEdit = (section: DiscoverySection) => {
    const newId = handleAddCard(section)
    const snapshot: AuthProviderCard = {
      id: newId,
      authentication_provider_id: null,
      label: '',
      icon: undefined,
    }
    setEditingCardId(newId)
    setEditingCardSnapshot(snapshot)
    setScrollToCardId(newId)
  }

  const handleEditStart = (section: DiscoverySection, cardId: string) => {
    const card = config.discovery_page[section].find(c => c.id === cardId)
    if (!card) return
    setEditingCardId(cardId)
    setEditingCardSnapshot({...card})
    setScrollToCardId(cardId)
  }

  const handleEditDone = (
    section: DiscoverySection,
    cardId: string,
    draft: AuthProviderCardDraft,
  ) => {
    handleUpdateCard(section, cardId, draft)
    setIsDirty(true)
    setEditingCardId(null)
    setEditingCardSnapshot(null)
  }

  const handleEditCancel = (section: DiscoverySection, cardId: string) => {
    const snapshot = editingCardSnapshot
    const isNewCard = snapshot?.authentication_provider_id === null && snapshot?.label === ''

    if (isNewCard) {
      handleDeleteCard(section, cardId)
    } else if (snapshot) {
      handleUpdateCard(section, cardId, snapshot)
    }

    setEditingCardId(null)
    setEditingCardSnapshot(null)
  }

  const resetEditing = () => {
    setEditingCardId(null)
    setEditingCardSnapshot(null)
  }

  return {
    editingCardId,
    isEditingAnyCard: editingCardId !== null,
    cardRefs,
    handleAddAndEdit,
    handleEditStart,
    handleEditDone,
    handleEditCancel,
    resetEditing,
  }
}
