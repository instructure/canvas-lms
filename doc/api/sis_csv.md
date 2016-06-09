SIS Import Format Documentation
===============================

Instructure Canvas can integrate with an institution's Student Information Services (SIS) in
several ways. The simplest way involves providing Canvas with several CSV files describing
users, courses, and enrollments.
These files can be zipped together and uploaded to the Account admin area.

Standard CSV rules apply:

* The first row will be interpreted as a header defining the ordering of your columns. This
header row is mandatory.
* Fields that contain a comma must be surrounded by double-quotes.
* Fields that contain double-quotes must also be surrounded by double-quotes, with the
internal double-quotes doubled. Example: Chevy "The Man" Chase would be included in
the CSV as "Chevy ""The Man"" Chase".

All text should be UTF-8 encoded.

All timestamps are sent and returned in ISO 8601 format.  All timestamps default to UTC time zone
unless specified.

    YYYY-MM-DDTHH:MM:SSZ

Batch Mode
----------

If the option to do a "full batch update" is selected in the UI, then this SIS upload is considered
to be the new canonical set of data, and data from previous SIS imports that isn't present in
this import will be deleted. This can be useful if the source SIS software doesn't have a way
to send delete records as part of the import. This deletion is scoped to a single term, which
must be specified when uploading the SIS import. Use this option with caution, as it can delete
large data sets without any prompting on the individual records. Currently, this affects courses,
sections and enrollments.

This option will only affect data created via previous SIS imports. Manually created courses, for
example, won't be deleted even if they don't appear in the new SIS import.

Diffing Mode
------------

If your account has a SIS integration that is sending its entire data set on
each import, rather than just sending what has changed, you can speed up
the import process by enabling diffing mode. In diffing mode, a
preprocessing step in Canvas will compare the current SIS import against
the last successful SIS import with the same *data set identifier*, and
only apply the difference between the two imports.

For instance, If user A is created by import 1, and then the name is changed for
user A on import 2, Canvas will apply the new information for user A.

If user B is created by import 1, and then user B is omitted from import 2,
Canvas will mark the user as deleted.

If user C is created by import 1, and the exact same information
is specified for user C in import 2, Canvas will mark that nothing has changed
for that CSV row and skip looking up user C entirely. This can greatly speed
up SIS imports with thousands of rows that change rarely.

It is important to note that if any SIS data was changed outside of that
previous CSV import, the changes will not be noticed by the diffing
code. For example:

  1. Import 1 sets user A state to "active".
  2. An admin sets user A state to "deleted" either through the Canvas
     UI, or a non-diff SIS import.
  3. Import 2 sets user A state to "active" again, and is configured to
     diff against Import 1.
  4. Because only the difference between Import 1 and Import 2 is
     applied, and the user's state is "active" in both CSVs, the user
     remains deleted.

Diffing mode is enabled by passing the `diffing_data_set_identifier`
option in the "Import SIS Data" API call. This is a unique, non-changing
string identifier for the series of SIS imports that will be diffed
against one another. The string can contain any valid UTF-8, and be up
to 128 bytes in length. If an account has multiple SIS integrations that
want to take advantage of diffing, each integration can select a unique
data set identifier to avoid interfering with each other.

When choosing a data set identifier, it's important to include any
relevant details to differentiate this data set from other import data
sets that may come concurrently or later. This might include things such
as source system, data type, and term id. Some examples of good identifiers:

 * users:fall-2015
 * source-system-1:all-data:spring-2016

If changes are made to SIS-managed objects outside of the normal import
process, as in the example given above, it may be necessary to process a SIS
import with the same data set identifier, but apply the entire import
rather than applying just the diff.  To enable this mode, set the
`diffing_remaster_data_set=true` option when creating the import, and it
will be applied without diffing. The next import for the same data
set will still diff against that import.

CSV Data Formats
================

users.csv
---------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>user_id</td>
<td>text</td>
<td><b>Required field</b>. A unique identifier used to reference users in the enrollments table.
This identifier must not change for the user, and must be globally unique. In the user interface,
 this is called the SIS ID.</td>
</tr>
<tr>
<td>integration_id</td>
<td>text</td>
<td>A secondary unique identifier useful for more complex SIS integrations.
This identifier must not change for the user, and must be globally unique.</td>
</tr>
<tr>
<td>login_id</td>
<td>text</td>
<td><b>Required field</b>. The name that a user will use to login to Instructure. If you have an
authentication service configured (like LDAP), this will be their username
from the remote system.</td>
</tr>
<tr>
<td>password</td>
<td>text</td>
<td><p>If the account is configured to use LDAP or an SSO protocol then
this should not be set. Otherwise this is the password that will be used to
login to Canvas along with the 'login_id' above.</p>
<p>If the user already has a password (from a previous SIS import or
otherwise) it will <em>not</em> be overwritten</p>
<p>Setting the password will in most cases log the user out of Canvas. If
the user has managed to change their password in Canvas they will not be
affected by this.  This latter case would happen if your institution
transitioned from using Canvas authentication to a SSO solution.
For this reason it is important to not set this if you are using LDAP or an
SSO protocol.</p>
</td>
</tr>
<tr>
<td>ssha_password</td>
<td>text</td>
<td>Instead of a plain-text password, you can pass a pre-hashed password using
the SSHA password generation scheme in this field. While better than passing
a plain text password, you should still encourage users to change their
password after logging in for the first time.</td>
</tr>
<tr>
<td>authentication_provider_id</td>
<td>text or integer</td>
<td>
<p>The authentication provider this login is associated with. Logins
associated with a specific provider can only be used with that provider.
Legacy providers (LDAP, CAS, SAML) will search for logins associated with
them, or unassociated logins. New providers will only search for logins
explicitly associated with them. This can be the integer ID of the
provider, or the type of the provider (in which case, it will find the
first matching provider).</p>
</td>
<tr>
<td>first_name</td>
<td>text</td>
<td>Given name of the user.</td>
</tr>
<tr>
<td>last_name</td>
<td>text</td>
<td>Last name of the user.</td>
</tr>
<tr>
<td>full_name</td>
<td>text</td>
<td>Full name of the user. Omit first_name and last_name if this is provided.</td>
</tr>
<tr>
<td>sortable_name</td>
<td>text</td>
<td>Sortable name of the user. This is normally inferred from the user's name,
but you can customize it here.</td>
</tr>
<tr>
<td>short_name</td>
<td>text</td>
<td>Display name of the user. This is normally inferred from the user's name,
but you can customize it here.</td>
</tr>
<tr>
<td>email</td>
<td>text</td>
<td>The email address of the user. This might be the same as login_id, but should
still be provided.</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted</td>
</tr>
</table>

<p>The user's name (either first_name and last_name, or full_name) should always
be provided. Otherwise, the name will be blanked out.</p>

<p>When a student is 'deleted' all of its enrollments will also be deleted and
they won't be able to log in to the school's account. If you still want the
student to be able to log in but just not participate, leave the student
'active' but set the enrollments to 'completed'.</p>

Sample:

<pre>user_id,login_id,authentication_provider_id,password,first_name,last_name,short_name,email,status
01103,bsmith01,,,Bob,Smith,Bobby Smith,bob.smith@myschool.edu,active
13834,jdoe03,google,,John,Doe,,john.doe@myschool.edu,active
13aa3,psue01,7,,Peggy,Sue,,peggy.sue@myschool.edu,active
</pre>

accounts.csv
------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>account_id</td>
<td>text</td>
<td><b>Required field</b>. A unique identifier used to reference accounts in the enrollments data.
This identifier must not change for the account, and must be globally unique. In the user
interface, this is called the SIS ID.</td>
</tr>
<tr>
<td>parent_account_id</td>
<td>text</td>
<td><b>Required column</b>. The account identifier of the parent account.
If this is blank the parent account will be the root account. Note that even if
all values are blank, the column must be included to differentiate the file
from a group import.</td>
</tr>
<tr>
<td>name</td>
<td>text</td>
<td><b>Required field</b>. The name of the account</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted</td>
</tr>
</table>

Any account that will have child accounts must be listed in the csv before any child account
references it.

Sample:

<pre>account_id,parent_account_id,name,status
A001,,Humanities,active
A002,A001,English,active
A003,A001,Spanish,active
</pre>

terms.csv
------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>term_id</td>
<td>text</td>
<td><b>Required field</b>. A unique identifier used to reference terms in the enrollments data.
This identifier must not change for the account, and must be globally unique. In the user
interface, this is called the SIS ID.</td>
</tr>
<tr>
<td>name</td>
<td>text</td>
<td><b>Required field</b>. The name of the term</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted</td>
</tr>
<tr>
<td>start_date</td>
<td>date</td>
<td>The date the term starts. The format should be in ISO 8601: YYYY-MM-DDTHH:MM:SSZ</td>
</tr>
<tr>
<td>end_date</td>
<td>date</td>
<td>The date the term ends. The format should be in ISO 8601: YYYY-MM-DDTHH:MM:SSZ</td>
</tr>
</table>

Sample:

<pre>term_id,name,status,start_date,end_date
T001,Winter2011,active,,
T002,Spring2011,active,2013-1-03 00:00:00,2013-05-03 00:00:00-06:00
T003,Fall2011,active,,
</pre>

courses.csv
------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>course_id</td>
<td>text</td>
<td><b>Required field</b>. A unique identifier used to reference courses in the enrollments data.
This identifier must not change for the account, and must be globally unique. In the user
interface, this is called the SIS ID.</td>
</tr>
<tr>
<td>short_name</td>
<td>text</td>
<td><b>Required field</b>. A short name for the course</td>
</tr>
<tr>
<td>long_name</td>
<td>text</td>
<td><b>Required field</b>. A long name for the course. (This can be the same as the short name,
but if both are available, it will provide a better user experience to provide both.)</td>
</tr>
<tr>
<td>account_id</td>
<td>text</td>
<td>The account identifier from accounts.csv, if none is specified the course will be attached to
the root account</td>
</tr>
<tr>
<td>term_id</td>
<td>text</td>
<td>The term identifier from terms.csv, if no term_id is specified the
default term for the account will be used</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted, completed</td>
</tr>
<tr>
<td>start_date</td>
<td>date</td>
<td>The course start date. The format should be in ISO 8601: YYYY-MM-DDTHH:MM:SSZ</td>
</tr>
<tr>
<td>end_date</td>
<td>date</td>
<td>The course end date. The format should be in ISO 8601: YYYY-MM-DDTHH:MM:SSZ</td>
</tr>
</table>

<p>If the start_date is set, it will override the term start date. If the end_date is set, it will
override the term end date.</p>

Sample:

<pre>course_id,short_name,long_name,account_id,term_id,status
E411208,ENG115,English 115: Intro to English,A002,,active
R001104,BIO300,"Biology 300: Rocking it, Bio Style",A004,Fall2011,active
A110035,ART105,"Art 105: ""Art as a Medium""",A001,,active
</pre>

sections.csv
------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>section_id</td>
<td>text</td>
<td><b>Required field</b>. A unique identifier used to reference sections in the enrollments data.
This identifier must not change for the account, and must be globally unique. In the user
interface, this is called the SIS ID.</td>
</tr>
<tr>
<td>course_id</td>
<td>text</td>
<td><b>Required field</b>. The course identifier from courses.csv</td>
</tr>
<tr>
<td>name</td>
<td>text</td>
<td><b>Required field</b>. The name of the section</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted</td>
</tr>
<tr>
<td>start_date</td>
<td>date</td>
<td>The section start date. The format should be in ISO 8601: YYYY-MM-DDTHH:MM:SSZ</td>
</tr>
<tr>
<td>end_date</td>
<td>date</td>
<td>The section end date The format should be in ISO 8601: YYYY-MM-DDTHH:MM:SSZ</td>
</tr>
</table>

<p>If the start_date is set, it will override the course and term start dates. If the end_date is
set, it will override the course and term end dates.</p>

Sample:

<pre>section_id,course_id,name,status,start_date,end_date
S001,E411208,Section 1,active,,
S002,E411208,Section 2,active,,
S003,R001104,Section 1,active,,
</pre>

enrollments.csv
---------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>course_id</td>
<td>text</td>
<td><b>Required field if section_id is missing</b>. The course identifier from courses.csv</td>
</tr>
<tr>
<td>root_account</td>
<td>text</td>
<td>The domain of the account to search for the user.</td>
</tr>
<tr>
<td>user_id</td>
<td>text</td>
<td><b>Required field</b>. The User identifier from users.csv</td>
</tr>
<tr>
<td>role</td>
<td>text</td>
<td><b>Required field if role_id missing</b>. student, teacher, ta, observer, designer, or a custom role defined
by the account</td>
</tr>
<tr>
<td>role_id</td>
<td>text</td>
<td><b>Required field if role missing</b>. Uses a role id, either built-in or defined by the account</td>
</tr>
<tr>
<td>section_id</td>
<td>text</td>
<td><b>Required field if course_id missing</b>. The section identifier from sections.csv, if none
is specified the default section for the course will be used</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted, completed, inactive</td>
</tr>
<tr>
<td>associated_user_id</td>
<td>text</td>
<td>For observers, the user identifier from users.csv of a student
in the same course that this observer should be able to see grades for.
Ignored for any role other than observer</td>
</tr>
</table>


When an enrollment is in a 'completed' state the student is limited to read-only access to the
course.

If in an 'inactive' state, the student will be listed in the course roster for teachers,
but will not be able to view or participate in the course until the enrollment is activated.

Sample:

<pre>course_id,user_id,role,section_id,status
E411208,01103,student,1B,active
E411208,13834,student,2A,active
E411208,13aa3,teacher,2A,active
</pre>

groups.csv
------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>group_id</td>
<td>text</td>
<td><b>Required field</b>. A unique identifier used to reference groups in the group_users data.
This identifier must not change for the group, and must be globally unique.</td>
</tr>
<tr>
<td>account_id</td>
<td>text</td>
<td>The account identifier from accounts.csv, if none is specified the group will be attached to
the root account.</td>
</tr>
<tr>
<td>name</td>
<td>text</td>
<td><b>Required field</b>. The name of the group.</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. available, deleted</td>
</tr>
</table>

Sample:

<pre>group_id,account_id,name,status
G411208,A001,Group1,available
G411208,,Group2,available
G411208,,Group3,deleted
</pre>

groups_membership.csv
------------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>group_id</td>
<td>text</td>
<td><b>Required field</b>. The group identifier from groups.csv</td>
</tr>
<tr>
<td>user_id</td>
<td>text</td>
<td><b>Required field</b>. The user identifier from users.csv</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. accepted, deleted</td>
</tr>
</table>

Sample:

<pre>group_id,user_id,status
G411208,U001,accepted
G411208,U002,accepted
G411208,U003,deleted
</pre>

xlists.csv
----------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>xlist_course_id</td>
<td>text</td>
<td><b>Required field</b>. The course identifier from courses.csv</td>
</tr>
<tr>
<td>section_id</td>
<td>text</td>
<td><b>Required field</b>. The section identifier from sections.csv</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted</td>
</tr>
</table>

xlists.csv is optional. The goal of xlists.csv is to provide a way to add cross-listing
information to an existing course and section hierarchy. Section ids are expected to exist
already and already reference other course ids. If a section id is provided in this file,
it will be moved from its existing course id to a new course id, such that if that new course
is removed or the cross-listing is removed, the section will revert to its previous course id.
If xlist_course_id does not reference an existing course, it will be created. If you want to
provide more information about the cross-listed course, please do so in courses.csv.

Sample:

<pre>xlist_course_id,section_id,status
E411208,1B,active
E411208,2A,active
E411208,2A,active
</pre>

user_observers.csv
----------

<table class="sis_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Description</th>
</tr>
<tr>
<td>observer_id</td>
<td>text</td>
<td><b>Required field</b>. The User identifier from users.csv for the observing user.</td>
</tr>
<tr>
<td>student_id</td>
<td>text</td>
<td><b>Required field</b>. The User identifier from users.csv for the student user.</td>
</tr>
<tr>
<td>status</td>
<td>enum</td>
<td><b>Required field</b>. active, deleted</td>
</tr>
</table>

user_observers.csv is optional. The goal of user_observers.csv is to provide a
way to create user_observers. These observers will automatically be enrolled as
an observer for each of the students enrollments. When a user_observer is
deleted the observer enrollments of the student are also deleted.

Sample:

<pre>observer_id,student_id,status
u411208,u411222,active
u411208,u411295,active
u413405,u411385,deleted
</pre>
