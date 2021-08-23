# LTI Launches

An LTI launch is the act of loading an LTI tool (See [LTI Overview](./01_lti_overview.md)). LTI launches serve as the primary form of user authentication for the LTI tool.

LTI launches for LTI 1.1 and LTI 2.0 are very similar. Launches for LTI 1.3, however, are more distinct. The following is a description of LTI launches for each LTI version (See "Intro to Spec Versions" in [the LTI overview](./01_lti_overview.md)).

## LTI 1.1 Launches
Canvas has five primary entry points for initiating LTI 1.1 launches:

- Users Controller (`/app/controllers/users_controller.rb#external_tool`)
- Application Controller (`app/controllers/application_controller.rb#content_tag_redirect`)
- External Tools Controller `show` action (`app/controllers/external_tools_controller.rb#show`)
- External Tools Controller `retrieve` action (`app/controllers/external_tools_controller.rb#retrieve`)
- External Tools Controller `sessionless_launch` action (`app/controllers/external_tools_controller.rb#sessionless_launch`)

Each launch path is defined in greater detail in the [LTI 1.1 Launches document](./05_lti_1_1_launches.md).

When making sweeping changes to LTI 1.1 launches in Canvas, these are the primary points that should be tested.

## LTI 2.0 Launches
Canvas has three primary entry points for initiating LTI 2.0 launches:

- LTI Messages Controller `resource` action (`app/controllers/lti/message_controller.rb#resource`)
- LTI Messages Controller `basic_lti_launch_request` action (`app/controllers/lti/message_controller.rb#basic_lti_launch_request`)
- LTI Messages Controller `reregistration` action (`app/controllers/lti/message_controller.rb#reregistration`)

Each launch path is defined in greater detail in the [LTI 2.0 Launches document](./06_lti_2_0_launches.md)

If, for some reason, you need to make sweeping changes to LTI 2.0 launches, these three entry points should be tested.

## LTI 1.3 Launches
Canvas has five primary entry points for initiating LTI 1.1 launches:

- Users Controller (`/app/controllers/users_controller.rb#external_tool`)
- Application Controller (`app/controllers/application_controller.rb#content_tag_redirect`)
- External Tools Controller `show` action (`app/controllers/external_tools_controller.rb#show`)
- External Tools Controller `retrieve` action (`app/controllers/external_tools_controller.rb#retrieve`)
- External Tools Controller `sessionless_launch` action (`app/controllers/external_tools_controller.rb#sessionless_launch`)

Each launch path is defined in greater detail in the [LTI 1.3 Launches document](./07_lti_1_3_launches.md).

Note that these are the exact same entry points for LTI 1.1. LTI 1.3 piggy-backs on the LTI 1.1 implementation (See [LTI Overview](./01_lti_overview.md)).

When making sweeping changes to LTI 1.1 launches in Canvas, these are the primary points that should be tested.
