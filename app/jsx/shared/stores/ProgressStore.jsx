define([
  'react',
  'underscore',
  'jsx/shared/helpers/createStore',
  'jquery'
], (React, _, createStore, $) => {
  var ProgressStore = createStore({}),
    _progresses = {};

  ProgressStore.get = function(progress_id) {
    var url = "/api/v1/progress/" + progress_id;

    $.getJSON(url, function(data) {
      _progresses[data.id] = data;
      ProgressStore.setState(_progresses);
    });
  };

  return ProgressStore;
})
