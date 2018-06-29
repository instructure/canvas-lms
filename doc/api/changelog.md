API Change Log
==============

The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the <a href="https://www.canvaslms.com/policies/api-policy">Canvas API Policy page</a>.

<ul><li>For a summary of all deprecations, view the <a href="file.breaking.html">breaking changes API page</a>.</li>
<li>This page documents API changes for the last four releases. For prior releases, view the <a href="file.changelog_archive.html">API Change Log archive page</a>.</li>
</ul>

<h2>2018-07-14</h2>
  <h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td>Plagiarism Detection Platform APIs</td>
<td></td>
<td>In the API page sidebar, moved all API documentation for the plagiarism platform to the External Tools section</td>
</tr>
</table>

<h3>Additions</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="api_token_scopes.html">API Token Scopes</a></td>
<td></td>
<td>Added endpoint</td>
</tr>
<tr>
<td><a href="proficiency_ratings.html">Proficiency Ratings API</a></td>
<td></td>
<td>Added endpoint</td>
</tr>
</table>

<h2>2018-06-23</h2>
  <h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="users.html">Users API</a></td>
<td>Get a Pandata JWT Token and its Expiration Date endpoint</td>
<td>Changed endpoint to reflect use for current user only (/api/v1/users/self/pandata_token)<br><br>
Clarified description in that endpoint is currently only available to the mobile developer keys</td>
</tr>
</table>
<p></p>
<table class="changelog">
<tr>
<th>API Responses</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="files.html">Files API</a></td>
<td>File Object</td>
<td>Updated file object example and ordering; object returns uuid, folder_id, display_name, and modified_at fields</td>
</tr>
</table>

<h3>Additions</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="sis_imports.html">SIS Imports API</a></td>
<td>Restore workflow_states of SIS imported items</td>
<td>Added endpoint to restore states for sis_imports</td>
</tr>
</table>

<h2>2018-06-02</h2>
  <h3>Additions</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="content_exports.html">Content Exports API</a></td>
<td>Export Content Endpoint</td>
  <td>Added select parameter</td>
</tr>
<tr>
<td><a href="external_tools.html">External Tools API</a></td>
<td>Create an External Tool Endpoint</td>
<td>Added account_navigation[display_type] parameter</td>
</tr>
<tr>
<td><a href="file.assignment_tools.html">Grade Passback External Tools</a></td>
<td>
  </td>
<td>Added Submission Details Return Extension documentation, which includes information about supporting Submitted At timestamps</td>
</tr>
<td><a href="submissions.html">Submissions API</a></td>
<td>Submission Summary Endpoint</td>
<td>Added grouped parameter</td>
</tr>
<td><a href="users.html">Users API</a></td>
<td>Create a User endpoint</td>
<td>Added destination parameter</td>
</tr>
</table>
<p></p>

<h2>2018-05-12</h2>

<h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="accounts.html">Accounts API</a></td>
<td>List Active Courses in an Account endpoint</td>
<td>sort parameter: replaced <i>subaccount</i> value with <i>account_name</i> value. Subaccount can still be used as a value for backward compatibility.</td>
</tr>
<tr>
<td><a href="user_observees.html">User Observees API</a></td>
<td>List Observees endpoint</td>
<td>Clarifies that the returned observees will include the observation_link_root_account_ids attribute</td>
</tr>
</table>

<h3>Additions</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="accounts.html">Accounts API</a></td>
<td>List Active Courses in an Account endpoint</td>
<td>Include parameter: Added account_name value</td>
</tr>
<tr>
<td><a href="communication_channels.html">Communication Channels API</a></td>
<td>Delete a Push Notification endpoint</td>
<td>Added endpoint</td>
</tr>
<tr>
<td><a href="courses.html">Courses API</a></td>
<td>List Your Courses endpoint<br><br>
  List Courses for a User endpoint<br><br>
Get a Single Course endpoint</td>
<td>include parameter: Added account object</td>
</tr>
<tr>
<td><a href="enrollments.html">Enrollments API</a></td>
<td>List Enrollments endpoint</td>
<td>Added enrollment_term_id parameter</td>
</tr>
<tr>
<td><a href="submissions.html">Submissions API</a></td>
<td>List Submissions for Multiple Assignments endpoint</td>
<td>Added graded_since parameter</td>
</tr>
<td><a href="users.html">Users API</a></td>
<td>Create a User endpoint</td>
<td>Added destination parameter</td>
</tr>
<tr>
<td><a href="user_observees.html">User Observees API</a></td>
<td>Add an Observee with Credentials endpoint<br><br>
  Add an Observee endpoint<br><br>
  Remove an Observee endpoint</td>
<td>Added root_account_id parameter</td>
</tr>
</table>
