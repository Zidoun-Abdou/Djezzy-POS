from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import PhoneNumberViewSet

router = DefaultRouter()
router.register('', PhoneNumberViewSet, basename='phone-number')

urlpatterns = [
    path('', include(router.urls)),
]
