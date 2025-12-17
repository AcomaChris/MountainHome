"""Types that are part of this library's public interface."""

from typing import Any, TypeAlias

import pydantic

from artificial_agency.generated_api_types import (
    function_description,
    introspection,
    presentation_config,
    role_config,
    service_config,
    ui_config,
)

# re-export generated types
from artificial_agency.generated_api_types.component_config import (
    FunctionHinterConfig,
    KVStoreConfig,
    LimitedListConfig,
    PuppeteerKVStoreConfig,
    PuppeteerLimitedListConfig,
    StaticTextConfig,
    TextBlockConfig,
)
from artificial_agency.generated_api_types.function_description import (
    ArrayParameter,
    ObjectParameter,
    SimpleParameter,
)
from artificial_agency.generated_api_types.messages import (
    ContentMessage,
    FunctionCall,
    KVDelTreeMessage,
    KVMessage,
    PuppeteerMessage,
    Type,
)

# re-exported types
FunctionDescription = function_description.FunctionDescription
PresentationConfig = presentation_config.PresentationConfig
PresentationOrderItem = presentation_config.PresentationOrderItem
RoleConfig = role_config.RoleConfig
UIConfig = ui_config.UIConfig

# re-exported introspection types
Service = introspection.Service

# unions
ComponentConfig: TypeAlias = (
    FunctionHinterConfig
    | KVStoreConfig
    | LimitedListConfig
    | PuppeteerKVStoreConfig
    | PuppeteerLimitedListConfig
    | StaticTextConfig
    | TextBlockConfig
)
ServiceConfig: TypeAlias = service_config.ServiceConfig
FunctionParameters: TypeAlias = SimpleParameter | ArrayParameter | ObjectParameter


GameMessage: TypeAlias = (
    ContentMessage | KVMessage | KVDelTreeMessage | PuppeteerMessage
)


FunctionCall = FunctionCall
FunctionResultType = Type


class APIResponse(pydantic.BaseModel):
    pass


class Session(APIResponse):
    id: str
    created_at: int
    project_id: str | None
    metadata: dict[str, str]
    expires_at: int | None
    max_requests: int | None


class DestroySessionResponse(APIResponse):
    success: bool
    session_key: str | None
    error_message: str | None


class CreateAgentResponse(APIResponse):
    id: str
    session_id: str
    moment_id: int
    moment_uuid: str
    ui_config: ui_config.UIConfig


class MessagesAdded(APIResponse):
    moment_id: str


class HistoryUpdated(APIResponse):
    """Deprecated: use add_messages() and MessagesAdded instead."""

    moment_id: str


class TextGenerated(APIResponse):
    moment_id: str
    text: str


class FunctionCallGenerated(APIResponse):
    class FunctionCall(pydantic.BaseModel):
        id: str
        name: str
        args: dict[str, Any]

    moment_id: str
    function_call: FunctionCall


class JSONGenerated(APIResponse):
    moment_id: str
    # the name "json" is used internally by pydantic.
    json_: Any = pydantic.Field(alias="json")


class ListResponse(APIResponse, introspection.ListResponse):
    pass
