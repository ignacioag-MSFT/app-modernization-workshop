# Scenario Instructions

## User Preferences

### Technical Preferences
- Target framework: net10.0 (.NET 10 LTS).
- Migrate ContosoUniversity from ASP.NET MVC 5 on .NET Framework 4.8 to ASP.NET Core MVC.
- Update Entity Framework Core from 3.1.32 to the latest supported release compatible with .NET 10.
- Preserve existing functional behavior.
- Do not create any rulebook-evidence.md file; no rulebook policy is active.

### Execution Style
- Flow mode: Automatic.
- Fully autonomous execution: do not pause for confirmation or review; accept defaults and proceed until complete or blocked by technical failure.

## Decisions
- Working branch: modernize/001-upgrade-dotnet10-aspnetcore-efcore.
- Source control strategy: clean working tree detected; create/use modernization branch before workflow initialization.
- TaskId: 001-upgrade-dotnet10-aspnetcore-efcore.
- Modernization work folder: .github/modernize/contoso-dotnet10-modernization.
- Success criteria: build passes and unit tests pass.
## Upgrade Options

| Option | Selected | Why |
|---|---|---|
| Upgrade Strategy | All-at-Once | Single-project ASP.NET Framework web application requires coordinated project, MVC, configuration, and EF Core migration. |
| Project Approach | In-place modernization | User requested migration of this project and accepted defaults for autonomous execution. |
| Test Coverage | Skip generation | Assessment reported no projects recommended for test coverage; no existing test project was found. |

## Strategy
**Selected**: All-at-Once
**Rationale**: The solution contains one high-complexity ASP.NET Framework web project with SDK-style conversion, System.Web MVC migration, unsupported bundling/routing, and EF Core/package compatibility issues that must be updated together.

### Execution Constraints
- Perform a single coordinated migration of the ContosoUniversity web project to SDK-style ASP.NET Core MVC targeting net10.0.
- Replace System.Web MVC, Web.config runtime configuration, Global.asax, RouteConfig, FilterConfig, and BundleConfig concepts with ASP.NET Core Program.cs, appsettings.json, endpoint routing, and static assets.
- Upgrade EF Core 3.1.32 packages to the latest installed/supported .NET 10-compatible release and adapt DbContext registration/configuration.
- Validate the migrated project with restore/build and tests where present; treat warnings in modified projects as build blockers.
- Preserve old functional behavior for Students, Courses, Departments, Instructors, Office Assignments, Enrollments, seed data, file upload, and notification flows where present.
## Upgrade Options

| Option | Selected | Why |
|---|---|---|
| Upgrade Strategy | All-at-Once | Single-project ASP.NET Framework web application requires coordinated project, MVC, configuration, and EF Core migration. |
| Project Approach | In-place modernization | User requested migration of this project and accepted defaults for autonomous execution. |
| Test Coverage | Skip generation | Assessment reported no projects recommended for test coverage; no existing test project was found. |

## Strategy
**Selected**: All-at-Once
**Rationale**: The solution contains one high-complexity ASP.NET Framework web project with SDK-style conversion, System.Web MVC migration, unsupported bundling/routing, and EF Core/package compatibility issues that must be updated together.

### Execution Constraints
- Perform a single coordinated migration of the ContosoUniversity web project to SDK-style ASP.NET Core MVC targeting net10.0.
- Replace System.Web MVC, Web.config runtime configuration, Global.asax, RouteConfig, FilterConfig, and BundleConfig concepts with ASP.NET Core Program.cs, appsettings.json, endpoint routing, and static assets.
- Upgrade EF Core 3.1.32 packages to the latest installed/supported .NET 10-compatible release and adapt DbContext registration/configuration.
- Validate the migrated project with restore/build and tests where present; treat warnings in modified projects as build blockers.
- Preserve old functional behavior for Students, Courses, Departments, Instructors, Office Assignments, Enrollments, seed data, file upload, and notification flows where present.
## Upgrade Options

| Option | Selected | Why |
|---|---|---|
| Upgrade Strategy | All-at-Once | Single-project ASP.NET Framework web application requires coordinated project, MVC, configuration, and EF Core migration. |
| Project Approach | In-place modernization | User requested migration of this project and accepted defaults for autonomous execution. |
| Test Coverage | Skip generation | Assessment reported no projects recommended for test coverage; no existing test project was found. |

## Strategy
**Selected**: All-at-Once
**Rationale**: Single high-complexity ASP.NET Framework web project; SDK conversion, hosting, MVC, EF Core, and packages must move together.

### Execution Constraints
- Upgrade ContosoUniversity atomically to SDK-style Microsoft.NET.Sdk.Web targeting net10.0.
- Replace System.Web MVC hosting/configuration with ASP.NET Core Program.cs, endpoint routing, MVC services, and static files.
- Upgrade EF Core 3.1.32 to the latest .NET 10-compatible release and register SchoolContext through DI.
- Preserve behavior and validate restore/build/tests with zero warnings/errors.
