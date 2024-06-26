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

type Mutex = {
  isLocked: boolean
  waiting: any[]
}
type MutexCollection = {[key: string]: Mutex}

class MutexManager {
  private mutexes: MutexCollection = {}

  private static instance: MutexManager

  // This prevents the class from being instantiated
  // eslint-disable-next-line no-useless-constructor, no-empty-function
  private constructor() {}

  static getInstance(): MutexManager {
    if (!MutexManager.instance) {
      MutexManager.instance = new MutexManager()
    }
    return MutexManager.instance
  }

  // Create a Mutex. Optionally it can be created with a callback function.
  createMutex(mutex: string, callbackFn: () => void): void {
    if (this.mutexes[mutex]) {
      // if the Mutex already exists, update the entry
      this.mutexes[mutex].isLocked = true
      callbackFn && this.mutexes[mutex].waiting.push(callbackFn)
    } else {
      // otherwise create a new Mutex
      this.mutexes[mutex] = {
        isLocked: true,
        waiting: callbackFn ? [callbackFn] : [],
      }
    }
  }

  releaseMutex(mutex: string): void {
    if (this.mutexes[mutex]) {
      // unlock first to prevent callbacks from being queued while releasing
      this.mutexes[mutex].isLocked = false
      this.mutexes[mutex].waiting.forEach((callback: any) => callback())
      delete this.mutexes[mutex]
    }
  }

  awaitMutex(mutex: string, callbackFn: () => void): void {
    if (this.mutexes[mutex] && this.mutexes[mutex].isLocked) {
      // If the Mutex is locked, add the callback to the waiting list.
      this.mutexes[mutex].waiting.push(callbackFn)
    } else {
      // If the Mutex is not locked or not registered, resolve the callback immediately.
      callbackFn()
    }
  }
}

export default MutexManager.getInstance()
