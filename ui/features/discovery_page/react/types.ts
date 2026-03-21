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

// ---------------------------------------------------------------------------
// api types (what the back-end sends and receives)
// ---------------------------------------------------------------------------

export interface AuthProviderConfig {
  authentication_provider_id: number
  label: string
  icon?: string
}

export interface AuthProviderOption {
  id: string
  url: string
  auth_type: string
}

export interface DiscoveryConfig {
  discovery_page: {
    primary: AuthProviderConfig[]
    secondary: AuthProviderConfig[]
    active?: boolean
  }
}

// ---------------------------------------------------------------------------
// internal ui types (used by components and hooks)
// ---------------------------------------------------------------------------

export type DiscoverySection = 'primary' | 'secondary'

export type MoveDirection = 'up' | 'down'

export interface AuthProviderCard extends Omit<AuthProviderConfig, 'authentication_provider_id'> {
  id: string
  authentication_provider_id: number | null
}

export interface CardFormErrors {
  label?: string
  providerId?: string
}

export interface CardConfig {
  discovery_page: {
    primary: AuthProviderCard[]
    secondary: AuthProviderCard[]
    active?: boolean
  }
}

export interface AuthProviderCardDraft {
  label: string
  authentication_provider_id: number
  icon: string | undefined
}

export interface DiscoveryPageIcon {
  id: string
  name: string
  url: string
}

// ---------------------------------------------------------------------------
// component props
// ---------------------------------------------------------------------------

export interface DiscoveryPageProps {
  initialEnabled: boolean
  onChange: (enabled: boolean) => void
}

export interface AuthProviderProps {
  card: AuthProviderCard
  isEditing: boolean
  isDisabled: boolean
  authProviders?: AuthProviderOption[]
  authProviderUrl?: string
  elementRef?: (el: HTMLElement | null) => void
  onEditStart: () => void
  onEditDone: (draft: AuthProviderCardDraft) => void
  onEditCancel: () => void
  disableMoveUp?: boolean
  disableMoveDown?: boolean
  onDelete: () => void
  onMoveUp: () => void
  onMoveDown: () => void
}

export interface AuthProviderFormProps {
  authProviders?: AuthProviderOption[]
  loginLabel: string
  selectedProviderId: string
  onLoginChange: (value: string) => void
  onProviderChange: (value: string) => void
  selectedIconId: string
  onIconSelect: (iconId: string) => void
  errors?: CardFormErrors
  onLabelRef?: (el: HTMLInputElement | null) => void
  onProviderRef?: (el: HTMLSelectElement | null) => void
}

export interface AuthProviderHeaderProps {
  label: string
  iconUrl?: string
  providerUrl?: string
  isEditing: boolean
  isDisabled: boolean
  disableMoveUp?: boolean
  disableMoveDown?: boolean
  onEditStart: () => void
  onDelete: () => void
  onMoveUp: () => void
  onMoveDown: () => void
}

export interface ConfigureModalProps {
  open: boolean
  onClose: () => void
}

export interface ModalError {
  message: string
  code?: string
}

export interface LoadingSaveOverlayProps {
  isLoading: boolean
  isLoadingConfig: boolean
  mountNode: () => HTMLElement | null
}

export interface PreviewAndSidebarProps {
  previewUrl?: string
  children?: React.ReactNode
  iframeRef?: React.RefObject<HTMLIFrameElement>
}

export interface SignInOptionsHeaderProps {
  title: string
  description?: string
  onAddClick: () => void
  disabled?: boolean
}

// ---------------------------------------------------------------------------
// hook types
// ---------------------------------------------------------------------------

export interface UseCardEditingOptions {
  config: CardConfig
  handleAddCard: (section: DiscoverySection) => string
  handleUpdateCard: (
    section: DiscoverySection,
    cardId: string,
    updates: Partial<AuthProviderCard>,
  ) => void
  handleDeleteCard: (section: DiscoverySection, cardId: string) => void
  setIsDirty: (dirty: boolean) => void
}

export interface UseCardEditingReturn {
  editingCardId: string | null
  isEditingAnyCard: boolean
  cardRefs: React.RefObject<Map<string, HTMLElement>>
  handleAddAndEdit: (section: DiscoverySection) => void
  handleEditStart: (section: DiscoverySection, cardId: string) => void
  handleEditDone: (section: DiscoverySection, cardId: string, draft: AuthProviderCardDraft) => void
  handleEditCancel: (section: DiscoverySection, cardId: string) => void
  resetEditing: () => void
}

export interface UseDiscoveryConfigOptions {
  initialConfig: CardConfig
}

export interface UseDiscoveryConfigReturn {
  config: CardConfig
  setConfig: (config: CardConfig) => void
  isDirty: boolean
  setIsDirty: (dirty: boolean) => void
  handleAddCard: (section: DiscoverySection) => string
  handleUpdateCard: (
    section: DiscoverySection,
    cardId: string,
    updates: Partial<AuthProviderCard>,
  ) => void
  handleDeleteCard: (section: DiscoverySection, cardId: string) => void
  handleMoveCard: (section: DiscoverySection, cardId: string, direction: MoveDirection) => void
}

export interface UseIframeMessagingOptions {
  iframeRef: React.RefObject<HTMLIFrameElement>
  config: CardConfig
  previewUrl?: string
}
