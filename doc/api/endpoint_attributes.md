API Endpoint Attributes
=======================

Canvas adds attributes to links in returned HTML snippets to make it easier for
API consumers to digest the referenced resources. These attributes are as follows:

* `data-api-endpoint` - A URL where the linked object can be accessed via the API
* `data-api-returntype` - The type of data returned

For example, consider an assignment description containing a link to a wiki page in
the same course.  The description returned by the Get Assignment API might look
like this:

    !!!javascript
    <a href="http://canvas.example.com/courses/123/pages/a-wiki-page"
       data-api-endpoint="http://canvas.example.com/api/v1/courses/123/pages/a-wiki-page"
       data-api-returntype="Page">More information here</a>

The currently supported `data-api-returntype` values are:

* `Assignment`
* `Discussion`
* `Page`
* `File`
* `Folder`
* `Quiz`
* `Module`
* `SessionlessLaunchUrl`

If the API returns a list of objects instead of a single object, the `data-api-returntype`
will be wrapped in square brackets, e.g. `[Assignment]`.
