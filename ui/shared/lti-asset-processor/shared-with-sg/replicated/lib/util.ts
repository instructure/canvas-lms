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

/**
 * This function will be implemented twice in Canvas, with a test to make sure
 * the implementations are the same, to ease code sharing with Speedgrader
 */
export function buildAPDisplayTitle({
  title,
  toolPlacementLabel,
  toolName,
}: {
  title?: string | null
  toolPlacementLabel?: string | null
  toolName: string
}): string {
  const toolTitle = toolPlacementLabel || toolName
  return title && title !== toolTitle ? `${toolTitle} · ${title}` : toolTitle
}
