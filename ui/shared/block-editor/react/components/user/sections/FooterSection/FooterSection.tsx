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
import {Element, useEditor} from '@craftjs/core'

import {contrast} from '@instructure/ui-color-utils'

import {Container} from '../../blocks/Container'
import {ButtonBlock} from '../../blocks/ButtonBlock'
import {SVGImageBlock} from '../../blocks/SVGImageBlock'
import canvas_logo from '../../../../assets/logos/canvas_logo_left'
import {NoSections} from '../ColumnsSection'

import {useClassNames, white, black} from '../../../../utils'

type FooterSectionProps = {
  background?: string
}

const FooterSection = ({background}: FooterSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [cid] = useState<string>('hero-section')
  const clazz = useClassNames(enabled, {isEmpty: false, isSelected: false, isHovered: false}, [
    'footer-section',
  ])

  const backgroundColor = background || FooterSection.craft.defaultProps.background
  const textColor =
    contrast(backgroundColor, white) > contrast(backgroundColor, black) ? white : black
  const buttonColor = textColor === white ? 'primary-inverse' : 'secondary'

  return (
    <Container className={clazz} style={{color: textColor}} background={backgroundColor}>
      <Element
        id={`${cid}__footer-no-section`}
        is={NoSections}
        canvas={true}
        variant="fixed"
        className="footer-section__inner"
      >
        <SVGImageBlock src={canvas_logo} color={textColor} />
        <ButtonBlock
          text="Back to top"
          variant="condensed"
          color={buttonColor}
          iconName="arrow_up"
          iconSize="x-small"
          href="#page-top"
        />
      </Element>
    </Container>
  )
}

FooterSection.craft = {
  displayName: 'Footer',
  custom: {
    isSection: true,
  },
  defaultProps: {
    background: '#1A2729',
  },
}

export {FooterSection}
