# Environment initializers

Modules in this directory are expected to return a JSON object that contains
initial app configuration.

## `production.js`

Contains initial configuration for the built-version of CQS, which will be
embedded inside Canvas.

## `development.js`

This file will *not* be included in the built version. Use this to define
helpers helpers and config defaults that facilitate development. This will be
checked in to git and shared between the team.

## `development_local.js`

This file will not be included in the built version, nor will it be checked-in
to git. Use this file to provide your own API token and any "private" config
that you don't necessarily think other team members will be benefit from.

This file is also a good place to swap in fixtures instead of API endpoints if
you want to speed things up and not hit the actual Canvas API. For example:

```javascript
  return {
    apiToken: 'MY_API_TOKEN',

    // You can hit against the actual Canvas API if you got reverse proxy
    // going on:
    //
    // quizStatisticsUrl: '/api/v1/courses/1/quizzes/1/statistics',
    // quizReportsUrl: '/api/v1/courses/1/quizzes/1/reports',

    // Or just use the fixtures for speed:
    quizStatisticsUrl: '/fixtures/quiz_statistics_all_types.json',
    quizReportsUrl: '/fixtures/quiz_reports.json',
  };
```