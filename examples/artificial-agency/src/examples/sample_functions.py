"""Sample functions that agents created in the artificial agency behavior engine can
call in a generate_function_call request.
"""

from artificial_agency import api_types

# Example with an enumeration-valued parameter.
move_to_fn = api_types.FunctionDescription(
    name="move_to",
    docs="Move to a location.",
    parameters={
        "location": api_types.SimpleParameter(
            value_type="string",
            docs="where to go",
            enumeration=[
                "home",
                "work",
                "beach",
                "mall",
            ],
        )
    },
    required=["location"],
)


# Example with a simple integer-valued parameter.
add_fn = api_types.FunctionDescription(
    name="add",
    docs="Add two numbers.",
    parameters={
        "x": api_types.SimpleParameter(
            value_type="integer",
            docs="first operand",
        ),
        "y": api_types.SimpleParameter(
            value_type="integer",
            docs="second operand",
        ),
    },
    required=["x", "y"],
)


# Example with a list-valued parameter.
sum_fn = api_types.FunctionDescription(
    name="sum",
    docs="Sum a list of numbers.",
    parameters={
        "numbers": api_types.ArrayParameter(
            items=api_types.SimpleParameter(
                value_type="integer",
                docs="number to sum",
            ),
            docs="list of numbers to sum",
        ),
    },
    required=["numbers"],
)


# Example with optional parameters.
speak_fn = api_types.FunctionDescription(
    name="speak",
    docs="Speak a message, optionally directed to someone.",
    parameters={
        "message": api_types.SimpleParameter(
            value_type="string",
            docs="the message to speak",
        ),
        "speak_to": api_types.SimpleParameter(
            value_type="string",
            docs="the name of a specific person to speak to",
        ),
    },
    required=["message"],
)


# Example with no parameters.
squeek_fn = api_types.FunctionDescription(
    name="squeek",
    docs="Makes a squeek sound",
    parameters={},
    required=[],
)
