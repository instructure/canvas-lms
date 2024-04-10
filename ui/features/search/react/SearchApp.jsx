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

import React, {useEffect, useRef, useState} from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {IconSearchLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {Pill} from '@instructure/ui-pill'
import {Spinner} from '@instructure/ui-spinner'
import {TextArea} from '@instructure/ui-text-area'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import SearchResults from './SearchResults'

const I18n = useI18nScope('SmartSearch')

export default function SearchApp() {
  const [previousSearch, setPreviousSearch] = useState(null)
  const searchInput = useRef(null)
  const [error, setError] = useState(null)
  const [feedback, setFeedback] = useState({
    action: null,
    comment: '',
    objectId: null,
    objectType: null,
  })
  const [feedbackOpen, setFeedbackOpen] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [searchResults, setSearchResults] = useState([])
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    if (searchInput.current) {
      searchInput.current.focus()
    }
  }, [])

  const onDislike = ({id, type}) => {
    console.debug('dislike', id, type)

    setFeedbackOpen(true)
    setFeedback({...feedback, action: 'DISLIKE', objectId: id, objectType: type})
  }

  const onExplain = ({id, type}) => {
    console.debug('explain', id, type)
  }

  const onLike = ({id, type}) => {
    console.debug('like', id, type)

    setFeedbackOpen(true)
    setFeedback({...feedback, action: 'LIKE', objectId: id, objectType: type})
  }

  const onCloseFeedback = () => {
    setFeedback('')
    setFeedbackOpen(false)
  }

  const onSubmitFeedback = e => {
    e.preventDefault()
    console.debug('submit feedback', feedback)

    fetch(
      `/api/v1/courses/${ENV.COURSE_ID}/smartsearch/log?q=${encodeURIComponent(previousSearch)}&a=${
        feedback.action
      }&oid=${feedback.objectId}&ot=${feedback.objectType}&c=${encodeURIComponent(
        feedback.comment
      )}`
    )
    setFeedback({action: null, comment: '', objectId: null, objectType: null})
    setFeedbackOpen(false)
  }

  const onSearch = e => {
    e.preventDefault()

    if (searchTerm === '') return

    setIsLoading(true)
    setSearchResults([])
    setPreviousSearch(searchTerm)

    fetch(`/api/v1/courses/${ENV.COURSE_ID}/smartsearch?q=${searchTerm}`)
      .then(res => {
        res
          .json()
          .then(({results}) => {
            setSearchResults(results)
          })
          .catch(err => {
            console.error(err)
            setError(err.message)
          })
      })
      .catch(err => {
        console.error(err)
        setError(err.message)
      })
      .finally(() => {
        setIsLoading(false)
      })
  }

  return (
    <View>
      <Modal
        as="form"
        label={I18n.t('Help us Improve!')}
        open={feedbackOpen}
        onDismiss={onCloseFeedback}
        onSubmit={onSubmitFeedback}
        shouldCloseOnDocumentClick={true}
        size="medium"
      >
        <Modal.Header>
          <CloseButton
            onClick={onCloseFeedback}
            offset="small"
            placement="end"
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading level="h2">{I18n.t('Help us Improve!')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <TextArea
            onChange={e => setFeedback({...feedback, comment: e.target.value})}
            label={I18n.t('How do you feel about this search result?')}
            value={feedback.comment}
          />
        </Modal.Body>
        <Modal.Footer>
          <Button margin="0 small 0 0" type="button" onClick={onCloseFeedback}>
            {I18n.t('Cancel')}
          </Button>
          <Button color="primary" type="submit">
            {I18n.t('Submit')}
          </Button>
        </Modal.Footer>
      </Modal>

      {error && (
        <Alert
          margin="medium 0"
          onDismiss={_ => setError(null)}
          renderCloseButtonLabel={I18n.t('Close')}
          variant="error"
        >
          {error}
        </Alert>
      )}

      <Heading level="h1" margin="0 0 medium 0">
        {I18n.t('Smart Search')}
        <Pill color="alert" margin="0 0 0 small" themeOverride={{background: 'alert'}}>
          {I18n.t('Beta')}
        </Pill>
      </Heading>

      <form action="#" method="get" onSubmit={onSearch}>
        <fieldset>
          <TextInput
            inputRef={el => (searchInput.current = el)}
            onChange={e => setSearchTerm(e.target.value)}
            placeholder={I18n.t('Food that a panda eats')}
            renderAfterInput={
              <IconButton
                renderIcon={<IconSearchLine />}
                withBackground={false}
                withBorder={false}
                screenReaderLabel={'Search'}
                type="submit"
              />
            }
            renderLabel=""
          />
        </fieldset>
      </form>

      {isLoading ? (
        <Flex justifyItems="center">
          <Spinner renderTitle={I18n.t('Searching')} />
        </Flex>
      ) : (
        <View display="block" className="searchResults" margin="small 0 0 0">
          <SearchResults
            onDislike={onDislike}
            onExplain={onExplain}
            onLike={onLike}
            searchResults={searchResults}
          />
        </View>
      )}
    </View>
  )
}
