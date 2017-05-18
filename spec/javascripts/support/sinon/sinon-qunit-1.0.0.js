/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

/**
 * sinon-qunit 1.0.0, 2010/12/09
 *
 * @author Simon Williams
 * Modified version of sinon-qunit from Gustavo Machado (@machadogj), Jose Romaniello (@jfroma)
 * - https://github.com/jfromaniello/jmail/blob/master/scripts/Tests/sinon-qunit-1.0.0.js
 * Modified version of sinon-qunit from Christian Johansen
 * - https://github.com/cjohansen/sinon-qunit/blob/master/lib/sinon-qunit.js
 *
 * (The BSD License)
 *
 * Copyright (c) 2010-2011, Christian Johansen, christian@cjohansen.no
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice,
 *       this list of conditions and the following disclaimer in the documentation
 *       and/or other materials provided with the distribution.
 *     * Neither the name of Christian Johansen nor the names of his contributors
 *       may be used to endorse or promote products derived from this software
 *       without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
(function (factory) {
  var global = (function () { return this }())
  if (typeof module === 'object' && module.exports) {
    var sinon = require('sinon')

    // export sinon to the global scope for our specs that expect it there
    global.sinon = sinon

    // Karma will have already loaded QUnit as a global, we don't want to require a new one
    // so there is nothing funky from having 2 QUnits on the page.
    var QUnit = global.QUnit

    module.exports = factory(global, QUnit, sinon)
  } else {
    factory(global, global.QUnit, global.sinon)
  }
}(function (global, QUnit, sinon) {
  sinon.assert.fail = function (msg) {
    return QUnit.ok(false, msg)
  }
  sinon.assert.pass = function (assertion) {
    return QUnit.ok(true, assertion)
  }

  sinon.config = {
    injectIntoThis: true,
    injectInto: null,
    properties: ['spy', 'stub', 'mock', 'clock', 'sandbox'],
    useFakeTimers: false,
    useFakeServer: false,
  }

  var qModule = QUnit.module
  var wrappingSandbox

  var setup = function () {
    var config = Object.assign({}, sinon.defaultConfig, sinon.config)
    config.injectInto = config.injectIntoThis && this || config.injectInto
    wrappingSandbox = sinon.sandbox.create(config)
  }

  var teardown = function () {
    return wrappingSandbox.verifyAndRestore()
  }

  QUnit.module = global.module = function (name, lifecycle) {
    lifecycle = lifecycle || {}
    var origSetup = lifecycle.setup
    var origTeardown = lifecycle.teardown

    lifecycle.setup = function () {
      setup.call(this)
      origSetup && origSetup.call(this)
    }
    lifecycle.teardown = function () {
      teardown.call(this)
      origTeardown && origTeardown.call(this)
    }

    qModule(name, lifecycle)
  }
}))
