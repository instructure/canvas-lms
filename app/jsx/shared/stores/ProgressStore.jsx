import React from 'react'
import _ from 'underscore'
import createStore from 'jsx/shared/helpers/createStore'
import $ from 'jquery'
  var ProgressStore = createStore({}),
    _progresses = {};

  ProgressStore.get = function(progress_id) {
    var url = "/api/v1/progress/" + progress_id;

    $.getJSON(url, function(data) {
      _progresses[data.id] = data;
      ProgressStore.setState(_progresses);
    });
  };

export default ProgressStore
