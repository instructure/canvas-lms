Pagination
==========

Requests that return multiple items will be paginated to 10 items by default. Further pages
can be requested with the `?page` query parameter. You can set a custom per-page amount
with the `?per_page` parameter.

Pagination information is provided in the [link Header](http://www.w3.org/Protocols/9707-link-header.html):

    Link: </courses/:id/discussion_topics.json?page=2&per_page=10>; rel="next",</courses/:id/discussion_topics.json?page=1&per_page=10>; rel="first",</courses/:id/discussion_topics.json?page=5&per_page=10>; rel="last"

The possible `rel` values are:

* next - link to the next page of results. None is sent if there is no next page.
* prev - link to the previous page of results. None is sent if there is no previous page.
* first - link to the first page of results. None is sent if there are no pages.
* last - link to the last page of results. None is sent if there are no pages.
