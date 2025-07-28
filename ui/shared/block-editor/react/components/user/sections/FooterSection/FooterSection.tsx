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
import {Element, useEditor, useNode} from '@craftjs/core'
import {Container} from '../../blocks/Container'
import {ButtonBlock} from '../../blocks/ButtonBlock'
import {ImageBlock} from '../../blocks/ImageBlock'
import {NoSections} from '../../common'

import {useClassNames, getContrastingColor, getContrastingButtonColor} from '../../../../utils'

type FooterSectionProps = {
  background?: string
}

const FooterSection = ({background}: FooterSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const {id} = useNode()
  const clazz = useClassNames(enabled, {empty: false}, ['section, footer-section'])

  const backgroundColor = background || FooterSection.craft.defaultProps.background
  const textColor = getContrastingColor(backgroundColor)
  const buttonColor = getContrastingButtonColor(textColor)

  return (
    <Container className={clazz} style={{color: textColor}} background={backgroundColor}>
      <Element
        id={`footer-no-section-${id}`}
        is={NoSections}
        canvas={true}
        className="footer-section__inner"
      >
        <Element
          id={`footer-canvas-icon-${id}`}
          is={ImageBlock}
          src="/images/block_editor/canvas_logo_white.svg"
          width={113}
          height={28}
        />
        <Element
          id={`footer-canvas-to-to-${id}`}
          is={ButtonBlock}
          text="Back to top"
          variant="text"
          background={buttonColor}
          iconName="arrow_up"
          href="#page-top"
        />
      </Element>
    </Container>
  )
}

FooterSection.craft = {
  displayName: 'Footer',
  defaultProps: {
    background: '#1A2729',
  },
  custom: {
    isSection: true,
  },
}

export {FooterSection}
