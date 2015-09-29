define([
  'jquery',
  'jquery.ajaxJSON'
], function($) {
  var exists, Depaginator, depaginate;

  depaginate = function(url) {
    var deferred, depaginator;

    deferred = $.Deferred();
    depaginator = new Depaginator(url, deferred);
    depaginator.retrieve();

    return deferred.promise();
  };

  exists = function(object) {
    return object !== null && object !== undefined;
  };

  notExists = function(object) {
    return !exists(object);
  }

  Depaginator = function(url, deferred) {
    this.url = url;
    this.deferred = deferred;
  };

  Depaginator.prototype.retrieve = function() {
    return $.getJSON(this.url, 'GET')
    .done(this.handleInitialRequest.bind(this));
  };

  Depaginator.prototype.handleInitialRequest = function(resultData, status, xhr) {
    var paginationLinks, lastLink;

    paginationLinks = xhr.getResponseHeader('Link');
    lastLink = paginationLinks.match(/<[^>]+>; *rel="last"/);
    lastLink = lastLink[0].match(/<[^>]+>;/);
    currentLink = paginationLinks.match(/<[^>]+>; *rel="current"/);
    currentLink = currentLink[0].match(/<[^>]+>;/);

    if (notExists(lastLink) || lastLink[0] === currentLink[0]) {
      this.deferred.resolve(resultData);
    } else {
      this.depaginate(resultData, lastLink);
    }
  };

  Depaginator.prototype.depaginate = function(resultData, lastLink) {
    var lastPage, requests, allResults;

    lastPage = lastLink[0].match(/page=(\d+)/)[1];
    lastPage = parseInt(lastPage, 10);

    requests = this.getAllRequests(lastPage);

    this.makeRequests(requests).then(function(responses) {
      var results;

      allResults = resultData;

      for (var responseNumber = 0; responseNumber < arguments.length; responseNumber += 3) {
        results = arguments[responseNumber];
        allResults = allResults.concat(results);
      }

      this.deferred.resolve(allResults);
    }.bind(this));
  };

  Depaginator.prototype.getAllRequests = function(lastPage) {
    var requests = [], pageNumber, request;

    for (pageNumber = 2; pageNumber <= lastPage; pageNumber++) {
      request = this.fetchResources(pageNumber);
      requests.push(request);
    }

    return requests;
  };

  Depaginator.prototype.fetchResources = function(pageNumber) {
    return $.ajaxJSON(this.url, 'GET', {page: pageNumber});
  };

  Depaginator.prototype.makeRequests = function(requests) {
    return $.when.apply($, requests);
  };

  return depaginate;
});
