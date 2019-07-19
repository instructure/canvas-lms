API Change Log
==============

### What is the API Change Log?
The API Change Log includes adjustments to the Canvas API documentation as part of each Canvas release. This change log can be updated at any time. Instructure may add, change, and deprecate API elements according to the timelines indicated in the [Canvas API Policy page](https://www.canvaslms.com/policies/api-policy).

### How do I use the API Change Log?
- **The release date indicates the date that the API code will be available in the production environment.**
- For a summary of all deprecations, view the [breaking changes API page](file.breaking.html).
- This page documents API changes for the last four releases. For prior releases, view the [API Change Log archive page](file.changelog_archive.html).

<div class="changelog"></div>
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
