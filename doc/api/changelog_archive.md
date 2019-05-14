API Change Log Archive
======================

The Change Log Archive page displays previous API changes in the [API Change Log](file.changelog.html) older than the last four releases.

The release date indicates the date that the API code was made available in the production environment.

<div class="changelog"></div>
## 2019-03-09
### Changes
| API Calls | Function |  |
|----------------------|----------------------|--------------------------|
| [SIS Imports API] | Imports SIS Data Endpoint | Added change_threshold parameter

[SIS Imports API]: sis_imports.html

### Removals
| API Responses | Function |      |
|----------------------|----------------------|--------------------------|
| [Users API] | To Do Items Endpoint | Removed mention of user dashboard, as this API call is not used for the dashboard

[Users API]: users.html

## 2019-02-16
### Additions
| API Responses | Function |      |
|----------------------|----------------------|--------------------------|
| [Users API] | Edit a User Endpoint | Added [user]title and [user]bio parameters

[Users API]: users.html

## 2019-01-26

### Changes
| API Calls | Function |      |
|----------------------|----------------------|--------------------------|
| [Submissions API]  |  List Gradeable Students Endpoint | Added clarification about anonymous grading |

[Submissions API]: submissions.html

### Additions
| API Responses | Function |      |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Assignment Object | Returns grader_count, final_grader, grader_comments_visible_to_graders, graders_anonymous_to_graders, grader_names_visible_to_final_grader, and anonymous_grading parameters |
| [Submissions API] | Submission Object | Returns UserDisplay parameter |
| [Users API] |      | Added AnonyousUserDisplay Object |

[Assignments API]: assignments.html
[Submissions API]: submissions.html
[Users API]: users.html

### Removals
| API Responses | Function |      |
|----------------------|----------------------|--------------------------|
| [Enrollments API] | Enrollment Object | Removed computed_current_score, computed_final_score, computed_current_grade, computed_final_grade, current_period_computed_current_score, current_period_computed_final_score, current_period_computed_current_grade, and current_period_computed_final_grade parameters |

[Enrollments API]: enrollments.html

## 2019-01-05

### Changes
| API Calls            | Function             |                          |
|----------------------|----------------------|--------------------------|
| [Developer Keys API] |                      | Verified and corrected all links in document               |
| [Files API]          | Delete File Endpoint | Clarified endpoint usage and added permanent deletion warning |

  [Developer Keys API]: file.developer_keys.html
  [Files API]: files.html

### Additions
| API Calls  | Function  |           |
|------------|-----------|-----------|
| [Assignments API]   | Create an Assignment Endpoint<br><br>Edit an Assignment Endpoint  | Added assignment\[allowed\_attempts\] parameter |
| [Conversations API] | Create a Conversations Endpoint | Added force\_new parameter |
| [Courses API]       | Get a Single Course Endpoint    | Added teacher\_limit parameter                                               |
| [Roles API]         | Create a New Role Endpoint      | Permissions\_enabled parameter: Added view\_audit\_trail in permissions list |

  [Assignments API]: assignments.html
  [Conversations API]: conversations.html
  [Courses API]: courses.html
  [Roles API]: roles.html

<p></p>
| API Responses     | Function   |   |
|-------------------|------------|---|
| [Assignments API] | Assignment Object  | Added allowed\_attempts parameter |
| [Enrollments API] | Enrollment Object  | Added override\_grade, override\_score, current\_period\_override\_grade, and current\_period\_override\_score parameters<br><br>Added override score clarifications in computed\_current\_score, computed\_final\_score, computed\_final\_grade, current\_period\_computed\_current\_score, current\_period\_computed\_final\_score, current\_period\_computed\_current\_grade, and current\_period\_computed\_final\_grade parameters |
| [SIS Imports API] | SIS Import Statistic Object <br><br>SIS Import Statistic Objects | Added object examples |
| [SIS Imports API] | SIS Import Object  | Workflow\_state parameter: Added initializing and failed descriptions <br><br>Added statistics parameter                           |
| [Submissions API] | Submission Object  | Added extra\_attempts parameter  |

  [Assignments API]: assignments.html
  [Enrollments API]: enrollments.html
  [SIS Imports API]: sis_imports.html
  [Submissions API]: submissions.html


### Removals
| API Calls     | Function  |   |
|---------------|-----------|---|
| [Courses API] | List Users in Course Endpoint | Include parameter: Removed email as an optional parameter |

  [Courses API]: courses.html

<p></p>
| Content       | Function |   |
|---------------|----------|---|
| [Navigation Tools] |     | Removed incorrect auto-generated links from page |

  [Navigation Tools]: file.navigation_tools.html

## 2018-12-08

### Changes
| API Calls         | Function |   |
|-------------------|----------|---|
| [SIS Imports API] | Abort SIS Import Endpoint<br><br> Get SIS Import List Endpoint | Added clarification that aborting a sis batch can take time and subsequent sis batches begin to process 10 minutes after the abort.<br><br> Workflow\_state parameter: added initializing, failed, restoring, partially\_restored, and restored as allowed values |

  [SIS Imports API]: sis_imports.html

### Additions
| API Calls               | Function                          |   |
|-------------------------|-----------------------------------|---|
| [SIS Import Errors API] | SISImportError Object             | Added row\_info parameter, which displays the contents of the line that had the error |
| [Users API]             | List the Activity Stream Endpoint | Added only\_active\_courses parameter |

  [SIS Import Errors API]: sis_import_errors.html
  [Users API]: users.html

<p></p>
| API Responses | Function                   |   |
|---------------|----------------------------|---|
| [Courses API] | List Your Courses Endpoint | Include parameter: Added graded period parameters to be returned even if total grades are hidden in the course |

  [Courses API]: courses.html

## 2018-11-17

### Changes
| API Calls   | Function                   |     |
|-------------|----------------------------|-----|
| [Roles API] | Create a New Role Endpoint | Permissions parameter: Updated account- and course-level role names to match roles in the Canvas Permissions page |

  [Roles API]: roles.html

<p></p>
| API Responses     | Function                        |   |
|-------------------|---------------------------------|---|
| [Assignments API] | List Assignments Endpoint       | Clarified that the paginated list of assignments is returned for the current course or assignment group |
| [Rubrics API]     | Create a Single Rubric Endpoint | Clarified the rubric return value |

  [Assignments API]: assignments.html
  [Rubrics API]: rubrics.html

### Additions
| API Calls                    | Function                              |    |
|------------------------------|---------------------------------------|----|
| [LTI Variable Substitutions] | com.instructure.Person.name\_sortable | Added variable that returns the sortable name of the launching user. Availability is when launched by a logged in user |

  [LTI Variable Substitutions]: file.tools_variable_substitutions.html

<p></p>
| API Responses     | Function                                      |   |
|-------------------|-----------------------------------------------|---|
| [SIS Imports API] | Get the Current Importing SIS Import Endpoint | Added endpoint to return the SIS imports that are currently processing for an account |

  [SIS Imports API]: sis_imports.html

### Removals
| API Calls     | Function |                                                            |
|---------------|----------|------------------------------------------------------------|
| [Planner API] |          | Removed the beta warning banner from the API documentation |

  [Planner API]: planner.html

## 2018-10-27

### Changes
| API Calls              | Function                                             |                                                                                                                                                     |
|------------------------|------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| [Conversations API]    | Create a Conversation Endpoint                       | Recipients parameter: Added clarification when the course/group has over 100 enrollments, bulk\_message and group\_conversation must be set to true |
| [Quiz Extensions API]  | Set Extensions for Student Quiz Submissions Endpoint | All parameters: Added quiz\_extensions to parameter name                                                                                            |
| [Quiz Submissions API] | Update Student Question Scores and Comment Endpoint  | All parameters: Added quiz\_submissions to parameter name                                                                                           |

  [Conversations API]: conversations.html
  [Quiz Extensions API]: quiz_extensions.html
  [Quiz Submissions API]: quiz_submissions.html

<p></p>
### Additions
| API Responses                                   | Function             |                                                     |
|-------------------------------------------------|----------------------|-----------------------------------------------------|
| [Plagiarism Detection Platform Assignments API] | LtiAssignment Object | Added LTI Course ID and Course ID return parameters |
| [Plagiarism Detection Submissions API]          | Submission Object    | Added LTI Course ID and Course ID return parameters |

  [Plagiarism Detection Platform Assignments API]: plagiarism_detection_platform_assignments.html
  [Plagiarism Detection Submissions API]: plagiarism_detection_submissions.html

## 2018-10-06

### Changes
| API Calls      | Function             |                                              |
|----------------|----------------------|----------------------------------------------|
| [Accounts API] | Permissions Endpoint | Added links to Course and Group permissions  |
| [Courses API]  | Permissions Endpoint | Added links to Account and Group permissions |

  [Accounts API]: accounts.html
  [Courses API]: courses.html

<p></p>

| Basics          | File               |                                                                                            |
|-----------------|--------------------|--------------------------------------------------------------------------------------------|
| Uploading Files | Uploading via POST | Step 3: Explains file management system transition and clarifies newer file upload process |

<p></p>

| OAuth2           | Endpoint              |                                                                     |
|------------------|-----------------------|---------------------------------------------------------------------|
| OAuth2 Endpoints | Get login/oauth2/auth | Below parameters table, clarified info on scopes for oath2 endpoint |

<p></p>

### Additions
| API Calls                   | Function             |                    |
|-----------------------------|----------------------|--------------------|
| [Assignment External Tools] |                      | Added content page |
| [Groups API]                | Permissions Endpoint | Added endpoint     |

  [Assignment External Tools]: file.assignment_external_tools.html
  [Groups API]: groups.html
<p></p>

| API Responses | Function      |                                                                            |
|---------------|---------------|----------------------------------------------------------------------------|
| [Courses API] | Course Object | Added created\_at parameter, which returns the date the course was created |

  [Courses API]: courses.html

### Removals
| API             | File               |                                                                                                                          |
|-----------------|--------------------|--------------------------------------------------------------------------------------------------------------------------|
| Uploading Files | Uploading via POST | Step 3: Identifies deprecated behavior in replacing GET calls with the deprecated POST request, to be removed 2019-04-21 |

## 2018-09-15

### Additions
| API Calls                      | Function                                                                       |                                                                                                                           |
|--------------------------------|--------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| [Custom Gradebook Columns API] | Bulk Update Column Data                                                        | Sets the content of custom columns                                                                                        |
| [LTI Variable Substitutions]   | com.instructure.Assignment.anonymous\_grading <br><br>com.Instructure.membership.roles | Returns true if the assignment has anonymous grading enabled<br><br>Returns true if the assignment has anonymous grading enabled |
| [SIS Imports API]              | SIS Import Object                                                              | CSV\_attachments parameter: Returns an array of CSV files for processing                                                  |

  [Custom Gradebook Columns API]: custom_gradebook_columns.html
  [LTI Variable Substitutions]: file.tools_variable_substitutions.html
  [SIS Imports API]: sis_imports.html
<p></p>

| API Responses           | Function                                                           |                                                                                                                                                                                                                    |
|-------------------------|--------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Accounts API]          | Get Help Links Endpoint                                            | Returns the help links for that account                                                                                                                                                                            |
| [Blueprint Courses API] | BlueprintSubscription Object <br><br>List Blueprint Subscriptions Endpoint | Returns the ID of the blueprint course and blueprint template the associated course is subscribed to <br><br>Returns a list of blueprint subscriptions for the given course (currently a course may have no more than one) |

  [Accounts API]: accounts.html
  [Blueprint Courses API]: blueprint_courses.html

## 2018-08-04

### Changes
| API Calls             | Function                   |                                                                                                                                                                                                                                                                                                                    |
|-----------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Outcome Results API] | Get Outcome Result Rollups | Aggregate parameter: Clarified that the median is a separate parameter |

  [Outcome Results API]: Outcome_results.html

<p></p>
| CSV Format        | File                   |                                                                                                                                                                                                                                                                                                                    |
|-----------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Outcomes Data Format] | outcomes.csv | Vendor_guid field: Clarified that vendor_guid IDs will prefix “canvas_outcome:” and “canvas_outcome_group:” for outcomes and groups, respectively. In addition, these prefixes are reserved; newly created outcomes and groups may not have vendor_guid fields with these prefixes. |

[Outcomes Data Format]: outcomes_csv.html


### Additions
| API Calls             | Function                   |                                                                                                                                                                                                                                                                                                                    |
|-----------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Outcome Results API] | Get Outcome Result Rollups | Exclude parameter: Specified additional values to exclude. “Missing\_user\_rollups” excludes rollups for users without results. <br><br>Aggregate\_stat parameter: If aggregate rollups requested, then this value determines what statistic is used for the aggregate. Defaults to “mean” if this value is not specified. |

  [Outcome Results API]: Outcome_results.html

## 2018-07-14

### Changes
| API Calls                          | Function |                                                                                                                |
|------------------------------------|----------|----------------------------------------------------------------------------------------------------------------|
| Plagiarism Detection Platform APIs |          | In the API page sidebar, moved all API documentation for the plagiarism platform to the External Tools section |

### Additions
| API Calls                 | Function |           |
|---------------------------|----------|-----------|
| [API Token Scopes]        |          | Added API |
| [Proficiency Ratings API] |          | Added API |

  [API Token Scopes]: api_token_scopes.html
  [Proficiency Ratings API]: proficiency_ratings.html

## 2018-06-23

### Changes

| API Calls   | Function                                                 |                                                                                                                                                                                           |
|-------------|----------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Users API] | Get a Pandata JWT Token and its Expiration Date endpoint | Changed endpoint to reflect use for current user only (/api/v1/users/self/pandata\_token) <br><br>Clarified description in that endpoint is currently only available to the mobile developer keys |

<p></p>

| API Responses | Function    |                                                                                                                   |
|---------------|-------------|-------------------------------------------------------------------------------------------------------------------|
| [Files API]   | File Object | Updated file object example and ordering; object returns uuid, folder\_id, display\_name, and modified\_at fields |

  [Users API]: users.html
  [Files API]: files.html

### Additions
| API Calls         | Function                                       |                                 |
|-------------------|------------------------------------------------|---------------------------------|
| [SIS Imports API] | Restore workflow\_states of SIS imported items | Restore states for sis\_imports |

  [SIS Imports API]: sis_imports.html

<p></p>

## 2018-06-02

### Additions

| API Calls                       | Function                         |                                                                                                                              |
|---------------------------------|----------------------------------|------------------------------------------------------------------------------------------------------------------------------|
| [Content Exports API]           | Export Content Endpoint          | Added select parameter                                                                                                       |
| [External Tools API]            | Create an External Tool Endpoint | Added account\_navigation\[display\_type\] parameter                                                                         |
| [Grade Passback External Tools] |                                  | Added Submission Details Return Extension documentation, which includes information about supporting Submitted At timestamps |
| [Submissions API]               | Submission Summary Endpoint      | Added grouped parameter                                                                                                      |
| [Users API]                     | Create a User endpoint           | Added destination parameter                                                                                                  |

  [Content Exports API]: content_exports.html
  [External Tools API]: external_tools.html
  [Grade Passback External Tools]: file.assignment_tools.html
  [Submissions API]: submissions.html
  [Users API]: users.html

## 2018-05-12

### Changes
| API Calls            | Function                                   |                                                                                                                                             |
|----------------------|--------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------|
| [Accounts API]       | List Active Courses in an Account endpoint | sort parameter: replaced *subaccount* value with *account\_name* value. Subaccount can still be used as a value for backward compatibility. |
| [User Observees API] | List Observees endpoint                    | Clarifies that the returned observees will include the observation\_link\_root\_account\_ids attribute                                      |

  [Accounts API]: accounts.html
  [User Observees API]: user_observees.html

### Additions
| API Calls                    | Function                                                                                       |                                              |
|------------------------------|------------------------------------------------------------------------------------------------|----------------------------------------------|
| [Accounts API]               | List Active Courses in an Account endpoint                                                     | Include parameter: Added account\_name value |
| [Communication Channels API] | Delete a Push Notification endpoint                                                            | Added endpoint                               |
| [Courses API]                | List Your Courses endpoint <br><br>List Courses for a User endpoint<br><br> Get a Single Course endpoint       | include parameter: Added account object      |
| [Enrollments API]            | List Enrollments endpoint                                                                      | Added enrollment\_term\_id parameter         |
| [Submissions API]            | List Submissions for Multiple Assignments endpoint                                             | Added graded\_since parameter                |
| [Users API]                  | Create a User endpoint                                                                         | Added destination parameter                  |
| [User Observees API]         | Add an Observee with Credentials endpoint <br><br>Add an Observee endpoint <br><br>Remove an Observee endpoint | Added root\_account\_id parameter            |

  [Accounts API]: accounts.html
  [Communication Channels API]: communication_channels.html
  [Courses API]: courses.html
  [Enrollments API]: enrollments.html
  [Submissions API]: submissions.html
  [Users API]: users.html
  [User Observees API]: user_observees.html

## 2018-04-21

### Changes
| API Calls      | Function                       |                                                                                                                                 |
|----------------|--------------------------------|---------------------------------------------------------------------------------------------------------------------------------|
| [Courses API]  | Permissions endpoint           | Includes link to Accounts API Permissions endpoint <br><br>Clarifies that permission names are documented in the Create a Role endpoint |
| [Sections API] | Create Course Section endpoint | Course\_section\[sis\_section\_id\] parameter: Notes the user must have the manage\_sis permissions to set                      |

  [Courses API]: courses.html
  [Sections API]: sections.html

###Additions
| API Calls               | Function                                                    |                                                                                                            |
|-------------------------|-------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|
| [Accounts API]          | Permissions endpoint                                        | New endpoint: GET /api/v1/accounts/:account\_id/permissions                                                |
| [Discussion Topics API] | Get a Single Topic endpoint <br><br>List Discussion Topics endpoint | Added include parameter <br><br>Added overrides as an allowed value in the include parameter                       |
| [Sections API]          | Create Course Section endpoint                              | course\_section\[integration\_id\] parameter: sets the integration\_id of the section                      |
| [SIS Imports API]       | Import SIS Data endpoint                                    | skip\_deletes parameter: can be used on any type of SIS import; when set, the import will skip any deletes |
| [Users API]             | Get a Pandata JWT Token and its Expiration Date endpoint    | Returns a jwt token, which can be used to send events to Canvas Data                                       |

  [Accounts API]: accounts.html
  [Discussion Topics API]: discussion_topics.html
  [Sections API]: sections.html
  [SIS Imports API]: sis_imports.html
  [Users API]: users.html

<p></p>
| API Responses           | Function                                                               |                                                                                                                                                                                           |
|-------------------------|------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Modules API]           | Module object <br><br>ModuleItem SequenceNode object <br><br>ModuleItemSequence object | Returns the published parameter <br><br>Returns the mastery\_path parameter and includes examples for the current and next items in the course <br><br>Returns full examples for items and modules arrays |
| [SIS Import Errors API] | Get SIS Import Error List endpoint                                     | Returns a list of SIS import errors for an account or SIS import                                                                                                                          |
| [SIS Imports API]       | SISImport object                                                       | workflow\_state parameter: returns whether the SIS import was aborted <br><br>skip\_deletes parameter: returns whether the import skipped any deleted objects                                     |

  [Modules API]: modules.html
  [SIS Import Errors API]: sis_import_errors.html
  [SIS Imports API]: sis_imports.html

<p></p>
| CSV Format       | File                 |                                                                                                                                                                                                                                         |
|------------------|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [SIS CSV Format] | changes\_sis\_id.csv | Added group\_category as a type <br><br>old\_integration\_id field: description clarifies that this field does not support group categories <br><br>new\_integration\_id field: description clarifies that this field does not support group categories |

  [SIS CSV Format]: file.sis_csv.html
