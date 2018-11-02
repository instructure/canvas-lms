API Change Log
==============

The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the <a href="https://www.canvaslms.com/policies/api-policy">Canvas API Policy page</a>.

<ul><li>For a summary of all deprecations, view the <a href="file.breaking.html">breaking changes API page</a>.</li>
<li>This page documents API changes for the last four releases. For prior releases, view the <a href="file.changelog_archive.html">API Change Log archive page</a>.</li>
</ul>

<h2>2018-11-17</h2>

<h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="roles.html">Roles API</a></td>
<td>Create a New Role Endpoint</td>
<td>Permissions parameter: Updated account- and course-level roles to match roles in the Canvas Permissions page
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
<td><a href="assignments.html">Assignments API</a></td>
<td>List Assignments Endpoint</td>
<td>Clarified that the paginated list of assignments is returned for the current course or assignment group
</tr>
<tr>
<td><a href="rubrics.html">Rubrics API</a></td>
<td>Create a Single Rubric Endpoint</td>
<td>Clarified the rubric return value</td>
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
<td><a href="file.tools_variable_substitutions.html">LTI Variable Substitutions</a></td>
<td>com.instructure.Person.name_sortable</td>
<td>Added variable that returns the sortable name of the launching user.
<br><br>Availability: when launched by a logged in user
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
<td><a href="sis_imports.html">SIS Imports API</a></td>
<td>Get the Current Importing SIS Import Endpoint</td>
<td>Added endpoint to return the SIS imports that are currently processing for an account
</table>

<h3>Removals</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="planner.html">Planner API</td>
<td></td>
<td>Removed the beta warning banner from the API documentation</td>
</tr>
</table>


<h2>2018-10-27</h2>

<h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="conversations.html">Conversations API</a></td>
<td>Create a Conversation Endpoint</td>
<td>Recipients parameter: Added clarification when the course/group has over 100 enrollments, bulk_message and group_conversation must be set to true
</tr>
<tr>
<td><a href="quiz_extensions.html">Quiz Extensions API</a></td>
<td>Set Extensions for Student Quiz Submissions Endpoint</td>
<td>All parameters: Added quiz_extensions to parameter name</td>
</tr>
<tr>
<td><a href="quiz_submissions.html">Quiz Submissions API</a></td>
<td>Update Student Question Scores and Comment Endpoint</td>
<td>All parameters: Added quiz_submissions to parameter name</td>
</tr>
</table>

<h3>Additions</h3>
<table class="changelog">
<tr>
<th>API Responses</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="plagiarism_detection_platform_assignments.html">Plagiarism Detection Platform Assignments API</a></td>
<td>LtiAssignment Object</td>
<td>Added LTI Course ID and Course ID return parameters
</tr>
<tr>
<td><a href="plagiarism_detection_submissions.html">Plagiarism Detection Submissions API</a></td>
<td>Submission Object</td>
<td>Added LTI Course ID and Course ID return parameters</td>
</tr>
</table>


<h2>2018-10-06</h2>

<h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="accounts.html">Accounts API</a></td>
<td>Permissions Endpoint</td>
<td>Added links to Course and Group permissions</td>
</tr>
<tr>
<td><a href="courses.html">Courses API</a></td>
<td>Permissions Endpoint</td>
<td>Added links to Account and Group permissions</td>
</tr>
</table>
<p></p>
<table class="changelog">
<tr>
<th>Basics</th>
<th>File</th>
<th></th>
</tr>
<tr>
<td><a href="file.file_uploads.html">Uploading Files</td>
<td>Uploading via URL</td>
<td>Explains file management system transition and clarifies newer file upload process
</td>
</tr>
</table>
<p></p>
<table class="changelog">
<tr>
<th>OAuth2</th>
<th>Endpoint</th>
<th></th>
</tr>
<tr>
<td><a href="file.oauth_endpoints.html">OAuth2 Endpoints</td>
<td>Get login/oauth2/auth</td>
<td>Below parameters table, clarified info on scopes for oath2 endpoint
</td>
</tr>
</table>

<h3>Additions</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
<tr>
<td><a href="file.assignment_external_tools.html">Assignment External Tools</a></td>
<td></td>
<td>Added content page</td>
</tr>
<tr>
<td><a href="groups.html">Groups API</a></td>
<td>Permissions Endpoint</td>
<td>Added endpoint
</td>
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
<td><a href="courses.html">Courses API</a></td>
<td>Course Object</td>
<td>Added created_at parameter, which returns the date the course was created
</td>
</tr>
</table>

<h3>Removals</h3>
<table class="changelog">
<tr>
<th>Basics</th>
<th>File</th>
<th></th>
</tr>
<tr>
<td><a href="file.file_uploads.html">Uploading Files</td>
<td>Uploading via URL</td>
<td>Explains file management system transition and identifies deprecated behavior
</td>
</tr>
</table>
