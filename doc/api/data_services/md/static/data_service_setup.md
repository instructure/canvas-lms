Creating a New Data Stream
=========

1. Click on +ADD button to launch a new subscription form
2. Add Subscription Name - use a distinct name to identify your subscription purpose or type e.g : Blackboard Ally Integration
3. Choose Delivery Method
  * SQS - AWS Simple Queue Services
        - URL - AWS SQS URL
        - Authentication via an IAM User Key and Secret is supported but optional. When using a Key and Secret for your SQS queue, please provide the region.
  * HTTPS - Webhook with JWT signing
        - URL - web service endpoint. The event body is a signed JWT. Beta and Production JWKs can be found [here](https://8axpcl50e4.execute-api.us-east-1.amazonaws.com/main/jwks). Most libraries should be able to match the kid in the JWT header to the relevant JWK to validate the signature. If a customer's HTTPS service experiences an outage, the events will not be delivered till the service is recovered.
4. Select the format of the events:
  * Canvas: A simple JSON payload of the events. See the docs for examples
  * Caliper IMS: A standardized JSON object for representing LMS events. See the docs for examples.
5. Find and select a single or multiple events
6. Save your new data stream

Your new subscription will be listed on the Settings page. You will be able to edit, duplicate or deactivate your new subscription record by using right side kebab menu.

## SQS configuration

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


