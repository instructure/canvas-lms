# Nouns and where they are initiated from 

## page_view

### Model 
Generated from the PageView model.

### Cloud Canvas APIs
Some API coverage in Cloud Canvas - not a direct feed, attached to other objects.

### Cloud Canvas Event
PageView does not appear to generate a cloud canvas event. (Does xApi or Caliper generate one?)

## context_module_progression

### Model

Generated from the ContextModuleProgression model. Triggered in Legacy by shim decorator.

### Cloud Canvas APIs

No readily apparent direct API to these in Cloud Canvas

### Cloud Canvas Event

This looks like it's an event for something similar that has been added. https://canvas.instructure.com/doc/api/file.data_service_canvas_course.html#course_progress 

## course_progress
### Model
Virtual Noun, generated from the point in time contents of ContextModuleProgression and CourseProgress models when a ContextModuleProgression is saved, via the context_module_progression shim decorator.
### Cloud Canvas APIs
These may not be the same as legacy events; we should check them.
https://canvas.instructure.com/doc/api/courses.html#method.courses.user_progress
### Cloud Canvas Event
These may not be the same as legacy events; we should check them.
https://canvas.instructure.com/doc/api/file.data_service_canvas_course.html#course_progress

## assignment
### Model
Assignment model; Published via shim decorator for both assignment and also submission.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/assignments.html

### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_assignment.html

## student_enrollment
### Model
Enrollment model. Triggered in shim decorator, published as student.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/enrollments.html

### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_enrollment.html

## submission
### Model
Submission model; Published via shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/submissions.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_submission.html

## content_tag
### Model
ContentTag model; Published via shim decorator.
### Cloud Canvas APIs
Does not appear to be directly in the cloud canvas API.
### Cloud Canvas Event
Does not appear to be in the cloud canvas events list.

## pseudonym
### Model
Pseudonym model; Published via shim decorator.
### Cloud Canvas APIs
No direct API. Maybe via user api? Does it include the full information? Do we need the full information?
### Cloud Canvas Event
No direct event - does it trigger the user update event? We think it does.

## user
### Model
User model; Published via shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/users.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_user.html

## module_item
### Model
Is the model ContextModelItem (which is not an activerecord model, but a class)? Publishing is triggered via ContentTag.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/modules.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_module.html

## course
### Model
Model is Course; published via shim decorator
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/courses.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_course.html

## module
### Model
Model is ContextModule; published via shim decorator with alias "Module"
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/modules.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_module.html


## teacher_enrollment
### Model
Enrollment model. Triggered in shim decorator, published as teacher_enrollment.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/enrollments.html

### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_enrollment.html


## conversation_participant
### Model
ConversationParticipant model. Triggered in shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/conversations.html but the object is part of a conversation, doesn't have an API of its own.
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_conversation.html but the event is sent when the `Conversation` is changed, not the `ConversationParticipant`. We would probably need to trigger on `conversation_message_created`.


## discussion_topic
### Model
`DiscussionTopic` model. Triggered in shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/discussion_topics.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_discussion.html

## observer_enrollment
### Model
Enrollment model. Triggered in shim decorator, published as observer_enrollment.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/enrollments.html

### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_enrollment.html


## conversation
### Model
Conversation model. Triggered in shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/conversations.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_conversation.html


## conversation_message
### Model
`ConversationMessage` model. Triggered via shim decorator.  It's only triggered if there is a conversation ID present. We *theorize* that this is to avoid publishing private messages between users, but have not checked if that is so. 
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/conversations.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_conversation.html

## ta_enrollment
### Model
Enrollment model. Triggered in shim decorator, published as ta_enrollment.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/enrollments.html

### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_enrollment.html


## course_section
### Model
`CourseSection` model. Triggered in shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/sections.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_course.html

## content_migration
### Model
`ContentMigration` model. Triggered in shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/content_migrations.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_content.html

## assignment_group
### Model
`AssignmentGroup` model. Triggered in shim decorator.
### Cloud Canvas APIs
https://canvas.instructure.com/doc/api/assignment_groups.html
### Cloud Canvas Event
https://canvas.instructure.com/doc/api/file.data_service_canvas_assignment.html

