from rest_framework import serializers
from .models import PhoneNumber


class PhoneNumberSerializer(serializers.ModelSerializer):
    """Serializer for phone numbers."""

    formatted_number = serializers.ReadOnlyField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = PhoneNumber
        fields = [
            'id', 'number', 'formatted_number', 'status', 'status_display',
            'assigned_to_name', 'assigned_to_nin', 'assigned_date',
            'notes', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at', 'assigned_date']
