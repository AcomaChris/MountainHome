import json
import unittest

import httpx
import respx

from artificial_agency import _requests, api_types, client, errors


class SimpleRequest(_requests.APIRequest):
    pass


class SimpleResponse(api_types.APIResponse):
    ok: bool


class TestClientConfiguration(unittest.TestCase):
    def test_default_base_url(self):
        cl = client.Client("test-api-key")

        request = cl._build_request(
            method="POST", path="/process-request", data=SimpleRequest()
        )
        assert request.url.scheme == "https"
        assert request.url.host == "api.artificial.agency"
        assert request.url.path == "/process-request"

    def test_base_url_trailing_slash(self):
        cl = client.Client("test-api-key", base_url="http://localhost/")

        request = cl._build_request(
            method="POST", path="/process-request", data=SimpleRequest()
        )
        assert request.url.scheme == "http"
        assert request.url.host == "localhost"
        assert request.url.path == "/process-request"

    def test_base_url_no_trailing_slash(self):
        cl = client.Client("test-api-key", base_url="http://localhost")

        request = cl._build_request(
            method="POST", path="/process-request", data=SimpleRequest()
        )
        assert request.url.scheme == "http"
        assert request.url.host == "localhost"
        assert request.url.path == "/process-request"

    def test_empty_api_key(self):
        with self.assertRaisesRegex(ValueError, "api_key must not be empty"):
            client.Client("")


class TestClientRequestBuilding(unittest.TestCase):
    def test_build_request_keeps_message_type(self):
        cl = client.Client("test-api-key")
        data = _requests.AddMessagesRequest(
            messages=[
                api_types.ContentMessage(content="Hello"),
                api_types.ContentMessage(content="World"),
            ]
        )
        req = cl._build_request(
            method="POST",
            path="/v1/sessions/sess_1234/agents/agent_567/messages",
            data=data,
        )
        self.assertEqual(
            req.url.path, "/v1/sessions/sess_1234/agents/agent_567/messages"
        )
        self.assertEqual(req.method, "POST")
        body = json.loads(req.content.decode("utf-8"))
        self.assertEqual(2, len(body["messages"]))
        for m in body["messages"]:
            self.assertEqual("ContentMessage", m["message_type"])

    def test_build_request_drops_notgiven_properties(self):
        cl = client.Client("test-api-key")
        data = _requests.GenerateFunctionCallRequest(
            functions=[
                api_types.FunctionDescription(
                    name="foo", docs="", parameters={}, required=[]
                )
            ],
        )
        req = cl._build_request(
            method="POST",
            path="/v1/sessions/sess_1234/agents/agent_567/generate_function_call",
            data=data,
        )
        self.assertEqual(
            req.url.path,
            "/v1/sessions/sess_1234/agents/agent_567/generate_function_call",
        )
        self.assertEqual(req.method, "POST")
        body = json.loads(req.content.decode("utf-8"))
        self.assertEqual(1, len(body["functions"]))
        self.assertEqual("foo", body["functions"][0]["name"])
        self.assertEqual({}, body["functions"][0]["parameters"])
        self.assertEqual([], body["functions"][0]["required"])
        self.assertNotIn("messages", body)
        self.assertNotIn("cue", body)


class TestClientRequests(unittest.IsolatedAsyncioTestCase):
    client = client.Client(api_key="test-api-key")

    @respx.mock
    def test_process_request(self, respx_mock: respx.Router):
        respx_mock.post("/process-request").mock(
            return_value=httpx.Response(200, json={"ok": True})
        )

        response = self.client._process_request(
            method="POST",
            path="/process-request",
            data=SimpleRequest(),
            return_type=SimpleResponse,
        )
        assert response.ok

    @respx.mock
    def test_process_request_error(self, respx_mock):
        respx_mock.post("/process-request").mock(
            return_value=httpx.Response(
                400,
                json={
                    "error": {
                        "type": "invalid_request",
                        "message": "An example failure.",
                        "trace": "1234567890abcdef",
                    },
                },
            )
        )

        with self.assertRaisesRegex(errors.APIError, "An example failure.") as e:
            self.client._process_request(
                method="POST",
                path="/process-request",
                data=SimpleRequest(),
                return_type=SimpleResponse,
            )

            assert e.exception.status_code == 200
            assert e.exception.error_type == "invalid_request"

    @respx.mock
    def test_process_request_unparseable_error(self, respx_mock):
        respx_mock.post("/process-request").mock(
            return_value=httpx.Response(500, content="Server Error")
        )

        with self.assertRaisesRegex(
            errors.APIError, "The server returned an unexpected response."
        ) as e:
            self.client._process_request(
                method="POST",
                path="/process-request",
                data=SimpleRequest(),
                return_type=SimpleResponse,
            )

            assert e.exception.status_code == 500
            assert e.exception.error_type == "invalid_request"

    @respx.mock
    def test_process_request_unparseable_success(self, respx_mock):
        respx_mock.post("/process-request").mock(
            return_value=httpx.Response(
                200, json={"this-is": "not-the-expected-response"}
            )
        )

        with self.assertRaisesRegex(
            errors.APIError, "Server returned data in an unexpected format."
        ) as e:
            self.client._process_request(
                method="POST",
                path="/process-request",
                data=SimpleRequest(),
                return_type=SimpleResponse,
            )

            assert e.exception.status_code == 500
            assert e.exception.error_type == "server_error"

    @respx.mock
    def test_process_request_timeout(self, respx_mock):
        respx_mock.post("/process-request").mock(side_effect=httpx.TimeoutException)

        with self.assertRaisesRegex(errors.APIError, "Request timed out.") as e:
            self.client._process_request(
                method="POST",
                path="/process-request",
                data=SimpleRequest(),
                return_type=SimpleResponse,
            )

            assert e.exception.status_code == 500
            assert e.exception.error_type == "server_error"

    @respx.mock
    def test_create_session(self, respx_mock: respx.Router):
        route = respx_mock.post("/v1/sessions").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "sess_1234",
                    "created_at": "1680318000",
                    "project_id": "proj_1234",
                    "metadata": {},
                    "expires_at": None,
                    "max_requests": 1000,
                },
            )
        )

        response = self.client.create_session(
            project_id="proj_1234", metadata={"client": "testing"}
        )
        assert response.id == "sess_1234"
        assert response.project_id == "proj_1234"
        assert response.metadata == {}
        assert response.expires_at == None
        assert response.max_requests == 1000

        assert json.loads(route.calls.last.request.content) == {
            "project_id": "proj_1234",
            "metadata": {"client": "testing"},
            # properties with default values were omitted.
        }

    @respx.mock
    def test_create_session_nondefault_expiry(self, respx_mock: respx.Router):
        route = respx_mock.post("/v1/sessions").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "sess_1234",
                    "created_at": "1680318000",
                    "project_id": "proj_1234",
                    "metadata": {},
                    "expires_at": None,
                    "max_requests": 1000,
                },
            )
        )

        response = self.client.create_session(
            project_id="proj_1234",
            metadata={"client": "testing"},
            expires_in=60,
            max_requests=None,
        )
        assert response.id == "sess_1234"
        assert response.project_id == "proj_1234"
        assert response.metadata == {}
        assert response.expires_at == None
        assert response.max_requests == 1000

        assert json.loads(route.calls.last.request.content) == {
            "project_id": "proj_1234",
            "metadata": {"client": "testing"},
            "expires_in": 60,
            "max_requests": None,
        }

    @respx.mock
    def test_create_agent(self, respx_mock: respx.Router):
        route = respx_mock.post("/v1/advanced/sessions/sess_1234/agents").mock(
            return_value=httpx.Response(
                200,
                json={
                    "id": "agent_1234",
                    "session_id": "sess_1234",
                    "moment_id": 1,
                    "moment_uuid": "moment_1234",
                    "ui_config": {
                        "friendly_name": None,
                        "emoji": None,
                        "metadata": {"client": "testing"},
                    },
                },
            )
        )

        metadata = {"client": "testing"}
        role_config = api_types.RoleConfig(
            core="bios content",
            characterization="characterization content",
        )
        presentation_config = api_types.PresentationConfig(
            presentation_order=[api_types.PresentationOrderItem(["history", "items"])],
        )
        component_configs = [api_types.LimitedListConfig(id="history")]
        service_configs = [
            api_types.ServiceConfig(
                id="default_llm",
                service_name="openai/gpt_4o_mini",
            ),
        ]
        agent_llm = "default_llm"

        agent = self.client.create_agent(
            session_id="sess_1234",
            role_config=role_config,
            presentation_config=presentation_config,
            component_configs=component_configs,
            service_configs=service_configs,
            agent_llm=agent_llm,
            ui_config=api_types.UIConfig(metadata=metadata),
        )

        assert agent.session_id == "sess_1234"
        assert agent.agent_id == "agent_1234"
        assert agent.moment_id == 1
        assert agent.moment_uuid == "moment_1234"

        assert json.loads(route.calls.last.request.content) == {
            "role_config": {
                "core": "bios content",
                "characterization": "characterization content",
            },
            "presentation_config": {"presentation_order": [["history", "items"]]},
            "component_configs": [{"id": "history", "type": "limited_list"}],
            "service_configs": [
                {"id": "default_llm", "service_name": "openai/gpt_4o_mini"}
            ],
            "agent_llm": agent_llm,
            "ui_config": {"metadata": metadata},
        }

    @respx.mock
    def test_generate_json(self, respx_mock: respx.Router):
        respx_mock.post("/v1/sessions/sess_1234/agents/agent_1234/generate_json").mock(
            return_value=httpx.Response(
                200,
                json={"moment_id": "1", "json": {"species": "Felis catus", "hp": 1}},
            )
        )

        response = self.client.generate_json(
            session_id="sess_1234",
            agent_id="agent_1234",
            schema={
                "type": "object",
                "properties": {
                    "species": {"type": "string"},
                    "hp": {"type": "integer"},
                },
                "required": ["species", "hp"],
                "additionalProperties": False,
            },
        )
        assert response.moment_id == "1"
        assert response.json_ == {"species": "Felis catus", "hp": 1}
