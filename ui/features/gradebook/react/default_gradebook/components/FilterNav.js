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

import React, {useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import I18n from 'i18n!gradebook'
import {IconFilterSolid, IconFilterLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {Tray} from '@instructure/ui-tray'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'

export default function FilterNav() {
  const [isTrayOpen, setIsTrayOpen] = useState(false)

  const openTray = () => {
    setIsTrayOpen(true)
  }

  // empty for now
  const filters = [].map(({label}) => {
    return (
      <Tag
        text={<AccessibleContent alt={I18n.t('Remove filter')}>{label}</AccessibleContent>}
        dismissible
        onClick={() => {}}
        margin="0 xx-small 0 0"
      />
    )
  })

  return (
    <Flex justifyItems="space-between" padding="0 0 small 0">
      <Flex.Item>
        <Flex>
          <Flex.Item padding="0 x-small 0 0">
            <IconFilterLine /> <Text weight="bold">{I18n.t('Applied Filters:')}</Text>
          </Flex.Item>
          <Flex.Item>
            {filters.length ? (
              filters
            ) : (
              <Text color="secondary" weight="bold">
                {I18n.t('None')}
              </Text>
            )}
          </Flex.Item>
        </Flex>
      </Flex.Item>
      <Flex.Item>
        <Button
          renderIcon={IconFilterSolid}
          id="gradebook-settings-button"
          color="secondary"
          onClick={openTray}
        >
          {I18n.t('Filters')}
        </Button>
      </Flex.Item>
      <Tray
        placement="end"
        label="Tray Example"
        open={isTrayOpen}
        onDismiss={() => setIsTrayOpen(false)}
        size="small"
      >
        <View as="div" padding="medium">
          <Flex>
            <Flex.Item shouldGrow shouldShrink>
              <Heading level="h3" as="h3" margin="0 0 x-small">
                {I18n.t('Gradebook Filters')}
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                placement="end"
                offset="small"
                screenReaderLabel="Close"
                onClick={() => setIsTrayOpen(false)}
              />
            </Flex.Item>
          </Flex>
          <Button
            renderIcon={IconFilterLine}
            color="secondary"
            onClick={() => {}}
            margin="small 0 0 0"
            withVisualDebug
            data-testid="new-filter-button"
          >
            {I18n.t('Create New Filter')}
          </Button>
        </View>
      </Tray>
    </Flex>
  )
}
