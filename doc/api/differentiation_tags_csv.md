Differentiation Tags Import Format Documentation
================================================

Differentiation Tags can be updated in bulk by using the Differentiation Tags Import API. Each row
in a CSV file represents a user to be added to a tag, where a tag set can be specified.

Tags and tag sets that don't exist in the UI will be created. Tags that are created will only use the
tag_name column for creation. User columns in the file are used to identify the user to be
added to the tag. Users names are available in the Differentiation Tags export, but not used or
updated in the import process.

If a tag set is provided, tags that don't exist in the UI will be created under that set and existing
tags will be moved (along with their memberships) to that tag set.

Standard CSV rules apply (including adherence to the CSV RFC 4180 format):

* The first row will be interpreted as a header defining the ordering of your columns. This
header row is mandatory.
* Fields that contain a comma must be surrounded by double-quotes.
* Fields that contain double-quotes must also be surrounded by double-quotes, with the
internal double-quotes doubled. Example: Chevy "The Man" Chase would be included in
the CSV as "Chevy ""The Man"" Chase".

All text should be UTF-8 encoded.

Differentiation Tag Data Format
===============================

differentiation_tag.csv
------------------------

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
<td>tag_name</td>
<td>text</td>
<td>✓&#42;</td>
<td>The name of the differentiation tag.</td>
</tr>
<tr>
<td>canvas_tag_id</td>
<td>text</td>
<td>✓&#42;</td>
<td>The canvas id for a differentiation tag.</td>
</tr>
<tr>
<td>tag_id</td>
<td>text</td>
<td>✓&#42;</td>
<td>A unique identifier used to reference tags.
This identifier must not change for the tag, and must be globally unique.
This column is for identification and does not populate new tags with sis_ids</td>
</tr>
<tr>
<td>tag_set_name</td>
<td>text</td>
<td>&#42;</td>
<td>The name of the differentiation tag set.</td>
</tr>
<tr>
<td>canvas_tag_set_id</td>
<td>text</td>
<td>&#42;</td>
<td>The canvas id for a differentiation tag set.</td>
</tr>
<tr>
<td>tag_set_id</td>
<td>text</td>
<td>&#42;</td>
<td>A unique identifier used to reference tag sets.
This identifier must not change for the tag, and must be globally unique.
This column is for identification and does not populate new tag sets with sis_ids</td>
</tr>
</table>

&#42; canvas_user_id, user_id, or login_id is required and tag_name,
canvas_tag_id or tag_id is required. If you would like to specify a tag set,
tag_set_name, canvas_tag_set_id or tag_set_id is required.

Sample:
<pre>
canvas_user_id,user_id,login_id,tag_name,canvas_tag_id,tag_id,tag_set_name,canvas_tag_set_id,tag_set_id
92,,,Awesome Tag,,,Awesome Tag Set,,
,13aa3,,,45,,,,
,,mlemon,,,g125,,,
</pre>

<pre>
canvas_user_id,user_id,login_id,tag_name
92,,,Awesome Tag
,13aa3,,Other Tag
,,mlemon,Awesome Tag
</pre>
