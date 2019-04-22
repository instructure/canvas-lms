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
import React from 'react'
import {bool, string} from 'prop-types'
import I18n from 'i18n!assignments_2'
import FriendlyDatetime from '../../../../shared/FriendlyDatetime'
import IconCalendarMonth from '@instructure/ui-icons/lib/Line/IconCalendarMonth'
import FormField from '@instructure/ui-form-field/lib/components/FormField'
import Flex, {FlexItem} from '@instructure/ui-layout/lib/components/Flex'
import View from '@instructure/ui-layout/lib/components/View'
import generateElementId from '@instructure/ui-utils/lib/dom/generateElementId'

OverrideDates.propTypes = {
  dueAt: string,
  unlockAt: string,
  lockAt: string,
  readOnly: bool
}

OverrideDates.defaultProps = {
  readOnly: false
}

export default function OverrideDates(props) {
  return (
    <Flex
      as="div"
      margin="small 0"
      padding="0"
      justifyItems="space-between"
      wrapItems
      data-testid="OverrideDates"
    >
      <FlexItem margin="0 x-small small 0" as="div" grow>
        {renderDate(I18n.t('Due:'), props.dueAt)}
      </FlexItem>
      <FlexItem margin="0 x-small small 0" as="div" grow>
        {renderDate(I18n.t('Available:'), props.unlockAt)}
      </FlexItem>
      <FlexItem margin="0 0 small 0" as="div" grow>
        {renderDate(I18n.t('Until:'), props.lockAt)}
      </FlexItem>
    </Flex>
  )
}

function renderDate(label, value) {
  const id = generateElementId('overidedate')
  return (
    <FormField id={id} label={label} layout="stacked">
      <View id={id} as="div" padding="x-small" borderWidth="small" borderRadius="medium">
        <Flex justifyItems="space-between">
          <FlexItem>
            {value && <FriendlyDatetime dateTime={value} format={I18n.t('#date.formats.full')} />}
          </FlexItem>
          <FlexItem padding="0 0 xx-small x-small">
            <IconCalendarMonth />
          </FlexItem>
        </Flex>
      </View>
    </FormField>
  )
}
