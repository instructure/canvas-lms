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

import React, {useMemo} from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'

import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'

import apiUserContent from '@canvas/util/jquery/apiUserContent'
import {ImmersiveReaderButton} from '@canvas/immersive-reader/ImmersiveReader'

const I18n = useI18nScope('overview_page')

export default function OverviewPage({content, url, canEdit, showImmersiveReader}) {
  const html = useMemo(() => apiUserContent.convert(content), [content])
  return (
    <>
      <Flex justifyItems="end" alignItems="center" margin="small 0 0">
        {canEdit && (
          <Flex.Item>
            <IconButton
              screenReaderLabel={I18n.t('Edit home page')}
              renderIcon={IconEditLine}
              href={url}
              withBackground={false}
              withBorder={false}
            />
          </Flex.Item>
        )}
        {showImmersiveReader && (
          <Flex.Item margin="0 0 0 small">
            <ImmersiveReaderButton
              content={{content: () => html, title: I18n.t('Subject Home Page')}}
            />
          </Flex.Item>
        )}
      </Flex>
      <div
        className="user_content"
        /* html sanitized by server */
        dangerouslySetInnerHTML={{__html: html}}
      />
    </>
  )
}

OverviewPage.propTypes = {
  content: PropTypes.string.isRequired,
  url: PropTypes.string.isRequired,
  canEdit: PropTypes.bool.isRequired,
  showImmersiveReader: PropTypes.bool.isRequired,
}
