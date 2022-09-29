/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useMemo, createRef} from 'react'

const useInputFocus = inputEls => {
  const inputElRefs = useMemo(
    () => inputEls.reduce((acc, el) => acc.set(el, createRef()), new Map()),
    [] // eslint-disable-line react-hooks/exhaustive-deps
  )

  const setInputElRef = (el, key) => {
    const elRef = inputElRefs.get(key)
    elRef.current = el
    inputElRefs.set(key, elRef)
  }

  return {
    inputElRefs,
    setInputElRef,
  }
}

export default useInputFocus
