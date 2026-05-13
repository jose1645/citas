from django.db import models
from django.contrib.auth.models import AbstractUser
from django.conf import settings

class User(AbstractUser):
    is_partner = models.BooleanField(default=False)
    is_owner = models.BooleanField(default=False)
    phone_number = models.CharField(max_length=20, blank=True, null=True)

    def __str__(self):
        return f"{self.username} ({'Partner' if self.is_partner else 'Owner'})"

class Partner(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='partner_profile')
    referral_code = models.CharField(max_length=20, unique=True)
    commission_rate = models.DecimalField(max_digits=5, decimal_places=2, default=20.00) # Percentage
    total_earned = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)

    def __str__(self):
        return f"Partner: {self.user.username} [{self.referral_code}]"

class BarberShop(models.Model):
    name = models.CharField(max_length=100)
    owner = models.ForeignKey(User, on_delete=models.CASCADE, related_name='shops')
    referred_by = models.ForeignKey(Partner, on_delete=models.SET_NULL, null=True, blank=True, related_name='referred_shops')
    whatsapp_number = models.CharField(max_length=20, unique=True)
    timezone = models.CharField(max_length=50, default='America/Mexico_City')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class Staff(models.Model):
    shop = models.ForeignKey(BarberShop, on_delete=models.CASCADE, related_name='staff')
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.name} @ {self.shop.name}"

class Service(models.Model):
    shop = models.ForeignKey(BarberShop, on_delete=models.CASCADE, related_name='services')
    name = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    duration_minutes = models.PositiveIntegerField(default=30)

    def __str__(self):
        return f"{self.name} (${self.price})"

class Appointment(models.Model):
    STATUS_CHOICES = [
        ('scheduled', 'Programada'),
        ('confirmed', 'Confirmada'),
        ('completed', 'Completada'),
        ('cancelled', 'Cancelada'),
    ]

    shop = models.ForeignKey(BarberShop, on_delete=models.CASCADE, related_name='appointments')
    staff = models.ForeignKey(Staff, on_delete=models.CASCADE, related_name='appointments')
    service = models.ForeignKey(Service, on_delete=models.CASCADE)
    client_name = models.CharField(max_length=100)
    client_phone = models.CharField(max_length=20)
    start_time = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.client_name} - {self.start_time} ({self.status})"
