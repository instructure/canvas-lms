API Change Log
==============

The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the <a href="https://www.canvaslms.com/policies/api-policy">Canvas API Policy page</a>.

For a summary of all deprecations, view the <a href="file.breaking.html">breaking changes API page</a>.

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
<table class="changelog">
<tr>
<th>API Responses</th>
<th>Function</th>
<th></th>
</tr>
<tr>
<td><a href="scopes.html">Scopes API</a></td>
<td>Scope Object</td>
<td>Returns the scope's associated resource and the HTTP verb for the scope</td>
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
<td><a href="file.sis_csv.html">SIS CSV Format</a></td>
<td>changes_sis_id.csv</td>
<td>Added group_category as a type<br><br>
old_integration_id field: description clarifies that this field does not support group categories<br><br>
new_integration_id field: description clarifies that this field does not support group categories</td>
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
