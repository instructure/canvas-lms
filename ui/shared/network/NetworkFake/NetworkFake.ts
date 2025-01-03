/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
 * details.g
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import sinon from 'sinon'
import waitForCondition from './waitForCondition'
import Request, {SinonFakeXMLHttpRequest} from './Request'

export default class NetworkFake {
  private fakeXhr: {
    onCreate: (xhr: SinonFakeXMLHttpRequest) => void
    restore: () => void
  }
  private requests: Request[]

  constructor() {
    this.fakeXhr = sinon.useFakeXMLHttpRequest()
    this.fakeXhr.onCreate = (request: SinonFakeXMLHttpRequest) => {
      this.requests.push(new Request(request))
    }
    this.requests = []
  }

  async allRequestsReady(): Promise<void> {
    return waitForCondition(() => this.requests.every(request => request.isReady()))
  }

  getRequests(): Request[] {
    return this.requests
  }

  restore(): void {
    this.fakeXhr.restore()
  }
}
