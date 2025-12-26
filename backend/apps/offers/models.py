from django.db import models


class Offer(models.Model):
    """Djezzy offer model."""

    CURRENCY_CHOICES = [
        ('DZD', 'Dinar Algerien'),
    ]

    name = models.CharField(
        max_length=100,
        verbose_name='Nom de l\'offre'
    )
    code = models.CharField(
        max_length=50,
        unique=True,
        verbose_name='Code offre'
    )
    description = models.TextField(
        blank=True,
        verbose_name='Description'
    )
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name='Prix'
    )
    currency = models.CharField(
        max_length=3,
        choices=CURRENCY_CHOICES,
        default='DZD',
        verbose_name='Devise'
    )
    data_allowance_mb = models.PositiveIntegerField(
        default=0,
        verbose_name='Data (Mo)'
    )
    voice_minutes = models.PositiveIntegerField(
        default=0,
        verbose_name='Minutes voix'
    )
    sms_count = models.PositiveIntegerField(
        default=0,
        verbose_name='SMS inclus'
    )
    validity_days = models.PositiveIntegerField(
        default=30,
        verbose_name='Validite (jours)'
    )
    features = models.JSONField(
        default=list,
        blank=True,
        verbose_name='Avantages inclus'
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name='Actif'
    )
    is_featured = models.BooleanField(
        default=False,
        verbose_name='Mis en avant'
    )
    display_order = models.PositiveIntegerField(
        default=0,
        verbose_name='Ordre d\'affichage'
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
        verbose_name = 'Offre'
        verbose_name_plural = 'Offres'
        ordering = ['display_order', '-is_featured', 'name']

    def __str__(self):
        return f"{self.name} - {self.price} {self.currency}"

    @property
    def data_allowance_gb(self):
        """Return data allowance in GB."""
        return self.data_allowance_mb / 1024

    @property
    def formatted_price(self):
        """Return formatted price."""
        return f"{int(self.price)} DA"
