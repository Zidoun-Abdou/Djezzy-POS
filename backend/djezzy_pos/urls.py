"""
URL configuration for Djezzy POS project.
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

# Customize admin site
admin.site.site_header = "Djezzy POS Administration"
admin.site.site_title = "Djezzy POS Admin"
admin.site.index_title = "Bienvenue sur Djezzy POS Administration"

urlpatterns = [
    path('admin/', admin.site.urls),

    # API endpoints
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/user/', include('apps.accounts.urls')),
    path('api/offers/', include('apps.offers.urls')),
    path('api/phone-numbers/', include('apps.phone_numbers.urls')),
    path('api/contracts/', include('apps.contracts.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
