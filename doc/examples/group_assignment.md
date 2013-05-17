The following diagram provides an example to describe the structure
of group assignments. It also shows the correspondence between the
fields of an assignment override API request and the resources they
map to.

![Group assignments structure example](./images/group_assignment.png)
  
The components in <span style="background: #FFDD00;">yellow</span>
are *group sets*. When creating or updating an assignment override,
you will refer to the group set by the `group_category_id` field.

The components in <span style="background: #C1E200;">green</span>
are *groups*. An assignment can become a group assignment iff it
has a `group_category_id` that maps to an active group set, as well
as a `group_id` that maps to an active, valid group. In the API,
you will be specifying the group by the `group_id` field of the
`assignment_override` construct.

**Important**: an assignment must be assigned to a group set
(the `group_category_id` field) on **creation** for an override
with a `group_id` to be effective.