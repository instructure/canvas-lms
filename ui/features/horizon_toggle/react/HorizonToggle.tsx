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

import {ContentChanges} from './contents/ContentChanges'
import {useEffect, useMemo, useState} from 'react'
import {CanvasCareerValidationResponse} from './types'
import {HorizonToggleContext} from './HorizonToggleContext'
import {ContentUnsupported} from './contents/ContentUnsupported'
import {LoadingContainer} from './LoadingContainer'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('horizon_toggle_page')

export const HorizonToggle = () => {
  const [data, setData] = useState<CanvasCareerValidationResponse>({errors: {}})
  const [isLoading, setLoading] = useState(true)
  const [isTermsAccepted, setTermsAccepted] = useState(false)

  useEffect(() => {
    doFetchApi<CanvasCareerValidationResponse>({
      path: `/courses/${ENV.COURSE_ID}/canvas_career_validation`,
    })
      .then(response => setData(response.json!))
      .catch(err => console.log(err))
      .finally(() => setLoading(false))
  }, [])

  const hasUnsupportedContent = useMemo(() => {
    return (
      data?.errors?.discussions ||
      data?.errors?.groups ||
      data?.errors?.outcomes ||
      data?.errors?.collaborations
    )
  }, [data])

  const hasChangesNeededContent = useMemo(() => {
    return data?.errors?.quizzes || data?.errors?.assignments
  }, [data])

  return (
    <View as="div">
      <Text as="p">
        {I18n.t(
          'Canvas Career is a new LMS experience for learners at all career stages. It offers a simplified user interface along with powerful new features, including a notebook for organizing insights, an AI assist tool for personalized guidance, and more.',
        )}
      </Text>
      <View background="secondary" as="div" padding="small" margin="medium 0 0 0" minHeight="300px">
        <Flex direction="column" justifyItems="space-between">
          <HorizonToggleContext.Provider value={data}>
            <Flex direction="column" gap="large" as="div">
              {isLoading && <LoadingContainer />}
              {hasUnsupportedContent && <ContentUnsupported />}
              {hasChangesNeededContent && <ContentChanges />}
              {!hasUnsupportedContent && !hasChangesNeededContent && !isLoading && (
                <View as="div" minHeight="500px">
                  <Text as="p">
                    {I18n.t(
                      'All existing course content is supported. Your course is ready to convert to Canvas Career.',
                    )}
                  </Text>
                </View>
              )}
            </Flex>
          </HorizonToggleContext.Provider>
          <Flex gap="small" direction="column" margin="small 0 0 0" as="div">
            {!isLoading && (
              <Checkbox
                label={I18n.t(
                  'I acknowledge that switching to the Canvas Career learner experience may result in some course content being deleted or modified.',
                )}
                checked={isTermsAccepted}
                onChange={() => setTermsAccepted(!isTermsAccepted)}
              />
            )}
            <Menu.Separator />
            <Flex justifyItems="end">
              <Button color="primary" disabled={isLoading || !isTermsAccepted}>
                {I18n.t('Switch to Canvas Career')}
              </Button>
            </Flex>
          </Flex>
        </Flex>
      </View>
    </View>
  )
}
