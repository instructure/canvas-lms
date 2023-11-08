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

import React, {useEffect, useState, useCallback, useRef} from 'react'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {List} from '@instructure/ui-list'
import {Alert} from '@instructure/ui-alerts'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'

const {Item: ListItem} = List as any

const I18n = useI18nScope('content_migrations_redesign')

export type MigrationIssue = {
  id: number
  description: string
  workflow_state: 'active' | 'resolved'
  fix_issue_html_url: string | null
  issue_type: 'todo' | 'warning' | 'error'
  created_at: string
  updated_at: string
  content_migration_url: string
  error_message: string | null
}

type MigrationIssuesResponse = MigrationIssue[]

type ActionButtonProps = {
  migration_type_title: string
  migration_issues_count: number
  migration_issues_url: string
}

type MigrationIssuesModalProps = {
  open: boolean
  migration_type_title: string
  migration_issues_url: string
  migration_issues_count: number
  onClose: () => void
}

const buildButton = (migration_issues_count: number, onClose: () => void) => {
  if (migration_issues_count > 0) {
    return (
      <Button withBackground={false} color="secondary" onClick={onClose}>
        {I18n.t('View Issues')}
      </Button>
    )
  }
  return null
}

const ISSUES_PAGE_SIZE = 10

const MigrationIssuesModal = ({
  open,
  migration_type_title,
  migration_issues_url,
  migration_issues_count,
  onClose,
}: MigrationIssuesModalProps) => {
  const currentPage = useRef(1)
  const [haveNextPage, setHaveNextPage] = useState(false)
  const [issues, setIssues] = useState<MigrationIssuesResponse | null>(null)
  const [hasErrors, setHasErrors] = useState(false)
  const [isLoadingMoreIssues, setIsLoadingMoreIssues] = useState(false)

  const handleShowMore = useCallback(() => {
    setIsLoadingMoreIssues(true)
    const url = new URL(migration_issues_url)
    currentPage.current += 1
    url.searchParams.set('page', currentPage.current.toString())
    url.searchParams.set('per_page', ISSUES_PAGE_SIZE.toString())
    doFetchApi({path: url.toString(), method: 'GET'})
      .then(({json}: {json: MigrationIssuesResponse}) => {
        if (issues) {
          const newIssues = issues.concat(json)
          setIssues(newIssues)
          setHaveNextPage(newIssues.length < migration_issues_count)
        }
      })
      .catch(() => setHasErrors(true))
      .finally(() => setIsLoadingMoreIssues(false))
  }, [migration_issues_url, migration_issues_count, issues])

  const fetchIssues = useCallback(
    () =>
      migration_issues_url &&
      doFetchApi({path: migration_issues_url, method: 'GET'})
        .then(({json}: {json: MigrationIssuesResponse}) => {
          setIssues(json)
          setHaveNextPage(json.length < migration_issues_count)
        })
        .catch(() => setHasErrors(true)),
    [migration_issues_url, migration_issues_count]
  )

  useEffect(() => {
    if (open && !issues) fetchIssues()
  }, [open, issues, fetchIssues])

  let content
  if (issues && !hasErrors) {
    content = (
      <>
        <List as="ol" isUnstyled={true}>
          {issues.map(({id, description, fix_issue_html_url}) => (
            <ListItem key={id}>
              {fix_issue_html_url ? (
                <Link href={fix_issue_html_url}>{description}</Link>
              ) : (
                <Text>{description}</Text>
              )}
            </ListItem>
          ))}
        </List>
        {haveNextPage && (
          <View as="div" textAlign="center">
            {isLoadingMoreIssues ? (
              <Spinner renderTitle={() => I18n.t('Loading more issues')} size="x-small" />
            ) : (
              <View as="div" textAlign="center">
                <Link onClick={handleShowMore} isWithinText={false}>
                  <Text weight="bold">{I18n.t('Show More')}</Text>
                </Link>
              </View>
            )}
          </View>
        )}
      </>
    )
  } else if (hasErrors) {
    content = (
      <Alert variant="error" margin="small">
        {I18n.t('Failed to fetch migration issues data.')}
      </Alert>
    )
  } else {
    content = (
      <View display="block" padding="large" textAlign="center">
        <Spinner renderTitle={() => I18n.t('Loading issues')} />
      </View>
    )
  }

  return (
    <Modal
      open={open}
      onDismiss={onClose}
      size="medium"
      label={I18n.t('%{migration_type_title} Issues Modal', {migration_type_title})}
      shouldCloseOnDocumentClick={true}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('%{migration_type_title} Issues', {migration_type_title})}</Heading>
      </Modal.Header>
      <Modal.Body>{content}</Modal.Body>
      <Modal.Footer>
        <Button onClick={onClose} color="primary">
          {I18n.t('Close')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export const ActionButton = ({
  migration_type_title,
  migration_issues_count,
  migration_issues_url,
}: ActionButtonProps) => {
  const [modalOpen, setModalOpen] = useState(false)

  const button = buildButton(migration_issues_count, () => setModalOpen(true))
  return (
    <>
      {button}
      <MigrationIssuesModal
        open={modalOpen}
        migration_type_title={migration_type_title}
        migration_issues_url={migration_issues_url}
        migration_issues_count={migration_issues_count}
        onClose={() => setModalOpen(false)}
      />
    </>
  )
}
