Live Events Introduction
==============

Live Events are specific events emitted by Canvas when an interesting action takes place, such as a page being accessed, a student
submitting an assignment, or course settings being updated. Customers can subscribe to specific events and receive them using
either an AWS SQS queue or an HTTPS Webhook. Live Events are well suited for analytics and data collection applications, but should
not be used for applications that need their data immediately and as up-to-date as possible. If you find your application needs the
most up-to-date information possible, you should use the regular Canvas API instead of Live Events.


## Live Events Usage Examples
To determine ways in which you can make use of the different types of events, you should ask a specific business question and seek its answer by collecting and visualizing data. Here are some of the questions our clients ask when they are considering using our Live Events service:

### Assessment (Quiz) Submissions

Tracking patterns using the old quizzes events will allow instructors to understand more about how students are interacting with their assessments.

* How much time is required to submit an assessment?
* If test-taking times are flexible, when do students submit their assessments?
* How much time does it take to grade an assessment after a students submits it?
* How often are assessments being revised by instructors?
* How often are instructors relying on external assessment content or re-using assessment content (imported via QTI) when building their assessments?

### User Sessions

A session is a group of user interactions in the Canvas Learning Platform that take place within a given timeframe, e.g. a single session can contain multiple page views, submission events, discussion entries, and assignment content interaction. We can think of a session as a container for the actions a user takes in Canvas. A single user can open multiple sessions. Those sessions can occur on the same day, or over several days, weeks, or months. Sessions are limited based on time limit.

* What is my average user session duration?
* Number of sessions by type of canvas user.
* Are there any common patterns in different user sessions that attribute to the distribution and setup of the course content? I.e. Are your course structures/content convoluted and students get lost a lot?
* What is the typical time of the day your users visit Canvas by user type?
* When do users typically leave Canvas by user type?
* What does a user Canvas session look like and are there any similar patterns across the same types of users—e.g. users participating in the same group or course?
* How often is the content viewed?
* What paths are taken to reach the specific content?

### Course Assignments and submissions

This event data could help instructors to gather insight about the relationship between students and their assignments.

* What type of assignments are typically gradable?
* How long does it take to submit something that has been assigned?
* What assignments present the biggest challenge, e.g. which need the most retake attempts?

### Course content

This event data could help administration to assess the account course content changes on a periodic basis.

* When does content typically get revised?
* How often is course content being copied over?
* How complex is the typical course content structure?
* How often does the course syllabus get revised?