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

import React, {useState} from 'react'
import {ePortfolioSection, NamedSubmission} from './types'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useQuery, QueryFunction} from '@tanstack/react-query'
import {Spinner} from '@instructure/ui-spinner'
import {Alert} from '@instructure/ui-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Button} from '@instructure/ui-buttons'
import SubmissionModal from './SubmissionModal'
import {Link} from '@instructure/ui-link'

const I18n = createI18nScope('eportfolio')

interface Props {
  readonly sections: ePortfolioSection[]
  readonly portfolioId: number
  readonly sectionId: number
}

type SubmissionListQueryKey = readonly ['submissionList', number]

const fetchSubmissionList: QueryFunction<NamedSubmission[], SubmissionListQueryKey> = async ({
  queryKey,
}) => {
  const [, portfolioId] = queryKey
  return fetchSubmissions(portfolioId)
}

const fetchSubmissions = async (portfolioId: number): Promise<NamedSubmission[]> => {
  const params = {
    page: 1,
    per_page: '100',
  }
  const {json} = await doFetchApi<NamedSubmission[]>({
    path: `/eportfolios/${portfolioId}/recent_submissions`,
    params,
  })
  return json!
}

export default function SubmissionList(props: Props) {
  const [submission, setSubmission] = useState<NamedSubmission | null>(null)

  const {data, isLoading, error} = useQuery<
    NamedSubmission[],
    Error,
    NamedSubmission[],
    SubmissionListQueryKey
  >({
    queryKey: ['submissionList', props.portfolioId],
    queryFn: fetchSubmissionList,
  })

  const openModal = (submission: NamedSubmission) => {
    setSubmission(submission)
  }

  const closeModal = () => {
    setSubmission(null)
  }

  const renderSubmission = (submission: NamedSubmission) => {
    return (
      <Flex justifyItems="space-between" key={submission.id} margin="small medium">
        <Link
          data-testid={`submission-modal-${submission.id}`}
          isWithinText={false}
          onClick={() => openModal(submission)}
        >
          <Flex gap="x-small">
            <Text size="large">{submission.assignment_name}</Text>
            <Text fontStyle="italic" size="small">
              {submission.course_name}
            </Text>
          </Flex>
        </Link>
        <Flex gap="x-small">
          <Flex direction="column">
            <Text color="secondary" size="x-small">
              {new Intl.DateTimeFormat(ENV.LOCALE, {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
                hour: 'numeric',
                minute: '2-digit',
                hour12: true,
              }).format(new Date(submission.submitted_at))}
            </Text>
            {submission.attachment_count > 0 && (
              <Text fontStyle="italic" size="x-small" color="secondary">
                {I18n.t(
                  {one: '%{count} attachment', other: '%{count} attachments'},
                  {count: submission.attachment_count},
                )}
              </Text>
            )}
          </Flex>
          <Button
            data-testid={`preview-${submission.id}`}
            href={submission.preview_url}
            target="_blank"
            rel="noopener noreferrer"
          >
            {I18n.t('Preview')}
          </Button>
        </Flex>
      </Flex>
    )
  }

  const renderContents = () => {
    if (isLoading) {
      return <Spinner margin="0 auto" renderTitle={I18n.t('Loading submission list')} />
    } else if (error) {
      return (
        <Alert variant="error" margin="0 auto">
          {I18n.t('Could not load submission list')}
        </Alert>
      )
    } else if (!isLoading && data && data.length === 0) {
      return (
        <Text size="medium" fontStyle="italic" color="secondary">
          {I18n.t('No recent submissions')}
        </Text>
      )
    } else {
      return data?.map(submission => renderSubmission(submission))
    }
  }

  return (
    <>
      <View
        margin="small"
        as="div"
        textAlign="center"
        borderRadius="medium"
        borderWidth="small"
        maxHeight="300px"
        overflowY="auto"
      >
        {renderContents()}
      </View>
      <SubmissionModal
        portfolioId={props.portfolioId}
        isOpen={submission != null}
        submission={submission}
        onClose={closeModal}
        sections={props.sections}
        sectionId={props.sectionId}
      />
    </>
  )
}
