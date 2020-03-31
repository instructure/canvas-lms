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
import {bool, arrayOf, shape, string, func} from 'prop-types'
import I18n from 'i18n!HelpLinks'
import {Link} from '@instructure/ui-link'
import {List, Spinner, Text, Pill} from '@instructure/ui-elements'
import FeaturedHelpLink from './FeaturedHelpLink'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y'
import tourPubSub from '../nav_tourpoints/tourPubsub'

export default function HelpLinks({links, hasLoaded, onClick}) {
  const featuredLink = links.find(link => link.is_featured)
  const featuredLinksEnabled = window.ENV.FEATURES.featured_help_links
  const nonFeaturedLinks = featuredLinksEnabled ? links.filter(link => !link.is_featured) : links
  const showSeparator = featuredLink && !!nonFeaturedLinks.length && featuredLinksEnabled

  const handleClick = link => event => {
    if (link.url === '#create_ticket' || link.url === '#teacher_feedback') {
      event.preventDefault()
      onClick(link.url)
    }
  }

  return !hasLoaded ? (
    <Spinner size="small" renderTitle={I18n.t('Loading')} />
  ) : (
    <View>
      <FeaturedHelpLink featuredLink={featuredLink} handleClick={handleClick} />
      {showSeparator && (
        <View display="block" margin="medium 0 0">
          <Text weight="bold" transform="uppercase" size="small" lineHeight="double">
            {I18n.t('OTHER RESOURCES')}
          </Text>
          <hr role="presentation" style={{marginTop: '0'}} />
        </View>
      )}
      <List variant="unstyled" margin="small 0" itemSpacing="small">
        {nonFeaturedLinks
          .map(link => {
            const has_new_tag = link.is_new && featuredLinksEnabled
            return (
              <List.Item key={`link-${link.id}`}>
                <Flex justifyItems="space-between" alignItems="center">
                  <Flex.Item size={has_new_tag ? '80%' : '100%'}>
                    <Link
                      isWithinText={false}
                      href={link.url}
                      target="_blank"
                      rel="noopener"
                      onClick={handleClick(link)}
                    >
                      {link.text}
                    </Link>
                    {has_new_tag && <ScreenReaderContent>{I18n.t('New')}</ScreenReaderContent>}
                    {link.subtext && (
                      <Text as="div" size="small">
                        {link.subtext}
                      </Text>
                    )}
                  </Flex.Item>
                  <Flex.Item>
                    {has_new_tag && (
                      <PresentationContent>
                        <Pill variant="success" text={I18n.t('NEW')} />
                      </PresentationContent>
                    )}
                  </Flex.Item>
                </Flex>
              </List.Item>
            )
          })
          .concat(
            // if the current user is a teacher, show a link to
            // open up the welcome tour
            window.ENV.FEATURES?.product_tours &&
              (window.ENV.current_user_roles?.includes('admin') ||
                window.ENV.current_user_roles?.includes('teacher') ||
                window.ENV.current_user_roles?.includes('student')) && [
                <List.Item key="welcome_tour">
                  <View className="welcome-tour-link">
                    <Link isWithinText={false} onClick={() => tourPubSub.publish('tour-open')}>
                      {I18n.t('Show Welcome Tour')}
                    </Link>
                  </View>
                </List.Item>
              ]
          )
          .concat(
            // if the current user is an admin, show the settings link to
            // customize this menu
            window.ENV.current_user_roles?.includes('root_admin') && [
              <List.Item key="hr">
                <hr role="presentation" />
              </List.Item>,
              <List.Item key="customize">
                <Link isWithinText={false} href="/accounts/self/settings#custom_help_link_settings">
                  {I18n.t('Customize this menu')}
                </Link>
              </List.Item>
            ]
          )
          .filter(Boolean)}
      </List>
    </View>
  )
}

HelpLinks.propTypes = {
  links: arrayOf(
    shape({
      id: string.isRequired,
      url: string.isRequired,
      text: string.isRequired,
      subtext: string,
      feature_headline: string,
      is_featured: bool,
      is_new: bool
    })
  ).isRequired,
  hasLoaded: bool,
  onClick: func
}

HelpLinks.defaultProps = {
  hasLoaded: false,
  links: [],
  onClick: () => {}
}
