tests = shuffle(__TESTS__);
// tests = __TESTS__
// tests = tests.slice(0,50);
// console.log(tests);

tests = tests.map(function(test) {
  return test.indexOf('spec/javascripts') === 0 ? '../../' + test : test;
});

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

// Fisher-Yates shuffle
// http://jsperf.com/fisher-yates-compare-shuffle/12
function shuffle(array) {
  var tmp, current, top = array.length;
  if (top) while (top) {
    current = (Math.random() * (top--)) | 0;
    tmp = array[current];
    array[current] = array[top];
    array[top] = tmp;
  }
  return array;
}
