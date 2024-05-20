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

import UploadResult from '../upload_result'

describe('UploadResult', () => {
  beforeEach(() => {
    this.result = new UploadResult()
  })

  it('parsesXML', () => {
    const xml = `
      <?xml version="1.0" encoding="ISO-8859-1"?><xml>
        <result>
          <result_ok>
            <token>1011389726328.4103</token>
            <filename>13897264059231</filename>
            <origFilename>iShowU HD.mov</origFilename>
            <thumb_url></thumb_url>
            <thumb_created></thumb_created>
          </result_ok>
          <serverTime>1389726406</serverTime>
        </result>
        <error></error>
        <debug>
          <sigtype>1</sigtype>
          <validateSignature></validateSignature>
          <signature>8b98fa8d24e22d6fe515b03ded7a7ee6</signature>
          <execute_impl_time>0.41368103027344</execute_impl_time>
          <execute_time>0.45064902305603</execute_time>
          <total_time>0.45182085037231</total_time>
        </debug>
      </xml>
    `

    this.result.parseXML(xml)
    expect(this.result.isError).toBeFalsy()
  })

  it('reports token correctly', () => {
    const xml = `
      <?xml version="1.0" encoding="ISO-8859-1"?><xml>
        <result>
          <result_ok>
            <token>1011389726328.4103</token>
            <filename>13897264059231</filename>
            <origFilename>iShowU HD.mov</origFilename>
            <thumb_url></thumb_url>
            <thumb_created></thumb_created>
          </result_ok>
          <serverTime>1389726406</serverTime>
        </result>
        <error></error>
        <debug>
          <sigtype>1</sigtype>
          <validateSignature></validateSignature>
          <signature>8b98fa8d24e22d6fe515b03ded7a7ee6</signature>
          <execute_impl_time>0.41368103027344</execute_impl_time>
          <execute_time>0.45064902305603</execute_time>
          <total_time>0.45182085037231</total_time>
        </debug>
      </xml>
    `

    this.result.parseXML(xml)
    expect(this.result.token).toEqual('1011389726328.4103')
  })

  it('handles no token', () => {
    const xml = '<xml><result><result_ok></result_ok></result></xml>'
    this.result.parseXML(xml)
    expect(this.result.token).toBeNull()
  })

  it('asEntryParams serializes all needed keys', () => {
    const eParams = this.result.asEntryParams()
    expect(eParams.entry1_name).toBeDefined()
    expect(eParams.entry1_filename).toBeDefined()
    expect(eParams.entry1_realFilename).toBeDefined()
  })
})
