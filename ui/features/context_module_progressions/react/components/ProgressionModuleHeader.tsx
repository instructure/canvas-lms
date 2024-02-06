/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('progression_module_header')

type Props = {
  bridge: {
    on: (
      event: string,
      callback: (model: {attributes: {user: {id: string; name: string}}}) => void
    ) => void
  }
}

const ProgressionModuleHeader = ({bridge}: Props) => {
  const [state, setState] = useState()
  bridge.on('selectionChanged', setState)

  const renderTitle = () => {
    if (!state) return null

    const user = state.attributes
    const href = `${ENV.COURSE_USERS_PATH}/${user.id}`
    return I18n.t('Module Progress for *%{name}*', {
      name: user.name,
      wrappers: [`<a href="${href}">$1</a>`],
    })
  }

  return (
    <Flex margin="0 0 medium">
      <Flex.Item>
        <Heading level="h1">
          <span dangerouslySetInnerHTML={{__html: renderTitle()}} />
        </Heading>
      </Flex.Item>
    </Flex>
  )
}

export default ProgressionModuleHeader
