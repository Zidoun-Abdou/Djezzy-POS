from django.core.management.base import BaseCommand
from apps.offers.models import Offer
from apps.phone_numbers.models import PhoneNumber


class Command(BaseCommand):
    help = 'Load sample data for Djezzy POS (5 offers and 5 phone numbers)'

    def handle(self, *args, **options):
        self.stdout.write('Loading sample data...')

        # Create offers
        offers_data = [
            {
                'name': 'LEGEND 1500',
                'code': 'legend_1500',
                'description': 'L\'offre premium avec 50 Go de data',
                'price': 1500,
                'data_allowance_mb': 50 * 1024,  # 50 Go
                'voice_minutes': 500,
                'sms_count': 100,
                'validity_days': 30,
                'features': [
                    '50 Go de data 4G',
                    '500 minutes vers tous les reseaux',
                    '100 SMS gratuits',
                    'Appels illimites vers Djezzy',
                    'Acces 4G prioritaire'
                ],
                'is_featured': True,
                'display_order': 1,
            },
            {
                'name': 'LEGEND 1000',
                'code': 'legend_1000',
                'description': 'Une offre equilibree avec 30 Go',
                'price': 1000,
                'data_allowance_mb': 30 * 1024,  # 30 Go
                'voice_minutes': 300,
                'sms_count': 50,
                'validity_days': 30,
                'features': [
                    '30 Go de data 4G',
                    '300 minutes vers tous les reseaux',
                    '50 SMS gratuits',
                    'Appels illimites vers Djezzy'
                ],
                'is_featured': False,
                'display_order': 2,
            },
            {
                'name': 'LEGEND 150',
                'code': 'legend_150',
                'description': 'Offre hebdomadaire avec 5 Go',
                'price': 150,
                'data_allowance_mb': 5 * 1024,  # 5 Go
                'voice_minutes': 60,
                'sms_count': 20,
                'validity_days': 7,
                'features': [
                    '5 Go de data 4G',
                    '60 minutes vers tous les reseaux',
                    '20 SMS gratuits'
                ],
                'is_featured': False,
                'display_order': 3,
            },
            {
                'name': 'LEGEND 100',
                'code': 'legend_100',
                'description': 'Offre 3 jours avec 3 Go',
                'price': 100,
                'data_allowance_mb': 3 * 1024,  # 3 Go
                'voice_minutes': 30,
                'sms_count': 10,
                'validity_days': 3,
                'features': [
                    '3 Go de data 4G',
                    '30 minutes vers tous les reseaux',
                    '10 SMS gratuits'
                ],
                'is_featured': False,
                'display_order': 4,
            },
            {
                'name': 'LEGEND 50',
                'code': 'legend_50',
                'description': 'Offre journaliere avec 1 Go',
                'price': 50,
                'data_allowance_mb': 1 * 1024,  # 1 Go
                'voice_minutes': 15,
                'sms_count': 5,
                'validity_days': 1,
                'features': [
                    '1 Go de data 4G',
                    '15 minutes vers tous les reseaux',
                    '5 SMS gratuits'
                ],
                'is_featured': False,
                'display_order': 5,
            },
        ]

        for offer_data in offers_data:
            offer, created = Offer.objects.update_or_create(
                code=offer_data['code'],
                defaults=offer_data
            )
            status = 'Created' if created else 'Updated'
            self.stdout.write(f'  {status}: {offer.name}')

        # Create phone numbers
        phone_numbers = [
            '0770123456',
            '0771234567',
            '0772345678',
            '0773456789',
            '0774567890',
        ]

        for number in phone_numbers:
            phone, created = PhoneNumber.objects.update_or_create(
                number=number,
                defaults={'status': 'available'}
            )
            status = 'Created' if created else 'Updated'
            self.stdout.write(f'  {status}: {phone.formatted_number}')

        self.stdout.write(self.style.SUCCESS(
            f'Successfully loaded {len(offers_data)} offers and {len(phone_numbers)} phone numbers'
        ))
