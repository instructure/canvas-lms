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
  const [resolveFeedback, setResolveFeedback] = useState(null)

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
    return new Promise(resolve => setResolveFeedback(() => resolve))
  }

  const onExplain = ({id, type}) => {
    console.debug('explain', id, type)
  }

  const onLike = ({id, type}) => {
    console.debug('like', id, type)

    setFeedbackOpen(true)
    setFeedback({...feedback, action: 'LIKE', objectId: id, objectType: type})
    return new Promise(resolve => setResolveFeedback(() => resolve))
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
    if (resolveFeedback) {
      resolveFeedback()
    }
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
        if(!res.ok) {
          throw new Error(I18n.t('Failed to execute search: ') + res.statusText)
        }
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
              {I18n.t('Feature Preview')}
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
              <h3>{I18n.t('About Smart Search')}</h3>
              <p>{I18n.t('Smart Search, currently in development for Canvas, uses semantic algorithms and AI to understand query context and semantic meaning, not just keyword matching.')}</p>
              <h3>{I18n.t('Using Smart Search')}</h3>
              <p>{I18n.t('Smart Search employs "embeddings" to mathematically represent content and queries for comparison, understanding keywords or general queries in any language, thanks to its multilingual AI model. Write search queries using keywords, questions, sentences, or whatever is most natural for you to describe what you are trying to find.')}</p>
              <h3>{I18n.t('Searchable Content')}</h3>
              <p>{I18n.t('As of June 1, 2024, searchable items include content pages, announcements, discussion prompts, and assignment descriptions, with plans to expand.')}</p>
              <h3>{I18n.t('Contributing to Development')}</h3>
              <p>{I18n.t('Smart Search is in feature preview. Feedback can be provided through result ratings and the Canvas Community space for Smart Search Beta. Canvas community space can be found here: ')}<a href="https://community.canvaslms.com/t5/Smart-Search/gh-p/smart_search" target="_blank">{I18n.t('Smart Search Community')}</a></p>
            </Flex.Item>
          </Flex>
        </View>
      </Tray>
    </View>
  )
}
