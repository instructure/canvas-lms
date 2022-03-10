/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import I18n from 'i18n!overview_page'

import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

import apiUserContent from '@canvas/util/jquery/apiUserContent'

export default function OverviewPage({content, url, canEdit}) {
  return (
    <>
      {canEdit && (
        <View as="div" textAlign="end" margin="small 0 0">
          <IconButton
            screenReaderLabel={I18n.t('Edit home page')}
            renderIcon={IconEditLine}
            href={url}
            withBackground={false}
            withBorder={false}
          />
        </View>
      )}
      <div
        className="user_content"
        /* html sanitized by server */
        dangerouslySetInnerHTML={{__html: apiUserContent.convert(content)}}
      />
    </>
  )
}

OverviewPage.propTypes = {
  content: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired,
  canEdit: PropTypes.bool.isRequired
}
