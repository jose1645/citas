from django.test import TestCase
from django.utils import timezone
from datetime import datetime, time, timedelta
from core.models import BarberShop
from scheduler.models import Staff, Service, Appointment, StaffSchedule, TimeBlocker

class SchedulerModelsTestCase(TestCase):
    def setUp(self):
        # 1. Create a BarberShop
        self.shop = BarberShop.objects.create(
            name="Test Barber Shop",
            whatsapp_number="1234567890",
            is_active=True
        )
        
        # 2. Create Staff
        self.staff = Staff.objects.create(
            shop=self.shop,
            name="Alex Barber",
            is_active=True
        )

        # 3. Create Service
        self.service = Service.objects.create(
            shop=self.shop,
            name="Classic Cut",
            price=250.00,
            duration_minutes=45,
            is_active=True
        )

    def test_staff_creation(self):
        self.assertEqual(self.staff.name, "Alex Barber")
        self.assertTrue(self.staff.is_active)
        self.assertEqual(str(self.staff), "Alex Barber - Test Barber Shop")

    def test_service_creation(self):
        self.assertEqual(self.service.name, "Classic Cut")
        self.assertEqual(self.service.price, 250.00)
        self.assertEqual(self.service.duration_minutes, 45)
        self.assertEqual(self.service.get_retailer_id(), f"shop_{self.shop.id}_service_{self.service.id}")

    def test_appointment_auto_end_time(self):
        # Create an appointment starting today at 10:00 AM
        start_dt = timezone.make_aware(datetime.combine(timezone.now().date(), time(10, 0)))
        
        appt = Appointment.objects.create(
            shop=self.shop,
            staff=self.staff,
            service=self.service,
            client_name="John Doe",
            client_phone="5551234",
            start_time=start_dt
        )
        
        # end_time should be calculated: start_time + 45 minutes
        expected_end_dt = start_dt + timedelta(minutes=45)
        self.assertEqual(appt.end_time, expected_end_dt)
        self.assertEqual(appt.status, "scheduled")

    def test_staff_schedule(self):
        schedule = StaffSchedule.objects.create(
            staff=self.staff,
            day_of_week=0,  # Lunes
            start_time=time(9, 0),
            end_time=time(18, 0),
            is_working=True
        )
        self.assertEqual(schedule.day_of_week, 0)
        self.assertTrue(schedule.is_working)
        self.assertEqual(str(schedule), "Alex Barber - Lunes (09:00:00 - 18:00:00)")

    def test_time_blocker(self):
        start_dt = timezone.now()
        end_dt = start_dt + timedelta(hours=1)
        
        blocker = TimeBlocker.objects.create(
            staff=self.staff,
            start_datetime=start_dt,
            end_datetime=end_dt,
            reason="Lunch Break"
        )
        self.assertEqual(blocker.reason, "Lunch Break")
        self.assertEqual(blocker.start_datetime, start_dt)
