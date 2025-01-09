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

import React, {useCallback, useEffect, useState} from 'react'
import {Button, CondensedButton} from '@instructure/ui-buttons'
import {Popover} from '@instructure/ui-popover'
import {Flex} from '@instructure/ui-flex'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {
  IconExpandItemsLine,
  IconTextStartLine,
  IconTextCenteredLine,
  IconTextEndLine,
  IconMoreLine,
} from '@instructure/ui-icons'
import {
  IconPlacementTop,
  IconPlacementMiddle,
  IconPlacementBottom,
} from '../../../../../assets/internal-icons'
import {
  type GroupLayout,
  type GroupAlignment,
  type GroupHorizontalAlignment,
  defaultAlignment,
} from '../types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type ToolbarAlignmentProps = {
  layout?: GroupLayout
  alignment?: GroupAlignment
  verticalAlignment?: GroupAlignment
  onSave: (
    layout: GroupLayout,
    alignment: GroupHorizontalAlignment,
    verticalAlignment: GroupAlignment,
  ) => void
}

const ToolbarAlignment = ({
  layout,
  alignment,
  verticalAlignment,
  onSave,
}: ToolbarAlignmentProps) => {
  const [isOpen, setIsOpen] = useState(false)
  const [currLayout, setCurrLayout] = useState<GroupLayout>(layout || defaultAlignment.layout)
  const [currAlignment, setCurrAlignment] = useState<GroupHorizontalAlignment>(
    alignment || defaultAlignment.alignment,
  )
  const [currVerticalAlignment, setCurrVerticalAlignment] = useState<GroupAlignment>(
    verticalAlignment || defaultAlignment.verticalAlignment,
  )
  const [menuKey, setMenuKey] = useState(Date.now())

  useEffect(() => {
    if (!isOpen) {
      // reset
      setCurrLayout(layout || defaultAlignment.layout)
      setCurrAlignment(alignment || defaultAlignment.alignment)
      setCurrVerticalAlignment(verticalAlignment || defaultAlignment.verticalAlignment)
    }
  }, [isOpen, layout, alignment, verticalAlignment])

  const handleCancel = useCallback(() => {
    setIsOpen(false)
  }, [])

  const handleShowContent = useCallback(() => {
    setIsOpen(true)
  }, [])

  const handleHideContent = useCallback(() => {
    setIsOpen(false)
  }, [])

  const handleSave = useCallback(() => {
    setIsOpen(false)
    onSave(currLayout, currAlignment, currVerticalAlignment)
  }, [currAlignment, currLayout, currVerticalAlignment, onSave])

  const renderReset = () => {
    if (
      currLayout !== defaultAlignment.layout ||
      currAlignment !== defaultAlignment.alignment ||
      currVerticalAlignment !== defaultAlignment.verticalAlignment
    ) {
      return (
        <View as="div" margin="small" textAlign="start">
          <CondensedButton
            color="secondary"
            onClick={() => {
              setCurrLayout(defaultAlignment.layout)
              setCurrAlignment(defaultAlignment.alignment)
              setCurrVerticalAlignment(defaultAlignment.verticalAlignment)
              setMenuKey(Date.now())
            }}
            themeOverride={{secondaryGhostColor: '#0e68b3'}}
          >
            {I18n.t('Reset Default Alignment')}
          </CondensedButton>
        </View>
      )
    }
  }

  return (
    <Popover
      on="click"
      isShowingContent={isOpen}
      renderTrigger={
        <CondensedButton
          size="small"
          color="secondary"
          themeOverride={{secondaryGhostColor: '#0e68b3'}}
        >
          {I18n.t('Alignment Options')}
        </CondensedButton>
      }
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
    >
      <View as="div" textAlign="center" minWidth="222px">
        {renderReset()}
        {/* the menu was not updating on resetting values. Updating the key gets a new Menu */}
        <Menu defaultShow={true} key={`${menuKey}`}>
          <Menu.Group label={I18n.t('Orientation')}>
            <Menu.Item
              value="row"
              onSelect={() => setCurrLayout('row')}
              selected={currLayout === 'row'}
            >
              <Flex gap="x-small">
                <span style={{rotate: '90deg'}}>
                  <IconExpandItemsLine />
                </span>
                {I18n.t('Align Horizontally')}
              </Flex>
            </Menu.Item>
            <Menu.Item
              value="column"
              onSelect={() => setCurrLayout('column')}
              selected={currLayout === 'column'}
            >
              <Flex gap="x-small">
                <IconExpandItemsLine />

                {I18n.t('Align Vertically')}
              </Flex>
            </Menu.Item>
          </Menu.Group>
          <Menu.Group label={I18n.t('Alignment')}>
            <Menu.Item
              value="start"
              onSelect={() => setCurrAlignment('start')}
              selected={currAlignment === 'start'}
            >
              <Flex gap="x-small">
                <IconTextStartLine />
                {I18n.t('Align to start')}
              </Flex>
            </Menu.Item>
            <Menu.Item
              value="center"
              onSelect={() => setCurrAlignment('center')}
              selected={currAlignment === 'center'}
            >
              <Flex gap="x-small">
                <IconTextCenteredLine />
                {I18n.t('Align to center')}
              </Flex>
            </Menu.Item>
            <Menu.Item
              value="end"
              onSelect={() => setCurrAlignment('end')}
              selected={currAlignment === 'end'}
            >
              <Flex gap="x-small">
                <IconTextEndLine />
                {I18n.t('Align to end')}
              </Flex>
            </Menu.Item>
            <Menu.Item
              value="distribute"
              onSelect={() => setCurrAlignment('distribute')}
              selected={currAlignment === 'distribute'}
            >
              <Flex gap="x-small">
                <span style={{rotate: '90deg'}}>
                  <IconMoreLine />
                </span>
                {I18n.t('Distribute')}
              </Flex>
            </Menu.Item>
          </Menu.Group>
          <Menu.Group label={I18n.t('Placement')}>
            <Menu.Item
              value="start"
              onSelect={() => setCurrVerticalAlignment('start')}
              selected={currVerticalAlignment === 'start'}
            >
              <Flex gap="x-small">
                <IconPlacementTop size="x-small" />

                {I18n.t('Align to top')}
              </Flex>
            </Menu.Item>
            <Menu.Item
              value="center"
              onSelect={() => setCurrVerticalAlignment('center')}
              selected={currVerticalAlignment === 'center'}
            >
              <Flex gap="x-small">
                <IconPlacementMiddle size="x-small" />
                {I18n.t('Align to middle')}
              </Flex>
            </Menu.Item>
            <Menu.Item
              value="end"
              onSelect={() => setCurrVerticalAlignment('end')}
              selected={currVerticalAlignment === 'end'}
            >
              <Flex gap="x-small">
                <IconPlacementBottom size="x-small" />
                {I18n.t('Align to bottom')}
              </Flex>
            </Menu.Item>
          </Menu.Group>
        </Menu>
        <View as="div" background="secondary" padding="small" textAlign="end">
          <Button onClick={handleCancel}>{I18n.t('Close')}</Button>
          <Button color="primary" onClick={handleSave} margin="0 0 0 small">
            {I18n.t('Apply')}
          </Button>
        </View>
      </View>
    </Popover>
  )
}

export {ToolbarAlignment}
