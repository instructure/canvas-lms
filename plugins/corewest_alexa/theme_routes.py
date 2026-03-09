"""
Core West College Theme Routes
FastAPI router serving all HTML template pages.
"""
from pathlib import Path
from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

TEMPLATES_DIR = Path(__file__).parent / "templates"
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))

router = APIRouter()


def render(request: Request, template: str, **context):
    """Helper to render a template with common context."""
    return templates.TemplateResponse(
        template,
        {
            "request": request,
            "page_title": context.pop("page_title", "Core West College"),
            **context,
        },
    )


@router.get("/", response_class=HTMLResponse)
async def homepage(request: Request):
    return render(request, "index.html", page_title="Home")


@router.get("/about", response_class=HTMLResponse)
async def about(request: Request):
    return render(request, "about.html", page_title="About Us")


@router.get("/divisions", response_class=HTMLResponse)
async def divisions(request: Request):
    return render(request, "divisions.html", page_title="Academic Divisions")


@router.get("/teaching-learning", response_class=HTMLResponse)
async def teaching_learning(request: Request):
    return render(request, "teaching_learning.html", page_title="Teaching & Learning")


@router.get("/facilities", response_class=HTMLResponse)
async def facilities(request: Request):
    return render(request, "facilities.html", page_title="Facilities")


@router.get("/admission", response_class=HTMLResponse)
async def admission(request: Request):
    return render(request, "admission.html", page_title="Admission")


@router.get("/events", response_class=HTMLResponse)
async def events(request: Request):
    return render(request, "events.html", page_title="Events")


@router.get("/careers", response_class=HTMLResponse)
async def careers(request: Request):
    return render(request, "careers.html", page_title="Careers")


@router.get("/contact", response_class=HTMLResponse)
async def contact(request: Request):
    return render(request, "contact.html", page_title="Contact Us")


@router.get("/login", response_class=HTMLResponse)
async def login(request: Request):
    return render(request, "login.html", page_title="Login")


@router.get("/dashboard", response_class=HTMLResponse)
async def dashboard(request: Request):
    return render(request, "dashboard.html", page_title="AI Command Center")


@router.get("/inspection-dashboard", response_class=HTMLResponse)
async def inspection_dashboard(request: Request):
    return render(request, "inspection_dashboard.html", page_title="Inspection Dashboard")


@router.get("/curriculum-dashboard", response_class=HTMLResponse)
async def curriculum_dashboard(request: Request):
    return render(request, "curriculum_dashboard.html", page_title="Curriculum Dashboard")
