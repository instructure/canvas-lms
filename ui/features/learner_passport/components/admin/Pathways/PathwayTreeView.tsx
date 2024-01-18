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

import React, {useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState} from 'react'
import dagre from 'dagre'
import type {Node} from 'dagre'
import bspline from 'b-spline'
import {Flex} from '@instructure/ui-flex'
import {IconBulletListLine, IconGroupLine} from '@instructure/ui-icons'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import type {MilestoneData, PathwayDetailData} from '../../types'
import {pluralize} from '../../shared/utils'

const BOX_WIDTH = 322

type PathwayNode = Node<PathwayDetailData | MilestoneData>
type GraphNode = PathwayDetailData | MilestoneData | PathwayNode
type NodeType = 'pathway' | 'milestone'

type PathwayTreeViewProps = {
  pathway: PathwayDetailData
  selectedStep: string | null
  onSelected?: (selectedStep: MilestoneData | null) => void
  layout?: 'TB' | 'BT' | 'LR' | 'RL'
  zoomLevel?: number
}

type BoxHeights = {
  height: number
  milestones: Array<{id: string; height: number}>
}

interface NamespacedDiv
  extends React.DetailedHTMLProps<React.HTMLAttributes<HTMLDivElement>, HTMLDivElement> {
  elementRef?: (node: HTMLDivElement) => void
  xmlns?: string
}

const DivInSVG: React.FC<NamespacedDiv> = props => {
  const {elementRef, ...divprops} = props

  return (
    <div xmlns="http://www.w3.org/1999/xhtml" {...divprops} ref={elementRef}>
      {props.children}
    </div>
  )
}

const PathwayTreeView = ({
  pathway,
  selectedStep,
  onSelected,
  layout = 'TB',
  zoomLevel = 1,
}: PathwayTreeViewProps) => {
  const [g] = useState(new dagre.graphlib.Graph())
  const [dagNodes, setDagNodes] = useState<JSX.Element[]>([])
  const [dagEdges, setDagEdges] = useState<JSX.Element[]>([])
  const [firstNodeRef, setFirstNodeRef] = useState(null)
  const [viewBox, setViewBox] = useState([0, 0, 0, 0])
  const [preRendered, setPreRendered] = useState(false)
  const [graphBoxHeights, setGraphBoxHeights] = useState<BoxHeights>({
    height: 0,
    milestones: [],
  })
  const viewRef = useRef<HTMLDivElement>(null)
  const preRenderNodeRef = useRef<HTMLDivElement>(null)
  const svgRef = useRef<SVGSVGElement>(null)

  const handleSelectBox = useCallback(
    (id: string) => {
      if (!onSelected) return
      if (id === '0') {
        onSelected(null)
      } else {
        const milestone = pathway.milestones.find(m => m.id === id)
        if (!milestone) return
        onSelected(milestone)
      }
    },
    [onSelected, pathway.milestones]
  )

  const handleBoxClick = useCallback(
    (e: React.MouseEvent<HTMLDivElement>) => {
      handleSelectBox(e.currentTarget.id)
    },
    [handleSelectBox]
  )

  const handleBoxKey = useCallback(
    (e: React.KeyboardEvent<HTMLDivElement>) => {
      if (e.key === 'Enter') {
        handleSelectBox(e.currentTarget.id)
      }
    },
    [handleSelectBox]
  )
  const boxStyle = useMemo(() => {
    return onSelected
      ? {
          cursor: 'pointer',
        }
      : {}
  }, [onSelected])
  const boxProps = useMemo(() => {
    return onSelected
      ? {
          role: 'button',
          tabIndex: 0,
          onClick: handleBoxClick,
          onKeyDown: handleBoxKey,
        }
      : {}
  }, [handleBoxClick, handleBoxKey, onSelected])

  const handleFirstNodeRef = useCallback(
    node => {
      setFirstNodeRef(node)
    },
    [setFirstNodeRef]
  )

  const renderPathwayBoxContent = useCallback(
    (node: GraphNode, type: NodeType, selected: boolean, width: number, height?: number) => {
      const req_count: number = 'requirement_count' in node ? (node.requirement_count as number) : 0
      return (
        <View
          as="div"
          padding="small"
          background={type === 'pathway' ? 'primary-inverse' : 'primary'}
          borderRadius="medium"
          borderWidth="medium"
          width={`${width}px`}
          height={height ? `${height}px` : 'auto'}
          minHeight="100%"
          borderColor={selected ? 'brand' : undefined}
        >
          <Flex as="div" direction="column" justifyItems="start" height="100%">
            <Flex.Item shouldGrow={true} overflowY="visible">
              <Flex as="div" gap="small">
                <div style={{width: '30px', height: '30px', background: 'grey'}} />
                <Flex.Item>
                  <Text weight="bold">{node.title}</Text>
                  <div style={{marginTop: '.5rem'}}>
                    <Text size="small">
                      <TruncateText maxLines={2} truncate="character">
                        {node.description}
                      </TruncateText>
                    </Text>
                  </div>
                </Flex.Item>
              </Flex>
              {!('required' in node) || node.required ? null : (
                <div style={{marginTop: '.5rem'}}>
                  <Pill>Optional</Pill>
                </div>
              )}
            </Flex.Item>

            {type === 'pathway' ? (
              <Flex.Item>
                <IconGroupLine size="x-small" />
                <View display="inline-block" margin="0 0 0 x-small">
                  <Text>
                    {pluralize(
                      (node as PathwayDetailData).learner_groups.length,
                      '1 learner group',
                      `${(node as PathwayDetailData).learner_groups.length} learner groups`
                    )}
                  </Text>
                </View>
              </Flex.Item>
            ) : (
              <Flex.Item>
                <IconBulletListLine size="x-small" />
                <View display="inline-block" margin="0 0 0 x-small">
                  <Text>{pluralize(req_count, '1 requirement', `${req_count} requirements`)}</Text>
                </View>
              </Flex.Item>
            )}
          </Flex>
        </View>
      )
    },
    []
  )

  const renderPathwayBox = useCallback(
    (data: PathwayDetailData | MilestoneData, type: NodeType, key: string) => {
      return (
        <div id={data.id} key={key} role="button">
          {renderPathwayBoxContent(data, type, false, BOX_WIDTH, undefined)}
        </div>
      )
    },
    [renderPathwayBoxContent]
  )

  const renderPathwayBoxes = useCallback(() => {
    const boxes = pathway.milestones.map((m: MilestoneData) => {
      return renderPathwayBox(m, 'milestone', `milestone-${m.id}`)
    })
    boxes.unshift(renderPathwayBox(pathway, 'pathway', `pathway-${pathway.id}`))

    return <div ref={preRenderNodeRef}>{boxes}</div>
  }, [pathway, renderPathwayBox])

  const renderDAG = useCallback(() => {
    // Set an object for the graph label
    g.setGraph({rankdir: layout, marginx: pathway.first_milestones.length < 2 ? 100 : 0})

    // Default to assigning a new object as a label for each new edge.
    g.setDefaultEdgeLabel(function () {
      return {}
    })

    g.setNode('0', {
      title: pathway.title,
      description: pathway.description,
      width: 320,
      height: graphBoxHeights.height,
      learner_groups: pathway.learner_groups,
    })
    pathway.first_milestones.forEach((m: string) => {
      g.setEdge('0', m)
    })
    pathway.milestones.forEach((m: MilestoneData) => {
      const ht = graphBoxHeights.milestones.find(n => n.id === m.id)?.height
      g.setNode(m.id, {
        id: m.id,
        title: m.title,
        description: m.description,
        required: m.required,
        requirement_count: m.requirements.length,
        width: 320,
        height: ht || 132,
      })
      m.next_milestones.forEach((n: string) => {
        g.setEdge(m.id, n)
      })
    })

    dagre.layout(g)

    const maxX = g.graph().width as number
    const maxY = g.graph().height as number
    setViewBox([0, 0, maxX, maxY])

    const nodes = g.nodes().map((n, i) => {
      const node = g.node(n)
      const type = i === 0 ? 'pathway' : 'milestone'
      const opacity = i === 0 && selectedStep !== null ? 0.7 : 1
      return (
        <foreignObject
          key={n}
          x={`${node.x - node.width / 2}`}
          y={`${node.y - node.height / 2}`}
          width={node.width}
          height={node.height}
        >
          <DivInSVG
            xmlns="http://www.w3.org/1999/xhtml"
            className={i === 0 ? 'pathway' : 'milestone'}
            elementRef={i === 0 ? handleFirstNodeRef : undefined}
            id={n}
            style={{
              left: 0,
              top: 0,
              ...boxStyle,
              opacity,
            }}
            {...boxProps}
          >
            {renderPathwayBoxContent(
              node as PathwayNode,
              type,
              selectedStep === n,
              node.width,
              node.height
            )}
          </DivInSVG>
        </foreignObject>
      )
    })

    setDagNodes(nodes)
  }, [
    boxProps,
    boxStyle,
    g,
    graphBoxHeights.height,
    graphBoxHeights.milestones,
    handleFirstNodeRef,
    layout,
    pathway.description,
    pathway.first_milestones,
    pathway.learner_groups,
    pathway.milestones,
    pathway.title,
    renderPathwayBoxContent,
    selectedStep,
  ])

  const renderDAGEdges = useCallback(() => {
    if (firstNodeRef === null) return

    const edges = g.edges().map(edg => {
      const points = g.edge(edg).points
      const pts = points.map(p => Object.values(p))
      const commands = [`M${points[0].x} ${points[0].y}`]
      for (let t = 0; t <= 1; t += 0.1) {
        const p = bspline(t, pts.length - 1, pts)
        commands.push(`L${p[0]} ${p[1]}`)
      }
      commands.push(`L${points[points.length - 1].x} ${points[points.length - 1].y}`)
      return (
        <g fill="none" stroke="#C7CDD1">
          <circle cx={points[0].x} cy={points[0].y} r="2" strokeWidth="2" />
          <path d={commands.join(' ')} fill="none" strokeWidth={2} />
          <circle
            cx={points[points.length - 1].x}
            cy={points[points.length - 1].y}
            r="2"
            strokeWidth="2"
          />
        </g>
      )
    })
    setDagEdges(edges)
  }, [g, firstNodeRef])

  useEffect(() => {
    const sty = document.createElement('style')
    sty.innerText = `
    .dag {
        overflow: visible!important;
        font-size: 16px;
    }
    `
    document.head.appendChild(sty)
    return () => {
      sty.remove()
    }
  }, [])

  useLayoutEffect(() => {
    if (preRenderNodeRef?.current) {
      const boxes = Array.from(preRenderNodeRef.current.children)
      const boxHeights: BoxHeights = boxes.reduce(
        // we're reducing and accumulating a value that's not the same type as the array
        // that's not how reduce is typed.
        // @ts-expect-error
        (acc: BoxHeights, n: HTMLDivElement, index: number) => {
          const {height} = n.getBoundingClientRect()
          if (index === 0) {
            acc.height = height
          } else {
            acc.milestones.push({id: n.id, height})
          }
          return acc
        },
        {height: 0, milestones: []}
      ) as unknown as BoxHeights
      setPreRendered(true)
      setGraphBoxHeights(boxHeights)
    }
  }, [pathway.id, preRenderNodeRef])

  useEffect(() => {
    if (preRendered && graphBoxHeights.height > 0) {
      renderDAG()
    }
  }, [graphBoxHeights.height, preRendered, renderDAG])

  useEffect(() => {
    renderDAGEdges()
  }, [dagNodes, renderDAGEdges])

  const graphWidth = g.graph()?.width ? `${g.graph().width * zoomLevel}px` : 'auto'
  const graphHeight = g.graph()?.height ? `${g.graph().height * zoomLevel}px` : 'auto'

  return preRendered ? (
    <div
      data-compid="pathway-tree-view"
      style={{
        minWidth: graphWidth,
        minHeight: graphHeight,
        height: '100%',
        backgroundSize: '40px 40px',
        backgroundImage: `linear-gradient(to right, rgba(150, 173, 233, .3) 1px, transparent 1px),
                  linear-gradient(to bottom, rgba(150, 173, 233, .3) 1px, transparent 1px)`,
      }}
    >
      <View as="div" width="fit-content">
        <div
          ref={viewRef}
          style={{
            position: 'relative',
            padding: '.5rem',
            transform: `scale(${zoomLevel})`,
            transformOrigin: '0 0',
          }}
        >
          <svg
            ref={svgRef}
            className="dag"
            viewBox={`${viewBox[0]} ${viewBox[1]} ${viewBox[2]} ${viewBox[3]}`}
            x={viewBox[0]}
            y={viewBox[1]}
            width={viewBox[2]}
            height={viewBox[3]}
          >
            {dagNodes}
            <g fill="none" stroke="#C7CDD1">
              {dagEdges}
            </g>
          </svg>
        </div>
      </View>
    </div>
  ) : (
    renderPathwayBoxes()
  )
}

export default PathwayTreeView
