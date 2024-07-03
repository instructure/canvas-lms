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
import {Element, type Node} from '@craftjs/core'
import {uid} from '@instructure/uid'
import {Container} from '../../blocks/Container'
import {NoSections} from '../../common'
import {HeadingBlock} from '../../blocks/HeadingBlock'
import {TextBlock} from '../../blocks/TextBlock'
import {ButtonBlock} from '../../blocks/ButtonBlock'
import {black} from '../../../../utils'
import {ImageBlock} from '../../blocks/ImageBlock'

type HeroTextHalfProps = {
  id?: string
  title?: string
  text?: string
  color?: string
  buttonText?: string
  buttonLink?: string
}

const HeroTextHalf = ({
  id,
  title = 'Welcome!',
  text = 'We offer a diverse range of courses, certifications, and degree programs tailored to meet the needs of learners from all walks of life. With our innovative approach to education, you can achieve your goals without compromising your commitments.<br/><br/><br/>',
  color = black,
  buttonText = 'Start Here',
  buttonLink = '#',
}: HeroTextHalfProps) => {
  return (
    <Container className="hero-section__text" id={id}>
      <Element id={`${id}__no-section`} is={NoSections} canvas={true} className="text-half__inner">
        <ImageBlock src="/images/block_editor/canvas_logo_black.svg" width={113} height={28} />
        <Element
          id={`${id}__title`}
          is={HeadingBlock}
          text={title}
          level="h2"
          custom={{
            displayName: 'Headline',
            themeOverride: {
              h2FontFamily:
                'Georgia, LatoWeb, Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
              h2FontSize: '4rem',
              h2FontWeight: 'bold',
              primaryColor: color,
            },
          }}
        />
        <Element
          id={`${id}__text`}
          is={TextBlock}
          text={text}
          textAlign="start"
          color={color}
          custom={{displayName: 'Details'}}
        />
        <Element
          id={`${id}__link`}
          is={ButtonBlock}
          href={buttonLink}
          text={buttonText}
          color="#85a9ff33"
        />
      </Element>
    </Container>
  )
}

HeroTextHalf.craft = {
  displayName: 'Hero Text',
  defaultProps: {
    id: uid('hero-text', 2),
  },
  rules: {
    isDeletable: () => {
      return false
    },
  },
  custom: {
    noToolbar: true,
  },
}

export {HeroTextHalf}
