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

import React from 'react'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {ExperienceData} from '../../types'
import {formatDate} from '../../shared/utils'

interface ExperienceCardProps {
  experience: ExperienceData
}
const ExperienceCard = ({experience}: ExperienceCardProps) => {
  return (
    <View as="div" padding="medium" data-testid="experience-card">
      <Text size="x-small" weight="light">
        {formatDate(experience.from_date)} - {formatDate(experience.to_date)}
      </Text>
      <Heading level="h4" margin="small 0 0 0" themeOverride={{h4FontSize: '1.375rem'}}>
        {experience.where}
      </Heading>
      <Text as="div">{experience.title}</Text>
      <View as="div" margin="medium 0 0 0">
        <Text as="div" size="small" wrap="break-word">
          <div dangerouslySetInnerHTML={{__html: experience.description}} />
        </Text>
      </View>
    </View>
  )
}

export default ExperienceCard
