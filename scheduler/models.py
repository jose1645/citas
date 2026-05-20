from django.db import models
from datetime import timedelta

class Staff(models.Model):
    shop = models.ForeignKey('core.BarberShop', on_delete=models.CASCADE, related_name='staff')
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'core_staff'

    def __str__(self):
        return f"{self.name} - {self.shop.name}"

class StaffSchedule(models.Model):
    DAY_CHOICES = [
        (0, 'Lunes'), (1, 'Martes'), (2, 'Miércoles'), 
        (3, 'Jueves'), (4, 'Viernes'), (5, 'Sábado'), (6, 'Domingo')
    ]
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='schedules')
    day_of_week = models.IntegerField(choices=DAY_CHOICES)
    start_time = models.TimeField()
    end_time = models.TimeField()
    is_working = models.BooleanField(default=True)

    class Meta:
        unique_together = ('staff', 'day_of_week')

    def __str__(self):
        day_name = dict(self.DAY_CHOICES).get(self.day_of_week, str(self.day_of_week))
        return f"{self.staff.name} - {day_name} ({self.start_time} - {self.end_time})"

class TimeBlocker(models.Model):
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='blockers')
    start_datetime = models.DateTimeField()
    end_datetime = models.DateTimeField()
    reason = models.CharField(max_length=150, blank=True, null=True)

    def __str__(self):
        return f"Bloqueo {self.staff.name} ({self.start_datetime} a {self.end_datetime})"

class Service(models.Model):
    shop = models.ForeignKey('core.BarberShop', on_delete=models.CASCADE, related_name='services')
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_minutes = models.PositiveIntegerField(default=30)
    image_url = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'core_service'

    def get_retailer_id(self):
        return f"shop_{self.shop.id}_service_{self.id}"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Sync with Meta Catalog
        try:
            from core.utils import WhatsAppClient
            client = WhatsAppClient()
            client.sync_catalog_product(
                retailer_id=self.get_retailer_id(),
                name=self.name,
                description=self.description,
                price=self.price,
                image_url=self.image_url,
                is_active=self.is_active
            )
        except Exception as e:
            # Prevent failure during tests/offline modes
            pass

    def delete(self, *args, **kwargs):
        retailer_id = self.get_retailer_id()
        try:
            from core.utils import WhatsAppClient
            client = WhatsAppClient()
            client.delete_catalog_product(retailer_id)
        except Exception as e:
            pass
        super().delete(*args, **kwargs)

    def __str__(self):
        return f"{self.name} - {self.shop.name}"

class Appointment(models.Model):
    shop = models.ForeignKey('core.BarberShop', on_delete=models.CASCADE, related_name='appointments')
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointments')
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    client_name = models.CharField(max_length=100)
    client_phone = models.CharField(max_length=20)
    start_time = models.DateTimeField()
    end_time = models.DateTimeField(blank=True, null=True)
    status = models.CharField(max_length=20, default='scheduled')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'core_appointment'

    def save(self, *args, **kwargs):
        if not self.end_time and self.start_time and self.service:
            self.end_time = self.start_time + timedelta(minutes=self.service.duration_minutes)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"Cita: {self.client_name} - {self.start_time}"
