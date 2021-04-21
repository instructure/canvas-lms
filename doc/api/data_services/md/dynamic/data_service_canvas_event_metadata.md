Event Data Identifiers
==============

Event payloads use two types of identifiers: globalId and localId. Global identifier is equal to (shardId*10000000000000)+localId. Please note our global identifiers might change if your Canvas instance goes through shard migration process, in this case your current shardId in the global identifier will change to a new shardId. Local identifiers do not change after shard migration and stay unique in the context of the Canvas account. All new events will provide local identifiers in the body of the event payload. To achieve consistency across all events, in the future all supported events will share local identifiers only, global identifier support deprecation note will be given as soon as the change is planned.

## Event Data Formats

Event data is a record of a single event at a particular moment in time. An event consists of core attributes such as an event_name and event_type, and can be annotated with many additional attributes to provide more context. For example, Canvas captures detailed events when a user traverses a Canvas account or course.

Canvas collects numerous data points and emits some of them via its Live Events Data Service. The Live Events user interface displays a list of available event types that the customer could choose from depending on their needs. There are two formats of event data available for Canvas customers: IMS Caliper v1.1 and Canvas. The event type and format matters when you want to answer a specific business need.

## Event Data

Event data is useful when you need to filter data based on arbitrary characteristics—such as data queries that are unique to customer external data warehouse application, learning analytics, histograms, etc. Canvas emits numerous events with a list of attributes attached to each event. For example, individual user logged_in and logged_out sessions, assignment submission details, and grade_change transactions.

* Event data is not aggregated over time; therefore, it should not be used as a single source for your data warehouse. Use it in conjunction with Canvas Data Extracts and Canvas APIs to ensure the integrity of your LMS analytics dataset.
* Event data is not sequenced, and can only be arranged in time based order via the "event_time" attribute expressed in ISO-8601 where data and time values are formatted with the addition of millisecond precision. The format is yyyy-MM-ddTHH:mm:ss.SSSZ where ‘T’ separates the date from the time while ‘Z’ indicates that the time is set to UTC.
* Events are delivered in a "best-effort" fashion. In order to not slow down web requests, events are sent asynchronously. That means that there's a window where an event may happen, but the process responsible for sending the request to the queue is not able to queue it.
* Event data can be sent to AWS SQS queue and any HTTPS endpoint . In event of endpoint downtime, all events will be lost.

## Event Structure

Each event consists of two main parts : event metadata and event body. Based on the event trigger the metadata and body sections of the event will share different data. There are two types of event triggers : user request and system process or asynchronous job. System generated event will have job_id and job_tag in metadata associated with the asynchronous jobs that trigger the event. User generated event will have user id and request data associated with the event actor.

Event Metadata
==============

Events triggered by system processes such as a course content migration or SIS import jobs will share data around the process that triggered an event and the context of the trigger . All system generated events have job_id and job_tag associated with the asynchronous jobs that trigger the events.

## Examples



### Payload Example:

```json
{
  "metadata": {
    "event_name": "wiki_page_updated",
    "event_time": "2019-11-01T19:11:25.788Z",
    "job_id": "1020020528469291",
    "job_tag": "ContentMigration#import_content",
    "producer": "canvas",
    "root_account_id": "21070000000000001",
    "root_account_lti_guid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs.oxana.instructure.com",
    "root_account_uuid": "VicYj3cu5BIFpoZhDVU4DZumnlBrWi1grgJEzADs"
  },
  "body": {
    "body": "<p>page 1 - updated</p>",
    "old_body": "<p>page 1</p>",
    "old_title": "Page 1 Created",
    "title": "Page 1 Updated",
    "wiki_page_id": "21070000000000009"
  }
}
```



### Event Body Schema

| Field | Description |
|-|-|
| **body** | The new page body. NOTE: This field will be truncated to only include the first 8192 characters. |
| **old_body** | The old page body. NOTE: This field will be truncated to only include the first 8192 characters. |
| **old_title** | The old title. NOTE: This field will be truncated to only include the first 8192 characters. |
| **title** | The new title. NOTE: This field will be truncated to only include the first 8192 characters. |
| **wiki_page_id** | The Canvas id of the changed wiki page. |

