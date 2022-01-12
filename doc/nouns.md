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
No event in cloud canvas, but we think it might be triggered by the course?

## course
### Model

### Cloud Canvas APIs
### Cloud Canvas Event


## module
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## teacher_enrollment
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## conversation_participant
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## discussion_topic
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## observer_enrollment
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## conversation
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## conversation_message
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## ta_enrollment
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## course_section
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## content_migration
### Model
### Cloud Canvas APIs
### Cloud Canvas Event


## assignment_group
### Model
### Cloud Canvas APIs
### Cloud Canvas Event

