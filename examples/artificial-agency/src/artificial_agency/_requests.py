"""Types representing requests sent to the Artificial.Agency API."""

from typing import Any, Sequence

import pydantic

from artificial_agency import _types, api_types


class APIRequest(pydantic.BaseModel):
    model_config = {
        "arbitrary_types_allowed": True,
    }

    def model_dump(self, **kwargs):
        exclude = kwargs.get("exclude", set())

        # Find fields with NotGiven values and add them to exclude
        for field_name, field_value in self.__dict__.items():
            if field_value is _types.NotGiven:
                if isinstance(exclude, set):
                    exclude.add(field_name)
                else:
                    exclude = set(exclude)
                    exclude.add(field_name)
        kwargs["exclude"] = exclude
        return super().model_dump(**kwargs, exclude_unset=True)


class CreateSessionRequest(APIRequest):
    project_id: str
    metadata: dict[str, str] | type[_types.NotGiven] = _types.NotGiven
    expires_in: int | None | type[_types.NotGiven] = _types.NotGiven
    max_requests: int | None | type[_types.NotGiven] = _types.NotGiven


class CloneSessionRequest(APIRequest):
    moment_id: str | None | type[_types.NotGiven] = _types.NotGiven
    origin_moments: dict[str, int] | None | type[_types.NotGiven] = _types.NotGiven
    project_id: str | None | type[_types.NotGiven] = _types.NotGiven
    metadata: dict[str, str] | type[_types.NotGiven] = _types.NotGiven
    expires_in: int | None | type[_types.NotGiven] = _types.NotGiven
    max_requests: int | None | type[_types.NotGiven] = _types.NotGiven


class CreateAgentRequest(APIRequest):
    ui_config: api_types.UIConfig | type[_types.NotGiven] = _types.NotGiven
    role_config: api_types.RoleConfig
    presentation_config: api_types.PresentationConfig
    component_configs: Sequence[api_types.ComponentConfig | dict[str, Any]]
    service_configs: Sequence[api_types.ServiceConfig | dict[str, Any]]
    agent_llm: str


class AddMessagesRequest(APIRequest):
    messages: Sequence[api_types.GameMessage]


class UpdateHistoryRequest(APIRequest):
    """Deprecated: use add_messages() and AddMessagesRequest instead."""

    messages: Sequence[api_types.GameMessage]


class GenerateTextRequest(APIRequest):
    messages: Sequence[api_types.GameMessage] | type[_types.NotGiven] = _types.NotGiven
    cue: str | None | type[_types.NotGiven] = _types.NotGiven
    service_id: str | None | type[_types.NotGiven] = _types.NotGiven
    presentation_config: api_types.PresentationConfig | type[_types.NotGiven] = (
        _types.NotGiven
    )


class GenerateFunctionCallRequest(APIRequest):
    messages: Sequence[api_types.GameMessage] | type[_types.NotGiven] = _types.NotGiven
    functions: Sequence[api_types.FunctionDescription]
    cue: str | None | type[_types.NotGiven] = _types.NotGiven
    service_id: str | None | type[_types.NotGiven] = _types.NotGiven
    presentation_config: api_types.PresentationConfig | type[_types.NotGiven] = (
        _types.NotGiven
    )


class GenerateJSONRequest(APIRequest):
    messages: Sequence[api_types.GameMessage] | type[_types.NotGiven] = _types.NotGiven
    # the name "schema" is used internally by pydantic.
    schema_: dict[str, Any] = pydantic.Field(alias="schema")
    cue: str | None | type[_types.NotGiven] = _types.NotGiven
    service_id: str | None | type[_types.NotGiven] = _types.NotGiven
    presentation_config: api_types.PresentationConfig | type[_types.NotGiven] = (
        _types.NotGiven
    )
