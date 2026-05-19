//
// Copyright (C) 2013 - present Instructure, Inc.
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
//

import Backbone from '@canvas/backbone'
import type {SyllabusCollectionLike, SyllabusModelLike} from '../types'

interface CollectionMutationOptions {
  [key: string]: unknown
}

interface SyllabusCollectionMethods {
  add(model: SyllabusModelLike, options?: CollectionMutationOptions): unknown
  reduce<T>(iteratee: (memo: T, model: SyllabusModelLike) => T, initialValue: T): T
  remove(model: SyllabusModelLike, options?: CollectionMutationOptions): unknown
}

export default class SyllabusCollection extends Backbone.Collection {
  private get methods(): SyllabusCollectionMethods {
    return this as unknown as SyllabusCollectionMethods
  }

  // Attach to externally provided collections
  //
  // This cannot be the initialize method as that would cause the
  // collections to be passed to backbone as if they were model
  // instances... ungoodness.
  constructor(collections: SyllabusCollectionLike[]) {
    super()

    for (const collection of collections) {
      // @ts-expect-error TS2345 - typed callback not assignable to Backbone's (...args: unknown[]) => unknown
      collection.on('add', (model: SyllabusModelLike, _collection: unknown, options: unknown) =>
        this.methods.add(model, options as CollectionMutationOptions),
      )
      // @ts-expect-error TS2345 - typed callback not assignable to Backbone's (...args: unknown[]) => unknown
      collection.on('remove', (model: SyllabusModelLike, _collection: unknown, options: unknown) =>
        this.methods.remove(model, options as CollectionMutationOptions),
      )
      collection.on('reset', () => {
        const findCollectionModels = (memo: SyllabusModelLike[], model: SyllabusModelLike) => {
          if (model.get('collection') === collection) {
            memo.push(model)
          }
          return memo
        }

        for (const model of this.methods.reduce(findCollectionModels, [] as SyllabusModelLike[])) {
          this.methods.remove(model)
        }

        for (const model of collection.models) {
          this.methods.add(model)
        }
      })
    }
  }

  // No-op fetch
  //
  // This fetch should never do anything; this collection is
  // populated with models from other collections (see initialize).
  fetch() {}

  // Gives a "natural feeling" sort order to syllabus events
  //
  // Because this collection is an amalgamation of several types of
  // models, not all models will have the same fields. Additionally,
  // some events may not have a date at all. So we must account for
  // these discrepancies here.
  //
  // Sort conditions:
  //   1) start_at (oldest first)
  //      When start_at times match, sorted by end_at (youngest first)
  //
  //      For example, an appointment being sorted above an
  //      appointment group while the other appointments are sorted
  //      below the appointment group.
  //
  //   2) title (alphabetically)
  //      Gives a consistent ordering when start_at and end_at times
  //      on both items match.
  comparator(model1: SyllabusModelLike, model2: SyllabusModelLike) {
    const m1start_at = model1.get('start_at')
    const m2start_at = model2.get('start_at')
    const m1end_at = model1.get('end_at')
    const m2end_at = model2.get('end_at')
    const m1title = this.lowercaseTitle(model1.get('title'))
    const m2title = this.lowercaseTitle(model2.get('title'))

    // if the start_at times are different
    if (m1start_at !== m2start_at) {
      // if one of the start_at times is missing
      if (!m1start_at) {
        return 1
      }
      if (!m2start_at) {
        return -1
      }

      if (m1start_at < m2start_at) {
        return -1
      } else {
        return 1
      }

      // if the end_at times are different
    } else if (m1end_at !== m2end_at) {
      // if one of the end_at times is missing (shouldn't be)
      if (!m1end_at) {
        return 1
      }
      if (!m2end_at) {
        return -1
      }

      // This may seem backwards, but is intentional!
      // we sort longer running events first to give a better "feel" to
      // the sort order (for overlapping time spans)
      if (m1end_at < m2end_at) {
        return 1
      } else {
        return -1
      }
    }

    if (m1title < m2title) {
      return -1
    } else if (m1title > m2title) {
      return 1
    }

    return 0
  }

  private lowercaseTitle(title: unknown): string {
    if (typeof title === 'string') {
      return title.toLowerCase()
    }

    return ''
  }
}
