/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {useState, useEffect, useReducer, useRef, useCallback} from 'react'
import {string, func, object} from 'prop-types'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-layout'
import {Avatar, Img, Spinner, Text} from '@instructure/ui-elements'
import {Pagination} from '@instructure/ui-pagination'
import {Tooltip} from '@instructure/ui-overlays'
import {debounce} from 'lodash'
import formatMessage from '../../../../format-message'
import {StyleSheet, css} from 'aphrodite'

import UnsplashSVG from './UnsplashSVG'

const unsplashFetchReducer = (state, action) => {
  switch (action.type) {
    case 'FETCH':
      return {...state, loading: true}
    case 'FETCH_SUCCESS':
      return {
        ...state,
        loading: false,
        totalPages: action.payload.total_pages,
        results: {
          ...state.results,
          ...{[state.searchPage]: action.payload.results}
        }
      }
    case 'FETCH_FAILURE':
      return {...state, loading: false, error: true}
    case 'SET_SEARCH_DATA': {
      const newState = {...state, ...action.payload}
      if (state.searchTerm !== action.payload.searchTerm) {
        newState.results = {}
      }
      return newState
    }
    default:
      throw new Error('Not implemented') // Should never get here.
  }
}

const useUnsplashSearch = source => {
  const [state, dispatch] = useReducer(unsplashFetchReducer, {
    loading: false,
    error: false,
    results: {},
    totalPages: 1,
    searchTerm: '',
    searchPage: 1
  })

  const effectFirstRun = useRef(true)

  useEffect(() => {
    const fetchData = () => {
      dispatch({type: 'FETCH'})
      source
        .searchUnsplash(state.searchTerm, state.searchPage)
        .then(results => {
          dispatch({type: 'FETCH_SUCCESS', payload: results})
        })
        .catch(() => {
          dispatch({type: 'FETCH_FAILURE'})
        })
    }
    if (effectFirstRun.current) {
      effectFirstRun.current = false
      return
    } else if (state.results[state.searchPage]) {
      return // It's already in cache
    } else {
      fetchData()
    }
  }, [state.searchTerm, state.searchPage])

  const search = (term, page) => {
    dispatch({
      type: 'SET_SEARCH_DATA',
      payload: {
        searchTerm: term,
        searchPage: page
      }
    })
  }

  return {...state, search}
}

function Attribution({name, avatarUrl}) {
  return (
    <Flex>
      <Flex.Item margin="xx-small">
        <Avatar name={name} src={avatarUrl} />
      </Flex.Item>
      <Flex.Item margin="xx-small">
        <Text>{name}</Text>
      </Flex.Item>
    </Flex>
  )
}

export default function UnsplashPanel({editor, source, setUnsplashData}) {
  const [page, setPage] = useState(1)
  const [term, setTerm] = useState('')
  const [selectedImage, setSelectedImage] = useState(null)
  const [focusedImageIndex, setFocusedImageIndex] = useState(0)
  const {totalPages, results, loading, search} = useUnsplashSearch(source)

  const debouncedSearch = useCallback(debounce(search, 250), [])

  const resultRefs = []
  const skipEffect = useRef(false)

  useEffect(() => {
    if (skipEffect.current) {
      skipEffect.current = false
      return
    }
    if (resultRefs[focusedImageIndex]) {
      resultRefs[focusedImageIndex].focus()
    }
  }, [focusedImageIndex])

  return (
    <>
      <UnsplashSVG width="10em" />
      <TextInput
        type="search"
        label={formatMessage('Search Term')}
        value={term}
        onChange={(e, val) => {
          setFocusedImageIndex(0)
          setTerm(val)
          debouncedSearch(val, page)
        }}
      />
      {loading ? (
        <Spinner
          renderTitle={function() {
            return formatMessage('Loading')
          }}
          size="large"
          margin="0 0 0 medium"
        />
      ) : (
        <>
          <div
            className={css(styles.container)}
            role="radiogroup"
            onBlur={e => {
              if (!e.currentTarget.contains(e.relatedTarget)) {
                let newIndex = 0
                const selectedIndex = results[page].findIndex(result => result.id === selectedImage)
                if (selectedIndex > 0) {
                  newIndex = selectedIndex
                }
                setFocusedImageIndex(newIndex)
                skipEffect.current = true
              }
            }}
          >
            {results[page] &&
              results[page].map((resultImage, index) => (
                <Tooltip
                  key={resultImage.id}
                  on={['click', 'hover', 'focus']}
                  tip={
                    <Attribution name={resultImage.user.name} avatarUrl={resultImage.user.avatar} />
                  }
                >
                  <div
                    ref={c => (resultRefs[index] = c)}
                    key={resultImage.id}
                    className={css(
                      styles.imageContainer,
                      resultImage.id === selectedImage && styles.imageContainerChecked
                    )}
                    role="radio"
                    aria-checked={resultImage.id === selectedImage}
                    tabIndex={index === focusedImageIndex ? 0 : -1}
                    onClick={() => {
                      setSelectedImage(resultImage.id)
                      let newIndex = 0
                      const selectedIndex = results[page].findIndex(
                        result => result.id === resultImage.id
                      )
                      if (selectedIndex > 0) {
                        newIndex = selectedIndex
                      }
                      setFocusedImageIndex(newIndex)
                      setUnsplashData({
                        id: resultImage.id,
                        url: resultImage.urls.link
                      })
                    }}
                    onKeyDown={e => {
                      switch (e.keyCode) {
                        case 32: // Space
                          setSelectedImage(resultImage.id)
                          setUnsplashData({
                            id: resultImage.id,
                            url: resultImage.urls.link
                          })
                          break
                        case 38: // Up
                          if (index - 1 < 0) {
                            setFocusedImageIndex(results[page].length - 1)
                          } else {
                            setFocusedImageIndex(index - 1)
                          }
                          break
                        case 40: // Down
                          if (index + 1 >= results[page].length) {
                            setFocusedImageIndex(0)
                          } else {
                            setFocusedImageIndex(index + 1)
                          }
                          break
                        default:
                          break
                      }
                    }}
                  >
                    <Img
                      src={resultImage.urls.thumbnail}
                      alt={resultImage.alt_text}
                      height={resultImage.id === selectedImage ? '9.5em' : '10em'}
                      margin={resultImage.id === selectedImage ? 'small' : 'xx-small'}
                    />
                  </div>
                </Tooltip>
              ))}
          </div>
          {totalPages > 1 && results && Object.keys(results).length > 0 && (
            <Flex as="div" width="100%" justifyItems="center" margin="small 0 small">
              <Flex.Item margin="auto small auto small">
                <Pagination
                  as="nav"
                  variant="compact"
                  labelNext={formatMessage('Next Page')}
                  labelPrev={formatMessage('Previous Page')}
                >
                  {Array.from(Array(totalPages)).map((_v, i) => (
                    <Pagination.Page
                      key={i}
                      onClick={() => {
                        setPage(i + 1)
                        search(term, i + 1)
                      }}
                      current={i + 1 === page}
                    >
                      {i + 1}
                    </Pagination.Page>
                  ))}
                </Pagination>
              </Flex.Item>
            </Flex>
          )}
        </>
      )}
    </>
  )
}

UnsplashPanel.propTypes = {
  editor: object,
  source: object,
  imageUrl: string,
  setImageUrl: func
}

export const styles = StyleSheet.create({
  container: {
    marginTop: '12px',
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    flexWrap: 'wrap',
    flexFlow: 'row wrap'
  },
  imageContainer: {
    width: 'auto',
    height: '100%'
  },
  imageContainerChecked: {
    border: '.25em solid black'
  },
  positionedText: {
    position: 'absolute',
    height: '100%',
    width: '100%',
    top: '0',
    left: '0'
  }
})
