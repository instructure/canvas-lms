How to create a new Data Stream
==============

1. Click on +ADD button to launch a new subscription form
2. Add Subscription Name - use a distinct name to identify your subscription purpose or type e.g : Blackboard Ally Integration
3. Choose Delivery Method
* SQS - AWS Simple Queue Services
  * URL - aws sqs endpoint URL
  * Authentication via IAM User Key and Secret is supported but optional . When using Key and Secret for your SQS please provide the region

* HTTPS - Webhook with JWT signing
    * URL - web service endpoint. The event body is a signed JWT. Beta and Production JWKs can be found here. Most libraries should be able to match the kid in the JWT header to the relevant JWK to validate the signature. If a customer's HTTPS service experiences an outage, the events will not be delivered till the service is recovered.
4. Select the format of the events : Canvas or Caliper IMS
5. Find and select a single or multiple events
6. Save your new data stream

Your new subscription will be listed on the Settings page . You will be able to edit, duplicate or deactivate your new subscription record by going to each stream right side kebab menu.

## SQS configuration

1. In the Amazon Web Services console, open the Simple Queue Service (SQS) console by typing the name in the Services field. When Simple Queue Service displays in the list, click the name.
2. In the Amazon SQS console, click the Create New Queue button
3. Enter a name for the queue. The name of the queue must begin with canvas-live-events.
4. By default, Standard Queue will be selected
  * To create a queue with the default settings, click the Quick-Create Queue button. To configure additional queue parameters, click the Configure Queue button. **Note: FIFO Queues are not currently supported.**
5. Open Queue Permissions
6. Select the checkbox next to the name of your queue. In the queue details area, click the Permissions tab
7. In the permission details window, select the Allow radio button
8. In the Principal field, enter the account number 636161780776. This account number is required for the queue to receive Live Events data
9.  Select the All SQS Actions checkbox
10. Click the Add Permission button

How to Use the Events
==============

To determine ways in which you can make use of different types of events requires that you ask a specific business question and seek its answer by collecting and visualizing data. Here are some of the questions our clients ask when they are considering using our Live Events service.

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

### Course assignments and submissions

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
