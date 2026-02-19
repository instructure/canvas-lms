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

import {describe, it, expect} from 'vitest'
import {getIssueGrouping} from '../issueGrouping'

describe('getIssueGrouping', () => {
  describe('Table group', () => {
    it('returns correct grouping for table-caption', () => {
      expect(getIssueGrouping('table-caption')).toEqual({
        groupLabel: 'Table',
        ruleLabel: 'Missing caption',
      })
    })

    it('returns correct grouping for table-header', () => {
      expect(getIssueGrouping('table-header')).toEqual({
        groupLabel: 'Table',
        ruleLabel: 'Missing heading',
      })
    })

    it('returns correct grouping for table-header-scope', () => {
      expect(getIssueGrouping('table-header-scope')).toEqual({
        groupLabel: 'Table',
        ruleLabel: 'Heading scope missing',
      })
    })
  })

  describe('Alt text group', () => {
    it('returns correct grouping for img-alt', () => {
      expect(getIssueGrouping('img-alt')).toEqual({
        groupLabel: 'Alt text',
        ruleLabel: 'Missing',
      })
    })

    it('returns correct grouping for img-alt-length', () => {
      expect(getIssueGrouping('img-alt-length')).toEqual({
        groupLabel: 'Alt text',
        ruleLabel: 'Too long',
      })
    })

    it('returns correct grouping for img-alt-filename', () => {
      expect(getIssueGrouping('img-alt-filename')).toEqual({
        groupLabel: 'Alt text',
        ruleLabel: 'Is filename',
      })
    })
  })

  describe('Contrast group', () => {
    it('returns correct grouping for small-text-contrast', () => {
      expect(getIssueGrouping('small-text-contrast')).toEqual({
        groupLabel: 'Contrast',
        ruleLabel: 'Small text contrast',
      })
    })

    it('returns correct grouping for large-text-contrast', () => {
      expect(getIssueGrouping('large-text-contrast')).toEqual({
        groupLabel: 'Contrast',
        ruleLabel: 'Large text contrast',
      })
    })
  })

  describe('Links group', () => {
    it('returns correct grouping for adjacent-links', () => {
      expect(getIssueGrouping('adjacent-links')).toEqual({
        groupLabel: 'Links',
        ruleLabel: 'Adjacent',
      })
    })
  })

  describe('Formatting group', () => {
    it('returns correct grouping for list-structure', () => {
      expect(getIssueGrouping('list-structure')).toEqual({
        groupLabel: 'Formatting',
        ruleLabel: 'List',
      })
    })
  })

  describe('Headings group', () => {
    it('returns correct grouping for headings-sequence', () => {
      expect(getIssueGrouping('headings-sequence')).toEqual({
        groupLabel: 'Headings',
        ruleLabel: 'Skipped level',
      })
    })

    it('returns correct grouping for headings-start-at-h2', () => {
      expect(getIssueGrouping('headings-start-at-h2')).toEqual({
        groupLabel: 'Headings',
        ruleLabel: 'H1 in content',
      })
    })

    it('returns correct grouping for paragraphs-for-headings', () => {
      expect(getIssueGrouping('paragraphs-for-headings')).toEqual({
        groupLabel: 'Headings',
        ruleLabel: 'Too long',
      })
    })
  })

  describe('Currently not used rules', () => {
    it('returns null for link-text', () => {
      expect(getIssueGrouping('link-text')).toEqual({
        groupLabel: 'Unknown',
        ruleLabel: 'Unknown',
      })
    })

    it('returns null for link-purpose', () => {
      expect(getIssueGrouping('link-purpose')).toEqual({
        groupLabel: 'Unknown',
        ruleLabel: 'Unknown',
      })
    })

    it('returns null for has-lang-entry', () => {
      expect(getIssueGrouping('has-lang-entry')).toEqual({
        groupLabel: 'Unknown',
        ruleLabel: 'Unknown',
      })
    })
  })
})
