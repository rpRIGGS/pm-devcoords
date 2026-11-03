# PM DevCoords development

Standalone developer-only aim-point capture utility.

- No QBX or inventory dependencies.
- ACE gate: `command.devcoords` from existing server.cfg permissions.
- `/devcoords` toggles pointer; M opens ox_lib menu; J captures; K undoes.
- Groups and collections are freely named (e.g. Vineyard_01A / Row_01_SideA, Production / Sample_Barrels).
- vector4 is default; heading is the camera's horizontal aim heading, not ped heading.
- Captures are saved immediately to `captures.json`; group export writes `exports/<group>.lua`.
- Polygon creation remains outside scope.
- Pending: in-server testing, save/export checks, UI refinements and individual point review.
