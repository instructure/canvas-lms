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
import {Element} from '@craftjs/core'
import {uid} from '@instructure/uid'
import {Container} from '../../blocks/Container'
import {NoSections} from '../../common'
import {HeadingBlock} from '../../blocks/HeadingBlock'
import {TextBlock} from '../../blocks/TextBlock'
import {black} from '../../../../utils'

type AboutTextHalfProps = {
  id?: string
  title?: string
  text?: string
  color?: string
}

const AboutTextHalf = ({
  id,
  title = 'About Your Pathway to Career Success',
  text = "Hello and welcome! We understand that a successful career starts with the right education. Our mission is to provide you with the tools, knowledge, and confidence to excel in your chosen field and achieve your professional goals. Our course is designed with your career in mind. We focus on the skills and knowledge that are most in-demand in today's job market, ensuring that what you learn is directly applicable to your professional aspirations.",
  color = black,
}: AboutTextHalfProps) => {
  return (
    <Container className="about-section__text" id={id}>
      <Element id={`${id}__no-section`} is={NoSections} canvas={true} className="text-half__inner">
        <Element
          id={`${id}__title`}
          is={HeadingBlock}
          text={title}
          level="h2"
          custom={{
            themeOverride: {
              h2FontFamily:
                'Georgia, LatoWeb, Lato, "Helvetica Neue", Helvetica, Arial, sans-serif',
              h2FontWeight: 'bold',
              h2FontSize: '1.25rem',
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
          custom={{displayName: 'About Text'}}
        />
      </Element>
    </Container>
  )
}

AboutTextHalf.craft = {
  displayName: 'About Text',
  defaultProps: {
    id: uid('about-text', 2),
  },
  rules: {
    isDeletable: () => {
      return false
    },
  },
}

export {AboutTextHalf}
