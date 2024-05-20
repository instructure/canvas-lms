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

import React, {useEffect, useRef, useState} from 'react'
import {Popover} from '@instructure/ui-popover'
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine, IconTrashLine, IconUserLine, IconUpdownLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Menu} from '@instructure/ui-menu'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {AccessibleContent} from '@instructure/ui-a11y-content'

type Props = {
  userId: number
  userName: string
  isLeader: boolean
  onRemoveFromGroup: (userId: number) => void
  onRemoveAsLeader: (userId: number) => void
  onSetAsLeader: (userId: number) => void
  onMoveTo: (userId: number) => void
}

type MenuItemProps = {
  shouldRender?: boolean
  value: string
  onClick: () => void
  alt: string
  icon: React.ReactNode
  text: string
  setRef?: (ref: HTMLElement) => void
}

const I18n = useI18nScope('groups')

export const GroupUserMenu = ({...props}: Props): JSX.Element => {
  const [isOpen, setIsOpen] = useState<boolean>(false)
  const triggerButtonRef = useRef<HTMLElement | null>(null)
  const firstMenuItemRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (isOpen && firstMenuItemRef.current) {
      firstMenuItemRef.current.focus()
    }
  }, [isOpen, firstMenuItemRef])

  useEffect(() => {
    const eventName = `closeGroupUserMenuForUser${props.userId}`
    const handler = () => {
      if (isOpen) {
        setIsOpen(false)
      }
    }

    window.addEventListener(eventName, handler)
    return () => {
      window.removeEventListener(eventName, handler)
    }
  }, [isOpen, props.userId])

  const screenReaderLabel = I18n.t("Edit %{userName}'s membership", {
    userName: props.userName,
  })

  const handleMenuKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Tab' && isOpen) {
      setIsOpen(false)
      if (triggerButtonRef.current) {
        triggerButtonRef.current.focus()
      }
    }
  }

  const handlePopoverKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setIsOpen(true)
    }
  }

  const renderMenuItem = ({
    shouldRender = true,
    value,
    onClick,
    alt,
    icon,
    text,
    setRef = () => {},
  }: MenuItemProps): JSX.Element | false => {
    return (
      shouldRender && (
        <Menu.Item value={value} onClick={onClick} data-testid={value} ref={setRef}>
          <AccessibleContent alt={alt}>
            <Flex alignItems="center">
              <Flex.Item>{icon}</Flex.Item>
              <Flex.Item margin="0 xx-small">
                <Text as="div" size="small" weight="bold">
                  {text}
                </Text>
              </Flex.Item>
            </Flex>
          </AccessibleContent>
        </Menu.Item>
      )
    )
  }

  return (
    <>
      <Popover
        renderTrigger={
          <IconButton
            withBackground={false}
            withBorder={false}
            screenReaderLabel={screenReaderLabel}
            size="small"
            as="span"
            data-testid="groupUserMenu"
            data-userid={props.userId}
            elementRef={(el: HTMLElement) => {
              triggerButtonRef.current = el
            }}
          >
            <IconMoreLine />
          </IconButton>
        }
        onKeyDown={handlePopoverKeyDown}
        isShowingContent={isOpen}
        onShowContent={() => {
          setIsOpen(true)
        }}
        onHideContent={() => {
          setIsOpen(false)
        }}
        on="click"
        screenReaderLabel={screenReaderLabel}
        shouldContainFocus={true}
        shouldReturnFocus={true}
        shouldCloseOnDocumentClick={true}
      >
        <Menu onKeyDown={handleMenuKeyDown}>
          {renderMenuItem({
            value: 'removeFromGroup',
            onClick: () => {
              setIsOpen(false)
              props.onRemoveFromGroup(props.userId)
            },
            alt: I18n.t('Remove %{name} from group', {name: props.userName}),
            icon: <IconTrashLine size="x-small" />,
            text: I18n.t('Remove'),
            setRef: ref => {
              firstMenuItemRef.current = ref
            },
          })}
          {renderMenuItem({
            shouldRender: props.isLeader,
            value: 'removeAsLeader',
            onClick: () => {
              setIsOpen(false)
              props.onRemoveAsLeader(props.userId)
            },
            alt: I18n.t('Remove %{name} as leader', {name: props.userName}),
            icon: <IconUserLine size="x-small" />,
            text: I18n.t('Remove as Leader'),
          })}
          {renderMenuItem({
            shouldRender: !props.isLeader,
            value: 'setAsLeader',
            onClick: () => {
              setIsOpen(false)
              props.onSetAsLeader(props.userId)
            },
            alt: I18n.t('Set %{name} as leader', {name: props.userName}),
            icon: <IconUserLine size="x-small" />,
            text: I18n.t('Set as Leader'),
          })}
          {renderMenuItem({
            value: 'moveTo',
            onClick: () => {
              setIsOpen(false)
              props.onMoveTo(props.userId)
            },
            alt: I18n.t('Move %{name} to a new group', {name: props.userName}),
            icon: <IconUpdownLine size="x-small" />,
            text: I18n.t('Move To...'),
          })}
        </Menu>
      </Popover>
    </>
  )
}
