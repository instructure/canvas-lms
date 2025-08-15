/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'

import {
  IconKeyboardShortcutsLine,
  IconBlueprintSolid,
  IconBlueprintLockSolid,
  IconPublishSolid,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('modules_page_icon_legend')

const hideStyle = {
  opacity: 0,
}

type IconLegendItem = {
  icon: JSX.Element
  title: string
  text: string
}

const IconLegendItems: Record<string, IconLegendItem> = {
  blueprint_locked: {
    icon: <IconBlueprintLockSolid title={I18n.t('Locked by Blueprint icon')} />,
    title: I18n.t('Locked by Blueprint'),
    text: I18n.t('This item is managed by the Blueprint parent course and cannot be changed here'),
  },
  blueprint_unlocked: {
    icon: <IconBlueprintSolid title={I18n.t('Unlocked by Blueprint icon')} />,
    title: I18n.t('Unlocked by Blueprint'),
    text: I18n.t(
      'This item was shared from the blueprint, but changes can be made in this course.',
    ),
  },
  published: {
    icon: <IconPublishSolid title={I18n.t('Published icon')} />,
    title: I18n.t('Published'),
    text: I18n.t('This item is published and visible to students.'),
  },
  unpublished: {
    icon: <IconUnpublishedLine title={I18n.t('Unpublished icon')} />,
    title: I18n.t('Unpublished'),
    text: I18n.t('This item is unpublished and not visible to students.'),
  },
}

type ModulesPagePageLegendProps = {
  is_blueprint_course: boolean
  is_student: boolean
}

const ModulesPageLegend: React.FC<ModulesPagePageLegendProps> = ({
  is_blueprint_course,
  is_student,
}) => {
  const [open, setOpen] = useState(false)
  const [visible, setVisible] = useState(false)
  const [selectionIndex, setSelectionIndex] = useState(0)
  const [btnRef, setBtnRef] = useState<HTMLButtonElement | null>(null)
  const [returnFocusTo, setReturnFocusTo] = useState<HTMLElement | null>(null)

  const onClose = useCallback(() => {
    setOpen(false)
  }, [])

  const openLegend = useCallback(() => {
    setReturnFocusTo(document.activeElement as HTMLElement)
    setOpen(true)
  }, [])

  const handleOpenLegendAction = useCallback(() => {
    openLegend()
  }, [openLegend])

  // when we open the legend from the kb shortcut
  // we need to return focus to where focus was before
  useEffect(() => {
    if (!open && returnFocusTo) {
      returnFocusTo.focus()
    }
  }, [open, returnFocusTo])

  useEffect(() => {
    if (btnRef) {
      btnRef.addEventListener('show-legend-action', handleOpenLegendAction)
    }

    return () => {
      if (btnRef) {
        btnRef.removeEventListener('show-legend-action', handleOpenLegendAction)
      }
    }
  }, [btnRef, handleOpenLegendAction])

  const handleFocus = () => {
    setVisible(true)
  }

  const handleBlur = () => {
    setVisible(open)
  }

  const handleTabChange = (_event: unknown, {index}: {index: number}) => {
    setSelectionIndex(index)
  }

  const renderFooter = () => {
    return (
      <Button color="primary" onClick={onClose}>
        {I18n.t('Close')}
      </Button>
    )
  }

  const renderIconLegend = (item: IconLegendItem) => {
    return (
      <Flex as="div" margin="small 0" alignItems="start">
        <View as="div" margin="0 small 0 0">
          {item.icon}
        </View>
        <View as="div">
          <Text as="div" weight="bold" size="contentSmall">
            {item.title}
          </Text>
          <Text as="div" size="contentSmall">
            {item.text}
          </Text>
        </View>
      </Flex>
    )
  }

  const renderIconInfo = () => {
    return (
      <>
        {is_blueprint_course && (
          <>
            {renderIconLegend(IconLegendItems.blueprint_locked)}
            {renderIconLegend(IconLegendItems.blueprint_unlocked)}
            <hr style={{margin: '.5rem 0'}} />
          </>
        )}
        {renderIconLegend(IconLegendItems.published)}
        {renderIconLegend(IconLegendItems.unpublished)}
      </>
    )
  }

  const renderNavInfo = () => {
    return (
      <View as="div" data-testid="nav-info">
        <Text as="div" size="contentSmall">
          {I18n.t('Use the following keyboard shortcuts to navigate modules and items:')}
        </Text>
        <View as="dl">
          <Text as="dt" size="contentSmall" weight="bold">
            {I18n.t('Up arrow or k:')}
          </Text>
          <Text as="dd" size="contentSmall">
            {I18n.t('Select previous module or item')}
          </Text>
          <Text as="dt" size="contentSmall" weight="bold">
            {I18n.t('Down arrow or j:')}
          </Text>
          <Text as="dd" size="contentSmall">
            {I18n.t('Select next module or item')}
          </Text>
          <Text as="dt" size="contentSmall" weight="bold">
            {I18n.t('Space:')}
          </Text>
          <Text as="dd" size="contentSmall">
            {I18n.t(
              'When the drag handle has focus, select the module or item to begin dragging, then again to drop selected item',
            )}
          </Text>
          <Text as="dt" size="contentSmall" weight="bold">
            {I18n.t('?:')}
          </Text>
          <Text as="dd" size="contentSmall">
            {I18n.t('Open this legend')}
          </Text>
        </View>
      </View>
    )
  }

  const renderCommandInfo = () => {
    return (
      <>
        <Text as="dt" size="contentSmall" weight="bold">
          {I18n.t('e:')}
        </Text>
        <Text as="dd" size="contentSmall">
          {I18n.t('Edit current module or module item')}
        </Text>
        <Text as="dt" size="contentSmall" weight="bold">
          {I18n.t('d:')}
        </Text>
        <Text as="dd" size="contentSmall">
          {I18n.t('Delete current module or module item')}
        </Text>
        <Text as="dt" size="contentSmall" weight="bold">
          {I18n.t('i:')}
        </Text>
        <Text as="dd" size="contentSmall">
          {I18n.t('Increase item indent')}
        </Text>
        <Text as="dt" size="contentSmall" weight="bold">
          {I18n.t('o:')}
        </Text>
        <Text as="dd" size="contentSmall">
          {I18n.t('Decrease item indent')}
        </Text>
        <Text as="dt" size="contentSmall" weight="bold">
          {I18n.t('n:')}
        </Text>
        <Text as="dd" size="contentSmall">
          {I18n.t('New module')}
        </Text>
      </>
    )
  }

  const renderModalBody = () => {
    if (is_student) {
      return renderNavInfo()
    }
    return (
      <Tabs data-testid="legend-tabs" fixHeight="100%" onRequestTabChange={handleTabChange}>
        <Tabs.Panel
          renderTitle={I18n.t('Icons')}
          isSelected={selectionIndex === 0}
          onSelect={() => setSelectionIndex(0)}
        >
          {renderIconInfo()}
        </Tabs.Panel>
        <Tabs.Panel
          renderTitle={I18n.t('Navigation')}
          isSelected={selectionIndex === 1}
          onSelect={() => setSelectionIndex(1)}
        >
          {renderNavInfo()}
        </Tabs.Panel>
        <Tabs.Panel
          renderTitle={I18n.t('Commands')}
          isSelected={selectionIndex === 2}
          onSelect={() => setSelectionIndex(2)}
        >
          {renderCommandInfo()}
        </Tabs.Panel>
      </Tabs>
    )
  }

  return (
    <div data-testid="icon-legend-button-wrapper" style={visible ? undefined : hideStyle}>
      <IconButton
        id="legend-button"
        elementRef={btn => {
          setBtnRef(btn as HTMLButtonElement)
        }}
        onClick={openLegend}
        screenReaderLabel={I18n.t('Open legend')}
        withBackground={false}
        withBorder={false}
        onFocus={handleFocus}
        onBlur={handleBlur}
      >
        <IconKeyboardShortcutsLine />
      </IconButton>
      {open && (
        <CanvasModal
          data-testid="icon-legend-modal"
          label={I18n.t('Legend')}
          title={I18n.t('Legend')}
          size="medium"
          open={open}
          onDismiss={onClose}
          footer={renderFooter()}
          shouldReturnFocus={returnFocusTo === null}
        >
          <View as="div" minHeight="22rem" margin="modalElements">
            {renderModalBody()}
          </View>
        </CanvasModal>
      )}
    </div>
  )
}

export {ModulesPageLegend, type ModulesPagePageLegendProps}
