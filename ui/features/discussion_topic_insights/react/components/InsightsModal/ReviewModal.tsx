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
import React, {useState, useEffect, useMemo} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex, FlexItem} from '@instructure/ui-flex'
import {formatDate} from '../../utils'
import {Text} from '@instructure/ui-text'
import EvaluationFeedback from './EvaluationFeedback'
import {Pagination} from '@instructure/ui-pagination'
import DisagreeFeedback from './DisagreeFeedback'
import useInsightStore from '../../hooks/useInsightStore'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('discussion_insights')

const ReviewModal = () => {
  const isOpen = useInsightStore(state => state.modalOpen)
  const setModalOpen = useInsightStore(state => state.setModalOpen)
  const entryId = useInsightStore(state => state.entryId)
  const entries = useInsightStore(state => state.entries)
  const openEvaluationModal = useInsightStore(state => state.openEvaluationModal)
  const contextId = useInsightStore(state => state.contextId)
  const discussionId = useInsightStore(state => state.discussionId)

  const [currentPage, setCurrentPage] = useState(1)

  useEffect(() => {
    if (entries && entryId) {
      const initialPage = entries.findIndex(e => e.id === entryId) + 1
      if (initialPage > 0) {
        setCurrentPage(initialPage)
      }
    }
  }, [entries, entryId])

  const {entry, feedback} = useMemo(() => {
    const entry = entries.find(e => e.id === entryId)

    let feedback = null

    if (entry?.relevance_human_feedback_liked) {
      feedback = true
    } else if (entry?.relevance_human_feedback_disliked) {
      feedback = false
    }

    return {entry, feedback}
  }, [entries, entryId])

  if (!entry) {
    return null
  }

  const handleClose = () => {
    setModalOpen(false)
  }

  const handlePageChange = (nextPage: number) => {
    const nextEntry = entries[nextPage - 1]

    if (nextEntry) {
      openEvaluationModal(nextEntry.id, nextEntry.relevance_human_feedback_notes)
      setCurrentPage(nextPage)
    }
  }

  const replyUrl = `/courses/${contextId}/discussion_topics/${discussionId}?entry_id=${entry.entry_id}`

  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={handleClose}
      size="large"
      label={I18n.t('Review Evaluation')}
      data-testid="reviewModal"
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <Flex justifyItems="center" alignItems="center">
          <CloseButton
            placement="end"
            offset="medium"
            onClick={handleClose}
            screenReaderLabel={I18n.t('Close')}
          />
        </Flex>
        <Heading>{I18n.t('Review Evaluation')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column" gap="medium">
          <Flex display="flex" justifyItems="space-between">
            <Flex direction="column">
              <FlexItem>
                <Text weight="bold">{entry.student_name}</Text>
              </FlexItem>
              <FlexItem>
                <Text color="secondary">{formatDate(new Date(entry.entry_updated_at))}</Text>
              </FlexItem>
            </Flex>
            <Button as="a" href={replyUrl} size="small" data-testid="seeReplyInContext">
              {I18n.t('See Reply in Context')}
            </Button>
          </Flex>
          <FlexItem>
            <div
              dangerouslySetInnerHTML={{__html: entry.entry_content.replace(/<\/?p>/g, '')}}
              style={{maxHeight: '150px', overflowY: 'auto', margin: '0'}}
            />
          </FlexItem>
          <View borderWidth="small" borderRadius="medium" borderColor="primary" as="div">
            <Flex direction="column" padding="medium" gap="mediumSmall">
              <EvaluationFeedback
                entryId={entryId}
                relevance={entry.relevance_ai_classification}
                relevanceNotes={entry.relevance_ai_evaluation_notes}
                feedback={feedback}
              />
              {feedback === false && !entry.relevance_human_feedback_notes && (
                <DisagreeFeedback entryId={entryId} />
              )}
            </Flex>
          </View>
          <Pagination
            as="nav"
            variant="input"
            labelNext="Next Page"
            labelPrev="Previous Page"
            currentPage={currentPage}
            totalPageNumber={entries.length}
            onPageChange={handlePageChange}
          />
        </Flex>
      </Modal.Body>
    </Modal>
  )
}

export default ReviewModal
