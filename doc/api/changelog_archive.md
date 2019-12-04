API Change Log Archive
======================

As of 2019-12-04, the API Change Log Archive has moved to the Canvas Community. Please see the [Canvas API page](https://community.canvaslms.com/community/answers/releases/canvas-apis).

This page will be removed from Canvas LMS API Documentation on 2020-03-25.


###Archive

The Change Log Archive page displays previous API changes in the [API Change Log](file.changelog.html) older than the last four releases.

The release date indicates the date that the API code was made available in the production environment.

<div class="changelog"></div>
## 2019-09-21
### Changes
| Resources | Function |     |
|----------------------|----------------------|--------------------------|
| [Submissions API] | Upload a File Endpoint | Added validation for file type; if a submission is set to accept only specific file types, the endpoint rejects uploaded file types not included for submission uploads |

[Submissions API]: submissions.html

## 2019-07-31
### Additions
| OAuth2 | File |     |
|----------------------|----------------------|--------------------------|
| [OAuth2 Overview] | Description | Added link to LTI Advantage documentation and section for accessing LTI Advantage Services |

[OAuth2 Overview]: file.oauth.html

<p></p>

| Resources | Function |     |
|----------------------|----------------------|--------------------------|
| [Assignments API] | List Assignments Endpoint | Added post_to_sis parameter |

[Assignments API]: assignments.html

<p></p>

| SIS | File |  |
|----------------------|----------------------|--------------------------|
| [SIS CSV Format] | Logins.csv | Added file |

[SIS CSV Format]: file.sis_csv.html

### Changes
| SIS | File |  |
|----------------------|----------------------|--------------------------|
| [SIS CSV Format] | Courses.csv | Clarified description for account_id to specify that new courses will be attached to the root account if not specified |

[SIS CSV Format]: file.sis_csv.html

## 2019-07-13
### Additions
| Basics | File |  |
|----------------------|----------------------|--------------------------|
| [GraphQL] |  | Added file |

[GraphQL]: file.graphql.html

<p></p>

| External Tools | Function |  |
|----------------------|----------------------|--------------------------|
| [Variable Substitutions] | Canvas.course.sectionRestricted | Added variable that corresponds with whether the user was enrolled with the restriction to only interact with users in their own section |

[Variable Substitutions]: file.tools_variable_substitutions.html

<p></p>

| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Assignment Object | Added posted_manually parameter |
| [Submissions API] | Submissions Object | Added posted_at parameter |

[Assignments API]: assignments.html
[Submissions API]: submissions.html

### Changes
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Assignment Object | Muted parameter: Updated description for muted parameter regarding Old and New Gradebooks |
| [Conversations API] | Create a Conversation Endpoint | Group_conversation parameter: updated description to indicate the value must be set to true if the number of recipients is over the set maximum (100) |

[Assignments API]: assignments.html
[Conversations API]: conversations.html

### Removals
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Create an Assignment Endpoint | Assignment[muted] parameter: deprecated for New Gradebook, to be removed 2020-01-18<br><br>This parameter may only still be used with the Old Gradebook |

[Assignments API]: assignments.html

## 2019-06-22
### Additions
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Users API] | List Users in Account Endpoint | Added enrollment_type parameter |

[Users API]: Users.html

## 2019-06-01
### Additions
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Files API] | Get Uploaded Media Folder for User Endpoint | Added endpoint |
| [Originality Report API] | Create an Originality Report<br><br>Edit an Originality Report | Added originality_report[error_message] parameter
|                     | Originality Report Object | Returns Error_report |

[Files API]: files.html
[Originality Report API]: originality_reports.html

### Removals
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [File Uploads] | Uploading via POST Process | Step 3: Deprecated POST requests in favor of GET requests for forward compatibility

[File Uploads]: file.file_uploads.html

## 2019-05-11
### Additions
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Create an Assignment Endpoint<br><br>Edit an Assignment Endpoint | Added assignment [grader_count], assignment [final_grader_id], assignment [grader_comments_visible_to_graders], assignment [graders_anonymous_to_graders], assignment [graders_names_visible_to_final_grader], assignment [anonymous_grading] parameters
|  [SIS Imports API]         | Import SIS Data Endpoint | Added diff_row_count_threshold parameter
|  [Users API]         | Merge User Into Another User Endpoint | Added user merge details and caveats for behaviors relating to avatars, terms of use, communication channels, enrollments, submissions, access tokens, conversations, favorites, and LTI tools

[Assignments API]: assignments.html
[SIS Imports API]: sis_imports.html
[Users API]: users.html

## 2019-04-20
### Additions
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Submissions API] | Grade or Comment on a Submission Endpoint | Rubric_assessment parameter: Added rubric_assessment[criterion_id][rating_id] sub-parameter<br><br>Added rating IDs to example rubric in description
|  [Users API]         | Update User Settings Endpoint | Added hide_dashcard_color_overlays parameter

[Submissions API]: submissions.html
[Users API]: users.html

## 2019-03-30
### Additions
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Content Migrations API] | Create a Content Migration Endpoint | Added selective_import parameter
|                          | List Items for Selective Import Endpoint | Added endpoint

[Content Migrations API]: content_migrations.html

### Changes
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [Content Migrations API] | Update a Content Migration Endpoint | Clarified the endpoint takes same arguments as creating a migration<br><br>Clarified that updating the content migration will also be used when importing content selectively |

[Content Migrations API]: content_migrations.html

## 2019-03-09
### Changes
| Resources | Function |  |
|----------------------|----------------------|--------------------------|
| [SIS Imports API] | Imports SIS Data Endpoint | Added change_threshold parameter

[SIS Imports API]: sis_imports.html

### Removals
| Resources | Function |      |
|----------------------|----------------------|--------------------------|
| [Users API] | To Do Items Endpoint | Removed mention of user dashboard, as this API call is not used for the dashboard

[Users API]: users.html

## 2019-02-16
### Additions
| Resources | Function |      |
|----------------------|----------------------|--------------------------|
| [Users API] | Edit a User Endpoint | Added [user]title and [user]bio parameters

[Users API]: users.html

## 2019-01-26
### Additions
| Resources | Function |      |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Assignment Object | Returns grader_count, final_grader, grader_comments_visible_to_graders, graders_anonymous_to_graders, grader_names_visible_to_final_grader, and anonymous_grading parameters |
| [Submissions API] | Submission Object | Returns UserDisplay parameter |
| [Users API] |      | Added AnonyousUserDisplay Object |

[Assignments API]: assignments.html
[Submissions API]: submissions.html
[Users API]: users.html

### Changes
| Resources | Function |      |
|----------------------|----------------------|--------------------------|
| [Submissions API]  |  List Gradeable Students Endpoint | Added clarification about anonymous grading |

[Submissions API]: submissions.html

### Removals
| Resources | Function |      |
|----------------------|----------------------|--------------------------|
| [Enrollments API] | Enrollment Object | Removed computed_current_score, computed_final_score, computed_current_grade, computed_final_grade, current_period_computed_current_score, current_period_computed_final_score, current_period_computed_current_grade, and current_period_computed_final_grade parameters |

[Enrollments API]: enrollments.html

## 2019-01-05
### Additions
| Resources  | Function  |           |
|------------|-----------|-----------|
| [Assignments API]   | Create an Assignment Endpoint<br><br>Edit an Assignment Endpoint  | Added assignment\[allowed\_attempts\] parameter |
|                   | Assignment Object  | Added allowed\_attempts parameter |
| [Conversations API] | Create a Conversations Endpoint | Added force\_new parameter |
| [Courses API]       | Get a Single Course Endpoint    | Added teacher\_limit parameter                                               |
| [Enrollments API] | Enrollment Object  | Added override\_grade, override\_score, current\_period\_override\_grade, and current\_period\_override\_score parameters<br><br>Added override score clarifications in computed\_current\_score, computed\_final\_score, computed\_final\_grade, current\_period\_computed\_current\_score, current\_period\_computed\_final\_score, current\_period\_computed\_current\_grade, and current\_period\_computed\_final\_grade parameters |
| [Roles API]         | Create a New Role Endpoint      | Permissions\_enabled parameter: Added view\_audit\_trail in permissions list |
| [SIS Imports API] | SIS Import Statistic Object <br><br>SIS Import Statistic Objects | Added object examples |
|               | SIS Import Object  | Workflow\_state parameter: Added initializing and failed descriptions <br><br>Added statistics parameter                           |
| [Submissions API] | Submission Object  | Added extra\_attempts parameter  |

  [Assignments API]: assignments.html
  [Enrollments API]: enrollments.html
  [Conversations API]: conversations.html
  [Courses API]: courses.html
  [Roles API]: roles.html
  [SIS Imports API]: sis_imports.html
  [Submissions API]: submissions.html

### Changes
| OAuth2            | File             |                          |
|----------------------|----------------------|--------------------------|
| [Developer Keys] |                      | Verified and corrected all links in document            |

  [Developer Keys]: file.developer_keys.html

<p></p>
| Resources            | Function             |                          |
|----------------------|----------------------|--------------------------|
| [Files API]          | Delete File Endpoint | Clarified endpoint usage and added permanent deletion warning |

  [Files API]: files.html

### Removals
| External Tools       | Function |   |
|---------------|----------|---|
| [Navigation Tools] |     | Removed incorrect auto-generated links from page |

[Navigation Tools]: file.navigation_tools.html

<p></p>
| Resources     | Function  |   |
|---------------|-----------|---|
| [Courses API] | List Users in Course Endpoint | Include parameter: Removed email as an optional parameter |

  [Courses API]: courses.html

## 2018-12-08
### Additions
| Resources               | Function                          |   |
|-------------------------|-----------------------------------|---|
| [Courses API] | List Your Courses Endpoint | Include parameter: Added graded period parameters to be returned even if total grades are hidden in the course |
| [SIS Import Errors API] | SISImportError Object             | Added row\_info parameter, which displays the contents of the line that had the error |
| [Users API]             | List the Activity Stream Endpoint | Added only\_active\_courses parameter |

  [Courses API]: courses.html
  [SIS Import Errors API]: sis_import_errors.html
  [Users API]: users.html

### Changes
| Resources         | Function |   |
|-------------------|----------|---|
| [SIS Imports API] | Abort SIS Import Endpoint<br><br> Get SIS Import List Endpoint | Added clarification that aborting a sis batch can take time and subsequent sis batches begin to process 10 minutes after the abort.<br><br> Workflow\_state parameter: added initializing, failed, restoring, partially\_restored, and restored as allowed values |

  [SIS Imports API]: sis_imports.html

## 2018-11-17
### Additions
| External Tools                    | Function                              |    |
|------------------------------|---------------------------------------|----|
| [Variable Substitutions] | com.instructure.Person.name\_sortable | Added variable that returns the sortable name of the launching user. Availability is when launched by a logged in user |

  [Variable Substitutions]: file.tools_variable_substitutions.html

<p></p>
| Resources     | Function                                      |   |
|-------------------|-----------------------------------------------|---|
| [SIS Imports API] | Get the Current Importing SIS Import Endpoint | Added endpoint to return the SIS imports that are currently processing for an account |

  [SIS Imports API]: sis_imports.html

### Changes
| Resources   | Function                   |     |
|-------------|----------------------------|-----|
| [Assignments API] | List Assignments Endpoint       | Clarified that the paginated list of assignments is returned for the current course or assignment group |
| [Rubrics API]     | Create a Single Rubric Endpoint | Clarified the rubric return value |
| [Roles API] | Create a New Role Endpoint | Permissions parameter: Updated account- and course-level role names to match roles in the Canvas Permissions page |

  [Assignments API]: assignments.html
  [Rubrics API]: rubrics.html
  [Roles API]: roles.html

### Removals
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Planner API] |          | Removed the beta warning banner from the API documentation |

  [Planner API]: planner.html

## 2018-10-27
### Additions
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Plagiarism Detection Platform Assignments API] | LtiAssignment Object | Added LTI Course ID and Course ID return parameters |
| [Plagiarism Detection Submissions API]          | Submission Object    | Added LTI Course ID and Course ID return parameters |

  [Plagiarism Detection Platform Assignments API]: plagiarism_detection_platform_assignments.html
  [Plagiarism Detection Submissions API]: plagiarism_detection_submissions.html

### Changes
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Conversations API]    | Create a Conversation Endpoint                       | Recipients parameter: Added clarification when the course/group has over 100 enrollments, bulk\_message and group\_conversation must be set to true |
| [Quiz Extensions API]  | Set Extensions for Student Quiz Submissions Endpoint | All parameters: Added quiz\_extensions to parameter name
| [Quiz Submissions API] | Update Student Question Scores and Comment Endpoint  | All parameters: Added quiz\_submissions to parameter name  |

  [Conversations API]: conversations.html
  [Quiz Extensions API]: quiz_extensions.html
  [Quiz Submissions API]: quiz_submissions.html

## 2018-10-06
### Additions
| Resources                   | Function             |                    |
|-----------------------------|----------------------|--------------------|
| [Assignment External Tools] |                      | Added content page |
| [Courses API] | Course Object | Added created\_at parameter, which returns the date the course was created |
| [Groups API]                | Permissions Endpoint | Added endpoint     |

  [Assignment External Tools]: file.assignment_external_tools.html
  [Courses API]: courses.html
  [Groups API]: groups.html

### Changes
| Basics     | File                        |   |
|-------------------|---------------------------------|---|
| [File Uploads] | Uploading via POST | Step 3: Clarified file management system transition and newer file upload process |

  [File Uploads]: file.file_uploads.html

<p></p>

| OAuth2     | Function                        |   |
|-------------------|---------------------------------|---|
| [OAuth2 Endpoints] | Get login/oauth2/auth | Below parameters table, clarified info on scopes for OAuth2 endpoint |

[OAuth2 Endpoints]: file.oauth_endpoints.html

<p></p>

| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Accounts API] | Permissions Endpoint | Added links to Course and Group permissions  |
| [Courses API]  | Permissions Endpoint | Added links to Account and Group permissions |

  [Accounts API]: accounts.html
  [Courses API]: courses.html

### Removals
Basics   | File |     |
|-----------------|--------------------|-------------|
| [File Uploads] | Uploading via POST | Step 3: Deprecated POST requests in favor of GET requests for forward compatibility, to be removed 2019-04-21 |

  [File Uploads]: file.file_uploads.html

## 2018-09-15
### Additions
| External Tools     | File                        |   |
|-------------------|---------------------------------|---|
| [Variable Substitutions]   | com.instructure.Assignment.anonymous\_grading <br><br>com.Instructure.membership.roles | Returns true if the assignment has anonymous grading enabled<br><br>Returns true if the assignment has anonymous grading enabled |

  [Variable Substitutions]: file.tools_variable_substitutions.html

<p></p>
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Accounts API]          | Get Help Links Endpoint     | Returns the help links for that account  |
| [Blueprint Courses API] | BlueprintSubscription Object <br><br>List Blueprint Subscriptions Endpoint | Returns the ID of the blueprint course and blueprint template the associated course is subscribed to <br><br>Returns a list of blueprint subscriptions for the given course (currently a course may have no more than one) |
| [Custom Gradebook Columns API] | Bulk Update Column Data | Sets the content of custom columns  |
| [SIS Imports API]              | SIS Import Object         | CSV\_attachments parameter: Returns an array of CSV files for processing        |

  [Accounts API]: accounts.html
  [Blueprint Courses API]: blueprint_courses.html
  [Custom Gradebook Columns API]: custom_gradebook_columns.html
  [SIS Imports API]: sis_imports.html

## 2018-08-04
### Additions
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Outcome Results API] | Get Outcome Result Rollups | Exclude parameter: Specified additional values to exclude. “Missing\_user\_rollups” excludes rollups for users without results. <br><br>Aggregate\_stat parameter: If aggregate rollups requested, then this value determines what statistic is used for the aggregate. Defaults to “mean” if this value is not specified. |

  [Outcome Results API]: Outcome_results.html

### Changes
| Outcomes     | File                        |   |
|-------------------|---------------------------------|---|
| [Outcomes Data Format] | outcomes.csv | Vendor_guid field: Clarified that vendor_guid IDs will prefix “canvas_outcome:” and “canvas_outcome_group:” for outcomes and groups, respectively. In addition, these prefixes are reserved; newly created outcomes and groups may not have vendor_guid fields with these prefixes. |

[Outcomes Data Format]: outcomes_csv.html

<p></p>
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Outcome Results API] | Get Outcome Result Rollups | Aggregate parameter: Clarified that the median is a separate parameter |

  [Outcome Results API]: Outcome_results.html

## 2018-07-14
### Additions
| Resources                 | Function |           |
|---------------------------|----------|-----------|
| [API Token Scopes]        |          | Added API |
| [Proficiency Ratings API] |          | Added API |

  [API Token Scopes]: api_token_scopes.html
  [Proficiency Ratings API]: proficiency_ratings.html

### Changes
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| Plagiarism Detection Platform APIs |          | In the API page sidebar, moved all API documentation for the plagiarism platform to the External Tools section |

## 2018-06-23
### Additions
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [SIS Imports API] | Restore workflow\_states of SIS Imported Items Endpoint| Added endpoint |

  [SIS Imports API]: sis_imports.html

### Changes
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Files API]   | File Object | Updated file object example and ordering; object returns uuid, folder\_id, display\_name, and modified\_at fields |
| [Users API] | Get a Pandata JWT Token and its Expiration Date  | Changed endpoint to reflect use for current user only (/api/v1/users/self/pandata\_token) <br><br>Clarified description in that endpoint is currently only available to the mobile developer keys |

  [Users API]: users.html
  [Files API]: files.html

## 2018-06-02
### Additions
| External Tools     | File                        |   |
|-------------------|---------------------------------|---|
| [Grading] |                 | Added Submission Details Return Extension documentation, which includes information about supporting Submitted At timestamps |

[Grading]: file.assignment_tools.html

<p></p>
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Content Exports API]           | Export Content Endpoint          | Added select parameter         |
| [External Tools API]            | Create an External Tool Endpoint | Added account\_navigation\[display\_type\] parameter                 |
| [Submissions API]               | Submission Summary Endpoint      | Added grouped parameter           |
| [Users API]                     | Create a User            | Added destination parameter    

  [Content Exports API]: content_exports.html
  [External Tools API]: external_tools.html
  [Submissions API]: submissions.html
  [Users API]: users.html

## 2018-05-12
### Additions
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Accounts API]               | List Active Courses in an Account    | Include parameter: Added account\_name value |
| [Communication Channels API] | Delete a Push Notification Endpoint   | Added endpoint      |
| [Courses API]      | List Your Courses Endpoint <br><br>List Courses for a User Endpoint<br><br> Get a Single Course Endpoint       | include parameter: Added account object      |
| [Enrollments API]            | List Enrollments Endpoint   | Added enrollment\_term\_id parameter         |
| [Submissions API]            | List Submissions for Multiple Assignments Endpoint   | Added graded\_since parameter                |
| [Users API]                  | Create a User Endpoint      | Added destination parameter                  |
| [User Observees API]         | Add an Observee with Credentials Endpoint <br><br>Add an Observee Endpoint <br><br>Remove an Observee Endpoint | Added root\_account\_id parameter            |

  [Accounts API]: accounts.html
  [Communication Channels API]: communication_channels.html
  [Courses API]: courses.html
  [Enrollments API]: enrollments.html
  [Submissions API]: submissions.html
  [Users API]: users.html
  [User Observees API]: user_observees.html

### Changes
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Accounts API]       | List Active Courses in an Account Endpoint | Sort parameter: replaced *subaccount* value with *account\_name* value. Subaccount can still be used as a value for backward compatibility. |
| [User Observees API] | List Observees Endpoint                    | Clarifies that the returned observees will include the observation\_link\_root\_account\_ids attribute                                      |

  [Accounts API]: accounts.html
  [User Observees API]: user_observees.html

## 2018-04-21
### Additions
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Accounts API]          |                     | Added permissions Endpoint|
| [Discussion Topics API] | Get a Single Topic Endpoint <br><br>List Discussion Topics Endpoint | Added include parameter; include overrides as an allowed value               |
| [Modules API]           | Module Object <br><br>ModuleItem SequenceNode Object <br><br>ModuleItemSequence Object | Returns the published parameter <br><br>Returns the mastery\_path parameter and includes examples for the current and next items in the course <br><br>Returns full examples for items and modules arrays |
| [Sections API]          | Create Course Section Endpoint                              | Course\_section\[integration\_id\] parameter: sets the integration\_id of the section                      |
| [SIS Imports API]       | Import SIS Data Endpoint                                    | Skip\_deletes parameter: can be used on any type of SIS import; when set, the import will skip any deletes |
|                          | SISImport Object                                                       | Workflow\_state parameter: returns whether the SIS import was aborted <br><br>Skip\_deletes parameter: returns whether the import skipped any deleted objects                                     |
| [SIS Import Errors API] | Get SIS Import Error List Endpoint  | Returns a list of SIS import errors for an account or SIS import  |
| [Users API]             | Get a Pandata JWT Token and its Expiration Date Endpoint    | Returns a jwt token, which can be used to send events to Canvas Data                                       |

  [Accounts API]: accounts.html
  [Discussion Topics API]: discussion_topics.html
  [Modules API]: modules.html
  [Sections API]: sections.html
  [SIS Imports API]: sis_imports.html
  [SIS Import Errors API]: sis_import_errors.html
  [Users API]: users.html

<p></p>
| SIS     | File                        |   |
|-------------------|---------------------------------|---|
| [SIS CSV Format] | changes\_sis\_id.csv | Added group\_category as a type <br><br>Old\_integration\_id field: description clarifies that this field does not support group categories <br><br>New\_integration\_id field: description clarifies that this field does not support group categories |

  [SIS CSV Format]: file.sis_csv.html

### Changes
| Resources     | Function                        |   |
|-------------------|---------------------------------|---|
| [Courses API]  | Permissions Endpoint           | Includes link to Accounts API Permissions Endpoint <br><br>Clarifies that permission names are documented in the Create a Role Endpoint |
| [Sections API] | Create Course Section Endpoint | Course\_section\[sis\_section\_id\] parameter: Notes the user must have the manage\_sis permissions to set                      |

  [Courses API]: courses.html
  [Sections API]: sections.html
