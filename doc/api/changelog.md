# API Change Log

### What is the API Change Log?
The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the [Canvas API Policy page](https://www.canvaslms.com/policies/api-policy).

### How do I use the API Change Log?
- **The release date indicates the date that the API code will be available in the production environment.**
- For a summary of all deprecations, view the [breaking changes API page](file.breaking.html).
- This page documents API changes for the last four releases. For prior releases, view the [API Change Log archive page](file.changelog_archive.html).

## 2019-01-26

### Changes
<div class="changelog"></div>
| API Calls | Function |      |
|----------------------|----------------------|--------------------------|
| [Submissions API]  |  List Gradeable Students endpoint | Added clarification about anonymous grading |

[Submissions API]: submissions.html

### Additions
<div class="changelog"></div>
| API Responses | Function |      |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Assignment Object | Returns grader_count, ginal_grader, grader_comments_visible_to_graders, graders_anonymous_to_graders, grader_names_visible_to_final_grader, and anonymous_grading parameters |
| [Submissions API] | Submission Object | Returns UserDisplay parameter |
| [Users API] |      | Added AnonyousUserDisplay Object |

[Assignments API]: assignments.html
[Submissions API]: submissions.html
[Users API]: users.html

### Removals
<div class="changelog"></div>
| API Responses | Function |      |
|----------------------|----------------------|--------------------------|
| [Enrollments API] | Enrollment Object | Removed computed_current_score, computed_final_score, computed_current_grade, computed_final_grade, current_period_computed_current_score, current_period_computed_final_score, current_period_computed_current_grade, and current_period_computed_final_grade parameters |

[Enrollments API]: enrollments.html

## 2019-01-05

### Changes
<div class="changelog"></div>
| API Calls            | Function             |                          |
|----------------------|----------------------|--------------------------|
| [Developer Keys API] |                      | Verified and corrected all links in document               |
| [Files API]          | Delete File Endpoint | Clarified endpoint usage and added permanent deletion warning |

  [Developer Keys API]: file.developer_keys.html
  [Files API]: files.html

### Additions
<div class="changelog"></div>
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
<div class="changelog"></div>
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
<div class="changelog"></div>
| API Calls     | Function  |   |
|---------------|-----------|---|
| [Courses API] | List Users in Course Endpoint | Include parameter: Removed email as an optional parameter |

  [Courses API]: courses.html

<p></p>
<div class="changelog"></div>
| Content       | Function |   |
|---------------|----------|---|
| [Navigation Tools] |     | Removed incorrect auto-generated links from page |

  [Navigation Tools]: file.navigation_tools.html

## 2018-12-08

### Changes
<div class="changelog"></div>
| API Calls         | Function |   |
|-------------------|----------|---|
| [SIS Imports API] | Abort SIS Import Endpoint<br><br> Get SIS Import List Endpoint | Added clarification that aborting a sis batch can take time and subsequent sis batches begin to process 10 minutes after the abort.<br><br> Workflow\_state parameter: added initializing, failed, restoring, partially\_restored, and restored as allowed values |

  [SIS Imports API]: sis_imports.html

### Additions
<div class="changelog"></div>
| API Calls               | Function                          |   |
|-------------------------|-----------------------------------|---|
| [SIS Import Errors API] | SISImportError Object             | Added row\_info parameter, which displays the contents of the line that had the error |
| [Users API]             | List the Activity Stream Endpoint | Added only\_active\_courses parameter |

  [SIS Import Errors API]: sis_import_errors.html
  [Users API]: users.html

<p></p>
<div class="changelog"></div>
| API Responses | Function                   |   |
|---------------|----------------------------|---|
| [Courses API] | List Your Courses Endpoint | Include parameter: Added graded period parameters to be returned even if total grades are hidden in the course |

  [Courses API]: courses.html
<p></p>

## 2018-11-17

### Changes
<div class="changelog"></div>
| API Calls   | Function                   |     |
|-------------|----------------------------|-----|
| [Roles API] | Create a New Role Endpoint | Permissions parameter: Updated account- and course-level role names to match roles in the Canvas Permissions page |

  [Roles API]: roles.html

<p></p>
<div class="changelog"></div>
| API Responses     | Function                        |   |
|-------------------|---------------------------------|---|
| [Assignments API] | List Assignments Endpoint       | Clarified that the paginated list of assignments is returned for the current course or assignment group |
| [Rubrics API]     | Create a Single Rubric Endpoint | Clarified the rubric return value |

  [Assignments API]: assignments.html
  [Rubrics API]: rubrics.html

### Additions
<div class="changelog"></div>
| API Calls                    | Function                              |    |
|------------------------------|---------------------------------------|----|
| [LTI Variable Substitutions] | com.instructure.Person.name\_sortable | Added variable that returns the sortable name of the launching user. Availability is when launched by a logged in user |

  [LTI Variable Substitutions]: file.tools_variable_substitutions.html

<p></p>
<div class="changelog"></div>
| API Responses     | Function                                      |   |
|-------------------|-----------------------------------------------|---|
| [SIS Imports API] | Get the Current Importing SIS Import Endpoint | Added endpoint to return the SIS imports that are currently processing for an account |

  [SIS Imports API]: sis_imports.html

### Removals
<div class="changelog"></div>
| API Calls     | Function |                                                            |
|---------------|----------|------------------------------------------------------------|
| [Planner API] |          | Removed the beta warning banner from the API documentation |

  [Planner API]: planner.html
