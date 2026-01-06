import base64
from rest_framework import serializers
from django.core.files.base import ContentFile
from .models import Contract
from apps.offers.serializers import OfferSerializer
from apps.phone_numbers.serializers import PhoneNumberSerializer


class ContractSerializer(serializers.ModelSerializer):
    """Serializer for contracts."""

    offer_detail = OfferSerializer(source='offer', read_only=True)
    phone_number_detail = PhoneNumberSerializer(source='phone_number', read_only=True)
    customer_full_name = serializers.ReadOnlyField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    agent_name = serializers.SerializerMethodField()

    class Meta:
        model = Contract
        fields = [
            'id', 'contract_number', 'status', 'status_display',
            # Customer info
            'customer_first_name', 'customer_last_name',
            'customer_first_name_ar', 'customer_last_name_ar',
            'customer_full_name', 'customer_birth_date', 'customer_birth_place',
            'customer_sex', 'customer_nin', 'customer_id_number',
            'customer_id_expiry', 'customer_daira', 'customer_baladia',
            # Relations
            'offer', 'offer_detail', 'phone_number', 'phone_number_detail',
            # Files
            'pdf_file', 'customer_photo', 'signature_base64',
            # Contact
            'customer_phone', 'customer_email', 'customer_address',
            'email_sent', 'email_sent_at',
            # Metadata
            'created_by', 'agent_name', 'created_at', 'updated_at', 'signed_at'
        ]
        read_only_fields = [
            'contract_number', 'created_at', 'updated_at',
            'signed_at', 'email_sent_at'
        ]

    def get_agent_name(self, obj):
        """Get the name of the agent who created this contract."""
        if obj.created_by:
            full_name = f"{obj.created_by.first_name} {obj.created_by.last_name}".strip()
            return full_name if full_name else obj.created_by.username
        return None


class ContractCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating contracts."""

    # Accept base64 photo data from mobile app
    customer_photo_base64 = serializers.CharField(
        write_only=True, required=False, allow_blank=True, allow_null=True
    )

    class Meta:
        model = Contract
        fields = [
            'customer_first_name', 'customer_last_name',
            'customer_first_name_ar', 'customer_last_name_ar',
            'customer_birth_date', 'customer_birth_place',
            'customer_sex', 'customer_nin', 'customer_id_number',
            'customer_id_expiry', 'customer_daira', 'customer_baladia',
            'offer', 'phone_number',
            'customer_phone', 'customer_email', 'customer_address',
            'signature_base64', 'customer_photo_base64', 'pdf_file'
        ]

    def create(self, validated_data):
        # Handle base64 photo - convert to file
        photo_base64 = validated_data.pop('customer_photo_base64', None)
        if photo_base64:
            try:
                image_data = base64.b64decode(photo_base64)
                nin = validated_data.get('customer_nin', 'unknown')
                validated_data['customer_photo'] = ContentFile(
                    image_data,
                    name=f"photo_{nin}.jpg"
                )
            except Exception:
                pass  # Ignore invalid base64

        # Set created_by from authenticated user
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            validated_data['created_by'] = request.user

        # Assign phone number to customer
        phone_number = validated_data.get('phone_number')
        if phone_number and phone_number.status == 'available':
            name = f"{validated_data.get('customer_first_name')} {validated_data.get('customer_last_name')}"
            nin = validated_data.get('customer_nin', '')
            phone_number.assign_to(name, nin)

        return super().create(validated_data)
