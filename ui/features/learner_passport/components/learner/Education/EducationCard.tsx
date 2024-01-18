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

import type {EducationData} from '../../types'
import {formatDate} from '../../shared/utils'

interface EducationCardProps {
  education: EducationData
}

const EducationCard = ({education}: EducationCardProps) => {
  return (
    <View as="div" padding="medium" data-testid="education-card">
      <Text size="x-small" weight="light">
        {formatDate(education.from_date)} - {formatDate(education.to_date)}
      </Text>
      <Heading level="h4" margin="small 0" themeOverride={{h4FontSize: '1.375rem'}}>
        {education.institution}
      </Heading>
      <Text as="div">
        {education.city}, {education.state}
      </Text>
      {education.title && <Text as="div">{education.title}</Text>}
      {education.gpa && <Text as="div">GPA: {education.gpa}</Text>}
    </View>
  )
}

export default EducationCard
