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

import React from 'react'
import {z} from 'zod'
import {createRoot} from 'react-dom/client'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('lti_asset_processor')

type FlashErrorBoundaryProps = {
  title: string
  children: React.ReactNode
}

class FlashErrorBoundary extends React.Component<FlashErrorBoundaryProps, {hasError: boolean}> {
  constructor(props: FlashErrorBoundaryProps) {
    super(props)
    this.state = {hasError: false}
  }

  static getDerivedStateFromError(_error: unknown) {
    // Update state so the next render will show the fallback UI.
    return {hasError: true}
  }

  componentDidCatch(error: unknown, info: any) {
    console.error(`ErrorBoundary (${this.props.title}) caught an error`, error, info)
    showFlashError(this.props.title)
  }

  render() {
    if (this.state.hasError) {
      return null
    }

    return this.props.children
  }
}

type ComponentForZodSchema<T extends z.ZodType | undefined> = T extends z.ZodType
  ? React.ComponentType<z.infer<T>>
  : T extends undefined
    ? React.ComponentType<{}>
    : never

type RenderToElementsOptions<T extends z.ZodType | undefined> = {
  selector: string
  Component: ComponentForZodSchema<T>
  datasetSchema: T
  flashErrorTitle: string
  withQueryClient: boolean
  propsGetter?: T extends z.ZodType ? (element: HTMLElement) => z.infer<T> : never
}

/**
 * Renders a React component into all elements matching the given selector.
 * The component's props are derived from the element's dataset, validated against the provided Zod schema.
 * If rendering fails for any element, a flash error is shown with the provided title.
 * @param selector - The CSS selector to match elements (e.g., '.my-component').
 * @param Component - The React component to render.
 * @param datasetSchema - A Zod schema to validate the element's dataset against.
 * @param flashErrorTitle - The title to use in the flash error if rendering fails.
 * @param withQueryClient - If true, the component will be rendered with a QueryClientProvider.
 * @param propsGetter - Optional function that takes element and returns props to use instead of dataset.
 * @returns The number of successfully rendered components.
 * @example
 * ```tsx
 * const ZProps = z.object({
 *   userId: z.string().uuid(),
 *   isAdmin: z.string().transform(val => val === 'true'),
 *   });
 *   renderToElements({
 *   selector: '.my-component',
 *   Component: MyComponent,
 *   datasetSchema: ZProps,
 *   flashErrorTitle: 'Error loading MyComponent',
 * });
 * ```
 */
export function renderToElements<T extends z.ZodType | undefined>({
  selector,
  Component,
  datasetSchema,
  withQueryClient,
  flashErrorTitle,
  propsGetter,
}: RenderToElementsOptions<T>) {
  const containers = document.querySelectorAll<HTMLElement>(selector)
  let count = 0
  let error = false

  for (const container of Array.from(containers)) {
    try {
      let elem = undefined
      if (datasetSchema === undefined) {
        const CompWithNoAttrs: ComponentForZodSchema<undefined> = Component
        elem = <CompWithNoAttrs />
      } else if (propsGetter !== undefined) {
        // Use provided props getter function instead of dataset
        const props = propsGetter(container)
        elem = <Component {...props} />
      } else {
        const data = datasetSchema.safeParse(container.dataset)
        if (data.success) {
          elem = <Component {...data.data} />
        } else {
          console.warn(`Invalid props for element ${selector}:`, data.error)
          error = true
        }
      }

      if (elem) {
        if (withQueryClient) {
          elem = <QueryClientProvider client={queryClient}>{elem}</QueryClientProvider>
        }

        createRoot(container).render(
          <FlashErrorBoundary title={flashErrorTitle}>{elem}</FlashErrorBoundary>,
        )

        count++
      }
    } catch (e) {
      console.error(`Error rendering element ${selector}`, e)
      error = true
    }
  }

  if (error) {
    showFlashError(flashErrorTitle)
  }

  return count
}

// Convenience functions
export function renderAPComponent<T extends z.ZodType | undefined>(
  selector: string,
  Component: ComponentForZodSchema<T>,
  datasetSchema?: T,
  propsGetter?: T extends z.ZodType ? (element: HTMLElement) => z.infer<T> : never,
) {
  return renderToElements({
    selector,
    Component,
    datasetSchema,
    withQueryClient: true,
    flashErrorTitle: I18n.t('Error loading Document Processors information'),
    propsGetter,
  })
}

export function renderAPComponentNoQC<T extends z.ZodType | undefined>(
  selector: string,
  Component: ComponentForZodSchema<T>,
  datasetSchema?: T,
) {
  return renderToElements({
    selector,
    Component,
    datasetSchema,
    withQueryClient: false,
    flashErrorTitle: I18n.t('Error loading Document Processors information'),
  })
}
