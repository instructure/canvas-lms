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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {Avatar} from '@instructure/ui-avatar'
import {Img} from '@instructure/ui-img'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Link} from '@instructure/ui-link'
import {IconEmailLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {MasteryBucket} from '@canvas/outcomes/react/hooks/useStudentMasteryScores'

const I18n = createI18nScope('OutcomeManagement')

export interface StudentMasteryScoreSummaryProps {
  studentName: string
  studentEmail?: string
  studentAvatarUrl?: string
  masteryLevel?: {
    score: number
    text: string
    description?: string
    iconUrl: string
  }
  buckets?: {
    [key: string]: MasteryBucket
  }
}

const ResultIcon: React.FC<{url: string; alt: string; size?: string}> = ({
  url,
  alt,
  size = '100%',
}) => {
  return (
    <>
      <Img width={size} height={size} src={url} alt={alt} />
      <ScreenReaderContent>{alt}</ScreenReaderContent>
    </>
  )
}

export const StudentMasteryScoreSummary: React.FC<StudentMasteryScoreSummaryProps> = ({
  studentName,
  studentEmail,
  studentAvatarUrl,
  masteryLevel,
  buckets,
}) => {
  return (
    <View as="div" background="primary" data-testid="student-mastery-header" padding="xxx-small">
      <Flex justifyItems="space-between" alignItems="center">
        <Flex.Item shouldGrow>
          <Flex gap="small" alignItems="center">
            <Flex.Item>
              <Avatar
                alt={studentName}
                as="div"
                size="medium"
                name={studentName}
                src={studentAvatarUrl}
                data-testid="student-mastery-avatar"
              />
            </Flex.Item>
            <Flex.Item>
              <View>
                <Text size="x-large" lineHeight="fit">
                  {studentName}
                </Text>
                {studentEmail && (
                  <Flex direction="row" gap="xx-small">
                    <IconEmailLine size="x-small" />
                    <Link href={`mailto:${studentEmail}`} isWithinText={false}>
                      <Text size="medium">{studentEmail}</Text>
                    </Link>
                  </Flex>
                )}
              </View>
            </Flex.Item>
          </Flex>
        </Flex.Item>
        {masteryLevel && (
          <Flex.Item>
            <View shadow="resting" borderRadius="medium" display="inline-block" padding="small">
              <Flex direction="row" alignItems="center" gap="space2">
                <Flex.Item width="4rem">
                  <ResultIcon url={masteryLevel.iconUrl} alt={masteryLevel.text} size="48px" />
                </Flex.Item>
                <Flex.Item>
                  <Flex direction="column">
                    <Flex.Item>
                      <Flex direction="row" gap="xx-small">
                        <Flex.Item padding="0 0 0 space2">
                          <Text size="large" weight="bold" lineHeight="condensed">
                            {masteryLevel.score.toFixed(1)}
                          </Text>
                        </Flex.Item>
                        <Flex.Item>
                          <Text size="medium">{masteryLevel.text}</Text>
                        </Flex.Item>
                      </Flex>
                    </Flex.Item>
                    {buckets && (
                      <Flex.Item>
                        <Flex gap="space24">
                          {Object.values(buckets)
                            .reverse()
                            .map(bucket => (
                              <Flex
                                key={bucket.name}
                                direction="row"
                                alignItems="center"
                                gap="space4"
                              >
                                <ResultIcon url={bucket.iconURL} alt={bucket.name} />
                                <Text size="medium">{bucket.count}</Text>
                              </Flex>
                            ))}
                        </Flex>
                      </Flex.Item>
                    )}
                    <Flex.Item margin="space4 0 0 0">
                      <Text size="small" color="secondary">
                        {I18n.t('Traditional Grade Export')}
                      </Text>
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
              </Flex>
            </View>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}
