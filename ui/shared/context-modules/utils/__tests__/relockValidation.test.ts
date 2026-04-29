/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {shouldShowRelockWarning} from '../relockValidation'

describe('relockValidation', () => {
  describe('shouldShowRelockWarning', () => {
    beforeEach(() => {
      window.ENV.CONTEXT_IS_AVAILABLE = true
    })

    describe('when course is not available', () => {
      it('returns false even when requirements are added', () => {
        window.ENV.CONTEXT_IS_AVAILABLE = false
        const newState = {
          requirements: [
            {id: '1', name: 'Assignment 1', resource: 'assignment', type: 'must_view'},
          ],
        }
        const currentState = {
          requirements: [],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })
    })

    describe('requirements', () => {
      it('returns true when new requirement is added', () => {
        const newState = {
          requirements: [
            {id: '1', name: 'Assignment 1', resource: 'assignment', type: 'must_view'},
          ],
        }
        const currentState = {
          requirements: [],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(true)
      })

      it('returns false when no new requirements are added', () => {
        const requirement = {
          id: '1',
          name: 'Assignment 1',
          resource: 'assignment',
          type: 'must_view',
        }
        const newState = {
          requirements: [requirement],
        }
        const currentState = {
          requirements: [requirement],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })

      it('returns false when requirements are only removed', () => {
        const newState = {
          requirements: [],
        }
        const currentState = {
          requirements: [
            {id: '1', name: 'Assignment 1', resource: 'assignment', type: 'must_view'},
          ],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })

      it('returns true when requirements are added even if some are removed', () => {
        const newState = {
          requirements: [
            {id: '2', name: 'Assignment 2', resource: 'assignment', type: 'must_view'},
          ],
        }
        const currentState = {
          requirements: [
            {id: '1', name: 'Assignment 1', resource: 'assignment', type: 'must_view'},
          ],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(true)
      })

      it('matches requirements by id, resource, and type', () => {
        const newState = {
          requirements: [
            {id: '1', name: 'Assignment 1', resource: 'assignment', type: 'must_submit'},
          ],
        }
        const currentState = {
          requirements: [
            {id: '1', name: 'Assignment 1', resource: 'assignment', type: 'must_view'},
          ],
        }
        // Same id and resource but different type = new requirement
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(true)
      })
    })

    describe('prerequisites', () => {
      it('returns true when new prerequisite is added', () => {
        const newState = {
          prerequisites: [{id: '1', name: 'Module 1'}],
        }
        const currentState = {
          prerequisites: [],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(true)
      })

      it('returns false when no new prerequisites are added', () => {
        const prerequisite = {id: '1', name: 'Module 1'}
        const newState = {
          prerequisites: [prerequisite],
        }
        const currentState = {
          prerequisites: [prerequisite],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })

      it('returns false when prerequisites are only removed', () => {
        const newState = {
          prerequisites: [],
        }
        const currentState = {
          prerequisites: [{id: '1', name: 'Module 1'}],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })

      it('returns true when prerequisites are added even if some are removed', () => {
        const newState = {
          prerequisites: [{id: '2', name: 'Module 2'}],
        }
        const currentState = {
          prerequisites: [{id: '1', name: 'Module 1'}],
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(true)
      })

      it('matches prerequisites by id only', () => {
        const newState = {
          prerequisites: [{id: '1', name: 'Module 1 Updated'}],
        }
        const currentState = {
          prerequisites: [{id: '1', name: 'Module 1'}],
        }
        // Same id but different name = not a new prerequisite
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })
    })

    describe('unlock date', () => {
      it('returns true when unlock date is added', () => {
        const newState = {
          unlockAt: '2024-01-01T00:00:00Z',
        }
        const currentState = {
          lockUntilChecked: false,
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(true)
      })

      it('returns false when unlock date is removed', () => {
        const newState = {
          unlockAt: undefined,
        }
        const currentState = {
          lockUntilChecked: true,
          unlockAt: '2024-01-01T00:00:00Z',
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })

      it('returns false when unlock date is changed but already existed', () => {
        const newState = {
          unlockAt: '2024-02-01T00:00:00Z',
        }
        const currentState = {
          lockUntilChecked: true,
          unlockAt: '2024-01-01T00:00:00Z',
        }
        expect(shouldShowRelockWarning(newState, currentState, true)).toBe(false)
      })
    })
  })
})
