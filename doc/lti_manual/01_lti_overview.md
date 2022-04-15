# LTI Overview

LTI stands for Learning Tools Interoperability and is a standard developed by IMS Global for interfacing between different learning tools. This provides a way for all LMSs and other EdTech products to speak the same language. Helpful links:

- [What is LTI and how it can improve your learning ecosystem | Moodle](https://moodle.com/news/what-is-lti-and-how-it-can-improve-your-learning-ecosystem/)
- [Learning Tools Interoperability Homepage | IMS Global Learning Consortium](https://www.imsglobal.org/activity/learning-tools-interoperability)

## Glossary of Core Concepts

- **Tool:** The main unit of LTI work, a singular piece of software that performs a task associated with the LMS. Examples include:
  - submitting homework using Google Drive
  - viewing a page of a textbook embedded in an assignment
  - creating a meeting in a calendar event with Microsoft Teams
- **Tool Consumer/Platform:** an LMS like Canvas, who consumes external content from tools. "Tool Consumer" is from earlier iterations of the standard, and has since been simplified to "Platform".
- **Tool Provider:** External content that provides a tool. From earlier iterations of the standard, and is now discouraged in favor of "Tool".
- **Launch:** The act of loading a tool, usually within an iframe set in a Canvas page. The main way of interacting with LTI tools. Data in this case is flowing from Canvas to the LTI tool, in the form of an HTTP POST request.
- **Placement:** The place in the Canvas UI where an LTI link should be displayed. For example, the `course_navigation` placement indicates to Canvas that a link to the tool should be placed in the course navigation. Note that although this concept never officially appears in the LTI spec, many if not all platforms that implement LTI have some sort of configuration for allowing the tool to be displayed in different places. For more information, see [the Placements page](./14_placements.md)

## Intro to Spec Versions

Canvas and IMS have historically worked hand-in-hand to develop new features and flesh out the core specifications of the LTI standard. This standard has gone through a few versions, all of which Canvas supports and implements in different ways. This is a main source of confusion when working on LTI in Canvas, since these versions are disparate and implemented very differently. In addition, some of these versions are now deprecated, and Canvas supports them only for backwards compatibility. Here is an overview of each of them:

### LTI 1.1

**Status: Deprecated**

The original LTI standard. LTI 1.0 was originally released in 2010 and provided a very simple mechanism for launching Tools from an LMS. This standard uses **OAuth 1** signing for authentication, and the data sent to the tool is contained in the form body of the HTTP POST request. LTI 1.1 was released in 2011 and provided the spec for Tools to send data back to the Tool Consumer, called the **Outcomes Service**. Standards for communicating with **LIS** (IMS Learning Information Services) were also included in this release, which provides methods to commmunicate enrollment information between Tool Providers, Tool Consumers, and SISs (Student Information Systems, enrollment and data systems commonly owned by the school).

- [LTI 1.1 Specification](https://www.imsglobal.org/specs/ltiv1p1/implementation-guide)
- [More information about LIS](https://www.imsglobal.org/activity/onerosterlis)

#### General Implementation Notes

LTI 1.0 was the first version of LTI implemented in Canvas. Much of its implementation is found in various models, controllers, and helpers in Canvas.

Some of its implementation is also located in the "LTI Outbound" gem, which serves as a data format translation layer (See "LTI 1.1 Launches" in [the LTI Launches document](./03_lti_launches.md) for more details).

### LTI 2.0

**Status: Deprecated**

You may be wondering why 2.0 comes before 1.3, and why it's deprecated - time for a short historical lesson. In 2014, IMS released a new version of the LTI Standard, and originally titled it 1.2. Once they finished its development, it had grown into something different and more extensible and more complicated. It introduced many new concepts, and added features like automatic tool registration, but that wasn't enough to save it from the bloat and complexity that came with it. Eventually, all parties involved decided to move on, and IMS deprecated the standard in favor of its newer version, LTI 1.3. However, the 1.2->2.0 name change stuck around, and so we have this strange hierarchy.

- [LTI v2.0 Implementation Guide | IMS Global Learning Consortium](http://www.imsglobal.org/specs/ltiv2p0/implementation-guide)
- [LTI Adoption Roadmap and 2.0 FAQs | IMS Global Learning Consortium](http://www.imsglobal.org/lti-adoption-roadmap)

#### Version-Specific Concepts

There are a _lot_ of new concepts in this standard, and they are best defined in the spec [here](http://www.imsglobal.org/specs/ltiv2p0/implementation-guide#toc-4).

#### General Implementation Notes

For the the most case, LTI 2.0 implementation in Canvas is completely separate from the LTI 1.1 implementation. The team made a clean break when implementing 2.0 (with some exceptions, see [LTI Launches](./03_lti_launches.md) for more details).

One of the downfalls of this decision was that LTI 2.0 never reached feature parity with LTI 1.1 in Canvas. Because of this (and the general complexity of LTI 2.0), it was rarely used in Canvas.

At the time of writing, the [plagiarism detection platform](./04_plagiarism_detection_platform.md) is the last valid reason to use LTI 2.0.

### LTI 1.3

**Status: Current**

The advent of LTI 1.3 in 2019 promised all the same functionality as previous versions, a brand new security model, and many more services that allowed greater communication between Tool and Platform. It is the current and long-term LTI Core version. The largest change was to move to **OpenID Connect** and **OAuth 2** workflows for authentication, and data is sent to the tool in a signed **JWT** instead of in the request body. This means that instead of the simple one-request flow of 1.1, a couple of additional redirects/requests are needed. In addition, 3 new services for sending data from Tool to Platform were standardized under the **LTI Advantage** umbrella, which will be talked about in detail later. This is the most important version to understand, since all new LTI development in Canvas falls under this category.

- [LTI 1.3 Specification](http://www.imsglobal.org/spec/lti/v1p3)
- [LTI Advantage Overview](http://www.imsglobal.org/spec/lti/v1p3/impl)
- [IMS Security Framework 1.0 | IMS Global Learning Consortium](https://www.imsglobal.org/spec/security/v1p0/)

#### Version-Specific Concepts

- **Deployment**: Commonly called an "installation" in Canvas LTI, the scope of contexts under which a tool is made available. For example, a tool can be deployed:
  - in a single course
  - in a root account, making it available to the whole institution
  - in Site Admin, making it available to all Canvas customers
- **Link**: A reference to a Tool stored by a Platform, usually a URL that points to the Tool. Not just an HTML link, though, since other metadata can be included like files, images, or HTML.
- **Resource**: An item of content delivered by a tool, that's usually linked to something like assignment. A Link to a Resource is called, you guessed it, a Resource Link. Launching a tool using a Resource Link is the main form of interaction with a Tool.
- **Message**: One of the two main integrations between Platform and Tool. A Message comes from a user and their actions within their browser, such as clicking on an embedded link for an LTI Resource. This action initiates an OpenID login, which results in the platform passing the Message (a JWT) to the tool.
- **Service**: One of the two main integrations between Platform and Tool. A Service allows a Tool to directly communicate with a Platform. The LTI Advantage services are an example of this integration type.

More information about these are found in the spec [here](http://www.imsglobal.org/spec/lti/v1p3/#key-concepts-and-elements).

#### General Implementation Notes

Rather than making a clean break in implementation as we did with LTI 2.0, the team decided to piggy-back on as much existing LTI 1.1 code as we could to quickly reach feature parity.

This worked very well in general, although some code may feel initially confusing without knowing it serves LTI 1.1 and LTI 1.3. More details on the LTI launch code can be found [here](./03_lti_launches).
