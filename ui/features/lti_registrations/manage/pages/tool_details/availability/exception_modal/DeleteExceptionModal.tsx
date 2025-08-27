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

import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {ContextCard} from '../ContextCard'
import type {LtiContextControl} from '../../../../model/LtiContextControl'
import {toUndefined} from '../../../../../common/lib/toUndefined'
import {List} from '@instructure/ui-list'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import type {deleteContextControl} from '../../../../api/contextControls'
import {type ReactNode, useState} from 'react'
import {Spinner} from '@instructure/ui-spinner'
import type {ApiResult} from '../../../../../common/lib/apiResult/ApiResult'

const I18n = createI18nScope('lti_registrations')

export type DeleteExceptionModalOpenState =
  | {
      open: false
    }
  | {
      open: true
      toolName: string
      availableInParentContext: boolean
      courseControl: LtiContextControl
    }
  | {
      open: true
      toolName: string
      availableInParentContext: boolean
      accountControl: LtiContextControl
      childControls: LtiContextControl[]
    }

export type DeleteExceptionModalProps = DeleteExceptionModalOpenState & {
  onClose: () => void
  onDelete: typeof deleteContextControl
}

export const DeleteExceptionModal = ({onClose, onDelete, ...props}: DeleteExceptionModalProps) => {
  const [deletingControl, setDeletingControl] = useState(false)

  let body: ReactNode
  if (deletingControl) {
    body = (
      <Flex justifyItems="center" alignItems="center" margin="x-large">
        <Flex.Item>
          <Spinner
            variant="inverse"
            size="large"
            margin="0 small"
            renderTitle={I18n.t('Deleting exceptions')}
          />
        </Flex.Item>
      </Flex>
    )
  } else if (props.open) {
    body = (
      <Modal.Body padding="medium medium" overflow="scroll">
        <View height="25rem" as="div">
          {'accountControl' in props ? (
            <AccountControlDeletionBody
              parent={props.accountControl}
              childControls={props.childControls}
              toolName={props.toolName}
              availableInParentContext={props.availableInParentContext}
            />
          ) : (
            <CourseControlDeletionBody
              toolName={props.toolName}
              control={props.courseControl}
              availableInParentContext={props.availableInParentContext}
            />
          )}
        </View>
      </Modal.Body>
    )
  } else {
    body = null
  }

  return (
    <Modal open={props.open} label={I18n.t('Delete Exception')} size="medium" onDismiss={onClose}>
      <Modal.Header>
        <CloseButton placement="end" offset="small" onClick={onClose} screenReaderLabel="Close" />
        <Heading>{I18n.t('Delete Exception')}</Heading>
      </Modal.Header>
      {body}

      <Modal.Footer>
        <Button margin="0 small 0 0" onClick={onClose}>
          {I18n.t('Cancel')}
        </Button>
        <Button
          id="delete-exception-modal-button"
          color="danger"
          interaction={deletingControl ? 'disabled' : 'enabled'}
          onClick={async () => {
            setDeletingControl(true)
            let result: ApiResult<unknown>
            if (props.open === false) {
              return
            }
            if ('accountControl' in props) {
              result = await onDelete(props.accountControl.registration_id, props.accountControl.id)
            } else {
              result = await onDelete(props.courseControl.registration_id, props.courseControl.id)
            }

            if (result._type === 'Success') {
              onClose()
            }
            setDeletingControl(false)
          }}
        >
          {I18n.t('Delete')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

type CourseControlDeletionBodyProps = {
  availableInParentContext: boolean
  toolName: string
  control: LtiContextControl
}

const CourseControlDeletionBody = ({
  toolName,
  availableInParentContext,
  control,
}: CourseControlDeletionBodyProps) => {
  return (
    <Flex direction="column">
      <Flex.Item margin="0 0 medium 0">
        <Alert variant="info" margin="0">
          <Text
            dangerouslySetInnerHTML={{
              __html: I18n.t(
                'After this change, %{toolName} will be *%{status}* for the %{courseName} course.',
                {
                  toolName: toolName,
                  status: availableInParentContext ? I18n.t('Available') : I18n.t('Not Available'),
                  courseName: control.context_name,
                  wrapper: ['<strong>$1</strong>'],
                },
              ),
            }}
          />
        </Alert>
      </Flex.Item>
      <Flex.Item margin="0 0 small 0">
        <Heading variant="titleCardRegular">{I18n.t('Exception to be deleted:')}</Heading>
      </Flex.Item>
      <Flex.Item>
        <ContextCard
          context_name={control.context_name}
          available={control.available}
          account_id={undefined}
          course_id={control.course_id!}
          path={control.path}
          path_segments={control.display_path}
          exception_counts={{
            child_control_count: control.child_control_count,
            course_count: control.course_count,
            subaccount_count: control.subaccount_count,
          }}
          depth={1}
          inherit_note={false}
        />
      </Flex.Item>
    </Flex>
  )
}

type AccountControlDeletionBodyProps = {
  availableInParentContext: boolean
  toolName: string
  parent: LtiContextControl
  childControls: LtiContextControl[]
}

const AccountControlDeletionBody = ({
  availableInParentContext,
  parent,
  toolName,
  childControls,
}: AccountControlDeletionBodyProps) => {
  const nonRenderedChildControlCount = parent.child_control_count - childControls.length
  return (
    <Flex direction="column">
      <Flex.Item margin="0 0 medium 0">
        <Alert variant="info" margin="0">
          <Text
            dangerouslySetInnerHTML={{
              __html: I18n.t(
                'After this change, %{toolName} will be *%{status}* for the %{accountName} sub-account and its children.',
                {
                  toolName: toolName,
                  status: availableInParentContext ? I18n.t('Available') : I18n.t('Not Available'),
                  accountName: parent.context_name,
                  wrapper: ['<strong>$1</strong>', '<em>$1</em>', '<u>$1</u>'],
                },
              ),
            }}
          />
        </Alert>
      </Flex.Item>
      <Flex.Item margin="0 0 small 0">
        <Heading variant="titleCardRegular">
          {childControls.length > 0
            ? I18n.t('exceptions_to_be_deleted', 'Exceptions to be deleted:')
            : I18n.t('exception_to_be_deleted', 'Exception to be deleted')}
        </Heading>
      </Flex.Item>
      <Flex.Item margin="0 0 small 0">
        <ContextCard
          context_name={parent.context_name}
          available={parent.available}
          exception_counts={{
            child_control_count: parent.child_control_count,
            course_count: parent.course_count,
            subaccount_count: parent.subaccount_count,
          }}
          course_id={undefined}
          account_id={parent.account_id!}
          path={parent.path}
          path_segments={parent.display_path}
          depth={0}
          inherit_note={false}
        />
      </Flex.Item>
      <Flex.Item>
        <List isUnstyled margin="0" itemSpacing="small">
          {childControls.map((control, index) => {
            return (
              <List.Item key={index}>
                <ContextCard
                  key={index}
                  context_name={control.context_name}
                  available={control.available}
                  path={control.path}
                  path_segments={control.display_path}
                  exception_counts={{
                    child_control_count: control.child_control_count,
                    course_count: control.course_count,
                    subaccount_count: control.subaccount_count,
                  }}
                  // Adjust indents to make the account's depth as the new "zero"
                  depth={(control.depth || 1) - (parent.depth || 0)}
                  course_id={toUndefined(control.course_id)}
                  account_id={toUndefined(control.account_id)}
                  inherit_note={false}
                />
              </List.Item>
            )
          })}
        </List>
      </Flex.Item>
      {nonRenderedChildControlCount > 0 && (
        <Flex.Item margin="small 0 0 0">
          <Text>
            {I18n.t(
              {
                one: '1 additional exception not shown.',
                other: '%{count} additional exceptions not shown.',
              },
              {
                count: nonRenderedChildControlCount,
              },
            )}
          </Text>
        </Flex.Item>
      )}
    </Flex>
  )
}
