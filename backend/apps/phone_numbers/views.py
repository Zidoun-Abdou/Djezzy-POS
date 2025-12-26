from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import PhoneNumber
from .serializers import PhoneNumberSerializer


class PhoneNumberViewSet(viewsets.ModelViewSet):
    """ViewSet for phone numbers."""

    queryset = PhoneNumber.objects.all()
    serializer_class = PhoneNumberSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['status']

    def get_permissions(self):
        if self.action in ['list', 'retrieve', 'available']:
            return [AllowAny()]
        return [IsAuthenticated()]

    @action(detail=False, methods=['get'])
    def available(self, request):
        """Return only available phone numbers."""
        limit = request.query_params.get('limit', 5)
        try:
            limit = int(limit)
        except ValueError:
            limit = 5

        numbers = PhoneNumber.objects.filter(status='available').order_by('number')[:limit]
        serializer = self.get_serializer(numbers, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def assign(self, request, pk=None):
        """Assign a phone number to a customer."""
        phone = self.get_object()

        if phone.status != 'available':
            return Response(
                {'error': 'Ce numero n\'est pas disponible.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        name = request.data.get('name')
        nin = request.data.get('nin')

        if not name or not nin:
            return Response(
                {'error': 'Le nom et le NIN sont requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        phone.assign_to(name, nin)
        serializer = self.get_serializer(phone)
        return Response(serializer.data)
