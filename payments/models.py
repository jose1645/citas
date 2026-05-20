from django.db import models
from scheduler.models import Appointment

class PaymentIntentRecord(models.Model):
    PROVIDER_CHOICES = [
        ('stripe', 'Stripe'),
        ('mercadopago', 'Mercado Pago')
    ]
    STATUS_CHOICES = [
        ('pending', 'Pendiente de Pago'),
        ('succeeded', 'Completado'),
        ('failed', 'Fallido'),
        ('refunded', 'Reembolsado')
    ]
    appointment = models.OneToOneField(Appointment, on_delete=models.CASCADE, related_name='payment')
    provider = models.CharField(max_length=20, choices=PROVIDER_CHOICES)
    external_checkout_id = models.CharField(max_length=255)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=5, default='MXN')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    checkout_url = models.URLField(max_length=1000)
    paid_at = models.DateTimeField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.provider.upper()} - {self.amount:.2f} {self.currency} ({self.status})"
