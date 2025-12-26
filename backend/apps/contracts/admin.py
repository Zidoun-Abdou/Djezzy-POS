from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from .models import Contract
import base64


@admin.register(Contract)
class ContractAdmin(admin.ModelAdmin):
    list_display = [
        'contract_number', 'customer_full_name', 'offer_display',
        'phone_number_display', 'status_badge', 'email_sent_display', 'created_at'
    ]
    list_filter = ['status', 'email_sent', 'offer', 'created_at']
    search_fields = [
        'contract_number', 'customer_first_name', 'customer_last_name',
        'customer_nin', 'customer_id_number', 'customer_email'
    ]
    readonly_fields = [
        'contract_number', 'signature_preview', 'photo_preview',
        'created_at', 'updated_at', 'signed_at', 'email_sent_at'
    ]
    date_hierarchy = 'created_at'
    ordering = ['-created_at']

    fieldsets = [
        ('Contrat', {
            'fields': ['contract_number', 'status', 'offer', 'phone_number']
        }),
        ('Client - Identite', {
            'fields': [
                ('customer_first_name', 'customer_last_name'),
                ('customer_first_name_ar', 'customer_last_name_ar'),
                ('customer_birth_date', 'customer_birth_place'),
                'customer_sex'
            ]
        }),
        ('Client - Documents', {
            'fields': [
                'customer_nin', 'customer_id_number', 'customer_id_expiry',
                ('customer_daira', 'customer_baladia')
            ]
        }),
        ('Contact', {
            'fields': ['customer_email', 'email_sent', 'email_sent_at']
        }),
        ('Fichiers', {
            'fields': ['pdf_file', 'photo_preview', 'signature_preview'],
            'classes': ['collapse']
        }),
        ('Metadata', {
            'fields': ['created_by', 'created_at', 'updated_at', 'signed_at'],
            'classes': ['collapse']
        }),
    ]

    @admin.display(description='Client')
    def customer_full_name(self, obj):
        return obj.customer_full_name

    @admin.display(description='Offre')
    def offer_display(self, obj):
        return format_html(
            '<span style="color: #ED1C24; font-weight: bold;">{}</span>',
            obj.offer.name
        )

    @admin.display(description='Numero')
    def phone_number_display(self, obj):
        return format_html(
            '<span style="font-family: monospace;">{}</span>',
            obj.phone_number.formatted_number
        )

    @admin.display(description='Statut')
    def status_badge(self, obj):
        colors = {
            'draft': '#6c757d',
            'signed': '#28a745',
            'validated': '#007bff',
            'cancelled': '#dc3545',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 4px 8px; '
            'border-radius: 4px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display()
        )

    @admin.display(description='Email', boolean=True)
    def email_sent_display(self, obj):
        return obj.email_sent

    @admin.display(description='Signature')
    def signature_preview(self, obj):
        if obj.signature_base64:
            return format_html(
                '<img src="data:image/png;base64,{}" style="max-width: 200px; '
                'max-height: 80px; border: 1px solid #ddd; border-radius: 4px;" />',
                obj.signature_base64
            )
        return "Pas de signature"

    @admin.display(description='Photo')
    def photo_preview(self, obj):
        if obj.customer_photo:
            return format_html(
                '<img src="{}" style="max-width: 100px; max-height: 120px; '
                'border: 1px solid #ddd; border-radius: 4px;" />',
                obj.customer_photo.url
            )
        return "Pas de photo"

    actions = ['validate_contracts', 'cancel_contracts', 'send_emails']

    @admin.action(description='Valider les contrats selectionnes')
    def validate_contracts(self, request, queryset):
        updated = queryset.filter(status='signed').update(status='validated')
        self.message_user(request, f'{updated} contrat(s) valide(s).')

    @admin.action(description='Annuler les contrats selectionnes')
    def cancel_contracts(self, request, queryset):
        updated = queryset.exclude(status='cancelled').update(status='cancelled')
        self.message_user(request, f'{updated} contrat(s) annule(s).')

    @admin.action(description='Envoyer les emails')
    def send_emails(self, request, queryset):
        # Placeholder for email sending logic
        count = 0
        for contract in queryset.filter(email_sent=False, customer_email__isnull=False):
            if contract.customer_email:
                # TODO: Implement actual email sending
                contract.mark_email_sent()
                count += 1
        self.message_user(request, f'{count} email(s) envoye(s).')
