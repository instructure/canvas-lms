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
import {useCallback, useEffect, useMemo, useState} from 'react'
import {CanvasCareerValidationResponse, CompletionProgressResponse} from './types'
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
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

const I18n = createI18nScope('horizon_toggle_page')

const timeout = (delay: number) => {
  return new Promise(resolve => setTimeout(resolve, delay))
}

export const HorizonToggle = () => {
  const [data, setData] = useState<CanvasCareerValidationResponse>({errors: {}})
  const [progress, setProgress] = useState<Partial<CompletionProgressResponse>>({url: ''})
  const [loadingText, setLoadingText] = useState<string>(I18n.t('Checking course content...'))
  const [isTermsAccepted, setTermsAccepted] = useState(false)

  useEffect(() => {
    doFetchApi<CanvasCareerValidationResponse>({
      path: `/courses/${ENV.COURSE_ID}/canvas_career_validation`,
    })
      .then(response => setData(response.json!))
      .catch(err => showFlashAlert({message: err.message}))
      .finally(() => setLoadingText(''))
  }, [])

  const hasUnsupportedContent = useMemo(() => {
    return (
      data?.errors?.discussions ||
      data?.errors?.groups ||
      data?.errors?.outcomes ||
      data?.errors?.collaborations ||
      data?.errors?.quizzes
    )
  }, [data])

  const hasChangesNeededContent = useMemo(() => {
    return data?.errors?.assignments
  }, [data])

  const fetchProgress = useCallback(async () => {
    if (!progress?.url) return
    try {
      const response = await doFetchApi<CompletionProgressResponse>({
        path: progress?.url!,
        method: 'GET',
      })
      const json = response.json!
      await timeout(1000)
      if (json.workflow_state === 'completed' || json.workflow_state === 'failed') {
        window.location.reload()
      } else {
        await fetchProgress()
      }
      setProgress(json)
    } catch (e: any) {
      showFlashAlert({
        message: I18n.t('Could not convert course to Canvas Career. Please try again.'),
        type: 'error',
      })
    }
  }, [progress])

  const onSubmit = useCallback(async () => {
    setLoadingText(I18n.t('Converting course to Canvas Career...'))
    try {
      const response = await doFetchApi<CompletionProgressResponse>({
        path: `/courses/${ENV.COURSE_ID}/canvas_career_conversion`,
        method: 'POST',
      })
      const json = response.json!
      if (json.success) {
        window.location.reload()
      }
      if (json.errors) {
        showFlashAlert({
          message: json.errors,
          type: 'error',
        })
        setLoadingText('')
      }
      if (json.workflow_state) {
        setProgress(json)
      }
    } catch (e: any) {
      showFlashAlert({
        message: I18n.t('Could not convert course to Canvas Career. Please try again.'),
        type: 'error',
      })
      setLoadingText('')
    }
  }, [])

  useEffect(() => {
    if (
      progress &&
      progress?.workflow_state !== 'completed' &&
      progress?.workflow_state !== 'failed'
    ) {
      fetchProgress()
    } else if (
      (progress && progress?.workflow_state === 'completed') ||
      progress?.workflow_state === 'failed'
    ) {
      window.location.reload()
    }
  }, [progress, fetchProgress])

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
              {loadingText ? (
                <LoadingContainer loadingText={loadingText} />
              ) : (
                <>
                  {hasUnsupportedContent && <ContentUnsupported />}
                  {hasChangesNeededContent && <ContentChanges />}
                </>
              )}
              {!hasUnsupportedContent && !hasChangesNeededContent && !loadingText && (
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
            {!loadingText && (
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
              <Button
                color="primary"
                disabled={!!loadingText || !isTermsAccepted}
                onClick={onSubmit}
              >
                {I18n.t('Switch to Canvas Career')}
              </Button>
            </Flex>
          </Flex>
        </Flex>
      </View>
    </View>
  )
}
