import requests
import json
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class WhatsAppClient:
    def __init__(self):
        self.access_token = getattr(settings, 'WHATSAPP_ACCESS_TOKEN', None)
        self.phone_number_id = getattr(settings, 'WHATSAPP_PHONE_NUMBER_ID', None)
        self.api_version = 'v19.0'
        self.base_url = f"https://graph.facebook.com/{self.api_version}/{self.phone_number_id}"

    def send_message(self, to, message_data):
        if not self.access_token or not self.phone_number_id:
            logger.error("WhatsApp credentials not configured")
            return None

        url = f"{self.base_url}/messages"
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "messaging_product": "whatsapp",
            "to": to,
            **message_data
        }

        try:
            response = requests.post(url, headers=headers, json=payload)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Error sending WhatsApp message: {str(e)}")
            if hasattr(e, 'response') and e.response is not None:
                logger.error(f"Response: {e.response.text}")
            return None

    def send_text(self, to, text):
        data = {
            "type": "text",
            "text": {"body": text}
        }
        return self.send_message(to, data)

    def send_template(self, to, template_name, language_code="es_MX", components=None):
        data = {
            "type": "template",
            "template": {
                "name": template_name,
                "language": {"code": language_code},
            }
        }
        if components:
            data["template"]["components"] = components
        return self.send_message(to, data)

    def send_flow(self, to, flow_id, flow_token, flow_cta, flow_data=None):
        """
        Sends a message to trigger a WhatsApp Flow.
        """
        data = {
            "type": "interactive",
            "interactive": {
                "type": "flow",
                "header": {
                    "type": "text",
                    "text": "Reserva tu Cita"
                },
                "body": {
                    "text": "Haz clic abajo para seleccionar tu servicio y horario."
                },
                "footer": {
                    "text": "Bot Barber"
                },
                "action": {
                    "name": "flow",
                    "parameters": {
                        "flow_message_version": "3",
                        "flow_token": flow_token,
                        "flow_id": flow_id,
                        "flow_cta": flow_cta,
                        "flow_action": "navigate",
                        "flow_data": flow_data or {},
                    }
                }
            }
        }
        return self.send_message(to, data)
