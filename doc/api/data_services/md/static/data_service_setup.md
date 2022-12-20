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
        - URL - web service endpoint. The event body is a signed JWT. Beta and Production JWKs can be found [here](https://8axpcl50e4.execute-api.us-east-1.amazonaws.com/main/jwks). Most libraries should be able to match the kid in the JWT header to the relevant JWK to validate the signature. If a customer's HTTPS service experiences an outage, the events will not be delivered till the service is recovered.
        - More info is found in [this Canvas Community article](https://community.canvaslms.com/t5/Admin-Guide/How-do-I-configure-and-test-Canvas-Live-Events-using-HTTPS/ta-p/151)
4. Select the format of the events:
  * Canvas: A simple JSON payload of the events. See the docs for examples
  * Caliper IMS: A standardized JSON object for representing LMS events. See the docs for examples.
5. Find and select a single or multiple events
6. Save your new data stream

Your new subscription will be listed on the Settings page. You will be able to edit, duplicate or deactivate your new subscription record by using right side kebab menu.

### Note: HTTPS Delivery and AWS API Gateway

If you are using an AWS API Gateway endpoint to consume Live Events via the HTTPS delivery method described above, you will need to configure a custom domain name for your endpoint instead of using the default public endpoint. HTTPS-type Live Events are sent from within Instructure-owned VPCs that have Private DNS enabled for a variety of AWS services, including API Gateway. Unfortunately, the private DNS entry for API Gateway includes a wild-card entry for `*.execute-api.<REGION>.amazonaws.com` that will catch all public API Gateway endpoints, as well as the private endpoints that it was designed to route [(source)](https://aws.amazon.com/premiumsupport/knowledge-center/api-gateway-vpc-connections/).

Steps for configuring a Custom Domain Name for an API Gateway endpoint:
1. Register a domain name, if you need one (if you already have a Route 53 Hosted Zone in your AWS account, or otherwise own a domain name, you can safely ignore this step).
2. Follow the instructions in [this support article](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-regional-api-custom-domain-create.html#create-regional-domain-using-console) to set up the custom domain name at the API Gateway level (most likely, using a "regional" domain that matches the region of your endpoint). Make sure to map the new domain to the correct stage of your endpoint. Confusingly, this doesn't actually create the domain name or register it with DNS, which will be handled in the next step.
3. Follow the instructions in [this support article](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-to-api-gateway.html#routing-to-api-gateway-config) to configure the actual DNS routing of traffic to this new domain name. This change may take a few minutes for the new domain name to actually work.
4. Once the custom domain name is accepting traffic, use the new URL when setting up HTTPS-type Live Events subscriptions in Canvas.

[Further reading](https://www.readysetcloud.io/blog/allen.helton/adding-a-custom-domain-to-aws-api-gateway/)

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


