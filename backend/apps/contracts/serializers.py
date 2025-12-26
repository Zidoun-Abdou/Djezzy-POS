from rest_framework import serializers
from .models import Contract
from apps.offers.serializers import OfferSerializer
from apps.phone_numbers.serializers import PhoneNumberSerializer


class ContractSerializer(serializers.ModelSerializer):
    """Serializer for contracts."""

    offer_detail = OfferSerializer(source='offer', read_only=True)
    phone_number_detail = PhoneNumberSerializer(source='phone_number', read_only=True)
    customer_full_name = serializers.ReadOnlyField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)

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
            'customer_email', 'email_sent', 'email_sent_at',
            # Metadata
            'created_by', 'created_at', 'updated_at', 'signed_at'
        ]
        read_only_fields = [
            'contract_number', 'created_at', 'updated_at',
            'signed_at', 'email_sent_at'
        ]


class ContractCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating contracts."""

    class Meta:
        model = Contract
        fields = [
            'customer_first_name', 'customer_last_name',
            'customer_first_name_ar', 'customer_last_name_ar',
            'customer_birth_date', 'customer_birth_place',
            'customer_sex', 'customer_nin', 'customer_id_number',
            'customer_id_expiry', 'customer_daira', 'customer_baladia',
            'offer', 'phone_number', 'customer_email',
            'signature_base64', 'customer_photo', 'pdf_file'
        ]

    def create(self, validated_data):
        # Assign phone number to customer
        phone_number = validated_data.get('phone_number')
        if phone_number and phone_number.status == 'available':
            name = f"{validated_data.get('customer_first_name')} {validated_data.get('customer_last_name')}"
            nin = validated_data.get('customer_nin', '')
            phone_number.assign_to(name, nin)

        return super().create(validated_data)
