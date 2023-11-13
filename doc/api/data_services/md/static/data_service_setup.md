Creating a New Data Stream
=========

These instructions, and a guide to the rest of Live Events/Canvas Data Services, are hosted in the Canvas Community and are found [here](https://community.canvaslms.com/t5/Admin-Guide/How-do-I-subscribe-to-Live-Events-using-Canvas-Data-Services/ta-p/227).

1. Click on +ADD button to launch a new subscription form
2. Add Subscription Name - use a distinct name to identify your subscription purpose or type e.g : Blackboard Ally Integration
3. Choose Delivery Method
  * SQS - AWS Simple Queue Services
        - URL - AWS SQS URL
        - Authentication via an IAM User Key and Secret is supported but optional. When using a Key and Secret for your SQS queue, please provide the region.
  * HTTPS - Webhook with JWT signing
        - URL - web service endpoint. Each live event will trigger a POST request to this endpoint.
        - If the "Sign Payload" option is not selected, the POST body will be the live event JSON.
        - If "Sign Payload" is selected, the event body will be a signed JWT with the live event data in the claims. Beta and Production JWKs can be found [here](https://8axpcl50e4.execute-api.us-east-1.amazonaws.com/main/jwks). These are rotated monthly; that endpoint returns the previous, current, and next (future) JWK used. Most libraries should be able to match the kid in the JWT header to the relevant JWK to validate the signature.
        - If a customer's HTTPS service experiences an outage, the events will not be delivered until the service is recovered. See [HTTPS delivery failures](#https-delivery-failures) for more info.
        - More info is found in [this Canvas Community article](https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-and-test-Canvas-Live-Events-using-HTTPS/ta-p/151)
4. Select the format of the events:
  * Canvas: A simple JSON payload of the events. See the docs for examples
  * Caliper IMS: A standardized JSON object for representing LMS events. See the docs for examples.
5. Find and select a single or multiple events
6. Save your new data stream

Your new subscription will be listed on the Settings page. You will be able to edit, duplicate or deactivate your new subscription record by using right side kebab menu.

## SQS configuration

More info is found in [this Canvas Community article](https://community.canvaslms.com/t5/Admin-Guide/How-do-I-create-an-SQS-queue-in-Amazon-Web-Services-to-receive/ta-p/170)

1. In the Amazon Web Services console, open the Simple Queue Service (SQS) console by typing the name in the Services field. When Simple Queue Service displays in the list, click the name.
2. In the Amazon SQS console, click the Create New Queue button
3. Enter a name for the queue. The name of the queue must begin with canvas-live-events.
4. By default, Standard Queue will be selected
  * To create a queue with the default settings, click the Quick-Create Queue button. To configure additional queue parameters, click
  the Configure Queue button. **Note: FIFO Queues are not currently supported.**
5. Open Queue Permissions
6. Select the checkbox next to the name of your queue. In the queue details area, click the Permissions tab
7. In the permission details window, select the Allow radio button
8. In the Principal field, enter the account number 636161780776. This account number is required for the queue to receive Live Events data
9.  Select the All SQS Actions checkbox
10. Click the Add Permission button

## HTTPS delivery failures

When setting up a subscription with an HTTPS webhook, the endpoint is expected to return a 2xx HTTP response code. If it does not, the event is assumed to not be successfully delivered and we will retry up to three times (a total of four tries), using exponential backoff with jitter, over a period of approximately 10 - 20 minutes.

If an excessive number of events fail after these retries, the subscription will be deactivated, and the creator of the subscription will be notified via email. In other words, if you are notified of a failure, it means we have consistently received invalid/error responses (or no response at all) from your webhook's server for a large number of events. The error threshold is approximately 9,500 timeout errors or 28,000 other errors in a 24 hour period. Potential failures on our side do not trigger disabling of the subscription, nor do intermittent failures which succeed upon retry.

It is the end user’s responsibility to implement logging on their endpoints to alert them to any issues and enable troubleshooting should an issue arise. We are unable to provide detailed information the failures, beyond the type of failures and/or HTTP status code, estimated number of events that failed after exhausting retries, and date of occurrence. Common failures include:

* HTTP 4xx or 5xx errors, suggesting some part of your endpoint's infrastructure has rejected requests due to authorization or load issues, or outages
* Timeout errors, suggesting your endpoint's HTTP server may be down or overloaded, or there is a network misconfiguration. Timeouts occur when failing to receive a response after 15 seconds.
* SSL/certificate errors

Since we only consider events that failed after exhausting retries, often errors can be reproduced by simply `curl`ing your endpoint.
