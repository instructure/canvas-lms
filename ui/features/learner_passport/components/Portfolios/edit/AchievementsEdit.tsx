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

import React, {useCallback, useState} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconAddLine, IconDragHandleLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {View} from '@instructure/ui-view'

import type {AchievementData, PortfolioDetailData} from '../../types'
import AchievementCard from '../../Achievements/AchievementCard'

const AchievementEditCard = (achievement: AchievementData) => {
  return (
    <View as="div" borderWidth="small" shadow="resting">
      <Flex as="div" alignItems="stretch">
        <Flex.Item shouldShrink={false} shouldGrow={false}>
          <View as="div" position="relative" width="26px" height="100%" background="secondary">
            <div
              style={{
                position: 'absolute',
                top: '50%',
                left: '50%',
                transform: 'translate(-50%, -50%)',
              }}
            >
              <IconDragHandleLine inline={false} />
            </div>
          </View>
        </Flex.Item>
        <Flex.Item shouldShrink={false} shouldGrow={false}>
          <AchievementCard
            isNew={false}
            title={achievement.title}
            issuer={achievement.issuer.name}
            imageUrl={achievement.imageUrl}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}

function renderAchievements(achievements: AchievementData[]) {
  return achievements.map((achievement: AchievementData) => {
    return (
      <Flex.Item key={achievement.id} shouldShrink={false}>
        <AchievementEditCard {...achievement} />
      </Flex.Item>
    )
  })
}

type AchievementsEditProps = {
  portfolio: PortfolioDetailData
}

const AchievementsEdit = ({portfolio}: AchievementsEditProps) => {
  const [expanded, setExpanded] = useState(true)

  const handleToggle = useCallback((_event: React.MouseEvent, toggleExpanded: boolean) => {
    setExpanded(toggleExpanded)
  }, [])

  return (
    <ToggleDetails
      summary={
        <View as="div" margin="small 0">
          <Heading level="h2" themeOverride={{h2FontSize: '1.375rem'}}>
            Achievements
          </Heading>
        </View>
      }
      variant="filled"
      expanded={expanded}
      onToggle={handleToggle}
    >
      <View as="div" margin="medium 0 large 0">
        <View as="div">
          <Text size="small">
            Add verified badges, degrees, certificates, and awards from your achievements
          </Text>
        </View>
        <View as="div" margin="medium 0 0 0">
          <Button renderIcon={IconAddLine}>Add achievement</Button>
        </View>
        <Flex as="div" margin="medium 0 0 0" gap="medium" wrap="wrap">
          {portfolio.achievements.length > 0 ? renderAchievements(portfolio.achievements) : null}
        </Flex>
      </View>
    </ToggleDetails>
  )
}

export default AchievementsEdit
