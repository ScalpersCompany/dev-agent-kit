# Flow specs

Add a `.spec.ts` per flow here. Keep selectors user-facing (`getByRole`, `getByLabel`,
`getByText`) and assert the result the user sees or the data the service persists.
Do not mock the application under test. External providers use a local fake or a recorded
cassette configured by the profile.
