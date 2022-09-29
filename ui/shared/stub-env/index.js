//
// Copyright (C) 2021 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

// assign exactly what window.ENV should be in your test suite:
//
//     describe('my thing that relies on window.ENV', () => {
//       const env = stubEnv({ SOME: 'key' })
//
//       it('works', () => {
//         expect(window.ENV.SOME).toEqual('key')
//         env.FOO = 1
//         expect(window.ENV.FOO).toEqual(1)
//       })
//
//       it('does not bleed', () => {
//         expect(window.ENV.FOO).toEqual(undefined)
//       })
//     })
//
// any partial writes you do to window.ENV mid-test will be restored
const stubEnv = nextEnv => {
  const restore = snapshot(nextEnv)

  let previousEnv

  beforeEach(() => {
    previousEnv = window.ENV
    window.ENV = nextEnv
  })

  afterEach(() => {
    restore(nextEnv)
    window.ENV = previousEnv
  })

  return nextEnv
}

const snapshot = ({...initial}) => {
  return current => {
    for (const x of Object.getOwnPropertyNames(current)) {
      delete current[x]
    }

    Object.assign(current, initial)
  }
}

export default stubEnv
