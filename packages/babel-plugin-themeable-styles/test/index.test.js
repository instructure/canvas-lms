/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
const path = require('path')
const fs = require('fs')
const {assert} = require('chai')
const {transformFileSync} = require('@babel/core')
const plugin = require('../')

const subject = filename => transformFileSync(filename, { plugins: [plugin] }).code

describe('import', () => {
  it('expands import x from "./y.css"', () => {
    assert.deepEqual(
      subject(path.resolve(__dirname, 'fixture/esm-rel.in.js')),
      fs.readFileSync(path.resolve(__dirname, 'fixture/out.js'), 'utf8'),
    )
  })

  it('expands import x from "y.css"', () => {
    assert.deepEqual(
      subject(path.resolve(__dirname, 'fixture/esm-abs.in.js')),
      fs.readFileSync(path.resolve(__dirname, 'fixture/out.js'), 'utf8'),
    )
  })
})

describe('require', () => {
  it('expands x = require("./y.css")', () => {
    assert.deepEqual(
      subject(path.resolve(__dirname, 'fixture/cjs-rel.in.js')),
      fs.readFileSync(path.resolve(__dirname, 'fixture/out.js'), 'utf8'),
    )
  })

  it('expands x = require("y.css")', () => {
    assert.deepEqual(
      subject(path.resolve(__dirname, 'fixture/cjs-abs.in.js')),
      fs.readFileSync(path.resolve(__dirname, 'fixture/out.js'), 'utf8'),
    )
  })
})
