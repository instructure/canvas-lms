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

import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import CanvasModal from '@canvas/instui-bindings/react/Modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'

const I18n = useI18nScope('faculty_journal')

const DeprecationModal = ({
  deprecationDate,
  timezone,
}: {
  deprecationDate: string
  timezone: string
}) => {
  const [isOpen, setOpen] = useState(true)
  const [suppressCheckboxChecked, setSuppressCheckboxChecked] = useState(false)
  const dateFormatter = useDateTimeFormat('date.formats.long', timezone)

  const handleAck = () => {
    if (suppressCheckboxChecked) {
      doFetchApi({
        method: 'PUT',
        path: '/api/v1/users/self/user_notes/suppress_deprecation_notice',
      })
        .then(() => setOpen(false))
        .catch(showFlashError('Failed to save preference.'))
    } else {
      setOpen(false)
    }
  }

  const renderFooter = () => (
    <Flex justifyItems="end">
      <Button color="primary" onClick={handleAck}>
        {I18n.t('I Understand')}
      </Button>
    </Flex>
  )

  return (
    <CanvasModal
      open={isOpen}
      onDismiss={() => setOpen(false)}
      label={I18n.t('Deprecated Tool')}
      footer={renderFooter}
      size="small"
    >
      <View as="div" padding="small">
        <Text as="div" weight="bold">
          {I18n.t('Faculty Journal has been deprecated!')}
        </Text>
        <Text as="div">
          {I18n.t(
            'Access to Faculty Journal will end on %{deprecationDate}. Contact your Canvas Administrator with any questions.',
            {deprecationDate: dateFormatter(deprecationDate)}
          )}
        </Text>
        <View as="div" margin="medium 0 small">
          <Checkbox
            label={I18n.t("Don't show this again")}
            checked={suppressCheckboxChecked}
            onChange={e => setSuppressCheckboxChecked(e.target.checked)}
          />
        </View>
      </View>
    </CanvasModal>
  )
}

export default DeprecationModal
