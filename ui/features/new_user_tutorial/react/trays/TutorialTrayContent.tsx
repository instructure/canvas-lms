/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {Img} from '@instructure/ui-img'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {IconQuestionLine} from '@instructure/ui-icons'

import {TruncateText} from '@instructure/ui-truncate-text'

interface TutorialLink {
  href: string
  label: string
}

interface TutorialTrayContentProps {
  name?: string
  heading: string
  subheading: string
  children?: React.ReactNode
  image?: string | null
  imageWidth?: string
  links?: TutorialLink[]
  seeAllLink?: TutorialLink
}

const TutorialTrayContent: React.FC<TutorialTrayContentProps> = ({
  name = '',
  heading,
  subheading,
  children = [],
  image = null,
  imageWidth = '7.5rem',
  links,
  seeAllLink,
}) => (
  <div className={`NewUserTutorialTray__Content ${name}`}>
    <div>
      <Heading level="h3" margin="none none medium">
        <TruncateText>{heading}</TruncateText>
      </Heading>
      <Text size="large">{subheading}</Text>
      <View as="p" margin="small none none">
        {children}
      </View>
      {links && (
        <View
          as="div"
          borderWidth="small none none"
          padding="medium x-small"
          margin="medium none none"
        >
          {links.map((link, index) => {
            return (
              <Flex
                key={link.href}
                margin={index === 0 ? 'none' : 'x-small none none'}
                alignItems="start"
              >
                <Flex.Item padding="xxx-small small none none">
                  <IconQuestionLine inline={false} size="x-small" />
                </Flex.Item>
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Link href={link.href} isWithinText={false} display="block" target="_blank">
                    {link.label}
                  </Link>
                </Flex.Item>
              </Flex>
            )
          })}
        </View>
      )}
      {seeAllLink && (
        <View as="div" padding="medium x-small" borderWidth="small none none">
          <Link href={seeAllLink.href} isWithinText={false} target="_blank">
            {seeAllLink.label}
          </Link>
        </View>
      )}
    </div>
    {image && (
      <Flex aria-hidden="true" height="100%" padding="none none x-small" justifyItems="center">
        <Flex.Item>
          <Img src={image} width={imageWidth} alt="" />
        </Flex.Item>
      </Flex>
    )}
  </div>
)

export default TutorialTrayContent
