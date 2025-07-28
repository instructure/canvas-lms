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

import React from 'react'
import {ResourcesSection} from '../components/user/sections/ResourcesSection'
import {HeroSection} from '../components/user/sections/HeroSection'
import {NavigationSection} from '../components/user/sections/NavigationSection'
import {AboutSection} from '../components/user/sections/AboutSection'
import {FooterSection} from '../components/user/sections/FooterSection'
import {KnowledgeCheckSection} from '../components/user/sections/KnowledgeCheckSection'
import {AnnouncementSection} from '../components/user/sections/AnnouncementSection'
import {ColumnsSection} from '../components/user/sections/ColumnsSection'

// import {type PageSection} from '../components/editor/NewPageStepper/types'

export const buildPageContent = (
  actions: any,
  query: any,
  selectedSections: any[],
  _paletteName: string,
  _fontName: string,
) => {
  if (selectedSections.length === 0) {
    selectedSections.push('blank')
  }
  selectedSections.forEach(section => {
    let nodeTree
    switch (section) {
      case 'navigation':
        nodeTree = query.parseReactElement(<NavigationSection />).toNodeTree()
        break
      case 'heroWithText':
        nodeTree = query.parseReactElement(<HeroSection />).toNodeTree()
        break
      case 'about':
        nodeTree = query.parseReactElement(<AboutSection />).toNodeTree()
        break
      case 'resources':
        nodeTree = query.parseReactElement(<ResourcesSection />).toNodeTree()
        break
      case 'footer':
        nodeTree = query.parseReactElement(<FooterSection />).toNodeTree()
        break
      case 'knowledgeCheck':
        // @ts-expect-error
        nodeTree = query.parseReactElement(<KnowledgeCheckSection />).toNodeTree()
        break
      case 'announcement':
        nodeTree = query.parseReactElement(<AnnouncementSection />).toNodeTree()
        break
      case 'blank':
        nodeTree = query.parseReactElement(<ColumnsSection columns={1} />).toNodeTree()
    }
    if (nodeTree) {
      actions.addNodeTree(nodeTree, 'ROOT')
    }
  })
}
