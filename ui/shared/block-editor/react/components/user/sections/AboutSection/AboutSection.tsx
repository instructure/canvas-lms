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

import {Container} from '../../blocks/Container'
import {AboutTextHalf} from './AboutTextHalf'
import {ImageBlock} from '../../blocks/ImageBlock'
import {NoSections} from '../../common'
import {useClassNames, getContrastingColor} from '../../../../utils'
import {SectionMenu} from '../../../editor/SectionMenu'
import {SectionToolbar} from '../../common/SectionToolbar'

type AboutSectionProps = {
  background?: string
}

export const AboutSection = ({background}: AboutSectionProps) => {
  const {enabled} = useEditor(state => ({
    enabled: state.options.enabled,
  }))
  const [cid] = useState<string>('about-section')
  const clazz = useClassNames(enabled, {empty: false}, [
    'section',
    'columns-section',
    'about-section',
    'fixed',
    'columns-2',
  ])

  const backgroundColor = background || AboutSection.craft.defaultProps.background
  const textColor = getContrastingColor(backgroundColor)

  // TODO: the layout here is inadequate. The AboutTextHalf needs to be different to the user
  //       can drop components anywhere they want. As it is, the flexbox layout
  //       messes with what the user might want to do.
  // Or maybe we don't want to let the user drop any new things in here and just edit
  // what's already there.
  return (
    <Container className={clazz} background={backgroundColor}>
      <Element
        id={`${cid}_about-nosection1`}
        is={NoSections}
        canvas={true}
        className="about-section__inner-end"
      >
        <Element
          id={`${cid}_image`}
          is={ImageBlock}
          constraint="contain"
          src="/images/block_editor/default_about_image.svg"
        />
      </Element>
      <Element
        id={`${cid}_about-no-section2`}
        is={NoSections}
        canvas={true}
        className="about-section__inner-start"
      >
        <Element id={`${cid}_text`} is={AboutTextHalf} color={textColor} />
      </Element>
    </Container>
  )
}

AboutSection.craft = {
  displayName: 'About',
  defaultProps: {
    background: '#E5E9F3',
  },
  custom: {
    isSection: true,
  },
  related: {
    sectionMenu: SectionMenu,
    toolbar: SectionToolbar,
  },
}
