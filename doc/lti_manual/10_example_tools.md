# Example Tools

Here is a sample list of some of the LTI tools that exist in the Canvas ecosystem. Most of these are reference tools, used for testing, and directions for testing using these tools are found [here](./11_testing.md)

## LTI 1.1

### Outcome Service Example

[Code](https://github.com/instructure/lti_example)

This is a very simple tool that allows you to test 1.1 Grade Passback (also called Basic Outcomes). Manipulating the XML that gets passed from the tool to Canvas is also very easy.

Installation instructions are found in the repository's README file, and should still work with only a couple of small changes:
- omit the `-rubygems` from the start up command
- you may need to point your dockerized canvas at your computer's localhost, but this worked out of the box for me.
- the Canvas screenshots for configuring are out of date but the instructions still work.

### "The Heroku App"

[1.1 Config Builder](https://wkd-lti-test.herokuapp.com/xml_builder)
[Code](https://github.com/instructure/lti_tool_provider_example)

This tool is suitable for testing 1.1 launches from pretty much everywhere, and displays the parameters it was given on launch. It is a legacy app and lives in Weston Dransfield's Heroku account. Note that this is also a functioning LTI 2.0 tool! It is also totally possible to set this up locally, following the instructions in the README.

### In the Wild

Other 1.1 tools in the Canvas ecosystem:

- [Office365](https://gerrit.instructure.com/plugins/gitiles/office365)
- [Google Drive LTI](https://gerrit.instructure.com/plugins/gitiles/google_drive_lti)
- [Quizzes](https://gerrit.instructure.com/plugins/gitiles/quiz_lti) - also includes other repositories

## LTI 1.3

### LTI 1.3 Test Tool

[Code](https://gerrit.instructure.com/plugins/gitiles/lti-1.3-test-tool)

This tool is capable of testing 1.3 launches from all supported placements, and also supports all AGS actions (the 1.3 equivalent of Grade Passback). The README has instructions on how to configure Canvas to talk to this tool. This tool also supports multiple configurations within the same installation, which can be helpful for different types of testing.

### Data Services

[Code](https://gerrit.instructure.com/plugins/gitiles/live-events-lti)

This is a deployed-to-production tool that has a fairly simple Ruby implementation, and has been used as a reference for other internally-developed 1.3 tools. Note that it has other dependencies for it to fully work locally, but can be installed as a standalone way to test 1.3 launches.

### In the Wild

Other 1.3 tools in the Canvas ecosystem:

- [Google Meet](https://gerrit.instructure.com/plugins/gitiles/google-meet-lti)
- [Microsoft Teams](https://gerrit.instructure.com/plugins/gitiles/msteams-lti)
- [other examples](https://livegrep.inseng.net/search/?q=file%3A%5C.md%24%20-repo%3Acanvas-lms%20lti%201.3&fold_case=auto&regex=true&context=true) - a list of repositories that have "LTI 1.3" in their README file, not meant to be exhaustive

## LTI 2.0

### "The Heroku App"

[Home Page](https://wkd-lti-test.herokuapp.com/)
[Code](https://github.com/instructure/lti_tool_provider_example)

This tool is suitable for testing 2.0 launches from pretty much everywhere, and displays the parameters it was given on launch. It is a legacy app and lives in Weston Dransfield's Heroku account. Note that this is also a functioning LTI 1.1 tool! It is also totally possible to set this up locally, following the instructions in the README. The home page has a registration link for pasting into Canvas.

### Similarity Detection Reference Tool

[Code](https://github.com/instructure/lti_originality_report_example)

This tool is particularly helpful when testing or troubleshooting the [Plagiarism Detection Platform](./04_plagiarism_detection_platform). The README has adequate instructions for setting it up.

### In the Wild

About the only current use case for LTI 2.0 tools is the Plagiarism Platform, which is used by external tool providers like TurnItIn.