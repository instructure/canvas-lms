/*
 * Qt+WebKit powered (mostly) headless test runner using Phantomjs
 *
 * Phantomjs installation: http://code.google.com/p/phantomjs/wiki/BuildInstructions
 *
 * Run with:
 *  phantomjs test.js [url-of-your-qunit-testsuite]
 *
 * E.g.
 *      phantomjs test.js http://localhost/qunit/test
 */

var system = require('system');
var fs = require('fs');

var url = phantom.args[0];
var page = new WebPage();

// Route "console.log()" calls from within the Page context to the main Phantom context (i.e. current "this")
var timer;
var errors = 0;
var completed = false;
var timeout = 30;
page.onConsoleMessage = function (msg) {
  var result = msg.match(/^Took .*, (\d+) failed\.$/);
  if (result) {
    errors = parseInt(result[1], 10);
    completed = true;
  }
  console.log(msg);
  clearTimeout(timer);
  // exit after <timeout> seconds of no messages
  timer = setTimeout(function () {
    if (!completed)
      console.log("Error: test timeout after " + timeout + " seconds");
    phantom.exit(completed && !errors ? 0 : 1);
  }, timeout * 1000);
};

page.open(url, function(status){
  if (status !== "success") {
    console.log("Unable to access network: " + status);
    phantom.exit(1);
    return
  }

  // allow access to phantom's environment
  page.evaluate(function(env) { window.PHANTOM_ENV = env; }, system.env);

  // inject runner javascript, if present
  var runner = 'spec/javascripts/runner.js';
  if (fs.exists(runner)) {
    if (page.injectJs(runner)) {
      console.log('runner injection successful');
    } else {
      console.log('runner injection FAILED');
    }
  }

  page.evaluate(addLogging);
  var interval = setInterval(function() {
    if (finished()) {
      clearInterval(interval);
      onfinishedTests();
    }
  }, 500);
});

function finished() {
  return page.evaluate(function(){
    return !!window.qunitDone;
  });
};

function onfinishedTests() {
  var output = page.evaluate(function() {
      return JSON.stringify(window.qunitDone);
  });
  phantom.exit(JSON.parse(output).failed > 0 ? 1 : 0);
};

function addLogging() {
  var current_test_assertions = [];

  QUnit.testDone(function(result) {
    var name = result.module + ': ' + result.name;
    var i;

    if (result.failed) {
      console.log('Assertion Failed: ' + name);

      for (i = 0; i < current_test_assertions.length; i++) {
        console.log('    ' + current_test_assertions[i]);
      }
    } else {
      console.log(name);
    }

    current_test_assertions = [];
  });

  QUnit.log(function(details) {
    var response;

    if (details.result) {
      return;
    }

    response = details.message || '';

    if (typeof details.expected !== 'undefined') {
      if (response) {
        response += ', ';
      }

      response += 'expected: ' + details.expected + ', but was: ' + details.actual;
    }

    current_test_assertions.push('Failed assertion: ' + response);
  });

  // timer for PhantomJS, prints final results multiple times, prematurely w/o it :\
  var timer;
  QUnit.done(function( result ) {
    clearTimeout(timer);
    timer = setTimeout(function () {
      console.log('');
      console.log('Took ' + result.runtime +  'ms to run ' + result.total + ' tests. ' + result.passed + ' passed, ' + result.failed + ' failed.');
    }, 2500);
  });
}
