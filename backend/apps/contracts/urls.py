from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ContractViewSet, public_contract_pdf

router = DefaultRouter()
router.register('', ContractViewSet, basename='contract')

urlpatterns = [
    # Public endpoint for QR code PDF download (no auth required)
    path('public/<str:contract_number>/pdf/', public_contract_pdf, name='public-contract-pdf'),
    path('', include(router.urls)),
]
