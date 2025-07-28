/*
 * Copyright (C) 2025 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.IconCalculatorSolid = exports.IconCalculatorLine = exports.IconCalculatorDesmosSolid = exports.IconCalculatorDesmosLine = exports.IconButtonAndIconMakerSolid = exports.IconButtonAndIconMakerLine = exports.IconBulletListSquareSolid = exports.IconBulletListSquareLine = exports.IconBulletListSolid = exports.IconBulletListRomanSolid = exports.IconBulletListRomanLine = exports.IconBulletListLine = exports.IconBulletListCircleOutlineSolid = exports.IconBulletListCircleOutlineLine = exports.IconBulletListAlphaSolid = exports.IconBulletListAlphaLine = exports.IconBoxSolid = exports.IconBoxLine = exports.IconBookmarkSolid = exports.IconBookmarkLine = exports.IconBoldSolid = exports.IconBoldLine = exports.IconBlueprintSolid = exports.IconBlueprintLockSolid = exports.IconBlueprintLockLine = exports.IconBlueprintLine = exports.IconBankSolid = exports.IconBankLine = exports.IconAwardSolid = exports.IconAwardLine = exports.IconAudioSolid = exports.IconAudioOffSolid = exports.IconAudioOffLine = exports.IconAudioLine = exports.IconAttachMediaSolid = exports.IconAttachMediaLine = exports.IconAssignmentSolid = exports.IconAssignmentLine = exports.IconArrowUpSolid = exports.IconArrowUpLine = exports.IconArrowStartSolid = exports.IconArrowStartLine = exports.IconArrowRightSolid = exports.IconArrowRightLine = exports.IconArrowOpenUpSolid = exports.IconArrowOpenUpLine = exports.IconArrowOpenStartSolid = exports.IconArrowOpenStartLine = exports.IconArrowOpenRightSolid = exports.IconArrowOpenRightLine = exports.IconArrowOpenLeftSolid = exports.IconArrowOpenLeftLine = exports.IconArrowOpenEndSolid = exports.IconArrowOpenEndLine = exports.IconArrowOpenDownSolid = exports.IconArrowOpenDownLine = exports.IconArrowNestSolid = exports.IconArrowNestLine = exports.IconArrowLeftSolid = exports.IconArrowLeftLine = exports.IconArrowEndSolid = exports.IconArrowEndLine = exports.IconArrowDownSolid = exports.IconArrowDownLine = exports.IconArrowDoubleStartSolid = exports.IconArrowDoubleStartLine = exports.IconArrowDoubleEndSolid = exports.IconArrowDoubleEndLine = exports.IconArchiveSolid = exports.IconArchiveLine = exports.IconArcSolid = exports.IconArcLine = exports.IconAppleSolid = exports.IconAppleLine = exports.IconAnnouncementSolid = exports.IconAnnouncementLine = exports.IconAnnotateSolid = exports.IconAnnotateLine = exports.IconAndroidSolid = exports.IconAndroidLine = exports.IconAnalyticsSolid = exports.IconAnalyticsLine = exports.IconAlertsSolid = exports.IconAlertsLine = exports.IconAiSolid = exports.IconAiLine = exports.IconAdminToolsSolid = exports.IconAdminToolsLine = exports.IconAdminSolid = exports.IconAdminLine = exports.IconAddressBookSolid = exports.IconAddressBookLine = exports.IconAddSolid = exports.IconAddMediaSolid = exports.IconAddMediaLine = exports.IconAddLine = exports.IconAddFolderSolid = exports.IconAddFolderLine = exports.IconA11ySolid = exports.IconA11yLine = void 0;
exports.IconDiscussionReplyLine = exports.IconDiscussionReplyDarkSolid = exports.IconDiscussionReplyDarkLine = exports.IconDiscussionReply2Solid = exports.IconDiscussionReply2Line = exports.IconDiscussionNewSolid = exports.IconDiscussionNewLine = exports.IconDiscussionLine = exports.IconDiscussionCheckSolid = exports.IconDiscussionCheckLine = exports.IconDeactivateUserSolid = exports.IconDeactivateUserLine = exports.IconDashboardSolid = exports.IconDashboardLine = exports.IconCropSolid = exports.IconCropLine = exports.IconCoursesSolid = exports.IconCoursesLine = exports.IconCopySolid = exports.IconCopyLine = exports.IconCopyCourseSolid = exports.IconCopyCourseLine = exports.IconConfigureSolid = exports.IconConfigureLine = exports.IconComposeSolid = exports.IconComposeLine = exports.IconCompleteSolid = exports.IconCompleteLine = exports.IconCompassSolid = exports.IconCompassLine = exports.IconCommonsSolid = exports.IconCommonsLine = exports.IconCommentsOnSolid = exports.IconCommentsOnLine = exports.IconCommentsOffSolid = exports.IconCommentsOffLine = exports.IconCommentSolid = exports.IconCommentLine = exports.IconCollectionSolid = exports.IconCollectionSaveSolid = exports.IconCollectionSaveLine = exports.IconCollectionLine = exports.IconCollapseSolid = exports.IconCollapseLine = exports.IconCodeSolid = exports.IconCodeLine = exports.IconCloudUploadSolid = exports.IconCloudUploadLine = exports.IconCloudLockSolid = exports.IconCloudLockLine = exports.IconCloudDownloadSolid = exports.IconCloudDownloadLine = exports.IconClosedCaptioningSolid = exports.IconClosedCaptioningOnSolid = exports.IconClosedCaptioningOnLine = exports.IconClosedCaptioningOffSolid = exports.IconClosedCaptioningOffLine = exports.IconClosedCaptioningLine = exports.IconClockSolid = exports.IconClockLine = exports.IconClearTextFormattingSolid = exports.IconClearTextFormattingLine = exports.IconCircleArrowUpSolid = exports.IconCircleArrowUpLine = exports.IconCircleArrowDownSolid = exports.IconCircleArrowDownLine = exports.IconCheckSolid = exports.IconCheckPlusSolid = exports.IconCheckPlusLine = exports.IconCheckMarkSolid = exports.IconCheckMarkLine = exports.IconCheckMarkIndeterminateSolid = exports.IconCheckMarkIndeterminateLine = exports.IconCheckLine = exports.IconCheckDarkSolid = exports.IconCheckDarkLine = exports.IconChatSolid = exports.IconChatLine = exports.IconChartScatterSolid = exports.IconChartScatterLine = exports.IconChartPieSolid = exports.IconChartPieLine = exports.IconChartLineSolid = exports.IconChartLineLine = exports.IconCertifiedSolid = exports.IconCertifiedLine = exports.IconCanvasLogoSolid = exports.IconCanvasLogoLine = exports.IconCalendarReservedSolid = exports.IconCalendarReservedLine = exports.IconCalendarMonthSolid = exports.IconCalendarMonthLine = exports.IconCalendarDaysSolid = exports.IconCalendarDaysLine = exports.IconCalendarDaySolid = exports.IconCalendarDayLine = exports.IconCalendarClockSolid = exports.IconCalendarClockLine = exports.IconCalendarAddSolid = exports.IconCalendarAddLine = void 0;
exports.IconGridViewSolid = exports.IconGridViewLine = exports.IconGradebookSolid = exports.IconGradebookLine = exports.IconGradebookImportSolid = exports.IconGradebookImportLine = exports.IconGradebookExportSolid = exports.IconGradebookExportLine = exports.IconGiveAwardSolid = exports.IconGiveAwardLine = exports.IconGithubSolid = exports.IconGithubLine = exports.IconFullScreenSolid = exports.IconFullScreenLine = exports.IconForwardSolid = exports.IconForwardLine = exports.IconFolderSolid = exports.IconFolderLockedSolid = exports.IconFolderLockedLine = exports.IconFolderLine = exports.IconFlagSolid = exports.IconFlagLine = exports.IconFilterSolid = exports.IconFilterLine = exports.IconFilmstripSolid = exports.IconFilmstripLine = exports.IconFilesPublicDomainSolid = exports.IconFilesPublicDomainLine = exports.IconFilesObtainedPermissionSolid = exports.IconFilesObtainedPermissionLine = exports.IconFilesFairUseSolid = exports.IconFilesFairUseLine = exports.IconFilesCreativeCommonsSolid = exports.IconFilesCreativeCommonsLine = exports.IconFilesCopyrightSolid = exports.IconFilesCopyrightLine = exports.IconFileLockedSolid = exports.IconFileLockedLine = exports.IconFeedbackSolid = exports.IconFeedbackLine = exports.IconFastForwardSolid = exports.IconFastForwardLine = exports.IconFacebookSolid = exports.IconFacebookLine = exports.IconFacebookBoxedSolid = exports.IconFacebookBoxedLine = exports.IconEyeSolid = exports.IconEyeLine = exports.IconExternalLinkSolid = exports.IconExternalLinkLine = exports.IconExportSolid = exports.IconExportLine = exports.IconExportContentSolid = exports.IconExportContentLine = exports.IconExpandStartSolid = exports.IconExpandStartLine = exports.IconExpandSolid = exports.IconExpandLine = exports.IconExpandLeftSolid = exports.IconExpandLeftLine = exports.IconExpandItemsSolid = exports.IconExpandItemsLine = exports.IconExitFullScreenSolid = exports.IconExitFullScreenLine = exports.IconEssaySolid = exports.IconEssayLine = exports.IconEquellaSolid = exports.IconEquellaLine = exports.IconEquationSolid = exports.IconEquationLine = exports.IconEportfolioSolid = exports.IconEportfolioLine = exports.IconEndSolid = exports.IconEndLine = exports.IconEmptySolid = exports.IconEmptyLine = exports.IconEmailSolid = exports.IconEmailLine = exports.IconElevateLogoSolid = exports.IconElevateLogoLine = exports.IconEducatorsSolid = exports.IconEducatorsLine = exports.IconEditSolid = exports.IconEditLine = exports.IconDuplicateSolid = exports.IconDuplicateLine = exports.IconDropDownSolid = exports.IconDropDownLine = exports.IconDragHandleSolid = exports.IconDragHandleLine = exports.IconDownloadSolid = exports.IconDownloadLine = exports.IconDocumentSolid = exports.IconDocumentLine = exports.IconDiscussionXSolid = exports.IconDiscussionXLine = exports.IconDiscussionSolid = exports.IconDiscussionSearchSolid = exports.IconDiscussionSearchLine = exports.IconDiscussionReplySolid = void 0;
exports.IconMiniArrowDoubleSolid = exports.IconMiniArrowDoubleLine = exports.IconMicSolid = exports.IconMicOffSolid = exports.IconMicOffLine = exports.IconMicLine = exports.IconMessageSolid = exports.IconMessageLine = exports.IconMediaSolid = exports.IconMediaLine = exports.IconMatureSolid = exports.IconMatureLine = exports.IconMatureLightSolid = exports.IconMatureLightLine = exports.IconMaterialsRequiredSolid = exports.IconMaterialsRequiredLine = exports.IconMaterialsRequiredLightSolid = exports.IconMaterialsRequiredLightLine = exports.IconMasteryPathsSolid = exports.IconMasteryPathsLine = exports.IconMasteryLogoSolid = exports.IconMasteryLogoLine = exports.IconMasqueradeSolid = exports.IconMasqueradeLine = exports.IconMarkerSolid = exports.IconMarkerLine = exports.IconMarkAsReadSolid = exports.IconMarkAsReadLine = exports.IconLtiSolid = exports.IconLtiLine = exports.IconLockSolid = exports.IconLockLine = exports.IconListViewSolid = exports.IconListViewLine = exports.IconLinkedinSolid = exports.IconLinkedinLine = exports.IconLinkSolid = exports.IconLinkLine = exports.IconLineReaderSolid = exports.IconLineReaderLine = exports.IconLikeSolid = exports.IconLikeLine = exports.IconLifePreserverSolid = exports.IconLifePreserverLine = exports.IconLearnplatformSolid = exports.IconLearnplatformLine = exports.IconLaunchSolid = exports.IconLaunchLine = exports.IconKeyboardShortcutsSolid = exports.IconKeyboardShortcutsLine = exports.IconItalicSolid = exports.IconItalicLine = exports.IconInvitationSolid = exports.IconInvitationLine = exports.IconIntegrationsSolid = exports.IconIntegrationsLine = exports.IconInstructureSolid = exports.IconInstructureLogoSolid = exports.IconInstructureLogoLine = exports.IconInstructureLine = exports.IconInfoSolid = exports.IconInfoLine = exports.IconInfoBorderlessSolid = exports.IconInfoBorderlessLine = exports.IconIndentSolid = exports.IconIndentLine = exports.IconIndent2Solid = exports.IconIndent2Line = exports.IconInboxSolid = exports.IconInboxLine = exports.IconImportantDatesSolid = exports.IconImportantDatesLine = exports.IconImportSolid = exports.IconImportLine = exports.IconImportContentSolid = exports.IconImportContentLine = exports.IconImpactLogoSolid = exports.IconImpactLogoLine = exports.IconImmersiveReaderSolid = exports.IconImmersiveReaderLine = exports.IconImageSolid = exports.IconImageLine = exports.IconHourGlassSolid = exports.IconHourGlassLine = exports.IconHomeSolid = exports.IconHomeLine = exports.IconHighlighterSolid = exports.IconHighlighterLine = exports.IconHeartSolid = exports.IconHeartLine = exports.IconHeaderSolid = exports.IconHeaderLine = exports.IconHamburgerSolid = exports.IconHamburgerLine = exports.IconGroupSolid = exports.IconGroupNewSolid = exports.IconGroupNewLine = exports.IconGroupLine = exports.IconGroupDarkNewSolid = exports.IconGroupDarkNewLine = void 0;
exports.IconPostToSisSolid = exports.IconPostToSisLine = exports.IconPlusSolid = exports.IconPlusLine = exports.IconPlaySolid = exports.IconPlayLine = exports.IconPinterestSolid = exports.IconPinterestLine = exports.IconPinSolid = exports.IconPinLine = exports.IconPermissionsSolid = exports.IconPermissionsLine = exports.IconPeerReviewSolid = exports.IconPeerReviewLine = exports.IconPeerGradedSolid = exports.IconPeerGradedLine = exports.IconPdfSolid = exports.IconPdfLine = exports.IconPauseSolid = exports.IconPauseLine = exports.IconPartialSolid = exports.IconPartialLine = exports.IconPaperclipSolid = exports.IconPaperclipLine = exports.IconPaintSolid = exports.IconPaintLine = exports.IconPageUpSolid = exports.IconPageUpLine = exports.IconPageDownSolid = exports.IconPageDownLine = exports.IconOvalHalfSolid = exports.IconOvalHalfLine = exports.IconOutdentSolid = exports.IconOutdentLine = exports.IconOutdent2Solid = exports.IconOutdent2Line = exports.IconOutcomesSolid = exports.IconOutcomesLine = exports.IconOpenFolderSolid = exports.IconOpenFolderLine = exports.IconOffSolid = exports.IconOffLine = exports.IconNumberedListSolid = exports.IconNumberedListLine = exports.IconNotepadSolid = exports.IconNotepadLine = exports.IconNoteSolid = exports.IconNoteLine = exports.IconNoteLightSolid = exports.IconNoteLightLine = exports.IconNoteDarkSolid = exports.IconNoteDarkLine = exports.IconNotGradedSolid = exports.IconNotGradedLine = exports.IconNoSolid = exports.IconNoLine = exports.IconNextUnreadSolid = exports.IconNextUnreadLine = exports.IconMutedSolid = exports.IconMutedLine = exports.IconMsWordSolid = exports.IconMsWordLine = exports.IconMsPptSolid = exports.IconMsPptLine = exports.IconMsExcelSolid = exports.IconMsExcelLine = exports.IconMoveUpTopSolid = exports.IconMoveUpTopLine = exports.IconMoveUpSolid = exports.IconMoveUpLine = exports.IconMoveStartSolid = exports.IconMoveStartLine = exports.IconMoveRightSolid = exports.IconMoveRightLine = exports.IconMoveLeftSolid = exports.IconMoveLeftLine = exports.IconMoveEndSolid = exports.IconMoveEndLine = exports.IconMoveDownSolid = exports.IconMoveDownLine = exports.IconMoveDownBottomSolid = exports.IconMoveDownBottomLine = exports.IconMoreSolid = exports.IconMoreLine = exports.IconModuleSolid = exports.IconModuleLine = exports.IconMinimizeSolid = exports.IconMinimizeLine = exports.IconMiniArrowUpSolid = exports.IconMiniArrowUpLine = exports.IconMiniArrowStartSolid = exports.IconMiniArrowStartLine = exports.IconMiniArrowRightSolid = exports.IconMiniArrowRightLine = exports.IconMiniArrowLeftSolid = exports.IconMiniArrowLeftLine = exports.IconMiniArrowEndSolid = exports.IconMiniArrowEndLine = exports.IconMiniArrowDownSolid = exports.IconMiniArrowDownLine = void 0;
exports.IconSisSyncedSolid = exports.IconSisSyncedLine = exports.IconSisNotSyncedSolid = exports.IconSisNotSyncedLine = exports.IconSisImportedSolid = exports.IconSisImportedLine = exports.IconSingleMetricSolid = exports.IconSingleMetricLine = exports.IconShareSolid = exports.IconShareLine = exports.IconShapeRectangleSolid = exports.IconShapeRectangleLine = exports.IconShapePolygonSolid = exports.IconShapePolygonLine = exports.IconShapeOvalSolid = exports.IconShapeOvalLine = exports.IconSettingsSolid = exports.IconSettingsLine = exports.IconSettings2Solid = exports.IconSettings2Line = exports.IconSearchSolid = exports.IconSearchLine = exports.IconSearchAiSolid = exports.IconSearchAiLine = exports.IconSearchAddressBookSolid = exports.IconSearchAddressBookLine = exports.IconScreenCaptureSolid = exports.IconScreenCaptureLine = exports.IconSaveSolid = exports.IconSaveLine = exports.IconRulerSolid = exports.IconRulerLine = exports.IconRubricSolid = exports.IconRubricLine = exports.IconRubricDarkSolid = exports.IconRubricDarkLine = exports.IconRssSolid = exports.IconRssLine = exports.IconRssAddSolid = exports.IconRssAddLine = exports.IconRotateRightSolid = exports.IconRotateRightLine = exports.IconRotateLeftSolid = exports.IconRotateLeftLine = exports.IconRewindSolid = exports.IconRewindLine = exports.IconReviewScreenSolid = exports.IconReviewScreenLine = exports.IconResetSolid = exports.IconResetLine = exports.IconReplySolid = exports.IconReplyLine = exports.IconReplyAll2Solid = exports.IconReplyAll2Line = exports.IconReply2Solid = exports.IconReply2Line = exports.IconRepliedSolid = exports.IconRepliedLine = exports.IconRemoveLinkSolid = exports.IconRemoveLinkLine = exports.IconRemoveFromCollectionSolid = exports.IconRemoveFromCollectionLine = exports.IconRemoveBookmarkSolid = exports.IconRemoveBookmarkLine = exports.IconRefreshSolid = exports.IconRefreshLine = exports.IconRecordSolid = exports.IconRecordLine = exports.IconQuizTitleSolid = exports.IconQuizTitleLine = exports.IconQuizStatsTimeSolid = exports.IconQuizStatsTimeLine = exports.IconQuizStatsLowSolid = exports.IconQuizStatsLowLine = exports.IconQuizStatsHighSolid = exports.IconQuizStatsHighLine = exports.IconQuizStatsDeviationSolid = exports.IconQuizStatsDeviationLine = exports.IconQuizStatsCronbachsAlphaSolid = exports.IconQuizStatsCronbachsAlphaLine = exports.IconQuizStatsAvgSolid = exports.IconQuizStatsAvgLine = exports.IconQuizSolid = exports.IconQuizLine = exports.IconQuizInstructionsSolid = exports.IconQuizInstructionsLine = exports.IconQuestionSolid = exports.IconQuestionLine = exports.IconPublishSolid = exports.IconPublishLine = exports.IconProtractorSolid = exports.IconProtractorLine = exports.IconProgressSolid = exports.IconProgressLine = exports.IconPrinterSolid = exports.IconPrinterLine = exports.IconPrerequisiteSolid = exports.IconPrerequisiteLine = exports.IconPredictiveSolid = exports.IconPredictiveLine = void 0;
exports.IconTroubleSolid = exports.IconTroubleLine = exports.IconTrashSolid = exports.IconTrashLine = exports.IconToggleStartSolid = exports.IconToggleStartLine = exports.IconToggleRightSolid = exports.IconToggleRightLine = exports.IconToggleLeftSolid = exports.IconToggleLeftLine = exports.IconToggleEndSolid = exports.IconToggleEndLine = exports.IconTimerSolid = exports.IconTimerLine = exports.IconTextareaSolid = exports.IconTextareaLine = exports.IconTextSuperscriptSolid = exports.IconTextSuperscriptLine = exports.IconTextSubscriptSolid = exports.IconTextSubscriptLine = exports.IconTextStartSolid = exports.IconTextStartLine = exports.IconTextSolid = exports.IconTextRightSolid = exports.IconTextRightLine = exports.IconTextLine = exports.IconTextLeftSolid = exports.IconTextLeftLine = exports.IconTextEndSolid = exports.IconTextEndLine = exports.IconTextDirectionRtlSolid = exports.IconTextDirectionRtlLine = exports.IconTextDirectionLtrSolid = exports.IconTextDirectionLtrLine = exports.IconTextColorSolid = exports.IconTextColorLine = exports.IconTextCenteredSolid = exports.IconTextCenteredLine = exports.IconTextBackgroundColorSolid = exports.IconTextBackgroundColorLine = exports.IconTargetSolid = exports.IconTargetLine = exports.IconTagSolid = exports.IconTagLine = exports.IconTableTopHeaderSolid = exports.IconTableTopHeaderLine = exports.IconTableSplitCellsSolid = exports.IconTableSplitCellsLine = exports.IconTableSolid = exports.IconTableRowPropertiesSolid = exports.IconTableRowPropertiesLine = exports.IconTableMergeCellsSolid = exports.IconTableMergeCellsLine = exports.IconTableLine = exports.IconTableLeftHeaderSolid = exports.IconTableLeftHeaderLine = exports.IconTableInsertRowAfterSolid = exports.IconTableInsertRowAfterLine = exports.IconTableInsertRowAboveSolid = exports.IconTableInsertRowAboveLine = exports.IconTableInsertColumnBeforeSolid = exports.IconTableInsertColumnBeforeLine = exports.IconTableInsertColumnAfterSolid = exports.IconTableInsertColumnAfterLine = exports.IconTableDeleteTableSolid = exports.IconTableDeleteTableLine = exports.IconTableDeleteRowSolid = exports.IconTableDeleteRowLine = exports.IconTableDeleteColumnSolid = exports.IconTableDeleteColumnLine = exports.IconTableCellSelectAllSolid = exports.IconTableCellSelectAllLine = exports.IconSyllabusSolid = exports.IconSyllabusLine = exports.IconSubtitlesSolid = exports.IconSubtitlesLine = exports.IconSubaccountsSolid = exports.IconSubaccountsLine = exports.IconStudioSolid = exports.IconStudioLine = exports.IconStudentViewSolid = exports.IconStudentViewLine = exports.IconStrikethroughSolid = exports.IconStrikethroughLine = exports.IconStopSolid = exports.IconStopLine = exports.IconStatsSolid = exports.IconStatsLine = exports.IconStarSolid = exports.IconStarLine = exports.IconStarLightSolid = exports.IconStarLightLine = exports.IconStandardsSolid = exports.IconStandardsLine = exports.IconSpeedGraderSolid = exports.IconSpeedGraderLine = exports.IconSortSolid = exports.IconSortLine = exports.IconSkypeSolid = exports.IconSkypeLine = void 0;
exports.IconZoomOutSolid = exports.IconZoomOutLine = exports.IconZoomInSolid = exports.IconZoomInLine = exports.IconZippedSolid = exports.IconZippedLine = exports.IconXSolid = exports.IconXLine = exports.IconWordpressSolid = exports.IconWordpressLine = exports.IconWindowsSolid = exports.IconWindowsLine = exports.IconWarningSolid = exports.IconWarningLine = exports.IconWarningBorderlessSolid = exports.IconWarningBorderlessLine = exports.IconVideoSolid = exports.IconVideoLine = exports.IconVideoCameraSolid = exports.IconVideoCameraOffSolid = exports.IconVideoCameraOffLine = exports.IconVideoCameraLine = exports.IconUserSolid = exports.IconUserLine = exports.IconUserAddSolid = exports.IconUserAddLine = exports.IconUploadSolid = exports.IconUploadLine = exports.IconUpdownSolid = exports.IconUpdownLine = exports.IconUnpublishedSolid = exports.IconUnpublishedLine = exports.IconUnpublishSolid = exports.IconUnpublishLine = exports.IconUnmutedSolid = exports.IconUnmutedLine = exports.IconUnlockSolid = exports.IconUnlockLine = exports.IconUnderlineSolid = exports.IconUnderlineLine = exports.IconUnarchiveSolid = exports.IconUnarchiveLine = exports.IconTwitterSolid = exports.IconTwitterLine = exports.IconTwitterBoxedSolid = exports.IconTwitterBoxedLine = void 0;
const IconArcLine = exports.IconArcLine = {
  "variant": "Line",
  "glyphName": "Arc",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA01",
  "className": "icon-Arc",
  "classes": ["icon-line", "icon-Arc"],
  "bidirectional": false,
  "deprecated": false
};
const IconArcSolid = exports.IconArcSolid = {
  "variant": "Solid",
  "glyphName": "Arc",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA01",
  "className": "icon-Arc",
  "classes": ["icon-solid", "icon-Arc"],
  "bidirectional": false,
  "deprecated": false
};
const IconA11yLine = exports.IconA11yLine = {
  "variant": "Line",
  "glyphName": "a11y",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA02",
  "className": "icon-a11y",
  "classes": ["icon-line", "icon-a11y"],
  "bidirectional": false,
  "deprecated": false
};
const IconA11ySolid = exports.IconA11ySolid = {
  "variant": "Solid",
  "glyphName": "a11y",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA02",
  "className": "icon-a11y",
  "classes": ["icon-solid", "icon-a11y"],
  "bidirectional": false,
  "deprecated": false
};
const IconAddFolderLine = exports.IconAddFolderLine = {
  "variant": "Line",
  "glyphName": "add-folder",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA03",
  "className": "icon-add-folder",
  "classes": ["icon-line", "icon-add-folder"],
  "bidirectional": false,
  "deprecated": false
};
const IconAddFolderSolid = exports.IconAddFolderSolid = {
  "variant": "Solid",
  "glyphName": "add-folder",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA03",
  "className": "icon-add-folder",
  "classes": ["icon-solid", "icon-add-folder"],
  "bidirectional": false,
  "deprecated": false
};
const IconAddMediaLine = exports.IconAddMediaLine = {
  "variant": "Line",
  "glyphName": "add-media",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA04",
  "className": "icon-add-media",
  "classes": ["icon-line", "icon-add-media"],
  "bidirectional": false,
  "deprecated": false
};
const IconAddMediaSolid = exports.IconAddMediaSolid = {
  "variant": "Solid",
  "glyphName": "add-media",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA04",
  "className": "icon-add-media",
  "classes": ["icon-solid", "icon-add-media"],
  "bidirectional": false,
  "deprecated": false
};
const IconAddLine = exports.IconAddLine = {
  "variant": "Line",
  "glyphName": "add",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA05",
  "className": "icon-add",
  "classes": ["icon-line", "icon-add"],
  "bidirectional": false,
  "deprecated": false
};
const IconAddSolid = exports.IconAddSolid = {
  "variant": "Solid",
  "glyphName": "add",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA05",
  "className": "icon-add",
  "classes": ["icon-solid", "icon-add"],
  "bidirectional": false,
  "deprecated": false
};
const IconAddressBookLine = exports.IconAddressBookLine = {
  "variant": "Line",
  "glyphName": "address-book",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA06",
  "className": "icon-address-book",
  "classes": ["icon-line", "icon-address-book"],
  "bidirectional": true,
  "deprecated": false
};
const IconAddressBookSolid = exports.IconAddressBookSolid = {
  "variant": "Solid",
  "glyphName": "address-book",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA06",
  "className": "icon-address-book",
  "classes": ["icon-solid", "icon-address-book"],
  "bidirectional": true,
  "deprecated": false
};
const IconAdminToolsLine = exports.IconAdminToolsLine = {
  "variant": "Line",
  "glyphName": "admin-tools",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA07",
  "className": "icon-admin-tools",
  "classes": ["icon-line", "icon-admin-tools"],
  "bidirectional": false,
  "deprecated": false
};
const IconAdminToolsSolid = exports.IconAdminToolsSolid = {
  "variant": "Solid",
  "glyphName": "admin-tools",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA07",
  "className": "icon-admin-tools",
  "classes": ["icon-solid", "icon-admin-tools"],
  "bidirectional": false,
  "deprecated": false
};
const IconAdminLine = exports.IconAdminLine = {
  "variant": "Line",
  "glyphName": "admin",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA08",
  "className": "icon-admin",
  "classes": ["icon-line", "icon-admin"],
  "bidirectional": false,
  "deprecated": false
};
const IconAdminSolid = exports.IconAdminSolid = {
  "variant": "Solid",
  "glyphName": "admin",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA08",
  "className": "icon-admin",
  "classes": ["icon-solid", "icon-admin"],
  "bidirectional": false,
  "deprecated": false
};
const IconAiLine = exports.IconAiLine = {
  "variant": "Line",
  "glyphName": "ai",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA09",
  "className": "icon-ai",
  "classes": ["icon-line", "icon-ai"],
  "bidirectional": false,
  "deprecated": false
};
const IconAiSolid = exports.IconAiSolid = {
  "variant": "Solid",
  "glyphName": "ai",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA09",
  "className": "icon-ai",
  "classes": ["icon-solid", "icon-ai"],
  "bidirectional": false,
  "deprecated": false
};
const IconAlertsLine = exports.IconAlertsLine = {
  "variant": "Line",
  "glyphName": "alerts",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA0A",
  "className": "icon-alerts",
  "classes": ["icon-line", "icon-alerts"],
  "bidirectional": false,
  "deprecated": false
};
const IconAlertsSolid = exports.IconAlertsSolid = {
  "variant": "Solid",
  "glyphName": "alerts",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA0A",
  "className": "icon-alerts",
  "classes": ["icon-solid", "icon-alerts"],
  "bidirectional": false,
  "deprecated": false
};
const IconAnalyticsLine = exports.IconAnalyticsLine = {
  "variant": "Line",
  "glyphName": "analytics",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA0B",
  "className": "icon-analytics",
  "classes": ["icon-line", "icon-analytics"],
  "bidirectional": false,
  "deprecated": false
};
const IconAnalyticsSolid = exports.IconAnalyticsSolid = {
  "variant": "Solid",
  "glyphName": "analytics",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA0B",
  "className": "icon-analytics",
  "classes": ["icon-solid", "icon-analytics"],
  "bidirectional": false,
  "deprecated": false
};
const IconAndroidLine = exports.IconAndroidLine = {
  "variant": "Line",
  "glyphName": "android",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA0C",
  "className": "icon-android",
  "classes": ["icon-line", "icon-android"],
  "bidirectional": false,
  "deprecated": false
};
const IconAndroidSolid = exports.IconAndroidSolid = {
  "variant": "Solid",
  "glyphName": "android",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA0C",
  "className": "icon-android",
  "classes": ["icon-solid", "icon-android"],
  "bidirectional": false,
  "deprecated": false
};
const IconAnnotateLine = exports.IconAnnotateLine = {
  "variant": "Line",
  "glyphName": "annotate",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA0D",
  "className": "icon-annotate",
  "classes": ["icon-line", "icon-annotate"],
  "bidirectional": true,
  "deprecated": false
};
const IconAnnotateSolid = exports.IconAnnotateSolid = {
  "variant": "Solid",
  "glyphName": "annotate",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA0D",
  "className": "icon-annotate",
  "classes": ["icon-solid", "icon-annotate"],
  "bidirectional": true,
  "deprecated": false
};
const IconAnnouncementLine = exports.IconAnnouncementLine = {
  "variant": "Line",
  "glyphName": "announcement",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA0E",
  "className": "icon-announcement",
  "classes": ["icon-line", "icon-announcement"],
  "bidirectional": true,
  "deprecated": false
};
const IconAnnouncementSolid = exports.IconAnnouncementSolid = {
  "variant": "Solid",
  "glyphName": "announcement",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA0E",
  "className": "icon-announcement",
  "classes": ["icon-solid", "icon-announcement"],
  "bidirectional": true,
  "deprecated": false
};
const IconAppleLine = exports.IconAppleLine = {
  "variant": "Line",
  "glyphName": "apple",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA0F",
  "className": "icon-apple",
  "classes": ["icon-line", "icon-apple"],
  "bidirectional": false,
  "deprecated": false
};
const IconAppleSolid = exports.IconAppleSolid = {
  "variant": "Solid",
  "glyphName": "apple",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA0F",
  "className": "icon-apple",
  "classes": ["icon-solid", "icon-apple"],
  "bidirectional": false,
  "deprecated": false
};
const IconArchiveLine = exports.IconArchiveLine = {
  "variant": "Line",
  "glyphName": "archive",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA10",
  "className": "icon-archive",
  "classes": ["icon-line", "icon-archive"],
  "bidirectional": false,
  "deprecated": false
};
const IconArchiveSolid = exports.IconArchiveSolid = {
  "variant": "Solid",
  "glyphName": "archive",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA10",
  "className": "icon-archive",
  "classes": ["icon-solid", "icon-archive"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowDoubleEndLine = exports.IconArrowDoubleEndLine = {
  "variant": "Line",
  "glyphName": "arrow-double-end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA11",
  "className": "icon-arrow-double-end",
  "classes": ["icon-line", "icon-arrow-double-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowDoubleEndSolid = exports.IconArrowDoubleEndSolid = {
  "variant": "Solid",
  "glyphName": "arrow-double-end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA11",
  "className": "icon-arrow-double-end",
  "classes": ["icon-solid", "icon-arrow-double-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowDoubleStartLine = exports.IconArrowDoubleStartLine = {
  "variant": "Line",
  "glyphName": "arrow-double-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA12",
  "className": "icon-arrow-double-start",
  "classes": ["icon-line", "icon-arrow-double-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowDoubleStartSolid = exports.IconArrowDoubleStartSolid = {
  "variant": "Solid",
  "glyphName": "arrow-double-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA12",
  "className": "icon-arrow-double-start",
  "classes": ["icon-solid", "icon-arrow-double-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowDownLine = exports.IconArrowDownLine = {
  "variant": "Line",
  "glyphName": "arrow-down",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA13",
  "className": "icon-arrow-down",
  "classes": ["icon-line", "icon-arrow-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowDownSolid = exports.IconArrowDownSolid = {
  "variant": "Solid",
  "glyphName": "arrow-down",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA13",
  "className": "icon-arrow-down",
  "classes": ["icon-solid", "icon-arrow-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowEndLine = exports.IconArrowEndLine = {
  "variant": "Line",
  "glyphName": "arrow-end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA14",
  "className": "icon-arrow-end",
  "classes": ["icon-line", "icon-arrow-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowEndSolid = exports.IconArrowEndSolid = {
  "variant": "Solid",
  "glyphName": "arrow-end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA14",
  "className": "icon-arrow-end",
  "classes": ["icon-solid", "icon-arrow-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowLeftLine = exports.IconArrowLeftLine = {
  "variant": "Line",
  "glyphName": "arrow-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA15",
  "className": "icon-arrow-left",
  "classes": ["icon-line", "icon-arrow-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowLeftSolid = exports.IconArrowLeftSolid = {
  "variant": "Solid",
  "glyphName": "arrow-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA15",
  "className": "icon-arrow-left",
  "classes": ["icon-solid", "icon-arrow-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowNestLine = exports.IconArrowNestLine = {
  "variant": "Line",
  "glyphName": "arrow-nest",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA16",
  "className": "icon-arrow-nest",
  "classes": ["icon-line", "icon-arrow-nest"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowNestSolid = exports.IconArrowNestSolid = {
  "variant": "Solid",
  "glyphName": "arrow-nest",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA16",
  "className": "icon-arrow-nest",
  "classes": ["icon-solid", "icon-arrow-nest"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowOpenDownLine = exports.IconArrowOpenDownLine = {
  "variant": "Line",
  "glyphName": "arrow-open-down",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA17",
  "className": "icon-arrow-open-down",
  "classes": ["icon-line", "icon-arrow-open-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowOpenDownSolid = exports.IconArrowOpenDownSolid = {
  "variant": "Solid",
  "glyphName": "arrow-open-down",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA17",
  "className": "icon-arrow-open-down",
  "classes": ["icon-solid", "icon-arrow-open-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowOpenEndLine = exports.IconArrowOpenEndLine = {
  "variant": "Line",
  "glyphName": "arrow-open-end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA18",
  "className": "icon-arrow-open-end",
  "classes": ["icon-line", "icon-arrow-open-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowOpenEndSolid = exports.IconArrowOpenEndSolid = {
  "variant": "Solid",
  "glyphName": "arrow-open-end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA18",
  "className": "icon-arrow-open-end",
  "classes": ["icon-solid", "icon-arrow-open-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowOpenLeftLine = exports.IconArrowOpenLeftLine = {
  "variant": "Line",
  "glyphName": "arrow-open-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA19",
  "className": "icon-arrow-open-left",
  "classes": ["icon-line", "icon-arrow-open-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowOpenLeftSolid = exports.IconArrowOpenLeftSolid = {
  "variant": "Solid",
  "glyphName": "arrow-open-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA19",
  "className": "icon-arrow-open-left",
  "classes": ["icon-solid", "icon-arrow-open-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowOpenRightLine = exports.IconArrowOpenRightLine = {
  "variant": "Line",
  "glyphName": "arrow-open-right",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA1A",
  "className": "icon-arrow-open-right",
  "classes": ["icon-line", "icon-arrow-open-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowOpenRightSolid = exports.IconArrowOpenRightSolid = {
  "variant": "Solid",
  "glyphName": "arrow-open-right",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA1A",
  "className": "icon-arrow-open-right",
  "classes": ["icon-solid", "icon-arrow-open-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowOpenStartLine = exports.IconArrowOpenStartLine = {
  "variant": "Line",
  "glyphName": "arrow-open-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA1B",
  "className": "icon-arrow-open-start",
  "classes": ["icon-line", "icon-arrow-open-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowOpenStartSolid = exports.IconArrowOpenStartSolid = {
  "variant": "Solid",
  "glyphName": "arrow-open-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA1B",
  "className": "icon-arrow-open-start",
  "classes": ["icon-solid", "icon-arrow-open-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowOpenUpLine = exports.IconArrowOpenUpLine = {
  "variant": "Line",
  "glyphName": "arrow-open-up",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA1C",
  "className": "icon-arrow-open-up",
  "classes": ["icon-line", "icon-arrow-open-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowOpenUpSolid = exports.IconArrowOpenUpSolid = {
  "variant": "Solid",
  "glyphName": "arrow-open-up",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA1C",
  "className": "icon-arrow-open-up",
  "classes": ["icon-solid", "icon-arrow-open-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowRightLine = exports.IconArrowRightLine = {
  "variant": "Line",
  "glyphName": "arrow-right",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA1D",
  "className": "icon-arrow-right",
  "classes": ["icon-line", "icon-arrow-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowRightSolid = exports.IconArrowRightSolid = {
  "variant": "Solid",
  "glyphName": "arrow-right",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA1D",
  "className": "icon-arrow-right",
  "classes": ["icon-solid", "icon-arrow-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconArrowStartLine = exports.IconArrowStartLine = {
  "variant": "Line",
  "glyphName": "arrow-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA1E",
  "className": "icon-arrow-start",
  "classes": ["icon-line", "icon-arrow-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowStartSolid = exports.IconArrowStartSolid = {
  "variant": "Solid",
  "glyphName": "arrow-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA1E",
  "className": "icon-arrow-start",
  "classes": ["icon-solid", "icon-arrow-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconArrowUpLine = exports.IconArrowUpLine = {
  "variant": "Line",
  "glyphName": "arrow-up",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA1F",
  "className": "icon-arrow-up",
  "classes": ["icon-line", "icon-arrow-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconArrowUpSolid = exports.IconArrowUpSolid = {
  "variant": "Solid",
  "glyphName": "arrow-up",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA1F",
  "className": "icon-arrow-up",
  "classes": ["icon-solid", "icon-arrow-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconAssignmentLine = exports.IconAssignmentLine = {
  "variant": "Line",
  "glyphName": "assignment",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA20",
  "className": "icon-assignment",
  "classes": ["icon-line", "icon-assignment"],
  "bidirectional": true,
  "deprecated": false
};
const IconAssignmentSolid = exports.IconAssignmentSolid = {
  "variant": "Solid",
  "glyphName": "assignment",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA20",
  "className": "icon-assignment",
  "classes": ["icon-solid", "icon-assignment"],
  "bidirectional": true,
  "deprecated": false
};
const IconAttachMediaLine = exports.IconAttachMediaLine = {
  "variant": "Line",
  "glyphName": "attach-media",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA21",
  "className": "icon-attach-media",
  "classes": ["icon-line", "icon-attach-media"],
  "bidirectional": false,
  "deprecated": false
};
const IconAttachMediaSolid = exports.IconAttachMediaSolid = {
  "variant": "Solid",
  "glyphName": "attach-media",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA21",
  "className": "icon-attach-media",
  "classes": ["icon-solid", "icon-attach-media"],
  "bidirectional": false,
  "deprecated": false
};
const IconAudioOffLine = exports.IconAudioOffLine = {
  "variant": "Line",
  "glyphName": "audio-off",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA22",
  "className": "icon-audio-off",
  "classes": ["icon-line", "icon-audio-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconAudioOffSolid = exports.IconAudioOffSolid = {
  "variant": "Solid",
  "glyphName": "audio-off",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA22",
  "className": "icon-audio-off",
  "classes": ["icon-solid", "icon-audio-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconAudioLine = exports.IconAudioLine = {
  "variant": "Line",
  "glyphName": "audio",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA23",
  "className": "icon-audio",
  "classes": ["icon-line", "icon-audio"],
  "bidirectional": true,
  "deprecated": false
};
const IconAudioSolid = exports.IconAudioSolid = {
  "variant": "Solid",
  "glyphName": "audio",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA23",
  "className": "icon-audio",
  "classes": ["icon-solid", "icon-audio"],
  "bidirectional": true,
  "deprecated": false
};
const IconAwardLine = exports.IconAwardLine = {
  "variant": "Line",
  "glyphName": "award",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA24",
  "className": "icon-award",
  "classes": ["icon-line", "icon-award"],
  "bidirectional": false,
  "deprecated": false
};
const IconAwardSolid = exports.IconAwardSolid = {
  "variant": "Solid",
  "glyphName": "award",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA24",
  "className": "icon-award",
  "classes": ["icon-solid", "icon-award"],
  "bidirectional": false,
  "deprecated": false
};
const IconBankLine = exports.IconBankLine = {
  "variant": "Line",
  "glyphName": "bank",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA25",
  "className": "icon-bank",
  "classes": ["icon-line", "icon-bank"],
  "bidirectional": false,
  "deprecated": false
};
const IconBankSolid = exports.IconBankSolid = {
  "variant": "Solid",
  "glyphName": "bank",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA25",
  "className": "icon-bank",
  "classes": ["icon-solid", "icon-bank"],
  "bidirectional": false,
  "deprecated": false
};
const IconBlueprintLockLine = exports.IconBlueprintLockLine = {
  "variant": "Line",
  "glyphName": "blueprint-lock",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA26",
  "className": "icon-blueprint-lock",
  "classes": ["icon-line", "icon-blueprint-lock"],
  "bidirectional": false,
  "deprecated": false
};
const IconBlueprintLockSolid = exports.IconBlueprintLockSolid = {
  "variant": "Solid",
  "glyphName": "blueprint-lock",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA26",
  "className": "icon-blueprint-lock",
  "classes": ["icon-solid", "icon-blueprint-lock"],
  "bidirectional": false,
  "deprecated": false
};
const IconBlueprintLine = exports.IconBlueprintLine = {
  "variant": "Line",
  "glyphName": "blueprint",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA27",
  "className": "icon-blueprint",
  "classes": ["icon-line", "icon-blueprint"],
  "bidirectional": false,
  "deprecated": false
};
const IconBlueprintSolid = exports.IconBlueprintSolid = {
  "variant": "Solid",
  "glyphName": "blueprint",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA27",
  "className": "icon-blueprint",
  "classes": ["icon-solid", "icon-blueprint"],
  "bidirectional": false,
  "deprecated": false
};
const IconBoldLine = exports.IconBoldLine = {
  "variant": "Line",
  "glyphName": "bold",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA28",
  "className": "icon-bold",
  "classes": ["icon-line", "icon-bold"],
  "bidirectional": false,
  "deprecated": false
};
const IconBoldSolid = exports.IconBoldSolid = {
  "variant": "Solid",
  "glyphName": "bold",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA28",
  "className": "icon-bold",
  "classes": ["icon-solid", "icon-bold"],
  "bidirectional": false,
  "deprecated": false
};
const IconBookmarkLine = exports.IconBookmarkLine = {
  "variant": "Line",
  "glyphName": "bookmark",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA29",
  "className": "icon-bookmark",
  "classes": ["icon-line", "icon-bookmark"],
  "bidirectional": false,
  "deprecated": false
};
const IconBookmarkSolid = exports.IconBookmarkSolid = {
  "variant": "Solid",
  "glyphName": "bookmark",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA29",
  "className": "icon-bookmark",
  "classes": ["icon-solid", "icon-bookmark"],
  "bidirectional": false,
  "deprecated": false
};
const IconBoxLine = exports.IconBoxLine = {
  "variant": "Line",
  "glyphName": "box",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA2A",
  "className": "icon-box",
  "classes": ["icon-line", "icon-box"],
  "bidirectional": false,
  "deprecated": false
};
const IconBoxSolid = exports.IconBoxSolid = {
  "variant": "Solid",
  "glyphName": "box",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA2A",
  "className": "icon-box",
  "classes": ["icon-solid", "icon-box"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListAlphaLine = exports.IconBulletListAlphaLine = {
  "variant": "Line",
  "glyphName": "bullet-list-alpha",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA2B",
  "className": "icon-bullet-list-alpha",
  "classes": ["icon-line", "icon-bullet-list-alpha"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListAlphaSolid = exports.IconBulletListAlphaSolid = {
  "variant": "Solid",
  "glyphName": "bullet-list-alpha",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA2B",
  "className": "icon-bullet-list-alpha",
  "classes": ["icon-solid", "icon-bullet-list-alpha"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListCircleOutlineLine = exports.IconBulletListCircleOutlineLine = {
  "variant": "Line",
  "glyphName": "bullet-list-circle-outline",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA2C",
  "className": "icon-bullet-list-circle-outline",
  "classes": ["icon-line", "icon-bullet-list-circle-outline"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListCircleOutlineSolid = exports.IconBulletListCircleOutlineSolid = {
  "variant": "Solid",
  "glyphName": "bullet-list-circle-outline",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA2C",
  "className": "icon-bullet-list-circle-outline",
  "classes": ["icon-solid", "icon-bullet-list-circle-outline"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListRomanLine = exports.IconBulletListRomanLine = {
  "variant": "Line",
  "glyphName": "bullet-list-roman",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA2D",
  "className": "icon-bullet-list-roman",
  "classes": ["icon-line", "icon-bullet-list-roman"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListRomanSolid = exports.IconBulletListRomanSolid = {
  "variant": "Solid",
  "glyphName": "bullet-list-roman",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA2D",
  "className": "icon-bullet-list-roman",
  "classes": ["icon-solid", "icon-bullet-list-roman"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListSquareLine = exports.IconBulletListSquareLine = {
  "variant": "Line",
  "glyphName": "bullet-list-square",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA2E",
  "className": "icon-bullet-list-square",
  "classes": ["icon-line", "icon-bullet-list-square"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListSquareSolid = exports.IconBulletListSquareSolid = {
  "variant": "Solid",
  "glyphName": "bullet-list-square",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA2E",
  "className": "icon-bullet-list-square",
  "classes": ["icon-solid", "icon-bullet-list-square"],
  "bidirectional": false,
  "deprecated": false
};
const IconBulletListLine = exports.IconBulletListLine = {
  "variant": "Line",
  "glyphName": "bullet-list",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA2F",
  "className": "icon-bullet-list",
  "classes": ["icon-line", "icon-bullet-list"],
  "bidirectional": true,
  "deprecated": false
};
const IconBulletListSolid = exports.IconBulletListSolid = {
  "variant": "Solid",
  "glyphName": "bullet-list",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA2F",
  "className": "icon-bullet-list",
  "classes": ["icon-solid", "icon-bullet-list"],
  "bidirectional": true,
  "deprecated": false
};
const IconButtonAndIconMakerLine = exports.IconButtonAndIconMakerLine = {
  "variant": "Line",
  "glyphName": "button-and-icon-maker",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA30",
  "className": "icon-button-and-icon-maker",
  "classes": ["icon-line", "icon-button-and-icon-maker"],
  "bidirectional": false,
  "deprecated": false
};
const IconButtonAndIconMakerSolid = exports.IconButtonAndIconMakerSolid = {
  "variant": "Solid",
  "glyphName": "button-and-icon-maker",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA30",
  "className": "icon-button-and-icon-maker",
  "classes": ["icon-solid", "icon-button-and-icon-maker"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalculatorDesmosLine = exports.IconCalculatorDesmosLine = {
  "variant": "Line",
  "glyphName": "calculator-desmos",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA31",
  "className": "icon-calculator-desmos",
  "classes": ["icon-line", "icon-calculator-desmos"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalculatorDesmosSolid = exports.IconCalculatorDesmosSolid = {
  "variant": "Solid",
  "glyphName": "calculator-desmos",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA31",
  "className": "icon-calculator-desmos",
  "classes": ["icon-solid", "icon-calculator-desmos"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalculatorLine = exports.IconCalculatorLine = {
  "variant": "Line",
  "glyphName": "calculator",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA32",
  "className": "icon-calculator",
  "classes": ["icon-line", "icon-calculator"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalculatorSolid = exports.IconCalculatorSolid = {
  "variant": "Solid",
  "glyphName": "calculator",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA32",
  "className": "icon-calculator",
  "classes": ["icon-solid", "icon-calculator"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarAddLine = exports.IconCalendarAddLine = {
  "variant": "Line",
  "glyphName": "calendar-add",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA33",
  "className": "icon-calendar-add",
  "classes": ["icon-line", "icon-calendar-add"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarAddSolid = exports.IconCalendarAddSolid = {
  "variant": "Solid",
  "glyphName": "calendar-add",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA33",
  "className": "icon-calendar-add",
  "classes": ["icon-solid", "icon-calendar-add"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarClockLine = exports.IconCalendarClockLine = {
  "variant": "Line",
  "glyphName": "calendar-clock",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA34",
  "className": "icon-calendar-clock",
  "classes": ["icon-line", "icon-calendar-clock"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarClockSolid = exports.IconCalendarClockSolid = {
  "variant": "Solid",
  "glyphName": "calendar-clock",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA34",
  "className": "icon-calendar-clock",
  "classes": ["icon-solid", "icon-calendar-clock"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarDayLine = exports.IconCalendarDayLine = {
  "variant": "Line",
  "glyphName": "calendar-day",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA35",
  "className": "icon-calendar-day",
  "classes": ["icon-line", "icon-calendar-day"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarDaySolid = exports.IconCalendarDaySolid = {
  "variant": "Solid",
  "glyphName": "calendar-day",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA35",
  "className": "icon-calendar-day",
  "classes": ["icon-solid", "icon-calendar-day"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarDaysLine = exports.IconCalendarDaysLine = {
  "variant": "Line",
  "glyphName": "calendar-days",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA36",
  "className": "icon-calendar-days",
  "classes": ["icon-line", "icon-calendar-days"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarDaysSolid = exports.IconCalendarDaysSolid = {
  "variant": "Solid",
  "glyphName": "calendar-days",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA36",
  "className": "icon-calendar-days",
  "classes": ["icon-solid", "icon-calendar-days"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarMonthLine = exports.IconCalendarMonthLine = {
  "variant": "Line",
  "glyphName": "calendar-month",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA37",
  "className": "icon-calendar-month",
  "classes": ["icon-line", "icon-calendar-month"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarMonthSolid = exports.IconCalendarMonthSolid = {
  "variant": "Solid",
  "glyphName": "calendar-month",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA37",
  "className": "icon-calendar-month",
  "classes": ["icon-solid", "icon-calendar-month"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarReservedLine = exports.IconCalendarReservedLine = {
  "variant": "Line",
  "glyphName": "calendar-reserved",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA38",
  "className": "icon-calendar-reserved",
  "classes": ["icon-line", "icon-calendar-reserved"],
  "bidirectional": false,
  "deprecated": false
};
const IconCalendarReservedSolid = exports.IconCalendarReservedSolid = {
  "variant": "Solid",
  "glyphName": "calendar-reserved",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA38",
  "className": "icon-calendar-reserved",
  "classes": ["icon-solid", "icon-calendar-reserved"],
  "bidirectional": false,
  "deprecated": false
};
const IconCanvasLogoLine = exports.IconCanvasLogoLine = {
  "variant": "Line",
  "glyphName": "canvas-logo",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA39",
  "className": "icon-canvas-logo",
  "classes": ["icon-line", "icon-canvas-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconCanvasLogoSolid = exports.IconCanvasLogoSolid = {
  "variant": "Solid",
  "glyphName": "canvas-logo",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA39",
  "className": "icon-canvas-logo",
  "classes": ["icon-solid", "icon-canvas-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconCertifiedLine = exports.IconCertifiedLine = {
  "variant": "Line",
  "glyphName": "certified",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA3A",
  "className": "icon-certified",
  "classes": ["icon-line", "icon-certified"],
  "bidirectional": false,
  "deprecated": false
};
const IconCertifiedSolid = exports.IconCertifiedSolid = {
  "variant": "Solid",
  "glyphName": "certified",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA3A",
  "className": "icon-certified",
  "classes": ["icon-solid", "icon-certified"],
  "bidirectional": false,
  "deprecated": false
};
const IconChartLineLine = exports.IconChartLineLine = {
  "variant": "Line",
  "glyphName": "chart-line",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA3B",
  "className": "icon-chart-line",
  "classes": ["icon-line", "icon-chart-line"],
  "bidirectional": false,
  "deprecated": false
};
const IconChartLineSolid = exports.IconChartLineSolid = {
  "variant": "Solid",
  "glyphName": "chart-line",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA3B",
  "className": "icon-chart-line",
  "classes": ["icon-solid", "icon-chart-line"],
  "bidirectional": false,
  "deprecated": false
};
const IconChartPieLine = exports.IconChartPieLine = {
  "variant": "Line",
  "glyphName": "chart-pie",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA3C",
  "className": "icon-chart-pie",
  "classes": ["icon-line", "icon-chart-pie"],
  "bidirectional": false,
  "deprecated": false
};
const IconChartPieSolid = exports.IconChartPieSolid = {
  "variant": "Solid",
  "glyphName": "chart-pie",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA3C",
  "className": "icon-chart-pie",
  "classes": ["icon-solid", "icon-chart-pie"],
  "bidirectional": false,
  "deprecated": false
};
const IconChartScatterLine = exports.IconChartScatterLine = {
  "variant": "Line",
  "glyphName": "chart-scatter",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA3D",
  "className": "icon-chart-scatter",
  "classes": ["icon-line", "icon-chart-scatter"],
  "bidirectional": false,
  "deprecated": false
};
const IconChartScatterSolid = exports.IconChartScatterSolid = {
  "variant": "Solid",
  "glyphName": "chart-scatter",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA3D",
  "className": "icon-chart-scatter",
  "classes": ["icon-solid", "icon-chart-scatter"],
  "bidirectional": false,
  "deprecated": false
};
const IconChatLine = exports.IconChatLine = {
  "variant": "Line",
  "glyphName": "chat",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA3E",
  "className": "icon-chat",
  "classes": ["icon-line", "icon-chat"],
  "bidirectional": true,
  "deprecated": false
};
const IconChatSolid = exports.IconChatSolid = {
  "variant": "Solid",
  "glyphName": "chat",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA3E",
  "className": "icon-chat",
  "classes": ["icon-solid", "icon-chat"],
  "bidirectional": true,
  "deprecated": false
};
const IconCheckDarkLine = exports.IconCheckDarkLine = {
  "variant": "Line",
  "glyphName": "check-dark",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA3F",
  "className": "icon-check-dark",
  "classes": ["icon-line", "icon-check-dark"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckDarkSolid = exports.IconCheckDarkSolid = {
  "variant": "Solid",
  "glyphName": "check-dark",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA3F",
  "className": "icon-check-dark",
  "classes": ["icon-solid", "icon-check-dark"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckMarkIndeterminateLine = exports.IconCheckMarkIndeterminateLine = {
  "variant": "Line",
  "glyphName": "check-mark-indeterminate",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA40",
  "className": "icon-check-mark-indeterminate",
  "classes": ["icon-line", "icon-check-mark-indeterminate"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckMarkIndeterminateSolid = exports.IconCheckMarkIndeterminateSolid = {
  "variant": "Solid",
  "glyphName": "check-mark-indeterminate",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA40",
  "className": "icon-check-mark-indeterminate",
  "classes": ["icon-solid", "icon-check-mark-indeterminate"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckMarkLine = exports.IconCheckMarkLine = {
  "variant": "Line",
  "glyphName": "check-mark",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA41",
  "className": "icon-check-mark",
  "classes": ["icon-line", "icon-check-mark"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckMarkSolid = exports.IconCheckMarkSolid = {
  "variant": "Solid",
  "glyphName": "check-mark",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA41",
  "className": "icon-check-mark",
  "classes": ["icon-solid", "icon-check-mark"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckPlusLine = exports.IconCheckPlusLine = {
  "variant": "Line",
  "glyphName": "check-plus",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA42",
  "className": "icon-check-plus",
  "classes": ["icon-line", "icon-check-plus"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckPlusSolid = exports.IconCheckPlusSolid = {
  "variant": "Solid",
  "glyphName": "check-plus",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA42",
  "className": "icon-check-plus",
  "classes": ["icon-solid", "icon-check-plus"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckLine = exports.IconCheckLine = {
  "variant": "Line",
  "glyphName": "check",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA43",
  "className": "icon-check",
  "classes": ["icon-line", "icon-check"],
  "bidirectional": false,
  "deprecated": false
};
const IconCheckSolid = exports.IconCheckSolid = {
  "variant": "Solid",
  "glyphName": "check",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA43",
  "className": "icon-check",
  "classes": ["icon-solid", "icon-check"],
  "bidirectional": false,
  "deprecated": false
};
const IconCircleArrowDownLine = exports.IconCircleArrowDownLine = {
  "variant": "Line",
  "glyphName": "circle-arrow-down",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA44",
  "className": "icon-circle-arrow-down",
  "classes": ["icon-line", "icon-circle-arrow-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconCircleArrowDownSolid = exports.IconCircleArrowDownSolid = {
  "variant": "Solid",
  "glyphName": "circle-arrow-down",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA44",
  "className": "icon-circle-arrow-down",
  "classes": ["icon-solid", "icon-circle-arrow-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconCircleArrowUpLine = exports.IconCircleArrowUpLine = {
  "variant": "Line",
  "glyphName": "circle-arrow-up",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA45",
  "className": "icon-circle-arrow-up",
  "classes": ["icon-line", "icon-circle-arrow-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconCircleArrowUpSolid = exports.IconCircleArrowUpSolid = {
  "variant": "Solid",
  "glyphName": "circle-arrow-up",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA45",
  "className": "icon-circle-arrow-up",
  "classes": ["icon-solid", "icon-circle-arrow-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconClearTextFormattingLine = exports.IconClearTextFormattingLine = {
  "variant": "Line",
  "glyphName": "clear-text-formatting",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA46",
  "className": "icon-clear-text-formatting",
  "classes": ["icon-line", "icon-clear-text-formatting"],
  "bidirectional": false,
  "deprecated": false
};
const IconClearTextFormattingSolid = exports.IconClearTextFormattingSolid = {
  "variant": "Solid",
  "glyphName": "clear-text-formatting",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA46",
  "className": "icon-clear-text-formatting",
  "classes": ["icon-solid", "icon-clear-text-formatting"],
  "bidirectional": false,
  "deprecated": false
};
const IconClockLine = exports.IconClockLine = {
  "variant": "Line",
  "glyphName": "clock",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA47",
  "className": "icon-clock",
  "classes": ["icon-line", "icon-clock"],
  "bidirectional": false,
  "deprecated": false
};
const IconClockSolid = exports.IconClockSolid = {
  "variant": "Solid",
  "glyphName": "clock",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA47",
  "className": "icon-clock",
  "classes": ["icon-solid", "icon-clock"],
  "bidirectional": false,
  "deprecated": false
};
const IconClosedCaptioningOffLine = exports.IconClosedCaptioningOffLine = {
  "variant": "Line",
  "glyphName": "closed-captioning-off",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA48",
  "className": "icon-closed-captioning-off",
  "classes": ["icon-line", "icon-closed-captioning-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconClosedCaptioningOffSolid = exports.IconClosedCaptioningOffSolid = {
  "variant": "Solid",
  "glyphName": "closed-captioning-off",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA48",
  "className": "icon-closed-captioning-off",
  "classes": ["icon-solid", "icon-closed-captioning-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconClosedCaptioningOnLine = exports.IconClosedCaptioningOnLine = {
  "variant": "Line",
  "glyphName": "closed-captioning-on",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA49",
  "className": "icon-closed-captioning-on",
  "classes": ["icon-line", "icon-closed-captioning-on"],
  "bidirectional": false,
  "deprecated": false
};
const IconClosedCaptioningOnSolid = exports.IconClosedCaptioningOnSolid = {
  "variant": "Solid",
  "glyphName": "closed-captioning-on",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA49",
  "className": "icon-closed-captioning-on",
  "classes": ["icon-solid", "icon-closed-captioning-on"],
  "bidirectional": false,
  "deprecated": false
};
const IconClosedCaptioningLine = exports.IconClosedCaptioningLine = {
  "variant": "Line",
  "glyphName": "closed-captioning",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA4A",
  "className": "icon-closed-captioning",
  "classes": ["icon-line", "icon-closed-captioning"],
  "bidirectional": false,
  "deprecated": false
};
const IconClosedCaptioningSolid = exports.IconClosedCaptioningSolid = {
  "variant": "Solid",
  "glyphName": "closed-captioning",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA4A",
  "className": "icon-closed-captioning",
  "classes": ["icon-solid", "icon-closed-captioning"],
  "bidirectional": false,
  "deprecated": false
};
const IconCloudDownloadLine = exports.IconCloudDownloadLine = {
  "variant": "Line",
  "glyphName": "cloud-download",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA4B",
  "className": "icon-cloud-download",
  "classes": ["icon-line", "icon-cloud-download"],
  "bidirectional": false,
  "deprecated": false
};
const IconCloudDownloadSolid = exports.IconCloudDownloadSolid = {
  "variant": "Solid",
  "glyphName": "cloud-download",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA4B",
  "className": "icon-cloud-download",
  "classes": ["icon-solid", "icon-cloud-download"],
  "bidirectional": false,
  "deprecated": false
};
const IconCloudLockLine = exports.IconCloudLockLine = {
  "variant": "Line",
  "glyphName": "cloud-lock",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA4C",
  "className": "icon-cloud-lock",
  "classes": ["icon-line", "icon-cloud-lock"],
  "bidirectional": false,
  "deprecated": false
};
const IconCloudLockSolid = exports.IconCloudLockSolid = {
  "variant": "Solid",
  "glyphName": "cloud-lock",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA4C",
  "className": "icon-cloud-lock",
  "classes": ["icon-solid", "icon-cloud-lock"],
  "bidirectional": false,
  "deprecated": false
};
const IconCloudUploadLine = exports.IconCloudUploadLine = {
  "variant": "Line",
  "glyphName": "cloud-upload",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA4D",
  "className": "icon-cloud-upload",
  "classes": ["icon-line", "icon-cloud-upload"],
  "bidirectional": false,
  "deprecated": false
};
const IconCloudUploadSolid = exports.IconCloudUploadSolid = {
  "variant": "Solid",
  "glyphName": "cloud-upload",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA4D",
  "className": "icon-cloud-upload",
  "classes": ["icon-solid", "icon-cloud-upload"],
  "bidirectional": false,
  "deprecated": false
};
const IconCodeLine = exports.IconCodeLine = {
  "variant": "Line",
  "glyphName": "code",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA4E",
  "className": "icon-code",
  "classes": ["icon-line", "icon-code"],
  "bidirectional": false,
  "deprecated": false
};
const IconCodeSolid = exports.IconCodeSolid = {
  "variant": "Solid",
  "glyphName": "code",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA4E",
  "className": "icon-code",
  "classes": ["icon-solid", "icon-code"],
  "bidirectional": false,
  "deprecated": false
};
const IconCollapseLine = exports.IconCollapseLine = {
  "variant": "Line",
  "glyphName": "collapse",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA4F",
  "className": "icon-collapse",
  "classes": ["icon-line", "icon-collapse"],
  "bidirectional": false,
  "deprecated": false
};
const IconCollapseSolid = exports.IconCollapseSolid = {
  "variant": "Solid",
  "glyphName": "collapse",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA4F",
  "className": "icon-collapse",
  "classes": ["icon-solid", "icon-collapse"],
  "bidirectional": false,
  "deprecated": false
};
const IconCollectionSaveLine = exports.IconCollectionSaveLine = {
  "variant": "Line",
  "glyphName": "collection-save",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA50",
  "className": "icon-collection-save",
  "classes": ["icon-line", "icon-collection-save"],
  "bidirectional": false,
  "deprecated": false
};
const IconCollectionSaveSolid = exports.IconCollectionSaveSolid = {
  "variant": "Solid",
  "glyphName": "collection-save",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA50",
  "className": "icon-collection-save",
  "classes": ["icon-solid", "icon-collection-save"],
  "bidirectional": false,
  "deprecated": false
};
const IconCollectionLine = exports.IconCollectionLine = {
  "variant": "Line",
  "glyphName": "collection",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA51",
  "className": "icon-collection",
  "classes": ["icon-line", "icon-collection"],
  "bidirectional": false,
  "deprecated": false
};
const IconCollectionSolid = exports.IconCollectionSolid = {
  "variant": "Solid",
  "glyphName": "collection",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA51",
  "className": "icon-collection",
  "classes": ["icon-solid", "icon-collection"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommentLine = exports.IconCommentLine = {
  "variant": "Line",
  "glyphName": "comment",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA52",
  "className": "icon-comment",
  "classes": ["icon-line", "icon-comment"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommentSolid = exports.IconCommentSolid = {
  "variant": "Solid",
  "glyphName": "comment",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA52",
  "className": "icon-comment",
  "classes": ["icon-solid", "icon-comment"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommentsOffLine = exports.IconCommentsOffLine = {
  "variant": "Line",
  "glyphName": "comments-off",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA53",
  "className": "icon-comments-off",
  "classes": ["icon-line", "icon-comments-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommentsOffSolid = exports.IconCommentsOffSolid = {
  "variant": "Solid",
  "glyphName": "comments-off",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA53",
  "className": "icon-comments-off",
  "classes": ["icon-solid", "icon-comments-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommentsOnLine = exports.IconCommentsOnLine = {
  "variant": "Line",
  "glyphName": "comments-on",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA54",
  "className": "icon-comments-on",
  "classes": ["icon-line", "icon-comments-on"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommentsOnSolid = exports.IconCommentsOnSolid = {
  "variant": "Solid",
  "glyphName": "comments-on",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA54",
  "className": "icon-comments-on",
  "classes": ["icon-solid", "icon-comments-on"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommonsLine = exports.IconCommonsLine = {
  "variant": "Line",
  "glyphName": "commons",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA55",
  "className": "icon-commons",
  "classes": ["icon-line", "icon-commons"],
  "bidirectional": false,
  "deprecated": false
};
const IconCommonsSolid = exports.IconCommonsSolid = {
  "variant": "Solid",
  "glyphName": "commons",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA55",
  "className": "icon-commons",
  "classes": ["icon-solid", "icon-commons"],
  "bidirectional": false,
  "deprecated": false
};
const IconCompassLine = exports.IconCompassLine = {
  "variant": "Line",
  "glyphName": "compass",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA56",
  "className": "icon-compass",
  "classes": ["icon-line", "icon-compass"],
  "bidirectional": false,
  "deprecated": false
};
const IconCompassSolid = exports.IconCompassSolid = {
  "variant": "Solid",
  "glyphName": "compass",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA56",
  "className": "icon-compass",
  "classes": ["icon-solid", "icon-compass"],
  "bidirectional": false,
  "deprecated": false
};
const IconCompleteLine = exports.IconCompleteLine = {
  "variant": "Line",
  "glyphName": "complete",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA57",
  "className": "icon-complete",
  "classes": ["icon-line", "icon-complete"],
  "bidirectional": false,
  "deprecated": false
};
const IconCompleteSolid = exports.IconCompleteSolid = {
  "variant": "Solid",
  "glyphName": "complete",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA57",
  "className": "icon-complete",
  "classes": ["icon-solid", "icon-complete"],
  "bidirectional": false,
  "deprecated": false
};
const IconComposeLine = exports.IconComposeLine = {
  "variant": "Line",
  "glyphName": "compose",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA58",
  "className": "icon-compose",
  "classes": ["icon-line", "icon-compose"],
  "bidirectional": true,
  "deprecated": false
};
const IconComposeSolid = exports.IconComposeSolid = {
  "variant": "Solid",
  "glyphName": "compose",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA58",
  "className": "icon-compose",
  "classes": ["icon-solid", "icon-compose"],
  "bidirectional": true,
  "deprecated": false
};
const IconConfigureLine = exports.IconConfigureLine = {
  "variant": "Line",
  "glyphName": "configure",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA59",
  "className": "icon-configure",
  "classes": ["icon-line", "icon-configure"],
  "bidirectional": false,
  "deprecated": false
};
const IconConfigureSolid = exports.IconConfigureSolid = {
  "variant": "Solid",
  "glyphName": "configure",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA59",
  "className": "icon-configure",
  "classes": ["icon-solid", "icon-configure"],
  "bidirectional": false,
  "deprecated": false
};
const IconCopyCourseLine = exports.IconCopyCourseLine = {
  "variant": "Line",
  "glyphName": "copy-course",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA5A",
  "className": "icon-copy-course",
  "classes": ["icon-line", "icon-copy-course"],
  "bidirectional": false,
  "deprecated": true
};
const IconCopyCourseSolid = exports.IconCopyCourseSolid = {
  "variant": "Solid",
  "glyphName": "copy-course",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA5A",
  "className": "icon-copy-course",
  "classes": ["icon-solid", "icon-copy-course"],
  "bidirectional": false,
  "deprecated": true
};
const IconCopyLine = exports.IconCopyLine = {
  "variant": "Line",
  "glyphName": "copy",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA5B",
  "className": "icon-copy",
  "classes": ["icon-line", "icon-copy"],
  "bidirectional": false,
  "deprecated": false
};
const IconCopySolid = exports.IconCopySolid = {
  "variant": "Solid",
  "glyphName": "copy",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA5B",
  "className": "icon-copy",
  "classes": ["icon-solid", "icon-copy"],
  "bidirectional": false,
  "deprecated": false
};
const IconCoursesLine = exports.IconCoursesLine = {
  "variant": "Line",
  "glyphName": "courses",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA5C",
  "className": "icon-courses",
  "classes": ["icon-line", "icon-courses"],
  "bidirectional": true,
  "deprecated": false
};
const IconCoursesSolid = exports.IconCoursesSolid = {
  "variant": "Solid",
  "glyphName": "courses",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA5C",
  "className": "icon-courses",
  "classes": ["icon-solid", "icon-courses"],
  "bidirectional": true,
  "deprecated": false
};
const IconCropLine = exports.IconCropLine = {
  "variant": "Line",
  "glyphName": "crop",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA5D",
  "className": "icon-crop",
  "classes": ["icon-line", "icon-crop"],
  "bidirectional": false,
  "deprecated": false
};
const IconCropSolid = exports.IconCropSolid = {
  "variant": "Solid",
  "glyphName": "crop",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA5D",
  "className": "icon-crop",
  "classes": ["icon-solid", "icon-crop"],
  "bidirectional": false,
  "deprecated": false
};
const IconDashboardLine = exports.IconDashboardLine = {
  "variant": "Line",
  "glyphName": "dashboard",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA5E",
  "className": "icon-dashboard",
  "classes": ["icon-line", "icon-dashboard"],
  "bidirectional": false,
  "deprecated": false
};
const IconDashboardSolid = exports.IconDashboardSolid = {
  "variant": "Solid",
  "glyphName": "dashboard",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA5E",
  "className": "icon-dashboard",
  "classes": ["icon-solid", "icon-dashboard"],
  "bidirectional": false,
  "deprecated": false
};
const IconDeactivateUserLine = exports.IconDeactivateUserLine = {
  "variant": "Line",
  "glyphName": "deactivate-user",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA5F",
  "className": "icon-deactivate-user",
  "classes": ["icon-line", "icon-deactivate-user"],
  "bidirectional": false,
  "deprecated": false
};
const IconDeactivateUserSolid = exports.IconDeactivateUserSolid = {
  "variant": "Solid",
  "glyphName": "deactivate-user",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA5F",
  "className": "icon-deactivate-user",
  "classes": ["icon-solid", "icon-deactivate-user"],
  "bidirectional": false,
  "deprecated": false
};
const IconDiscussionCheckLine = exports.IconDiscussionCheckLine = {
  "variant": "Line",
  "glyphName": "discussion-check",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA60",
  "className": "icon-discussion-check",
  "classes": ["icon-line", "icon-discussion-check"],
  "bidirectional": false,
  "deprecated": false
};
const IconDiscussionCheckSolid = exports.IconDiscussionCheckSolid = {
  "variant": "Solid",
  "glyphName": "discussion-check",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA60",
  "className": "icon-discussion-check",
  "classes": ["icon-solid", "icon-discussion-check"],
  "bidirectional": false,
  "deprecated": false
};
const IconDiscussionNewLine = exports.IconDiscussionNewLine = {
  "variant": "Line",
  "glyphName": "discussion-new",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA61",
  "className": "icon-discussion-new",
  "classes": ["icon-line", "icon-discussion-new"],
  "bidirectional": false,
  "deprecated": false
};
const IconDiscussionNewSolid = exports.IconDiscussionNewSolid = {
  "variant": "Solid",
  "glyphName": "discussion-new",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA61",
  "className": "icon-discussion-new",
  "classes": ["icon-solid", "icon-discussion-new"],
  "bidirectional": false,
  "deprecated": false
};
const IconDiscussionReply2Line = exports.IconDiscussionReply2Line = {
  "variant": "Line",
  "glyphName": "discussion-reply-2",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA62",
  "className": "icon-discussion-reply-2",
  "classes": ["icon-line", "icon-discussion-reply-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconDiscussionReply2Solid = exports.IconDiscussionReply2Solid = {
  "variant": "Solid",
  "glyphName": "discussion-reply-2",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA62",
  "className": "icon-discussion-reply-2",
  "classes": ["icon-solid", "icon-discussion-reply-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconDiscussionReplyDarkLine = exports.IconDiscussionReplyDarkLine = {
  "variant": "Line",
  "glyphName": "discussion-reply-dark",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA63",
  "className": "icon-discussion-reply-dark",
  "classes": ["icon-line", "icon-discussion-reply-dark"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionReplyDarkSolid = exports.IconDiscussionReplyDarkSolid = {
  "variant": "Solid",
  "glyphName": "discussion-reply-dark",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA63",
  "className": "icon-discussion-reply-dark",
  "classes": ["icon-solid", "icon-discussion-reply-dark"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionReplyLine = exports.IconDiscussionReplyLine = {
  "variant": "Line",
  "glyphName": "discussion-reply",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA64",
  "className": "icon-discussion-reply",
  "classes": ["icon-line", "icon-discussion-reply"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionReplySolid = exports.IconDiscussionReplySolid = {
  "variant": "Solid",
  "glyphName": "discussion-reply",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA64",
  "className": "icon-discussion-reply",
  "classes": ["icon-solid", "icon-discussion-reply"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionSearchLine = exports.IconDiscussionSearchLine = {
  "variant": "Line",
  "glyphName": "discussion-search",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA65",
  "className": "icon-discussion-search",
  "classes": ["icon-line", "icon-discussion-search"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionSearchSolid = exports.IconDiscussionSearchSolid = {
  "variant": "Solid",
  "glyphName": "discussion-search",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA65",
  "className": "icon-discussion-search",
  "classes": ["icon-solid", "icon-discussion-search"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionXLine = exports.IconDiscussionXLine = {
  "variant": "Line",
  "glyphName": "discussion-x",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA66",
  "className": "icon-discussion-x",
  "classes": ["icon-line", "icon-discussion-x"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionXSolid = exports.IconDiscussionXSolid = {
  "variant": "Solid",
  "glyphName": "discussion-x",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA66",
  "className": "icon-discussion-x",
  "classes": ["icon-solid", "icon-discussion-x"],
  "bidirectional": false,
  "deprecated": true
};
const IconDiscussionLine = exports.IconDiscussionLine = {
  "variant": "Line",
  "glyphName": "discussion",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA67",
  "className": "icon-discussion",
  "classes": ["icon-line", "icon-discussion"],
  "bidirectional": true,
  "deprecated": false
};
const IconDiscussionSolid = exports.IconDiscussionSolid = {
  "variant": "Solid",
  "glyphName": "discussion",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA67",
  "className": "icon-discussion",
  "classes": ["icon-solid", "icon-discussion"],
  "bidirectional": true,
  "deprecated": false
};
const IconDocumentLine = exports.IconDocumentLine = {
  "variant": "Line",
  "glyphName": "document",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA68",
  "className": "icon-document",
  "classes": ["icon-line", "icon-document"],
  "bidirectional": true,
  "deprecated": false
};
const IconDocumentSolid = exports.IconDocumentSolid = {
  "variant": "Solid",
  "glyphName": "document",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA68",
  "className": "icon-document",
  "classes": ["icon-solid", "icon-document"],
  "bidirectional": true,
  "deprecated": false
};
const IconDownloadLine = exports.IconDownloadLine = {
  "variant": "Line",
  "glyphName": "download",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA69",
  "className": "icon-download",
  "classes": ["icon-line", "icon-download"],
  "bidirectional": false,
  "deprecated": false
};
const IconDownloadSolid = exports.IconDownloadSolid = {
  "variant": "Solid",
  "glyphName": "download",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA69",
  "className": "icon-download",
  "classes": ["icon-solid", "icon-download"],
  "bidirectional": false,
  "deprecated": false
};
const IconDragHandleLine = exports.IconDragHandleLine = {
  "variant": "Line",
  "glyphName": "drag-handle",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA6A",
  "className": "icon-drag-handle",
  "classes": ["icon-line", "icon-drag-handle"],
  "bidirectional": false,
  "deprecated": false
};
const IconDragHandleSolid = exports.IconDragHandleSolid = {
  "variant": "Solid",
  "glyphName": "drag-handle",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA6A",
  "className": "icon-drag-handle",
  "classes": ["icon-solid", "icon-drag-handle"],
  "bidirectional": false,
  "deprecated": false
};
const IconDropDownLine = exports.IconDropDownLine = {
  "variant": "Line",
  "glyphName": "drop-down",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA6B",
  "className": "icon-drop-down",
  "classes": ["icon-line", "icon-drop-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconDropDownSolid = exports.IconDropDownSolid = {
  "variant": "Solid",
  "glyphName": "drop-down",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA6B",
  "className": "icon-drop-down",
  "classes": ["icon-solid", "icon-drop-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconDuplicateLine = exports.IconDuplicateLine = {
  "variant": "Line",
  "glyphName": "duplicate",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA6C",
  "className": "icon-duplicate",
  "classes": ["icon-line", "icon-duplicate"],
  "bidirectional": false,
  "deprecated": false
};
const IconDuplicateSolid = exports.IconDuplicateSolid = {
  "variant": "Solid",
  "glyphName": "duplicate",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA6C",
  "className": "icon-duplicate",
  "classes": ["icon-solid", "icon-duplicate"],
  "bidirectional": false,
  "deprecated": false
};
const IconEditLine = exports.IconEditLine = {
  "variant": "Line",
  "glyphName": "edit",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA6D",
  "className": "icon-edit",
  "classes": ["icon-line", "icon-edit"],
  "bidirectional": true,
  "deprecated": false
};
const IconEditSolid = exports.IconEditSolid = {
  "variant": "Solid",
  "glyphName": "edit",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA6D",
  "className": "icon-edit",
  "classes": ["icon-solid", "icon-edit"],
  "bidirectional": true,
  "deprecated": false
};
const IconEducatorsLine = exports.IconEducatorsLine = {
  "variant": "Line",
  "glyphName": "educators",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA6E",
  "className": "icon-educators",
  "classes": ["icon-line", "icon-educators"],
  "bidirectional": false,
  "deprecated": false
};
const IconEducatorsSolid = exports.IconEducatorsSolid = {
  "variant": "Solid",
  "glyphName": "educators",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA6E",
  "className": "icon-educators",
  "classes": ["icon-solid", "icon-educators"],
  "bidirectional": false,
  "deprecated": false
};
const IconElevateLogoLine = exports.IconElevateLogoLine = {
  "variant": "Line",
  "glyphName": "elevate-logo",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA6F",
  "className": "icon-elevate-logo",
  "classes": ["icon-line", "icon-elevate-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconElevateLogoSolid = exports.IconElevateLogoSolid = {
  "variant": "Solid",
  "glyphName": "elevate-logo",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA6F",
  "className": "icon-elevate-logo",
  "classes": ["icon-solid", "icon-elevate-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconEmailLine = exports.IconEmailLine = {
  "variant": "Line",
  "glyphName": "email",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA70",
  "className": "icon-email",
  "classes": ["icon-line", "icon-email"],
  "bidirectional": false,
  "deprecated": false
};
const IconEmailSolid = exports.IconEmailSolid = {
  "variant": "Solid",
  "glyphName": "email",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA70",
  "className": "icon-email",
  "classes": ["icon-solid", "icon-email"],
  "bidirectional": false,
  "deprecated": false
};
const IconEmptyLine = exports.IconEmptyLine = {
  "variant": "Line",
  "glyphName": "empty",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA71",
  "className": "icon-empty",
  "classes": ["icon-line", "icon-empty"],
  "bidirectional": false,
  "deprecated": false
};
const IconEmptySolid = exports.IconEmptySolid = {
  "variant": "Solid",
  "glyphName": "empty",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA71",
  "className": "icon-empty",
  "classes": ["icon-solid", "icon-empty"],
  "bidirectional": false,
  "deprecated": false
};
const IconEndLine = exports.IconEndLine = {
  "variant": "Line",
  "glyphName": "end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA72",
  "className": "icon-end",
  "classes": ["icon-line", "icon-end"],
  "bidirectional": false,
  "deprecated": false
};
const IconEndSolid = exports.IconEndSolid = {
  "variant": "Solid",
  "glyphName": "end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA72",
  "className": "icon-end",
  "classes": ["icon-solid", "icon-end"],
  "bidirectional": false,
  "deprecated": false
};
const IconEportfolioLine = exports.IconEportfolioLine = {
  "variant": "Line",
  "glyphName": "eportfolio",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA73",
  "className": "icon-eportfolio",
  "classes": ["icon-line", "icon-eportfolio"],
  "bidirectional": false,
  "deprecated": false
};
const IconEportfolioSolid = exports.IconEportfolioSolid = {
  "variant": "Solid",
  "glyphName": "eportfolio",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA73",
  "className": "icon-eportfolio",
  "classes": ["icon-solid", "icon-eportfolio"],
  "bidirectional": false,
  "deprecated": false
};
const IconEquationLine = exports.IconEquationLine = {
  "variant": "Line",
  "glyphName": "equation",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA74",
  "className": "icon-equation",
  "classes": ["icon-line", "icon-equation"],
  "bidirectional": false,
  "deprecated": false
};
const IconEquationSolid = exports.IconEquationSolid = {
  "variant": "Solid",
  "glyphName": "equation",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA74",
  "className": "icon-equation",
  "classes": ["icon-solid", "icon-equation"],
  "bidirectional": false,
  "deprecated": false
};
const IconEquellaLine = exports.IconEquellaLine = {
  "variant": "Line",
  "glyphName": "equella",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA75",
  "className": "icon-equella",
  "classes": ["icon-line", "icon-equella"],
  "bidirectional": false,
  "deprecated": false
};
const IconEquellaSolid = exports.IconEquellaSolid = {
  "variant": "Solid",
  "glyphName": "equella",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA75",
  "className": "icon-equella",
  "classes": ["icon-solid", "icon-equella"],
  "bidirectional": false,
  "deprecated": false
};
const IconEssayLine = exports.IconEssayLine = {
  "variant": "Line",
  "glyphName": "essay",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA76",
  "className": "icon-essay",
  "classes": ["icon-line", "icon-essay"],
  "bidirectional": true,
  "deprecated": false
};
const IconEssaySolid = exports.IconEssaySolid = {
  "variant": "Solid",
  "glyphName": "essay",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA76",
  "className": "icon-essay",
  "classes": ["icon-solid", "icon-essay"],
  "bidirectional": true,
  "deprecated": false
};
const IconExitFullScreenLine = exports.IconExitFullScreenLine = {
  "variant": "Line",
  "glyphName": "exit-full-screen",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA77",
  "className": "icon-exit-full-screen",
  "classes": ["icon-line", "icon-exit-full-screen"],
  "bidirectional": false,
  "deprecated": false
};
const IconExitFullScreenSolid = exports.IconExitFullScreenSolid = {
  "variant": "Solid",
  "glyphName": "exit-full-screen",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA77",
  "className": "icon-exit-full-screen",
  "classes": ["icon-solid", "icon-exit-full-screen"],
  "bidirectional": false,
  "deprecated": false
};
const IconExpandItemsLine = exports.IconExpandItemsLine = {
  "variant": "Line",
  "glyphName": "expand-items",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA78",
  "className": "icon-expand-items",
  "classes": ["icon-line", "icon-expand-items"],
  "bidirectional": false,
  "deprecated": false
};
const IconExpandItemsSolid = exports.IconExpandItemsSolid = {
  "variant": "Solid",
  "glyphName": "expand-items",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA78",
  "className": "icon-expand-items",
  "classes": ["icon-solid", "icon-expand-items"],
  "bidirectional": false,
  "deprecated": false
};
const IconExpandLeftLine = exports.IconExpandLeftLine = {
  "variant": "Line",
  "glyphName": "expand-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA79",
  "className": "icon-expand-left",
  "classes": ["icon-line", "icon-expand-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconExpandLeftSolid = exports.IconExpandLeftSolid = {
  "variant": "Solid",
  "glyphName": "expand-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA79",
  "className": "icon-expand-left",
  "classes": ["icon-solid", "icon-expand-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconExpandStartLine = exports.IconExpandStartLine = {
  "variant": "Line",
  "glyphName": "expand-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA7A",
  "className": "icon-expand-start",
  "classes": ["icon-line", "icon-expand-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconExpandStartSolid = exports.IconExpandStartSolid = {
  "variant": "Solid",
  "glyphName": "expand-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA7A",
  "className": "icon-expand-start",
  "classes": ["icon-solid", "icon-expand-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconExpandLine = exports.IconExpandLine = {
  "variant": "Line",
  "glyphName": "expand",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA7B",
  "className": "icon-expand",
  "classes": ["icon-line", "icon-expand"],
  "bidirectional": false,
  "deprecated": false
};
const IconExpandSolid = exports.IconExpandSolid = {
  "variant": "Solid",
  "glyphName": "expand",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA7B",
  "className": "icon-expand",
  "classes": ["icon-solid", "icon-expand"],
  "bidirectional": false,
  "deprecated": false
};
const IconExportContentLine = exports.IconExportContentLine = {
  "variant": "Line",
  "glyphName": "export-content",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA7C",
  "className": "icon-export-content",
  "classes": ["icon-line", "icon-export-content"],
  "bidirectional": true,
  "deprecated": false
};
const IconExportContentSolid = exports.IconExportContentSolid = {
  "variant": "Solid",
  "glyphName": "export-content",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA7C",
  "className": "icon-export-content",
  "classes": ["icon-solid", "icon-export-content"],
  "bidirectional": true,
  "deprecated": false
};
const IconExportLine = exports.IconExportLine = {
  "variant": "Line",
  "glyphName": "export",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA7D",
  "className": "icon-export",
  "classes": ["icon-line", "icon-export"],
  "bidirectional": true,
  "deprecated": false
};
const IconExportSolid = exports.IconExportSolid = {
  "variant": "Solid",
  "glyphName": "export",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA7D",
  "className": "icon-export",
  "classes": ["icon-solid", "icon-export"],
  "bidirectional": true,
  "deprecated": false
};
const IconExternalLinkLine = exports.IconExternalLinkLine = {
  "variant": "Line",
  "glyphName": "external-link",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA7E",
  "className": "icon-external-link",
  "classes": ["icon-line", "icon-external-link"],
  "bidirectional": true,
  "deprecated": false
};
const IconExternalLinkSolid = exports.IconExternalLinkSolid = {
  "variant": "Solid",
  "glyphName": "external-link",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA7E",
  "className": "icon-external-link",
  "classes": ["icon-solid", "icon-external-link"],
  "bidirectional": true,
  "deprecated": false
};
const IconEyeLine = exports.IconEyeLine = {
  "variant": "Line",
  "glyphName": "eye",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA7F",
  "className": "icon-eye",
  "classes": ["icon-line", "icon-eye"],
  "bidirectional": false,
  "deprecated": false
};
const IconEyeSolid = exports.IconEyeSolid = {
  "variant": "Solid",
  "glyphName": "eye",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA7F",
  "className": "icon-eye",
  "classes": ["icon-solid", "icon-eye"],
  "bidirectional": false,
  "deprecated": false
};
const IconFacebookBoxedLine = exports.IconFacebookBoxedLine = {
  "variant": "Line",
  "glyphName": "facebook-boxed",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA80",
  "className": "icon-facebook-boxed",
  "classes": ["icon-line", "icon-facebook-boxed"],
  "bidirectional": false,
  "deprecated": false
};
const IconFacebookBoxedSolid = exports.IconFacebookBoxedSolid = {
  "variant": "Solid",
  "glyphName": "facebook-boxed",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA80",
  "className": "icon-facebook-boxed",
  "classes": ["icon-solid", "icon-facebook-boxed"],
  "bidirectional": false,
  "deprecated": false
};
const IconFacebookLine = exports.IconFacebookLine = {
  "variant": "Line",
  "glyphName": "facebook",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA81",
  "className": "icon-facebook",
  "classes": ["icon-line", "icon-facebook"],
  "bidirectional": false,
  "deprecated": false
};
const IconFacebookSolid = exports.IconFacebookSolid = {
  "variant": "Solid",
  "glyphName": "facebook",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA81",
  "className": "icon-facebook",
  "classes": ["icon-solid", "icon-facebook"],
  "bidirectional": false,
  "deprecated": false
};
const IconFastForwardLine = exports.IconFastForwardLine = {
  "variant": "Line",
  "glyphName": "fast-forward",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA82",
  "className": "icon-fast-forward",
  "classes": ["icon-line", "icon-fast-forward"],
  "bidirectional": false,
  "deprecated": false
};
const IconFastForwardSolid = exports.IconFastForwardSolid = {
  "variant": "Solid",
  "glyphName": "fast-forward",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA82",
  "className": "icon-fast-forward",
  "classes": ["icon-solid", "icon-fast-forward"],
  "bidirectional": false,
  "deprecated": false
};
const IconFeedbackLine = exports.IconFeedbackLine = {
  "variant": "Line",
  "glyphName": "feedback",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA83",
  "className": "icon-feedback",
  "classes": ["icon-line", "icon-feedback"],
  "bidirectional": true,
  "deprecated": false
};
const IconFeedbackSolid = exports.IconFeedbackSolid = {
  "variant": "Solid",
  "glyphName": "feedback",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA83",
  "className": "icon-feedback",
  "classes": ["icon-solid", "icon-feedback"],
  "bidirectional": true,
  "deprecated": false
};
const IconFileLockedLine = exports.IconFileLockedLine = {
  "variant": "Line",
  "glyphName": "file-locked",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA84",
  "className": "icon-file-locked",
  "classes": ["icon-line", "icon-file-locked"],
  "bidirectional": false,
  "deprecated": false
};
const IconFileLockedSolid = exports.IconFileLockedSolid = {
  "variant": "Solid",
  "glyphName": "file-locked",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA84",
  "className": "icon-file-locked",
  "classes": ["icon-solid", "icon-file-locked"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesCopyrightLine = exports.IconFilesCopyrightLine = {
  "variant": "Line",
  "glyphName": "files-copyright",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA85",
  "className": "icon-files-copyright",
  "classes": ["icon-line", "icon-files-copyright"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesCopyrightSolid = exports.IconFilesCopyrightSolid = {
  "variant": "Solid",
  "glyphName": "files-copyright",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA85",
  "className": "icon-files-copyright",
  "classes": ["icon-solid", "icon-files-copyright"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesCreativeCommonsLine = exports.IconFilesCreativeCommonsLine = {
  "variant": "Line",
  "glyphName": "files-creative-commons",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA86",
  "className": "icon-files-creative-commons",
  "classes": ["icon-line", "icon-files-creative-commons"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesCreativeCommonsSolid = exports.IconFilesCreativeCommonsSolid = {
  "variant": "Solid",
  "glyphName": "files-creative-commons",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA86",
  "className": "icon-files-creative-commons",
  "classes": ["icon-solid", "icon-files-creative-commons"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesFairUseLine = exports.IconFilesFairUseLine = {
  "variant": "Line",
  "glyphName": "files-fair-use",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA87",
  "className": "icon-files-fair-use",
  "classes": ["icon-line", "icon-files-fair-use"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesFairUseSolid = exports.IconFilesFairUseSolid = {
  "variant": "Solid",
  "glyphName": "files-fair-use",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA87",
  "className": "icon-files-fair-use",
  "classes": ["icon-solid", "icon-files-fair-use"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesObtainedPermissionLine = exports.IconFilesObtainedPermissionLine = {
  "variant": "Line",
  "glyphName": "files-obtained-permission",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA88",
  "className": "icon-files-obtained-permission",
  "classes": ["icon-line", "icon-files-obtained-permission"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesObtainedPermissionSolid = exports.IconFilesObtainedPermissionSolid = {
  "variant": "Solid",
  "glyphName": "files-obtained-permission",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA88",
  "className": "icon-files-obtained-permission",
  "classes": ["icon-solid", "icon-files-obtained-permission"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesPublicDomainLine = exports.IconFilesPublicDomainLine = {
  "variant": "Line",
  "glyphName": "files-public-domain",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA89",
  "className": "icon-files-public-domain",
  "classes": ["icon-line", "icon-files-public-domain"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilesPublicDomainSolid = exports.IconFilesPublicDomainSolid = {
  "variant": "Solid",
  "glyphName": "files-public-domain",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA89",
  "className": "icon-files-public-domain",
  "classes": ["icon-solid", "icon-files-public-domain"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilmstripLine = exports.IconFilmstripLine = {
  "variant": "Line",
  "glyphName": "filmstrip",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA8A",
  "className": "icon-filmstrip",
  "classes": ["icon-line", "icon-filmstrip"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilmstripSolid = exports.IconFilmstripSolid = {
  "variant": "Solid",
  "glyphName": "filmstrip",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA8A",
  "className": "icon-filmstrip",
  "classes": ["icon-solid", "icon-filmstrip"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilterLine = exports.IconFilterLine = {
  "variant": "Line",
  "glyphName": "filter",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA8B",
  "className": "icon-filter",
  "classes": ["icon-line", "icon-filter"],
  "bidirectional": false,
  "deprecated": false
};
const IconFilterSolid = exports.IconFilterSolid = {
  "variant": "Solid",
  "glyphName": "filter",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA8B",
  "className": "icon-filter",
  "classes": ["icon-solid", "icon-filter"],
  "bidirectional": false,
  "deprecated": false
};
const IconFlagLine = exports.IconFlagLine = {
  "variant": "Line",
  "glyphName": "flag",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA8C",
  "className": "icon-flag",
  "classes": ["icon-line", "icon-flag"],
  "bidirectional": false,
  "deprecated": false
};
const IconFlagSolid = exports.IconFlagSolid = {
  "variant": "Solid",
  "glyphName": "flag",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA8C",
  "className": "icon-flag",
  "classes": ["icon-solid", "icon-flag"],
  "bidirectional": false,
  "deprecated": false
};
const IconFolderLockedLine = exports.IconFolderLockedLine = {
  "variant": "Line",
  "glyphName": "folder-locked",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA8D",
  "className": "icon-folder-locked",
  "classes": ["icon-line", "icon-folder-locked"],
  "bidirectional": true,
  "deprecated": false
};
const IconFolderLockedSolid = exports.IconFolderLockedSolid = {
  "variant": "Solid",
  "glyphName": "folder-locked",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA8D",
  "className": "icon-folder-locked",
  "classes": ["icon-solid", "icon-folder-locked"],
  "bidirectional": true,
  "deprecated": false
};
const IconFolderLine = exports.IconFolderLine = {
  "variant": "Line",
  "glyphName": "folder",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA8E",
  "className": "icon-folder",
  "classes": ["icon-line", "icon-folder"],
  "bidirectional": true,
  "deprecated": false
};
const IconFolderSolid = exports.IconFolderSolid = {
  "variant": "Solid",
  "glyphName": "folder",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA8E",
  "className": "icon-folder",
  "classes": ["icon-solid", "icon-folder"],
  "bidirectional": true,
  "deprecated": false
};
const IconForwardLine = exports.IconForwardLine = {
  "variant": "Line",
  "glyphName": "forward",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA8F",
  "className": "icon-forward",
  "classes": ["icon-line", "icon-forward"],
  "bidirectional": true,
  "deprecated": false
};
const IconForwardSolid = exports.IconForwardSolid = {
  "variant": "Solid",
  "glyphName": "forward",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA8F",
  "className": "icon-forward",
  "classes": ["icon-solid", "icon-forward"],
  "bidirectional": true,
  "deprecated": false
};
const IconFullScreenLine = exports.IconFullScreenLine = {
  "variant": "Line",
  "glyphName": "full-screen",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA90",
  "className": "icon-full-screen",
  "classes": ["icon-line", "icon-full-screen"],
  "bidirectional": false,
  "deprecated": false
};
const IconFullScreenSolid = exports.IconFullScreenSolid = {
  "variant": "Solid",
  "glyphName": "full-screen",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA90",
  "className": "icon-full-screen",
  "classes": ["icon-solid", "icon-full-screen"],
  "bidirectional": false,
  "deprecated": false
};
const IconGithubLine = exports.IconGithubLine = {
  "variant": "Line",
  "glyphName": "github",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA91",
  "className": "icon-github",
  "classes": ["icon-line", "icon-github"],
  "bidirectional": false,
  "deprecated": false
};
const IconGithubSolid = exports.IconGithubSolid = {
  "variant": "Solid",
  "glyphName": "github",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA91",
  "className": "icon-github",
  "classes": ["icon-solid", "icon-github"],
  "bidirectional": false,
  "deprecated": false
};
const IconGiveAwardLine = exports.IconGiveAwardLine = {
  "variant": "Line",
  "glyphName": "give-award",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA92",
  "className": "icon-give-award",
  "classes": ["icon-line", "icon-give-award"],
  "bidirectional": false,
  "deprecated": false
};
const IconGiveAwardSolid = exports.IconGiveAwardSolid = {
  "variant": "Solid",
  "glyphName": "give-award",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA92",
  "className": "icon-give-award",
  "classes": ["icon-solid", "icon-give-award"],
  "bidirectional": false,
  "deprecated": false
};
const IconGradebookExportLine = exports.IconGradebookExportLine = {
  "variant": "Line",
  "glyphName": "gradebook-export",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA93",
  "className": "icon-gradebook-export",
  "classes": ["icon-line", "icon-gradebook-export"],
  "bidirectional": true,
  "deprecated": false
};
const IconGradebookExportSolid = exports.IconGradebookExportSolid = {
  "variant": "Solid",
  "glyphName": "gradebook-export",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA93",
  "className": "icon-gradebook-export",
  "classes": ["icon-solid", "icon-gradebook-export"],
  "bidirectional": true,
  "deprecated": false
};
const IconGradebookImportLine = exports.IconGradebookImportLine = {
  "variant": "Line",
  "glyphName": "gradebook-import",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA94",
  "className": "icon-gradebook-import",
  "classes": ["icon-line", "icon-gradebook-import"],
  "bidirectional": true,
  "deprecated": false
};
const IconGradebookImportSolid = exports.IconGradebookImportSolid = {
  "variant": "Solid",
  "glyphName": "gradebook-import",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA94",
  "className": "icon-gradebook-import",
  "classes": ["icon-solid", "icon-gradebook-import"],
  "bidirectional": true,
  "deprecated": false
};
const IconGradebookLine = exports.IconGradebookLine = {
  "variant": "Line",
  "glyphName": "gradebook",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA95",
  "className": "icon-gradebook",
  "classes": ["icon-line", "icon-gradebook"],
  "bidirectional": false,
  "deprecated": false
};
const IconGradebookSolid = exports.IconGradebookSolid = {
  "variant": "Solid",
  "glyphName": "gradebook",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA95",
  "className": "icon-gradebook",
  "classes": ["icon-solid", "icon-gradebook"],
  "bidirectional": false,
  "deprecated": false
};
const IconGridViewLine = exports.IconGridViewLine = {
  "variant": "Line",
  "glyphName": "grid-view",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA96",
  "className": "icon-grid-view",
  "classes": ["icon-line", "icon-grid-view"],
  "bidirectional": false,
  "deprecated": false
};
const IconGridViewSolid = exports.IconGridViewSolid = {
  "variant": "Solid",
  "glyphName": "grid-view",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA96",
  "className": "icon-grid-view",
  "classes": ["icon-solid", "icon-grid-view"],
  "bidirectional": false,
  "deprecated": false
};
const IconGroupDarkNewLine = exports.IconGroupDarkNewLine = {
  "variant": "Line",
  "glyphName": "group-dark-new",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA97",
  "className": "icon-group-dark-new",
  "classes": ["icon-line", "icon-group-dark-new"],
  "bidirectional": false,
  "deprecated": false
};
const IconGroupDarkNewSolid = exports.IconGroupDarkNewSolid = {
  "variant": "Solid",
  "glyphName": "group-dark-new",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA97",
  "className": "icon-group-dark-new",
  "classes": ["icon-solid", "icon-group-dark-new"],
  "bidirectional": false,
  "deprecated": false
};
const IconGroupNewLine = exports.IconGroupNewLine = {
  "variant": "Line",
  "glyphName": "group-new",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA98",
  "className": "icon-group-new",
  "classes": ["icon-line", "icon-group-new"],
  "bidirectional": false,
  "deprecated": false
};
const IconGroupNewSolid = exports.IconGroupNewSolid = {
  "variant": "Solid",
  "glyphName": "group-new",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA98",
  "className": "icon-group-new",
  "classes": ["icon-solid", "icon-group-new"],
  "bidirectional": false,
  "deprecated": false
};
const IconGroupLine = exports.IconGroupLine = {
  "variant": "Line",
  "glyphName": "group",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA99",
  "className": "icon-group",
  "classes": ["icon-line", "icon-group"],
  "bidirectional": false,
  "deprecated": false
};
const IconGroupSolid = exports.IconGroupSolid = {
  "variant": "Solid",
  "glyphName": "group",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA99",
  "className": "icon-group",
  "classes": ["icon-solid", "icon-group"],
  "bidirectional": false,
  "deprecated": false
};
const IconHamburgerLine = exports.IconHamburgerLine = {
  "variant": "Line",
  "glyphName": "hamburger",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA9A",
  "className": "icon-hamburger",
  "classes": ["icon-line", "icon-hamburger"],
  "bidirectional": false,
  "deprecated": false
};
const IconHamburgerSolid = exports.IconHamburgerSolid = {
  "variant": "Solid",
  "glyphName": "hamburger",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA9A",
  "className": "icon-hamburger",
  "classes": ["icon-solid", "icon-hamburger"],
  "bidirectional": false,
  "deprecated": false
};
const IconHeaderLine = exports.IconHeaderLine = {
  "variant": "Line",
  "glyphName": "header",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA9B",
  "className": "icon-header",
  "classes": ["icon-line", "icon-header"],
  "bidirectional": false,
  "deprecated": false
};
const IconHeaderSolid = exports.IconHeaderSolid = {
  "variant": "Solid",
  "glyphName": "header",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA9B",
  "className": "icon-header",
  "classes": ["icon-solid", "icon-header"],
  "bidirectional": false,
  "deprecated": false
};
const IconHeartLine = exports.IconHeartLine = {
  "variant": "Line",
  "glyphName": "heart",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA9C",
  "className": "icon-heart",
  "classes": ["icon-line", "icon-heart"],
  "bidirectional": false,
  "deprecated": false
};
const IconHeartSolid = exports.IconHeartSolid = {
  "variant": "Solid",
  "glyphName": "heart",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA9C",
  "className": "icon-heart",
  "classes": ["icon-solid", "icon-heart"],
  "bidirectional": false,
  "deprecated": false
};
const IconHighlighterLine = exports.IconHighlighterLine = {
  "variant": "Line",
  "glyphName": "highlighter",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA9D",
  "className": "icon-highlighter",
  "classes": ["icon-line", "icon-highlighter"],
  "bidirectional": true,
  "deprecated": false
};
const IconHighlighterSolid = exports.IconHighlighterSolid = {
  "variant": "Solid",
  "glyphName": "highlighter",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA9D",
  "className": "icon-highlighter",
  "classes": ["icon-solid", "icon-highlighter"],
  "bidirectional": true,
  "deprecated": false
};
const IconHomeLine = exports.IconHomeLine = {
  "variant": "Line",
  "glyphName": "home",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA9E",
  "className": "icon-home",
  "classes": ["icon-line", "icon-home"],
  "bidirectional": false,
  "deprecated": false
};
const IconHomeSolid = exports.IconHomeSolid = {
  "variant": "Solid",
  "glyphName": "home",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA9E",
  "className": "icon-home",
  "classes": ["icon-solid", "icon-home"],
  "bidirectional": false,
  "deprecated": false
};
const IconHourGlassLine = exports.IconHourGlassLine = {
  "variant": "Line",
  "glyphName": "hour-glass",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EA9F",
  "className": "icon-hour-glass",
  "classes": ["icon-line", "icon-hour-glass"],
  "bidirectional": false,
  "deprecated": false
};
const IconHourGlassSolid = exports.IconHourGlassSolid = {
  "variant": "Solid",
  "glyphName": "hour-glass",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EA9F",
  "className": "icon-hour-glass",
  "classes": ["icon-solid", "icon-hour-glass"],
  "bidirectional": false,
  "deprecated": false
};
const IconImageLine = exports.IconImageLine = {
  "variant": "Line",
  "glyphName": "image",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA0",
  "className": "icon-image",
  "classes": ["icon-line", "icon-image"],
  "bidirectional": false,
  "deprecated": false
};
const IconImageSolid = exports.IconImageSolid = {
  "variant": "Solid",
  "glyphName": "image",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA0",
  "className": "icon-image",
  "classes": ["icon-solid", "icon-image"],
  "bidirectional": false,
  "deprecated": false
};
const IconImmersiveReaderLine = exports.IconImmersiveReaderLine = {
  "variant": "Line",
  "glyphName": "immersive-reader",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA1",
  "className": "icon-immersive-reader",
  "classes": ["icon-line", "icon-immersive-reader"],
  "bidirectional": false,
  "deprecated": false
};
const IconImmersiveReaderSolid = exports.IconImmersiveReaderSolid = {
  "variant": "Solid",
  "glyphName": "immersive-reader",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA1",
  "className": "icon-immersive-reader",
  "classes": ["icon-solid", "icon-immersive-reader"],
  "bidirectional": false,
  "deprecated": false
};
const IconImpactLogoLine = exports.IconImpactLogoLine = {
  "variant": "Line",
  "glyphName": "impact-logo",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA2",
  "className": "icon-impact-logo",
  "classes": ["icon-line", "icon-impact-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconImpactLogoSolid = exports.IconImpactLogoSolid = {
  "variant": "Solid",
  "glyphName": "impact-logo",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA2",
  "className": "icon-impact-logo",
  "classes": ["icon-solid", "icon-impact-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconImportContentLine = exports.IconImportContentLine = {
  "variant": "Line",
  "glyphName": "import-content",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA3",
  "className": "icon-import-content",
  "classes": ["icon-line", "icon-import-content"],
  "bidirectional": true,
  "deprecated": false
};
const IconImportContentSolid = exports.IconImportContentSolid = {
  "variant": "Solid",
  "glyphName": "import-content",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA3",
  "className": "icon-import-content",
  "classes": ["icon-solid", "icon-import-content"],
  "bidirectional": true,
  "deprecated": false
};
const IconImportLine = exports.IconImportLine = {
  "variant": "Line",
  "glyphName": "import",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA4",
  "className": "icon-import",
  "classes": ["icon-line", "icon-import"],
  "bidirectional": true,
  "deprecated": false
};
const IconImportSolid = exports.IconImportSolid = {
  "variant": "Solid",
  "glyphName": "import",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA4",
  "className": "icon-import",
  "classes": ["icon-solid", "icon-import"],
  "bidirectional": true,
  "deprecated": false
};
const IconImportantDatesLine = exports.IconImportantDatesLine = {
  "variant": "Line",
  "glyphName": "important-dates",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA5",
  "className": "icon-important-dates",
  "classes": ["icon-line", "icon-important-dates"],
  "bidirectional": false,
  "deprecated": false
};
const IconImportantDatesSolid = exports.IconImportantDatesSolid = {
  "variant": "Solid",
  "glyphName": "important-dates",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA5",
  "className": "icon-important-dates",
  "classes": ["icon-solid", "icon-important-dates"],
  "bidirectional": false,
  "deprecated": false
};
const IconInboxLine = exports.IconInboxLine = {
  "variant": "Line",
  "glyphName": "inbox",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA6",
  "className": "icon-inbox",
  "classes": ["icon-line", "icon-inbox"],
  "bidirectional": false,
  "deprecated": false
};
const IconInboxSolid = exports.IconInboxSolid = {
  "variant": "Solid",
  "glyphName": "inbox",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA6",
  "className": "icon-inbox",
  "classes": ["icon-solid", "icon-inbox"],
  "bidirectional": false,
  "deprecated": false
};
const IconIndent2Line = exports.IconIndent2Line = {
  "variant": "Line",
  "glyphName": "indent-2",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA7",
  "className": "icon-indent-2",
  "classes": ["icon-line", "icon-indent-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconIndent2Solid = exports.IconIndent2Solid = {
  "variant": "Solid",
  "glyphName": "indent-2",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA7",
  "className": "icon-indent-2",
  "classes": ["icon-solid", "icon-indent-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconIndentLine = exports.IconIndentLine = {
  "variant": "Line",
  "glyphName": "indent",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA8",
  "className": "icon-indent",
  "classes": ["icon-line", "icon-indent"],
  "bidirectional": true,
  "deprecated": false
};
const IconIndentSolid = exports.IconIndentSolid = {
  "variant": "Solid",
  "glyphName": "indent",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA8",
  "className": "icon-indent",
  "classes": ["icon-solid", "icon-indent"],
  "bidirectional": true,
  "deprecated": false
};
const IconInfoBorderlessLine = exports.IconInfoBorderlessLine = {
  "variant": "Line",
  "glyphName": "info-borderless",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAA9",
  "className": "icon-info-borderless",
  "classes": ["icon-line", "icon-info-borderless"],
  "bidirectional": false,
  "deprecated": false
};
const IconInfoBorderlessSolid = exports.IconInfoBorderlessSolid = {
  "variant": "Solid",
  "glyphName": "info-borderless",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAA9",
  "className": "icon-info-borderless",
  "classes": ["icon-solid", "icon-info-borderless"],
  "bidirectional": false,
  "deprecated": false
};
const IconInfoLine = exports.IconInfoLine = {
  "variant": "Line",
  "glyphName": "info",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAAA",
  "className": "icon-info",
  "classes": ["icon-line", "icon-info"],
  "bidirectional": false,
  "deprecated": false
};
const IconInfoSolid = exports.IconInfoSolid = {
  "variant": "Solid",
  "glyphName": "info",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAAA",
  "className": "icon-info",
  "classes": ["icon-solid", "icon-info"],
  "bidirectional": false,
  "deprecated": false
};
const IconInstructureLogoLine = exports.IconInstructureLogoLine = {
  "variant": "Line",
  "glyphName": "instructure-logo",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAAB",
  "className": "icon-instructure-logo",
  "classes": ["icon-line", "icon-instructure-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconInstructureLogoSolid = exports.IconInstructureLogoSolid = {
  "variant": "Solid",
  "glyphName": "instructure-logo",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAAB",
  "className": "icon-instructure-logo",
  "classes": ["icon-solid", "icon-instructure-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconInstructureLine = exports.IconInstructureLine = {
  "variant": "Line",
  "glyphName": "instructure",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAAC",
  "className": "icon-instructure",
  "classes": ["icon-line", "icon-instructure"],
  "bidirectional": false,
  "deprecated": true
};
const IconInstructureSolid = exports.IconInstructureSolid = {
  "variant": "Solid",
  "glyphName": "instructure",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAAC",
  "className": "icon-instructure",
  "classes": ["icon-solid", "icon-instructure"],
  "bidirectional": false,
  "deprecated": true
};
const IconIntegrationsLine = exports.IconIntegrationsLine = {
  "variant": "Line",
  "glyphName": "integrations",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAAD",
  "className": "icon-integrations",
  "classes": ["icon-line", "icon-integrations"],
  "bidirectional": false,
  "deprecated": false
};
const IconIntegrationsSolid = exports.IconIntegrationsSolid = {
  "variant": "Solid",
  "glyphName": "integrations",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAAD",
  "className": "icon-integrations",
  "classes": ["icon-solid", "icon-integrations"],
  "bidirectional": false,
  "deprecated": false
};
const IconInvitationLine = exports.IconInvitationLine = {
  "variant": "Line",
  "glyphName": "invitation",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAAE",
  "className": "icon-invitation",
  "classes": ["icon-line", "icon-invitation"],
  "bidirectional": false,
  "deprecated": false
};
const IconInvitationSolid = exports.IconInvitationSolid = {
  "variant": "Solid",
  "glyphName": "invitation",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAAE",
  "className": "icon-invitation",
  "classes": ["icon-solid", "icon-invitation"],
  "bidirectional": false,
  "deprecated": false
};
const IconItalicLine = exports.IconItalicLine = {
  "variant": "Line",
  "glyphName": "italic",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAAF",
  "className": "icon-italic",
  "classes": ["icon-line", "icon-italic"],
  "bidirectional": false,
  "deprecated": false
};
const IconItalicSolid = exports.IconItalicSolid = {
  "variant": "Solid",
  "glyphName": "italic",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAAF",
  "className": "icon-italic",
  "classes": ["icon-solid", "icon-italic"],
  "bidirectional": false,
  "deprecated": false
};
const IconKeyboardShortcutsLine = exports.IconKeyboardShortcutsLine = {
  "variant": "Line",
  "glyphName": "keyboard-shortcuts",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB0",
  "className": "icon-keyboard-shortcuts",
  "classes": ["icon-line", "icon-keyboard-shortcuts"],
  "bidirectional": false,
  "deprecated": false
};
const IconKeyboardShortcutsSolid = exports.IconKeyboardShortcutsSolid = {
  "variant": "Solid",
  "glyphName": "keyboard-shortcuts",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB0",
  "className": "icon-keyboard-shortcuts",
  "classes": ["icon-solid", "icon-keyboard-shortcuts"],
  "bidirectional": false,
  "deprecated": false
};
const IconLaunchLine = exports.IconLaunchLine = {
  "variant": "Line",
  "glyphName": "launch",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB1",
  "className": "icon-launch",
  "classes": ["icon-line", "icon-launch"],
  "bidirectional": false,
  "deprecated": false
};
const IconLaunchSolid = exports.IconLaunchSolid = {
  "variant": "Solid",
  "glyphName": "launch",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB1",
  "className": "icon-launch",
  "classes": ["icon-solid", "icon-launch"],
  "bidirectional": false,
  "deprecated": false
};
const IconLearnplatformLine = exports.IconLearnplatformLine = {
  "variant": "Line",
  "glyphName": "learnplatform",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB2",
  "className": "icon-learnplatform",
  "classes": ["icon-line", "icon-learnplatform"],
  "bidirectional": false,
  "deprecated": false
};
const IconLearnplatformSolid = exports.IconLearnplatformSolid = {
  "variant": "Solid",
  "glyphName": "learnplatform",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB2",
  "className": "icon-learnplatform",
  "classes": ["icon-solid", "icon-learnplatform"],
  "bidirectional": false,
  "deprecated": false
};
const IconLifePreserverLine = exports.IconLifePreserverLine = {
  "variant": "Line",
  "glyphName": "life-preserver",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB3",
  "className": "icon-life-preserver",
  "classes": ["icon-line", "icon-life-preserver"],
  "bidirectional": false,
  "deprecated": false
};
const IconLifePreserverSolid = exports.IconLifePreserverSolid = {
  "variant": "Solid",
  "glyphName": "life-preserver",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB3",
  "className": "icon-life-preserver",
  "classes": ["icon-solid", "icon-life-preserver"],
  "bidirectional": false,
  "deprecated": false
};
const IconLikeLine = exports.IconLikeLine = {
  "variant": "Line",
  "glyphName": "like",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB4",
  "className": "icon-like",
  "classes": ["icon-line", "icon-like"],
  "bidirectional": false,
  "deprecated": false
};
const IconLikeSolid = exports.IconLikeSolid = {
  "variant": "Solid",
  "glyphName": "like",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB4",
  "className": "icon-like",
  "classes": ["icon-solid", "icon-like"],
  "bidirectional": false,
  "deprecated": false
};
const IconLineReaderLine = exports.IconLineReaderLine = {
  "variant": "Line",
  "glyphName": "line-reader",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB5",
  "className": "icon-line-reader",
  "classes": ["icon-line", "icon-line-reader"],
  "bidirectional": false,
  "deprecated": false
};
const IconLineReaderSolid = exports.IconLineReaderSolid = {
  "variant": "Solid",
  "glyphName": "line-reader",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB5",
  "className": "icon-line-reader",
  "classes": ["icon-solid", "icon-line-reader"],
  "bidirectional": false,
  "deprecated": false
};
const IconLinkLine = exports.IconLinkLine = {
  "variant": "Line",
  "glyphName": "link",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB6",
  "className": "icon-link",
  "classes": ["icon-line", "icon-link"],
  "bidirectional": false,
  "deprecated": false
};
const IconLinkSolid = exports.IconLinkSolid = {
  "variant": "Solid",
  "glyphName": "link",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB6",
  "className": "icon-link",
  "classes": ["icon-solid", "icon-link"],
  "bidirectional": false,
  "deprecated": false
};
const IconLinkedinLine = exports.IconLinkedinLine = {
  "variant": "Line",
  "glyphName": "linkedin",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB7",
  "className": "icon-linkedin",
  "classes": ["icon-line", "icon-linkedin"],
  "bidirectional": false,
  "deprecated": false
};
const IconLinkedinSolid = exports.IconLinkedinSolid = {
  "variant": "Solid",
  "glyphName": "linkedin",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB7",
  "className": "icon-linkedin",
  "classes": ["icon-solid", "icon-linkedin"],
  "bidirectional": false,
  "deprecated": false
};
const IconListViewLine = exports.IconListViewLine = {
  "variant": "Line",
  "glyphName": "list-view",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB8",
  "className": "icon-list-view",
  "classes": ["icon-line", "icon-list-view"],
  "bidirectional": false,
  "deprecated": false
};
const IconListViewSolid = exports.IconListViewSolid = {
  "variant": "Solid",
  "glyphName": "list-view",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB8",
  "className": "icon-list-view",
  "classes": ["icon-solid", "icon-list-view"],
  "bidirectional": false,
  "deprecated": false
};
const IconLockLine = exports.IconLockLine = {
  "variant": "Line",
  "glyphName": "lock",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAB9",
  "className": "icon-lock",
  "classes": ["icon-line", "icon-lock"],
  "bidirectional": false,
  "deprecated": false
};
const IconLockSolid = exports.IconLockSolid = {
  "variant": "Solid",
  "glyphName": "lock",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAB9",
  "className": "icon-lock",
  "classes": ["icon-solid", "icon-lock"],
  "bidirectional": false,
  "deprecated": false
};
const IconLtiLine = exports.IconLtiLine = {
  "variant": "Line",
  "glyphName": "lti",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EABA",
  "className": "icon-lti",
  "classes": ["icon-line", "icon-lti"],
  "bidirectional": false,
  "deprecated": false
};
const IconLtiSolid = exports.IconLtiSolid = {
  "variant": "Solid",
  "glyphName": "lti",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EABA",
  "className": "icon-lti",
  "classes": ["icon-solid", "icon-lti"],
  "bidirectional": false,
  "deprecated": false
};
const IconMarkAsReadLine = exports.IconMarkAsReadLine = {
  "variant": "Line",
  "glyphName": "mark-as-read",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EABB",
  "className": "icon-mark-as-read",
  "classes": ["icon-line", "icon-mark-as-read"],
  "bidirectional": false,
  "deprecated": false
};
const IconMarkAsReadSolid = exports.IconMarkAsReadSolid = {
  "variant": "Solid",
  "glyphName": "mark-as-read",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EABB",
  "className": "icon-mark-as-read",
  "classes": ["icon-solid", "icon-mark-as-read"],
  "bidirectional": false,
  "deprecated": false
};
const IconMarkerLine = exports.IconMarkerLine = {
  "variant": "Line",
  "glyphName": "marker",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EABC",
  "className": "icon-marker",
  "classes": ["icon-line", "icon-marker"],
  "bidirectional": false,
  "deprecated": false
};
const IconMarkerSolid = exports.IconMarkerSolid = {
  "variant": "Solid",
  "glyphName": "marker",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EABC",
  "className": "icon-marker",
  "classes": ["icon-solid", "icon-marker"],
  "bidirectional": false,
  "deprecated": false
};
const IconMasqueradeLine = exports.IconMasqueradeLine = {
  "variant": "Line",
  "glyphName": "masquerade",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EABD",
  "className": "icon-masquerade",
  "classes": ["icon-line", "icon-masquerade"],
  "bidirectional": false,
  "deprecated": false
};
const IconMasqueradeSolid = exports.IconMasqueradeSolid = {
  "variant": "Solid",
  "glyphName": "masquerade",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EABD",
  "className": "icon-masquerade",
  "classes": ["icon-solid", "icon-masquerade"],
  "bidirectional": false,
  "deprecated": false
};
const IconMasteryLogoLine = exports.IconMasteryLogoLine = {
  "variant": "Line",
  "glyphName": "mastery-logo",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EABE",
  "className": "icon-mastery-logo",
  "classes": ["icon-line", "icon-mastery-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconMasteryLogoSolid = exports.IconMasteryLogoSolid = {
  "variant": "Solid",
  "glyphName": "mastery-logo",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EABE",
  "className": "icon-mastery-logo",
  "classes": ["icon-solid", "icon-mastery-logo"],
  "bidirectional": false,
  "deprecated": false
};
const IconMasteryPathsLine = exports.IconMasteryPathsLine = {
  "variant": "Line",
  "glyphName": "mastery-paths",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EABF",
  "className": "icon-mastery-paths",
  "classes": ["icon-line", "icon-mastery-paths"],
  "bidirectional": false,
  "deprecated": false
};
const IconMasteryPathsSolid = exports.IconMasteryPathsSolid = {
  "variant": "Solid",
  "glyphName": "mastery-paths",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EABF",
  "className": "icon-mastery-paths",
  "classes": ["icon-solid", "icon-mastery-paths"],
  "bidirectional": false,
  "deprecated": false
};
const IconMaterialsRequiredLightLine = exports.IconMaterialsRequiredLightLine = {
  "variant": "Line",
  "glyphName": "materials-required-light",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC0",
  "className": "icon-materials-required-light",
  "classes": ["icon-line", "icon-materials-required-light"],
  "bidirectional": false,
  "deprecated": true
};
const IconMaterialsRequiredLightSolid = exports.IconMaterialsRequiredLightSolid = {
  "variant": "Solid",
  "glyphName": "materials-required-light",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC0",
  "className": "icon-materials-required-light",
  "classes": ["icon-solid", "icon-materials-required-light"],
  "bidirectional": false,
  "deprecated": true
};
const IconMaterialsRequiredLine = exports.IconMaterialsRequiredLine = {
  "variant": "Line",
  "glyphName": "materials-required",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC1",
  "className": "icon-materials-required",
  "classes": ["icon-line", "icon-materials-required"],
  "bidirectional": false,
  "deprecated": false
};
const IconMaterialsRequiredSolid = exports.IconMaterialsRequiredSolid = {
  "variant": "Solid",
  "glyphName": "materials-required",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC1",
  "className": "icon-materials-required",
  "classes": ["icon-solid", "icon-materials-required"],
  "bidirectional": false,
  "deprecated": false
};
const IconMatureLightLine = exports.IconMatureLightLine = {
  "variant": "Line",
  "glyphName": "mature-light",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC2",
  "className": "icon-mature-light",
  "classes": ["icon-line", "icon-mature-light"],
  "bidirectional": false,
  "deprecated": true
};
const IconMatureLightSolid = exports.IconMatureLightSolid = {
  "variant": "Solid",
  "glyphName": "mature-light",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC2",
  "className": "icon-mature-light",
  "classes": ["icon-solid", "icon-mature-light"],
  "bidirectional": false,
  "deprecated": true
};
const IconMatureLine = exports.IconMatureLine = {
  "variant": "Line",
  "glyphName": "mature",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC3",
  "className": "icon-mature",
  "classes": ["icon-line", "icon-mature"],
  "bidirectional": false,
  "deprecated": false
};
const IconMatureSolid = exports.IconMatureSolid = {
  "variant": "Solid",
  "glyphName": "mature",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC3",
  "className": "icon-mature",
  "classes": ["icon-solid", "icon-mature"],
  "bidirectional": false,
  "deprecated": false
};
const IconMediaLine = exports.IconMediaLine = {
  "variant": "Line",
  "glyphName": "media",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC4",
  "className": "icon-media",
  "classes": ["icon-line", "icon-media"],
  "bidirectional": false,
  "deprecated": false
};
const IconMediaSolid = exports.IconMediaSolid = {
  "variant": "Solid",
  "glyphName": "media",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC4",
  "className": "icon-media",
  "classes": ["icon-solid", "icon-media"],
  "bidirectional": false,
  "deprecated": false
};
const IconMessageLine = exports.IconMessageLine = {
  "variant": "Line",
  "glyphName": "message",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC5",
  "className": "icon-message",
  "classes": ["icon-line", "icon-message"],
  "bidirectional": false,
  "deprecated": false
};
const IconMessageSolid = exports.IconMessageSolid = {
  "variant": "Solid",
  "glyphName": "message",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC5",
  "className": "icon-message",
  "classes": ["icon-solid", "icon-message"],
  "bidirectional": false,
  "deprecated": false
};
const IconMicOffLine = exports.IconMicOffLine = {
  "variant": "Line",
  "glyphName": "mic-off",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC6",
  "className": "icon-mic-off",
  "classes": ["icon-line", "icon-mic-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconMicOffSolid = exports.IconMicOffSolid = {
  "variant": "Solid",
  "glyphName": "mic-off",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC6",
  "className": "icon-mic-off",
  "classes": ["icon-solid", "icon-mic-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconMicLine = exports.IconMicLine = {
  "variant": "Line",
  "glyphName": "mic",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC7",
  "className": "icon-mic",
  "classes": ["icon-line", "icon-mic"],
  "bidirectional": false,
  "deprecated": false
};
const IconMicSolid = exports.IconMicSolid = {
  "variant": "Solid",
  "glyphName": "mic",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC7",
  "className": "icon-mic",
  "classes": ["icon-solid", "icon-mic"],
  "bidirectional": false,
  "deprecated": false
};
const IconMiniArrowDoubleLine = exports.IconMiniArrowDoubleLine = {
  "variant": "Line",
  "glyphName": "mini-arrow-double",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC8",
  "className": "icon-mini-arrow-double",
  "classes": ["icon-line", "icon-mini-arrow-double"],
  "bidirectional": false,
  "deprecated": false
};
const IconMiniArrowDoubleSolid = exports.IconMiniArrowDoubleSolid = {
  "variant": "Solid",
  "glyphName": "mini-arrow-double",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC8",
  "className": "icon-mini-arrow-double",
  "classes": ["icon-solid", "icon-mini-arrow-double"],
  "bidirectional": false,
  "deprecated": false
};
const IconMiniArrowDownLine = exports.IconMiniArrowDownLine = {
  "variant": "Line",
  "glyphName": "mini-arrow-down",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAC9",
  "className": "icon-mini-arrow-down",
  "classes": ["icon-line", "icon-mini-arrow-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconMiniArrowDownSolid = exports.IconMiniArrowDownSolid = {
  "variant": "Solid",
  "glyphName": "mini-arrow-down",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAC9",
  "className": "icon-mini-arrow-down",
  "classes": ["icon-solid", "icon-mini-arrow-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconMiniArrowEndLine = exports.IconMiniArrowEndLine = {
  "variant": "Line",
  "glyphName": "mini-arrow-end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EACA",
  "className": "icon-mini-arrow-end",
  "classes": ["icon-line", "icon-mini-arrow-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconMiniArrowEndSolid = exports.IconMiniArrowEndSolid = {
  "variant": "Solid",
  "glyphName": "mini-arrow-end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EACA",
  "className": "icon-mini-arrow-end",
  "classes": ["icon-solid", "icon-mini-arrow-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconMiniArrowLeftLine = exports.IconMiniArrowLeftLine = {
  "variant": "Line",
  "glyphName": "mini-arrow-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EACB",
  "className": "icon-mini-arrow-left",
  "classes": ["icon-line", "icon-mini-arrow-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconMiniArrowLeftSolid = exports.IconMiniArrowLeftSolid = {
  "variant": "Solid",
  "glyphName": "mini-arrow-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EACB",
  "className": "icon-mini-arrow-left",
  "classes": ["icon-solid", "icon-mini-arrow-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconMiniArrowRightLine = exports.IconMiniArrowRightLine = {
  "variant": "Line",
  "glyphName": "mini-arrow-right",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EACC",
  "className": "icon-mini-arrow-right",
  "classes": ["icon-line", "icon-mini-arrow-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconMiniArrowRightSolid = exports.IconMiniArrowRightSolid = {
  "variant": "Solid",
  "glyphName": "mini-arrow-right",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EACC",
  "className": "icon-mini-arrow-right",
  "classes": ["icon-solid", "icon-mini-arrow-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconMiniArrowStartLine = exports.IconMiniArrowStartLine = {
  "variant": "Line",
  "glyphName": "mini-arrow-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EACD",
  "className": "icon-mini-arrow-start",
  "classes": ["icon-line", "icon-mini-arrow-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconMiniArrowStartSolid = exports.IconMiniArrowStartSolid = {
  "variant": "Solid",
  "glyphName": "mini-arrow-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EACD",
  "className": "icon-mini-arrow-start",
  "classes": ["icon-solid", "icon-mini-arrow-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconMiniArrowUpLine = exports.IconMiniArrowUpLine = {
  "variant": "Line",
  "glyphName": "mini-arrow-up",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EACE",
  "className": "icon-mini-arrow-up",
  "classes": ["icon-line", "icon-mini-arrow-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconMiniArrowUpSolid = exports.IconMiniArrowUpSolid = {
  "variant": "Solid",
  "glyphName": "mini-arrow-up",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EACE",
  "className": "icon-mini-arrow-up",
  "classes": ["icon-solid", "icon-mini-arrow-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconMinimizeLine = exports.IconMinimizeLine = {
  "variant": "Line",
  "glyphName": "minimize",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EACF",
  "className": "icon-minimize",
  "classes": ["icon-line", "icon-minimize"],
  "bidirectional": false,
  "deprecated": false
};
const IconMinimizeSolid = exports.IconMinimizeSolid = {
  "variant": "Solid",
  "glyphName": "minimize",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EACF",
  "className": "icon-minimize",
  "classes": ["icon-solid", "icon-minimize"],
  "bidirectional": false,
  "deprecated": false
};
const IconModuleLine = exports.IconModuleLine = {
  "variant": "Line",
  "glyphName": "module",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD0",
  "className": "icon-module",
  "classes": ["icon-line", "icon-module"],
  "bidirectional": false,
  "deprecated": false
};
const IconModuleSolid = exports.IconModuleSolid = {
  "variant": "Solid",
  "glyphName": "module",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD0",
  "className": "icon-module",
  "classes": ["icon-solid", "icon-module"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoreLine = exports.IconMoreLine = {
  "variant": "Line",
  "glyphName": "more",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD1",
  "className": "icon-more",
  "classes": ["icon-line", "icon-more"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoreSolid = exports.IconMoreSolid = {
  "variant": "Solid",
  "glyphName": "more",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD1",
  "className": "icon-more",
  "classes": ["icon-solid", "icon-more"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveDownBottomLine = exports.IconMoveDownBottomLine = {
  "variant": "Line",
  "glyphName": "move-down-bottom",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD2",
  "className": "icon-move-down-bottom",
  "classes": ["icon-line", "icon-move-down-bottom"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveDownBottomSolid = exports.IconMoveDownBottomSolid = {
  "variant": "Solid",
  "glyphName": "move-down-bottom",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD2",
  "className": "icon-move-down-bottom",
  "classes": ["icon-solid", "icon-move-down-bottom"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveDownLine = exports.IconMoveDownLine = {
  "variant": "Line",
  "glyphName": "move-down",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD3",
  "className": "icon-move-down",
  "classes": ["icon-line", "icon-move-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveDownSolid = exports.IconMoveDownSolid = {
  "variant": "Solid",
  "glyphName": "move-down",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD3",
  "className": "icon-move-down",
  "classes": ["icon-solid", "icon-move-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveEndLine = exports.IconMoveEndLine = {
  "variant": "Line",
  "glyphName": "move-end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD4",
  "className": "icon-move-end",
  "classes": ["icon-line", "icon-move-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconMoveEndSolid = exports.IconMoveEndSolid = {
  "variant": "Solid",
  "glyphName": "move-end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD4",
  "className": "icon-move-end",
  "classes": ["icon-solid", "icon-move-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconMoveLeftLine = exports.IconMoveLeftLine = {
  "variant": "Line",
  "glyphName": "move-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD5",
  "className": "icon-move-left",
  "classes": ["icon-line", "icon-move-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconMoveLeftSolid = exports.IconMoveLeftSolid = {
  "variant": "Solid",
  "glyphName": "move-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD5",
  "className": "icon-move-left",
  "classes": ["icon-solid", "icon-move-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconMoveRightLine = exports.IconMoveRightLine = {
  "variant": "Line",
  "glyphName": "move-right",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD6",
  "className": "icon-move-right",
  "classes": ["icon-line", "icon-move-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconMoveRightSolid = exports.IconMoveRightSolid = {
  "variant": "Solid",
  "glyphName": "move-right",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD6",
  "className": "icon-move-right",
  "classes": ["icon-solid", "icon-move-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconMoveStartLine = exports.IconMoveStartLine = {
  "variant": "Line",
  "glyphName": "move-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD7",
  "className": "icon-move-start",
  "classes": ["icon-line", "icon-move-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconMoveStartSolid = exports.IconMoveStartSolid = {
  "variant": "Solid",
  "glyphName": "move-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD7",
  "className": "icon-move-start",
  "classes": ["icon-solid", "icon-move-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconMoveUpTopLine = exports.IconMoveUpTopLine = {
  "variant": "Line",
  "glyphName": "move-up-top",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD8",
  "className": "icon-move-up-top",
  "classes": ["icon-line", "icon-move-up-top"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveUpTopSolid = exports.IconMoveUpTopSolid = {
  "variant": "Solid",
  "glyphName": "move-up-top",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD8",
  "className": "icon-move-up-top",
  "classes": ["icon-solid", "icon-move-up-top"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveUpLine = exports.IconMoveUpLine = {
  "variant": "Line",
  "glyphName": "move-up",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAD9",
  "className": "icon-move-up",
  "classes": ["icon-line", "icon-move-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconMoveUpSolid = exports.IconMoveUpSolid = {
  "variant": "Solid",
  "glyphName": "move-up",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAD9",
  "className": "icon-move-up",
  "classes": ["icon-solid", "icon-move-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconMsExcelLine = exports.IconMsExcelLine = {
  "variant": "Line",
  "glyphName": "ms-excel",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EADA",
  "className": "icon-ms-excel",
  "classes": ["icon-line", "icon-ms-excel"],
  "bidirectional": false,
  "deprecated": false
};
const IconMsExcelSolid = exports.IconMsExcelSolid = {
  "variant": "Solid",
  "glyphName": "ms-excel",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EADA",
  "className": "icon-ms-excel",
  "classes": ["icon-solid", "icon-ms-excel"],
  "bidirectional": false,
  "deprecated": false
};
const IconMsPptLine = exports.IconMsPptLine = {
  "variant": "Line",
  "glyphName": "ms-ppt",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EADB",
  "className": "icon-ms-ppt",
  "classes": ["icon-line", "icon-ms-ppt"],
  "bidirectional": false,
  "deprecated": false
};
const IconMsPptSolid = exports.IconMsPptSolid = {
  "variant": "Solid",
  "glyphName": "ms-ppt",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EADB",
  "className": "icon-ms-ppt",
  "classes": ["icon-solid", "icon-ms-ppt"],
  "bidirectional": false,
  "deprecated": false
};
const IconMsWordLine = exports.IconMsWordLine = {
  "variant": "Line",
  "glyphName": "ms-word",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EADC",
  "className": "icon-ms-word",
  "classes": ["icon-line", "icon-ms-word"],
  "bidirectional": false,
  "deprecated": false
};
const IconMsWordSolid = exports.IconMsWordSolid = {
  "variant": "Solid",
  "glyphName": "ms-word",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EADC",
  "className": "icon-ms-word",
  "classes": ["icon-solid", "icon-ms-word"],
  "bidirectional": false,
  "deprecated": false
};
const IconMutedLine = exports.IconMutedLine = {
  "variant": "Line",
  "glyphName": "muted",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EADD",
  "className": "icon-muted",
  "classes": ["icon-line", "icon-muted"],
  "bidirectional": false,
  "deprecated": false
};
const IconMutedSolid = exports.IconMutedSolid = {
  "variant": "Solid",
  "glyphName": "muted",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EADD",
  "className": "icon-muted",
  "classes": ["icon-solid", "icon-muted"],
  "bidirectional": false,
  "deprecated": false
};
const IconNextUnreadLine = exports.IconNextUnreadLine = {
  "variant": "Line",
  "glyphName": "next-unread",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EADE",
  "className": "icon-next-unread",
  "classes": ["icon-line", "icon-next-unread"],
  "bidirectional": true,
  "deprecated": false
};
const IconNextUnreadSolid = exports.IconNextUnreadSolid = {
  "variant": "Solid",
  "glyphName": "next-unread",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EADE",
  "className": "icon-next-unread",
  "classes": ["icon-solid", "icon-next-unread"],
  "bidirectional": true,
  "deprecated": false
};
const IconNoLine = exports.IconNoLine = {
  "variant": "Line",
  "glyphName": "no",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EADF",
  "className": "icon-no",
  "classes": ["icon-line", "icon-no"],
  "bidirectional": false,
  "deprecated": false
};
const IconNoSolid = exports.IconNoSolid = {
  "variant": "Solid",
  "glyphName": "no",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EADF",
  "className": "icon-no",
  "classes": ["icon-solid", "icon-no"],
  "bidirectional": false,
  "deprecated": false
};
const IconNotGradedLine = exports.IconNotGradedLine = {
  "variant": "Line",
  "glyphName": "not-graded",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE0",
  "className": "icon-not-graded",
  "classes": ["icon-line", "icon-not-graded"],
  "bidirectional": true,
  "deprecated": false
};
const IconNotGradedSolid = exports.IconNotGradedSolid = {
  "variant": "Solid",
  "glyphName": "not-graded",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE0",
  "className": "icon-not-graded",
  "classes": ["icon-solid", "icon-not-graded"],
  "bidirectional": true,
  "deprecated": false
};
const IconNoteDarkLine = exports.IconNoteDarkLine = {
  "variant": "Line",
  "glyphName": "note-dark",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE1",
  "className": "icon-note-dark",
  "classes": ["icon-line", "icon-note-dark"],
  "bidirectional": false,
  "deprecated": true
};
const IconNoteDarkSolid = exports.IconNoteDarkSolid = {
  "variant": "Solid",
  "glyphName": "note-dark",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE1",
  "className": "icon-note-dark",
  "classes": ["icon-solid", "icon-note-dark"],
  "bidirectional": false,
  "deprecated": true
};
const IconNoteLightLine = exports.IconNoteLightLine = {
  "variant": "Line",
  "glyphName": "note-light",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE2",
  "className": "icon-note-light",
  "classes": ["icon-line", "icon-note-light"],
  "bidirectional": false,
  "deprecated": true
};
const IconNoteLightSolid = exports.IconNoteLightSolid = {
  "variant": "Solid",
  "glyphName": "note-light",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE2",
  "className": "icon-note-light",
  "classes": ["icon-solid", "icon-note-light"],
  "bidirectional": false,
  "deprecated": true
};
const IconNoteLine = exports.IconNoteLine = {
  "variant": "Line",
  "glyphName": "note",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE3",
  "className": "icon-note",
  "classes": ["icon-line", "icon-note"],
  "bidirectional": true,
  "deprecated": false
};
const IconNoteSolid = exports.IconNoteSolid = {
  "variant": "Solid",
  "glyphName": "note",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE3",
  "className": "icon-note",
  "classes": ["icon-solid", "icon-note"],
  "bidirectional": true,
  "deprecated": false
};
const IconNotepadLine = exports.IconNotepadLine = {
  "variant": "Line",
  "glyphName": "notepad",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE4",
  "className": "icon-notepad",
  "classes": ["icon-line", "icon-notepad"],
  "bidirectional": false,
  "deprecated": false
};
const IconNotepadSolid = exports.IconNotepadSolid = {
  "variant": "Solid",
  "glyphName": "notepad",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE4",
  "className": "icon-notepad",
  "classes": ["icon-solid", "icon-notepad"],
  "bidirectional": false,
  "deprecated": false
};
const IconNumberedListLine = exports.IconNumberedListLine = {
  "variant": "Line",
  "glyphName": "numbered-list",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE5",
  "className": "icon-numbered-list",
  "classes": ["icon-line", "icon-numbered-list"],
  "bidirectional": false,
  "deprecated": false
};
const IconNumberedListSolid = exports.IconNumberedListSolid = {
  "variant": "Solid",
  "glyphName": "numbered-list",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE5",
  "className": "icon-numbered-list",
  "classes": ["icon-solid", "icon-numbered-list"],
  "bidirectional": false,
  "deprecated": false
};
const IconOffLine = exports.IconOffLine = {
  "variant": "Line",
  "glyphName": "off",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE6",
  "className": "icon-off",
  "classes": ["icon-line", "icon-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconOffSolid = exports.IconOffSolid = {
  "variant": "Solid",
  "glyphName": "off",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE6",
  "className": "icon-off",
  "classes": ["icon-solid", "icon-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconOpenFolderLine = exports.IconOpenFolderLine = {
  "variant": "Line",
  "glyphName": "open-folder",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE7",
  "className": "icon-open-folder",
  "classes": ["icon-line", "icon-open-folder"],
  "bidirectional": true,
  "deprecated": false
};
const IconOpenFolderSolid = exports.IconOpenFolderSolid = {
  "variant": "Solid",
  "glyphName": "open-folder",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE7",
  "className": "icon-open-folder",
  "classes": ["icon-solid", "icon-open-folder"],
  "bidirectional": true,
  "deprecated": false
};
const IconOutcomesLine = exports.IconOutcomesLine = {
  "variant": "Line",
  "glyphName": "outcomes",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE8",
  "className": "icon-outcomes",
  "classes": ["icon-line", "icon-outcomes"],
  "bidirectional": false,
  "deprecated": false
};
const IconOutcomesSolid = exports.IconOutcomesSolid = {
  "variant": "Solid",
  "glyphName": "outcomes",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE8",
  "className": "icon-outcomes",
  "classes": ["icon-solid", "icon-outcomes"],
  "bidirectional": false,
  "deprecated": false
};
const IconOutdentLine = exports.IconOutdentLine = {
  "variant": "Line",
  "glyphName": "outdent",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAE9",
  "className": "icon-outdent",
  "classes": ["icon-line", "icon-outdent"],
  "bidirectional": true,
  "deprecated": false
};
const IconOutdentSolid = exports.IconOutdentSolid = {
  "variant": "Solid",
  "glyphName": "outdent",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAE9",
  "className": "icon-outdent",
  "classes": ["icon-solid", "icon-outdent"],
  "bidirectional": true,
  "deprecated": false
};
const IconOutdent2Line = exports.IconOutdent2Line = {
  "variant": "Line",
  "glyphName": "outdent2",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAEA",
  "className": "icon-outdent2",
  "classes": ["icon-line", "icon-outdent2"],
  "bidirectional": true,
  "deprecated": false
};
const IconOutdent2Solid = exports.IconOutdent2Solid = {
  "variant": "Solid",
  "glyphName": "outdent2",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAEA",
  "className": "icon-outdent2",
  "classes": ["icon-solid", "icon-outdent2"],
  "bidirectional": true,
  "deprecated": false
};
const IconOvalHalfLine = exports.IconOvalHalfLine = {
  "variant": "Line",
  "glyphName": "oval-half",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAEB",
  "className": "icon-oval-half",
  "classes": ["icon-line", "icon-oval-half"],
  "bidirectional": false,
  "deprecated": false
};
const IconOvalHalfSolid = exports.IconOvalHalfSolid = {
  "variant": "Solid",
  "glyphName": "oval-half",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAEB",
  "className": "icon-oval-half",
  "classes": ["icon-solid", "icon-oval-half"],
  "bidirectional": false,
  "deprecated": false
};
const IconPageDownLine = exports.IconPageDownLine = {
  "variant": "Line",
  "glyphName": "page-down",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAEC",
  "className": "icon-page-down",
  "classes": ["icon-line", "icon-page-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconPageDownSolid = exports.IconPageDownSolid = {
  "variant": "Solid",
  "glyphName": "page-down",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAEC",
  "className": "icon-page-down",
  "classes": ["icon-solid", "icon-page-down"],
  "bidirectional": false,
  "deprecated": false
};
const IconPageUpLine = exports.IconPageUpLine = {
  "variant": "Line",
  "glyphName": "page-up",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAED",
  "className": "icon-page-up",
  "classes": ["icon-line", "icon-page-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconPageUpSolid = exports.IconPageUpSolid = {
  "variant": "Solid",
  "glyphName": "page-up",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAED",
  "className": "icon-page-up",
  "classes": ["icon-solid", "icon-page-up"],
  "bidirectional": false,
  "deprecated": false
};
const IconPaintLine = exports.IconPaintLine = {
  "variant": "Line",
  "glyphName": "paint",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAEE",
  "className": "icon-paint",
  "classes": ["icon-line", "icon-paint"],
  "bidirectional": false,
  "deprecated": false
};
const IconPaintSolid = exports.IconPaintSolid = {
  "variant": "Solid",
  "glyphName": "paint",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAEE",
  "className": "icon-paint",
  "classes": ["icon-solid", "icon-paint"],
  "bidirectional": false,
  "deprecated": false
};
const IconPaperclipLine = exports.IconPaperclipLine = {
  "variant": "Line",
  "glyphName": "paperclip",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAEF",
  "className": "icon-paperclip",
  "classes": ["icon-line", "icon-paperclip"],
  "bidirectional": false,
  "deprecated": false
};
const IconPaperclipSolid = exports.IconPaperclipSolid = {
  "variant": "Solid",
  "glyphName": "paperclip",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAEF",
  "className": "icon-paperclip",
  "classes": ["icon-solid", "icon-paperclip"],
  "bidirectional": false,
  "deprecated": false
};
const IconPartialLine = exports.IconPartialLine = {
  "variant": "Line",
  "glyphName": "partial",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF0",
  "className": "icon-partial",
  "classes": ["icon-line", "icon-partial"],
  "bidirectional": false,
  "deprecated": false
};
const IconPartialSolid = exports.IconPartialSolid = {
  "variant": "Solid",
  "glyphName": "partial",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF0",
  "className": "icon-partial",
  "classes": ["icon-solid", "icon-partial"],
  "bidirectional": false,
  "deprecated": false
};
const IconPauseLine = exports.IconPauseLine = {
  "variant": "Line",
  "glyphName": "pause",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF1",
  "className": "icon-pause",
  "classes": ["icon-line", "icon-pause"],
  "bidirectional": false,
  "deprecated": false
};
const IconPauseSolid = exports.IconPauseSolid = {
  "variant": "Solid",
  "glyphName": "pause",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF1",
  "className": "icon-pause",
  "classes": ["icon-solid", "icon-pause"],
  "bidirectional": false,
  "deprecated": false
};
const IconPdfLine = exports.IconPdfLine = {
  "variant": "Line",
  "glyphName": "pdf",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF2",
  "className": "icon-pdf",
  "classes": ["icon-line", "icon-pdf"],
  "bidirectional": false,
  "deprecated": false
};
const IconPdfSolid = exports.IconPdfSolid = {
  "variant": "Solid",
  "glyphName": "pdf",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF2",
  "className": "icon-pdf",
  "classes": ["icon-solid", "icon-pdf"],
  "bidirectional": false,
  "deprecated": false
};
const IconPeerGradedLine = exports.IconPeerGradedLine = {
  "variant": "Line",
  "glyphName": "peer-graded",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF3",
  "className": "icon-peer-graded",
  "classes": ["icon-line", "icon-peer-graded"],
  "bidirectional": false,
  "deprecated": false
};
const IconPeerGradedSolid = exports.IconPeerGradedSolid = {
  "variant": "Solid",
  "glyphName": "peer-graded",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF3",
  "className": "icon-peer-graded",
  "classes": ["icon-solid", "icon-peer-graded"],
  "bidirectional": false,
  "deprecated": false
};
const IconPeerReviewLine = exports.IconPeerReviewLine = {
  "variant": "Line",
  "glyphName": "peer-review",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF4",
  "className": "icon-peer-review",
  "classes": ["icon-line", "icon-peer-review"],
  "bidirectional": false,
  "deprecated": false
};
const IconPeerReviewSolid = exports.IconPeerReviewSolid = {
  "variant": "Solid",
  "glyphName": "peer-review",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF4",
  "className": "icon-peer-review",
  "classes": ["icon-solid", "icon-peer-review"],
  "bidirectional": false,
  "deprecated": false
};
const IconPermissionsLine = exports.IconPermissionsLine = {
  "variant": "Line",
  "glyphName": "permissions",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF5",
  "className": "icon-permissions",
  "classes": ["icon-line", "icon-permissions"],
  "bidirectional": false,
  "deprecated": false
};
const IconPermissionsSolid = exports.IconPermissionsSolid = {
  "variant": "Solid",
  "glyphName": "permissions",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF5",
  "className": "icon-permissions",
  "classes": ["icon-solid", "icon-permissions"],
  "bidirectional": false,
  "deprecated": false
};
const IconPinLine = exports.IconPinLine = {
  "variant": "Line",
  "glyphName": "pin",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF6",
  "className": "icon-pin",
  "classes": ["icon-line", "icon-pin"],
  "bidirectional": false,
  "deprecated": false
};
const IconPinSolid = exports.IconPinSolid = {
  "variant": "Solid",
  "glyphName": "pin",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF6",
  "className": "icon-pin",
  "classes": ["icon-solid", "icon-pin"],
  "bidirectional": false,
  "deprecated": false
};
const IconPinterestLine = exports.IconPinterestLine = {
  "variant": "Line",
  "glyphName": "pinterest",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF7",
  "className": "icon-pinterest",
  "classes": ["icon-line", "icon-pinterest"],
  "bidirectional": false,
  "deprecated": false
};
const IconPinterestSolid = exports.IconPinterestSolid = {
  "variant": "Solid",
  "glyphName": "pinterest",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF7",
  "className": "icon-pinterest",
  "classes": ["icon-solid", "icon-pinterest"],
  "bidirectional": false,
  "deprecated": false
};
const IconPlayLine = exports.IconPlayLine = {
  "variant": "Line",
  "glyphName": "play",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF8",
  "className": "icon-play",
  "classes": ["icon-line", "icon-play"],
  "bidirectional": false,
  "deprecated": false
};
const IconPlaySolid = exports.IconPlaySolid = {
  "variant": "Solid",
  "glyphName": "play",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF8",
  "className": "icon-play",
  "classes": ["icon-solid", "icon-play"],
  "bidirectional": false,
  "deprecated": false
};
const IconPlusLine = exports.IconPlusLine = {
  "variant": "Line",
  "glyphName": "plus",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAF9",
  "className": "icon-plus",
  "classes": ["icon-line", "icon-plus"],
  "bidirectional": false,
  "deprecated": false
};
const IconPlusSolid = exports.IconPlusSolid = {
  "variant": "Solid",
  "glyphName": "plus",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAF9",
  "className": "icon-plus",
  "classes": ["icon-solid", "icon-plus"],
  "bidirectional": false,
  "deprecated": false
};
const IconPostToSisLine = exports.IconPostToSisLine = {
  "variant": "Line",
  "glyphName": "post-to-sis",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAFA",
  "className": "icon-post-to-sis",
  "classes": ["icon-line", "icon-post-to-sis"],
  "bidirectional": false,
  "deprecated": false
};
const IconPostToSisSolid = exports.IconPostToSisSolid = {
  "variant": "Solid",
  "glyphName": "post-to-sis",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAFA",
  "className": "icon-post-to-sis",
  "classes": ["icon-solid", "icon-post-to-sis"],
  "bidirectional": false,
  "deprecated": false
};
const IconPredictiveLine = exports.IconPredictiveLine = {
  "variant": "Line",
  "glyphName": "predictive",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAFB",
  "className": "icon-predictive",
  "classes": ["icon-line", "icon-predictive"],
  "bidirectional": false,
  "deprecated": false
};
const IconPredictiveSolid = exports.IconPredictiveSolid = {
  "variant": "Solid",
  "glyphName": "predictive",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAFB",
  "className": "icon-predictive",
  "classes": ["icon-solid", "icon-predictive"],
  "bidirectional": false,
  "deprecated": false
};
const IconPrerequisiteLine = exports.IconPrerequisiteLine = {
  "variant": "Line",
  "glyphName": "prerequisite",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAFC",
  "className": "icon-prerequisite",
  "classes": ["icon-line", "icon-prerequisite"],
  "bidirectional": false,
  "deprecated": false
};
const IconPrerequisiteSolid = exports.IconPrerequisiteSolid = {
  "variant": "Solid",
  "glyphName": "prerequisite",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAFC",
  "className": "icon-prerequisite",
  "classes": ["icon-solid", "icon-prerequisite"],
  "bidirectional": false,
  "deprecated": false
};
const IconPrinterLine = exports.IconPrinterLine = {
  "variant": "Line",
  "glyphName": "printer",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAFD",
  "className": "icon-printer",
  "classes": ["icon-line", "icon-printer"],
  "bidirectional": false,
  "deprecated": false
};
const IconPrinterSolid = exports.IconPrinterSolid = {
  "variant": "Solid",
  "glyphName": "printer",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAFD",
  "className": "icon-printer",
  "classes": ["icon-solid", "icon-printer"],
  "bidirectional": false,
  "deprecated": false
};
const IconProgressLine = exports.IconProgressLine = {
  "variant": "Line",
  "glyphName": "progress",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAFE",
  "className": "icon-progress",
  "classes": ["icon-line", "icon-progress"],
  "bidirectional": false,
  "deprecated": false
};
const IconProgressSolid = exports.IconProgressSolid = {
  "variant": "Solid",
  "glyphName": "progress",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAFE",
  "className": "icon-progress",
  "classes": ["icon-solid", "icon-progress"],
  "bidirectional": false,
  "deprecated": false
};
const IconProtractorLine = exports.IconProtractorLine = {
  "variant": "Line",
  "glyphName": "protractor",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EAFF",
  "className": "icon-protractor",
  "classes": ["icon-line", "icon-protractor"],
  "bidirectional": false,
  "deprecated": false
};
const IconProtractorSolid = exports.IconProtractorSolid = {
  "variant": "Solid",
  "glyphName": "protractor",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EAFF",
  "className": "icon-protractor",
  "classes": ["icon-solid", "icon-protractor"],
  "bidirectional": false,
  "deprecated": false
};
const IconPublishLine = exports.IconPublishLine = {
  "variant": "Line",
  "glyphName": "publish",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB00",
  "className": "icon-publish",
  "classes": ["icon-line", "icon-publish"],
  "bidirectional": false,
  "deprecated": false
};
const IconPublishSolid = exports.IconPublishSolid = {
  "variant": "Solid",
  "glyphName": "publish",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB00",
  "className": "icon-publish",
  "classes": ["icon-solid", "icon-publish"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuestionLine = exports.IconQuestionLine = {
  "variant": "Line",
  "glyphName": "question",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB01",
  "className": "icon-question",
  "classes": ["icon-line", "icon-question"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuestionSolid = exports.IconQuestionSolid = {
  "variant": "Solid",
  "glyphName": "question",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB01",
  "className": "icon-question",
  "classes": ["icon-solid", "icon-question"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizInstructionsLine = exports.IconQuizInstructionsLine = {
  "variant": "Line",
  "glyphName": "quiz-instructions",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB02",
  "className": "icon-quiz-instructions",
  "classes": ["icon-line", "icon-quiz-instructions"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizInstructionsSolid = exports.IconQuizInstructionsSolid = {
  "variant": "Solid",
  "glyphName": "quiz-instructions",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB02",
  "className": "icon-quiz-instructions",
  "classes": ["icon-solid", "icon-quiz-instructions"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsAvgLine = exports.IconQuizStatsAvgLine = {
  "variant": "Line",
  "glyphName": "quiz-stats-avg",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB03",
  "className": "icon-quiz-stats-avg",
  "classes": ["icon-line", "icon-quiz-stats-avg"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsAvgSolid = exports.IconQuizStatsAvgSolid = {
  "variant": "Solid",
  "glyphName": "quiz-stats-avg",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB03",
  "className": "icon-quiz-stats-avg",
  "classes": ["icon-solid", "icon-quiz-stats-avg"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsCronbachsAlphaLine = exports.IconQuizStatsCronbachsAlphaLine = {
  "variant": "Line",
  "glyphName": "quiz-stats-cronbachs-alpha",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB04",
  "className": "icon-quiz-stats-cronbachs-alpha",
  "classes": ["icon-line", "icon-quiz-stats-cronbachs-alpha"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsCronbachsAlphaSolid = exports.IconQuizStatsCronbachsAlphaSolid = {
  "variant": "Solid",
  "glyphName": "quiz-stats-cronbachs-alpha",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB04",
  "className": "icon-quiz-stats-cronbachs-alpha",
  "classes": ["icon-solid", "icon-quiz-stats-cronbachs-alpha"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsDeviationLine = exports.IconQuizStatsDeviationLine = {
  "variant": "Line",
  "glyphName": "quiz-stats-deviation",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB05",
  "className": "icon-quiz-stats-deviation",
  "classes": ["icon-line", "icon-quiz-stats-deviation"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsDeviationSolid = exports.IconQuizStatsDeviationSolid = {
  "variant": "Solid",
  "glyphName": "quiz-stats-deviation",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB05",
  "className": "icon-quiz-stats-deviation",
  "classes": ["icon-solid", "icon-quiz-stats-deviation"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsHighLine = exports.IconQuizStatsHighLine = {
  "variant": "Line",
  "glyphName": "quiz-stats-high",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB06",
  "className": "icon-quiz-stats-high",
  "classes": ["icon-line", "icon-quiz-stats-high"],
  "bidirectional": true,
  "deprecated": false
};
const IconQuizStatsHighSolid = exports.IconQuizStatsHighSolid = {
  "variant": "Solid",
  "glyphName": "quiz-stats-high",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB06",
  "className": "icon-quiz-stats-high",
  "classes": ["icon-solid", "icon-quiz-stats-high"],
  "bidirectional": true,
  "deprecated": false
};
const IconQuizStatsLowLine = exports.IconQuizStatsLowLine = {
  "variant": "Line",
  "glyphName": "quiz-stats-low",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB07",
  "className": "icon-quiz-stats-low",
  "classes": ["icon-line", "icon-quiz-stats-low"],
  "bidirectional": true,
  "deprecated": false
};
const IconQuizStatsLowSolid = exports.IconQuizStatsLowSolid = {
  "variant": "Solid",
  "glyphName": "quiz-stats-low",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB07",
  "className": "icon-quiz-stats-low",
  "classes": ["icon-solid", "icon-quiz-stats-low"],
  "bidirectional": true,
  "deprecated": false
};
const IconQuizStatsTimeLine = exports.IconQuizStatsTimeLine = {
  "variant": "Line",
  "glyphName": "quiz-stats-time",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB08",
  "className": "icon-quiz-stats-time",
  "classes": ["icon-line", "icon-quiz-stats-time"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizStatsTimeSolid = exports.IconQuizStatsTimeSolid = {
  "variant": "Solid",
  "glyphName": "quiz-stats-time",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB08",
  "className": "icon-quiz-stats-time",
  "classes": ["icon-solid", "icon-quiz-stats-time"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizTitleLine = exports.IconQuizTitleLine = {
  "variant": "Line",
  "glyphName": "quiz-title",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB09",
  "className": "icon-quiz-title",
  "classes": ["icon-line", "icon-quiz-title"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizTitleSolid = exports.IconQuizTitleSolid = {
  "variant": "Solid",
  "glyphName": "quiz-title",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB09",
  "className": "icon-quiz-title",
  "classes": ["icon-solid", "icon-quiz-title"],
  "bidirectional": false,
  "deprecated": false
};
const IconQuizLine = exports.IconQuizLine = {
  "variant": "Line",
  "glyphName": "quiz",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB0A",
  "className": "icon-quiz",
  "classes": ["icon-line", "icon-quiz"],
  "bidirectional": true,
  "deprecated": false
};
const IconQuizSolid = exports.IconQuizSolid = {
  "variant": "Solid",
  "glyphName": "quiz",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB0A",
  "className": "icon-quiz",
  "classes": ["icon-solid", "icon-quiz"],
  "bidirectional": true,
  "deprecated": false
};
const IconRecordLine = exports.IconRecordLine = {
  "variant": "Line",
  "glyphName": "record",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB0B",
  "className": "icon-record",
  "classes": ["icon-line", "icon-record"],
  "bidirectional": false,
  "deprecated": false
};
const IconRecordSolid = exports.IconRecordSolid = {
  "variant": "Solid",
  "glyphName": "record",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB0B",
  "className": "icon-record",
  "classes": ["icon-solid", "icon-record"],
  "bidirectional": false,
  "deprecated": false
};
const IconRefreshLine = exports.IconRefreshLine = {
  "variant": "Line",
  "glyphName": "refresh",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB0C",
  "className": "icon-refresh",
  "classes": ["icon-line", "icon-refresh"],
  "bidirectional": false,
  "deprecated": false
};
const IconRefreshSolid = exports.IconRefreshSolid = {
  "variant": "Solid",
  "glyphName": "refresh",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB0C",
  "className": "icon-refresh",
  "classes": ["icon-solid", "icon-refresh"],
  "bidirectional": false,
  "deprecated": false
};
const IconRemoveBookmarkLine = exports.IconRemoveBookmarkLine = {
  "variant": "Line",
  "glyphName": "remove-bookmark",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB0D",
  "className": "icon-remove-bookmark",
  "classes": ["icon-line", "icon-remove-bookmark"],
  "bidirectional": false,
  "deprecated": false
};
const IconRemoveBookmarkSolid = exports.IconRemoveBookmarkSolid = {
  "variant": "Solid",
  "glyphName": "remove-bookmark",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB0D",
  "className": "icon-remove-bookmark",
  "classes": ["icon-solid", "icon-remove-bookmark"],
  "bidirectional": false,
  "deprecated": false
};
const IconRemoveFromCollectionLine = exports.IconRemoveFromCollectionLine = {
  "variant": "Line",
  "glyphName": "remove-from-collection",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB0E",
  "className": "icon-remove-from-collection",
  "classes": ["icon-line", "icon-remove-from-collection"],
  "bidirectional": false,
  "deprecated": false
};
const IconRemoveFromCollectionSolid = exports.IconRemoveFromCollectionSolid = {
  "variant": "Solid",
  "glyphName": "remove-from-collection",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB0E",
  "className": "icon-remove-from-collection",
  "classes": ["icon-solid", "icon-remove-from-collection"],
  "bidirectional": false,
  "deprecated": false
};
const IconRemoveLinkLine = exports.IconRemoveLinkLine = {
  "variant": "Line",
  "glyphName": "remove-link",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB0F",
  "className": "icon-remove-link",
  "classes": ["icon-line", "icon-remove-link"],
  "bidirectional": false,
  "deprecated": false
};
const IconRemoveLinkSolid = exports.IconRemoveLinkSolid = {
  "variant": "Solid",
  "glyphName": "remove-link",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB0F",
  "className": "icon-remove-link",
  "classes": ["icon-solid", "icon-remove-link"],
  "bidirectional": false,
  "deprecated": false
};
const IconRepliedLine = exports.IconRepliedLine = {
  "variant": "Line",
  "glyphName": "replied",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB10",
  "className": "icon-replied",
  "classes": ["icon-line", "icon-replied"],
  "bidirectional": true,
  "deprecated": false
};
const IconRepliedSolid = exports.IconRepliedSolid = {
  "variant": "Solid",
  "glyphName": "replied",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB10",
  "className": "icon-replied",
  "classes": ["icon-solid", "icon-replied"],
  "bidirectional": true,
  "deprecated": false
};
const IconReply2Line = exports.IconReply2Line = {
  "variant": "Line",
  "glyphName": "reply-2",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB11",
  "className": "icon-reply-2",
  "classes": ["icon-line", "icon-reply-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconReply2Solid = exports.IconReply2Solid = {
  "variant": "Solid",
  "glyphName": "reply-2",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB11",
  "className": "icon-reply-2",
  "classes": ["icon-solid", "icon-reply-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconReplyAll2Line = exports.IconReplyAll2Line = {
  "variant": "Line",
  "glyphName": "reply-all-2",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB12",
  "className": "icon-reply-all-2",
  "classes": ["icon-line", "icon-reply-all-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconReplyAll2Solid = exports.IconReplyAll2Solid = {
  "variant": "Solid",
  "glyphName": "reply-all-2",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB12",
  "className": "icon-reply-all-2",
  "classes": ["icon-solid", "icon-reply-all-2"],
  "bidirectional": true,
  "deprecated": false
};
const IconReplyLine = exports.IconReplyLine = {
  "variant": "Line",
  "glyphName": "reply",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB13",
  "className": "icon-reply",
  "classes": ["icon-line", "icon-reply"],
  "bidirectional": true,
  "deprecated": false
};
const IconReplySolid = exports.IconReplySolid = {
  "variant": "Solid",
  "glyphName": "reply",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB13",
  "className": "icon-reply",
  "classes": ["icon-solid", "icon-reply"],
  "bidirectional": true,
  "deprecated": false
};
const IconResetLine = exports.IconResetLine = {
  "variant": "Line",
  "glyphName": "reset",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB14",
  "className": "icon-reset",
  "classes": ["icon-line", "icon-reset"],
  "bidirectional": false,
  "deprecated": false
};
const IconResetSolid = exports.IconResetSolid = {
  "variant": "Solid",
  "glyphName": "reset",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB14",
  "className": "icon-reset",
  "classes": ["icon-solid", "icon-reset"],
  "bidirectional": false,
  "deprecated": false
};
const IconReviewScreenLine = exports.IconReviewScreenLine = {
  "variant": "Line",
  "glyphName": "review-screen",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB15",
  "className": "icon-review-screen",
  "classes": ["icon-line", "icon-review-screen"],
  "bidirectional": false,
  "deprecated": false
};
const IconReviewScreenSolid = exports.IconReviewScreenSolid = {
  "variant": "Solid",
  "glyphName": "review-screen",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB15",
  "className": "icon-review-screen",
  "classes": ["icon-solid", "icon-review-screen"],
  "bidirectional": false,
  "deprecated": false
};
const IconRewindLine = exports.IconRewindLine = {
  "variant": "Line",
  "glyphName": "rewind",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB16",
  "className": "icon-rewind",
  "classes": ["icon-line", "icon-rewind"],
  "bidirectional": false,
  "deprecated": false
};
const IconRewindSolid = exports.IconRewindSolid = {
  "variant": "Solid",
  "glyphName": "rewind",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB16",
  "className": "icon-rewind",
  "classes": ["icon-solid", "icon-rewind"],
  "bidirectional": false,
  "deprecated": false
};
const IconRotateLeftLine = exports.IconRotateLeftLine = {
  "variant": "Line",
  "glyphName": "rotate-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB17",
  "className": "icon-rotate-left",
  "classes": ["icon-line", "icon-rotate-left"],
  "bidirectional": false,
  "deprecated": false
};
const IconRotateLeftSolid = exports.IconRotateLeftSolid = {
  "variant": "Solid",
  "glyphName": "rotate-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB17",
  "className": "icon-rotate-left",
  "classes": ["icon-solid", "icon-rotate-left"],
  "bidirectional": false,
  "deprecated": false
};
const IconRotateRightLine = exports.IconRotateRightLine = {
  "variant": "Line",
  "glyphName": "rotate-right",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB18",
  "className": "icon-rotate-right",
  "classes": ["icon-line", "icon-rotate-right"],
  "bidirectional": false,
  "deprecated": false
};
const IconRotateRightSolid = exports.IconRotateRightSolid = {
  "variant": "Solid",
  "glyphName": "rotate-right",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB18",
  "className": "icon-rotate-right",
  "classes": ["icon-solid", "icon-rotate-right"],
  "bidirectional": false,
  "deprecated": false
};
const IconRssAddLine = exports.IconRssAddLine = {
  "variant": "Line",
  "glyphName": "rss-add",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB19",
  "className": "icon-rss-add",
  "classes": ["icon-line", "icon-rss-add"],
  "bidirectional": false,
  "deprecated": true
};
const IconRssAddSolid = exports.IconRssAddSolid = {
  "variant": "Solid",
  "glyphName": "rss-add",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB19",
  "className": "icon-rss-add",
  "classes": ["icon-solid", "icon-rss-add"],
  "bidirectional": false,
  "deprecated": true
};
const IconRssLine = exports.IconRssLine = {
  "variant": "Line",
  "glyphName": "rss",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB1A",
  "className": "icon-rss",
  "classes": ["icon-line", "icon-rss"],
  "bidirectional": false,
  "deprecated": false
};
const IconRssSolid = exports.IconRssSolid = {
  "variant": "Solid",
  "glyphName": "rss",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB1A",
  "className": "icon-rss",
  "classes": ["icon-solid", "icon-rss"],
  "bidirectional": false,
  "deprecated": false
};
const IconRubricDarkLine = exports.IconRubricDarkLine = {
  "variant": "Line",
  "glyphName": "rubric-dark",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB1B",
  "className": "icon-rubric-dark",
  "classes": ["icon-line", "icon-rubric-dark"],
  "bidirectional": true,
  "deprecated": false
};
const IconRubricDarkSolid = exports.IconRubricDarkSolid = {
  "variant": "Solid",
  "glyphName": "rubric-dark",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB1B",
  "className": "icon-rubric-dark",
  "classes": ["icon-solid", "icon-rubric-dark"],
  "bidirectional": true,
  "deprecated": false
};
const IconRubricLine = exports.IconRubricLine = {
  "variant": "Line",
  "glyphName": "rubric",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB1C",
  "className": "icon-rubric",
  "classes": ["icon-line", "icon-rubric"],
  "bidirectional": true,
  "deprecated": false
};
const IconRubricSolid = exports.IconRubricSolid = {
  "variant": "Solid",
  "glyphName": "rubric",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB1C",
  "className": "icon-rubric",
  "classes": ["icon-solid", "icon-rubric"],
  "bidirectional": true,
  "deprecated": false
};
const IconRulerLine = exports.IconRulerLine = {
  "variant": "Line",
  "glyphName": "ruler",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB1D",
  "className": "icon-ruler",
  "classes": ["icon-line", "icon-ruler"],
  "bidirectional": false,
  "deprecated": false
};
const IconRulerSolid = exports.IconRulerSolid = {
  "variant": "Solid",
  "glyphName": "ruler",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB1D",
  "className": "icon-ruler",
  "classes": ["icon-solid", "icon-ruler"],
  "bidirectional": false,
  "deprecated": false
};
const IconSaveLine = exports.IconSaveLine = {
  "variant": "Line",
  "glyphName": "save",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB1E",
  "className": "icon-save",
  "classes": ["icon-line", "icon-save"],
  "bidirectional": false,
  "deprecated": false
};
const IconSaveSolid = exports.IconSaveSolid = {
  "variant": "Solid",
  "glyphName": "save",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB1E",
  "className": "icon-save",
  "classes": ["icon-solid", "icon-save"],
  "bidirectional": false,
  "deprecated": false
};
const IconScreenCaptureLine = exports.IconScreenCaptureLine = {
  "variant": "Line",
  "glyphName": "screen-capture",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB1F",
  "className": "icon-screen-capture",
  "classes": ["icon-line", "icon-screen-capture"],
  "bidirectional": false,
  "deprecated": false
};
const IconScreenCaptureSolid = exports.IconScreenCaptureSolid = {
  "variant": "Solid",
  "glyphName": "screen-capture",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB1F",
  "className": "icon-screen-capture",
  "classes": ["icon-solid", "icon-screen-capture"],
  "bidirectional": false,
  "deprecated": false
};
const IconSearchAddressBookLine = exports.IconSearchAddressBookLine = {
  "variant": "Line",
  "glyphName": "search-address-book",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB20",
  "className": "icon-search-address-book",
  "classes": ["icon-line", "icon-search-address-book"],
  "bidirectional": false,
  "deprecated": true
};
const IconSearchAddressBookSolid = exports.IconSearchAddressBookSolid = {
  "variant": "Solid",
  "glyphName": "search-address-book",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB20",
  "className": "icon-search-address-book",
  "classes": ["icon-solid", "icon-search-address-book"],
  "bidirectional": false,
  "deprecated": true
};
const IconSearchAiLine = exports.IconSearchAiLine = {
  "variant": "Line",
  "glyphName": "search-ai",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB21",
  "className": "icon-search-ai",
  "classes": ["icon-line", "icon-search-ai"],
  "bidirectional": false,
  "deprecated": false
};
const IconSearchAiSolid = exports.IconSearchAiSolid = {
  "variant": "Solid",
  "glyphName": "search-ai",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB21",
  "className": "icon-search-ai",
  "classes": ["icon-solid", "icon-search-ai"],
  "bidirectional": false,
  "deprecated": false
};
const IconSearchLine = exports.IconSearchLine = {
  "variant": "Line",
  "glyphName": "search",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB22",
  "className": "icon-search",
  "classes": ["icon-line", "icon-search"],
  "bidirectional": false,
  "deprecated": false
};
const IconSearchSolid = exports.IconSearchSolid = {
  "variant": "Solid",
  "glyphName": "search",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB22",
  "className": "icon-search",
  "classes": ["icon-solid", "icon-search"],
  "bidirectional": false,
  "deprecated": false
};
const IconSettings2Line = exports.IconSettings2Line = {
  "variant": "Line",
  "glyphName": "settings-2",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB23",
  "className": "icon-settings-2",
  "classes": ["icon-line", "icon-settings-2"],
  "bidirectional": false,
  "deprecated": true
};
const IconSettings2Solid = exports.IconSettings2Solid = {
  "variant": "Solid",
  "glyphName": "settings-2",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB23",
  "className": "icon-settings-2",
  "classes": ["icon-solid", "icon-settings-2"],
  "bidirectional": false,
  "deprecated": true
};
const IconSettingsLine = exports.IconSettingsLine = {
  "variant": "Line",
  "glyphName": "settings",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB24",
  "className": "icon-settings",
  "classes": ["icon-line", "icon-settings"],
  "bidirectional": false,
  "deprecated": false
};
const IconSettingsSolid = exports.IconSettingsSolid = {
  "variant": "Solid",
  "glyphName": "settings",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB24",
  "className": "icon-settings",
  "classes": ["icon-solid", "icon-settings"],
  "bidirectional": false,
  "deprecated": false
};
const IconShapeOvalLine = exports.IconShapeOvalLine = {
  "variant": "Line",
  "glyphName": "shape-oval",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB25",
  "className": "icon-shape-oval",
  "classes": ["icon-line", "icon-shape-oval"],
  "bidirectional": false,
  "deprecated": false
};
const IconShapeOvalSolid = exports.IconShapeOvalSolid = {
  "variant": "Solid",
  "glyphName": "shape-oval",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB25",
  "className": "icon-shape-oval",
  "classes": ["icon-solid", "icon-shape-oval"],
  "bidirectional": false,
  "deprecated": false
};
const IconShapePolygonLine = exports.IconShapePolygonLine = {
  "variant": "Line",
  "glyphName": "shape-polygon",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB26",
  "className": "icon-shape-polygon",
  "classes": ["icon-line", "icon-shape-polygon"],
  "bidirectional": false,
  "deprecated": false
};
const IconShapePolygonSolid = exports.IconShapePolygonSolid = {
  "variant": "Solid",
  "glyphName": "shape-polygon",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB26",
  "className": "icon-shape-polygon",
  "classes": ["icon-solid", "icon-shape-polygon"],
  "bidirectional": false,
  "deprecated": false
};
const IconShapeRectangleLine = exports.IconShapeRectangleLine = {
  "variant": "Line",
  "glyphName": "shape-rectangle",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB27",
  "className": "icon-shape-rectangle",
  "classes": ["icon-line", "icon-shape-rectangle"],
  "bidirectional": false,
  "deprecated": false
};
const IconShapeRectangleSolid = exports.IconShapeRectangleSolid = {
  "variant": "Solid",
  "glyphName": "shape-rectangle",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB27",
  "className": "icon-shape-rectangle",
  "classes": ["icon-solid", "icon-shape-rectangle"],
  "bidirectional": false,
  "deprecated": false
};
const IconShareLine = exports.IconShareLine = {
  "variant": "Line",
  "glyphName": "share",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB28",
  "className": "icon-share",
  "classes": ["icon-line", "icon-share"],
  "bidirectional": false,
  "deprecated": false
};
const IconShareSolid = exports.IconShareSolid = {
  "variant": "Solid",
  "glyphName": "share",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB28",
  "className": "icon-share",
  "classes": ["icon-solid", "icon-share"],
  "bidirectional": false,
  "deprecated": false
};
const IconSingleMetricLine = exports.IconSingleMetricLine = {
  "variant": "Line",
  "glyphName": "single-metric",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB29",
  "className": "icon-single-metric",
  "classes": ["icon-line", "icon-single-metric"],
  "bidirectional": false,
  "deprecated": false
};
const IconSingleMetricSolid = exports.IconSingleMetricSolid = {
  "variant": "Solid",
  "glyphName": "single-metric",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB29",
  "className": "icon-single-metric",
  "classes": ["icon-solid", "icon-single-metric"],
  "bidirectional": false,
  "deprecated": false
};
const IconSisImportedLine = exports.IconSisImportedLine = {
  "variant": "Line",
  "glyphName": "sis-imported",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB2A",
  "className": "icon-sis-imported",
  "classes": ["icon-line", "icon-sis-imported"],
  "bidirectional": true,
  "deprecated": false
};
const IconSisImportedSolid = exports.IconSisImportedSolid = {
  "variant": "Solid",
  "glyphName": "sis-imported",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB2A",
  "className": "icon-sis-imported",
  "classes": ["icon-solid", "icon-sis-imported"],
  "bidirectional": true,
  "deprecated": false
};
const IconSisNotSyncedLine = exports.IconSisNotSyncedLine = {
  "variant": "Line",
  "glyphName": "sis-not-synced",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB2B",
  "className": "icon-sis-not-synced",
  "classes": ["icon-line", "icon-sis-not-synced"],
  "bidirectional": false,
  "deprecated": false
};
const IconSisNotSyncedSolid = exports.IconSisNotSyncedSolid = {
  "variant": "Solid",
  "glyphName": "sis-not-synced",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB2B",
  "className": "icon-sis-not-synced",
  "classes": ["icon-solid", "icon-sis-not-synced"],
  "bidirectional": false,
  "deprecated": false
};
const IconSisSyncedLine = exports.IconSisSyncedLine = {
  "variant": "Line",
  "glyphName": "sis-synced",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB2C",
  "className": "icon-sis-synced",
  "classes": ["icon-line", "icon-sis-synced"],
  "bidirectional": false,
  "deprecated": false
};
const IconSisSyncedSolid = exports.IconSisSyncedSolid = {
  "variant": "Solid",
  "glyphName": "sis-synced",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB2C",
  "className": "icon-sis-synced",
  "classes": ["icon-solid", "icon-sis-synced"],
  "bidirectional": false,
  "deprecated": false
};
const IconSkypeLine = exports.IconSkypeLine = {
  "variant": "Line",
  "glyphName": "skype",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB2D",
  "className": "icon-skype",
  "classes": ["icon-line", "icon-skype"],
  "bidirectional": false,
  "deprecated": false
};
const IconSkypeSolid = exports.IconSkypeSolid = {
  "variant": "Solid",
  "glyphName": "skype",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB2D",
  "className": "icon-skype",
  "classes": ["icon-solid", "icon-skype"],
  "bidirectional": false,
  "deprecated": false
};
const IconSortLine = exports.IconSortLine = {
  "variant": "Line",
  "glyphName": "sort",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB2E",
  "className": "icon-sort",
  "classes": ["icon-line", "icon-sort"],
  "bidirectional": false,
  "deprecated": false
};
const IconSortSolid = exports.IconSortSolid = {
  "variant": "Solid",
  "glyphName": "sort",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB2E",
  "className": "icon-sort",
  "classes": ["icon-solid", "icon-sort"],
  "bidirectional": false,
  "deprecated": false
};
const IconSpeedGraderLine = exports.IconSpeedGraderLine = {
  "variant": "Line",
  "glyphName": "speed-grader",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB2F",
  "className": "icon-speed-grader",
  "classes": ["icon-line", "icon-speed-grader"],
  "bidirectional": false,
  "deprecated": false
};
const IconSpeedGraderSolid = exports.IconSpeedGraderSolid = {
  "variant": "Solid",
  "glyphName": "speed-grader",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB2F",
  "className": "icon-speed-grader",
  "classes": ["icon-solid", "icon-speed-grader"],
  "bidirectional": false,
  "deprecated": false
};
const IconStandardsLine = exports.IconStandardsLine = {
  "variant": "Line",
  "glyphName": "standards",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB30",
  "className": "icon-standards",
  "classes": ["icon-line", "icon-standards"],
  "bidirectional": false,
  "deprecated": false
};
const IconStandardsSolid = exports.IconStandardsSolid = {
  "variant": "Solid",
  "glyphName": "standards",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB30",
  "className": "icon-standards",
  "classes": ["icon-solid", "icon-standards"],
  "bidirectional": false,
  "deprecated": false
};
const IconStarLightLine = exports.IconStarLightLine = {
  "variant": "Line",
  "glyphName": "star-light",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB31",
  "className": "icon-star-light",
  "classes": ["icon-line", "icon-star-light"],
  "bidirectional": false,
  "deprecated": false
};
const IconStarLightSolid = exports.IconStarLightSolid = {
  "variant": "Solid",
  "glyphName": "star-light",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB31",
  "className": "icon-star-light",
  "classes": ["icon-solid", "icon-star-light"],
  "bidirectional": false,
  "deprecated": false
};
const IconStarLine = exports.IconStarLine = {
  "variant": "Line",
  "glyphName": "star",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB32",
  "className": "icon-star",
  "classes": ["icon-line", "icon-star"],
  "bidirectional": false,
  "deprecated": false
};
const IconStarSolid = exports.IconStarSolid = {
  "variant": "Solid",
  "glyphName": "star",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB32",
  "className": "icon-star",
  "classes": ["icon-solid", "icon-star"],
  "bidirectional": false,
  "deprecated": false
};
const IconStatsLine = exports.IconStatsLine = {
  "variant": "Line",
  "glyphName": "stats",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB33",
  "className": "icon-stats",
  "classes": ["icon-line", "icon-stats"],
  "bidirectional": false,
  "deprecated": false
};
const IconStatsSolid = exports.IconStatsSolid = {
  "variant": "Solid",
  "glyphName": "stats",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB33",
  "className": "icon-stats",
  "classes": ["icon-solid", "icon-stats"],
  "bidirectional": false,
  "deprecated": false
};
const IconStopLine = exports.IconStopLine = {
  "variant": "Line",
  "glyphName": "stop",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB34",
  "className": "icon-stop",
  "classes": ["icon-line", "icon-stop"],
  "bidirectional": false,
  "deprecated": false
};
const IconStopSolid = exports.IconStopSolid = {
  "variant": "Solid",
  "glyphName": "stop",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB34",
  "className": "icon-stop",
  "classes": ["icon-solid", "icon-stop"],
  "bidirectional": false,
  "deprecated": false
};
const IconStrikethroughLine = exports.IconStrikethroughLine = {
  "variant": "Line",
  "glyphName": "strikethrough",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB35",
  "className": "icon-strikethrough",
  "classes": ["icon-line", "icon-strikethrough"],
  "bidirectional": false,
  "deprecated": false
};
const IconStrikethroughSolid = exports.IconStrikethroughSolid = {
  "variant": "Solid",
  "glyphName": "strikethrough",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB35",
  "className": "icon-strikethrough",
  "classes": ["icon-solid", "icon-strikethrough"],
  "bidirectional": false,
  "deprecated": false
};
const IconStudentViewLine = exports.IconStudentViewLine = {
  "variant": "Line",
  "glyphName": "student-view",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB36",
  "className": "icon-student-view",
  "classes": ["icon-line", "icon-student-view"],
  "bidirectional": false,
  "deprecated": false
};
const IconStudentViewSolid = exports.IconStudentViewSolid = {
  "variant": "Solid",
  "glyphName": "student-view",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB36",
  "className": "icon-student-view",
  "classes": ["icon-solid", "icon-student-view"],
  "bidirectional": false,
  "deprecated": false
};
const IconStudioLine = exports.IconStudioLine = {
  "variant": "Line",
  "glyphName": "studio",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB37",
  "className": "icon-studio",
  "classes": ["icon-line", "icon-studio"],
  "bidirectional": false,
  "deprecated": false
};
const IconStudioSolid = exports.IconStudioSolid = {
  "variant": "Solid",
  "glyphName": "studio",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB37",
  "className": "icon-studio",
  "classes": ["icon-solid", "icon-studio"],
  "bidirectional": false,
  "deprecated": false
};
const IconSubaccountsLine = exports.IconSubaccountsLine = {
  "variant": "Line",
  "glyphName": "subaccounts",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB38",
  "className": "icon-subaccounts",
  "classes": ["icon-line", "icon-subaccounts"],
  "bidirectional": false,
  "deprecated": false
};
const IconSubaccountsSolid = exports.IconSubaccountsSolid = {
  "variant": "Solid",
  "glyphName": "subaccounts",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB38",
  "className": "icon-subaccounts",
  "classes": ["icon-solid", "icon-subaccounts"],
  "bidirectional": false,
  "deprecated": false
};
const IconSubtitlesLine = exports.IconSubtitlesLine = {
  "variant": "Line",
  "glyphName": "subtitles",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB39",
  "className": "icon-subtitles",
  "classes": ["icon-line", "icon-subtitles"],
  "bidirectional": false,
  "deprecated": false
};
const IconSubtitlesSolid = exports.IconSubtitlesSolid = {
  "variant": "Solid",
  "glyphName": "subtitles",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB39",
  "className": "icon-subtitles",
  "classes": ["icon-solid", "icon-subtitles"],
  "bidirectional": false,
  "deprecated": false
};
const IconSyllabusLine = exports.IconSyllabusLine = {
  "variant": "Line",
  "glyphName": "syllabus",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB3A",
  "className": "icon-syllabus",
  "classes": ["icon-line", "icon-syllabus"],
  "bidirectional": true,
  "deprecated": false
};
const IconSyllabusSolid = exports.IconSyllabusSolid = {
  "variant": "Solid",
  "glyphName": "syllabus",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB3A",
  "className": "icon-syllabus",
  "classes": ["icon-solid", "icon-syllabus"],
  "bidirectional": true,
  "deprecated": false
};
const IconTableCellSelectAllLine = exports.IconTableCellSelectAllLine = {
  "variant": "Line",
  "glyphName": "table-cell-select-all",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB3B",
  "className": "icon-table-cell-select-all",
  "classes": ["icon-line", "icon-table-cell-select-all"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableCellSelectAllSolid = exports.IconTableCellSelectAllSolid = {
  "variant": "Solid",
  "glyphName": "table-cell-select-all",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB3B",
  "className": "icon-table-cell-select-all",
  "classes": ["icon-solid", "icon-table-cell-select-all"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableDeleteColumnLine = exports.IconTableDeleteColumnLine = {
  "variant": "Line",
  "glyphName": "table-delete-column",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB3C",
  "className": "icon-table-delete-column",
  "classes": ["icon-line", "icon-table-delete-column"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableDeleteColumnSolid = exports.IconTableDeleteColumnSolid = {
  "variant": "Solid",
  "glyphName": "table-delete-column",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB3C",
  "className": "icon-table-delete-column",
  "classes": ["icon-solid", "icon-table-delete-column"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableDeleteRowLine = exports.IconTableDeleteRowLine = {
  "variant": "Line",
  "glyphName": "table-delete-row",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB3D",
  "className": "icon-table-delete-row",
  "classes": ["icon-line", "icon-table-delete-row"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableDeleteRowSolid = exports.IconTableDeleteRowSolid = {
  "variant": "Solid",
  "glyphName": "table-delete-row",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB3D",
  "className": "icon-table-delete-row",
  "classes": ["icon-solid", "icon-table-delete-row"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableDeleteTableLine = exports.IconTableDeleteTableLine = {
  "variant": "Line",
  "glyphName": "table-delete-table",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB3E",
  "className": "icon-table-delete-table",
  "classes": ["icon-line", "icon-table-delete-table"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableDeleteTableSolid = exports.IconTableDeleteTableSolid = {
  "variant": "Solid",
  "glyphName": "table-delete-table",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB3E",
  "className": "icon-table-delete-table",
  "classes": ["icon-solid", "icon-table-delete-table"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertColumnAfterLine = exports.IconTableInsertColumnAfterLine = {
  "variant": "Line",
  "glyphName": "table-insert-column-after",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB3F",
  "className": "icon-table-insert-column-after",
  "classes": ["icon-line", "icon-table-insert-column-after"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertColumnAfterSolid = exports.IconTableInsertColumnAfterSolid = {
  "variant": "Solid",
  "glyphName": "table-insert-column-after",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB3F",
  "className": "icon-table-insert-column-after",
  "classes": ["icon-solid", "icon-table-insert-column-after"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertColumnBeforeLine = exports.IconTableInsertColumnBeforeLine = {
  "variant": "Line",
  "glyphName": "table-insert-column-before",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB40",
  "className": "icon-table-insert-column-before",
  "classes": ["icon-line", "icon-table-insert-column-before"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertColumnBeforeSolid = exports.IconTableInsertColumnBeforeSolid = {
  "variant": "Solid",
  "glyphName": "table-insert-column-before",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB40",
  "className": "icon-table-insert-column-before",
  "classes": ["icon-solid", "icon-table-insert-column-before"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertRowAboveLine = exports.IconTableInsertRowAboveLine = {
  "variant": "Line",
  "glyphName": "table-insert-row-above",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB41",
  "className": "icon-table-insert-row-above",
  "classes": ["icon-line", "icon-table-insert-row-above"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertRowAboveSolid = exports.IconTableInsertRowAboveSolid = {
  "variant": "Solid",
  "glyphName": "table-insert-row-above",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB41",
  "className": "icon-table-insert-row-above",
  "classes": ["icon-solid", "icon-table-insert-row-above"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertRowAfterLine = exports.IconTableInsertRowAfterLine = {
  "variant": "Line",
  "glyphName": "table-insert-row-after",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB42",
  "className": "icon-table-insert-row-after",
  "classes": ["icon-line", "icon-table-insert-row-after"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableInsertRowAfterSolid = exports.IconTableInsertRowAfterSolid = {
  "variant": "Solid",
  "glyphName": "table-insert-row-after",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB42",
  "className": "icon-table-insert-row-after",
  "classes": ["icon-solid", "icon-table-insert-row-after"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableLeftHeaderLine = exports.IconTableLeftHeaderLine = {
  "variant": "Line",
  "glyphName": "table-left-header",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB43",
  "className": "icon-table-left-header",
  "classes": ["icon-line", "icon-table-left-header"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableLeftHeaderSolid = exports.IconTableLeftHeaderSolid = {
  "variant": "Solid",
  "glyphName": "table-left-header",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB43",
  "className": "icon-table-left-header",
  "classes": ["icon-solid", "icon-table-left-header"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableMergeCellsLine = exports.IconTableMergeCellsLine = {
  "variant": "Line",
  "glyphName": "table-merge-cells",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB44",
  "className": "icon-table-merge-cells",
  "classes": ["icon-line", "icon-table-merge-cells"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableMergeCellsSolid = exports.IconTableMergeCellsSolid = {
  "variant": "Solid",
  "glyphName": "table-merge-cells",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB44",
  "className": "icon-table-merge-cells",
  "classes": ["icon-solid", "icon-table-merge-cells"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableRowPropertiesLine = exports.IconTableRowPropertiesLine = {
  "variant": "Line",
  "glyphName": "table-row-properties",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB45",
  "className": "icon-table-row-properties",
  "classes": ["icon-line", "icon-table-row-properties"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableRowPropertiesSolid = exports.IconTableRowPropertiesSolid = {
  "variant": "Solid",
  "glyphName": "table-row-properties",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB45",
  "className": "icon-table-row-properties",
  "classes": ["icon-solid", "icon-table-row-properties"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableSplitCellsLine = exports.IconTableSplitCellsLine = {
  "variant": "Line",
  "glyphName": "table-split-cells",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB46",
  "className": "icon-table-split-cells",
  "classes": ["icon-line", "icon-table-split-cells"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableSplitCellsSolid = exports.IconTableSplitCellsSolid = {
  "variant": "Solid",
  "glyphName": "table-split-cells",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB46",
  "className": "icon-table-split-cells",
  "classes": ["icon-solid", "icon-table-split-cells"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableTopHeaderLine = exports.IconTableTopHeaderLine = {
  "variant": "Line",
  "glyphName": "table-top-header",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB47",
  "className": "icon-table-top-header",
  "classes": ["icon-line", "icon-table-top-header"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableTopHeaderSolid = exports.IconTableTopHeaderSolid = {
  "variant": "Solid",
  "glyphName": "table-top-header",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB47",
  "className": "icon-table-top-header",
  "classes": ["icon-solid", "icon-table-top-header"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableLine = exports.IconTableLine = {
  "variant": "Line",
  "glyphName": "table",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB48",
  "className": "icon-table",
  "classes": ["icon-line", "icon-table"],
  "bidirectional": false,
  "deprecated": false
};
const IconTableSolid = exports.IconTableSolid = {
  "variant": "Solid",
  "glyphName": "table",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB48",
  "className": "icon-table",
  "classes": ["icon-solid", "icon-table"],
  "bidirectional": false,
  "deprecated": false
};
const IconTagLine = exports.IconTagLine = {
  "variant": "Line",
  "glyphName": "tag",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB49",
  "className": "icon-tag",
  "classes": ["icon-line", "icon-tag"],
  "bidirectional": false,
  "deprecated": false
};
const IconTagSolid = exports.IconTagSolid = {
  "variant": "Solid",
  "glyphName": "tag",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB49",
  "className": "icon-tag",
  "classes": ["icon-solid", "icon-tag"],
  "bidirectional": false,
  "deprecated": false
};
const IconTargetLine = exports.IconTargetLine = {
  "variant": "Line",
  "glyphName": "target",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB4A",
  "className": "icon-target",
  "classes": ["icon-line", "icon-target"],
  "bidirectional": false,
  "deprecated": false
};
const IconTargetSolid = exports.IconTargetSolid = {
  "variant": "Solid",
  "glyphName": "target",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB4A",
  "className": "icon-target",
  "classes": ["icon-solid", "icon-target"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextBackgroundColorLine = exports.IconTextBackgroundColorLine = {
  "variant": "Line",
  "glyphName": "text-background-color",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB4B",
  "className": "icon-text-background-color",
  "classes": ["icon-line", "icon-text-background-color"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextBackgroundColorSolid = exports.IconTextBackgroundColorSolid = {
  "variant": "Solid",
  "glyphName": "text-background-color",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB4B",
  "className": "icon-text-background-color",
  "classes": ["icon-solid", "icon-text-background-color"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextCenteredLine = exports.IconTextCenteredLine = {
  "variant": "Line",
  "glyphName": "text-centered",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB4C",
  "className": "icon-text-centered",
  "classes": ["icon-line", "icon-text-centered"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextCenteredSolid = exports.IconTextCenteredSolid = {
  "variant": "Solid",
  "glyphName": "text-centered",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB4C",
  "className": "icon-text-centered",
  "classes": ["icon-solid", "icon-text-centered"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextColorLine = exports.IconTextColorLine = {
  "variant": "Line",
  "glyphName": "text-color",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB4D",
  "className": "icon-text-color",
  "classes": ["icon-line", "icon-text-color"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextColorSolid = exports.IconTextColorSolid = {
  "variant": "Solid",
  "glyphName": "text-color",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB4D",
  "className": "icon-text-color",
  "classes": ["icon-solid", "icon-text-color"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextDirectionLtrLine = exports.IconTextDirectionLtrLine = {
  "variant": "Line",
  "glyphName": "text-direction-ltr",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB4E",
  "className": "icon-text-direction-ltr",
  "classes": ["icon-line", "icon-text-direction-ltr"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextDirectionLtrSolid = exports.IconTextDirectionLtrSolid = {
  "variant": "Solid",
  "glyphName": "text-direction-ltr",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB4E",
  "className": "icon-text-direction-ltr",
  "classes": ["icon-solid", "icon-text-direction-ltr"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextDirectionRtlLine = exports.IconTextDirectionRtlLine = {
  "variant": "Line",
  "glyphName": "text-direction-rtl",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB4F",
  "className": "icon-text-direction-rtl",
  "classes": ["icon-line", "icon-text-direction-rtl"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextDirectionRtlSolid = exports.IconTextDirectionRtlSolid = {
  "variant": "Solid",
  "glyphName": "text-direction-rtl",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB4F",
  "className": "icon-text-direction-rtl",
  "classes": ["icon-solid", "icon-text-direction-rtl"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextEndLine = exports.IconTextEndLine = {
  "variant": "Line",
  "glyphName": "text-end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB50",
  "className": "icon-text-end",
  "classes": ["icon-line", "icon-text-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconTextEndSolid = exports.IconTextEndSolid = {
  "variant": "Solid",
  "glyphName": "text-end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB50",
  "className": "icon-text-end",
  "classes": ["icon-solid", "icon-text-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconTextLeftLine = exports.IconTextLeftLine = {
  "variant": "Line",
  "glyphName": "text-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB51",
  "className": "icon-text-left",
  "classes": ["icon-line", "icon-text-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconTextLeftSolid = exports.IconTextLeftSolid = {
  "variant": "Solid",
  "glyphName": "text-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB51",
  "className": "icon-text-left",
  "classes": ["icon-solid", "icon-text-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconTextRightLine = exports.IconTextRightLine = {
  "variant": "Line",
  "glyphName": "text-right",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB52",
  "className": "icon-text-right",
  "classes": ["icon-line", "icon-text-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconTextRightSolid = exports.IconTextRightSolid = {
  "variant": "Solid",
  "glyphName": "text-right",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB52",
  "className": "icon-text-right",
  "classes": ["icon-solid", "icon-text-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconTextStartLine = exports.IconTextStartLine = {
  "variant": "Line",
  "glyphName": "text-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB53",
  "className": "icon-text-start",
  "classes": ["icon-line", "icon-text-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconTextStartSolid = exports.IconTextStartSolid = {
  "variant": "Solid",
  "glyphName": "text-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB53",
  "className": "icon-text-start",
  "classes": ["icon-solid", "icon-text-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconTextSubscriptLine = exports.IconTextSubscriptLine = {
  "variant": "Line",
  "glyphName": "text-subscript",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB54",
  "className": "icon-text-subscript",
  "classes": ["icon-line", "icon-text-subscript"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextSubscriptSolid = exports.IconTextSubscriptSolid = {
  "variant": "Solid",
  "glyphName": "text-subscript",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB54",
  "className": "icon-text-subscript",
  "classes": ["icon-solid", "icon-text-subscript"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextSuperscriptLine = exports.IconTextSuperscriptLine = {
  "variant": "Line",
  "glyphName": "text-superscript",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB55",
  "className": "icon-text-superscript",
  "classes": ["icon-line", "icon-text-superscript"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextSuperscriptSolid = exports.IconTextSuperscriptSolid = {
  "variant": "Solid",
  "glyphName": "text-superscript",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB55",
  "className": "icon-text-superscript",
  "classes": ["icon-solid", "icon-text-superscript"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextLine = exports.IconTextLine = {
  "variant": "Line",
  "glyphName": "text",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB56",
  "className": "icon-text",
  "classes": ["icon-line", "icon-text"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextSolid = exports.IconTextSolid = {
  "variant": "Solid",
  "glyphName": "text",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB56",
  "className": "icon-text",
  "classes": ["icon-solid", "icon-text"],
  "bidirectional": false,
  "deprecated": false
};
const IconTextareaLine = exports.IconTextareaLine = {
  "variant": "Line",
  "glyphName": "textarea",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB57",
  "className": "icon-textarea",
  "classes": ["icon-line", "icon-textarea"],
  "bidirectional": true,
  "deprecated": false
};
const IconTextareaSolid = exports.IconTextareaSolid = {
  "variant": "Solid",
  "glyphName": "textarea",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB57",
  "className": "icon-textarea",
  "classes": ["icon-solid", "icon-textarea"],
  "bidirectional": true,
  "deprecated": false
};
const IconTimerLine = exports.IconTimerLine = {
  "variant": "Line",
  "glyphName": "timer",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB58",
  "className": "icon-timer",
  "classes": ["icon-line", "icon-timer"],
  "bidirectional": false,
  "deprecated": false
};
const IconTimerSolid = exports.IconTimerSolid = {
  "variant": "Solid",
  "glyphName": "timer",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB58",
  "className": "icon-timer",
  "classes": ["icon-solid", "icon-timer"],
  "bidirectional": false,
  "deprecated": false
};
const IconToggleEndLine = exports.IconToggleEndLine = {
  "variant": "Line",
  "glyphName": "toggle-end",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB59",
  "className": "icon-toggle-end",
  "classes": ["icon-line", "icon-toggle-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconToggleEndSolid = exports.IconToggleEndSolid = {
  "variant": "Solid",
  "glyphName": "toggle-end",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB59",
  "className": "icon-toggle-end",
  "classes": ["icon-solid", "icon-toggle-end"],
  "bidirectional": true,
  "deprecated": false
};
const IconToggleLeftLine = exports.IconToggleLeftLine = {
  "variant": "Line",
  "glyphName": "toggle-left",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB5A",
  "className": "icon-toggle-left",
  "classes": ["icon-line", "icon-toggle-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconToggleLeftSolid = exports.IconToggleLeftSolid = {
  "variant": "Solid",
  "glyphName": "toggle-left",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB5A",
  "className": "icon-toggle-left",
  "classes": ["icon-solid", "icon-toggle-left"],
  "bidirectional": true,
  "deprecated": true
};
const IconToggleRightLine = exports.IconToggleRightLine = {
  "variant": "Line",
  "glyphName": "toggle-right",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB5B",
  "className": "icon-toggle-right",
  "classes": ["icon-line", "icon-toggle-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconToggleRightSolid = exports.IconToggleRightSolid = {
  "variant": "Solid",
  "glyphName": "toggle-right",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB5B",
  "className": "icon-toggle-right",
  "classes": ["icon-solid", "icon-toggle-right"],
  "bidirectional": true,
  "deprecated": true
};
const IconToggleStartLine = exports.IconToggleStartLine = {
  "variant": "Line",
  "glyphName": "toggle-start",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB5C",
  "className": "icon-toggle-start",
  "classes": ["icon-line", "icon-toggle-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconToggleStartSolid = exports.IconToggleStartSolid = {
  "variant": "Solid",
  "glyphName": "toggle-start",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB5C",
  "className": "icon-toggle-start",
  "classes": ["icon-solid", "icon-toggle-start"],
  "bidirectional": true,
  "deprecated": false
};
const IconTrashLine = exports.IconTrashLine = {
  "variant": "Line",
  "glyphName": "trash",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB5D",
  "className": "icon-trash",
  "classes": ["icon-line", "icon-trash"],
  "bidirectional": false,
  "deprecated": false
};
const IconTrashSolid = exports.IconTrashSolid = {
  "variant": "Solid",
  "glyphName": "trash",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB5D",
  "className": "icon-trash",
  "classes": ["icon-solid", "icon-trash"],
  "bidirectional": false,
  "deprecated": false
};
const IconTroubleLine = exports.IconTroubleLine = {
  "variant": "Line",
  "glyphName": "trouble",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB5E",
  "className": "icon-trouble",
  "classes": ["icon-line", "icon-trouble"],
  "bidirectional": false,
  "deprecated": false
};
const IconTroubleSolid = exports.IconTroubleSolid = {
  "variant": "Solid",
  "glyphName": "trouble",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB5E",
  "className": "icon-trouble",
  "classes": ["icon-solid", "icon-trouble"],
  "bidirectional": false,
  "deprecated": false
};
const IconTwitterBoxedLine = exports.IconTwitterBoxedLine = {
  "variant": "Line",
  "glyphName": "twitter-boxed",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB5F",
  "className": "icon-twitter-boxed",
  "classes": ["icon-line", "icon-twitter-boxed"],
  "bidirectional": false,
  "deprecated": true
};
const IconTwitterBoxedSolid = exports.IconTwitterBoxedSolid = {
  "variant": "Solid",
  "glyphName": "twitter-boxed",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB5F",
  "className": "icon-twitter-boxed",
  "classes": ["icon-solid", "icon-twitter-boxed"],
  "bidirectional": false,
  "deprecated": true
};
const IconTwitterLine = exports.IconTwitterLine = {
  "variant": "Line",
  "glyphName": "twitter",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB60",
  "className": "icon-twitter",
  "classes": ["icon-line", "icon-twitter"],
  "bidirectional": false,
  "deprecated": false
};
const IconTwitterSolid = exports.IconTwitterSolid = {
  "variant": "Solid",
  "glyphName": "twitter",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB60",
  "className": "icon-twitter",
  "classes": ["icon-solid", "icon-twitter"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnarchiveLine = exports.IconUnarchiveLine = {
  "variant": "Line",
  "glyphName": "unarchive",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB61",
  "className": "icon-unarchive",
  "classes": ["icon-line", "icon-unarchive"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnarchiveSolid = exports.IconUnarchiveSolid = {
  "variant": "Solid",
  "glyphName": "unarchive",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB61",
  "className": "icon-unarchive",
  "classes": ["icon-solid", "icon-unarchive"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnderlineLine = exports.IconUnderlineLine = {
  "variant": "Line",
  "glyphName": "underline",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB62",
  "className": "icon-underline",
  "classes": ["icon-line", "icon-underline"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnderlineSolid = exports.IconUnderlineSolid = {
  "variant": "Solid",
  "glyphName": "underline",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB62",
  "className": "icon-underline",
  "classes": ["icon-solid", "icon-underline"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnlockLine = exports.IconUnlockLine = {
  "variant": "Line",
  "glyphName": "unlock",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB63",
  "className": "icon-unlock",
  "classes": ["icon-line", "icon-unlock"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnlockSolid = exports.IconUnlockSolid = {
  "variant": "Solid",
  "glyphName": "unlock",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB63",
  "className": "icon-unlock",
  "classes": ["icon-solid", "icon-unlock"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnmutedLine = exports.IconUnmutedLine = {
  "variant": "Line",
  "glyphName": "unmuted",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB64",
  "className": "icon-unmuted",
  "classes": ["icon-line", "icon-unmuted"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnmutedSolid = exports.IconUnmutedSolid = {
  "variant": "Solid",
  "glyphName": "unmuted",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB64",
  "className": "icon-unmuted",
  "classes": ["icon-solid", "icon-unmuted"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnpublishLine = exports.IconUnpublishLine = {
  "variant": "Line",
  "glyphName": "unpublish",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB65",
  "className": "icon-unpublish",
  "classes": ["icon-line", "icon-unpublish"],
  "bidirectional": false,
  "deprecated": true
};
const IconUnpublishSolid = exports.IconUnpublishSolid = {
  "variant": "Solid",
  "glyphName": "unpublish",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB65",
  "className": "icon-unpublish",
  "classes": ["icon-solid", "icon-unpublish"],
  "bidirectional": false,
  "deprecated": true
};
const IconUnpublishedLine = exports.IconUnpublishedLine = {
  "variant": "Line",
  "glyphName": "unpublished",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB66",
  "className": "icon-unpublished",
  "classes": ["icon-line", "icon-unpublished"],
  "bidirectional": false,
  "deprecated": false
};
const IconUnpublishedSolid = exports.IconUnpublishedSolid = {
  "variant": "Solid",
  "glyphName": "unpublished",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB66",
  "className": "icon-unpublished",
  "classes": ["icon-solid", "icon-unpublished"],
  "bidirectional": false,
  "deprecated": false
};
const IconUpdownLine = exports.IconUpdownLine = {
  "variant": "Line",
  "glyphName": "updown",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB67",
  "className": "icon-updown",
  "classes": ["icon-line", "icon-updown"],
  "bidirectional": false,
  "deprecated": false
};
const IconUpdownSolid = exports.IconUpdownSolid = {
  "variant": "Solid",
  "glyphName": "updown",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB67",
  "className": "icon-updown",
  "classes": ["icon-solid", "icon-updown"],
  "bidirectional": false,
  "deprecated": false
};
const IconUploadLine = exports.IconUploadLine = {
  "variant": "Line",
  "glyphName": "upload",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB68",
  "className": "icon-upload",
  "classes": ["icon-line", "icon-upload"],
  "bidirectional": false,
  "deprecated": false
};
const IconUploadSolid = exports.IconUploadSolid = {
  "variant": "Solid",
  "glyphName": "upload",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB68",
  "className": "icon-upload",
  "classes": ["icon-solid", "icon-upload"],
  "bidirectional": false,
  "deprecated": false
};
const IconUserAddLine = exports.IconUserAddLine = {
  "variant": "Line",
  "glyphName": "user-add",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB69",
  "className": "icon-user-add",
  "classes": ["icon-line", "icon-user-add"],
  "bidirectional": false,
  "deprecated": true
};
const IconUserAddSolid = exports.IconUserAddSolid = {
  "variant": "Solid",
  "glyphName": "user-add",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB69",
  "className": "icon-user-add",
  "classes": ["icon-solid", "icon-user-add"],
  "bidirectional": false,
  "deprecated": true
};
const IconUserLine = exports.IconUserLine = {
  "variant": "Line",
  "glyphName": "user",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB6A",
  "className": "icon-user",
  "classes": ["icon-line", "icon-user"],
  "bidirectional": false,
  "deprecated": false
};
const IconUserSolid = exports.IconUserSolid = {
  "variant": "Solid",
  "glyphName": "user",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB6A",
  "className": "icon-user",
  "classes": ["icon-solid", "icon-user"],
  "bidirectional": false,
  "deprecated": false
};
const IconVideoCameraOffLine = exports.IconVideoCameraOffLine = {
  "variant": "Line",
  "glyphName": "video-camera-off",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB6B",
  "className": "icon-video-camera-off",
  "classes": ["icon-line", "icon-video-camera-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconVideoCameraOffSolid = exports.IconVideoCameraOffSolid = {
  "variant": "Solid",
  "glyphName": "video-camera-off",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB6B",
  "className": "icon-video-camera-off",
  "classes": ["icon-solid", "icon-video-camera-off"],
  "bidirectional": false,
  "deprecated": false
};
const IconVideoCameraLine = exports.IconVideoCameraLine = {
  "variant": "Line",
  "glyphName": "video-camera",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB6C",
  "className": "icon-video-camera",
  "classes": ["icon-line", "icon-video-camera"],
  "bidirectional": false,
  "deprecated": false
};
const IconVideoCameraSolid = exports.IconVideoCameraSolid = {
  "variant": "Solid",
  "glyphName": "video-camera",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB6C",
  "className": "icon-video-camera",
  "classes": ["icon-solid", "icon-video-camera"],
  "bidirectional": false,
  "deprecated": false
};
const IconVideoLine = exports.IconVideoLine = {
  "variant": "Line",
  "glyphName": "video",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB6D",
  "className": "icon-video",
  "classes": ["icon-line", "icon-video"],
  "bidirectional": false,
  "deprecated": false
};
const IconVideoSolid = exports.IconVideoSolid = {
  "variant": "Solid",
  "glyphName": "video",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB6D",
  "className": "icon-video",
  "classes": ["icon-solid", "icon-video"],
  "bidirectional": false,
  "deprecated": false
};
const IconWarningBorderlessLine = exports.IconWarningBorderlessLine = {
  "variant": "Line",
  "glyphName": "warning-borderless",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB6E",
  "className": "icon-warning-borderless",
  "classes": ["icon-line", "icon-warning-borderless"],
  "bidirectional": false,
  "deprecated": false
};
const IconWarningBorderlessSolid = exports.IconWarningBorderlessSolid = {
  "variant": "Solid",
  "glyphName": "warning-borderless",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB6E",
  "className": "icon-warning-borderless",
  "classes": ["icon-solid", "icon-warning-borderless"],
  "bidirectional": false,
  "deprecated": false
};
const IconWarningLine = exports.IconWarningLine = {
  "variant": "Line",
  "glyphName": "warning",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB6F",
  "className": "icon-warning",
  "classes": ["icon-line", "icon-warning"],
  "bidirectional": false,
  "deprecated": false
};
const IconWarningSolid = exports.IconWarningSolid = {
  "variant": "Solid",
  "glyphName": "warning",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB6F",
  "className": "icon-warning",
  "classes": ["icon-solid", "icon-warning"],
  "bidirectional": false,
  "deprecated": false
};
const IconWindowsLine = exports.IconWindowsLine = {
  "variant": "Line",
  "glyphName": "windows",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB70",
  "className": "icon-windows",
  "classes": ["icon-line", "icon-windows"],
  "bidirectional": false,
  "deprecated": false
};
const IconWindowsSolid = exports.IconWindowsSolid = {
  "variant": "Solid",
  "glyphName": "windows",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB70",
  "className": "icon-windows",
  "classes": ["icon-solid", "icon-windows"],
  "bidirectional": false,
  "deprecated": false
};
const IconWordpressLine = exports.IconWordpressLine = {
  "variant": "Line",
  "glyphName": "wordpress",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB71",
  "className": "icon-wordpress",
  "classes": ["icon-line", "icon-wordpress"],
  "bidirectional": false,
  "deprecated": false
};
const IconWordpressSolid = exports.IconWordpressSolid = {
  "variant": "Solid",
  "glyphName": "wordpress",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB71",
  "className": "icon-wordpress",
  "classes": ["icon-solid", "icon-wordpress"],
  "bidirectional": false,
  "deprecated": false
};
const IconXLine = exports.IconXLine = {
  "variant": "Line",
  "glyphName": "x",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB72",
  "className": "icon-x",
  "classes": ["icon-line", "icon-x"],
  "bidirectional": false,
  "deprecated": false
};
const IconXSolid = exports.IconXSolid = {
  "variant": "Solid",
  "glyphName": "x",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB72",
  "className": "icon-x",
  "classes": ["icon-solid", "icon-x"],
  "bidirectional": false,
  "deprecated": false
};
const IconZippedLine = exports.IconZippedLine = {
  "variant": "Line",
  "glyphName": "zipped",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB73",
  "className": "icon-zipped",
  "classes": ["icon-line", "icon-zipped"],
  "bidirectional": false,
  "deprecated": false
};
const IconZippedSolid = exports.IconZippedSolid = {
  "variant": "Solid",
  "glyphName": "zipped",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB73",
  "className": "icon-zipped",
  "classes": ["icon-solid", "icon-zipped"],
  "bidirectional": false,
  "deprecated": false
};
const IconZoomInLine = exports.IconZoomInLine = {
  "variant": "Line",
  "glyphName": "zoom-in",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB74",
  "className": "icon-zoom-in",
  "classes": ["icon-line", "icon-zoom-in"],
  "bidirectional": false,
  "deprecated": false
};
const IconZoomInSolid = exports.IconZoomInSolid = {
  "variant": "Solid",
  "glyphName": "zoom-in",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB74",
  "className": "icon-zoom-in",
  "classes": ["icon-solid", "icon-zoom-in"],
  "bidirectional": false,
  "deprecated": false
};
const IconZoomOutLine = exports.IconZoomOutLine = {
  "variant": "Line",
  "glyphName": "zoom-out",
  "cssFile": "InstructureIcons-Line.css",
  "codepoint": "EB75",
  "className": "icon-zoom-out",
  "classes": ["icon-line", "icon-zoom-out"],
  "bidirectional": false,
  "deprecated": false
};
const IconZoomOutSolid = exports.IconZoomOutSolid = {
  "variant": "Solid",
  "glyphName": "zoom-out",
  "cssFile": "InstructureIcons-Solid.css",
  "codepoint": "EB75",
  "className": "icon-zoom-out",
  "classes": ["icon-solid", "icon-zoom-out"],
  "bidirectional": false,
  "deprecated": false
};
