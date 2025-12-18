"""Types used internally by this library."""

import typing
from typing import Self, final

import pydantic


# a sentinel indicating that an argument was not given.
# this is used when "None" is a valid value for an argument.
@final
class NotGiven:
    pass


class GeneratedModel(pydantic.BaseModel):
    @pydantic.model_validator(mode="after")
    def explicitly_set_literals(self) -> Self:
        """Explicitly set any fields with a `Literal` type.

        This ensures that typed union discriminators are not treated as unset
        when we dump the model.
        e.g.

            type: Literal["openai/llm"] = pydantic.Field(default="openai/llm")
        """
        for k, v in self.model_fields.items():
            if v.annotation:
                """
                …:Literal[…]
                """
                if typing.get_origin(v.annotation) == typing.Literal:
                    literal_value = typing.get_args(v.annotation)
                    if len(literal_value) == 1:
                        setattr(self, k, literal_value[0])
        return self
