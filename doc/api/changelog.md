API Change Log
==============

### What is the API Change Log?
The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the [Canvas API Policy page](https://www.canvaslms.com/policies/api-policy).

### How do I use the API Change Log?
- **The release date indicates the date that the API code will be available in the production environment.**
- For a summary of all deprecations, view the [breaking changes API page](file.breaking.html).
- This page documents API changes for the last four releases. For prior releases, view the [API Change Log archive page](file.changelog_archive.html).

<div class="changelog"></div>

## 2019-05-11
### Additions
| API Calls | Function |  |
|----------------------|----------------------|--------------------------|
| [Assignments API] | Create an Assignment Endpoint<br><br>Edit an Assignment Endpoint | Added assignment [grader_count], assignment [final_grader_id], assignment [grader_comments_visible_to_graders], assignment [graders_anonymous_to_graders], assignment [graders_names_visible_to_final_grader], assignment [anonymous_grading] parameters
|  [SIS Imports API]         | Import SIS Data Endpoint | Added diff_row_count_threshold parameter
|  [Users API]         | Merge User Into Another User Endpoint | Added user merge details and caveats for behaviors relating to avatars, terms of use, communication channels, enrollments, submissions, access tokens, conversations, favorites, and LTI tools

[Assignments API]: assignments.html
[SIS Imports API]: sis_imports.html
[Users API]: users.html

## 2019-04-20
### Additions
| API Calls | Function |  |
|----------------------|----------------------|--------------------------|
| [Submissions API] | Grade or Comment on a Submission Endpoint | Rubric_assessment parameter: Added rubric_assessment[criterion_id][rating_id] sub-parameter<br><br>Added rating IDs to example rubric in description
|  [Users API]         | Update User Settings Endpoint | Hide_dashcard_color_overlays: Added parameter

[Submissions API]: submissions.html
[Users API]: users.html


## 2019-03-30
### Changes
| API Calls | Function |  |
|----------------------|----------------------|--------------------------|
| [Content Migrations API] | Update a Content Migration Endpoint | Clarified the endpoint takes same arguments as creating a migration<br><br>Clarified that updating the content migration will also be used when importing content selectively |

[Content Migrations API]: content_migrations.html

### Additions
| API Calls | Function |  |
|----------------------|----------------------|--------------------------|
| [Content Migrations API] | Create a Content Migration Endpoint | Added selective_import parameter
|                          | List Items for Selective Import Endpoint | Added endpoint

[Content Migrations API]: content_migrations.html


## 2019-03-09
### Changes
| API Calls | Function |  |
|----------------------|----------------------|--------------------------|
| [SIS Imports API] | Imports SIS Data Endpoint | Change_threshold parameter: added clarification for diffing percentage calculation

[SIS Imports API]: sis_imports.html

### Removals
| API Responses | Function |      |
|----------------------|----------------------|--------------------------|
| [Users API] | To Do Items Endpoint | Removed mention of user dashboard, as this API call is not used for the dashboard

[Users API]: users.html
