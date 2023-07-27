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

import PropTypes from 'prop-types'
import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {IconAddLine, IconTrashLine} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'

const I18n = useI18nScope('conversations_2')

const MAX_LABEL_LENGTH = 25

export const ManageUserLabels = ({open, labels, onCreate, onDelete, onClose}) => {
  const [newLabel, setNewLabel] = useState('')
  const [internalLabels, setInternalLabels] = useState([])
  const [deletedLabels, setDeletedLabels] = useState([])
  const [error, setError] = useState('')

  useEffect(() => {
    setInternalLabels(labels.map(label => ({name: label, new: false})))
  }, [labels])

  const renderCloseButton = () => {
    return (
      <CloseButton
        placement="end"
        offset="small"
        onClick={() => {
          close()
        }}
        screenReaderLabel={I18n.t('Close')}
      />
    )
  }

  const addLabel = () => {
    const labelExists = internalLabels.find(
      label => label.name.trim().toLowerCase() === newLabel.trim().toLowerCase()
    )

    if (labelExists) {
      setError(I18n.t('The specified label already exists. Please enter a different label name.'))
      return
    }

    const newInternalLabels = [...internalLabels, {name: newLabel.trim(), new: true}]
    newInternalLabels.sort((a, b) => a.name.localeCompare(b.name))

    setNewLabel('')
    setInternalLabels(newInternalLabels)
  }

  const deleteLabel = labelName => {
    const newInternalLabels = [...internalLabels].filter(label => label.name !== labelName)
    const labelIsNew = internalLabels.find(label => label.name === labelName)?.new || false

    // If the label is new, we don't need to call onDelete
    if (!labelIsNew) {
      setDeletedLabels([...deletedLabels, labelName])
    }
    setInternalLabels(newInternalLabels)
  }

  const reset = () => {
    setNewLabel('')
    setInternalLabels(labels.map(label => ({name: label, new: false})))
    setDeletedLabels([])
  }

  const close = () => {
    reset()

    if (onClose) {
      onClose()
    }
  }

  const save = () => {
    const newLabels = internalLabels.filter(label => label.new).map(label => label.name)

    if (newLabels.length > 0) {
      onCreate(newLabels)
    }

    if (deletedLabels.length > 0) {
      // This is hacky... TLDR: There are sync issues
      // when running both create and delete mutations at the same time.
      // Probably the best solution in the future is to have a single mutation
      // that handles addition and deletions at the same time.
      setTimeout(() => {
        onDelete(deletedLabels)
      }, 2500)
    }

    close()
  }

  return (
    <Modal
      open={open}
      onDismiss={() => {
        close()
      }}
      size="small"
      label={I18n.t('Labels')}
    >
      <Modal.Header>
        {renderCloseButton()}
        <Heading>{I18n.t('Labels')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {error && (
          <Alert
            variant="error"
            renderCloseButtonLabel={I18n.t('Close')}
            margin="small"
            timeout={5000}
            onDismiss={() => {
              setError('')
            }}
          >
            {error}
          </Alert>
        )}
        <Text>{I18n.t('Create labels to organize and filter conversations.')}</Text>
        <br />
        <Text>{I18n.t('Manage created labels below.')}</Text>
        <Flex margin="small 0 0 0">
          <Flex.Item shouldGrow={true}>
            <TextInput
              renderLabel={I18n.t('Label Name')}
              placeholder={I18n.t('Label Name')}
              value={newLabel}
              onChange={(_, value) => {
                setNewLabel(value.substring(0, MAX_LABEL_LENGTH))
              }}
            />
          </Flex.Item>
          <Flex.Item align="end" margin="0 0 0 x-small">
            <IconButton
              screenReaderLabel={I18n.t('Add Label')}
              onClick={() => {
                addLabel()
              }}
              disabled={newLabel.trim() === ''}
              data-testid="add-label"
            >
              <IconAddLine />
            </IconButton>
          </Flex.Item>
        </Flex>
        <View as="div" margin="small 0 0 0">
          <Text weight="bold">Manage Labels</Text>
        </View>
        <Table caption={I18n.t('Labels')}>
          <Table.Body>
            {internalLabels.map(label => (
              <Table.Row key={label.name} data-testid="label">
                <Table.Cell>
                  <Text dangerouslySetInnerHTML={{__html: label.name.replaceAll(' ', '&nbsp;')}} />
                </Table.Cell>
                <Table.Cell textAlign="end">
                  <IconButton
                    withBackground={false}
                    withBorder={false}
                    screenReaderLabel={I18n.t('Remove Label')}
                    color="danger"
                    onClick={() => {
                      deleteLabel(label.name)
                    }}
                    data-testid="delete-label"
                  >
                    <IconTrashLine />
                  </IconButton>
                </Table.Cell>
              </Table.Row>
            ))}
          </Table.Body>
        </Table>
      </Modal.Body>
      <Modal.Footer>
        <Button
          onClick={() => {
            close()
          }}
          margin="0 x-small 0 0"
        >
          {I18n.t('Close')}
        </Button>
        <Button
          onClick={() => {
            save()
          }}
          color="primary"
        >
          {I18n.t('Save')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

ManageUserLabels.propTypes = {
  open: PropTypes.bool,
  labels: PropTypes.arrayOf(PropTypes.string),
  onCreate: PropTypes.func,
  onDelete: PropTypes.func,
  onClose: PropTypes.func,
}
