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

import {EnvCommon} from '@canvas/global/env/EnvCommon';
import {create} from 'zustand'

// See nav_menu_link.rb#as_existing_link_objects and #sync_with_link_objects
export type ExistingNavMenuLink = {type: 'existing'; label: string; id: string}
export type NewNavMenuLink = {type: 'new'; url: string; label: string}
export type NavMenuLink = ExistingNavMenuLink | NewNavMenuLink

declare const ENV: EnvCommon & {
  NAV_MENU_LINKS?: ExistingNavMenuLink[]
}

export interface NavMenuLinksState {
  links: NavMenuLink[]
  appendLink: (link: Omit<NewNavMenuLink, 'type'>) => void
  deleteLink: (index: number) => void
}

export const useNavMenuLinksStore = create<NavMenuLinksState>(set => {
  return {
    links: ENV.NAV_MENU_LINKS || [],

    appendLink: link => {
      const newLink: NewNavMenuLink = {...link, type: 'new'}
      set(state => ({links: [...state.links, newLink]}))
    },

    deleteLink: index => {
      set(state => {
        const newLinks = [...state.links]
        newLinks.splice(index, 1)
        return {links: newLinks}
      })
    },
  }
})
