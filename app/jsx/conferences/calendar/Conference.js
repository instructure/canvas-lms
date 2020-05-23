/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconXLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {PresentationContent} from '@instructure/ui-a11y-content'
import sanitizeHtml from 'jsx/shared/sanitizeHtml'
import RichContentEditor from 'jsx/shared/rce/RichContentEditor'
import I18n from 'i18n!conferences'
import webConference from 'jsx/shared/proptypes/webConference'

// we use this to consolidate the import of tinymce into our environment
// (as recommended by jsx/shared/sanitizeHTML)
RichContentEditor.preloadRemoteModule()

const HtmlConference = ({html, removeConference}) => {
  return (
    <View as="div" position="relative">
      {removeConference && (
        <CloseButton
          placement="end"
          offset="none"
          screenReaderLabel={I18n.t('Remove conference')}
          onClick={() => removeConference(null)}
        />
      )}
      <div dangerouslySetInnerHTML={{__html: sanitizeHtml(html)}} />
    </View>
  )
}

const LinkConference = ({conference, removeConference}) => {
  const url = conference.lti_settings?.url || `${conference.url}/join`
  const iconURL = conference.lti_settings?.icon?.url
  const icon = iconURL && <Img src={iconURL} margin="0 x-small 0 0" height="20px" width="20px" />
  return (
    <Flex direction="row">
      <Flex.Item shouldGrow>
        <Link
          href={url}
          isWithinText={false}
          target="_blank"
          rel="noreferrer noopener"
          onClick={e => e.stopPropagation()}
        >
          <Flex direction="row">
            <Flex.Item>
              <PresentationContent>{icon}</PresentationContent>
            </Flex.Item>
            <Flex.Item shouldGrow>
              <Text size="small">
                <TruncateText>{conference.title || I18n.t('Conference')}</TruncateText>
              </Text>
            </Flex.Item>
          </Flex>
        </Link>
      </Flex.Item>
      {removeConference && (
        <Flex.Item padding="0 0 0 x-small">
          <IconButton
            size="small"
            withBorder={false}
            withBackground={false}
            screenReaderLabel={I18n.t('Remove conference')}
            onClick={() => removeConference()}
          >
            <IconXLine />
          </IconButton>
        </Flex.Item>
      )}
    </Flex>
  )
}

const Conference = ({conference, removeConference}) =>
  conference.conference_type === 'LtiConference' && conference.lti_settings?.type === 'html' ? (
    <HtmlConference html={conference.lti_settings.html} removeConference={removeConference} />
  ) : (
    <LinkConference conference={conference} removeConference={removeConference} />
  )

Conference.propTypes = {
  conference: webConference.isRequired,
  removeConference: PropTypes.func
}

Conference.defaultProps = {
  removeConference: null
}

export default Conference
