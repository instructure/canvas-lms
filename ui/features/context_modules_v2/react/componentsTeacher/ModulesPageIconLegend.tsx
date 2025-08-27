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

import React, {useCallback, useRef, useState} from 'react'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
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
}

const ModulesPageIconLegend: React.FC<ModulesPagePageLegendProps> = ({is_blueprint_course}) => {
  const [open, setOpen] = useState(false)
  const [visible, setVisible] = useState(false)
  const btnRef = useRef<HTMLButtonElement | null>(null)

  const onClose = useCallback(() => {
    setOpen(false)
    btnRef.current?.focus()
  }, [])

  const openLegend = useCallback(() => {
    setOpen(true)
  }, [])

  const handleFocus = () => {
    setVisible(true)
  }

  const handleBlur = () => {
    setVisible(open)
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

  return (
    <div data-testid="icon-legend-button-wrapper" style={visible ? undefined : hideStyle}>
      <IconButton
        elementRef={btn => {
          btnRef.current = btn as HTMLButtonElement
        }}
        onClick={openLegend}
        screenReaderLabel={I18n.t('Open icon legend')}
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
          label={I18n.t('Icon Legend')}
          title={I18n.t('Icon Legend')}
          open={open}
          onDismiss={onClose}
          footer={renderFooter()}
        >
          <View data-testid="icon-legend" as="div" margin="modalElements">
            {is_blueprint_course && (
              <>
                {renderIconLegend(IconLegendItems.blueprint_locked)}
                {renderIconLegend(IconLegendItems.blueprint_unlocked)}
                <hr style={{margin: '.5rem 0'}} />
              </>
            )}
            {renderIconLegend(IconLegendItems.published)}
            {renderIconLegend(IconLegendItems.unpublished)}
          </View>
        </CanvasModal>
      )}
    </div>
  )
}

export {ModulesPageIconLegend, type ModulesPagePageLegendProps}
