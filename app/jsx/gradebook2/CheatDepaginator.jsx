define(["jquery", "underscore"], ($, _) => {
  const consumePagesInOrder = (callback) => {
    const pendingResponses = [];
    let wantedPage = 1;

    const orderedConsumer = (response, page) => {
      if (page === wantedPage) {
        callback(response);
        wantedPage += 1;
      } else {
        pendingResponses.push([response, page]);
      }

      const nextPage = _.find(pendingResponses,
                              ([pageData,pageNum]) => pageNum === wantedPage);
      if (nextPage) {
        const [pageData, pageNum] = nextPage;
        orderedConsumer(pageData, pageNum);
      }
    };

    return orderedConsumer;
  };


  /**
   * Quickly depaginates a canvas API endpoint
   *
   * Returns pages in sequential order.
   *
   * Note: this can only be used for endpoints that have sequential page
   * numbers
   *
   * @param url - canvas api endpoint
   * @param params - params to be passed along with each request
   * @param pageCallback - called for each page of data
   * @returns a jQuery Deferred that will be resolved when all pages have been fetched
   */
  const cheaterDepaginate = (url, params, pageCallback) => {
    const gotAllPagesDfd = $.Deferred();
    const callback = consumePagesInOrder(pageCallback);

    $.ajaxJSON(url, "GET", params, (firstPageResponse, xhr) => {
      callback(firstPageResponse, 1);

      const paginationLinks = xhr.getResponseHeader('Link');
      const lastLink = paginationLinks.match(/<[^>]+>; *rel="last"/);
      if (lastLink === null) {
        gotAllPagesDfd.resolve();
        return;
      }

      const lastPage = parseInt(lastLink[0].match(/page=(\d+)/)[1], 10);
      if (lastPage === 1) {
        gotAllPagesDfd.resolve();
        return;
      }

      const fetchPage = (page) => {
        return $.ajaxJSON(url, "GET", {page: page, ...params},
                          response => callback(response, page));
      };

      const dfds = [];
      for (let page = 2; page <= lastPage; page++) {
        dfds.push(fetchPage(page));
      }

      $.when(...dfds).then(() => gotAllPagesDfd.resolve());
    });

    return gotAllPagesDfd;
  };

  return cheaterDepaginate;
});
