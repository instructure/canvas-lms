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

import {BlockContentEditorContextType} from '../BlockContentEditorContext'
import {AccessibilityIssue} from '../accessibilityChecker/types'

export type Mocks = {
  openMock: jest.Mock
}

export const mockBlockContentEditorContext = ({openMock = jest.fn()}: Partial<Mocks>) =>
  ({
    addBlockModal: {
      isOpen: false,
      insertAfterNodeId: undefined,
      open: openMock,
      close: jest.fn(),
    },
    settingsTray: {
      isOpen: false,
      open: jest.fn(),
      close: jest.fn(),
    },
    editor: {
      mode: 'default',
      setMode: jest.fn(),
    },
    editingBlock: {
      id: null,
      setId: jest.fn(),
      idRef: {current: null},
      addSaveCallback: jest.fn(),
      deleteSaveCallback: jest.fn(),
    },
    accessibility: {
      addA11yIssues: jest.fn(),
      removeA11yIssues: jest.fn(),
      a11yIssueCount: 0,
      a11yIssues: new Map<string, AccessibilityIssue[]>(),
    },
    aiAltTextGenerationURL: '/api/v1/courses/1/pages_ai/alt_text',
  }) as BlockContentEditorContextType
