define(['bower/react/react-dom'], function(ReactDOM) {
  console.warn('You requiring "ReactDOM" you should require "react-dom" instead.');
  window.ReactDOM = window.ReactDOM || ReactDOM;
  return ReactDOM;
});

