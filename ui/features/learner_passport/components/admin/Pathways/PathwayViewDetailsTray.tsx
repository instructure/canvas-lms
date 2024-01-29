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

import React, {useCallback, useContext} from 'react'
import {Avatar} from '@instructure/ui-avatar'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import type {PathwayDetailData} from '../../types'
import {renderCompletionAward} from './edit/AddBadgeTray'
import {LearnerGroupCard} from './edit/AddLearnerGroupsPicker'
import {DataContext} from './PathwayEditDataContext'

type PathwayViewDetailsTrayProps = {
  pathway: PathwayDetailData
  open: boolean
  onClose: () => void
}

const PathwayViewDetailsTray = ({pathway, open, onClose}: PathwayViewDetailsTrayProps) => {
  const {allBadges} = useContext(DataContext)

  const renderCanvasUserTable = useCallback(() => {
    return (
      <Table caption="Selected Users">
        <Table.Head>
          <Table.Row>
            <Table.ColHeader id="name">User</Table.ColHeader>
            <Table.ColHeader id="role">Role</Table.ColHeader>
          </Table.Row>
        </Table.Head>
        <Table.Body>
          {pathway.shares.length > 0 ? (
            pathway.shares
              .sort((a, b) => a.sortable_name.localeCompare(b.sortable_name))
              .map(user => {
                return (
                  <Table.Row key={user.id}>
                    <Table.Cell>
                      <Flex gap="x-small">
                        <Flex.Item shouldGrow={false} shouldShrink={false}>
                          <Avatar name={user.name} src={user.avatar_url} size="xx-small" />
                        </Flex.Item>
                        <Flex.Item shouldGrow={true} shouldShrink={true} wrap="wrap">
                          {user.name}
                        </Flex.Item>
                      </Flex>
                    </Table.Cell>
                    <Table.Cell>
                      <Text>{user.role}</Text>
                    </Table.Cell>
                  </Table.Row>
                )
              })
          ) : (
            <Table.Row>
              <Table.Cell colSpan={2}>No Shares</Table.Cell>
            </Table.Row>
          )}
        </Table.Body>
      </Table>
    )
  }, [pathway.shares])

  return (
    <View as="div">
      <Tray label="Pathway Details" open={open} onDismiss={onClose} size="regular" placement="end">
        <Flex as="div" direction="column" height="100vh">
          <Flex as="div" padding="small small medium medium">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <Heading level="h2" margin="0 0 small 0">
                Pathway Details
              </Heading>
            </Flex.Item>
            <Flex.Item>
              <CloseButton
                placement="end"
                offset="small"
                screenReaderLabel="Close"
                onClick={onClose}
              />
            </Flex.Item>
          </Flex>
          <Flex.Item overflowY="auto" shouldShrink={true}>
            <View as="div" padding="0 medium medium medium">
              <View as="div" padding="0 0 medium 0" borderWidth="0 0 small 0">
                <View as="div" margin="0 0 small 0">
                  <Text as="div" weight="bold">
                    {pathway.title}
                  </Text>
                </View>
                <View as="div" margin="0 0 small 0">
                  <Text as="div">{pathway.description}</Text>
                </View>
              </View>
              <View as="div" padding="medium 0" borderWidth="0 0 small 0">
                <Text as="div" weight="bold">
                  Pathway Completion Achievement
                </Text>
                {pathway.completion_award ? (
                  renderCompletionAward(allBadges, pathway.completion_award)
                ) : (
                  <Text>none</Text>
                )}
              </View>
              <View as="div" padding="medium 0" borderWidth="0 0 small 0">
                <Text as="div" weight="bold">
                  Learner Groups
                </Text>
                {pathway.learner_groups.length > 0 ? (
                  <Flex as="div" margin="small 0 0 0" direction="column" gap="small">
                    {pathway.learner_groups.map(group => {
                      return <LearnerGroupCard key={group.id} group={group} />
                    })}
                  </Flex>
                ) : (
                  <Text as="div" color="secondary">
                    No learner groups selected
                  </Text>
                )}
              </View>
              <View as="div" padding="medium 0">
                <Text as="div" weight="bold">
                  Shares
                </Text>
                {renderCanvasUserTable()}
              </View>
            </View>
          </Flex.Item>
          <Flex.Item align="end" width="100%">
            <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
              <Button onClick={onClose}>Close</Button>
            </View>
          </Flex.Item>
        </Flex>
      </Tray>
    </View>
  )
}

export default PathwayViewDetailsTray
