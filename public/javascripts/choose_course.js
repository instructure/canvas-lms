define([
  'jquery' /* $ */,
  'i18n!content_imports',
  'underscore',
  'compiled/xhr/RemoteSelect',
  'jqueryui/autocomplete' /* /\.autocomplete/ */
], function($, I18n, _, RemoteSelect){

  var $frame = $("<iframe id='copy_course_target' name='copy_course_target' src='about:blank'/>"),
        $select = $('#copy_from_course'),
        remoteSelect,
        currentCourseId = parseInt(window.location.pathname.split('/')[2]);

    if ($select.length) {
      remoteSelect = new RemoteSelect($('#copy_from_course'), {
        formatter: _.bind(function(courses) {
          /**
           * let's start by saying that this function is really long. for that,
           * I apologize. my hope is that most formatters won't have to be this
           * long or unwieldy. with that out of the way, let's begin.
           */

          // start by sorting by date, newest to oldest. this ensures that our
          // terms are displayed newest to oldest.
          courses = courses.sort(function(a, b) {
            return new Date(b.enrollment_start).getTime() - new Date(a.enrollment_start).getTime();
          });

          var terms,
              termMap   = _.groupBy(courses, function(course) { return course.term + ' (' + course.account_name + ')'; }),
              termNames = _.chain(termMap).keys().reduce(function(h, termName) {
                var strippedTermName = termName.replace(/\([^\)]+\)$/, '').trim();
                h[strippedTermName] = h[strippedTermName] || {count: 0, termNames: []};
                h[strippedTermName].count = h[strippedTermName].count + 1;
                h[strippedTermName].termNames.push(termName);
                return h;
              }, {}).value();

          // for each term/account pair, format the courses for display in
          // the <select> and reject the current course. also sort by course
          // course name inside each account.
          terms = _.reduce(termMap, function(memo, v, k) {
            memo[k] = _.chain(v).reject(function(c) {
              return c.id == currentCourseId;
            }).map(function(c) {
              return { label: c.label, value: c.id };
            }).sortBy(function(c) { return c.label }).value();

            return memo;
          }, {});

          // before we return our list of terms and courses, make another loop
          // through them to see if we can strip the account name off of any
          // terms that don't have duplicate names across accounts.
          return _.reduce(terms, function(memo, courses, term) {
            var strippedTermName = term.replace(/\([^\)]+\)$/, '').trim(),
                key = termNames[strippedTermName].count === 1 ?
                  strippedTermName :
                  term;
            memo[key] = courses;
            return memo;
          }, {});
        }, this),
        url: '/users/' + ENV.current_user_id + '/manageable_courses'
      });
      remoteSelect.currentRequest.success(function(data) {
        if (data.length >= 500) {
          $('#select-course-row').hide();
        }
      });
    }

    $('#include_concluded_courses').change(function(e) {
      var el = $(e.currentTarget);
      if (el.prop('checked')) {
        remoteSelect.makeRequest({ 'include[]': 'concluded' });
      } else {
        remoteSelect.makeRequest();
      }
    });

    $("#copy_from_course").change(
            function () {
              var select = $("#copy_from_course")[0];
              var idx = select.selectedIndex;
              var name = select.options[idx].innerHTML;
              var id = select.options[idx].value;
              if (id != "none") {
                $("#course_autocomplete_name_holder").show();
                $("#course_autocomplete_name").text(name);
                $("#course_autocomplete_id").val(id);
                $("#course_autocomplete_id_lookup").val("");
              }
            }).change();

    if ($("#course_autocomplete_id_lookup:visible").length > 0) {
      var autocompleteCache = {},
          lastAutocompleteRequest;

      $("#course_autocomplete_id_lookup").autocomplete({
        source : function(request, response) {
          var src = '/users/' + ENV.current_user_id + '/manageable_courses',
              params = { term: request.term },
              includeConcluded = $('#include_concluded_courses').prop('checked'),
              cacheKey = request.term;

          if (includeConcluded) {
            params['include[]'] = 'concluded';
            cacheKey += '|concluded';
          }

          if (cacheKey in autocompleteCache) {
            response(autocompleteCache[cacheKey]);
            return;
          }

          lastAutocompleteRequest = $.getJSON(src, params, function(data, status, xhr) {
            autocompleteCache[cacheKey] = data;
            if (lastAutocompleteRequest === xhr) { response(data); }
          });
        },
        select:function (event, ui) {
          $("#course_autocomplete_name_holder").show();
          $("#course_autocomplete_name").text(ui.item.label);
          $("#course_autocomplete_id").val(ui.item.id);
          $("#copy_from_course").val("none");
        }
      });
    }

});
