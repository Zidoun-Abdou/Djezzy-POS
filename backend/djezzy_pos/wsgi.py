"""
WSGI config for Djezzy POS project.
"""

import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'djezzy_pos.settings')

application = get_wsgi_application()
