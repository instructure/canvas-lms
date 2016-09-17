define([

], function () {

  const defaultState = {
      "rule": {},
      "ranges" : [
        {
           "scoring_range":{
              "lower_bound":"0.7",
              "upper_bound":"1.0",
           },
           "size":0,
           "students":[]
        },
        {
           "scoring_range":{
              "lower_bound":"0.4",
              "upper_bound":"0.7",
           },
           "size":0,
           "students":[]
        },
        {
           "scoring_range":{
              "lower_bound":"0.0",
              "upper_bound":"0.4",
           },
           "size":0,
           "students":[]
        }
      ],
      "enrolled" : 0,
      "assignment" : {
        "grading_type": "percent",
        "submission_types": "on_paper",
      },
      "global_shared" : {
        "errors" : [],
      }
    };

  return defaultState;
});