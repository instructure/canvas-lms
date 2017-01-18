define([
  'jquery',
  'underscore',
  'jquery.ajaxJSON'
], function($, _) {
  let exists, Depaginator, depaginate;

  depaginate = function(url, data) {
    let deferred, depaginator;
    deferred = $.Deferred();
    depaginator = new Depaginator(url, deferred, data);
    depaginator.retrieve();

    return deferred.promise();
  };

  exists = function(object) {
    return object !== null && object !== undefined;
  };

  let notExists = function(object) {
    return !exists(object);
  }

  Depaginator = function(url, deferred, data) {
    this.url = url;
    this.deferred = deferred;
    this.data = data;
  };

  Depaginator.prototype.retrieve = function() {
    return $.getJSON(this.url, this.data)
    .done(this.handleInitialRequest.bind(this));
  };

  Depaginator.prototype.handleInitialRequest = function(resultData, status, xhr) {
    let paginationLinks, lastLink;
    paginationLinks = xhr.getResponseHeader('Link');
    lastLink = paginationLinks.match(/<[^>]+>; *rel="last"/);
    lastLink = lastLink[0].match(/<[^>]+>;/);
    let currentLink = paginationLinks.match(/<[^>]+>; *rel="current"/);
    currentLink = currentLink[0].match(/<[^>]+>;/);

    if (notExists(lastLink) || lastLink[0] === currentLink[0]) {
      this.deferred.resolve(resultData);
    } else {
      this.depaginate(resultData, lastLink);
    }
  };

  Depaginator.prototype.depaginate = function(firstPageData, lastLink) {
    let lastPage, requests;
    lastPage = lastLink[0].match(/page=(\d+)/)[1];
    lastPage = parseInt(lastPage, 10);
    requests = this.getAllRequests(lastPage);

    this.makeRequests(requests).then(function() {
      let allOtherPagesData = _.chain(arguments)
        .map(response => response[0])
        .flatten()
        .value();
      let allData = firstPageData.concat(allOtherPagesData);
      this.deferred.resolve(allData);
    }.bind(this));
  };

  Depaginator.prototype.getAllRequests = function(lastPage) {
    let requests = [], pageNumber, request;
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
