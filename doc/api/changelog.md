API Change Log
==============

### What is the API Change Log?
The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the [Canvas API Policy page](https://www.canvaslms.com/policies/api-policy).

### How do I use the API Change Log?
- **The release date indicates the date that the API code will be available in the production environment.**
- For a summary of all deprecations, view the [breaking changes API page](file.breaking.html).
- This page documents API changes for the last four releases. For prior releases, view the [API Change Log archive page](file.changelog_archive.html).

<div class="changelog"></div>

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
<p></p>
