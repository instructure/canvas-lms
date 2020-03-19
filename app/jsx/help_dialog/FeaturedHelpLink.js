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
import {bool, shape, string, func} from 'prop-types'
import I18n from 'i18n!HelpLinks'
import {Link} from '@instructure/ui-link'
import {Text, Heading, Img} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import PandaMapSVGURL from '../../../public/images/panda-map.svg'

export default function FeaturedHelpLink({featuredLink, handleClick}) {
  if (featuredLink && window.ENV.FEATURES.featured_help_links) {
    return (
      <View textAlign="center" display="block">
        <Img alt={I18n.t('Cheerful panda holding a map')} src={PandaMapSVGURL} margin="small 0" />
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

FeaturedHelpLink.propTypes = {
  featuredLink: shape({
    url: string.isRequired,
    text: string.isRequired,
    subtext: string,
    feature_headline: string,
    is_featured: bool,
    is_new: bool
  }),
  handleClick: func
}

FeaturedHelpLink.defaultProps = {
  featuredLink: null,
  handleClick: () => {}
}
