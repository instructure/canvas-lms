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

export type Product = {
  id: string
  name: string
  company: Company
  logo_url: string
  tagline: string
  description: string
  updatedAt?: string
  toolType?: string
  demographic?: string
  lti?: Lti
  countries?: string[]
  badges: Badges[]
}

export type Company = {
  id: string
  name: string
  company_url?: string
}

export type Lti = {
  versions: string[]
  title: string[]
}

export type Badges = {
  name: string
  image_url: string
  badge_url: string
}
