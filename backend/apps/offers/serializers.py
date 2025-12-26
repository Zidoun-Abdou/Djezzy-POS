from rest_framework import serializers
from .models import Offer


class OfferSerializer(serializers.ModelSerializer):
    """Serializer for Djezzy offers."""

    data_allowance_gb = serializers.ReadOnlyField()
    formatted_price = serializers.ReadOnlyField()

    class Meta:
        model = Offer
        fields = [
            'id', 'name', 'code', 'description', 'price', 'currency',
            'data_allowance_mb', 'data_allowance_gb', 'voice_minutes',
            'sms_count', 'validity_days', 'features', 'is_active',
            'is_featured', 'display_order', 'formatted_price',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']
