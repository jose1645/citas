from datetime import datetime, timedelta
import pytz
from django.db.models import Q
from .models import BarberShop, Staff, Service, Appointment

class BookingService:
    @staticmethod
    def get_shop_data_for_flow(shop):
        """
        Prepares services and staff list for the WhatsApp Flow.
        """
        services = Service.objects.filter(shop=shop)
        staff_members = Staff.objects.filter(shop=shop, is_active=True)
        
        return {
            "services": [
                {"id": str(s.id), "title": s.name, "description": f"${s.price} - {s.duration_minutes} min"}
                for s in services
            ],
            "staff": [
                {"id": str(st.id), "title": st.name}
                for st in staff_members
            ]
        }

    @staticmethod
    def get_available_slots(shop, staff_id, date_str):
        """
        Calculates available slots for a specific staff on a given date.
        Simplification: 9 AM to 6 PM, every 30 mins.
        """
        # TODO: Implement real availability logic checking existing appointments
        # For now, return a static list of slots
        slots = []
        start_hour = 9
        end_hour = 18
        
        for hour in range(start_hour, end_hour):
            for minute in [0, 30]:
                slots.append({
                    "id": f"{hour:02d}:{minute:02d}",
                    "title": f"{hour:02d}:{minute:02d}"
                })
        
        return slots

    @staticmethod
    def create_appointment(shop, client_phone, client_name, service_id, staff_id, date_str, time_str):
        """
        Creates an appointment in the database.
        """
        # Parse date and time
        # Expecting date_str like "2026-05-10" and time_str like "14:30"
        dt_str = f"{date_str} {time_str}"
        naive_dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M")
        
        # Adjust timezone based on shop
        tz = pytz.timezone(shop.timezone)
        aware_dt = tz.localize(naive_dt)

        appointment = Appointment.objects.create(
            shop=shop,
            client_phone=client_phone,
            client_name=client_name,
            service_id=service_id,
            staff_id=staff_id,
            start_time=aware_dt,
            status='scheduled'
        )
        return appointment
