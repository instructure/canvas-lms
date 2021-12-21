import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import formatMessage from "../../../format-message.js";
import { scaleForHeight, scaleForWidth } from "../shared/DimensionUtils.js";
export const MIN_HEIGHT = 10;
export const MIN_WIDTH = 10;
export const MIN_WIDTH_VIDEO = 320;
export const MIN_PERCENTAGE = 10;
export const SMALL = 'small';
export const MEDIUM = 'medium';
export const LARGE = 'large';
export const EXTRA_LARGE = 'extra-large';
export const CUSTOM = 'custom';
export const imageSizes = ["small", "medium", "large", "extra-large", "custom"];
export const videoSizes = ["medium", "large", "extra-large", "custom"];
const sizeByMaximumDimension = {
  200: "small",
  320: "medium",
  400: "large",
  640: "extra-large"
};

function parsedOrNull($element, attribute) {
  // when the image is first inserted into the rce, it's size
  // is constrained by a style attribute with max-width, max-height.
  // While it doesn't have a 'width' or 'height' attribute, we can
  // still get its width and height directly from the img element
  const value = $element.hasAttribute(attribute) ? $element.getAttribute(attribute) : $element[attribute];
  return value ? Math.round(Number.parseInt(value, 10)) : null;
}

function imageSizeFromKnownOptions(imageOptions) {
  const intendedWidth = imageOptions.appliedWidth || imageOptions.naturalWidth;
  const intendedHeight = imageOptions.appliedHeight || imageOptions.naturalHeight;
  const largestDimension = Math.max(intendedWidth, intendedHeight);
  return sizeByMaximumDimension[largestDimension] || CUSTOM;
}

function getPercentageUnitsFromAttributes($element) {
  const getAttribute = attribute => $element.hasAttribute(attribute) ? $element.getAttribute(attribute) : $element[attribute];

  const widthValue = getAttribute('width');
  const heightValue = getAttribute('height');
  const value = [widthValue, heightValue].find(v => /\d+(?:\.\d+)?%/.test(v));
  return value ? Math.round(Number.parseInt(value, 10)) : null;
}

export function fromImageEmbed($element) {
  const altText = $element.getAttribute('alt');
  const percentageUnits = getPercentageUnitsFromAttributes($element);
  const imageOptions = {
    appliedWidth: parsedOrNull($element, 'width'),
    appliedHeight: parsedOrNull($element, 'height'),
    naturalWidth: $element.naturalWidth,
    naturalHeight: $element.naturalHeight,
    appliedPercentage: percentageUnits || 100,
    usePercentageUnits: !!percentageUnits,
    altText: altText || '',
    isDecorativeImage: altText !== null && altText.replace(/\s/g, '') === '',
    url: $element.src
  };
  imageOptions.imageSize = imageSizeFromKnownOptions(imageOptions);
  return imageOptions;
}
export function fromVideoEmbed($element) {
  // $element will be the <span> tinymce wraps around the iframe
  // that's hosting the video player
  let $videoElem = null;
  let $videoDoc;
  let naturalWidth, naturalHeight;
  const $videoIframe = $element.tagName === 'IFRAME' ? $element : $element.firstElementChild;
  const $tinymceIframeShim = $videoIframe.parentElement;

  if ($videoIframe.tagName === 'IFRAME') {
    $videoDoc = $videoIframe.contentDocument;

    if ($videoDoc) {
      $videoElem = $videoDoc.querySelector('video');
    }

    if ($videoElem && ($videoElem.loadedmetadata || $videoElem.readyState >= 1)) {
      naturalWidth = $videoElem.videoWidth;
      naturalHeight = $videoElem.videoHeight;
    }
  } // because tinymce doesn't put the title attribute on the iframe,
  // but maintains it on the span it adds around it.


  const title = ($videoIframe.getAttribute('title') || $tinymceIframeShim.getAttribute('data-mce-p-title') || '').replace(formatMessage('Video player for '), '');
  const rect = $element.getBoundingClientRect();
  const videoOptions = {
    titleText: title || '',
    appliedHeight: rect.height,
    appliedWidth: rect.width,
    naturalHeight,
    naturalWidth,
    source: $videoElem && $videoElem.querySelector('source')
  };

  try {
    var _$videoDoc$querySelec;

    const trackjson = (_$videoDoc$querySelec = $videoDoc.querySelector('[data-tracks]')) === null || _$videoDoc$querySelec === void 0 ? void 0 : _$videoDoc$querySelec.getAttribute('data-tracks');

    if (trackjson) {
      videoOptions.tracks = JSON.parse(trackjson);
    }
  } catch (_ignore) {// bad json?
  }

  videoOptions.videoSize = imageSizeFromKnownOptions(videoOptions);
  return videoOptions;
}
export function scaleImageForHeight(naturalWidth, naturalHeight, targetHeight) {
  return scaleForHeight(naturalWidth, naturalHeight, targetHeight, {
    minHeight: MIN_HEIGHT,
    minWidth: MIN_WIDTH
  });
}
export function scaleImageForWidth(naturalWidth, naturalHeight, targetWidth) {
  return scaleForWidth(naturalWidth, naturalHeight, targetWidth, {
    minHeight: MIN_HEIGHT,
    minWidth: MIN_WIDTH
  });
}
export function scaleToSize(imageSize, naturalWidth, naturalHeight) {
  if (imageSize === CUSTOM) {
    return {
      width: naturalWidth,
      height: naturalHeight
    };
  }

  const _Object$entries$find = Object.entries(sizeByMaximumDimension).find(([, size]) => size === imageSize),
        _Object$entries$find2 = _slicedToArray(_Object$entries$find, 1),
        dimension = _Object$entries$find2[0];

  const scaleFactor = dimension / Math.max(naturalWidth, naturalHeight);
  return {
    height: Math.round(naturalHeight * scaleFactor),
    width: Math.round(naturalWidth * scaleFactor)
  };
}
export function labelForImageSize(imageSize) {
  switch (imageSize) {
    case SMALL:
      {
        return formatMessage('Small');
      }

    case MEDIUM:
      {
        return formatMessage('Medium');
      }

    case LARGE:
      {
        return formatMessage('Large');
      }

    case EXTRA_LARGE:
      {
        return formatMessage('Extra Large');
      }

    default:
      {
        return formatMessage('Custom');
      }
  }
}