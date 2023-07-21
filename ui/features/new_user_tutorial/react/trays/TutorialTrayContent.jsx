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
import PropTypes from 'prop-types'
import {Img} from '@instructure/ui-img'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {IconQuestionLine} from '@instructure/ui-icons'

import {TruncateText} from '@instructure/ui-truncate-text'

const TutorialTrayContent = props => (
  <div className={`NewUserTutorialTray__Content ${props.name}`}>
    <div>
      <Heading level="h3" margin="none none medium">
        <TruncateText>{props.heading}</TruncateText>
      </Heading>
      <Text size="large">{props.subheading}</Text>
      <View as="p" margin="small none none">
        {props.children}
      </View>
      {props.links && (
        <View
          as="div"
          borderWidth="small none none"
          padding="medium x-small"
          margin="medium none none"
        >
          {props.links.map((link, index) => {
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
      {props.seeAllLink && (
        <View as="div" padding="medium x-small" borderWidth="small none none">
          <Link href={props.seeAllLink.href} isWithinText={false} target="_blank">
            {props.seeAllLink.label}
          </Link>
        </View>
      )}
    </div>
    {props.image && (
      <Flex aria-hidden="true" height="100%" padding="none none x-small" justifyItems="center">
        <Flex.Item>
          <Img src={props.image} width={props.imageWidth} alt="" />
        </Flex.Item>
      </Flex>
    )}
  </div>
)

TutorialTrayContent.propTypes = {
  name: PropTypes.string.isRequired,
  heading: PropTypes.string.isRequired,
  subheading: PropTypes.string.isRequired,
  children: PropTypes.oneOfType([PropTypes.arrayOf(PropTypes.node), PropTypes.node]),
  image: PropTypes.string,
  imageWidth: PropTypes.string,
  links: PropTypes.array,
  seeAllLink: PropTypes.object,
}
TutorialTrayContent.defaultProps = {
  children: [],
  image: null,
  imageWidth: '7.5rem',
  name: '',
  links: undefined,
  seeAllLink: undefined,
}

export default TutorialTrayContent
