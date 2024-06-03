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

import React, {useEffect, useRef, useState, useCallback} from 'react'
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
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import SearchResults from './SearchResults'
import IndexingProgress from './IndexingProgress'

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
  const [indexingProgress, setIndexingProgress] = useState(null)
  const [isTrayOpen, setIsTrayOpen] = useState(false)

  useEffect(() => {
    doUrlSearch(false)  // init the box but don't actually do the search until we've checked index status
    if (searchInput.current) {
      searchInput.current.focus()
    }
  }, [])

  const checkIndexStatus = useCallback(() => {
    fetch(`/api/v1/courses/${ENV.COURSE_ID}/smartsearch/index_status`).then(res => {
      res.json().then(({status, progress}) => {
        if (status === 'indexing') {
          setIndexingProgress(progress)
          setTimeout(checkIndexStatus, 2000)
        } else {
          setIndexingProgress(null)
          doUrlSearch()
        }
      })
    })
  }, [])

  const doUrlSearch = useCallback((perform = true) => {
    const url = new URL(window.location.href)
    const searchTerm = url.searchParams.get('q')
    if (searchTerm && searchTerm.length && searchInput.current) {
      searchInput.current.value = searchTerm
      if (perform) {
        onSearch()
      }
    }
  }, [])

  useEffect(() => {
    checkIndexStatus()
    window.addEventListener('popstate', doUrlSearch)
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
    e?.preventDefault()

    if (!searchInput.current) return

    const searchTerm = searchInput.current.value.trim()
    if (searchTerm === '') return

    setIsLoading(true)
    setSearchResults([])
    setPreviousSearch(searchTerm)

    const url = new URL(window.location.href);
    if (url.searchParams.get('q') !== searchTerm) {
      url.searchParams.set('q', searchTerm);
      window.history.pushState({}, '', url);
    }

    fetch(`/api/v1/courses/${ENV.COURSE_ID}/smartsearch?q=${searchTerm}&per_page=25`)
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
        <Flex justifyItems="space-between">
          <Flex.Item>
            {I18n.t('Smart Search')}
            <Pill color="alert" margin="0 0 0 small" themeOverride={{background: 'alert'}}>
              {I18n.t('Beta')}
            </Pill>
          </Flex.Item>
          <Flex.Item>
            <Button
            onClick={ _ => setIsTrayOpen(true) }
            >{I18n.t('How It Works')}</Button>
          </Flex.Item>
        </Flex>
      </Heading>

      <form action="#" method="get" onSubmit={onSearch}>
        <fieldset>
          <TextInput
            inputRef={el => (searchInput.current = el)}
            placeholder={I18n.t('Food that a panda eats')}
            renderAfterInput={
              <IconButton
                interaction={indexingProgress ? 'disabled' : 'enabled'}
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

      {indexingProgress !== null ? (
        <IndexingProgress progress={indexingProgress} />
      ) : isLoading ? (
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
            searchTerm={previousSearch}
          />
        </View>
      )}
      <Tray
        label={I18n.t('How It Works')}
        open={isTrayOpen}
        onDismiss={_ => { setIsTrayOpen(false)}}
        size="regular"
        placement="end"
      >
        <View as="div" padding="medium">
          <Flex>
            <Flex.Item>
              <CloseButton
                placement="end"
                offset="small"
                screenReaderLabel="Close"
                onClick={_ => { setIsTrayOpen(false)}}
              />
            </Flex.Item>
            <Flex.Item>
              <h3>{I18n.t('What is Smart Search?')}</h3>
              <p>{I18n.t('Smart Search is a feature of Canvas that is currently in development.  Leveraging semantic algorithms and AI, the new Smart Search feature understands the context of queries, providing more accurate and relevant results without the need for traditional boolean operators or other search tools.')}</p>
              <h3>{I18n.t('How do I use the Search feature?')}</h3>
              <p>{I18n.t('Our Smart Search feature relies on an AI-adjacent technology called “embeddings.” This technology “reads” the course content and creates a complex mathematical representation of each piece of content. When you perform a search, the technology “reads” your query and converts it into a complex mathematical representation. The tool then compares the mathematical representations of both your search and course content to return relevant results.')}</p>
              <p>{I18n.t('Because Smart Search operates on “understanding” both the content and the queries, you can type in keyword(s), content, or just give a general gist of what you are looking for (“guitar”, “what are the steps of photosynthesis?”, “math to turn a function into frequencies“). We think you will be surprised at how well the system understands the intent of your queries and returns results accordingly.')}</p>
              <p>{I18n.t('Additionally, the AI model we are using to power this feature is multilingual. This means that you can search in whatever language you like, and the most relevant content will be returned no matter what language it was written in. Give it a try!')}</p>
              <h3>{I18n.t('What content is searchable?')}</h3>
              <p>{I18n.t('As of June 1, 2024, the Smart Search feature is querying the following items (including titles) within a course: content pages, announcements, discussion prompts, assignment descriptions.')}</p>
              <p>{I18n.t('The intention is to expand this scope as the Smart Search tool continues development.')}</p>
              <h3>{I18n.t('How can I help with the development of this feature?')}</h3>
              <p>{I18n.t('Ultimately, this feature is still classified as an experimental beta. We want to provide opportunities for participants to provide feedback. Clicking thumbs up and thumbs down on your search results and telling us why the results are good or bad will help us determine when results should or shouldn’t be shown to you. You can also provide feedback in our Canvas Community space for Smart Search Beta.')}</p>
            </Flex.Item>
          </Flex>
        </View>
      </Tray>
    </View>
  )
}
