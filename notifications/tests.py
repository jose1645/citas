from django.test import TestCase
from django.utils import timezone
from datetime import datetime, time
from core.models import BarberShop
from scheduler.models import Staff, Service, Appointment
from notifications.models import WhatsAppTemplateConfig, NotificationLog

class NotificationsModelsTestCase(TestCase):
    def setUp(self):
        # 1. Setup dependecies
        self.shop = BarberShop.objects.create(
            name="Notifications Shop",
            whatsapp_number="9876543210",
            is_active=True
        )
        self.staff = Staff.objects.create(
            shop=self.shop,
            name="Sam Barber",
            is_active=True
        )
        self.service = Service.objects.create(
            shop=self.shop,
            name="Beard Trim",
            price=150.00,
            duration_minutes=20,
            is_active=True
        )
        
        start_dt = timezone.make_aware(datetime.combine(timezone.now().date(), time(14, 30)))
        self.appointment = Appointment.objects.create(
            shop=self.shop,
            staff=self.staff,
            service=self.service,
            client_name="Bob Smith",
            client_phone="5550000",
            start_time=start_dt
        )
        
        # 2. Setup Template config
        self.template_config = WhatsAppTemplateConfig.objects.create(
            shop=self.shop,
            template_name="appointment_reminder_sp",
            language_code="es_MX",
            category="utility",
            is_active=True
        )

    def test_template_config_creation(self):
        self.assertEqual(self.template_config.template_name, "appointment_reminder_sp")
        self.assertEqual(self.template_config.language_code, "es_MX")
        self.assertTrue(self.template_config.is_active)
        self.assertEqual(str(self.template_config), "appointment_reminder_sp (Notifications Shop)")

    def test_notification_log_creation(self):
        log = NotificationLog.objects.create(
            appointment=self.appointment,
            recipient_phone="5550000",
            message_type="confirmation",
            status="pending"
        )
        self.assertEqual(log.appointment, self.appointment)
        self.assertEqual(log.recipient_phone, "5550000")
        self.assertEqual(log.message_type, "confirmation")
        self.assertEqual(log.status, "pending")
        self.assertEqual(str(log), "confirmation a 5550000 (pending)")
        
        log.status = "sent"
        log.meta_message_id = "meta_msg_abc123"
        log.save()
        self.assertEqual(log.status, "sent")
        self.assertEqual(log.meta_message_id, "meta_msg_abc123")
