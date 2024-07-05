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

import React, {useState} from 'react'
import {Element, useNode, type Node} from '@craftjs/core'
import {uid} from '@instructure/uid'

import {Container} from '../../blocks/Container'
import {ResourceCard} from '../../blocks/ResourceCard'
import {SectionMenu} from '../../../editor/SectionMenu'
import {SectionToolbar} from '../../common/SectionToolbar'

type ResourcesSectionInnerProps = {
  children: React.ReactNode
}

const ResourcesSectionInner = ({children}: ResourcesSectionInnerProps) => {
  const {
    connectors: {connect},
  } = useNode()

  return (
    <div ref={ref => ref && connect(ref)} className="resources-section__inner">
      {children}
    </div>
  )
}

// TODO: I don't understand yet why I can't get ResouresSection.craft.rules functions called
// directly from craft. I had to create this inner object for it towork.
ResourcesSectionInner.craft = {
  rules: {
    canMoveIn: (incomingNodes: Node[]) => {
      return incomingNodes.every(incomingNode => incomingNode.data.type === ResourceCard)
    },
    canMoveOut: (outgoingNodes: Node[], currentNode: Node) => {
      return currentNode.data.nodes.length > outgoingNodes.length
    },
  },
  custom: {
    noToolbar: true,
  },
}

type ResourcesSectionProps = {
  background?: string
}

const ResourcesSection = ({background}: ResourcesSectionProps) => {
  const [myId] = useState('resources') // id || uid('resources', 2))
  const [card1Id] = useState(uid('resources__resource-card', 2))
  const [card2Id] = useState(uid('resources__resource-card', 2))
  const [card3Id] = useState(uid('resources__resource-card', 2))

  const backgroundColor = background || ResourcesSection.craft.defaultProps.background

  return (
    <Container
      id={myId}
      className="section resources-section"
      background={backgroundColor}
      style={{marginBlockEnd: '0.5rem'}}
    >
      <Element id={`${myId}__inner`} is={ResourcesSectionInner} canvas={true}>
        <Element
          id={card1Id}
          is={ResourceCard}
          iconName="calendar"
          title="Reading Checklist"
          description="Weekly reading materials can be found here."
          linkText="Jump to List"
        />
        <Element
          id={card2Id}
          is={ResourceCard}
          iconName="glasses"
          title="Study Groups"
          description="Join a group to ensure your success in the course."
          linkText="Go to Groups"
        />
        <Element
          id={card3Id}
          is={ResourceCard}
          iconName="communiction"
          title="Resources"
          description="See tutoring schedule and contact information."
          linkText="View Resources"
        />
      </Element>
    </Container>
  )
}

ResourcesSection.craft = {
  displayName: 'Highlights or services',
  defaultProps: {
    background: '#CEF5EA',
  },
  custom: {
    isSection: true,
  },
  related: {
    sectionMenu: SectionMenu,
    toolbar: SectionToolbar,
  },
}

export {ResourcesSection, ResourcesSectionInner}
