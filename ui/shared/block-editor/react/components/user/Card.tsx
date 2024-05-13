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
import {TextBlock} from './blocks/TextBlock/TextBlock'
import {HeadingBlock} from './blocks/HeadingBlock/HeadingBlock'
import {ButtonBlock} from './blocks/ButtonBlock/ButtonBlock'
import {Element, useNode} from '@craftjs/core'

import {Container, type ContainerProps} from './blocks/Container/Container'

// Notice how CardTop and CardBottom do not specify the drag connector. This is because we won't be using these components as draggables; adding the drag handler would be pointless.

export const CardTop = ({children}) => {
  const {
    connectors: {connect},
  } = useNode()
  return (
    <div ref={ref => ref && connect(ref)} className="text-only">
      {children}
    </div>
  )
}

CardTop.craft = {
  displayName: 'Card Top',
  rules: {
    // Only accept Text
    canMoveIn: incomingNodes =>
      incomingNodes.every(
        incomingNode =>
          incomingNode.data.type === TextBlock || incomingNode.data.type === HeadingBlock
      ),
  },
}

export const CardBottom = ({children}) => {
  const {
    connectors: {connect},
  } = useNode()
  return <div ref={connect}>{children}</div>
}

CardBottom.craft = {
  displayName: 'Card Bottom',
  rules: {
    // Only accept Buttons
    canMoveIn: incomingNodes =>
      incomingNodes.every(incomingNode => incomingNode.data.type === ButtonBlock),
  },
}

export const Card = () => {
  const [bottomid] = useState<string>('bottom') // window.crypto.randomUUID())
  return (
    <Container>
      <Element id="text" is={CardTop} canvas={true}>
        <TextBlock text="Title" fontSize={20} />
        <TextBlock text="Subtitle" fontSize={15} />
      </Element>
      <Element id={bottomid} is={CardBottom} canvas={true}>
        <ButtonBlock size="small" variant="filled" color="success" text="Learn More" />
      </Element>
    </Container>
  )
}

Card.craft = {
  ...Container.craft,
  displayName: 'Card',
  custom: {
    isSection: true,
  },
}
