Uploading Files
===============

There are two ways to upload a file to Canvas: either by sending the
file data in a POST request, or by sending Canvas a publicly
accessible HTTP or HTTPS URL to the file.

<table id='quicklinks'>
</table>

<h2 class='api_method_name' name='method.file_uploads.post' data-subtopic="Uploading Files">
<a name="method.file_uploads.post" href="#method.file_uploads.post">Uploading via POST</a>
</h2>

There are three steps to uploading a file directly via POST:

1. Notify Canvas that you are uploading a file with a POST to the file
   creation endpoint. This POST will include the file name and file size,
   along with information about what context the file is being created in.
2. Upload the file using the information returned in the first POST request.
3. On successful upload, the API will respond with a redirect. This
   redirect needs to be followed to complete the upload, or the file may not appear.

### Step 1: Telling Canvas about the file upload and getting a token

The first step is to POST to the relevant API endpoint, depending on where
you want to create the file. For example, to <a href="courses.html">add a file to a course</a>, you'd
POST to `/api/v1/courses/:course_id/files`. Or to <a href="submissions.html">upload a file as part of a student homework submission</a>, as the student you'd POST to
`/api/v1/courses/:course_id/assignments/:assignment_id/submissions/self/files`.

Arguments:

<dl>
  <dt>name</dt> <dd>The filename of the file. Any UTF-8 name is allowed. Path components such as `/` and `\` will be treated as part of the filename, not a path to a sub-folder.</dd>
  <dt>size</dt> <dd>The size of the file, in bytes. This field is recommended, as it will let you find out if there's a quota issue before uploading the raw file.</dd>
  <dt>content_type</dt> <dd>The content type of the file. If not given, it will be guessed based on the file extension.</dd>
  <dt>parent_folder_id</dt><dd>The id of the folder to store the file in. If this and parent_folder_path are sent an error will be returned. If neither is given, a default folder will be used.</dd>
  <dt>parent_folder_path</dt> <dd>The path of the folder to store the file in. The path separator is the forward slash `/`, never a back slash. The folder will be created if it does not already exist. This parameter only applies to file uploads in a context that has folders, such as a user, a course, or a group. If this and parent_folder_id are sent an error will be returned. If neither is given, a default folder will be used.</dd>
  <dt>folder</dt> <dd>[deprecated] Use parent_folder_path instead.</dd>
  <dt>on_duplicate</dt> <dd>How to handle duplicate filenames. If `overwrite`, then this file upload will overwrite any other file in the folder with the same name. If `rename`, then this file will be renamed if another file in the folder exists with the given name. If no parameter is given, the default is `overwrite`. This doesn't apply to file uploads in a context that doesn't have folders.</dd>
  <dt>success_include[]</dt> <dd>An array of additional information to include in the upload success response. See <a href="files.html#method.files.api_show">Files API</a> for more information.</dd>
</dl>

Example Request:

```bash
curl 'https://<canvas>/api/v1/users/self/files' \
     -F 'name=profile_pic.jpg' \
     -F 'size=302185' \
     -F 'content_type=image/jpeg' \
     -F 'parent_folder_path=my_files/section1' \
     -H "Authorization: Bearer <token>"
```

Example Response:

```json
{
  "upload_url": "https://some-bucket.s3.amazonaws.com/",
  "upload_params": {
    "key": "/users/1234/files/profile_pic.jpg",
    <unspecified parameters; key above will not necesarily be present either>
  }
}
```

At this point, the file object has been created in Canvas in a "pending"
state, with no content. It will not appear in any listings in the UI until
the next two steps are completed. The returned Signature is valid for 30
minutes.

### Step 2: Upload the file data to the URL given in the previous response

Using the data in the JSON response from Step 1, the application can now
upload the actual file data, by POSTing a specially formulated request to
the URL given in the `upload_url` field of the response.

Depending on how Canvas is configured, this upload URL might be another URL
in the same domain, or a Amazon S3 bucket, or some other URL. In order to
work with all Canvas installations, applications should be very careful to
follow this documentation and not make any undocumented assumptions about
the upload workflow.

This second request must be POSTed as a multipart/form-data request to
accomodate the file data. The parameters POSTed with this request come
directly from the `upload_params` part of the JSON response in Step 1.

The only addition is the `file` parameter which *must* be posted as the
last parameter following all the others.

Example Request:

```bash
curl '<upload_url>' \
     -F 'key=/users/1234/files/profile_pic.jpg' \
     <any other parameters specified in the upload_params response>
     -F 'file=@my_local_file.jpg'
```

The access token is not sent with this request.

Example Response:

    HTTP/1.1 301 Moved Permanently
    Location: https://<canvas>/api/v1/files/1234/create_success?uuid=ABCDE

IMPORTANT:  The request is signed, and will be denied if any parameters
from the `upload_params` response are added, removed or modified.  The
parameters in `upload_params` may vary over time, and between Canvas
installs. It's important for the application to copy over all of the
parameters, and not rely on the names or values of the params for any
functionality.

This example assumes there is a file called `my_local_file.jpg` in the
current directory.

### Step 3: Confirm the upload's success

If Step 2 is successful, the response will be either a 3XX redirect or
201 Created with a Location header set as normal.

In the case of a 3XX redirect, the application needs to perform a GET to
this location in order to complete the upload, otherwise the new file
may not be marked as available. This request is back against Canvas
again, and needs to be authenticated using the normal API access token
authentication.

<p class="note deprecated">
[DEPRECATED] While a POST would be truer to REST semantics, and was
previously called for by this documentation, a GET is recommended at
this point for forwards compatibility with the 201 Created response
described below. POST requests are currently supported for backwards
compatibility at all endpoints that may appear in the Location header,
but are deprecated effective 2019-04-21 (notice given 2018-10-06).
</p>

In the case of a 201 Created, the upload has been complete and the
Canvas JSON representation of the file can be retrieved with a GET from
the provided Location.

Example Request:

```bash
curl -X POST '<Location>' \
     -H 'Content-Length: 0' \
     -H "Authorization: Bearer <token>"
```

Example Response:

```json
{
  "id": 1234,
  "url": "...url to download the file...",
  "content-type": "image/jpeg",
  "display_name": "profile_pic.jpg",
  "size": 302185
}
```

<h2 class='api_method_name' name='method.file_uploads.url' data-subtopic="Uploading Files">
<a name="method.file_uploads.url" href="#method.file_uploads.url">Uploading via URL</a>
</h2>

Instead of uploading a file directly, you can also provide Canvas a
public HTTP or HTTPS URL from which to retrieve the file.

### Step 1a: Posting the file URL to Canvas

The first step is the same as with the "Uploading via POST" flow above,
with the addition of one new parameter:

<dl>
  <dt>url</dt>
  <dd>The full URL to the file to be uploaded. This URL must be publicly accessible.</dd>
</dl>

Example Request:

```bash
curl 'https://<canvas>/api/v1/users/self/files' \
     -F 'url=http://example.com/my_pic.jpg' \
     -F 'name=profile_pic.jpg' \
     -F 'size=302185' \
     -F 'content_type=image/jpeg' \
     -F 'parent_folder_path=my_files/section1' \
     -H "Authorization: Bearer <token>"
```

Example Response:

```json
{
  "upload_url": "https://file-service.url/opaque",
  "upload_params": {
    /* unspecified parameters; contents should be treated as opaque */
  },
  "progress": {
    /* amongst other tags, see the Progress API... */
    "url": "https://canvas.example.edu/api/v1/progress/1"
    "workflow_state": "running"
  }
}
```

### Step 1b: Understanding the response

Canvas' file management is in a moment of transition. For the duration
of this transition, there are two possible behaviors. The newer behavior
includes additional fields in the response to the first request and
expects an additional action from the application.

In the deprecated behavior, Canvas will initiate a "cloning" of the
provided URL by downloading it via Canvas servers. The initial POST was
sufficient to start this and no other action is necessary from the
application.

In the newer behavior, Canvas delegates the cloning of the URL to the
same service that accepts direct uploads. The cloning is kicked off by a
POST by the application to the provided `upload_url` with the provided
`upload_params`, in parallel with a direct upload. The service then
informs Canvas directly when it is complete.

In either case, the cloning of the URL will be performed in the background,
and the file will not necessarily be immediately available when the API
calls complete. Instead, a `progress` object is provided which can be
periodically polled to check the status of the upload.

You can distinguish the new behavior (and expected follow up)
from the old behavior precisely by the presence or absence of the
`upload_url` key.

### Step 2: POST to the URL given in the previous response

If the response to the initial POST includes an `upload_url`, you must
POST to it with the `upload_params` just as if you were performing a
direct upload. The only exception is that the `file` parameter is
omitted. The `Content-Type` is still expected to be multipart/form-data.

Example Request:

```bash
curl '<upload_url>' \
     -F 'target_url=http://example.com/my_pic.jpg' \
     <any other parameters specified in the upload_params response>
```

Example Response:

    HTTP/1.1 201 Created

This step is not necessary with the old behavior.

### Step 3: Check to see when the upload is complete

If the application needs to know the outcome of the upload, it can use
the {api:ProgressController#Show Progress endpoint} to query the status.
On success, the created attachment's id will be returned in the results
of the Progress object as `id`.
