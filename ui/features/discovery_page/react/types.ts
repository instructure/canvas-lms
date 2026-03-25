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
// api types (what the backend sends and receives)
// ---------------------------------------------------------------------------

export interface AuthProviderConfig {
  authentication_provider_id: number
  label: string
  icon?: string
}

export interface DiscoveryConfig {
  discovery_page: {
    primary: AuthProviderConfig[]
    secondary: AuthProviderConfig[]
  }
}

// ---------------------------------------------------------------------------
// internal ui types (used by components and hooks)
// ---------------------------------------------------------------------------

export interface AuthProviderCard extends AuthProviderConfig {
  id: string
}

export interface CardConfig {
  discovery_page: {
    primary: AuthProviderCard[]
    secondary: AuthProviderCard[]
  }
}

export interface DiscoveryContextType {
  modalOpen: boolean
  setModalOpen: (val: boolean) => void
  authProviders?: Array<{id: string; url: string; auth_type: string}>
  previewUrl?: string
}

export interface DiscoveryProviderProps {
  children: React.ReactNode
}

export interface DiscoveryPageProps {
  initialEnabled: boolean
  onChange: (enabled: boolean) => void
}

export interface ModalError {
  message: string
  code?: string
}

export interface DiscoveryPageIcon {
  id: string
  name: string
  url: string
}
