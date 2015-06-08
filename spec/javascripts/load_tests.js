tests = __TESTS__;
// tests = tests.slice(0,50);
// console.log(tests);

tests = tests.map(function(test) {
  return test.indexOf('spec/javascripts') === 0 ? '../../' + test : test;
});

// include the english translations by default, same as would happen in
// production via common.js. this saves the test writer from having to stub
// translations anytime they need to use code that uses a no-default
// translation call (e.g. I18n.t('#date.formats.medium')) with the default
// locale
tests.push('translations/_core_en');

window.addEventListener("DOMContentLoaded",function() {
  if(!document.getElementById('fixtures')) {
    var fixturesDiv = document.createElement('div');
    fixturesDiv.id = 'fixtures';
    document.body.appendChild(fixturesDiv);
  }
},false);

if(!window.ENV) window.ENV = {};

if(window.__karma__) {
  requirejs.config({
    baseUrl: '/base/public/javascripts',
    deps: tests,
    callback: window.__karma__.start
  });
} else {
  QUnit.config.autostart = false;
  requirejs.config({
    baseUrl: '/public/javascripts',
    deps: tests,
    callback: function() {
      QUnit.start();
    }
  });
}
