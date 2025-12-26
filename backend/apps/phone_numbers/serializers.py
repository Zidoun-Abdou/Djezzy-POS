from rest_framework import serializers
from .models import PhoneNumber
from apps.offers.models import Offer


class PhoneNumberSerializer(serializers.ModelSerializer):
    """Serializer for phone numbers."""

    formatted_number = serializers.ReadOnlyField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    offer_id = serializers.PrimaryKeyRelatedField(
        queryset=Offer.objects.all(),
        source='offer',
        write_only=True,
        required=False,
        allow_null=True
    )

    class Meta:
        model = PhoneNumber
        fields = [
            'id', 'number', 'formatted_number', 'status', 'status_display',
            'offer', 'offer_id',
            'assigned_to_name', 'assigned_to_nin', 'assigned_date',
            'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at', 'assigned_date']

    def to_representation(self, instance):
        """Include offer details in response."""
        data = super().to_representation(instance)
        if instance.offer:
            data['offer'] = {
                'id': instance.offer.id,
                'name': instance.offer.name,
                'code': instance.offer.code,
                'price': str(instance.offer.price),
                'formatted_price': instance.offer.formatted_price,
            }
        else:
            data['offer'] = None
        return data
