from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ['username', 'email', 'first_name', 'last_name', 'role', 'store_location', 'is_active']
    list_filter = ['role', 'is_active', 'is_staff', 'store_location']
    search_fields = ['username', 'email', 'first_name', 'last_name', 'phone_number']
    ordering = ['-created_at']

    fieldsets = BaseUserAdmin.fieldsets + (
        ('Informations Djezzy', {
            'fields': ('role', 'phone_number', 'store_location'),
        }),
    )

    add_fieldsets = BaseUserAdmin.add_fieldsets + (
        ('Informations Djezzy', {
            'fields': ('role', 'phone_number', 'store_location'),
        }),
    )
