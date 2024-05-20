Outcomes Import Format Documentation
===============================

Learning outcomes can be updated in bulk by using the Outcomes Import API. Each row
in a CSV file represents either a learning outcome or a learning outcome group to create or update.

Standard CSV rules apply (including adherence to the CSV RFC 4180 format):

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

Outcomes Data Format
================

outcomes.csv
---------

<table class="outcomes_csv">
<tr>
<th>Field Name</th>
<th>Data Type</th>
<th>Required</th>
<th>Description</th>
</tr>
<tr>
<td>vendor_guid</td>
<td>text</td>
<td>✓</td>
<td>A value that uniquely identifies this learning outcome or learning outcome group.
For learning outcome groups, this value can be referenced by other learning outcomes or
learning outcome groups in the parent_guids field below, to indicate that this group
contains an outcome or group. This value cannot contain spaces.
<br />
If outcomes have been exported from an account with no vendor_guid values set,
canvas will auto-assign vendor_guid values from internal identifiers. These ids will have the
prefix "canvas_outcome:" and "canvas_outcome_group:" for outcomes and groups respectively.  We
recommend that you *do not* change these values once they have been assigned.
If you want to set your own vendor_guid values for existing outcomes, you should do that using the
Canvas API prior to exporting outcomes from an account.
In addition, these prefixes are reserved; newly created outcomes and groups may not
have vendor_guid fields with these prefixes.
</td>
</tr>
<tr>
<td>object_type</td>
<td>text</td>
<td>✓</td>
<td>A value of "outcome" indicates this is a learning outcome. A value of "group"
indicates this is a learning outcome group</td>
</tr>
<tr>
<td>course_id</td>
<td>number</td>
<td></td>
<td>May only be given for rows where object_type="group". If given, the generated learning outcome group will belong to the course with the given ID instead of to the account from which the import was initiated. Referenced course must belong to the initiating account or one of its sub-accounts. Can not be used in course-level imports.</td>
</tr>
<tr>
<td>title</td>
<td>text</td>
<td>✓</td>
<td>The title of the learning outcome or learning outcome group.</td>
</tr>
<tr>
<td>description</td>
<td>text</td>
<td></td>
<td>The description of the learning outcome or learning outcome group (optional, defaults to blank).</td>
</tr>
<tr>
<td>friendly_description</td>
<td>text</td>
<td></td>
<td>Learning outcome display description in "friendly" language for students and parents (optional, defaults to blank). This value must be
less than 255 characters in length.</td>
</tr>
<tr>
<td>display_name</td>
<td>text</td>
<td></td>
<td>The display name (or friendly name) of the learning outcome.
This value does not apply to learning outcome groups.</td>
</tr>
<tr>
<td>calculation_method</td>
<td>text</td>
<td></td>
<td>Must be one of "decaying_average", "n_mastery", "highest", "latest", "average" or blank.
This field must be blank for learning outcome groups. If not provided and this
is a learning outcome, then the calculation method defaults to "decaying_average". If the Account and Course Level Outcome Mastery Scales flag is enabled, the calculation_method field does not need to be defined in the imported .csv. The calculation_method field will be determined by the account and course settings.
If Outcomes New Decaying Average Calculation Method feature flag is enabled then
we will have one more calculation method "weighted_average" and it would be
the default calculation method.
</td>
</tr>
<tr>
<td>calculation_int</td>
<td>integer</td>
<td></td>
<td>Valid values depend on the "calculation_method". For "decaying_average", the value must
be between 1 and 99, inclusive. For "n_mastery", the value must be between 1 and 10, inclusive.
For "highest", "latest" and "average", this field must be blank. If the Account and Course Level Outcome Mastery Scales flag is enabled, the calculation_int field does not need to be defined in the imported .csv. The calculation_int field will be determined by the account and course settings.
If Outcomes New Decaying Average Calculation Method feature flag is enabled then
For "weighted_average", the value must be between 1 and 99, inclusive.
For "standard_decaying_average", the value must be between 50 and 99, inclusive.
</td>
</tr>
<tr>
<td>parent_guids</td>
<td>text</td>
<td></td>
<td>A space-separated list of vendor_guid values of parent learning outcome groups for this
learning outcome or learning outcome group. All of these vendor_guid values
must refer to previous rows, and all of these previous rows must represent learning outcome groups.
If no value is provided, then this outcome or group will be added to the context's
root outcome group.</td>
</tr>
<tr>
<td>workflow_state</td>
<td>text</td>
<td></td>
<td>Must be either "active" or "deleted". If not present, we assume the learning outcome
or learning outcome group is "active".</td>
</tr>
<tr>
<td>mastery_points</td>
<td>number</td>
<td></td>
<td>The number of points that define mastery for this learning outcome.
Must be blank for learning outcome groups. If the Account and Course Level Outcome Mastery Scales flag is enabled, the mastery_points field does not need to be defined in the imported .csv. The mastery_points field will be determined by the account and course settings.</td>
</tr>
<tr>
<td>ratings</td>
<td>number/text (multiple columns)</td>
<td></td>
<td>These columns must be the final columns of each row, and contain the scoring
tiers for the given outcome. The columns alternate in decreasing point order:
first, number of points for the tier, then tier description. This alternating
pattern continues until there are no more scoring tiers for this outcome.
These columns must be blank for learning outcome groups. See sample below. If the Account and Course Level Outcome Mastery Scales flag is enabled, the ratings field does not need to be defined in the imported .csv. The ratings field will be determined by the account and course settings.</td>
</tr>
</table>

Sample:

<pre>
vendor_guid,object_type,title,description,display_name,calculation_method,calculation_int,workflow_state,parent_guids,ratings,,,,,,,
a,group,Parent group,parent group description,G-1,,,active,,,,,,,,,
b,group,Child group,child group description,G-1.1,,,active,a,,,,,,,,
c,outcome,Learning Standard,outcome description,LS-100,decaying_average,40,active,a b,3,Excellent,2,Better,1,Good,,
</pre>
