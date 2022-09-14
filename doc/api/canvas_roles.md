Canvas Roles
============

LTI generally recognizes that users make use of the integrated functionality offered by tools to platforms. These users
typically come with a defined role with respect to the context within which they operate when using a tool.

The role represents the level of privilege a user has been given within the context hosted by the platform. Typical
roles are "learner", "instructor", and "administrator". Note that it's entirely possible that a user might have a
different role in a different context (a user that is a "student" in one context may be an "instructor" in another, for
example).

The IMS role vocabularies are derived from the [LIS specification](https://www.imsglobal.org/activity/onerosterlis#LIS)

## LTI 1.1 using the LIS 1.1 Roles

| Canvas Role           | Role type        | IMS role                                      |
|-----------------------|------------------|-----------------------------------------------|
| user                  | System role      | urn:lti:sysrole:ims/lis/User                  |
| siteadmin             | System role      | urn:lti:sysrole:ims/lis/SysAdmin              |
| teacher               | Institution role | urn:lti:instrole:ims/lis/Instructor           |
| student               | Institution role | urn:lti:instrole:ims/lis/Student              |
| admin                 | Institution role | urn:lti:instrole:ims/lis/Administrator        |
| observer              | Context role     | urn:lti:role:ims/lis/Learner/NonCreditLearner |
| observer              | Context role     | urn:lti:role:ims/lis/Mentor                   |
| AccountUser           | Institution role | urn:lti:instrole:ims/lis/Administrator        |
| StudentEnrollment     | Context role     | urn:lti:role:ims/lis/Learner                  |
| TeacherEnrollment     | Context role     | urn:lti:role:ims/lis/Instructor               |
| TaEnrollment          | Context role     | urn:lti:role:ims/lis/TeachingAssistant        |
| DesignerEnrollment    | Context role     | urn:lti:role:ims/lis/ContentDeveloper         |
| ObserverEnrollment    | Context role     | urn:lti:role:ims/lis/Learner/NonCreditLearner |
| ObserverEnrollment    | Context role     | urn:lti:role:ims/lis/Mentor                   |
| StudentViewEnrollment | Context role     | urn:lti:role:ims/lis/Learner                  |

Source: [LTI 1.1 - Role vocabularies](http://www.imsglobal.org/specs/ltiv1p1/implementation-guide#toc-8)


## LTI 1.3 using the LIS 2.0 Roles

| Canvas Role           | Role type        | IMS role                                                                       |
|-----------------------|------------------|--------------------------------------------------------------------------------|
| user                  | System role      | http://purl.imsglobal.org/vocab/lis/v2/system/person#User                      |
| siteadmin             | System role      | http://purl.imsglobal.org/vocab/lis/v2/system/person#SysAdmin                  |
| teacher               | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor           |
| student               | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student              |
| admin                 | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator        |
| AccountUser           | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator        |
| TaEnrollment          | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor                   |
| TaEnrollment          | Context sub-role | http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor#TeachingAssistant |
| StudentEnrollment     | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Learner                      |
| TeacherEnrollment     | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor                   |
| DesignerEnrollment    | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper             |
| ObserverEnrollment    | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor                       |
| StudentViewEnrollment | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Learner                      |

Source: [LTI 1.3 - Role vocabularies](https://www.imsglobal.org/spec/lti/v1p3#role-vocabularies)


## LTI 1.3 using the LIS 2.0 LTI Advantage Roles

| Canvas Role           | Role type        | IMS role                                                                       |
|-----------------------|------------------|--------------------------------------------------------------------------------|
| user                  | System role      | http://purl.imsglobal.org/vocab/lis/v2/system/person#User                      |
| siteadmin             | System role      | http://purl.imsglobal.org/vocab/lis/v2/system/person#SysAdmin                  |
| fake_student          | System role      | http://purl.imsglobal.org/vocab/lti/system/person#TestUser                     |
| teacher               | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Instructor           |
| student               | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Student              |
| admin                 | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator        |
| AccountUser           | Institution role | http://purl.imsglobal.org/vocab/lis/v2/institution/person#Administrator        |
| TaEnrollment          | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor                   |
| TaEnrollment          | Context sub-role | http://purl.imsglobal.org/vocab/lis/v2/membership/Instructor#TeachingAssistant |
| StudentEnrollment     | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Learner                      |
| TeacherEnrollment     | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor                   |
| DesignerEnrollment    | Context sub-role | http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper             |
| ObserverEnrollment    | Context sub-role | http://purl.imsglobal.org/vocab/lis/v2/membership#Mentor                       |
| StudentViewEnrollment | Context sub-role | http://purl.imsglobal.org/vocab/lis/v2/membership#Learner                      |
| StudentViewEnrollment | System role      | http://purl.imsglobal.org/vocab/lti/system/person#TestUser                     |
| :group_member         | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Member                       |
| :group_leader         | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Member                       |
| :group_leader         | Context role     | http://purl.imsglobal.org/vocab/lis/v2/membership#Manager                      |

Source: [LTI 1.3 - Role vocabularies](https://www.imsglobal.org/spec/lti/v1p3#role-vocabularies)
