from django.test import TestCase
from django.utils import timezone
from datetime import datetime, time
from core.models import BarberShop
from scheduler.models import Staff, Service, Appointment
from payments.models import PaymentIntentRecord

class PaymentsModelsTestCase(TestCase):
    def setUp(self):
        # 1. Setup dependecies
        self.shop = BarberShop.objects.create(
            name="Payments Shop",
            whatsapp_number="1212121212",
            is_active=True
        )
        self.staff = Staff.objects.create(
            shop=self.shop,
            name="Clara Barber",
            is_active=True
        )
        self.service = Service.objects.create(
            shop=self.shop,
            name="Hair Spa",
            price=400.00,
            duration_minutes=60,
            is_active=True
        )
        
        start_dt = timezone.make_aware(datetime.combine(timezone.now().date(), time(16, 0)))
        self.appointment = Appointment.objects.create(
            shop=self.shop,
            staff=self.staff,
            service=self.service,
            client_name="Alice Green",
            client_phone="5558888",
            start_time=start_dt
        )

    def test_payment_intent_creation(self):
        record = PaymentIntentRecord.objects.create(
            appointment=self.appointment,
            provider="stripe",
            external_checkout_id="cs_test_abc123",
            amount=400.00,
            currency="MXN",
            status="pending",
            checkout_url="https://checkout.stripe.com/pay/cs_test_abc123"
        )
        
        self.assertEqual(record.appointment, self.appointment)
        self.assertEqual(record.provider, "stripe")
        self.assertEqual(record.external_checkout_id, "cs_test_abc123")
        self.assertEqual(record.amount, 400.00)
        self.assertEqual(record.currency, "MXN")
        self.assertEqual(record.status, "pending")
        self.assertEqual(record.checkout_url, "https://checkout.stripe.com/pay/cs_test_abc123")
        self.assertEqual(str(record), "STRIPE - 400.00 MXN (pending)")
        
        record.status = "succeeded"
        record.paid_at = timezone.now()
        record.save()
        
        self.assertEqual(record.status, "succeeded")
        self.assertIsNotNone(record.paid_at)
