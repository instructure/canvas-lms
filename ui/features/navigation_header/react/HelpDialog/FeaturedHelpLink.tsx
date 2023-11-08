/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {Link} from '@instructure/ui-link'
import {Img} from '@instructure/ui-img'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
// @ts-expect-error
import PandaMapSVGURL from '../../images/panda-map.svg'
import type {HelpLink} from '../../../../api.d'

type Props = {
  featuredLink: HelpLink
  handleClick: (link: HelpLink) => (event: React.MouseEvent<unknown, MouseEvent>) => void
}

export default function FeaturedHelpLink({featuredLink, handleClick}: Props) {
  if (featuredLink && window.ENV.FEATURES.featured_help_links) {
    return (
      <View textAlign="center" display="block">
        <Img data-testid="cheerful-panda-svg" src={PandaMapSVGURL} margin="small 0" />
        {featuredLink.feature_headline && (
          <Heading level="h3">{featuredLink.feature_headline}</Heading>
        )}
        <View display="block" margin="small 0">
          <Link
            isWithinText={false}
            href={featuredLink.url}
            target="_blank"
            rel="noopener"
            onClick={handleClick(featuredLink)}
          >
            <Text size="large">{featuredLink.text}</Text>
          </Link>
          {featuredLink.subtext && (
            <Text as="div" size="small">
              {featuredLink.subtext}
            </Text>
          )}
        </View>
      </View>
    )
  }
  return null
}

FeaturedHelpLink.defaultProps = {
  featuredLink: null,
  handleClick: () => {},
}
