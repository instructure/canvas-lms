Group Category Import Format Documentation
==========================================

Group categories can be updated in bulk by using the Group Categories Import API. Each row
in a CSV file represents a user to be added to a group in the group category.

Standard CSV rules apply (including adherence to the CSV RFC 4180 format):

* The first row will be interpreted as a header defining the ordering of your columns. This
header row is mandatory.
* Fields that contain a comma must be surrounded by double-quotes.
* Fields that contain double-quotes must also be surrounded by double-quotes, with the
internal double-quotes doubled. Example: Chevy "The Man" Chase would be included in
the CSV as "Chevy ""The Man"" Chase".

All text should be UTF-8 encoded.

All timestamps are sent and returned in ISO 8601 format.  All timestamps default to UTC time zone
unless specified.

    YYYY-MM-DDTHH:MM:SSZ

Group Category Data Format
==========================

group_category.csv
------------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Required</th>
<th>Description</th>
</tr>
<tr>
<td>canvas_user_id</td>
<td>text</td>
<td>✓&#42;</td>
<td>The canvas id for a user, required to identify a user.</td>
</tr>
<tr>
<td>user_id</td>
<td>text</td>
<td>✓&#42;</td>
<td>A unique identifier used to reference users in the enrollments table.
This identifier must not change for the user, and must be globally unique. In the user interface,
 this is called the SIS ID.</td>
</tr>
<tr>
<td>login_id</td>
<td>text</td>
<td>✓&#42;</td>
<td>The name that a user will use to
login to Instructure. If you have an authentication service configured (like
LDAP), this will be their username from the remote system.</td>
</tr>
<tr>
<td>group_name</td>
<td>text</td>
<td>✓&#42;</td>
<td>The name of the group.</td>
</tr>
<tr>
<td>canvas_group_id</td>
<td>text</td>
<td>✓&#42;</td>
<td>The canvas id for a group.</td>
</tr>
<tr>
<td>group_id</td>
<td>text</td>
<td>✓&#42;</td>
<td>A unique identifier used to reference groups in the group_users data.
This identifier must not change for the group, and must be globally unique.</td>
</tr>
</table>

&#42; canvas_user_id, user_id, or login_id is required and group_name, 
canvas_group_id or group_id is required.

Sample:
<pre>
canvas_user_id,user_id,login_id,group_name,canvas_group_id,group_id
92,,,Awesome Group,,
,13aa3,,,45,
,,mlemon,,,g125
</pre>
