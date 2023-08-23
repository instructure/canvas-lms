/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {string} from 'prop-types'

import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

import locked1SVG from '../../images/Locked1.svg'

const I18n = useI18nScope('assignments_2')

function modulesPage(moduleUrl) {
  const encodedUrl = encodeURI(moduleUrl)

  // xsslint safeString.identifier encodedUrl
  return I18n.t('Please visit your *modules page* for more information.', {
    wrappers: [`<a data-testid="modules-link" target="_blank" href="${encodedUrl}">$1</a>`],
  })
}

export default function MissingPrereqs(props) {
  return (
    <Flex textAlign="center" justifyItems="center" margin="0 0 large" direction="column">
      <Flex.Item>
        <img alt={I18n.t('Assignment Locked with Prerequisite')} src={locked1SVG} />
      </Flex.Item>
      <Flex.Item>
        <Flex margin="small" direction="column" alignItems="center" justifyContent="center">
          <Flex.Item>
            <Text weight="normal" data-testid="assignments-2-pre-req-title" margin="small">
              {I18n.t(
                'This assignment is currently unavailable because you have not yet completed prerequisites set by your instructor.'
              )}
            </Text>
          </Flex.Item>
          <Flex.Item>
            <Text
              weight="normal"
              dangerouslySetInnerHTML={{__html: modulesPage(props.moduleUrl)}}
            />
          </Flex.Item>
        </Flex>
      </Flex.Item>
    </Flex>
  )
}

MissingPrereqs.propTypes = {
  moduleUrl: string.isRequired,
}
