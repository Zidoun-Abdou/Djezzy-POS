from django.contrib import admin
from django.utils.html import format_html
from .models import PhoneNumber


@admin.register(PhoneNumber)
class PhoneNumberAdmin(admin.ModelAdmin):
    list_display = [
        'formatted_number_display', 'offer', 'status_badge', 'assigned_to_name',
        'assigned_to_nin', 'assigned_date'
    ]
    list_filter = ['status', 'offer', 'assigned_date']
    search_fields = ['number', 'assigned_to_name', 'assigned_to_nin', 'offer__name']
    list_editable = []
    ordering = ['number']
    readonly_fields = ['formatted_number_display', 'created_at', 'updated_at']
    autocomplete_fields = ['offer']

    fieldsets = [
        ('Numero', {
            'fields': ['number', 'formatted_number_display', 'offer', 'status']
        }),
        ('Attribution', {
            'fields': ['assigned_to_name', 'assigned_to_nin', 'assigned_date'],
            'classes': ['collapse']
        }),
        ('Informations', {
            'fields': ['notes', 'created_at', 'updated_at'],
            'classes': ['collapse']
        }),
    ]

    actions = ['mark_available', 'mark_blocked', 'mark_reserved']

    @admin.display(description='Numero')
    def formatted_number_display(self, obj):
        return format_html(
            '<span style="font-family: monospace; font-size: 14px;">{}</span>',
            obj.formatted_number
        )

    @admin.display(description='Statut')
    def status_badge(self, obj):
        colors = {
            'available': '#28a745',
            'assigned': '#007bff',
            'reserved': '#ffc107',
            'blocked': '#dc3545',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 4px 8px; '
            'border-radius: 4px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display()
        )

    @admin.action(description='Marquer comme disponible')
    def mark_available(self, request, queryset):
        for phone in queryset:
            phone.make_available()
        self.message_user(request, f'{queryset.count()} numero(s) marque(s) comme disponible(s).')

    @admin.action(description='Bloquer les numeros')
    def mark_blocked(self, request, queryset):
        updated = queryset.update(status='blocked')
        self.message_user(request, f'{updated} numero(s) bloque(s).')

    @admin.action(description='Reserver les numeros')
    def mark_reserved(self, request, queryset):
        updated = queryset.update(status='reserved')
        self.message_user(request, f'{updated} numero(s) reserve(s).')
