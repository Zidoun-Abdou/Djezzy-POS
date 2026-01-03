from rest_framework import serializers
from .models import Offer


class OfferSerializer(serializers.ModelSerializer):
    """Serializer for Djezzy offers."""

    data_allowance_gb = serializers.ReadOnlyField()
    formatted_price = serializers.ReadOnlyField()
    available_phone_numbers = serializers.SerializerMethodField()
    available_count = serializers.SerializerMethodField()
    distributed_count = serializers.SerializerMethodField()

    class Meta:
        model = Offer
        fields = [
            'id', 'name', 'code', 'description', 'price', 'currency',
            'data_allowance_mb', 'data_allowance_gb', 'voice_minutes',
            'sms_count', 'validity_days', 'features', 'is_active',
            'display_order', 'formatted_price',
            'available_phone_numbers', 'available_count', 'distributed_count',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']

    def get_available_phone_numbers(self, obj):
        """Return available phone numbers for this offer."""
        available = obj.phone_numbers.filter(status='available')
        return [
            {
                'id': pn.id,
                'number': pn.number,
                'formatted_number': pn.formatted_number,
            }
            for pn in available
        ]

    def get_available_count(self, obj):
        """Return count of available phone numbers."""
        return obj.phone_numbers.filter(status='available').count()

    def get_distributed_count(self, obj):
        """Return count of distributed/assigned phone numbers."""
        return obj.phone_numbers.filter(status='assigned').count()
