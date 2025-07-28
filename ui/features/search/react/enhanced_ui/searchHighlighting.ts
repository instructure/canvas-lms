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

import stopwords from '../stopwords'

const MAX_NUMBER_OF_SEGMENTS = 2
const SEGMENT_LENGTH = 24
// number of words to iterate by; the lower the value, the more accurate segments will be
// the tradeoff is performance, so keep this value high
const GRANULARITY = 6

const DEFAULTS = {
  segmentLength: SEGMENT_LENGTH,
  maxSegments: MAX_NUMBER_OF_SEGMENTS,
  granularity: GRANULARITY,
}

type Segment = {
  segment: string[]
  concentration: number
  highlightedIndex: number
  segmentIndex: number
  concatSegment: string
}

export const getConcentratedSegments = (
  searchExpression: RegExp,
  words: string[],
  overrides: {segmentLength: number; maxSegments: number; granularity: number} = DEFAULTS,
) => {
  // Calculate the concentration of highlighted words in each segment
  const segments: Segment[] = []
  const {segmentLength, maxSegments, granularity} = overrides

  if (words.length > maxSegments * (segmentLength + 1)) {
    const halfLength = Math.floor(segmentLength / 2)
    for (let i = halfLength; i <= words.length - halfLength; i += granularity) {
      // find index of a segment that matches the search term
      const segment = words.slice(i - halfLength, i + halfLength + 1)
      const highlightedIndices: number[] = []
      segment.forEach((word: string, index: number) => {
        if (searchExpression.test(word)) {
          highlightedIndices.push(index)
        }
      })
      const highlightCount = highlightedIndices.length

      const concatSegment = segment.join(' ')
      segments.push({
        segment,
        concentration: highlightCount,
        highlightedIndex: highlightedIndices[0],
        segmentIndex: (i - halfLength) / granularity,
        concatSegment,
      })
    }

    segments.sort((a, b) => {
      // sort by concentration first (highest first)
      const diff = b.concentration - a.concentration
      if (diff !== 0) {
        return diff
      } else if (a.segment.length !== b.segment.length) {
        // next by segment length (longest first)
        return b.segment.length - a.segment.length
      } else {
        // finally sort by highlighted term index (closest to middle first)
        const aDiff = a.highlightedIndex - halfLength
        const bDiff = b.highlightedIndex - halfLength
        return Math.abs(aDiff) - Math.abs(bDiff)
      }
    })
    const segmentsToKeep: Segment[] = []
    segments.forEach(segmentRecord => {
      const numOfKept = segmentsToKeep.length
      if (segmentsToKeep.length === 0) {
        segmentsToKeep.push(segmentRecord)
      } else if (segmentsToKeep.length < maxSegments) {
        const wordIndex = segmentRecord.segmentIndex * granularity + halfLength
        const prevIndex = segmentsToKeep[numOfKept - 1].segmentIndex * granularity + halfLength
        if (wordIndex > prevIndex + segmentLength || wordIndex < prevIndex - segmentLength) {
          segmentsToKeep.push(segmentRecord)
        }
      }
    })

    segmentsToKeep.sort((a, b) => a.segmentIndex - b.segmentIndex)

    let truncatedText = ''
    segmentsToKeep.forEach((segmentRecord, index) => {
      // in case the max number of segments is greater than the number of segments
      // with any relevance to the query
      if (segmentRecord.concentration !== 0 || index === 0) {
        const segmentIndex = segmentRecord.segmentIndex
        let text = segmentRecord.concatSegment
        // after first segment
        if (segmentIndex !== 0 && index === 0) {
          text = '...' + text
        }
        // before last segment
        const wordsIndex = segmentIndex * granularity + halfLength
        if (wordsIndex < words.length - 1 - halfLength) {
          text += '...'
        }
        truncatedText += text
      }
    })

    return truncatedText
  } else {
    return words.join(' ')
  }
}

export const splitSearchAndResult = (text: string, searchTerm: string) => {
  // Split the searchTerm into tokens
  const searchTerms = searchTerm.split(' ')

  // Filter out single character search terms and common words
  const validSearchTerms = searchTerms.filter(
    term => term.length > 1 && !stopwords.includes(term.toLowerCase()),
  )

  // Escape each searchTerm and join them with '|'
  const escapedSearchTerms = validSearchTerms
    .map(term => term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'))
    .join('|')

  // Create a RegExp that matches any of the searchTerms
  // TODO: prefix this regex with a word boundry \\b to avoid substrings
  // or figure out a way to remove stop words from the search terms
  const searchExpression = new RegExp(`(${escapedSearchTerms})`, 'gi')

  // Remove HTML tags and split the text into words
  const words = text.replace(/<[^>]*>/gm, '').split(' ')

  return {words, searchExpression}
}

export const addSearchHighlighting = (searchTerm: string, text: string) => {
  const {words, searchExpression} = splitSearchAndResult(text, searchTerm)
  const truncatedText = getConcentratedSegments(searchExpression, words)

  return truncatedText.replace(
    searchExpression,
    '<span data-testid="highlighted-search-item" style="font-weight: bold;">$1</span>',
  )
}
