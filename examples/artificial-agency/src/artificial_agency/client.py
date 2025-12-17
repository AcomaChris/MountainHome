import dataclasses
import warnings
from typing import Any, Sequence, TypeVar

import httpx
import pydantic

from artificial_agency import _requests, _types, api_types, constants, errors
from artificial_agency.generated_api_types import error as error_api_type

ResponseT = TypeVar("ResponseT", bound=api_types.APIResponse)


@dataclasses.dataclass
class Agent:
    session_id: str
    agent_id: str
    moment_id: int
    moment_uuid: str


class Client:
    def __init__(
        self,
        api_key: str,
        *,
        base_url: str = constants.API_URL,
        http_client: httpx.Client | None = None,
        timeout: int | float = constants.DEFAULT_REQUEST_TIMEOUT,
    ):
        if not api_key:
            raise ValueError("api_key must not be empty")

        self.api_key = api_key
        self.http_client = http_client or httpx.Client(base_url=base_url)
        self.timeout = timeout

    def _build_request(
        self,
        *,
        method: str,
        path: str,
        data: _requests.APIRequest | None,
        params: httpx.QueryParams | None = None,
    ) -> httpx.Request:
        if data:
            request_json = data.model_dump(mode="json", by_alias=True)
        else:
            request_json = None

        return self.http_client.build_request(
            method=method,
            url=path,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "AA-API-Version": constants.API_VERSION,
            },
            params=params,
            json=request_json,
            timeout=self.timeout,
        )

    def _process_request(
        self,
        *,
        method: str,
        path: str,
        data: _requests.APIRequest | None,
        return_type: type[ResponseT],
        params: httpx.QueryParams | None = None,
    ) -> ResponseT:
        request = self._build_request(
            method=method, path=path, data=data, params=params
        )
        try:
            response = self.http_client.send(request)
        except httpx.TimeoutException:
            raise errors.APITimeoutError(
                status_code=500, error_type="server_error", message="Request timed out."
            )

        if response.status_code != 200:
            try:
                error = error_api_type.ErrorResponseModel.model_validate_json(
                    response.content
                )
            except pydantic.ValidationError:
                raise errors.APIError(
                    status_code=response.status_code,
                    error_type="server_error",
                    message="The server returned an unexpected response.",
                )

            raise errors.APIError(
                status_code=response.status_code,
                error_type=str(error.error.type),
                message=error.error.message,
            )

        try:
            parsed = return_type.model_validate_json(response.content)
        except pydantic.ValidationError:
            raise errors.APIResponseValidationError(
                status_code=response.status_code,
                error_type="server_error",
                message="Server returned data in an unexpected format.",
            )

        return parsed

    def list_services(self) -> list[api_types.Service]:
        """List all services available to your organization."""
        result = self._process_request(
            method="GET",
            path="/v1/services",
            data=None,
            return_type=api_types.ListResponse,
        )

        return [api_types.Service.model_validate(s.model_dump()) for s in result.data]

    def create_session(
        self,
        *,
        project_id: str,
        metadata: dict[str, str] | type[_types.NotGiven] = _types.NotGiven,
        expires_in: int | None | type[_types.NotGiven] = _types.NotGiven,
        max_requests: int | None | type[_types.NotGiven] = _types.NotGiven,
    ) -> api_types.Session:
        """Create a new session.

        Args:
            project_id: The project ID.
            metadata:
                Arbitrary data that should be attached to the session.
            expires_in:
                A number of seconds that the new session should remain active for.
                "None" indicates that the session should not be limited by time.
            max_requests:
                A number of requests that the new session should remain active for.
                "None" indicates that the session should not be limited by a number of requests.
        """
        request = _requests.CreateSessionRequest(
            project_id=project_id,
            metadata=metadata,
            expires_in=expires_in,
            max_requests=max_requests,
        )

        result = self._process_request(
            method="POST",
            path="/v1/sessions",
            data=request,
            return_type=api_types.Session,
        )

        return result

    def clone_session(
        self,
        *,
        session_id: str,
        moment_id: str | None | type[_types.NotGiven] = _types.NotGiven,
        origin_moments: dict[str, int] | None | type[_types.NotGiven] = _types.NotGiven,
        project_id: str | None | type[_types.NotGiven] = _types.NotGiven,
        metadata: dict[str, str] | type[_types.NotGiven] = _types.NotGiven,
        expires_in: int | None | type[_types.NotGiven] = _types.NotGiven,
        max_requests: int | None | type[_types.NotGiven] = _types.NotGiven,
    ) -> api_types.Session:
        """Create a new session from an existing session at a given moment.

        Args:
            session_id: The ID of the session you want to clone.
            moment_id:
                The moment that you want to clone.
                "None" indicates that it should clone the most recent state of the session.
            origin_moments:
                A dictionary of agent IDs to moment IDs that should be used as the
                origin for each agent.  If not provided, all agents will be cloned from
                the moment specified by "moment_id".
            project_id:
                The project that this session should be attributed to.
                "None" indicates that it should use the same project as the original session.
            metadata:
                Arbitrary data that should be attached to the new session.
            expires_in:
                A number of seconds that the new session should remain active for.
                "None" indicates that the session should not be limited by time.
            max_requests:
                A number of requests that the new session should remain active for.
                "None" indicates that the session should not be limited by a number of requests.
        """
        payload = _requests.CloneSessionRequest(
            moment_id=moment_id,
            origin_moments=origin_moments,
            project_id=project_id,
            metadata=metadata,
            expires_in=expires_in,
            max_requests=max_requests,
        )

        result = self._process_request(
            method="POST",
            path=f"/v1/sessions/{session_id}/clone",
            data=payload,
            return_type=api_types.Session,
        )

        return result

    def create_agent(
        self,
        *,
        session_id: str,
        role_config: api_types.RoleConfig,
        presentation_config: api_types.PresentationConfig,
        component_configs: Sequence[api_types.ComponentConfig | dict[str, Any]],
        service_configs: Sequence[api_types.ServiceConfig | dict[str, Any]],
        agent_llm: str,
        ui_config: api_types.UIConfig | type[_types.NotGiven] = _types.NotGiven,
    ) -> Agent:
        """Create a new agent.

        Args:
            session_id: The ID of the session to create the agent within.
            role_config: Configuration of this agent's role.
            presentation_config: Configuration of this agent's presentation.
            component_configs: Configuration of this agent's components.
            service_configs: Configuration of this agent's services.
            agent_llm: The LLM service to use for agent generate_* requests.
            ui_config: Additional data used to present the agent in the UI.
        """
        request = _requests.CreateAgentRequest(
            ui_config=ui_config,
            role_config=role_config,
            presentation_config=presentation_config,
            component_configs=component_configs,
            service_configs=service_configs,
            agent_llm=agent_llm,
        )
        result = self._process_request(
            method="POST",
            path=f"/v1/advanced/sessions/{session_id}/agents",
            data=request,
            return_type=api_types.CreateAgentResponse,
        )
        return Agent(
            session_id=result.session_id,
            agent_id=result.id,
            moment_id=result.moment_id,
            moment_uuid=result.moment_uuid,
        )

    def update_history(
        self,
        *,
        session_id: str,
        agent_id: str,
        messages: Sequence[api_types.GameMessage],
    ) -> api_types.HistoryUpdated:
        """DEPRECATED: Use `add_messages` instead.

        Args:
            session_id: The session that this agent exists within.
            agent_id: The agent to target.
            messages: New history to store.
        """
        warnings.warn(
            "update_history is deprecated and will be removed in a future version. "
            "Use add_messages instead.",
            DeprecationWarning,
            stacklevel=2,
        )

        request = _requests.UpdateHistoryRequest(messages=messages)

        result = self._process_request(
            method="POST",
            path=f"/v1/sessions/{session_id}/agents/{agent_id}/messages",
            data=request,
            return_type=api_types.HistoryUpdated,
        )

        return result

    def add_messages(
        self,
        *,
        session_id: str,
        agent_id: str,
        messages: Sequence[api_types.GameMessage],
    ) -> api_types.MessagesAdded:
        """Update the agent state with new messages.

        Args:
            session_id: The session that this agent exists within.
            agent_id: The agent to target.
            messages: New history to store.
        """
        request = _requests.AddMessagesRequest(messages=messages)

        result = self._process_request(
            method="POST",
            path=f"/v1/sessions/{session_id}/agents/{agent_id}/messages",
            data=request,
            return_type=api_types.MessagesAdded,
        )

        return result

    def generate_text(
        self,
        *,
        session_id: str,
        agent_id: str,
        messages: (
            Sequence[api_types.GameMessage] | type[_types.NotGiven]
        ) = _types.NotGiven,
        cue: str | None | type[_types.NotGiven] = _types.NotGiven,
        service_id: str | None | type[_types.NotGiven] = _types.NotGiven,
        presentation_config: (
            api_types.PresentationConfig | type[_types.NotGiven]
        ) = _types.NotGiven,
    ) -> api_types.TextGenerated:
        """Ask the agent to generate text.

        Args:
            session_id: The session that this agent exists within.
            agent_id: The agent to target.
            messages: New history to process before generating text.
            cue: Optional text that can be used to prompt the agent.
        """
        payload = _requests.GenerateTextRequest(
            messages=messages,
            cue=cue,
            service_id=service_id,
            presentation_config=presentation_config,
        )
        result = self._process_request(
            method="POST",
            path=f"/v1/sessions/{session_id}/agents/{agent_id}/generate_text",
            data=payload,
            return_type=api_types.TextGenerated,
        )

        return result

    def generate_function_call(
        self,
        *,
        session_id: str,
        agent_id: str,
        functions: Sequence[api_types.FunctionDescription],
        messages: (
            Sequence[api_types.GameMessage] | type[_types.NotGiven]
        ) = _types.NotGiven,
        cue: str | None | type[_types.NotGiven] = _types.NotGiven,
        service_id: str | None | type[_types.NotGiven] = _types.NotGiven,
        presentation_config: (
            api_types.PresentationConfig | type[_types.NotGiven]
        ) = _types.NotGiven,
    ) -> api_types.FunctionCallGenerated:
        """Ask the agent to generate a function call.

        Args:
            session_id: The session that this agent exists within.
            agent_id: The agent to target.
            functions: List of functions available.
            messages: New history to use.
            cue: Optional text that can be used to prompt the agent.
        """
        payload = _requests.GenerateFunctionCallRequest(
            messages=messages,
            functions=functions,
            cue=cue,
            service_id=service_id,
            presentation_config=presentation_config,
        )
        result = self._process_request(
            method="POST",
            path=f"/v1/sessions/{session_id}/agents/{agent_id}/generate_function_call",
            data=payload,
            return_type=api_types.FunctionCallGenerated,
        )

        return result

    def generate_json(
        self,
        *,
        session_id: str,
        agent_id: str,
        schema: dict[str, Any],
        messages: (
            Sequence[api_types.GameMessage] | type[_types.NotGiven]
        ) = _types.NotGiven,
        cue: str | None | type[_types.NotGiven] = _types.NotGiven,
        service_id: str | None | type[_types.NotGiven] = _types.NotGiven,
        presentation_config: (
            api_types.PresentationConfig | type[_types.NotGiven]
        ) = _types.NotGiven,
    ) -> api_types.JSONGenerated:
        """Ask the agent to generate text.

        Args:
            session_id: The session that this agent exists within.
            agent_id: The agent to target.
            schema: A JSON schema that the result should satisfy.
            messages: New history to process before generating text.
            cue: Optional text that can be used to prompt the agent.
        """
        payload = _requests.GenerateJSONRequest(
            messages=messages,
            schema=schema,
            cue=cue,
            service_id=service_id,
            presentation_config=presentation_config,
        )

        result = self._process_request(
            method="POST",
            path=f"/v1/sessions/{session_id}/agents/{agent_id}/generate_json",
            data=payload,
            return_type=api_types.JSONGenerated,
        )

        return result
