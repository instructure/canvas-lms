/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {
  IconCalendarMonthLine,
  IconEducatorsLine,
  // IconDownloadLine,
  // IconPrinterLine,
  // IconReviewScreenLine,
  // IconShareLine,
  IconStarLightLine,
} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {List} from '@instructure/ui-list'
import {SVGIcon} from '@instructure/ui-svg-images'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Tooltip} from '@instructure/ui-tooltip'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import type {AchievementData, SkillData} from '../../types'
import {renderSkillTag} from '../../shared/SkillTag'
import {showUnimplemented} from '../../shared/utils'

const icon_verified = `<svg width="12" height="16" viewBox="0 0 12 16" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M10.5611 8.74483C10.5611 10.7674 7.61901 12.3745 6.36318 13.0607C6.20134 13.1491 6.06636 13.2226 5.96742 13.2812C5.86848 13.2226 5.7335 13.1491 5.57166 13.0607C4.31583 12.3745 1.37378 10.7674 1.37378 8.74483V4.73776L5.96742 2.76886L10.5611 4.73776V8.74483ZM5.96735 2L0.666992 4.27138V8.74488C0.666992 11.1866 3.86699 12.935 5.23307 13.6813C5.4048 13.7753 5.54402 13.8509 5.63943 13.9081V13.9088C5.74049 13.9696 5.85356 14 5.96735 14C6.08042 14 6.1942 13.9696 6.29526 13.9081C6.39067 13.8509 6.52989 13.7753 6.70162 13.6813C8.0677 12.935 11.2677 11.1866 11.2677 8.74488V4.27138L5.96735 2ZM3.7433 7.43494L3.24365 7.93458L5.25991 9.95154L9.04365 6.1678L8.54401 5.66815L5.25991 8.95154L3.7433 7.43494Z" fill="#0B874B"/>
<path d="M6.36318 13.0607L6.54285 13.3899L6.54299 13.3898L6.36318 13.0607ZM5.96742 13.2812L5.77618 13.6038L5.96742 13.7172L6.15866 13.6038L5.96742 13.2812ZM5.57166 13.0607L5.39184 13.3898L5.39199 13.3899L5.57166 13.0607ZM1.37378 4.73776L1.22605 4.39309L0.998779 4.4905V4.73776H1.37378ZM5.96742 2.76886L6.11515 2.42419L5.96742 2.36087L5.81969 2.42419L5.96742 2.76886ZM10.5611 4.73776H10.9361V4.4905L10.7088 4.39309L10.5611 4.73776ZM5.96735 2L6.11505 1.65532L5.96735 1.59202L5.81964 1.65532L5.96735 2ZM0.666992 4.27138L0.519284 3.92669L0.291992 4.0241V4.27138H0.666992ZM5.23307 13.6813L5.41311 13.3523L5.41285 13.3522L5.23307 13.6813ZM5.63943 13.9081H6.01443V13.6958L5.83237 13.5866L5.63943 13.9081ZM5.63943 13.9088H5.26443V14.1209L5.44616 14.2302L5.63943 13.9088ZM6.29526 13.9081L6.10232 13.5866L6.10035 13.5878L6.29526 13.9081ZM6.70162 13.6813L6.52184 13.3522L6.52158 13.3523L6.70162 13.6813ZM11.2677 4.27138H11.6427V4.0241L11.4154 3.92669L11.2677 4.27138ZM3.7433 7.43494L4.00846 7.16977L3.7433 6.90461L3.47813 7.16977L3.7433 7.43494ZM3.24365 7.93458L2.97849 7.66942L2.71337 7.93454L2.97844 8.1997L3.24365 7.93458ZM5.25991 9.95154L4.9947 10.2167L5.25986 10.4819L5.52507 10.2167L5.25991 9.95154ZM9.04365 6.1678L9.30882 6.43296L9.57398 6.1678L9.30882 5.90263L9.04365 6.1678ZM8.54401 5.66815L8.80917 5.40299L8.54403 5.13785L8.27887 5.40296L8.54401 5.66815ZM5.25991 8.95154L4.99474 9.21671L5.25988 9.48184L5.52504 9.21674L5.25991 8.95154ZM10.1861 8.74483C10.1861 9.57666 9.57178 10.3868 8.69363 11.1153C7.83281 11.8294 6.81402 12.387 6.18336 12.7317L6.54299 13.3898C7.16817 13.0482 8.24832 12.4592 9.17248 11.6925C10.0793 10.9403 10.9361 9.93562 10.9361 8.74483H10.1861ZM6.18351 12.7316C6.02449 12.8184 5.88229 12.8957 5.77618 12.9587L6.15866 13.6038C6.25043 13.5494 6.37819 13.4798 6.54285 13.3899L6.18351 12.7316ZM6.15866 12.9587C6.05255 12.8957 5.91034 12.8184 5.75133 12.7316L5.39199 13.3899C5.55665 13.4798 5.68441 13.5494 5.77618 13.6038L6.15866 12.9587ZM5.75147 12.7317C5.12082 12.387 4.10203 11.8294 3.24121 11.1153C2.36306 10.3868 1.74878 9.57666 1.74878 8.74483H0.998779C0.998779 9.93562 1.85553 10.9403 2.76236 11.6925C3.68652 12.4592 4.76667 13.0482 5.39184 13.3898L5.75147 12.7317ZM1.74878 8.74483V4.73776H0.998779V8.74483H1.74878ZM1.52151 5.08244L6.11515 3.11353L5.81969 2.42419L1.22605 4.39309L1.52151 5.08244ZM5.81969 3.11353L10.4133 5.08244L10.7088 4.39309L6.11515 2.42419L5.81969 3.11353ZM10.1861 4.73776V8.74483H10.9361V4.73776H10.1861ZM5.81964 1.65532L0.519284 3.92669L0.814701 4.61606L6.11505 2.34468L5.81964 1.65532ZM0.291992 4.27138V8.74488H1.04199V4.27138H0.291992ZM0.291992 8.74488C0.291992 10.1339 1.19835 11.2768 2.19311 12.1331C3.1979 12.998 4.37281 13.6386 5.05329 14.0104L5.41285 13.3522C4.72725 12.9776 3.61913 12.371 2.68239 11.5646C1.73564 10.7497 1.04199 9.79754 1.04199 8.74488H0.291992ZM5.05303 14.0102C5.22901 14.1065 5.35927 14.1774 5.44649 14.2297L5.83237 13.5866C5.72878 13.5244 5.58059 13.444 5.41311 13.3523L5.05303 14.0102ZM5.26443 13.9081V13.9088H6.01443V13.9081H5.26443ZM5.44616 14.2302C5.60636 14.3265 5.78638 14.375 5.96735 14.375V13.625C5.92074 13.625 5.87462 13.6127 5.8327 13.5875L5.44616 14.2302ZM5.96735 14.375C6.14747 14.375 6.32895 14.3266 6.49017 14.2285L6.10035 13.5878C6.05945 13.6126 6.01336 13.625 5.96735 13.625V14.375ZM6.4882 14.2297C6.57542 14.1774 6.70568 14.1065 6.88166 14.0102L6.52158 13.3523C6.3541 13.444 6.20591 13.5244 6.10232 13.5866L6.4882 14.2297ZM6.88141 14.0104C7.56188 13.6386 8.7368 12.998 9.74158 12.1331C10.7363 11.2768 11.6427 10.1339 11.6427 8.74488H10.8927C10.8927 9.79754 10.1991 10.7497 9.2523 11.5646C8.31556 12.371 7.20744 12.9776 6.52184 13.3522L6.88141 14.0104ZM11.6427 8.74488V4.27138H10.8927V8.74488H11.6427ZM11.4154 3.92669L6.11505 1.65532L5.81964 2.34468L11.12 4.61606L11.4154 3.92669ZM3.47813 7.16977L2.97849 7.66942L3.50882 8.19975L4.00846 7.7001L3.47813 7.16977ZM2.97844 8.1997L4.9947 10.2167L5.52512 9.68642L3.50886 7.66946L2.97844 8.1997ZM5.52507 10.2167L9.30882 6.43296L8.77849 5.90263L4.99474 9.68638L5.52507 10.2167ZM9.30882 5.90263L8.80917 5.40299L8.27884 5.93332L8.77849 6.43296L9.30882 5.90263ZM8.27887 5.40296L4.99477 8.68635L5.52504 9.21674L8.80914 5.93335L8.27887 5.40296ZM5.52507 8.68638L4.00846 7.16977L3.47813 7.7001L4.99474 9.21671L5.52507 8.68638Z" fill="currentColor"/>
</svg>`

interface AchievementTrayProps {
  activeCard?: AchievementData
  open: boolean
  onClose: () => void
}

const AchievementTray = ({activeCard, open, onClose}: AchievementTrayProps) => {
  const [trayHeadingIsTruncated, setTrayHeadingIsTruncated] = useState(false)

  const formatDate = useCallback((date: string) => {
    return new Intl.DateTimeFormat(ENV.LOCALE || 'en', {dateStyle: 'short'}).format(new Date(date))
  }, [])

  const handleTruncatedHeading = useCallback((isTruncated: boolean) => {
    setTrayHeadingIsTruncated(isTruncated)
  }, [])

  const renderTrayHeading = useCallback(() => {
    if (!activeCard) return null
    return (
      <Heading margin="0 large 0 0">
        <TruncateText onUpdate={handleTruncatedHeading}>{activeCard.title}</TruncateText>
      </Heading>
    )
  }, [activeCard, handleTruncatedHeading])

  const renderTrayHeader = useCallback(() => {
    if (!activeCard) return null

    return trayHeadingIsTruncated ? (
      <Tooltip renderTip={activeCard.title}>{renderTrayHeading()}</Tooltip>
    ) : (
      renderTrayHeading()
    )
  }, [activeCard, renderTrayHeading, trayHeadingIsTruncated])

  return (
    <Tray
      label="Achievement Details"
      open={open}
      onDismiss={onClose}
      size="regular"
      placement="end"
    >
      <Flex as="div" padding="small small small medium">
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          {renderTrayHeader()}
        </Flex.Item>
        <Flex.Item>
          <CloseButton placement="end" offset="small" screenReaderLabel="Close" onClick={onClose} />
        </Flex.Item>
      </Flex>
      <Flex
        as="div"
        margin="0 medium large medium"
        direction="column"
        justifyItems="start"
        alignItems="stretch"
      >
        {activeCard ? (
          <>
            <Flex.Item as="div" margin="0 0 small 0" align="center">
              <img
                src={activeCard.imageUrl || undefined}
                alt=""
                style={{
                  minHeight: '128px',
                  minWidth: '128px',
                  background: activeCard.imageUrl
                    ? 'none'
                    : 'repeating-linear-gradient(45deg, #cecece, #cecece 10px, #aeaeae 10px, #aeaeae 20px)',
                }}
              />
            </Flex.Item>
            {activeCard.verifiedBy && (
              <Flex.Item align="center">
                <SVGIcon src={icon_verified} size="x-small" color="success" />{' '}
                <Text size="small">
                  Verified by{' '}
                  <Link href=" https://openbadges.org/" target="_blank">
                    {activeCard.verifiedBy}
                  </Link>
                </Text>
              </Flex.Item>
            )}
            <Flex.Item align="end" margin="medium 0">
              <Button color="secondary" margin="xx-small" onClick={showUnimplemented}>
                View badge
              </Button>
              <Button color="secondary" margin="xx-small" onClick={showUnimplemented}>
                Print
              </Button>
              <Button color="secondary" margin="xx-small" onClick={showUnimplemented}>
                Download
              </Button>
              <Button color="primary" margin="xx-small" onClick={showUnimplemented}>
                Share
              </Button>
            </Flex.Item>
            <View borderWidth="small 0 0 0" borderColor="secondary" padding="medium 0">
              <List isUnstyled={true} margin="0">
                {activeCard.type && (
                  <List.Item margin="0 0 small 0">
                    <IconStarLightLine /> <Text>Award type:</Text>{' '}
                    <Text weight="bold">{activeCard.type}</Text>
                  </List.Item>
                )}
                <List.Item margin="0 0 small 0">
                  <IconCalendarMonthLine /> <Text>Issued on:</Text>{' '}
                  <Text weight="bold">{formatDate(activeCard.issuedOn)}</Text>
                </List.Item>
                {activeCard.expiresOn && (
                  <List.Item margin="0 0 small 0">
                    <IconCalendarMonthLine /> <Text>Expires on:</Text>{' '}
                    <Text weight="bold">{formatDate(activeCard.expiresOn)}</Text>
                  </List.Item>
                )}
                <List.Item margin="0 0 small 0">
                  <IconEducatorsLine /> <Text>Issued by:</Text>{' '}
                  {activeCard.issuer.iconUrl && (
                    <Img
                      src={activeCard.issuer.iconUrl}
                      alt=""
                      height="1rem"
                      margin="0 xx-small 0 0"
                    />
                  )}
                  {activeCard.issuer.url ? (
                    <Link href={activeCard.issuer.url} target="_blank">
                      <Text weight="bold">{activeCard.issuer.name}</Text>
                    </Link>
                  ) : (
                    <Text weight="bold">{activeCard.issuer.name}</Text>
                  )}
                </List.Item>
              </List>
            </View>
            {activeCard.criteria && (
              <View borderWidth="small 0 0 0" borderColor="secondary" padding="medium 0">
                <Text as="div" weight="bold">
                  Earning criteria
                </Text>
                <Text as="div">{activeCard.criteria}</Text>
              </View>
            )}
            {activeCard.skills?.length > 0 && (
              <View borderWidth="small 0 0 0" borderColor="secondary" padding="medium 0">
                <Text as="div" weight="bold">
                  Skills
                </Text>
                <SVGIcon src={icon_verified} size="x-small" color="success" />{' '}
                <Text as="span" size="x-small">
                  Verified by Lightcast
                </Text>
                <View as="div" margin="x-small 0 0 0">
                  {activeCard.skills.map((skill: SkillData) => renderSkillTag(skill))}
                </View>
              </View>
            )}
          </>
        ) : null}
      </Flex>
    </Tray>
  )
}

export default AchievementTray
