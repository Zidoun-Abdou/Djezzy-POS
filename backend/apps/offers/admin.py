from django.contrib import admin
from django.utils.html import format_html
from .models import Offer


@admin.register(Offer)
class OfferAdmin(admin.ModelAdmin):
    list_display = [
        'name', 'code', 'formatted_price_display', 'data_display',
        'validity_display', 'is_active', 'display_order'
    ]
    list_filter = ['is_active', 'validity_days']
    search_fields = ['name', 'code', 'description']
    list_editable = ['display_order', 'is_active']
    ordering = ['display_order', 'name']

    fieldsets = [
        ('Informations generales', {
            'fields': ['name', 'code', 'description']
        }),
        ('Tarification', {
            'fields': ['price', 'currency', 'validity_days']
        }),
        ('Inclusions', {
            'fields': ['data_allowance_mb', 'voice_minutes', 'sms_count', 'features']
        }),
        ('Affichage', {
            'fields': ['is_active', 'display_order']
        }),
    ]

    actions = ['activate_offers', 'deactivate_offers']

    @admin.display(description='Prix')
    def formatted_price_display(self, obj):
        return format_html(
            '<span style="font-weight: bold; color: #ED1C24;">{} DA</span>',
            int(obj.price)
        )

    @admin.display(description='Data')
    def data_display(self, obj):
        gb = obj.data_allowance_mb / 1024
        return f"{int(gb)} Go" if gb >= 1 else f"{obj.data_allowance_mb} Mo"

    @admin.display(description='Validite')
    def validity_display(self, obj):
        if obj.validity_days == 1:
            return "1 jour"
        elif obj.validity_days < 30:
            return f"{obj.validity_days} jours"
        else:
            months = obj.validity_days // 30
            return f"{months} mois" if months > 1 else "1 mois"

    @admin.action(description='Activer les offres selectionnees')
    def activate_offers(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f'{updated} offre(s) activee(s).')

    @admin.action(description='Desactiver les offres selectionnees')
    def deactivate_offers(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f'{updated} offre(s) desactivee(s).')
