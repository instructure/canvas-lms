"""
pytest conftest: adds the plugin root to sys.path so that
`curriculum` and `auth` packages can be imported without installation.
"""
import sys
from pathlib import Path

# Ensure the plugin root (plugins/corewest_alexa/) is on sys.path
plugin_root = Path(__file__).parent
if str(plugin_root) not in sys.path:
    sys.path.insert(0, str(plugin_root))
