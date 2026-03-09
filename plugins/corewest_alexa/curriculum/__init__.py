"""
Core West College AI LMS — Curriculum Monitoring & Inspection Readiness Module

Provides:
- Educational standards frameworks (Ofsted, Cognia, Common Core, National Curriculum, Danielson)
- Curriculum coverage monitoring and gap analysis
- Inspection readiness scoring and checklists
- Academic performance tracking and analytics
- FastAPI routes for all curriculum and inspection endpoints
"""

from .curriculum_monitor import CurriculumMonitor
from .inspection_readiness import InspectionReadinessEngine
from .performance_tracker import PerformanceTracker

__all__ = [
    "CurriculumMonitor",
    "InspectionReadinessEngine",
    "PerformanceTracker",
]
