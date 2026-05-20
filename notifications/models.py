from django.db import models
from core.models import BarberShop
from scheduler.models import Appointment

class WhatsAppTemplateConfig(models.Model):
    shop = models.ForeignKey(BarberShop, on_delete=models.CASCADE, related_name='notification_templates')
    template_name = models.CharField(max_length=150)
    language_code = models.CharField(max_length=10, default="es_MX")
    category = models.CharField(max_length=50, default="utility")
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.template_name} ({self.shop.name})"

class NotificationLog(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pendiente'),
        ('sent', 'Enviado'),
        ('delivered', 'Entregado'),
        ('read', 'Leído'),
        ('failed', 'Fallido')
    ]
    appointment = models.ForeignKey(Appointment, on_delete=models.CASCADE, related_name='notifications')
    recipient_phone = models.CharField(max_length=20)
    message_type = models.CharField(max_length=50) # confirmation, reminder_2h, reminder_24h
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    meta_message_id = models.CharField(max_length=100, blank=True, null=True)
    sent_at = models.DateTimeField(auto_now_add=True)
    error_message = models.TextField(blank=True, null=True)

    def __str__(self):
        return f"{self.message_type} a {self.recipient_phone} ({self.status})"
