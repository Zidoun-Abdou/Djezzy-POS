from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """Custom User model for Djezzy POS."""

    ROLE_CHOICES = [
        ('admin', 'Administrateur'),
        ('agent', 'Agent Commercial'),
    ]

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default='agent',
        verbose_name='Role'
    )
    phone_number = models.CharField(
        max_length=20,
        blank=True,
        verbose_name='Numero de telephone'
    )
    store_location = models.CharField(
        max_length=100,
        blank=True,
        verbose_name='Point de vente'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Date de creation'
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name='Derniere modification'
    )

    class Meta:
        verbose_name = 'Utilisateur'
        verbose_name_plural = 'Utilisateurs'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.get_full_name() or self.username} ({self.get_role_display()})"
