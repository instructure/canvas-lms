/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback} from 'react'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
// @ts-expect-error
import {IconAssignmentLine, IconQuizLine, IconQuestionLine} from '@instructure/ui-icons'
// import ItemAssignToPanel from './ItemAssignToPanel'
import TrayFooter from '../Footer'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

function itemTypeToIcon(itemType: string) {
  switch (itemType) {
    case 'Assignment':
      return <IconAssignmentLine />
    case 'Quizzes::Quiz':
      return <IconQuizLine />
    default:
      return <IconQuestionLine />
  }
}

export interface ItemAssignToTrayProps {
  open: boolean
  onDismiss: () => void
  onSave: () => void
  courseId: string
  moduleItemId: string
  moduleItemName: string
  moduleItemType: string
  pointsPossible: string
}

export default function ItemAssignToTray({
  open,
  onDismiss,
  onSave,
  // courseId,
  // moduleItemId,
  moduleItemName,
  moduleItemType,
  pointsPossible,
}: ItemAssignToTrayProps) {
  const handleUpdate = useCallback(() => {
    onSave()
  }, [onSave])

  function Header() {
    const icon = itemTypeToIcon(moduleItemType)
    return (
      <FlexItem margin="medium 0 0 0" padding="0 medium" width="100%">
        <CloseButton
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
        />
        <Heading as="h3">
          {icon} {moduleItemName}
        </Heading>
        <View as="div" margin="medium 0 0 0">
          {renderItemType()} {pointsPossible ? `| ${pointsPossible}` : ''}
        </View>
      </FlexItem>
    )
  }

  function renderItemType() {
    switch (moduleItemType) {
      case 'Assignment':
        return I18n.t('Assignment')
      case 'Quizzes::Quiz':
        return I18n.t('Quiz')
      default:
        return ''
    }
  }

  function Body() {
    return (
      <FlexItem margin="medium medium 0" width="100%" shouldGrow={true} shouldShrink={true}>
        <View as="div">content here</View>
        {/*
        <View as="div" margin="small 0 0 0">
          <ItemAssignToPanel courseId={courseId} moduleItemId={moduleItemId} canDelete={true} />
        </View>
         <View as="div" margin="small small 0 small">
           <ItemAssignToPanel courseId={courseId} moduleItemId={moduleItemId} />
      </View>
*/}
      </FlexItem>
    )
  }

  function Footer() {
    return (
      <FlexItem margin="small 0 0 0" width="100%">
        <TrayFooter
          updateButtonLabel={I18n.t('Save')}
          onDismiss={onDismiss}
          onUpdate={handleUpdate}
        />
      </FlexItem>
    )
  }

  return (
    <Tray
      open={open}
      label={I18n.t('Edit assignment %{name}', {
        name: moduleItemName,
      })}
      placement="end"
      size="regular"
    >
      <Flex direction="column" height="100vh" width="100%">
        {Header()}
        {Body()}
        {Footer()}
      </Flex>
    </Tray>
  )
}
