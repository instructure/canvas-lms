# The Canvas LTI Manual

**Audience:**

- new developers on the Interoperability team
- other Canvas developers who are interested in LTI
- anyone who is curious about how Canvas supports LTI
- not really customers

**Goal:**

- Provide a code-focused overview of the way that Canvas implements the LTI standard
- Help readers make an informed decision on where in the code to make changes
- Allow readers to discover existing LTI documentation, whether Canvas-specific or not
- Bring new developers up to speed so that they feel comfortable working with LTI
- Provide explanation for design decisions and why things are The Way They Are

**Contents**

- [LTI Overview](./01_lti_overview.md)
- [Tool Installation](./02_tool_installation.md)
  - [Example Tools](./10_example_tools.md)
- [LTI Launches](./03_lti_launches.md)
  - [1.1 Launches](./05_lti_1_1_launches.md)
  - [2.0 Launches](./06_lti_2_0_launches.md)
  - [1.3 Launches](./07_lti_1_3_launches.md)
- [Plagiarism Platform](./04_plagiarism_detection_platform.md)
- [Custom Parameters](./08_custom_parameters.md)
- [1.1 Implementation](./09_lti_1_1_implementation.md)
- [Common Testing Scenarios](./11_testing.md)
- [Deep Linking](./12_deep_linking.md)
- [Basic Outcomes](./13_basic_outcomes.md)
- [Placements](./14_placements.md)
- [Plagiarism](./15_plagiarism.md)
- [Privacy Level](./16_privacy_level.md)
- [Platform Storage](./17_platform_storage.md)

**Other Docs**

- [External Tools Introduction - Canvas LMS REST API Documentation (instructure.com)](https://canvas.instructure.com/doc/api/file.tools_intro.html)
  - the Canvas API docs have lots of reference-level specifics about installing tools, placements, variable substitutions, deep linking, etc
- [LTI from scratch (ruby) (instructure.com)](https://canvas.instructure.com/courses/913512)
  - a community Canvas course written by an unknown Platform team member years ago about LTI 1.1

---

More topics to write about:

- PostMessage
- list of placements and the postmessages and variable substitutions that work for each of them - probably also worth making customer facing
- variable expansion and custom fields
- custom params
- Services (implementation specifics)
  - AGS 1.3
  - Plagiarism Platform 2.0
  - Data Services/Subscriptions
