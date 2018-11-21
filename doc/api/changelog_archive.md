API Change Log Archive
================

The Change Log Archive page displays previous API changes in the <a href="file.changelog.html">API Change Log</a> older than the last four releases. The release date indicates the date that the API code was made available in the production environment.
<p>

<h2>Prior Updates</h2>

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

<h2>2018-04-21</h2>
<h3>Changes</h3>
<table class="changelog">
<tr>
<th>API Calls</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="courses.html">Courses API</a></td>
<td>Permissions endpoint</td>
<td>Includes link to Accounts API Permissions endpoint<br><br>
Clarifies that permission names are documented in the Create a Role endpoint</td>
</tr>
<tr>
<td><a href="sections.html">Sections API</a></td>
<td>Create Course Section endpoint</td>
<td>Course_section[sis_section_id] parameter: Notes the user must have the manage_sis permissions to set</td>
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
<td>Permissions endpoint</td>
<td>New endpoint: GET /api/v1/accounts/:account_id/permissions</td>
</tr>
<tr>
<td><a href="discussion_topics.html">Discussion Topics API</a></td>
<td>Get a Single Topic endpoint<br><br>
List Discussion Topics endpoint<br><br></td>
<td>Added include parameter<br><br>
Added overrides as an allowed value in the include parameter</td>
</tr>
<tr>
<td><a href="sections.html">Sections API</a></td>
<td>Create Course Section endpoint</td>
<td>course_section[integration_id] parameter: sets the integration_id of the section</td>
</tr>

<tr>
<td><a href="sis_imports.html">SIS Imports API</a></td>
<td>Import SIS Data endpoint</td>
<td>skip_deletes parameter: can be used on any type of SIS import; when set, the import will skip any deletes</td>
</tr>
<tr>
<td><a href="users.html">Users API</a></td>
<td>Get a Pandata JWT Token and its Expiration Date endpoint</td>
<td>Returns a jwt token, which can be used to send events to Canvas Data</td>
</tr>
</table>
<p></p>
<p></p>
<table class="changelog">
<tr>
<th>API Responses</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="modules.html">Modules API</a></td>
<td>Module object<br><br>
ModuleItem SequenceNode object<br><br>
ModuleItemSequence object</td>
<td>Returns the published parameter<br><br>
Returns the mastery_path parameter and includes examples for the current and next items in the course<br><br>
Returns full examples for items and modules arrays</td>
</tr>
<tr>
<td><a href="sis_import_errors.html">SIS Import Errors API</a></td>
<td>Get SIS Import Error List endpoint</td>
<td>Returns a list of SIS import errors for an account or SIS import </td>
</tr>
<tr>
<td><a href="sis_imports.html">SIS Imports API</a></td>
<td>SISImport object</td>
<td>workflow_state parameter: returns whether the SIS import was aborted<br><br>
skip_deletes parameter: returns whether the import skipped any deleted objects</td>
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
<td><a href="file.sis_csv.html">SIS CSV Format</a></td>
<td>changes_sis_id.csv</td>
<td>Added group_category as a type<br><br>
old_integration_id field: description clarifies that this field does not support group categories<br><br>
new_integration_id field: description clarifies that this field does not support group categories</td>
</tr>
</table>
