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

    @action(detail=False, methods=['get'], url_path='my-contracts')
    def my_contracts(self, request):
        """Get contracts created by the authenticated user."""
        contracts = Contract.objects.filter(
            created_by=request.user
        ).order_by('-created_at')
        serializer = self.get_serializer(contracts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='my-stats')
    def my_stats(self, request):
        """Get statistics for the authenticated user's contracts."""
        from django.db.models import Count
        from django.utils import timezone
        from datetime import timedelta

        user_contracts = Contract.objects.filter(created_by=request.user)
        today = timezone.now().date()
        this_month = today.replace(day=1)

        total = user_contracts.count()
        today_count = user_contracts.filter(created_at__date=today).count()
        this_month_count = user_contracts.filter(created_at__date__gte=this_month).count()
        by_status = user_contracts.values('status').annotate(count=Count('id'))

        return Response({
            'total': total,
            'today': today_count,
            'this_month': this_month_count,
            'by_status': {item['status']: item['count'] for item in by_status},
        })
