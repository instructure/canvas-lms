# Placements

As stated in the [LTI Overview](./01_lti_overview.md), placements are an integral part of the LTI experience in Canvas even though they aren't officially supported by the LTI spec. The list of supported placements in Canvas has grown over the years as both internal and external customers require new functionality.

The officially-documented list of placements is found in the API docs, in the LTI -> Placements section of the sidebar. It can be found [here](/doc/api/placements_overview.md). Note that some of the placements listed are restricted to only Instructure approved tools, such as the submission_type_selection placement.

## Definition and Configuration

Placement configuration and definition is currently somewhat scattered across a few different places in Canvas (and is ripe for consolidation).

The definitive list of all supported placements in Canvas is currently found in the [`Lti::ResourcePlacement`](/app/models/lti/resource_placement.rb) class.

As far as the front end goes, a list of placements with user-friendly names is also found in [`ExternalToolPlacementList`](/ui/features/external_apps/react/components/ExternalToolPlacementList.jsx), used by the External Apps UI to display a list of enabled placements for a tool, and the Developer Keys UI constructs the user-friendly name dynamically (and sadly not-i18n-ed either) in [`Placements.jsx`](/ui/features/developer_keys_v2/react/ManualConfigurationForm/Placements.jsx). 
As part of the LIME project, we also have some duplicated code that offers similar functionality in [LtiPlacement.ts](/ui/features/lti_registrations/manage/model/LtiPlacement.ts) and [i18nLtiPlacement.ts](/ui/features/lti_registrations/manage/model/i18nLtiPlacement.ts)

Placements that support [deep linking](./12_deep_linking.md) are listed and have configuration in [`Lti::Messages::DeepLinkingRequest`](/lib/lti/messages/deep_linking_request.rb).

## Adding a New Placement

Congratulations! If you have made it here, you have been tasked with adding a new placement in Canvas. It's up to you to work with product and design to figure out what this looks like and where it goes, but here are steps to help Canvas and LTI tools recognize this as a valid placement:

1. Choose a name for your new placement. It should describe roughly where it appears and be relatively short. Recent examples include `course_assignments_menu` and `module_index_menu_modal`.
2. Add the new placement to the list in [`Lti::ResourcePlacement::PLACEMENTS`](/app/models/lti/resource_placement.rb).
3. Add it and its user-friendly name (usually just the name of placement capitalized and spaced, eg "Course Assignments Menu" or "Module Index Menu (Modal)") to [`ExternalToolPlacementList.ALL_PLACEMENTS`](/ui/features/external_apps/react/components/ExternalToolPlacementList.jsx).
4. Add an entry for the placement in the [LtiPlacements, AllLtiPlacements, and LtiPlacementsByMessageType](/ui/features/lti_registrations/manage/model/LtiPlacement.ts) constants, as well as the user facing name of the placement to the [LtiPlacementTranslations](/ui/features/lti_registrations/manage/model/i18nLtiPlacement.ts) constant.
5. Add it to the list in the [External Tools API Spec](/spec/apis/v1/external_tools_api_spec.rb), following the example of [this commit](https://gerrit.instructure.com/c/canvas-lms/+/287770/6/spec/apis/v1/external_tools_api_spec.rb)
6. Add an image of the new placement to the [API docs](/doc/api/placements_overview.md). Make sure that you follow the naming convention of all of the other image files, to ensure we can easily link to our docs.
7. If this placement should accept deep links, or items of content returned from the tool, follow the [instructions](./12_deep_linking.md) to configure it for that.
