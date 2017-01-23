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
/* global sinon, QUnit, test*/
define(['qunit'], function (QUnit) {
  sinon.assert.fail = function (msg) {
    QUnit.ok(false, msg);
  };

  sinon.assert.pass = function (assertion) {
    QUnit.ok(true, assertion);
  };

  sinon.config = {
    injectIntoThis: true,
    injectInto: null,
    properties: ['spy', 'stub', 'mock', 'clock', 'sandbox'],
    useFakeTimers: false,
    useFakeServer: false
  };

  (function (global) {
    const qModule = QUnit.module;
    let wrappingSandbox;

    const setup = function () {
      const config = sinon.getConfig(sinon.config);
      config.injectInto = config.injectIntoThis && this || config.injectInto;
      wrappingSandbox = sinon.sandbox.create(config);
    };

    const teardown = function () { wrappingSandbox.verifyAndRestore(); };

    QUnit.module = global.module = function (name, lifecycle) {
      lifecycle = lifecycle || {};
      const origSetup = lifecycle.setup;
      const origTeardown = lifecycle.teardown;

      lifecycle.setup = function () {
        setup.call(this);
        origSetup && origSetup.call(this);
      };
      lifecycle.teardown = function () {
        teardown.call(this);
        origTeardown && origTeardown.call(this);
      };

      qModule(name, lifecycle);
    };
  }(this));
});
