# Uploading Files

Creating a file is a three step process:

1. Notify Canvas that you are uploading a file with a POST to the file
   creation endpoint. This POST will include the file name and file size,
   along with information about what context the file is being created in.
2. Upload the file using the information returned in the first POST request.
3. On successful upload, the API will respond with a redirect. This
   redirect needs to be followed to complete the upload, or the file may not appear.

## Step 1: Telling Canvas about the file upload and getting a token

The first step is to POST to the relevant API endpoint, depending one where
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
</dl>

Example Request:

    curl 'https://<canvas>/api/v1/users/self/files' \
         -F 'name=profile_pic.jpg' \
         -F 'size=302185' \
         -F 'content_type=image/jpeg' \
         -F 'parent_folder_path=my_files/section1' \
         -H "Authorization: Bearer <token>"

Example Response:

    {
      "upload_url": "https://some-bucket.s3.amazonaws.com/",
      "upload_params": {
        "key": "/users/1234/files/profile_pic.jpg",
        "acl": "private",
        "Filename": "profile_pic.jpg",
        "AWSAccessKeyId": "some_id",
        "Policy": "some_opaque_string",
        "Signature": "another_opaque_string",
        "Content-Type": "image/jpeg"
      }
    }

At this point, the file object has been created in Canvas in a "pending"
state, with no content. It will not appear in any listings in the UI until
the next two steps are completed.

## Step 2: Upload the file data to the URL given in the previous response

Using the data in the JSON response from Step 1, the application can now
upload the actual file data, by POSTing a specially formulated request to
the URL given in the `upload_url` field of the response.

Depending on how Canvas is configured, this upload URL might be another URL
in the same domain, or a Amazon S3 bucket, or some other URL.  In order to
work with all Canvas installations, applications should be very careful to
follow this documentation and not make any undocumented assumptions about
the upload workflow.

This second request must be POSTed as a multipart/form-data request to
accomodate the file data. The parameters POSTed with this request come
directly from the `upload_params` part of the JSON response in Step 1.

The only addition is the `file` parameter which *must* be posted as the
last parameter following all the others.

Example Request:

    curl '<upload_url>' \ 
         -F 'key=/users/1234/files/profile_pic.jpg' \ 
         -F 'acl=private' \ 
         -F 'Filename=profile_pic.jpg' \ 
         -F 'AWSAccessKeyId=some_id' \ 
         -F 'Policy=some_opaque_string' \ 
         -F 'Signature=another_opaque_string' \ 
         -F 'Content-Type=image/jpeg' \ 
         -F 'file=@my_local_file.jpg'

The access token is not sent with this request.

Example Response:

    HTTP/1.1 301 Moved Permanently
    Location: https://<canvas>/api/v1/s3_success/1234?uuid=ABCDE

IMPORTANT:  The request is signed, and will be denied if any parameters
from the `upload_params` response are added, removed or modified.  The
parameters in `upload_params` may vary over time, and between Canvas
installs. It's important for the application to copy over all of the
parameters, and not rely on the names or values of the params for any
functionality.

This example assumes there is a file called `my_local_file.jpg` in the
current directory.

## Step 3: Confirm the upload's success

If Step 2 is successful, the response will be a 3XX redirect with a
Location header set as normal. The application needs to perform a POST to
this location in order to complete the upload, otherwise the new file may
not be marked as available. This request is back against Canvas again,
and needs to be authenticated using the normal API access token
authentication.

Example Request:

    curl -X POST '<Location>' \
         -H 'Content-Length: 0' \
         -H "Authorization: Bearer <token>"

Example Response:

    {
      'id': 1234,
      'url': '...url to download the file...',
      'content-type': 'image/jpeg',
      'display_name': 'profile_pic.jpg',
      'size': 302185
    }
