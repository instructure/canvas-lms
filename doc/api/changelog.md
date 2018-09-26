API Change Log
==============

The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the <a href="https://www.canvaslms.com/policies/api-policy">Canvas API Policy page</a>.

<ul><li>For a summary of all deprecations, view the <a href="file.breaking.html">breaking changes API page</a>.</li>
<li>This page documents API changes for the last four releases. For prior releases, view the <a href="file.changelog_archive.html">API Change Log archive page</a>.</li>
</ul>

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
<td>Created_at parameter: Returns the date the course was created
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

<h2>2018-09-15</h2>

<h3>Additions</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="custom_gradebook_columns.html">Custom Gradebook Columns API</a></td>
<td>Bulk Update Column Data</td>
<td>Sets the content of custom columns
</td>
</tr>
<tr>
<td><a href="file.tools_variable_substitutions.html">LTI Variable Substitutions</a></td>
<td>com.instructure.Assignment.anonymous_grading<br><br>
    com.Instructure.membership.roles</td>
<td>Returns true if the assignment has anonymous grading enabled<br><br>
    Returns true if the assignment has anonymous grading enabled</td>
</tr>
<tr>
<td><a href="sis_imports.html">SIS Imports API</a></td>
<td>SIS Import Object</td>
<td>CSV_attachments parameter: Returns an array of CSV files for processing</td>
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
<td><a href="accounts.html">Accounts API</a></td>
<td>Get Help Links Endpoint</td>
<td>Returns the help links for that account</td>
</tr>
<tr>
<td><a href="blueprint_courses.html">Blueprint Courses API</a></td>
<td>BlueprintSubscription Object<br><br>
    List Blueprint Subscriptions Endpoint</td>
<td>Returns the ID of the blueprint course and blueprint template the associated course is subscribed to<br><br>
  Returns a list of blueprint subscriptions for the given course (currently a course may have no more than one)</td>
</tr>
</table>

<h2>2018-08-04</h2>

<h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="outcome_results.html">Outcome Results API</a></td>
<td>Get Outcome Result Rollups</td>
<td>Aggregate parameter: Clarified that the median is a separate parameter.</td>
</tr>
</table>
<p></p>
<table class="changelog">
<tr>
<th>CSV Format</th>
<th>File</th>
<th></th>
</tr>
<tr>
<td><a href="outcomes_csv.html">Outcomes Data Format</td>
<td>outcomes.csv</td>
<td>Vendor_guid field: Clarified that vendor_guid IDs will prefix “canvas_outcome:” and “canvas_outcome_group:” for outcomes and groups, respectively. In addition, these prefixes are reserved; newly created outcomes and groups may not have vendor_guid fields with these prefixes./td>
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
<td><a href="Outcome_results.html">Outcome Results API</a></td>
<td>Get Outcome Result Rollups</td>
<td>Exclude parameter: Specified additional values to exclude. “Missing_user_rollups” excludes rollups for users without results.<br><br>
  Aggregate_stat parameter: If aggregate rollups requested, then this value determines what statistic is used for the aggregate. Defaults to “mean” if this value is not specified.
</td>
</tr>
</table>
