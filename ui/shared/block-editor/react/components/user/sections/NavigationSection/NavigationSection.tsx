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
import {Element, useEditor, useNode, type Node} from '@craftjs/core'
import {Container} from '../../blocks/Container'
import {ButtonBlock} from '../../blocks/ButtonBlock'
import {useClassNames, getContrastingColor} from '../../../../utils'
import {SectionMenu} from '../../../editor/SectionMenu'
import {SectionToolbar} from '../../common/SectionToolbar'

export type NavigationSectionInnerProps = {
  children?: React.ReactNode
}

export const NavigationSectionInner = ({children}: NavigationSectionInnerProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {
    connectors: {connect},
  } = useNode()
  const clazz = useClassNames(enabled, {empty: !children}, ['navigation-section__inner'])

  return (
    <div ref={el => el && connect(el)} className={clazz} data-placeholder="Drop buttons here">
      {children}
    </div>
  )
}

NavigationSectionInner.craft = {
  displayName: 'Navigation',
  rules: {
    canMoveIn: (incomingNodes: Node[]) =>
      incomingNodes.every(incomingNode => incomingNode.data.type === ButtonBlock),
    canMoveOut: (outgoingNodes: Node[], currentNode: Node) => {
      return currentNode.data.nodes.length > outgoingNodes.length
    },
  },
  custom: {
    noToolbar: true,
  },
}

type NavigationSectionProps = {
  background?: string
}

const NavigationSection = ({background}: NavigationSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [cid] = useState<string>('navigation-section')
  const clazz = useClassNames(enabled, {empty: false}, ['section', 'navigation-section', 'fixed'])

  const backgroundColor = background || NavigationSection.craft.defaultProps.background
  const textColor = getContrastingColor(backgroundColor)

  return (
    <Container className={clazz} background={backgroundColor} style={{color: textColor}}>
      <Element id={`${cid}__inner`} is={NavigationSectionInner} canvas={true}>
        <Element
          id={`${cid}_link1`}
          is={ButtonBlock}
          text="Announcements"
          iconName="announcement"
          variant="condensed"
          color="primary-inverse"
          href="../announcements"
          custom={{themeOverride: {fontWeight: 'bold'}}}
        />
        <Element
          id={`${cid}_link2`}
          is={ButtonBlock}
          text="Virtual Classroom"
          iconName="video"
          variant="condensed"
          color="primary-inverse"
        />
        <Element
          id={`${cid}_link3`}
          is={ButtonBlock}
          text="Modules"
          iconName="module"
          variant="condensed"
          color="primary-inverse"
          href="../modules"
        />
        <Element
          id={`${cid}_link4`}
          is={ButtonBlock}
          text="Grades"
          iconName="gradebook"
          variant="condensed"
          color="primary-inverse"
          href="../grades"
        />
      </Element>
    </Container>
  )
}

NavigationSection.craft = {
  displayName: 'Navigation',
  defaultProps: {
    background: '#334870',
  },
  custom: {
    isSection: true,
  },
  related: {
    sectionMenu: SectionMenu,
    toolbar: SectionToolbar,
  },
}

export {NavigationSection}
