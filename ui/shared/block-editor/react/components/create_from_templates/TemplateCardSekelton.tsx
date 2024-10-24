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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import type {BlockTemplate} from '../../types'
import {Button} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor')

export default function TemplateCardSkeleton({
  template,
  createAction,
}: {
  template: BlockTemplate
  createAction: () => void
}) {
  return (
    <View
      as="div"
      className={`block-template-preview-card ${template.id === 'blank_page' ? 'blank-card' : ''}`}
      display="flex"
      position="relative"
      height="241px"
      shadow="above"
      tabIndex={0}
      style={{backgroundImage: template?.thumbnail && `url(${template.thumbnail})`}}
      width="341px"
    >
      {template.id === 'blank_page' && <div className="curl" />}
      <Flex alignItems="center" height="241px" justifyItems="center" width="100%">
        {template.id !== 'blank_page' ? (
          <div className="buttons">
            {/* Not yet */}
            {/* <Button color="secondary" margin="0 x-small 0 0" size="small"> */}
            {/*   {I18n.t('Quick Look')} */}
            {/* </Button> */}
            <Button color="primary" size="small" onClick={createAction}>
              {I18n.t('Customize')}
            </Button>
          </div>
        ) : (
          <Button color="primary" size="small" onClick={createAction}>
            {I18n.t('New Blank Page')}
          </Button>
        )}
      </Flex>
    </View>
  )
}
