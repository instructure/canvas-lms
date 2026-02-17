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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ProblemArea} from './ProblemArea/ProblemArea'
import {PreviewHandle} from './Preview'
import {AccessibilityIssue, AccessibilityResourceScan} from '../../types'
import {Grid, GridArea} from '../Grid'

const I18n = createI18nScope('accessibility_checker')

interface ProblemAreaAndIssueDescriptionSectionProps {
  previewRef: React.RefObject<PreviewHandle>
  selectedScan: AccessibilityResourceScan
  selectedIssue: AccessibilityIssue
  onOpenPage: () => void
  onEditPage: () => void
}

/**
 * ProblemAreaAndIssueDescriptionSection Component
 *
 * Displays the problem area and issue description with action links.
 *
 * ACCESSIBILITY REQUIREMENTS:
 * ===========================
 * The DOM order MUST follow this sequence for proper screen reader navigation:
 * 1. "Problem area" heading
 * 2. ProblemArea component (the actual content with the issue)
 * 3. "Issue description" heading
 * 4. Issue description text
 * 5. "Open Page" link
 * 6. "Edit Page" link
 *
 * VISUAL LAYOUT:
 * ==============
 * Despite the DOM order above, the visual layout displays:
 * - Row 1: "Problem area" heading (left) | Action links (right)
 * - Row 2: ProblemArea component (full width)
 * - Row 3: "Issue description" heading (full width)
 * - Row 4: Issue description text (full width)
 *
 * IMPLEMENTATION:
 * ==============
 * - Uses CSS Grid with named template areas:
 *     "heading actions"
 *     "content content"
 *     "desc-heading desc-heading"
 *     "desc-text desc-text"
 * - Each element is assigned to its grid area via grid-area property
 * - This creates the correct visual layout while maintaining proper DOM/tab order
 */
export const ProblemAreaAndIssueDescriptionSection = ({
  previewRef,
  selectedScan,
  selectedIssue,
  onOpenPage,
  onEditPage,
}: ProblemAreaAndIssueDescriptionSectionProps) => {
  return (
    <Grid
      templateColumns="1fr auto"
      templateAreas={`
        "heading actions"
        "content content"
        "desc-heading desc-heading"
        "desc-text desc-text"
      `}
      rowGap="0.5rem"
      alignItems="baseline"
    >
      <GridArea area="heading">
        <Heading level="h4" variant="titleCardMini">
          {I18n.t('Problem area')}
        </Heading>
      </GridArea>

      <GridArea area="content">
        <ProblemArea previewRef={previewRef} item={selectedScan} issue={selectedIssue} />
      </GridArea>

      <GridArea area="desc-heading" additionalStyles={{marginTop: '0.5rem'}}>
        <Heading level="h4" variant="titleCardMini">
          {I18n.t('Issue description')}
        </Heading>
      </GridArea>

      <GridArea area="desc-text">
        <Text weight="weightRegular">{selectedIssue.message}</Text>
      </GridArea>

      <GridArea area="actions" additionalStyles={{justifySelf: 'end'}}>
        <Flex gap="small">
          <Link
            href={selectedScan?.resourceUrl}
            variant="standalone"
            target="_blank"
            iconPlacement="end"
            renderIcon={<IconExternalLinkLine size="x-small" />}
            onClick={onOpenPage}
          >
            {I18n.t('Open Page')}
            <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
          </Link>
          <Link
            href={
              selectedScan?.resourceType === 'Syllabus'
                ? selectedScan.resourceUrl // Syllabus is edited inline, no separate edit page
                : `${selectedScan.resourceUrl}/edit`
            }
            variant="standalone"
            target="_blank"
            iconPlacement="end"
            renderIcon={<IconExternalLinkLine size="x-small" />}
            onClick={onEditPage}
          >
            {I18n.t('Edit Page')}
            <ScreenReaderContent>{I18n.t('- Opens in a new tab.')}</ScreenReaderContent>
          </Link>
        </Flex>
      </GridArea>
    </Grid>
  )
}
