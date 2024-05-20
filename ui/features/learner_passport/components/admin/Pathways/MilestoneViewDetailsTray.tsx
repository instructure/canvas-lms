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

import React, {useContext} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import type {MilestoneData} from '../../types'
import {renderCompletionAward} from './edit/AddBadgeTray'
import MilestoneRequirementCard from './edit/requirements/MilestoneRequirementCard'
import {DataContext} from './PathwayEditDataContext'

type MilestoneViewTrayProps = {
  milestone: MilestoneData | null
  open: boolean
  onClose: () => void
}

const MilestoneViewTray = ({milestone, open, onClose}: MilestoneViewTrayProps) => {
  const {allBadges} = useContext(DataContext)

  return (
    <Tray label="Step Details" open={open} size="regular" placement="end" onDismiss={onClose}>
      <Flex as="div" direction="column" height="100vh">
        <Flex as="div" padding="small small medium medium">
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h2" margin="0 0 small 0">
              Step Details
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
        <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="auto">
          {milestone && (
            <View as="div" padding="0 medium medium medium">
              <View as="div" padding="0 0 medium 0" borderWidth="0 0 small 0">
                <View as="div" margin="0 0 small 0">
                  <Text as="div" weight="bold">
                    {milestone.title}
                  </Text>
                </View>
                <View as="div" margin="0 0 small 0">
                  <Text as="div">{milestone.description}</Text>
                </View>
                <View as="div" margin="0 0 small 0">
                  {!milestone.required && (
                    <Text as="div" weight="bold">
                      Optional
                    </Text>
                  )}
                </View>
              </View>
              <View as="div" padding="large 0" borderWidth="0 0 small 0">
                <Text as="div" weight="bold">
                  Requirements
                </Text>
                <View as="div" margin="0 0 small 0">
                  {milestone.requirements.length > 0 ? (
                    <View as="div" margin="small 0">
                      {milestone.requirements.map(requirement => (
                        <View
                          key={requirement.id}
                          as="div"
                          padding="small"
                          background="secondary"
                          borderWidth="small"
                          borderRadius="medium"
                          margin="0 0 small 0"
                        >
                          <MilestoneRequirementCard
                            key={requirement.id}
                            variant="view"
                            requirement={requirement}
                          />
                        </View>
                      ))}
                    </View>
                  ) : (
                    <Text as="div">None</Text>
                  )}
                </View>
              </View>
              {milestone.completion_award && (
                <View as="div" padding="large 0 0 0">
                  <Text as="div" weight="bold">
                    Completion Award
                  </Text>
                  {milestone.completion_award &&
                    renderCompletionAward(allBadges, milestone.completion_award)}
                </View>
              )}
            </View>
          )}
        </Flex.Item>
        <Flex.Item align="end" width="100%">
          <View as="div" padding="small medium" borderWidth="small 0 0 0" textAlign="end">
            <Button onClick={onClose}>Close</Button>
          </View>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

export default MilestoneViewTray
