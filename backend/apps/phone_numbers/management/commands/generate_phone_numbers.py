"""
Management command to generate sample phone numbers for testing.
"""

import random
from django.core.management.base import BaseCommand
from apps.phone_numbers.models import PhoneNumber
from apps.offers.models import Offer


class Command(BaseCommand):
    help = 'Generate sample phone numbers distributed across offers'

    def add_arguments(self, parser):
        parser.add_argument(
            '--count',
            type=int,
            default=200,
            help='Total number of phone numbers to generate (default: 200)'
        )
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing phone numbers before generating new ones'
        )

    def handle(self, *args, **options):
        count = options['count']

        if options['clear']:
            deleted_count = PhoneNumber.objects.all().delete()[0]
            self.stdout.write(
                self.style.WARNING(f'Deleted {deleted_count} existing phone numbers')
            )

        # Get all active offers
        offers = list(Offer.objects.filter(is_active=True).order_by('price'))

        if not offers:
            self.stdout.write(
                self.style.ERROR('No active offers found. Run load_djezzy_offers first.')
            )
            return

        # Djezzy number prefixes (07XX format)
        prefixes = ['0770', '0771', '0772', '0773', '0774', '0775', '0776', '0777', '0778', '0779']

        # Distribution: more numbers for popular mid-tier offers
        # Higher price = premium = fewer numbers, Lower price = more affordable = more numbers
        distribution = self._calculate_distribution(offers, count)

        generated_count = 0
        skipped_count = 0

        for offer, num_to_generate in distribution.items():
            self.stdout.write(f'Generating {num_to_generate} numbers for {offer.name}...')

            for _ in range(num_to_generate):
                # Generate unique phone number
                for attempt in range(100):  # Max 100 attempts per number
                    prefix = random.choice(prefixes)
                    suffix = ''.join([str(random.randint(0, 9)) for _ in range(6)])
                    number = f'{prefix}{suffix}'

                    if not PhoneNumber.objects.filter(number=number).exists():
                        PhoneNumber.objects.create(
                            number=number,
                            offer=offer,
                            status='available'
                        )
                        generated_count += 1
                        break
                else:
                    skipped_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f'\nDone! Generated: {generated_count} phone numbers'
            )
        )

        if skipped_count > 0:
            self.stdout.write(
                self.style.WARNING(f'Skipped: {skipped_count} (duplicates)')
            )

        # Show distribution summary
        self.stdout.write('\nDistribution by offer:')
        for offer in offers:
            count = PhoneNumber.objects.filter(offer=offer).count()
            self.stdout.write(f'  - {offer.name}: {count} numbers')

    def _calculate_distribution(self, offers, total_count):
        """
        Calculate number distribution across offers.
        Mid-tier offers get more numbers, premium gets fewer.
        """
        distribution = {}
        num_offers = len(offers)

        # Weight distribution (middle offers get more)
        if num_offers == 1:
            distribution[offers[0]] = total_count
        else:
            # Create bell curve-like distribution
            weights = []
            for i in range(num_offers):
                # Distance from middle (0 = middle, higher = edges)
                middle = (num_offers - 1) / 2
                distance = abs(i - middle)
                # Weight decreases with distance from middle
                weight = max(1, 3 - distance)
                weights.append(weight)

            total_weight = sum(weights)

            remaining = total_count
            for i, offer in enumerate(offers):
                if i == num_offers - 1:
                    # Last offer gets remaining
                    distribution[offer] = remaining
                else:
                    count = int(total_count * weights[i] / total_weight)
                    distribution[offer] = count
                    remaining -= count

        return distribution
