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
import React, {useState, useEffect} from 'react'
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

type ReviewModalProps = {
  isOpen: boolean
  onClose: () => void
}

const ReviewModal: React.FC<ReviewModalProps> = ({isOpen, onClose}) => {
  const entry = useInsightStore(state => state.entry)
  const entries = useInsightStore(state => state.entries)
  const setEntry = useInsightStore(state => state.setEntry)
  const [currentPage, setCurrentPage] = useState(1)
  const feedback = useInsightStore(state => state.feedback)

  useEffect(() => {
    if (entries && entry) {
      const initialPage = entries.findIndex(e => e.id === entry.id) + 1
      if (initialPage > 0) {
        setCurrentPage(initialPage)
      }
    }
  }, [entries, entry])

  const handlePageChange = (nextPage: number) => {
    const nextEntry = entries[nextPage - 1]
    setEntry(nextEntry)
    setCurrentPage(nextPage)
  }

  return (
    <Modal
      as="form"
      open={isOpen}
      onDismiss={onClose}
      size="large"
      label={I18n.t('Review Evaluation')}
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <Flex justifyItems="center" alignItems="center">
          <CloseButton
            placement="end"
            offset="medium"
            onClick={onClose}
            screenReaderLabel={I18n.t('Close')}
          />
        </Flex>
        <Heading>{I18n.t('Review Evaluation')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Flex direction="column">
          <Flex display="flex" justifyItems="space-between">
            <Flex direction="column">
              <FlexItem>
                <Text weight="bold">{entry.student_name}</Text>
              </FlexItem>
              <FlexItem>
                <Text color="secondary">{formatDate(new Date(entry.entry_updated_at))}</Text>
              </FlexItem>
            </Flex>
            <Button size="small">{I18n.t('See Reply in Context')}</Button>
          </Flex>
          <FlexItem size="150px" shouldGrow={false} shouldShrink={true}>
            <div dangerouslySetInnerHTML={{__html: entry.entry_content}} />
          </FlexItem>
          <View borderWidth="small" borderRadius="medium" borderColor="primary" as="div">
            <Flex direction="column" padding="medium" gap="mediumSmall">
              <EvaluationFeedback
                relevance={entry.relevance_ai_classification}
                relevanceNotes={entry.relevance_ai_evaluation_notes}
              />
              {feedback === false && <DisagreeFeedback />}
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
