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
import {Button} from '@instructure/ui-buttons'
import {List, Spinner, Text} from '@instructure/ui-elements'

export default function HelpLinks({links, hasLoaded, onClick}) {
  return (
    <List variant="unstyled" margin="small 0" itemSpacing="small">
      {hasLoaded ? (
        links
          .map((link, index) => (
            <List.Item key={`link-${index}`}>
              <Button
                variant="link"
                href={link.url}
                target="_blank"
                rel="noopener"
                onClick={event => {
                  if (link.url === '#create_ticket' || link.url === '#teacher_feedback') {
                    event.preventDefault()
                    onClick(link.url)
                  }
                }}
                theme={{mediumPadding: '0', mediumHeight: '1.5rem'}}
              >
                {link.text}
              </Button>
              {link.subtext && (
                <Text as="div" size="small">
                  {link.subtext}
                </Text>
              )}
            </List.Item>
          ))
          .concat(
            // if the current user is an admin, show the settings link to
            // customize this menu
            window.ENV.current_user_roles &&
              window.ENV.current_user_roles.includes('root_admin') && [
                <List.Item key="hr">
                  <hr role="presentation" />
                </List.Item>,
                <List.Item key="customize">
                  <Button
                    variant="link"
                    theme={{mediumPadding: '0', mediumHeight: '1.5rem'}}
                    href="/accounts/self/settings#custom_help_link_settings"
                  >
                    {I18n.t('Customize this menu')}
                  </Button>
                </List.Item>
              ]
          )
          .filter(Boolean)
      ) : (
        <List.Item>
          <Spinner size="small" renderTitle={I18n.t('Loading')} />
        </List.Item>
      )}
    </List>
  )
}

HelpLinks.propTypes = {
  links: arrayOf(
    shape({
      url: string.isRequired,
      text: string.isRequired,
      subtext: string
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
