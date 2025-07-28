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

import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import React, {useEffect, useState, useRef} from 'react'
import {Link} from '@instructure/ui-link'
import {
  IconAddLine,
  IconArrowDownLine,
  IconArrowUpLine,
  IconEditLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import type {AccountWithCounts} from './types'
import SubaccountNameForm from './SubaccountNameForm'
import {calculateIndent} from './util'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('sub_accounts')

interface Props {
  account: AccountWithCounts
  depth: number
  onAdd: () => void
  onExpand: () => void
  onCollapse: () => void
  onEditSaved: (json: AccountWithCounts) => void
  onDelete: () => void
  isExpanded: boolean
  canDelete: boolean
  show: boolean
  isFocus: boolean
}

export default function SubaccountItem(props: Props) {
  const linkRef = useRef<HTMLElement | null>(null)
  const [isEditing, setIsEditing] = useState(false)

  useEffect(() => {
    if (!props.show) {
      setIsEditing(false)
    }
  }, [props.show])

  useEffect(() => {
    if (props.isFocus && linkRef.current) {
      linkRef.current.focus()
    }
  }, [props.isFocus, linkRef])

  const courseCount = I18n.t(
    {
      one: '1 Course',
      other: '%{count} Courses',
    },
    {count: props.account.course_count},
  )

  const subaccountCount = I18n.t(
    {
      one: '1 Sub-Account',
      other: '%{count} Sub-Accounts',
    },
    {count: props.account.sub_account_count},
  )

  const renderRowContents = () => {
    const addTip = I18n.t("Add subaccount to '%{account}'", {
      account: props.account.name,
    })
    const collapseTip = I18n.t("Collapse subaccount list for '%{account}'", {
      account: props.account.name,
    })
    const expandTip = I18n.t("Expand subaccount list for '%{account}'", {
      account: props.account.name,
    })
    const editTip = I18n.t("Edit account '%{account}'", {
      account: props.account.name,
    })
    const deleteTip = I18n.t("Delete account '%{account}'", {
      account: props.account.name,
    })
    const collapsedProps = {
      screenReaderLabel: collapseTip,
      renderIcon: <IconArrowUpLine />,
      onClick: props.onCollapse,
    }
    const expandProps = {
      screenReaderLabel: expandTip,
      renderIcon: <IconArrowDownLine />,
      onClick: props.onExpand,
    }
    const buttonProps = props.isExpanded ? collapsedProps : expandProps
    return (
      <>
        <Flex.Item
          data-testid={`header_${props.account.id}`}
          className="sub_account_row"
          width={`${80 - indent}%`}
        >
          <Flex direction="column" gap="xx-small" display="inline-flex">
            <Link
              isWithinText={false}
              data-testid={`link_${props.account.id}`}
              href={`/accounts/${props.account.id}`}
              elementRef={(e: Element | null) => {
                linkRef.current = e as HTMLElement
              }}
            >
              <Text size="medium" weight="bold">
                {props.account.name}
              </Text>
            </Link>
            {props.account.course_count > 0 ? (
              <Flex.Item margin="0 0 0 small">
                <Text data-testid={`course_count_${props.account.id}`} color="secondary">
                  {courseCount}
                </Text>
              </Flex.Item>
            ) : null}
            {props.account.sub_account_count > 0 ? (
              <Flex.Item margin="0 0 0 small">
                <Text data-testid={`sub_count_${props.account.id}`} color="secondary">
                  {subaccountCount}
                </Text>
              </Flex.Item>
            ) : null}
          </Flex>
        </Flex.Item>
        <Flex.Item size="20%" shouldGrow>
          <Flex gap="x-small" justifyItems="end" alignItems="end">
            {props.account.sub_account_count > 0 ? (
              <Tooltip renderTip={props.isExpanded ? collapseTip : expandTip}>
                <IconButton
                  {...buttonProps}
                  withBorder={false}
                  data-testid={
                    props.isExpanded ? `collapse-${props.account.id}` : `expand-${props.account.id}`
                  }
                />
              </Tooltip>
            ) : null}
            <Tooltip renderTip={addTip}>
              <IconButton
                withBorder={false}
                screenReaderLabel={addTip}
                renderIcon={<IconAddLine />}
                onClick={props.onAdd}
                data-testid={`add-${props.account.id}`}
              />
            </Tooltip>
            <Tooltip renderTip={editTip}>
              <IconButton
                withBorder={false}
                screenReaderLabel={editTip}
                renderIcon={<IconEditLine />}
                onClick={() => setIsEditing(true)}
                data-testid={`edit-${props.account.id}`}
              />
            </Tooltip>
            <Tooltip renderTip={deleteTip}>
              <IconButton
                withBorder={false}
                screenReaderLabel={deleteTip}
                renderIcon={<IconTrashLine />}
                disabled={!props.canDelete}
                onClick={props.onDelete}
                data-testid={`delete-${props.account.id}`}
              />
            </Tooltip>
          </Flex>
        </Flex.Item>
      </>
    )
  }

  const indent = calculateIndent(props.depth)
  if (props.show && !isEditing) {
    return (
      <Flex key={`${props.account.id}_header`}>
        <Flex.Item width={`${indent}%`} />
        {renderRowContents()}
      </Flex>
    )
  } else if (props.show) {
    return (
      <SubaccountNameForm
        depth={props.depth}
        accountName={props.account.name}
        accountId={props.account.id}
        onSuccess={(json: AccountWithCounts) => {
          setIsEditing(false)
          props.onEditSaved(json)
        }}
        onCancel={() => setIsEditing(false)}
      />
    )
  }
}
