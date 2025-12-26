from rest_framework import viewsets, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from .models import Contract
from .serializers import ContractSerializer, ContractCreateSerializer


class ContractViewSet(viewsets.ModelViewSet):
    """ViewSet for contracts."""

    queryset = Contract.objects.all()
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['status', 'offer', 'email_sent']
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'create':
            return ContractCreateSerializer
        return ContractSerializer

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=['post'])
    def sign(self, request, pk=None):
        """Mark contract as signed."""
        contract = self.get_object()
        contract.mark_as_signed()
        serializer = self.get_serializer(contract)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def send_email(self, request, pk=None):
        """Send contract by email."""
        contract = self.get_object()

        if not contract.customer_email:
            return Response(
                {'error': 'Aucun email client specifie.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # TODO: Implement actual email sending
        contract.mark_email_sent()
        serializer = self.get_serializer(contract)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Return contract statistics."""
        from django.db.models import Count

        total = Contract.objects.count()
        by_status = Contract.objects.values('status').annotate(count=Count('id'))
        by_offer = Contract.objects.values('offer__name').annotate(count=Count('id'))

        return Response({
            'total': total,
            'by_status': {item['status']: item['count'] for item in by_status},
            'by_offer': {item['offer__name']: item['count'] for item in by_offer},
        })
