API Change Log
==============

The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the <a href="https://www.canvaslms.com/policies/api-policy">Canvas API Policy page</a>.

<ul><li>For a summary of all deprecations, view the <a href="file.breaking.html">breaking changes API page</a>.</li>
<li>This page documents API changes for the last four releases. For prior releases, view the <a href="file.changelog_archive.html">API Change Log archive page</a>.</li>
</ul>

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
<td>Added API</td>
</tr>
<tr>
<td><a href="proficiency_ratings.html">Proficiency Ratings API</a></td>
<td></td>
<td>Added API</td>
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
<td>Restore states for sis_imports</td>
</tr>
</table>
<p></p>
