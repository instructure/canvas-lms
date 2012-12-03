Masquerading
============

Masquerading is making an API call on behalf of another user. It will behave as if the target user had made the API
call with his own access token (even if he doesn't have one), including permission checks, enrollments, etc. In order
to masquerade via the API, the calling user must have the "Become other users" permission. If the target user is also
an admin, the calling user must additionally have every permission that the target user has. For auditing purposes,
all calls log both the calling user and the target user.

To masquerade, add an as_user_id parameter to any request. It can be either a Canvas user ID, or an SIS user ID
(as described in <a href="object_ids.html">SIS IDs</a>):

    curl 'https://<canvas>/api/v1/users/self/activity_stream?as_user_id=sis_user_id:brian' \
         -H "Authorization: Bearer <token>"

Masquerading could be useful in a number of use cases:

 * For developing an admin tool
 * For accessing APIs that can only be called on self (i.e. the activity stream as shown above)
 * For a portal type application that's already tightly integrated with an SIS and is managed
   by the school, to avoid going through the OAuth flow for every student