from ninja import NinjaAPI
from core.api import router as core_router

api = NinjaAPI(title="FlowCuts API", version="1.0.0")

api.add_router("/core/", core_router)
