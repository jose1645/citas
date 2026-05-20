import requests
import json
import logging
from django.conf import settings

logger = logging.getLogger(__name__)

class WhatsAppClient:
    def __init__(self, access_token=None, phone_number_id=None):
        from .models import MetaConfig
        db_config = MetaConfig.objects.filter(is_active=True).first()
        self.access_token = access_token or (db_config.access_token if db_config else None) or getattr(settings, 'WHATSAPP_ACCESS_TOKEN', None)
        self.phone_number_id = phone_number_id or getattr(settings, 'WHATSAPP_PHONE_NUMBER_ID', None)
        self.api_version = 'v19.0'
        self.base_url = f"https://graph.facebook.com/{self.api_version}/{self.phone_number_id}"

    def verify_connection(self):
        if not self.access_token or not self.phone_number_id:
            return False, "Credenciales no configuradas"
        url = f"https://graph.facebook.com/{self.api_version}/{self.phone_number_id}"
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                data = response.json()
                return True, f"Conexión OK: {data.get('display_phone_number')}"
            return False, f"Error Meta: {response.text}"
        except Exception as e:
            return False, str(e)

    def verify_waba_connection(self, waba_id):
        if not self.access_token or not waba_id: return False, "Token/WABA faltante"
        url = f"https://graph.facebook.com/{self.api_version}/{waba_id}"
        headers = {"Authorization": f"Bearer {self.access_token}"}
        try:
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                data = response.json()
                return True, f"WABA OK: {data.get('name')}"
            return False, f"Error WABA: {response.text}"
        except Exception as e:
            return False, str(e)

    def send_message(self, to, message_data):
        if not self.access_token or not self.phone_number_id:
            return {"error": {"message": "Credenciales incompletas"}}

        url = f"{self.base_url}/messages"
        headers = {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }
        payload = {"messaging_product": "whatsapp", "to": to, **message_data}

        try:
            logger.info(f"Sending payload: {json.dumps(payload)}")
            response = requests.post(url, headers=headers, json=payload)
            resp_json = response.json()
            if "error" in resp_json:
                logger.error(f"Error sending message: {resp_json}")
            else:
                logger.info(f"Message sent successfully: {resp_json}")
            # Devolvemos el JSON de Meta siempre, sea éxito o error
            return resp_json
        except Exception as e:
            logger.error(f"Network error sending message: {str(e)}")
            return {"error": {"message": f"Error de red: {str(e)}"}}

    def send_text(self, to, text):
        return self.send_message(to, {"type": "text", "text": {"body": text}})

    def send_template(self, to, template_name, language_code="es_MX", components=None):
        data = {"type": "template", "template": {"name": template_name, "language": {"code": language_code}}}
        if components: data["template"]["components"] = components
        return self.send_message(to, data)

    def send_location(self, to, latitude, longitude, name, address):
        data = {
            "type": "location",
            "location": {
                "latitude": float(latitude),
                "longitude": float(longitude),
                "name": name,
                "address": address
            }
        }
        return self.send_message(to, data)

    def send_flow(self, to, flow_id, flow_token, flow_cta, flow_action="data_exchange", flow_data=None):
        parameters = {
            "flow_message_version": "3",
            "flow_token": flow_token,
            "flow_id": flow_id,
            "flow_cta": flow_cta,
            "flow_action": flow_action,
        }
        # Solo incluir flow_action_payload para flujos estáticos/navegación inicial
        if flow_action == "navigate" and flow_data is not None:
            parameters["flow_action_payload"] = flow_data

        data = {
            "type": "interactive",
            "interactive": {
                "type": "flow",
                "header": {"type": "text", "text": "Reserva tu Cita"},
                "body": {"text": "Haz clic abajo para seleccionar tu servicio."},
                "footer": {"text": "Bot Barber"},
                "action": {
                    "name": "flow",
                    "parameters": parameters
                }
            }
        }
        return self.send_message(to, data)

    def sync_catalog_product(self, retailer_id, name, description, price, image_url, is_active=True, brand="Bot Barber"):
        from .models import MetaConfig
        db_config = MetaConfig.objects.filter(is_active=True).first()
        catalog_id = db_config.catalog_id if db_config else None
        if not catalog_id or not self.access_token:
            logger.warning("No catalog_id or access_token to sync product.")
            return False
            
        # We use the Batch API to UPSERT (update if exists, create if not)
        batch_url = f"https://graph.facebook.com/{self.api_version}/{catalog_id}/batch"
        headers = {"Authorization": f"Bearer {self.access_token}", "Content-Type": "application/json"}
        
        price_cents = int(float(price) * 100)
        default_img = "https://placehold.co/600x400/2C3E50/FFFFFF/png?text=Servicio"
        
        batch_payload = {
            "allow_upsert": True,
            "requests": [
                {
                    "method": "UPDATE",
                    "retailer_id": retailer_id,
                    "data": {
                        "name": name[:100],
                        "description": (description or name)[:5000],
                        "price": price_cents,
                        "currency": "MXN",
                        "url": "https://barber.synteck.org/",
                        "image_url": image_url or default_img,
                        "condition": "new",
                        "availability": "in stock" if is_active else "out of stock",
                        "brand": brand[:100]
                    }
                }
            ]
        }
        
        try:
            response = requests.post(batch_url, headers=headers, json=batch_payload)
            logger.info(f"Sync product {retailer_id} response: {response.text}")
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Error syncing product: {e}")
            return False

    def delete_catalog_product(self, retailer_id):
        from .models import MetaConfig
        db_config = MetaConfig.objects.filter(is_active=True).first()
        catalog_id = db_config.catalog_id if db_config else None
        if not catalog_id or not self.access_token:
            return False
            
        batch_url = f"https://graph.facebook.com/{self.api_version}/{catalog_id}/batch"
        headers = {"Authorization": f"Bearer {self.access_token}", "Content-Type": "application/json"}
        batch_payload = {
            "requests": [{"method": "DELETE", "retailer_id": retailer_id}]
        }
        try:
            response = requests.post(batch_url, headers=headers, json=batch_payload)
            return response.status_code == 200
        except:
            return False

    def send_product_list(self, to, catalog_id, retailer_ids, body_text):
        if not catalog_id or not retailer_ids:
            return self.send_text(to, "Catálogo no disponible por el momento.")
            
        items = [{"product_retailer_id": rid} for rid in retailer_ids[:30]]
        data = {
            "type": "interactive",
            "interactive": {
                "type": "product_list",
                "header": {"type": "text", "text": "Catálogo de Servicios"},
                "body": {"text": body_text},
                "footer": {"text": "Bot Barber"},
                "action": {
                    "catalog_id": catalog_id,
                    "sections": [
                        {
                            "title": "Servicios Disponibles",
                            "product_items": items
                        }
                    ]
                }
            }
        }
        return self.send_message(to, data)
